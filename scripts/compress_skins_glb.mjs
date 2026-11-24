/**
 * Compression & decimation optimisee des modeles 3D .glb Otaku Verse
 * - Garde les originaux intacts dans assets_sources_raw/Skin_3D/
 * - Decime les maillages lourds (1,5M tris -> ~28k-35k tris) en preservant UVs et normales
 * - Redimensionne et compresse les textures 4K PNG -> 1024px JPEG (core glTF 2.0, compatible 100% Android/iOS/Windows)
 * - Quantifie la geometrie (KHR_mesh_quantization) pour descendre sous ~1,5 - 2,5 Mo / personnage
 * - Copie automatiquement skin_kio.glb (Kio) dans app/assets/models/skins/
 * - Place les 10 modeles dans r2_build/models/skins/ prets pour upload Cloudflare R2
 *
 * Usage (via Node Windows avec outils dans %TEMP%\otaku_glb_tools) :
 *   NODE_PATH=... node scripts/compress_skins_glb.mjs [--only Ilka.glb]
 */

import fs from "node:fs";
import path from "node:path";
import { NodeIO } from "@gltf-transform/core";
import { ALL_EXTENSIONS } from "@gltf-transform/extensions";
import {
  dedup,
  prune,
  quantize,
  resample,
  simplify,
  textureCompress,
  weld,
} from "@gltf-transform/functions";
import { MeshoptSimplifier } from "meshoptimizer";
import sharp from "sharp";

const rootIdx = process.argv.indexOf("--root");
const ROOT = rootIdx >= 0 ? path.resolve(process.argv[rootIdx + 1]) : path.resolve(process.cwd());
const SRC_DIR = path.join(ROOT, "assets_sources_raw", "Skin_3D");
const R2_OUT_DIR = path.join(ROOT, "r2_build", "models", "skins");
const APP_OUT_DIR = path.join(ROOT, "app", "assets", "models", "skins");

// Correspondance officielle OTAKU_VERSE_PERSONNAGES.md (noms propres sans copyright)
const SKIN_MAPPING = [
  { src: "KIO.glb", dst: "skin_kio.glb", nom: "Kio", targetTris: 32000, embedInApk: true },
  { src: "Mazu.glb", dst: "skin_mazu.glb", nom: "Mazú", targetTris: 30000, embedInApk: false },
  { src: "Tavik.glb", dst: "skin_tavik.glb", nom: "Tavik", targetTris: 32000, embedInApk: false },
  { src: "Ruvé.glb", dst: "skin_ruve.glb", nom: "Ruvé", targetTris: 30000, embedInApk: false },
  { src: "Hesk.glb", dst: "skin_hesk.glb", nom: "Hesk", targetTris: 30000, embedInApk: false },
  { src: "Ilka.glb", dst: "skin_ilka.glb", nom: "Ilka", targetTris: 30000, embedInApk: false },
  { src: "Vael.glb", dst: "skin_vael.glb", nom: "Vael", targetTris: 30000, embedInApk: false },
  { src: "Dakore.glb", dst: "skin_dakore.glb", nom: "Dakoré", targetTris: 30000, embedInApk: false },
  { src: "Ysae.glb", dst: "skin_ysae.glb", nom: "Ysaé", targetTris: 30000, embedInApk: false },
  { src: "Cassio_vey.glb", dst: "skin_cassio_vey.glb", nom: "Cassio Vey", targetTris: 30000, embedInApk: false },
];

function countTriangles(doc) {
  let tris = 0;
  for (const mesh of doc.getRoot().listMeshes()) {
    for (const prim of mesh.listPrimitives()) {
      const indices = prim.getIndices();
      if (indices) {
        tris += Math.floor(indices.getCount() / 3);
      } else {
        const pos = prim.getAttribute("POSITION");
        if (pos) tris += Math.floor(pos.getCount() / 3);
      }
    }
  }
  return tris;
}

