import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/rank_badge.dart';
import 'tutorial_service.dart';

/// === TUTORIEL PHASE A : DECOUVERTE IMMEDIATE EN 2 MINUTES (TUTO-01 §4.1, TESTS 3, 4, 5) ===
/// - Etape A1 : Carrousel visuel des 21 oeuvres reelles du catalogue Cloudflare R2 (Solo Leveling retire)
/// - Etape A2 : Combat decouverte de 5 questions avec animations HAYA!! (-23 PV), COMBO x3 (-35 PV),
///   COMBO + HAYA!! (-41 PV) et K.O. KECCHAKU! ralentis, agrandis et expliques pas a pas
/// - Etape A3 : Recompense +300 OC & +100 XP + achat guide du 1er Goodies (300 OC) -> Sauvegarder mon compte
class TutorialPhaseAPage extends StatefulWidget {
  final VoidCallback onTermineVersInscription;
  final VoidCallback onDejaUnCompte;
  final bool dejaConnecte;

  const TutorialPhaseAPage({
    super.key,
    required this.onTermineVersInscription,
    required this.onDejaUnCompte,
    this.dejaConnecte = false,
  });

  @override
  State<TutorialPhaseAPage> createState() => _TutorialPhaseAPageState();
}

class _TutorialPhaseAPageState extends State<TutorialPhaseAPage> {
  final TutorialService _tutoService = TutorialService();

  int _etape = 1; // 1 = Choix anime, 2 = Combat 5Q, 3 = Recompense & 1er Goodies
  String _animeSlug = 'one_piece';
  String _animeTitre = 'One Piece';

  // Etat du combat decouverte (5 questions)
  int _qIndex = 0;
  int _pvJoueur = 350;
  int _pvBot = 120;
  int _combo = 0;
  DateTime _qStart = DateTime.now();
  String? _badgeAction;
  String? _explicationMecanique;
  Color _badgeCouleur = OtakuColors.accent;
  bool _repondu = false;
  int? _choixSelectionne;

  // Etape A3 : achat guide du 1er Goodies (300 OC)
  int _ocVirtuel = 300;
  bool _goodieAchete = false;

  // Les 21 oeuvres reelles du catalogue R2 (Test 3 : Solo Leveling retire)
  static const List<Map<String, String>> _animes = [
    {'slug': 'one_piece', 'titre': 'One Piece', 'tag': 'Grand Line & Haki'},
    {'slug': 'naruto', 'titre': 'Naruto', 'tag': 'Shinobi & Villages'},
    {'slug': 'naruto_shippuden', 'titre': 'Naruto Shippuden', 'tag': 'Akatsuki & Grande Guerre'},
    {'slug': 'jujutsu_kaisen', 'titre': 'Jujutsu Kaisen', 'tag': 'Exorcisme & Territoires'},
    {'slug': 'demon_slayer', 'titre': 'Demon Slayer', 'tag': 'Souffles & Piliers'},
    {'slug': 'attack_on_titan', 'titre': 'Attack on Titan', 'tag': 'Murs & Titans'},
    {'slug': 'bleach', 'titre': 'Bleach', 'tag': 'Soul Society & Bankai'},
    {'slug': 'dragon_ball', 'titre': 'Dragon Ball', 'tag': 'Arts Martiaux & Dragon Balls'},
    {'slug': 'dragon_ball_z', 'titre': 'Dragon Ball Z', 'tag': 'Saiyans & Super Saiyan'},
    {'slug': 'hunter_x_hunter', 'titre': 'Hunter x Hunter', 'tag': 'Examen Hunter & Nen'},
    {'slug': 'death_note', 'titre': 'Death Note', 'tag': 'Kira vs L'},
    {'slug': 'my_hero_academia', 'titre': 'My Hero Academia', 'tag': 'Alters & Héros'},
    {'slug': 'chainsaw_man', 'titre': 'Chainsaw Man', 'tag': 'Démons & Contrats'},
    {'slug': 'blue_lock', 'titre': 'Blue Lock', 'tag': 'Égoïstes & Buteurs'},
    {'slug': 'fullmetal_alchemist_brotherhood', 'titre': 'Fullmetal Alchemist: Brotherhood', 'tag': 'Alchimie & Homonculus'},
    {'slug': 'frieren', 'titre': 'Frieren', 'tag': 'Magie & Mémoire'},
    {'slug': 'dandadan', 'titre': 'Dandadan', 'tag': 'Esprits & Aliens'},
    {'slug': 'fairy_tail', 'titre': 'Fairy Tail', 'tag': 'Guilde & Magie'},
    {'slug': 'kingdom', 'titre': 'Kingdom', 'tag': 'Stratégie & Unification'},
    {'slug': 're_zero', 'titre': 'Re:Zero', 'tag': 'Mort & Boucles'},
    {'slug': 'kaguya_sama_love_is_war', 'titre': 'Kaguya-sama: Love Is War', 'tag': 'Duel Psychologique'},
  ];

