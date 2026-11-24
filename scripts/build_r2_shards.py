#!/usr/bin/env python3
"""
Convertisseur de la base de donnees Otaku Verse (5 996 fichiers .md.docx, 21 oeuvres)
en shards JSON compresses (gzip) prets pour Cloudflare R2 (105 shards : 21 oeuvres x 5 niveaux).

Usage :
  python3 scripts/build_r2_shards.py                    # Toutes les 21 oeuvres
  python3 scripts/build_r2_shards.py --work death_note  # Test rapide sur 1 oeuvre
"""

import argparse
import gzip
import json
import os
import re
import sys
import unicodedata
import zipfile
import xml.etree.ElementTree as ET
from collections import defaultdict
from concurrent.futures import ProcessPoolExecutor, as_completed

NS = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
ID_LINE_RE = re.compile(r"^[A-Z0-9]{2,8}-[A-Z0-9_]+-N[1-5]-V\d+_\d+-Q\d+-[A-Z0-9_]+$")
FALLBACK_ID_RE = re.compile(r"^[A-Z0-9]{2,8}-[A-Z0-9_]+-.*-(BASE|VAR\d+|V\d+)$")
KEY_VAL_RE = re.compile(r"^(?:-\s+)?([a-zA-Z_][a-zA-Z0-9_\\]*)\s*:\s*(.*)$")
ARC_STORY_RE = re.compile(r"^Arc\s+(.+?)\s*/\s*(Manga|Anime)\s*$", re.IGNORECASE)


def _norm_ascii(text):
    return "".join(
        c for c in unicodedata.normalize("NFD", str(text).strip().lower())
        if unicodedata.category(c) != "Mn"
    )


def classify_arc_name_v4(arc_name):
    """Classificateur officiel Standard V4.0 : 5 formats normalises, ZERO limite d'arcs par oeuvre."""
    raw = str(arc_name or "").strip()
    m = ARC_STORY_RE.match(raw)
    if m:
        official_name = m.group(1).strip()
        media_raw = m.group(2).strip().upper()
        return {
            "category": f"ARC_{media_raw}",
            "arc_display_name": official_name,
            "media": media_raw,
        }
    norm = _norm_ascii(raw)
    if norm == "personnages":
        return {"category": "PERSONNAGES", "arc_display_name": "Personnages", "media": "PERSONNAGES"}
    if norm in ("general", "global", ""):
        return {"category": "GLOBAL", "arc_display_name": "Général", "media": "GLOBAL"}
    if norm in ("films & oav", "films et oav", "films/oav"):
        return {"category": "FILMS_OAV", "arc_display_name": "Films & OAV", "media": "ANIME"}
    return {"category": "UNKNOWN", "arc_display_name": raw or "Général", "media": None}

DIFF_MAP = {
    1: "facile",
    2: "moyen",
    3: "difficile",
    4: "expert",
    5: "maitre",
}

DIFF_STR_MAP = {
    "facile": 1,
    "easy": 1,
    "moyen": 2,
    "medium": 2,
    "difficile": 3,
    "hard": 3,
    "expert": 4,
    "maitre": 5,
    "maître": 5,
    "master": 5,
}

# Mapping dossier -> (work_slug, work_title)
FOLDER_TO_WORK = {
    "Attack on Titan (Markdown)": ("attack_on_titan", "Attack on Titan"),
    "Bleach (Markdown)": ("bleach", "Bleach"),
    "Blue Lock (Markdown)": ("blue_lock", "Blue Lock"),
    "Chainsaw Man (Markdown)": ("chainsaw_man", "Chainsaw Man"),
    "Dandadan (Markdown)": ("dandadan", "Dandadan"),
    "Death Note (Markdown)": ("death_note", "Death Note"),
    "Demon Slayer (Markdown)": ("demon_slayer", "Demon Slayer"),
    "Dragon Ball (Markdown)": ("dragon_ball", "Dragon Ball"),
    "Dragon Ball Z (Markdown)": ("dragon_ball_z", "Dragon Ball Z"),
    "Fairy Tail (Markdown)": ("fairy_tail", "Fairy Tail"),
    "Frieren (Markdown)": ("frieren", "Frieren"),
    "Fullmetal Alchemist_ Brotherhood (Markdown)": ("fullmetal_alchemist_brotherhood", "Fullmetal Alchemist: Brotherhood"),
    "Hunter x Hunter (Markdown)": ("hunter_x_hunter", "Hunter x Hunter"),
    "Jujutsu Kaisen (Markdown)": ("jujutsu_kaisen", "Jujutsu Kaisen"),
    "Kaguya-sama_ Love Is War (Markdown)": ("kaguya_sama_love_is_war", "Kaguya-sama: Love Is War"),
    "Kingdom (Markdown)": ("kingdom", "Kingdom"),
    "My Hero Academia (Markdown)": ("my_hero_academia", "My Hero Academia"),
    "Naruto (Markdown)": ("naruto", "Naruto"),
    "Naruto Shippuden (Markdown)": ("naruto_shippuden", "Naruto Shippuden"),
    "One Piece (Markdown)": ("one_piece", "One Piece"),
    "Re_Zero (Markdown)": ("re_zero", "Re:Zero"),
}


