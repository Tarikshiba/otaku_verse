/**
 * Exporte les 10 modeles 3D .glb compresses (r2_build/models/skins/)
 * vers des archives .zip pretes a glisser-deposer sur Mixamo (.obj + .mtl + texture albedo .jpg).
 *
 * Pourquoi partir des .glb compresses (~30k tris) ?
 * - Mixamo plante ou refuse les maillages a 1,5 million de triangles.
 * - A ~30k triangles + texture 1024px, l'upload prend 2 secondes et l'Auto-Rigger est tres propre.
 *
 * Sortie : assets_sources_raw/mixamo_workspace/01_a_uploader_sur_mixamo/<perso>_mixamo.zip
 */

import fs from "node:fs";
import path from "node:path";
import { NodeIO } from "@gltf-transform/core";
import { ALL_EXTENSIONS } from "@gltf-transform/extensions";

const rootIdx = process.argv.indexOf("--root");
const ROOT = rootIdx >= 0 ? path.resolve(process.argv[rootIdx + 1]) : path.resolve(process.cwd());
const SRC_DIR = path.join(ROOT, "r2_build", "models", "skins");
const OUT_BASE = path.join(ROOT, "assets_sources_raw", "mixamo_workspace");
const OUT_UNPACKED = path.join(OUT_BASE, "_tmp_obj");
const OUT_UPLOAD = path.join(OUT_BASE, "01_a_uploader_sur_mixamo");
const OUT_ANIM = path.join(OUT_BASE, "02_animations_fbx_sortie");

const SKINS = [
  { file: "skin_kio.glb", name: "kio" },
  { file: "skin_mazu.glb", name: "mazu" },
  { file: "skin_tavik.glb", name: "tavik" },
  { file: "skin_ruve.glb", name: "ruve" },
  { file: "skin_hesk.glb", name: "hesk" },
  { file: "skin_ilka.glb", name: "ilka" },
  { file: "skin_vael.glb", name: "vael" },
  { file: "skin_dakore.glb", name: "dakore" },
  { file: "skin_ysae.glb", name: "ysae" },
  { file: "skin_cassio_vey.glb", name: "cassio_vey" },
];

// Multiplication matrice 4x4 (column-major glTF) par un point 3D
function transformPoint(m, x, y, z) {
  return [
    m[0] * x + m[4] * y + m[8] * z + m[12],
    m[1] * x + m[5] * y + m[9] * z + m[13],
    m[2] * x + m[6] * y + m[10] * z + m[14],
  ];
}

// Transformation d'une normale par la partie 3x3 de la matrice
function transformNormal(m, x, y, z) {
  const nx = m[0] * x + m[4] * y + m[8] * z;
  const ny = m[1] * x + m[5] * y + m[9] * z;
  const nz = m[2] * x + m[6] * y + m[10] * z;
  const len = Math.hypot(nx, ny, nz) || 1;
  return [nx / len, ny / len, nz / len];
}

