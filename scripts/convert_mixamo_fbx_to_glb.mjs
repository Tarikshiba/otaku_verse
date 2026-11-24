/**
 * Convertit automatiquement les fichiers .fbx exportes de Mixamo
 * (`assets_sources_raw/mixamo_workspace/02_animations_fbx_sortie/*.fbx`)
 * en modeles .glb animes, optimises et prets pour l'app + Cloudflare R2.
 *
 * - Accepte n'importe quel nom contenant le prenom du perso (ex: Anim_kio.fbx, kio.fbx, Anim_ysae.fbx)
 * - Convertit FBX -> GLB via `fbx2gltf` en conservant le squelette, l'animation et la texture
 * - Corrige la rugosite PBR (evite l'effet plastique brillant des exports FBX Mixamo)
 * - Compresse textures (1024px JPEG) + resample() sur les animations
 * - Met a jour `r2_build/models/skins/skin_<perso>.glb` et copie `skin_kio.glb` dans `app/assets/models/skins/`
 */

import fs from "node:fs";
import path from "node:path";
import convert from "fbx2gltf";
import { NodeIO } from "@gltf-transform/core";
import { ALL_EXTENSIONS } from "@gltf-transform/extensions";
import {
  dedup,
  prune,
  resample,
  textureCompress,
} from "@gltf-transform/functions";
import sharp from "sharp";

const rootIdx = process.argv.indexOf("--root");
const ROOT = rootIdx >= 0 ? path.resolve(process.argv[rootIdx + 1]) : path.resolve(process.cwd());
const FBX_DIR = path.join(ROOT, "assets_sources_raw", "mixamo_workspace", "02_animations_fbx_sortie");
const TMP_DIR = path.join(ROOT, "assets_sources_raw", "mixamo_workspace", "_tmp_glb");
const R2_OUT_DIR = path.join(ROOT, "r2_build", "models", "skins");
const APP_OUT_DIR = path.join(ROOT, "app", "assets", "models", "skins");

const CHARACTERS = [
  { key: "cassio_vey", dst: "skin_cassio_vey.glb", embed: false },
  { key: "kio", dst: "skin_kio.glb", embed: true },
  { key: "mazu", dst: "skin_mazu.glb", embed: false },
  { key: "tavik", dst: "skin_tavik.glb", embed: false },
  { key: "ruve", dst: "skin_ruve.glb", embed: false },
  { key: "hesk", dst: "skin_hesk.glb", embed: false },
  { key: "ilka", dst: "skin_ilka.glb", embed: false },
  { key: "vael", dst: "skin_vael.glb", embed: false },
  { key: "dakore", dst: "skin_dakore.glb", embed: false },
  { key: "ysae", dst: "skin_ysae.glb", embed: false },
];

function matchCharacter(fileName) {
  const lower = fileName.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  return CHARACTERS.find((c) => lower.includes(c.key));
}

async function processFbx(io, fbxFile) {
  const match = matchCharacter(fbxFile);
  if (!match) {
    console.warn(`[SKIP] Impossible d'identifier le personnage pour : ${fbxFile}`);
    return;
  }

  const fbxPath = path.join(FBX_DIR, fbxFile);
  const rawGlbPath = path.join(TMP_DIR, `${match.key}_raw.glb`);
  fs.mkdirSync(TMP_DIR, { recursive: true });

  console.log(`[CONVERT] ${fbxFile} -> ${match.dst}...`);
  await convert(fbxPath, rawGlbPath, ["--binary", "--pbr-metallic-roughness"]);

  const doc = await io.read(rawGlbPath);

  // Reglage materiau PBR propre (evite le rendu plastique brillant de certains exports FBX)
  for (const mat of doc.getRoot().listMaterials()) {
    mat.setMetallicFactor(0.05);
    mat.setRoughnessFactor(0.85);
    mat.setDoubleSided(false);
  }

  // Si Mixamo a perdu la texture albedo, la reinjecter depuis notre archive ZIP / GLB existant
  const textures = doc.getRoot().listTextures();
  if (textures.length === 0) {
    const existingGlb = path.join(R2_OUT_DIR, match.dst);
    if (fs.existsSync(existingGlb)) {
      const refDoc = await io.read(existingGlb);
      const refTex = refDoc.getRoot().listTextures()[0];
      if (refTex && refTex.getImage()) {
        const newTex = doc.createTexture(`${match.key}_albedo`)
          .setImage(refTex.getImage())
          .setMimeType(refTex.getMimeType() || "image/jpeg");
        for (const mat of doc.getRoot().listMaterials()) {
          mat.setBaseColorTexture(newTex);
        }
        console.log(`  [INFO] Texture couleur reinjectee automatiquement depuis ${match.dst}`);
      }
    }
  }

  // Optimisation sans casser le squelette ni l'animation
  await doc.transform(
    dedup(),
    textureCompress({
      encoder: sharp,
      targetFormat: "jpeg",
      resize: [1024, 1024],
      quality: 84,
    }),
    resample(),
    prune(),
  );

  const anims = doc.getRoot().listAnimations();
  const skins = doc.getRoot().listSkins();
  const texCount = doc.getRoot().listTextures().length;

  const outPath = path.join(R2_OUT_DIR, match.dst);
  await io.write(outPath, doc);
  const outSizeMB = (fs.statSync(outPath).size / (1024 * 1024)).toFixed(2);

  if (match.embed) {
    fs.mkdirSync(APP_OUT_DIR, { recursive: true });
    fs.copyFileSync(outPath, path.join(APP_OUT_DIR, match.dst));
  }

  console.log(
    `[OK] ${match.dst} : ${outSizeMB} Mo | anims=${anims.length} (${anims.map((a) => a.getName()).join(", ")}) | skins=${skins.length} | textures=${texCount}` +
    (match.embed ? " [EMBED APK + R2]" : " [R2]"),
  );
}

async function main() {
  if (!fs.existsSync(FBX_DIR)) {
    console.error(`Dossier introuvable : ${FBX_DIR}`);
    process.exit(1);
  }
  const fbxFiles = fs.readdirSync(FBX_DIR).filter((f) => f.toLowerCase().endsWith(".fbx"));
  if (fbxFiles.length === 0) {
    console.log("Aucun fichier .fbx trouve dans 02_animations_fbx_sortie.");
    return;
  }

  fs.mkdirSync(R2_OUT_DIR, { recursive: true });
  const io = new NodeIO().registerExtensions(ALL_EXTENSIONS);
  for (const file of fbxFiles) {
    await processFbx(io, file);
  }
  if (fs.existsSync(TMP_DIR)) {
    fs.rmSync(TMP_DIR, { recursive: true, force: true });
  }
  console.log("=== Conversion Mixamo FBX -> GLB terminee ===");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