def clean_null(val):
    if val is None:
        return None
    s = str(val).strip()
    if not s or s.lower() in ("null", "none", "n/a", "na", "-"):
        return None
    return s


def parse_int(val):
    s = clean_null(val)
    if s is None:
        return None
    try:
        return int(float(s.replace(" ", "").replace(",", ".")))
    except Exception:
        return None


def parse_float(val):
    s = clean_null(val)
    if s is None:
        return None
    try:
        return float(s.replace(" ", "").replace(",", "."))
    except Exception:
        return None


def parse_list(val):
    s = clean_null(val)
    if s is None:
        return None
    if s.startswith("[") and s.endswith("]"):
        try:
            arr = json.loads(s)
            if isinstance(arr, list):
                return [str(x).strip() for x in arr if str(x).strip()]
        except Exception:
            s = s[1:-1]
    if "|" in s:
        parts = [p.strip().strip('"').strip("'") for p in s.split("|")]
    else:
        parts = [p.strip().strip('"').strip("'") for p in s.split(",")]
    out = [p for p in parts if p]
    return out if out else None


def normalize_record(raw_id, fields, default_slug, default_title):
    q_text = clean_null(fields.get("question_text") or fields.get("question"))
    if not q_text:
        return None

    # Difficulte 1..5
    diff_lvl = parse_int(fields.get("difficulty_level"))
    if diff_lvl is None or diff_lvl not in (1, 2, 3, 4, 5):
        lbl = (fields.get("difficulty_label") or "").strip().lower()
        diff_lvl = DIFF_STR_MAP.get(lbl, 2)

    variant_code = clean_null(fields.get("variant_code") or fields.get("variant_id")) or "1.1"
    domain = (clean_null(fields.get("domain") or fields.get("theme")) or "GLOBAL").upper()
    arc_name = clean_null(fields.get("arc_name") or fields.get("arc_tags")) or "Global"
    explanation = clean_null(fields.get("explanation_lore") or fields.get("explanation"))

    correct_answer = clean_null(fields.get("correct_answer"))
    correct_text = clean_null(fields.get("correct_text"))
    exact_value = parse_float(fields.get("exact_value") or fields.get("numeric_answer"))

    # Compact schema pour limiter la taille des shards R2
    arc_meta = classify_arc_name_v4(arc_name)
    rec = {
        "id": raw_id,
        "w": default_slug,
        "d": domain,
        "a": arc_meta["arc_display_name"],
        "ac": arc_meta["category"],
        "n": diff_lvl,
        "v": variant_code,
        "q": q_text,
    }

    opt_a = clean_null(fields.get("option_a"))
    opt_b = clean_null(fields.get("option_b"))
    opt_c = clean_null(fields.get("option_c"))
    opt_d = clean_null(fields.get("option_d"))
    if opt_a is not None:
        rec["oa"] = opt_a
    if opt_b is not None:
        rec["ob"] = opt_b
    if opt_c is not None:
        rec["oc"] = opt_c
    if opt_d is not None:
        rec["od"] = opt_d

    if correct_answer is not None:
        rec["ca"] = correct_answer
    if correct_text is not None:
        rec["ct"] = correct_text
    if exact_value is not None:
        rec["ev"] = exact_value
        unit = clean_null(fields.get("unit"))
        if unit:
            rec["un"] = unit
        tol = parse_float(fields.get("tolerance_pct_full"))
        if tol is not None:
            rec["tf"] = tol
        min_s = parse_float(fields.get("min_slider"))
        max_s = parse_float(fields.get("max_slider"))
        if min_s is not None:
            rec["mn"] = min_s
        if max_s is not None:
            rec["mx"] = max_s

    wb = parse_list(fields.get("word_bank"))
    if wb:
        rec["wb"] = wb

    if explanation:
        rec["ex"] = explanation

    parent_id = clean_null(fields.get("parent_question_id"))
    if parent_id:
        rec["p"] = parent_id

    sp_ch = parse_int(fields.get("spoiler_chapter_max"))
    if sp_ch is not None:
        rec["sc"] = sp_ch

    sp_ep = parse_int(fields.get("spoiler_episode_max"))
    if sp_ep is not None:
        rec["se"] = sp_ep

    return rec


