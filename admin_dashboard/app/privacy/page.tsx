export default function PrivacyPolicyPage() {
  return (
    <main className="min-h-screen max-w-3xl mx-auto px-6 py-12 text-gray-200">
      <h1 className="text-3xl font-bold text-purple-400 mb-2">
        Politique de Confidentialite : Otaku Verse
      </h1>
      <p className="text-xs text-gray-400 mb-8">Derniere mise a jour : 24 novembre 2026</p>

      <section className="space-y-6 text-sm leading-relaxed">
        <div>
          <h2 className="text-lg font-semibold text-white mb-2">1. Donnees collectees</h2>
          <p>
            Otaku Verse collecte uniquement les donnees necessaires au fonctionnement du jeu : adresse
            email de connexion, pseudo, pays optionnel, statistiques de combat (XP, niveau, rang,
            victoires, division), objets cosmetiques debloques et jeton technique de notification push.
          </p>
        </div>

        <div>
          <h2 className="text-lg font-semibold text-white mb-2">2. Confidentialite et partage</h2>
          <p>
            Ton adresse email et tes soldes de monnaies virtuelles (Otaku Coins et Verse Coins) ne sont
            jamais rendus publics. Les cartes de partage 9:16 anonymisent par defaut les pseudos
            d&apos;amis et d&apos;adversaires, sauf accord explicite active dans les Parametres.
          </p>
        </div>

        <div>
          <h2 className="text-lg font-semibold text-white mb-2">3. Diagnostics et securite</h2>
          <p>
            Nous utilisons Supabase pour l&apos;authentification et la sauvegarde securisee, Cloudflare R2
            pour le chargement des quiz et modeles 3D, ainsi que Firebase Crashlytics et Analytics pour
            detecter les plantages et ameliorer la stabilite sur mobile.
          </p>
        </div>

        <div>
          <h2 className="text-lg font-semibold text-white mb-2">4. Suppression definitive du compte</h2>
          <p>
            Conformement aux regles Google Play et Apple App Store, tu peux supprimer definitivement
            ton compte et toutes les donnees associees a tout moment directement dans l&apos;application
            (Parametres &gt; Supprimer definitivement mon compte) ou en contactant{" "}
            <span className="text-purple-400">support@otakuverse.app</span>.
          </p>
        </div>
      </section>
    </main>
  );
}