  static const Map<String, List<Map<String, dynamic>>> _questionsDecouverte = {
    'one_piece': [
      {'q': 'Quel fruit du démon Monkey D. Luffy a-t-il mangé ?', 'c': ['Gomu Gomu no Mi', 'Mera Mera no Mi', 'Ope Ope no Mi', 'Gura Gura no Mi'], 'ok': 0},
      {'q': 'Combien de sabres Roronoa Zoro manie-t-il dans son style Santoryu ?', 'c': ['1 sabre', '2 sabres', '3 sabres', '4 sabres'], 'ok': 2},
      {'q': 'Quel est le nom du premier navire de l\'équipage au Chapeau de Paille ?', 'c': ['Thousand Sunny', 'Vogue Merry', 'Moby Dick', 'Oro Jackson'], 'ok': 1},
      {'q': 'Qui est le médecin de bord de l\'équipage de Luffy ?', 'c': ['Usopp', 'Franky', 'Tony Tony Chopper', 'Brook'], 'ok': 2},
      {'q': 'Comment s\'appelle le trésor légendaire laissé par Gol D. Roger ?', 'c': ['Le Grand Line', 'Le One Piece', 'Le Ponéglyphe', 'L\'All Blue'], 'ok': 1},
    ],
    'naruto': [
      {'q': 'Quel démon à queues est scellé en Naruto Uzumaki ?', 'c': ['Shukaku', 'Kurama (Kyûbi)', 'Gyûki', 'Matatabi'], 'ok': 1},
      {'q': 'Qui est le sensei de l\'équipe 7 au début de la série ?', 'c': ['Jiraiya', 'Kakashi Hatake', 'Might Guy', 'Asuma'], 'ok': 1},
      {'q': 'Quelle est la technique signature apprise par Naruto auprès de Jiraiya ?', 'c': ['Chidori', 'Rasengan', 'Amaterasu', 'Byakugan'], 'ok': 1},
      {'q': 'De quel clan Sasuke est-il issu ?', 'c': ['Clan Hyûga', 'Clan Senju', 'Clan Uchiha', 'Clan Nara'], 'ok': 2},
      {'q': 'Quel titre Naruto rêve-t-il d\'obtenir depuis son enfance ?', 'c': ['Kazekage', 'Mizukage', 'Hokage', 'Raikage'], 'ok': 2},
    ],
    'naruto_shippuden': [
      {'q': 'Quelle organisation criminelle traque les démons à queues ?', 'c': ['Anbu', 'Akatsuki', 'Racine', 'Taka'], 'ok': 1},
      {'q': 'Quel mode Naruto maîtrise-t-il au Mont Myôboku ?', 'c': ['Mode Ermite', 'Mode Susanoo', 'Mode Porte Céleste', 'Mode Karma'], 'ok': 0},
      {'q': 'Qui est le frère aîné de Sasuke Uchiha ?', 'c': ['Shisui', 'Obito', 'Itachi', 'Madara'], 'ok': 2},
      {'q': 'Quel personnage attaque le village avec les Six Chemins ?', 'c': ['Deidara', 'Pain', 'Sasori', 'Kakuzu'], 'ok': 1},
      {'q': 'Qui est le chef de l\'alliance des ninjas lors de la 4e Grande Guerre ?', 'c': ['Gaara (Commandant)', 'Kiba', 'Choji', 'Sai'], 'ok': 0},
    ],
    'jujutsu_kaisen': [
      {'q': 'Quel objet maudit Yuji Itadori avale-t-il au début de la série ?', 'c': ['Un sabre maudit', 'Un doigt de Sukuna', 'Un œil de fléau', 'Un parchemin'], 'ok': 1},
      {'q': 'Qui est le professeur le plus puissant de l\'école d\'exorcisme de Tokyo ?', 'c': ['Kento Nanami', 'Satoru Gojo', 'Suguru Geto', 'Aoi Todo'], 'ok': 1},
      {'q': 'Comment s\'appelle l\'extension du territoire de Satoru Gojo ?', 'c': ['Autel Démoniaque', 'Sphère de l\'Espace Infini', 'Jardin des Ombres', 'Cercueil de Fer'], 'ok': 1},
      {'q': 'Quel est le pouvoir héréditaire de Megumi Fushiguro ?', 'c': ['Les Dix Ombres', 'Le Pouvoir de l\'Infini', 'La Boogie Woogie', 'La Langue Maudite'], 'ok': 0},
      {'q': 'Qui est connu comme le Roi des Fléaux ?', 'c': ['Mahito', 'Jogo', 'Ryomen Sukuna', 'Hanami'], 'ok': 2},
    ],
    'demon_slayer': [
      {'q': 'Comment s\'appelle la petite sœur de Tanjiro Kamado ?', 'c': ['Kanao', 'Nezuko', 'Shinobu', 'Mitsuri'], 'ok': 1},
      {'q': 'Qui est le roi originel de tous les démons ?', 'c': ['Akaza', 'Kokushibo', 'Muzan Kibutsuji', 'Doma'], 'ok': 2},
      {'q': 'Quel souffle Tanjiro maîtrise-t-il en premier lors de sa formation ?', 'c': ['Souffle de la Foudre', 'Souffle de l\'Eau', 'Souffle de la Bête', 'Souffle du Vent'], 'ok': 1},
      {'q': 'Quel pourfendeur porte une tête de sanglier ?', 'c': ['Zenitsu Agatsuma', 'Inosuke Hashibira', 'Genya Shinazugawa', 'Muichiro Tokito'], 'ok': 1},
      {'q': 'Quel est le rang des neuf meilleurs pourfendeurs de l\'armée ?', 'c': ['Les Piliers', 'Les Capitaines', 'Les Empereurs', 'Les Gardiens'], 'ok': 0},
    ],
    'dragon_ball': [
      {'q': 'Combien de Dragon Balls faut-il réunir pour invoquer Shenron ?', 'c': ['5', '6', '7', '9'], 'ok': 2},
      {'q': 'Qui entraîne Son Goku et Krilin sur son île ?', 'c': ['Maître Karine', 'Tortue Géniale', 'Piccolo', 'Kami'], 'ok': 1},
      {'q': 'Quelle est l\'attaque énergétique emblématique de Goku ?', 'c': ['Final Flash', 'Makankosappo', 'Kamehameha', 'Galick Gun'], 'ok': 2},
      {'q': 'Comment s\'appelle le nuage magique sur lequel vole Goku ?', 'c': ['Nuage Kinto-Un', 'Nuage Nimbus Noir', 'Nuage Shenron', 'Nuage Kaio'], 'ok': 0},
      {'q': 'Quelle jeune inventrice rencontre Goku dès le premier épisode ?', 'c': ['Chichi', 'Bulma', 'Lunch', 'Videl'], 'ok': 1},
    ],
    'dragon_ball_z': [
      {'q': 'De quelle planète Son Goku est-il originaire ?', 'c': ['Namek', 'Vegeta', 'Terre', 'Yardrat'], 'ok': 1},
      {'q': 'Contre quel ennemi Goku se transforme-t-il en Super Saiyan pour la 1re fois ?', 'c': ['Cell', 'Freezer', 'Majin Buu', 'Broly'], 'ok': 1},
      {'q': 'Qui est le prince fier des Saiyans ?', 'c': ['Piccolo', 'Trunks', 'Vegeta', 'Gohan'], 'ok': 2},
      {'q': 'Quel guerrier vient du futur pour avertir de l\'arrivée des Cyborgs ?', 'c': ['Goten', 'Trunks du futur', 'Bardock', 'Raditz'], 'ok': 1},
      {'q': 'Quel fils de Goku bat Cell lors du Cell Game ?', 'c': ['Son Goten', 'Son Gohan', 'Trunks', 'Pan'], 'ok': 1},
    ],
    'attack_on_titan': [
      {'q': 'Comment s\'appelle le héros qui jure d\'exterminer tous les Titans ?', 'c': ['Armin Arlert', 'Eren Jäger', 'Jean Kirstein', 'Erwin Smith'], 'ok': 1},
      {'q': 'Quel mur est brisé en premier par le Titan Colossal ?', 'c': ['Mur Sina', 'Mur Rose', 'Mur Maria', 'Mur Shiganshina'], 'ok': 2},
      {'q': 'Quel capitaine est surnommé le soldat le plus fort de l\'humanité ?', 'c': ['Livaï Ackerman', 'Hansi Zoë', 'Connie Springer', 'Reiner Braun'], 'ok': 0},
      {'q': 'Quel corps d\'armée sort au-delà des murs pour explorer le monde ?', 'c': ['La Garnison', 'Les Brigades Spéciales', 'Le Bataillon d\'Exploration', 'La Garde Royale'], 'ok': 2},
      {'q': 'Quel est le point faible d\'un Titan classique ?', 'c': ['Le cœur', 'La nuque', 'Les genoux', 'Les yeux'], 'ok': 1},
    ],
    'bleach': [
      {'q': 'Comment s\'appelle le héros devenu Shinigami remplaçant ?', 'c': ['Renji Abarai', 'Ichigo Kurosaki', 'Uryû Ishida', 'Chad'], 'ok': 1},
      {'q': 'Qui transfère ses pouvoirs de Shinigami à Ichigo au tout début ?', 'c': ['Orihime Inoue', 'Rukia Kuchiki', 'Yoruichi', 'Rangiku'], 'ok': 1},
      {'q': 'Comment s\'appelle le sabre spirituel d\'un Shinigami ?', 'c': ['Bankai', 'Zanpakutô', 'Kido', 'Hollow'], 'ok': 1},
      {'q': 'Comment s\'appelle la seconde libération ultime d\'un Zanpakutô ?', 'c': ['Shikai', 'Bankai', 'Cero', 'Quincy'], 'ok': 1},
      {'q': 'Comment s\'appelle l\'attaque signature projetée par Zangetsu ?', 'c': ['Getsuga Tenshô', 'Senbonzakura', 'Kamehameha', 'Hado 90'], 'ok': 0},
    ],
    'hunter_x_hunter': [
      {'q': 'Pourquoi Gon Freecss passe-t-il l\'examen Hunter ?', 'c': ['Devenir roi', 'Retrouver son père Ging', 'Vaincre Hisoka', 'Venger son clan'], 'ok': 1},
      {'q': 'Qui est le meilleur ami de Gon, issu d\'une famille d\'assassins ?', 'c': ['Kurapika', 'Léolio', 'Kirua Zoldik', 'Kaito'], 'ok': 2},
      {'q': 'Comment s\'appelle l\'énergie vitale maîtrisée par les Hunters ?', 'c': ['Chakra', 'Nen', 'Haki', 'Reiatsu'], 'ok': 1},
      {'q': 'De quelle catégorie de Nen relève Gon Freecss ?', 'c': ['Renforcement', 'Spécialisation', 'Manipulation', 'Matérialisation'], 'ok': 0},
      {'q': 'Quelle brigade criminelle est traquée par Kurapika ?', 'c': ['L\'Akatsuki', 'La Brigade Fantôme', 'Les Chimera Ants', 'Les Zoldik'], 'ok': 1},
    ],
    'death_note': [
      {'q': 'Quel lycéen brillant ramasse le Death Note au début de la série ?', 'c': ['Near', 'Mello', 'Light Yagami', 'Teru Mikami'], 'ok': 2},
      {'q': 'Comment s\'appelle le Shinigami qui accompagne Light ?', 'c': ['Rem', 'Ryuk', 'Sidoh', 'Gelus'], 'ok': 1},
      {'q': 'Quel fruit Ryuk adore-t-il manger dans le monde des humains ?', 'c': ['Des oranges', 'Des pommes', 'Des raisins', 'Des fraises'], 'ok': 1},
      {'q': 'Quel pseudonyme utilise le plus grand détective du monde qui traque Kira ?', 'c': ['K', 'L', 'X', 'W'], 'ok': 1},
      {'q': 'Que faut-il connaître d\'une personne pour que le Death Note fonctionne ?', 'c': ['Sa date de naissance', 'Son nom et son visage', 'Son groupe sanguin', 'Son adresse'], 'ok': 1},
    ],
    'my_hero_academia': [
      {'q': 'Quel est le nom civil de Deku ?', 'c': ['Katsuki Bakugo', 'Izuku Midoriya', 'Shoto Todoroki', 'Eijiro Kirishima'], 'ok': 1},
      {'q': 'Quel célèbre héros transmet le One For All à Izuku ?', 'c': ['Endeavor', 'All Might', 'Hawks', 'Eraser Head'], 'ok': 1},
      {'q': 'Comment appelle-t-on les super-pouvoirs dans cet univers ?', 'c': ['Des Alters', 'Des Stands', 'Des Fruits', 'Des Souffles'], 'ok': 0},
      {'q': 'Dans quel prestigieux lycée héroïque étudie la seconde A ?', 'c': ['Shiketsu', 'Yuei (U.A.)', 'Ketsubutsu', 'Tokyo High'], 'ok': 1},
      {'q': 'Quel pouvoir possède Katsuki Bakugo ?', 'c': ['Glace et feu', 'Explosions', 'Gravité zéro', 'Foudre'], 'ok': 1},
    ],
  };