def parse_single_docx(args):
    """Supporte a la fois les fichiers .md (Standard V4.0 ### <ID>) et les .docx historiques."""
    filepath, default_slug, default_title = args
    records = []
    try:
        if filepath.lower().endswith(".md"):
            with open(filepath, "r", encoding="utf-8") as f:
                lines = [ln.strip() for ln in f.readlines() if ln.strip()]
        else:
            with zipfile.ZipFile(filepath, "r") as z:
                xml_bytes = z.read("word/document.xml")
            tree = ET.fromstring(xml_bytes)
            lines = []
            for p in tree.findall(".//w:p", NS):
                txt = "".join(t.text or "" for t in p.findall(".//w:t", NS)).strip()
                if txt:
                    lines.append(txt)
    except Exception:
        return records, 1

    cur_id = None
    cur_fields = {}

    def flush():
        if cur_id and cur_fields:
            rec = normalize_record(cur_id, cur_fields, default_slug, default_title)
            if rec:
                records.append(rec)

    for line in lines:
        # Format V4.0 : ### <ID>
        if line.startswith("### "):
            flush()
            cur_id = line[4:].strip()
            cur_fields = {}
            continue
        if line.startswith("#") or line.startswith("---") or line.startswith("```"):
            continue
        m = KEY_VAL_RE.match(line)
        if m and not ID_LINE_RE.match(line):
            k = m.group(1).strip().replace("\\_", "_").lower()
            v = m.group(2).strip()
            cur_fields[k] = v
        elif ID_LINE_RE.match(line) or (FALLBACK_ID_RE.match(line) and " " not in line):
            flush()
            cur_id = line.strip()
            cur_fields = {}

    flush()
    return records, 0


def build_work(quiz_root, folder_name, out_shards_dir, workers):
    slug, title = FOLDER_TO_WORK[folder_name]
    folder_path = os.path.join(quiz_root, folder_name)
    if not os.path.isdir(folder_path):
        return None

    files = []
    for root, dirs, filenames in os.walk(folder_path):
        dirs[:] = [d for d in dirs if d != "_ARCHIVES_DOUBLONS_A_SUPPRIMER"]
        for fn in sorted(filenames):
            if not (fn.endswith(".docx") or fn.endswith(".md")):
                continue
            if fn.startswith("_BILAN_FINAL") or fn.startswith("~$"):
                continue
            files.append((os.path.join(root, fn), slug, title))

    seen_ids = set()
    by_level = {1: [], 2: [], 3: [], 4: [], 5: []}
    arcs = set()
    domains = defaultdict(int)
    variants = defaultdict(int)
    errors = 0
    dupes = 0

    with ProcessPoolExecutor(max_workers=workers) as ex:
        for recs, err in ex.map(parse_single_docx, files, chunksize=8):
            errors += err
            for rec in recs:
                qid = rec["id"]
                if qid in seen_ids:
                    dupes += 1
                    continue
                seen_ids.add(qid)
                lvl = rec["n"]
                by_level[lvl].append(rec)
                arcs.add(rec["a"])
                domains[rec["d"]] += 1
                variants[rec["v"]] += 1

    level_counts = {}
    total_gz_bytes = 0
    for lvl in range(1, 6):
        arr = by_level[lvl]
        level_counts[str(lvl)] = len(arr)
        shard_path = os.path.join(out_shards_dir, f"{slug}_N{lvl}.json.gz")
        raw_json = json.dumps(arr, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        with gzip.open(shard_path, "wb", compresslevel=6) as gz:
            gz.write(raw_json)
        total_gz_bytes += os.path.getsize(shard_path)

    total_q = len(seen_ids)
    print(
        f"  [{slug}] {len(files)} fichiers -> {total_q:,} questions "
        f"(doublons: {dupes}, erreurs: {errors}, taille gz: {total_gz_bytes / (1024*1024):.2f} Mo)"
    )

    return {
        "slug": slug,
        "title": title,
        "total_questions": total_q,
        "levels": level_counts,
        "domains": dict(domains),
        "variants": dict(variants),
        "arcs": sorted(arcs),
        "shards_gz_bytes": total_gz_bytes,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--work", help="Filtrer sur un seul work_slug (ex: death_note)")
    parser.add_argument("--workers", type=int, default=max(2, (os.cpu_count() or 4) - 1))
    args = parser.parse_args()

    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    quiz_root = os.path.join(repo_root, "drive_sources", "02_quiz_21_oeuvres")
    out_root = os.path.join(repo_root, "r2_build")
    out_shards = os.path.join(out_root, "shards")
    os.makedirs(out_shards, exist_ok=True)

    folders = sorted(FOLDER_TO_WORK.keys())
    if args.work:
        folders = [f for f in folders if FOLDER_TO_WORK[f][0] == args.work]
        if not folders:
            print(f"Oeuvre inconnue : {args.work}")
            sys.exit(1)

    print(f"=== Conversion vers R2 shards ({len(folders)} oeuvre(s), {args.workers} workers) ===")
    catalog_works = []
    grand_total = 0
    grand_bytes = 0

    for folder in folders:
        info = build_work(quiz_root, folder, out_shards, args.workers)
        if info:
            catalog_works.append(info)
            grand_total += info["total_questions"]
            grand_bytes += info["shards_gz_bytes"]

    catalog = {
        "version": "v9.2",
        "total_works": len(catalog_works),
        "total_questions": grand_total,
        "total_gz_mb": round(grand_bytes / (1024 * 1024), 2),
        "works": catalog_works,
    }
    catalog_path = os.path.join(out_root, "catalog.json")
    with open(catalog_path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)

    print(f"=== TERMINE : {grand_total:,} questions -> {grand_bytes / (1024*1024):.2f} Mo compressés dans r2_build/ ===")


if __name__ == "__main__":
    main()
