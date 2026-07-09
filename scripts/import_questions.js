/**
 * Script d'import des questions .md vers Supabase.
 *
 * Usage : node scripts/import_questions.js
 *
 * Ce script :
 * 1. Lit tous les fichiers .md dans questions_db/ (recursif)
 * 2. Parse le frontmatter (metadata) et le contenu (question, choix, reponse)
 * 3. Insere dans la table "questions" de Supabase
 * 4. Detecte les doublons (par id) et les ignore
 */

const fs = require('fs');
const path = require('path');

// === CONFIGURATION ===
// On lit les cles depuis le .env a la racine du projet
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const SUPABASE_URL = process.env.SUPABASE_URL;
// On utilise la service_role key pour l'import (bypass RLS)
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error('ERREUR : SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY doivent etre dans .env');
  process.exit(1);
}

// === FONCTIONS ===

/**
 * Trouve tous les fichiers .md dans un dossier (recursif)
 */
function trouverFichiersMd(dossier) {
  let resultats = [];
  const elements = fs.readdirSync(dossier);

  for (const element of elements) {
    const cheminComplet = path.join(dossier, element);
    const stats = fs.statSync(cheminComplet);

    if (stats.isDirectory()) {
      resultats = resultats.concat(trouverFichiersMd(cheminComplet));
    } else if (element.endsWith('.md') && !element.startsWith('.')) {
      resultats.push(cheminComplet);
    }
  }
  return resultats;
}

/**
 * Parse un fichier .md de question et retourne un objet structure
 */
function parserQuestion(contenuFichier) {
  // Separe le frontmatter (entre ---) du corps
  const parties = contenuFichier.split('---');
  if (parties.length < 3) return null;

  const frontmatter = parties[1].trim();
  const corps = parties.slice(2).join('---').trim();

  // Parse le frontmatter (YAML simple, on le fait a la main pour eviter une dependance)
  const meta = {};
  for (const ligne of frontmatter.split('\n')) {
    const match = ligne.match(/^(\w+)\s*:\s*(.+)$/);
    if (match) {
      const cle = match[1].trim();
      let valeur = match[2].trim();

      // Gere les tableaux [tag1, tag2]
      if (valeur.startsWith('[') && valeur.endsWith(']')) {
        valeur = valeur.slice(1, -1).split(',').map(v => v.trim());
      }
      meta[cle] = valeur;
    }
  }

  // Parse le corps : question, choix, bonne reponse, explication
  const lignes = corps.split('\n');
  let question = '';
  let choix = { A: '', B: '', C: '', D: '' };
  let bonneReponse = '';
  let explication = '';

  for (const ligne of lignes) {
    if (ligne.startsWith('**Question :')) {
      question = ligne.replace('**Question :**', '').replace('**Question :', '').replace('**', '').trim();
    } else if (ligne.match(/^- A:/)) {
      choix.A = ligne.replace('- A:', '').trim();
    } else if (ligne.match(/^- B:/)) {
      choix.B = ligne.replace('- B:', '').trim();
    } else if (ligne.match(/^- C:/)) {
      choix.C = ligne.replace('- C:', '').trim();
    } else if (ligne.match(/^- D:/)) {
      choix.D = ligne.replace('- D:', '').trim();
    } else if (ligne.startsWith('**Bonne reponse :')) {
      bonneReponse = ligne.replace('**Bonne reponse :**', '').replace('**Bonne reponse :', '').replace('**', '').trim();
    } else if (ligne.startsWith('**Explication :')) {
      explication = ligne.replace('**Explication :**', '').replace('**Explication :', '').replace('**', '').trim();
    }
  }

  // Validation : tous les champs obligatoires doivent etre presents
  if (!meta.id || !meta.anime || !meta.type || !meta.difficulte || !question || !choix.A || !choix.B || !choix.C || !choix.D || !bonneReponse) {
    return null;
  }

  return {
    id: meta.id,
    anime: meta.anime,
    arc: meta.arc || null,
    chapitre: meta.chapitre || null,
    type: meta.type,
    difficulte: meta.difficulte,
    question: question,
    choix_a: choix.A,
    choix_b: choix.B,
    choix_c: choix.C,
    choix_d: choix.D,
    bonne_reponse: bonneReponse,
    explication: explication || null,
    tags: Array.isArray(meta.tags) ? meta.tags : null,
    statut: 'actif',
  };
}

/**
 * Insere les questions dans Supabase via l'API REST
 */
async function insererDansSupabase(questions) {
  const url = `${SUPABASE_URL}/rest/v1/questions`;

  const reponse = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`,
      'Prefer': 'resolution=ignore-duplicates',
    },
    body: JSON.stringify(questions),
  });

  if (!reponse.ok) {
    const erreur = await reponse.text();
    throw new Error(`Erreur Supabase (${reponse.status}): ${erreur}`);
  }

  return reponse;
}

// === EXECUTION ===

async function main() {
  const dossierQuestions = path.join(__dirname, '..', 'questions_db');

  console.log('=== IMPORT DES QUESTIONS VERS SUPABASE ===\n');

  // 1. Trouver tous les .md
  const fichiers = trouverFichiersMd(dossierQuestions);
  console.log(`Fichiers .md trouves : ${fichiers.length}`);

  // 2. Parser chaque fichier
  const questions = [];
  const erreurs = [];

  for (const fichier of fichiers) {
    const contenu = fs.readFileSync(fichier, 'utf-8');
    const question = parserQuestion(contenu);

    if (question) {
      questions.push(question);
    } else {
      erreurs.push(path.basename(fichier));
    }
  }

  console.log(`Questions valides : ${questions.length}`);
  if (erreurs.length > 0) {
    console.log(`Fichiers ignores (format invalide) : ${erreurs.join(', ')}`);
  }

  if (questions.length === 0) {
    console.log('\nAucune question a importer.');
    return;
  }

  // 3. Inserer dans Supabase
  console.log(`\nEnvoi vers Supabase...`);
  try {
    await insererDansSupabase(questions);
    console.log(`OK ! ${questions.length} questions importees (doublons ignores).`);
  } catch (e) {
    console.error(`ERREUR : ${e.message}`);
    process.exit(1);
  }

  console.log('\n=== IMPORT TERMINE ===');
}

main();
