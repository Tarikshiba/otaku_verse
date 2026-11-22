import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/rank_badge.dart';
import 'tutorial_service.dart';

/// === TUTORIEL PHASE A : DECOUVERTE IMMEDIATE EN 2 MINUTES (TUTO-01 §4.1) ===
/// Style eFootball avant la creation de compte :
/// - Etape A1 : Carrousel visuel de l'anime favori
/// - Etape A2 : Combat decouverte de 5 questions avec animations Haya!!, Combo x3 et KECCHAKU!
/// - Etape A3 : Recompense +300 OC & +100 XP + achat guide du 1er Goodies (300 OC) -> Sauvegarder mon compte
class TutorialPhaseAPage extends StatefulWidget {
  final VoidCallback onTermineVersInscription;
  final VoidCallback onDejaUnCompte;

  const TutorialPhaseAPage({
    super.key,
    required this.onTermineVersInscription,
    required this.onDejaUnCompte,
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
  int _pvBot = 100;
  int _combo = 0;
  DateTime _qStart = DateTime.now();
  String? _badgeAction;
  Color _badgeCouleur = OtakuColors.accent;
  bool _repondu = false;
  int? _choixSelectionne;

  // Etape A3 : achat guide du 1er Goodies (300 OC)
  int _ocVirtuel = 300;
  bool _goodieAchete = false;

  static const List<Map<String, String>> _animes = [
    {'slug': 'one_piece', 'titre': 'One Piece', 'tag': 'Grand Line & Haki'},
    {'slug': 'naruto', 'titre': 'Naruto', 'tag': 'Konoha & Shinobi'},
    {'slug': 'jujutsu_kaisen', 'titre': 'Jujutsu Kaisen', 'tag': 'Exorcisme & Territoires'},
    {'slug': 'demon_slayer', 'titre': 'Demon Slayer', 'tag': 'Souffles & Piliers'},
    {'slug': 'dragon_ball', 'titre': 'Dragon Ball', 'tag': 'Saiyans & Tournois'},
    {'slug': 'solo_leveling', 'titre': 'Solo Leveling', 'tag': 'Chasseurs & Ombres'},
  ];

  static const Map<String, List<Map<String, dynamic>>> _questionsDecouverte = {
    'one_piece': [
      {'q': 'Quel fruit du demon Monkey D. Luffy a-t-il mange ?', 'c': ['Gomu Gomu no Mi', 'Mera Mera no Mi', 'Ope Ope no Mi', 'Gura Gura no Mi'], 'ok': 0},
      {'q': 'Combien de sabres Roronoa Zoro manie-t-il dans son style Santoryu ?', 'c': ['1 sabre', '2 sabres', '3 sabres', '4 sabres'], 'ok': 2},
      {'q': 'Quel est le nom du premier navire de l\'equipage au Chapeau de Paille ?', 'c': ['Thousand Sunny', 'Vogue Merry', 'Moby Dick', 'Oro Jackson'], 'ok': 1},
      {'q': 'Qui est le medecin de bord de l\'equipage de Luffy ?', 'c': ['Usopp', 'Franky', 'Tony Tony Chopper', 'Brook'], 'ok': 2},
      {'q': 'Comment s\'appelle le tresor legendaire laisse par Gol D. Roger ?', 'c': ['Le Grand Line', 'Le One Piece', 'Le Ponéglyphe', 'L\'All Blue'], 'ok': 1},
    ],
    'naruto': [
      {'q': 'Quel demon a queues est scelle en Naruto Uzumaki ?', 'c': ['Shukaku', 'Kurama (Kyubi)', 'Gyuki', 'Matatabi'], 'ok': 1},
      {'q': 'Qui est le sensei de l\'equipe 7 a Konoha ?', 'c': ['Jiraiya', 'Kakashi Hatake', 'Might Guy', 'Asuma'], 'ok': 1},
      {'q': 'Quelle est la technique signature creee par le 4e Hokage et apprise par Naruto ?', 'c': ['Chidori', 'Rasengan', 'Amaterasu', 'Byakugan'], 'ok': 1},
      {'q': 'De quel clan Sasuke est-il issu ?', 'c': ['Clan Hyuga', 'Clan Senju', 'Clan Uchiha', 'Clan Nara'], 'ok': 2},
      {'q': 'Quel titre Naruto reve-t-il d\'obtenir depuis son enfance ?', 'c': ['Kazekage', 'Mizukage', 'Hokage', 'Raikage'], 'ok': 2},
    ],
    'jujutsu_kaisen': [
      {'q': 'Quel objet maudit Yuji Itadori avale-t-il au debut de la serie ?', 'c': ['Un sabre maudit', 'Un doigt de Sukuna', 'Un oeil de fleau', 'Un parchemin'], 'ok': 1},
      {'q': 'Qui est le professeur le plus puissant de l\'ecole d\'exorcisme de Tokyo ?', 'c': ['Kento Nanami', 'Satoru Gojo', 'Suguru Geto', 'Aoi Todo'], 'ok': 1},
      {'q': 'Comment s\'appelle l\'extension du territoire de Satoru Gojo ?', 'c': ['Autel Demuniaque', 'Sphere de l\'Espace Infini', 'Jardin des Ombres', 'Cercueil de Fer'], 'ok': 1},
      {'q': 'Quel est le pouvoir hereditaire de Megumi Fushiguro ?', 'c': ['Les Dix Ombres', 'Le Pouvoir de l\'Infini', 'La Boogie Woogie', 'La Langue Maudite'], 'ok': 0},
      {'q': 'Qui est connu comme le Roi des Fleaux ?', 'c': ['Mahito', 'Jogo', 'Ryomen Sukuna', 'Hanami'], 'ok': 2},
    ],
    'demon_slayer': [
      {'q': 'Comment s\'appelle la petite soeur de Tanjiro Kamado ?', 'c': ['Kanao', 'Nezuko', 'Shinobu', 'Mitsuri'], 'ok': 1},
      {'q': 'Qui est le roi originel de tous les demons ?', 'c': ['Akaza', 'Kokushibo', 'Muzan Kibutsuji', 'Doma'], 'ok': 2},
      {'q': 'Quel souffle Tanjiro maitrise-t-il en premier lors de sa formation ?', 'c': ['Souffle de la Foudre', 'Souffle de l\'Eau', 'Souffle de la Bete', 'Souffle du Vent'], 'ok': 1},
      {'q': 'Quel pourfendeur porte une tete de sanglier ?', 'c': ['Zenitsu Agatsuma', 'Inosuke Hashibira', 'Genya Shinazugawa', 'Muichiro Tokito'], 'ok': 1},
      {'q': 'Quel est le rang des neuf meilleurs pourfendeurs de l\'armee ?', 'c': ['Les Piliers', 'Les Capitaines', 'Les Empereurs', 'Les Gardiens'], 'ok': 0},
    ],
    'dragon_ball': [
      {'q': 'Combien de Dragon Balls faut-il reunir pour invoquer Shenron ?', 'c': ['5', '6', '7', '9'], 'ok': 2},
      {'q': 'De quelle planete Son Goku est-il originaire ?', 'c': ['Namek', 'Vegeta', 'Terre', 'Yardrat'], 'ok': 1},
      {'q': 'Quelle est l\'attaque energetique emblematique de Goku ?', 'c': ['Final Flash', 'Makankosappo', 'Kamehameha', 'Galick Gun'], 'ok': 2},
      {'q': 'Contre quel ennemi Goku se transforme-t-il en Super Saiyan pour la 1re fois ?', 'c': ['Cell', 'Freezer', 'Majin Buu', 'Broly'], 'ok': 1},
      {'q': 'Qui est le rival Saiyan et prince de sa race ?', 'c': ['Piccolo', 'Trunks', 'Vegeta', 'Gohan'], 'ok': 2},
    ],
    'solo_leveling': [
      {'q': 'Quel etait le rang initial de Sung Jin-Woo avant son eveil ?', 'c': ['Rang S', 'Rang B', 'Rang E', 'Rang C'], 'ok': 2},
      {'q': 'Quel mot cle Jin-Woo prononce-t-il pour extraire une ombre ?', 'c': ['Reveille-toi', 'Erige-toi (Arise)', 'Obeis', 'Frappe'], 'ok': 1},
      {'q': 'Quel est le nom du premier chevalier d\'ombre rouge recrute par Jin-Woo ?', 'c': ['Tank', 'Iron', 'Igris', 'Beru'], 'ok': 2},
      {'q': 'Quelle classe secrete Jin-Woo obtient-il apres la quete de changement de classe ?', 'c': ['Assassin', 'Monarque des Ombres (Necromancien)', 'Paladin', 'Archimage'], 'ok': 1},
      {'q': 'Sur quelle ile se deroule le raid contre le Roi des Fourmis ?', 'c': ['Ile de Jeju', 'Ile d\'Okinawa', 'Ile Rouge', 'Ile du Nord'], 'ok': 0},
    ],
  };

  List<Map<String, dynamic>> get _questionsCourantes =>
      _questionsDecouverte[_animeSlug] ?? _questionsDecouverte['one_piece']!;

  void _demarrerCombatDecouverte() {
    setState(() {
      _etape = 2;
      _qIndex = 0;
      _pvJoueur = 350;
      _pvBot = 100;
      _combo = 0;
      _badgeAction = null;
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
    final bool haya = correct && elapsedMs < 2500;

    setState(() {
      _repondu = true;
      _choixSelectionne = index;
      if (correct) {
        _combo++;
        int dmg = 20;
        if (_combo >= 3) {
          dmg = 35;
          _badgeAction = haya ? 'COMBO x$_combo + HAYA!! (-36 PV)' : 'COMBO x$_combo (-35 PV)';
          _badgeCouleur = const Color(0xFFFFD700);
        } else if (haya) {
          dmg = 22;
          _badgeAction = 'HAYA!! COUP ECLAIR (-22 PV)';
          _badgeCouleur = OtakuColors.accent;
        } else {
          _badgeAction = 'FRAPPE REUSSIE (-20 PV)';
          _badgeCouleur = OtakuColors.pvHaut;
        }
        _pvBot = (_pvBot - dmg).clamp(0, 100);
      } else {
        _combo = 0;
        _pvJoueur = (_pvJoueur - 15).clamp(50, 350);
        _badgeAction = 'AUTO-FAUTE ! REPRENDS LE RYTHME';
        _badgeCouleur = OtakuColors.error;
      }
    });

    Future.delayed(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      final isLast = _qIndex >= _questionsCourantes.length - 1 || _pvBot <= 0;
      if (isLast) {
        setState(() {
          _pvBot = 0;
          _badgeAction = 'K.O. — KECCHAKU!!';
          _badgeCouleur = const Color(0xFFFFD700);
        });
        Future.delayed(const Duration(milliseconds: 900), () {
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

  // === ETAPE A1 : CHOIX ANIME FAVORI ===
  Widget _buildEtapeA1ChoixAnime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logos/logo_icone.jpg',
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
                  Text('Etape 1/3 : Choisis ton anime favori pour ton premier combat (2 min)', style: OtakuTypo.bodySmall.copyWith(fontSize: 11, color: OtakuColors.textMuted)),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                await _tutoService.markPhaseADoneLocally(favoriteAnimeSlug: _animeSlug, wantsStarterGoodie: false);
                widget.onDejaUnCompte();
              },
              child: Text('J\'ai deja un compte', style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.accent)),
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
                        size: 38,
                        color: sel ? const Color(0xFFFFD700) : OtakuColors.accent,
                      ),
                      const SizedBox(height: 10),
                      Text(a['titre']!, textAlign: TextAlign.center, style: OtakuTypo.headlineSmall.copyWith(fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(a['tag']!, textAlign: TextAlign.center, style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted)),
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
              'LANCER LE COMBAT DECOUVERTE ($_animeTitre)',
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
              child: Text('Q${_qIndex + 1}/5', style: OtakuTypo.headlineSmall.copyWith(fontSize: 14, color: const Color(0xFFFFD700))),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('BOT AKINA  ($_pvBot / 100 PV)', style: OtakuTypo.hud.copyWith(fontSize: 11, color: OtakuColors.error)),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _pvBot / 100,
                    minHeight: 8,
                    backgroundColor: OtakuColors.border,
                    valueColor: const AlwaysStoppedAnimation(OtakuColors.error),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_badgeAction != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _badgeCouleur.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _badgeCouleur),
            ),
            child: Text(_badgeAction!, style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: _badgeCouleur)),
          ),

        // Carte question
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: OtakuColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.45)),
          ),
          child: Text(
            q['q'] as String,
            textAlign: TextAlign.center,
            style: OtakuTypo.headlineSmall.copyWith(fontSize: 15),
          ),
        ),
        const SizedBox(height: 10),

        // 4 choix en grille 2x2
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 10,
            childAspectRatio: 4.0,
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
              Text('K.O. — KECCHAKU!', style: OtakuTypo.headlineLarge.copyWith(fontSize: 22, color: const Color(0xFFFFD700))),
              const SizedBox(height: 6),
              Text('Recompense d\'accueil : +300 OC & +100 XP', style: OtakuTypo.hud.copyWith(fontSize: 12, color: OtakuColors.pvHaut)),
              const SizedBox(height: 12),
              Expanded(
                child: SafeAvatarBox(
                  assetPath: 'assets/images/skins/skin_ninja.png',
                  borderColor: _goodieAchete ? OtakuColors.pvHaut : const Color(0xFFFFD700),
                  borderRadius: 16,
                  topPadding: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _goodieAchete ? 'Ninja de Konoha EQUIPE !' : 'Ton 1er Goodies : Ninja de Konoha (300 OC)',
                style: OtakuTypo.headlineSmall.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 5,
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
                      'Depense tes 300 OC offerts pour equiper gratuitement ton premier Goodies, puis sauvegarde ton compte pour garder ta progression !',
                      style: OtakuTypo.bodySmall.copyWith(fontSize: 11, color: OtakuColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!_goodieAchete)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => setState(() {
                    _ocVirtuel = 0;
                    _goodieAchete = true;
                  }),
                  child: const Text('ACHETER & EQUIPER MON 1ER GOODIES (300 OC)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OtakuColors.pvHaut,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _terminerEtSauvegarder,
                  child: const Text('SAUVEGARDER MON COMPTE & ENTRER DANS LE VERSE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              const SizedBox(height: 8),
              if (!_goodieAchete)
                TextButton(
                  onPressed: _terminerEtSauvegarder,
                  child: Text('Garder mes 300 OC et creer mon compte', style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
