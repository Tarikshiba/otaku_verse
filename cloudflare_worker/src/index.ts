/**
 * Cloudflare Worker : API Quiz Otaku Verse (1 281 697 questions sur Cloudflare R2)
 *
 * Endpoints :
 * - GET  /catalog  : renvoie la liste des 21 oeuvres, arcs et compteurs
 * - POST /draw     : tire un lot de 40 questions (mix V9.2 10/25/30/25/10% ou Solo fixe)
 *                    SANS JAMAIS renvoyer la bonne reponse (ca / ct / ev) au client
 * - POST /validate : protege par X-Worker-Secret (appele uniquement par Supabase match-engine)
 *                    verifie la reponse cote serveur pour les 8 formats actifs
 */

export interface Env {
  QUIZ_BUCKET: R2Bucket;
  WORKER_API_SECRET: string;
}

interface ShardQuestion {
  id: string;
  w: string; // work_slug
  d: string; // domain
  a: string; // arc_name
  n: number; // difficulty_level 1..5
  v: string; // variant_code (1.1, 1.2, 1.4, 2.1, 2.2, 3.1, 3.2, 5.1)
  q: string; // question_text
  oa?: string;
  ob?: string;
  oc?: string;
  od?: string;
  ca?: string; // correct_answer (JAMAIS renvoye dans /draw)
  ct?: string; // correct_text (JAMAIS renvoye dans /draw)
  ev?: number; // exact_value (JAMAIS renvoye dans /draw)
  un?: string; // unit
  tf?: number; // tolerance_pct_full
  mn?: number; // min_slider
  mx?: number; // max_slider
  wb?: string[]; // word_bank
  ex?: string; // explanation_lore
  p?: string; // parent_question_id
  sc?: number; // spoiler_chapter_max
  se?: number; // spoiler_episode_max
}

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Worker-Secret",
};

// Mix V9.2 officiel sur 40 questions (§1.2bis)
const MIX_DISTRIBUTIONS: Record<string, Record<number, number>> = {
  division:  { 1: 4,  2: 10, 3: 12, 4: 10, 5: 4  },
  facile:    { 1: 28, 2: 10, 3: 2,  4: 0,  5: 0  },
  moyen:     { 1: 8,  2: 22, 3: 8,  4: 2,  5: 0  },
  difficile: { 1: 0,  2: 4,  3: 22, 4: 10, 5: 4  },
  expert:    { 1: 0,  2: 0,  3: 6,  4: 22, 5: 12 },
  maitre:    { 1: 0,  2: 0,  3: 0,  4: 8,  5: 32 },
  adaptatif: { 1: 8,  2: 8,  3: 8,  4: 8,  5: 8  },
};

const ALL_WORKS = [
  "attack_on_titan", "bleach", "blue_lock", "chainsaw_man", "dandadan",
  "death_note", "demon_slayer", "dragon_ball", "dragon_ball_z", "fairy_tail",
  "frieren", "fullmetal_alchemist_brotherhood", "hunter_x_hunter", "jujutsu_kaisen",
  "kaguya_sama_love_is_war", "kingdom", "my_hero_academia", "naruto",
  "naruto_shippuden", "one_piece", "re_zero",
];

// Cache memoire limite aux petits shards (< 10 000 questions, max 3 en RAM)
// pour rester largement sous la limite de 128 Mo RAM des Cloudflare Workers gratuits
const shardCache = new Map<string, ShardQuestion[]>();