async function exportOne(io, entry) {
  const srcPath = path.join(SRC_DIR, entry.file);
  if (!fs.existsSync(srcPath)) {
    console.error(`[SKIP] Introuvable : ${srcPath}`);
    return;
  }

  const doc = await io.read(srcPath);
  const workDir = path.join(OUT_UNPACKED, entry.name);
  fs.mkdirSync(workDir, { recursive: true });

  const objLines = [
    `# Otaku Verse - ${entry.name} (pret pour Mixamo)`,
    `mtllib ${entry.name}.mtl`,
  ];
  const mtlLines = [];
  const writtenMats = new Set();

  let vOffset = 1;
  let vtOffset = 1;
  let vnOffset = 1;
  let meshIdx = 0;

  // Parcourir tous les noeuds avec leur matrice monde exacte
  for (const node of doc.getRoot().listNodes()) {
    const mesh = node.getMesh();
    if (!mesh) continue;

    const worldMat = node.getWorldMatrix();

    for (const prim of mesh.listPrimitives()) {
      const posAcc = prim.getAttribute("POSITION");
      if (!posAcc) continue;
      const uvAcc = prim.getAttribute("TEXCOORD_0");
      const normAcc = prim.getAttribute("NORMAL");
      const idxAcc = prim.getIndices();

      const mat = prim.getMaterial();
      const matName = `mat_${meshIdx}`;
      meshIdx++;

      if (!writtenMats.has(matName)) {
        writtenMats.add(matName);
        mtlLines.push(`newmtl ${matName}`);
        mtlLines.push(`Ka 1.000 1.000 1.000`);
        mtlLines.push(`Kd 1.000 1.000 1.000`);
        mtlLines.push(`Ks 0.100 0.100 0.100`);
        mtlLines.push(`d 1.0`);

        const baseTex = mat?.getBaseColorTexture();
        if (baseTex) {
          const imgBytes = baseTex.getImage();
          const mime = baseTex.getMimeType() || "image/jpeg";
          const ext = mime.includes("png") ? "png" : "jpg";
          const texFile = `${entry.name}_${matName}_albedo.${ext}`;
          if (imgBytes) {
            fs.writeFileSync(path.join(workDir, texFile), Buffer.from(imgBytes));
            mtlLines.push(`map_Kd ${texFile}`);
          }
        }
        mtlLines.push("");
      }

      objLines.push(`g ${entry.name}_${meshIdx}`);
      objLines.push(`usemtl ${matName}`);

      const vCount = posAcc.getCount();
      const tmp = [0, 0, 0];
      for (let i = 0; i < vCount; i++) {
        posAcc.getElement(i, tmp);
        const [x, y, z] = transformPoint(worldMat, tmp[0], tmp[1], tmp[2]);
        objLines.push(`v ${x.toFixed(5)} ${y.toFixed(5)} ${z.toFixed(5)}`);
      }

      const hasUv = Boolean(uvAcc);
      if (hasUv) {
        const uv = [0, 0];
        for (let i = 0; i < uvAcc.getCount(); i++) {
          uvAcc.getElement(i, uv);
          // OBJ utilise V=0 en bas, glTF utilise V=0 en haut -> inversion 1 - v
          objLines.push(`vt ${uv[0].toFixed(5)} ${(1.0 - uv[1]).toFixed(5)}`);
        }
      }

      const hasNorm = Boolean(normAcc);
      if (hasNorm) {
        const n = [0, 0, 0];
        for (let i = 0; i < normAcc.getCount(); i++) {
          normAcc.getElement(i, n);
          const [nx, ny, nz] = transformNormal(worldMat, n[0], n[1], n[2]);
          objLines.push(`vn ${nx.toFixed(4)} ${ny.toFixed(4)} ${nz.toFixed(4)}`);
        }
      }

      const triCount = idxAcc ? Math.floor(idxAcc.getCount() / 3) : Math.floor(vCount / 3);
      for (let t = 0; t < triCount; t++) {
        const i0 = idxAcc ? idxAcc.getScalar(t * 3) : t * 3;
        const i1 = idxAcc ? idxAcc.getScalar(t * 3 + 1) : t * 3 + 1;
        const i2 = idxAcc ? idxAcc.getScalar(t * 3 + 2) : t * 3 + 2;

        const fmt = (idx) => {
          const vi = vOffset + idx;
          if (hasUv && hasNorm) return `${vi}/${vtOffset + idx}/${vnOffset + idx}`;
          if (hasUv) return `${vi}/${vtOffset + idx}`;
          if (hasNorm) return `${vi}//${vnOffset + idx}`;
          return `${vi}`;
        };
        objLines.push(`f ${fmt(i0)} ${fmt(i1)} ${fmt(i2)}`);
      }

      vOffset += vCount;
      if (hasUv) vtOffset += uvAcc.getCount();
      if (hasNorm) vnOffset += normAcc.getCount();
    }
  }

  fs.writeFileSync(path.join(workDir, `${entry.name}.obj`), objLines.join("\n"));
  fs.writeFileSync(path.join(workDir, `${entry.name}.mtl`), mtlLines.join("\n"));
  console.log(`[OBJ OK] ${entry.name} (${vOffset - 1} sommets)`);
}

async function main() {
  fs.mkdirSync(OUT_UNPACKED, { recursive: true });
  fs.mkdirSync(OUT_UPLOAD, { recursive: true });
  fs.mkdirSync(OUT_ANIM, { recursive: true });

  const io = new NodeIO().registerExtensions(ALL_EXTENSIONS);
  for (const entry of SKINS) {
    await exportOne(io, entry);
  }
  console.log("=== Export OBJ+MTL+Textures termine ===");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
