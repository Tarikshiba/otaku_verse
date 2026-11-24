export default function TermsPage() {
  return (
    <main className="min-h-screen max-w-3xl mx-auto px-6 py-12 text-gray-200">
      <h1 className="text-3xl font-bold text-purple-400 mb-2">
        Conditions Generales d&apos;Utilisation (CGU) : Otaku Verse
      </h1>
      <p className="text-xs text-gray-400 mb-8">Derniere mise a jour : 24 novembre 2026</p>

      <section className="space-y-6 text-sm leading-relaxed">
        <div>
          <h2 className="text-lg font-semibold text-white mb-2">1. Equite et regles de jeu</h2>
          <p>
            Otaku Verse est un jeu de quiz anime et manga base sur le merite (zero pay-to-win). Les
            skins, cadres, titres et effets visuels ne procurent aucun bonus de degats ou d&apos;XP en
            match classe. Toute tentative de triche ou d&apos;automatisation peut entrainer la suspension
            du compte.
          </p>
        </div>

        <div>
          <h2 className="text-lg font-semibold text-white mb-2">2. Monnaies virtuelles et achats</h2>
          <p>
            Les Otaku Coins (OC) s&apos;obtiennent gratuitement en jouant. Les Verse Coins (VC), le Pass
            Sans Pub et l&apos;abonnement VIP sont des biens numeriques sans valeur monetaire externe,
            regis par les conditions de facturation de Google Play et de l&apos;Apple App Store.
          </p>
        </div>

        <div>
          <h2 className="text-lg font-semibold text-white mb-2">3. Propriete intellectuelle</h2>
          <p>
            Les personnages originaux d&apos;Otaku Verse (Kio, Mazu, Tavik, Ruve, Hesk, Ilka, Vael,
            Dakore, Ysae, Cassio Vey, Soryn et Nyxara), les illustrations, les modeles 3D et le code
            sont la propriete d&apos;Otaku Verse.
          </p>
        </div>

        <div>
          <h2 className="text-lg font-semibold text-white mb-2">4. Contact et support</h2>
          <p>
            Pour toute question ou reclamation, contacte l&apos;equipe a{" "}
            <span className="text-purple-400">support@otakuverse.app</span> ou utilise le bouton de
            signalement integre dans l&apos;application.
          </p>
        </div>
      </section>
    </main>
  );
}