function jsonResp(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

async function loadShard(env: Env, workSlug: string, level: number): Promise<ShardQuestion[]> {
  const key = `shards/${workSlug}_N${level}.json.gz`;
  const cached = shardCache.get(key);
  if (cached) return cached;

  const obj = await env.QUIZ_BUCKET.get(key);
  if (!obj || !obj.body) return [];

  // Decompression gzip native Workers (Web Streams API)
  const ds = new DecompressionStream("gzip");
  const decompressed = obj.body.pipeThrough(ds);
  const text = await new Response(decompressed).text();
  const parsed = JSON.parse(text) as ShardQuestion[];

  if (parsed.length <= 10000) {
    if (shardCache.size >= 3) {
      const firstKey = shardCache.keys().next().value;
      if (firstKey) shardCache.delete(firstKey);
    }
    shardCache.set(key, parsed);
  }
  return parsed;
}

function sanitizeForClient(q: ShardQuestion) {
  return {
    id: q.id,
    work_slug: q.w,
    domain: q.d,
    arc_name: q.a,
    difficulty_level: q.n,
    variant_code: q.v,
    question: q.q,
    choix_a: q.oa ?? "",
    choix_b: q.ob ?? "",
    choix_c: q.oc ?? "",
    choix_d: q.od ?? "",
    word_bank: q.wb ?? null,
    unit: q.un ?? null,
    min_slider: q.mn ?? null,
    max_slider: q.mx ?? null,
  };
}

function pickRandom<T>(arr: T[], count: number, usedParents: Set<string>): T[] {
  if (arr.length === 0 || count <= 0) return [];
  const chosen: T[] = [];
  const tried = new Set<number>();
  const maxAttempts = Math.min(arr.length * 3, count * 20);

  for (let i = 0; i < maxAttempts && chosen.length < count; i++) {
    const idx = Math.floor(Math.random() * arr.length);
    if (tried.has(idx)) continue;
    tried.add(idx);
    const item = arr[idx] as unknown as ShardQuestion;
    const parentKey = item.p || item.id.replace(/-VAR\d+$/, "-BASE");
    if (usedParents.has(parentKey)) continue;
    usedParents.add(parentKey);
    chosen.push(arr[idx]);
  }
  return chosen;
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: CORS });
    }

    const url = new URL(req.url);

    // 1. GET /catalog : catalogue des 21 oeuvres et arcs
    if (req.method === "GET" && url.pathname === "/catalog") {
      const obj = await env.QUIZ_BUCKET.get("catalog.json");
      if (!obj) return jsonResp({ error: "Catalogue introuvable dans R2" }, 404);
      const body = await obj.text();
      return new Response(body, {
        headers: {
          ...CORS,
          "Content-Type": "application/json",
          "Cache-Control": "public, max-age=3600",
        },
      });
    }

    // 2. POST /draw : tirage de 40 questions sans bonne reponse
    if (req.method === "POST" && url.pathname === "/draw") {
      const body = (await req.json()) as Record<string, any>;
      const mode = String(body.mode || "division");
      const difficulty = String(body.difficulty || "moyen").toLowerCase();
      const totalRequested = Math.max(1, Math.min(40, Number(body.count) || 40));
      const requestedWork = typeof body.work_slug === "string" && body.work_slug.trim() ? body.work_slug.trim().toLowerCase() : null;
      const requestedArc = typeof body.arc_name === "string" && body.arc_name.trim() ? body.arc_name.trim().toLowerCase() : null;
      const requestedDomain = typeof body.domain === "string" && body.domain.trim() ? body.domain.trim().toUpperCase() : null;
      const maxSpoilerCh = typeof body.max_spoiler_chapter === "number" ? body.max_spoiler_chapter : null;
      const allowedVariants: string[] | null = Array.isArray(body.variants) ? body.variants.map(String) : ["1.1", "1.2", "1.4", "2.1", "2.2"];

      // Choix de la distribution selon mode/difficulte (V9.2 §1.2bis)
      const distKey = mode === "division" ? "division" : (MIX_DISTRIBUTIONS[difficulty] ? difficulty : "moyen");
      const baseDist = MIX_DISTRIBUTIONS[distKey];
      const scale = totalRequested / 40;

      // Si aucune oeuvre specifiee, choisir 3 oeuvres aleatoires pour limiter les lectures R2
      const worksPool = requestedWork
        ? [requestedWork]
        : [...ALL_WORKS].sort(() => Math.random() - 0.5).slice(0, 3);

      const usedParents = new Set<string>();
      const selected: ShardQuestion[] = [];

      for (const lvl of [1, 2, 3, 4, 5]) {
        const needed = Math.round((baseDist[lvl] || 0) * scale);
        if (needed <= 0) continue;

        let candidates: ShardQuestion[] = [];
        for (const w of worksPool) {
          const shard = await loadShard(env, w, lvl);
          for (const q of shard) {
            if (requestedDomain && requestedDomain !== "TOUS" && q.d !== requestedDomain) continue;
            if (requestedArc && !q.a.toLowerCase().includes(requestedArc)) continue;
            if (allowedVariants && !allowedVariants.includes(q.v)) continue;
            if (maxSpoilerCh !== null && q.sc !== undefined && q.sc > maxSpoilerCh) continue;
            candidates.push(q);
          }
        }

        const picked = pickRandom(candidates, needed, usedParents);
        selected.push(...picked);
      }

      // En mode Division, garder l'ordre progressif Facile -> Maitre (courbe de tension §1.2bis)
      const ordered = mode === "division"
        ? selected.sort((a, b) => a.n - b.n)
        : selected;

      return jsonResp({
        count: ordered.length,
        questions: ordered.slice(0, totalRequested).map(sanitizeForClient),
      });
    }

    // 3. POST /validate : verification serveur securisee (appelee uniquement par Supabase)
    if (req.method === "POST" && url.pathname === "/validate") {
      const secret = req.headers.get("X-Worker-Secret") || "";
      if (!env.WORKER_API_SECRET || secret !== env.WORKER_API_SECRET) {
        return jsonResp({ error: "Acces refuse" }, 403);
      }

      const body = (await req.json()) as Record<string, any>;
      const questionId = String(body.question_id || "");
      const workSlug = String(body.work_slug || "").toLowerCase();
      const level = Number(body.difficulty_level) || 1;
      const answer = String(body.answer ?? "").trim();

      if (!questionId || !workSlug) {
        return jsonResp({ error: "question_id et work_slug requis" }, 400);
      }

      const shard = await loadShard(env, workSlug, level);
      const q = shard.find((item) => item.id === questionId);
      if (!q) {
        return jsonResp({ error: "Question introuvable dans le shard" }, 404);
      }

      let isCorrect = false;
      if (q.v === "5.1" && q.ev !== undefined) {
        // Estimation numerique avec tolerance
        const numAns = Number(answer.replace(/\s+/g, "").replace(",", "."));
        const tolPct = (q.tf ?? 10) / 100;
        if (!Number.isNaN(numAns)) {
          const margin = Math.max(1, Math.abs(q.ev) * tolPct);
          isCorrect = Math.abs(numAns - q.ev) <= margin;
        }
      } else if (q.ca) {
        isCorrect = answer.toUpperCase() === q.ca.toUpperCase();
      } else if (q.ct) {
        isCorrect = answer.toLowerCase() === q.ct.toLowerCase();
      }

      return jsonResp({
        correct: isCorrect,
        correct_answer: q.ca ?? q.ct ?? String(q.ev ?? ""),
        explanation: q.ex ?? null,
        difficulty_level: q.n,
      });
    }

    return jsonResp({ error: "Route introuvable" }, 404);
  },
};