async function compressOne(io, entry) {
  const inputPath = path.join(SRC_DIR, entry.src);
  if (!fs.existsSync(inputPath)) {
    console.error(`[SKIP] Introuvable : ${inputPath}`);
    return null;
  }

  const startMs = Date.now();
  const inSizeMB = fs.statSync(inputPath).size / (1024 * 1024);
  const doc = await io.read(inputPath);
  const inTris = countTriangles(doc);

  // Calcul du ratio exact pour atteindre ~targetTris sans deformer la silhouette
  const ratio = inTris > entry.targetTris
    ? Math.max(0.015, Math.min(0.95, entry.targetTris / inTris))
    : 1.0;

  const hasAnims = doc.getRoot().listAnimations().length > 0;
  const hasSkins = doc.getRoot().listSkins().length > 0;

  // 1. Soudure des sommets dupliques puis decimation QEM preservant UV, normales et squelette Mixamo
  await doc.transform(
    dedup(),
    weld({ tolerance: 0.0001 }),
  );

  if (ratio < 0.99) {
    await doc.transform(
      simplify({
        simplifier: MeshoptSimplifier,
        ratio,
        error: hasSkins ? 0.002 : 0.003,
        lockBorder: hasSkins,
      }),
    );
  }

  // 2. Compression textures 4K -> 1024x1024 JPEG + optimisation des pistes d'animation si Mixamo/rig present
  const postSteps = [
    textureCompress({
      encoder: sharp,
      targetFormat: "jpeg",
      resize: [1024, 1024],
      quality: 84,
    }),
    prune(),
  ];
  if (hasAnims) {
    postSteps.push(resample());
  }
  postSteps.push(quantize());
  await doc.transform(...postSteps);

  const outTris = countTriangles(doc);
  const outPath = path.join(R2_OUT_DIR, entry.dst);
  await io.write(outPath, doc);
  const outSizeMB = fs.statSync(outPath).size / (1024 * 1024);

  if (entry.embedInApk) {
    fs.copyFileSync(outPath, path.join(APP_OUT_DIR, entry.dst));
  }

  const elapsed = ((Date.now() - startMs) / 1000).toFixed(1);
  console.log(
    `[OK] ${entry.nom.padEnd(11)} (${entry.src} -> ${entry.dst}) : ` +
    `${inSizeMB.toFixed(1)} Mo -> ${outSizeMB.toFixed(2)} Mo | ` +
    `${inTris.toLocaleString("en-US")} -> ${outTris.toLocaleString("en-US")} tris (${elapsed}s)` +
    (entry.embedInApk ? " [EMBED APK]" : " [R2]"),
  );
  return { ...entry, inSizeMB, outSizeMB, inTris, outTris };
}

async function main() {
  await MeshoptSimplifier.ready;
  fs.mkdirSync(R2_OUT_DIR, { recursive: true });
  fs.mkdirSync(APP_OUT_DIR, { recursive: true });

  const io = new NodeIO().registerExtensions(ALL_EXTENSIONS);
  const onlyIdx = process.argv.indexOf("--only");
  const onlyFile = onlyIdx >= 0 ? process.argv[onlyIdx + 1] : null;

  const targets = onlyFile
    ? SKIN_MAPPING.filter((e) => e.src.toLowerCase() === onlyFile.toLowerCase() || e.dst.toLowerCase() === onlyFile.toLowerCase())
    : SKIN_MAPPING;

  if (targets.length === 0) {
    console.error(`Aucun modele correspondant a --only ${onlyFile}`);
    process.exit(1);
  }

  console.log(`=== Compression 3D GLB Otaku Verse (${targets.length} modele(s)) ===`);
  let totalIn = 0;
  let totalOut = 0;
  for (const entry of targets) {
    const res = await compressOne(io, entry);
    if (res) {
      totalIn += res.inSizeMB;
      totalOut += res.outSizeMB;
    }
  }
  console.log(`=== TOTAL : ${totalIn.toFixed(1)} Mo -> ${totalOut.toFixed(2)} Mo (-${((1 - totalOut / Math.max(totalIn, 0.01)) * 100).toFixed(1)}%) ===`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