  // Questions decouverte multi-animes pour les oeuvres sans banque dediee
  static const List<Map<String, dynamic>> _questionsUniverselles = [
    {'q': 'Dans Otaku Verse, quel bonus se déclenche quand tu réponds juste en moins de 2 secondes ?', 'c': ['HAYA!! (-18/-23 PV)', 'Auto-Faute (-5 PV)', 'Éclipse', 'Brouillard'], 'ok': 0},
    {'q': 'Au bout de combien de bonnes réponses consécutives déclenches-tu un COMBO ×3 ?', 'c': ['2 réponses', '3 réponses (multiples de 3)', '5 réponses', '10 réponses'], 'ok': 1},
    {'q': 'Combien de PV chaque combattant possède-t-il au départ d\'un duel officiel ?', 'c': ['100 PV', '200 PV', '350 PV', '500 PV'], 'ok': 2},
    {'q': 'Que se passe-t-il quand tu donnes une mauvaise réponse ou dépasses le chrono ?', 'c': ['Auto-Faute (-5 PV)', 'Tu gagnes +10 PV', 'Rien ne se passe', 'Match nul immédiat'], 'ok': 0},
    {'q': 'Quelle monnaie gratuite sert aux frais d\'arène et aux options avant-match ?', 'c': ['Les Otaku Coins (OC)', 'L\'XP (jamais dépensée)', 'Les Points Division', 'Les Tickets'], 'ok': 0},
  ];

  List<Map<String, dynamic>> get _questionsCourantes =>
      _questionsDecouverte[_animeSlug] ?? _questionsUniverselles;

  void _demarrerCombatDecouverte() {
    setState(() {
      _etape = 2;
      _qIndex = 0;
      _pvJoueur = 350;
      _pvBot = 120;
      _combo = 0;
      _badgeAction = null;
      _explicationMecanique = 'Astuce : réponds juste en moins de 2 secondes pour déclencher HAYA!! (-23 PV) !';
      _repondu = false;
      _choixSelectionne = null;
      _qStart = DateTime.now();
    });
  }

  void _repondre(int index) {
    if (_repondu) return;
    final q = _questionsCourantes[_qIndex];
    final bool correct = index == (q['ok'] as int);
    final elapsedMs = DateTime.now().difference(_qStart).inMilliseconds;
    final bool haya = correct && elapsedMs < 2000;

    setState(() {
      _repondu = true;
      _choixSelectionne = index;
      if (correct) {
        _combo++;
        final bool isCombo3 = _combo > 0 && _combo % 3 == 0;
        int dmg = 20;
        if (isCombo3 && haya) {
          dmg = 41;
          _badgeAction = 'COMBO ×3 + HAYA!! (-41 PV)';
          _explicationMecanique = '3 bonnes réponses d\'affilée sous 2s : -36 PV + -5 PV Auto-faute adverse !';
          _badgeCouleur = const Color(0xFFFFD700);
        } else if (isCombo3) {
          dmg = 35;
          _badgeAction = 'COMBO ×3!! (-35 PV)';
          _explicationMecanique = 'Série multiple de 3 réussie : -30 PV + -5 PV Auto-faute adverse !';
          _badgeCouleur = const Color(0xFFFFD700);
        } else if (haya) {
          dmg = 23;
          _badgeAction = 'HAYA!! COUP ÉCLAIR (-23 PV)';
          _explicationMecanique = 'Réponse juste en moins de 2 secondes : -18 PV + -5 PV Auto-faute adverse !';
          _badgeCouleur = const Color(0xFF3FFFB0);
        } else {
          dmg = 20;
          _badgeAction = 'FRAPPE RÉUSSIE (-20 PV)';
          _explicationMecanique = 'Bonne réponse (-15 PV) + Auto-faute adverse (-5 PV) = -20 PV !';
          _badgeCouleur = OtakuColors.pvHaut;
        }
        _pvBot = (_pvBot - dmg).clamp(0, 120);
      } else {
        _combo = 0;
        _pvJoueur = (_pvJoueur - 17).clamp(50, 350);
        _badgeAction = 'AUTO-FAUTE (-5 PV) · RIPOSTE (-12 PV)';
        _explicationMecanique = 'Une erreur inflige -5 PV d\'Auto-faute. Enchaîne 3 bonnes réponses pour le Combo ×3 !';
        _badgeCouleur = OtakuColors.error;
      }
    });

    // Rythme ralenti (1,8s) pour laisser le temps de lire et comprendre les effets (Test 4)
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final isLast = _qIndex >= _questionsCourantes.length - 1 || _pvBot <= 0;
      if (isLast) {
        setState(() {
          _pvBot = 0;
          _badgeAction = 'K.O. · KECCHAKU!!';
          _explicationMecanique = 'Victoire par K.O. ! Tu remportes ta récompense d\'accueil : +300 OC et +100 XP.';
          _badgeCouleur = const Color(0xFFFFD700);
        });
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (!mounted) return;
          setState(() => _etape = 3);
        });
      } else {
        setState(() {
          _qIndex++;
          _repondu = false;
          _choixSelectionne = null;
          _badgeAction = null;
          _qStart = DateTime.now();
        });
      }
    });
  }

  Future<void> _terminerEtSauvegarder() async {
    await _tutoService.markPhaseADoneLocally(
      favoriteAnimeSlug: _animeSlug,
      wantsStarterGoodie: _goodieAchete,
    );
    widget.onTermineVersInscription();
  }

  /// Ferme la Phase A et renvoie directement vers l'ecran de connexion
  Future<void> _allerVersConnexion() async {
    await _tutoService.markPhaseADoneLocally(
      favoriteAnimeSlug: _animeSlug,
      wantsStarterGoodie: false,
    );
    widget.onDejaUnCompte();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: _etape == 1
              ? _buildEtapeA1ChoixAnime()
              : _etape == 2
                  ? _buildEtapeA2CombatDecouverte()
                  : _buildEtapeA3RecompenseGoodies(),
        ),
      ),
    );
  }

  // === ETAPE A1 : CHOIX ANIME FAVORI (21 OEUVRES REELLES) ===
  Widget _buildEtapeA1ChoixAnime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logos/logo_icone.png',
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.flash_on_rounded, color: OtakuColors.accent),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BIENVENUE DANS OTAKU VERSE', style: OtakuTypo.headlineLarge.copyWith(fontSize: 18)),
                  Text(
                    'Étape 1/3 : Choisis parmi les 21 œuvres officielles pour ton combat découverte (2 min)',
                    style: OtakuTypo.bodySmall.copyWith(fontSize: 11, color: OtakuColors.textMuted),
                  ),
                ],
              ),
            ),
            if (!widget.dejaConnecte)
              TextButton(
                onPressed: () async {
                  await _tutoService.markPhaseADoneLocally(favoriteAnimeSlug: _animeSlug, wantsStarterGoodie: false);
                  widget.onDejaUnCompte();
                },
                child: Text('J\'ai déjà un compte', style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.accent)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _animes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final a = _animes[i];
              final sel = _animeSlug == a['slug'];
              return GestureDetector(
                onTap: () => setState(() {
                  _animeSlug = a['slug']!;
                  _animeTitre = a['titre']!;
                }),
                child: Container(
                  width: 175,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel ? OtakuColors.accent.withValues(alpha: 0.18) : OtakuColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? OtakuColors.accent : OtakuColors.border, width: sel ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 36,
                        color: sel ? const Color(0xFFFFD700) : OtakuColors.accent,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        a['titre']!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: OtakuTypo.headlineSmall.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a['tag']!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: OtakuColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _demarrerCombatDecouverte,
            child: Text(
              'LANCER LE COMBAT DÉCOUVERTE ($_animeTitre)',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  // === ETAPE A2 : COMBAT DECOUVERTE 5 QUESTIONS ===
  Widget _buildEtapeA2CombatDecouverte() {
    final q = _questionsCourantes[_qIndex];
    final choix = List<String>.from(q['c'] as List);
    final okIdx = q['ok'] as int;

    return Column(
      children: [
        // Barres PV joueur vs Bot
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOI  ($_pvJoueur / 350 PV)', style: OtakuTypo.hud.copyWith(fontSize: 11, color: OtakuColors.pvHaut)),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _pvJoueur / 350,
                    minHeight: 8,
                    backgroundColor: OtakuColors.border,
                    valueColor: const AlwaysStoppedAnimation(OtakuColors.pvHaut),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  Text('Q${_qIndex + 1}/5', style: OtakuTypo.headlineSmall.copyWith(fontSize: 14, color: const Color(0xFFFFD700))),
                  Text(_animeTitre, style: OtakuTypo.bodySmall.copyWith(fontSize: 9, color: OtakuColors.accent)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('BOT AKINA  ($_pvBot / 120 PV)', style: OtakuTypo.hud.copyWith(fontSize: 11, color: OtakuColors.error)),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _pvBot / 120,
                    minHeight: 8,
                    backgroundColor: OtakuColors.border,
                    valueColor: const AlwaysStoppedAnimation(OtakuColors.error),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Banniere d'impact agrandie et lisible (Test 4)
        if (_badgeAction != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _badgeCouleur.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _badgeCouleur, width: 1.8),
            ),
            child: Column(
              children: [
                Text(
                  _badgeAction!,
                  textAlign: TextAlign.center,
                  style: OtakuTypo.impact.copyWith(fontSize: 22, color: _badgeCouleur, letterSpacing: 1.2),
                ),
                if (_explicationMecanique != null)
                  Text(
                    _explicationMecanique!,
                    textAlign: TextAlign.center,
                    style: OtakuTypo.bodySmall.copyWith(fontSize: 11, color: Colors.white),
                  ),
              ],
            ),
          )
        else if (_explicationMecanique != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              _explicationMecanique!,
              textAlign: TextAlign.center,
              style: OtakuTypo.bodySmall.copyWith(fontSize: 11, color: OtakuColors.textSecondary),
            ),
          ),

        // Carte question
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: OtakuColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.45)),
          ),
          child: Text(
            q['q'] as String,
            textAlign: TextAlign.center,
            style: OtakuTypo.headlineSmall.copyWith(fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),

        // 4 choix en grille 2x2
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 10,
            childAspectRatio: 4.2,
            children: List.generate(choix.length, (idx) {
              Color border = OtakuColors.border;
              Color bg = OtakuColors.surface;
              if (_repondu) {
                if (idx == okIdx) {
                  border = OtakuColors.pvHaut;
                  bg = OtakuColors.pvHaut.withValues(alpha: 0.2);
                } else if (idx == _choixSelectionne) {
                  border = OtakuColors.error;
                  bg = OtakuColors.error.withValues(alpha: 0.2);
                }
              }
              return GestureDetector(
                onTap: () => _repondre(idx),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border, width: 1.4),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${String.fromCharCode(65 + idx)}. ${choix[idx]}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: OtakuTypo.bodySmall.copyWith(fontSize: 12, color: Colors.white),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // === ETAPE A3 : RECOMPENSE +300 OC +100 XP & 1ER GOODIES (300 OC) ===
  Widget _buildEtapeA3RecompenseGoodies() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('K.O. · KECCHAKU!', style: OtakuTypo.headlineLarge.copyWith(fontSize: 22, color: const Color(0xFFFFD700))),
              const SizedBox(height: 6),
              Text('Récompense d\'accueil : +300 OC & +100 XP', style: OtakuTypo.hud.copyWith(fontSize: 12, color: OtakuColors.pvHaut)),
              const SizedBox(height: 12),
              Expanded(
                child: SafeAvatarBox(
                  assetPath: 'assets/images/skins/skin_mazu.png',
                  borderColor: _goodieAchete ? OtakuColors.pvHaut : const Color(0xFFFFD700),
                  borderRadius: 16,
                  topPadding: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _goodieAchete ? 'Mazú (Goodies Départ) ÉQUIPÉ !' : 'Ton 1er Goodies : Mazú (300 OC)',
                style: OtakuTypo.headlineSmall.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: OtakuColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: OtakuColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TON PORTEFEUILLE D\'ACCUEIL', style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.textMuted)),
                      const SizedBox(height: 6),
                      Text('Solde : $_ocVirtuel OC  |  +100 XP (Niveau 2)', style: OtakuTypo.hud.copyWith(fontSize: 14, color: OtakuColors.pvMoyen)),
                      const SizedBox(height: 6),
                      Text(
                        'Dépense tes 300 OC offerts pour équiper ton premier Goodies, puis sauvegarde ton compte pour garder ta progression !',
                        style: OtakuTypo.bodySmall.copyWith(fontSize: 11, color: OtakuColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!_goodieAchete)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () => setState(() {
                      _ocVirtuel = 0;
                      _goodieAchete = true;
                    }),
                    child: const Text('ACHETER & ÉQUIPER MON 1ER GOODIES (300 OC)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OtakuColors.pvHaut,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: _terminerEtSauvegarder,
                    child: Text(
                      widget.dejaConnecte
                          ? 'RÉCLAMER & ENTRER DANS LE VERSE'
                          : 'SAUVEGARDER MON COMPTE & ENTRER DANS LE VERSE',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 6),
                if (!_goodieAchete)
                  TextButton(
                    onPressed: _terminerEtSauvegarder,
                    child: Text(
                      widget.dejaConnecte ? 'Garder mes 300 OC et continuer' : 'Garder mes 300 OC et créer mon compte',
                      style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted),
                    ),
                  ),
                if (!widget.dejaConnecte)
                  TextButton(
                    onPressed: _allerVersConnexion,
                    child: Text(
                      'J\'ai déjà un compte · Se connecter',
                      style: OtakuTypo.label.copyWith(fontSize: 11, color: OtakuColors.accent),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
