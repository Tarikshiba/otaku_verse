import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'skin_model.dart';
import 'skin_service.dart';
import 'monetisation_v4_service.dart';

/// Ecran Boutique V4 — 4 categories : Skins, Articles & Coffres, Booster XP & Pub, Pass & Coins.
/// La Collection (skins possedes) reste accessible depuis le Profil.
class BoutiqueScreen extends StatefulWidget {
  final bool showBack;
  final int initialTab;
  const BoutiqueScreen({super.key, this.showBack = false, this.initialTab = 0});

  @override
  State<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends State<BoutiqueScreen> {
  final _skinService = SkinService();
  final _v4Service = MonetisationV4Service();
  List<Skin> _skins = [];
  Map<String, dynamic> _portefeuille = {
    'verseCoins': 100,
    'passPremium': false,
    'doubleXpActif': false,
    'minutesBoostRestantes': 0,
    'articlesPossedes': <String>[],
  };
  bool _chargement = true;
  late int _tabActive;
  String? _message;

  @override
  void initState() {
    super.initState();
    _tabActive = widget.initialTab;
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      await _skinService.donnerSkinGratuit();
      final results = await Future.wait([
        _skinService.tousLesSkins(),
        _v4Service.recupererPortefeuille(),
      ]);
      if (mounted) {
        setState(() {
          _skins = results[0] as List<Skin>;
          _portefeuille = results[1] as Map<String, dynamic>;
          _chargement = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  List<Skin> get _skinsAchetables => _skins.where((s) => !s.owned).toList();

  @override
  Widget build(BuildContext context) {
    final int verseCoins = _portefeuille['verseCoins'] as int? ?? 100;
    final bool passPremium = _portefeuille['passPremium'] == true;
    final bool doubleXpActif = _portefeuille['doubleXpActif'] == true;
    final int minsBoost = _portefeuille['minutesBoostRestantes'] as int? ?? 0;

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec compteur Verse Coins et badge Pass Premium (V4)
              Row(
                children: [
                  if (widget.showBack) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: OtakuColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: OtakuColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: OtakuColors.textPrimary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text('BOUTIQUE', style: OtakuTypo.headlineLarge.copyWith(fontSize: 20)),
                  const Spacer(),
                  if (doubleXpActif) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: Text('2X XP ($minsBoost m)', style: OtakuTypo.label.copyWith(fontSize: 9, color: Colors.greenAccent)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (passPremium) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Text('PASS PREMIUM', style: OtakuTypo.label.copyWith(fontSize: 9, color: Colors.amber)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: () => setState(() => _tabActive = 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('$verseCoins COINS', style: OtakuTypo.hud.copyWith(fontSize: 11, color: Colors.amber)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Categories V4
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTab('Skins', 0, Icons.person_rounded),
                    const SizedBox(width: 8),
                    _buildTab('Articles & Coffres', 1, Icons.shopping_bag_rounded),
                    const SizedBox(width: 8),
                    _buildTab('Booster XP & Pub', 2, Icons.bolt_rounded),
                    const SizedBox(width: 8),
                    _buildTab('Pass Premium & Coins', 3, Icons.workspace_premium_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              if (_message != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: OtakuColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_message!, style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.accent)),
                ),

              Expanded(child: _buildContenu()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContenu() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: OtakuColors.accent));
    }

    switch (_tabActive) {
      case 0:
        final skins = _skinsAchetables;
        if (skins.isEmpty) {
          return Center(child: Text('Tu as tout debloque !', style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted)));
        }
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: skins.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _buildSkinCard(skins[i]),
        );
      case 1:
        return _buildArticlesEtCoffresTab();
      case 2:
        return _buildBoostersEtPubTab();
      case 3:
        return _buildPassEtCoinsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Onglet 1 : Boutique cosmétique (non Pay-to-Win) et Coffres mystères (Roadmap 11.4 & 11.5)
  Widget _buildArticlesEtCoffresTab() {
    final List<String> possedes = (_portefeuille['articlesPossedes'] as List<String>?) ?? [];
    final items = [
      {
        'id': 'coffre_mystere',
        'nom': 'Coffre Mystère Otaku',
        'desc': 'Tirage aléatoire garanti : entre +150 XP et +400 XP.',
        'cout': 200,
        'estCoffre': true,
      },
      {
        'id': 'cadre_neon_shonen',
        'nom': 'Cadre de Profil : Shonen Jump',
        'desc': 'Bordure cosmétique animée autour de ton avatar en duel.',
        'cout': 150,
        'estCoffre': false,
      },
      {
        'id': 'effet_ko_eclairs',
        'nom': 'Effet K.O. : Éclairs du Haki',
        'desc': 'Animation visuelle spéciale lors d\'une victoire par K.O.',
        'cout': 250,
        'estCoffre': false,
      },
      {
        'id': 'titre_seigneur_verse',
        'nom': 'Titre Cosmétique : Seigneur du Verse',
        'desc': 'Titre affiché sous ton pseudo dans les salons multijoueurs.',
        'cout': 300,
        'estCoffre': false,
      },
    ];

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final it = items[index];
        final String id = it['id'] as String;
        final bool estCoffre = it['estCoffre'] == true;
        final bool dejaPossede = !estCoffre && possedes.contains(id);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: OtakuColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: estCoffre ? Colors.amber.withValues(alpha: 0.5) : OtakuColors.glassBorder),
          ),
          child: Row(
            children: [
              Icon(
                estCoffre ? Icons.inventory_2_rounded : Icons.auto_awesome_rounded,
                color: estCoffre ? Colors.amber : OtakuColors.accent,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it['nom'] as String, style: OtakuTypo.headlineSmall.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(it['desc'] as String, style: OtakuTypo.bodySmall.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (dejaPossede)
                const Text('POSSÉDÉ', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11))
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: estCoffre ? Colors.amber[800] : OtakuColors.accent),
                  onPressed: () async {
                    try {
                      final msg = await _v4Service.acheterArticleBoutique(
                        articleId: id,
                        nom: it['nom'] as String,
                        coutCoins: it['cout'] as int,
                        estCoffre: estCoffre,
                      );
                      setState(() => _message = msg);
                      await _charger();
                    } catch (e) {
                      setState(() => _message = e.toString().replaceAll('Exception: ', ''));
                    }
                  },
                  child: Text('${it['cout']} COINS', style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Onglet 2 : Publicités récompensées opt-in (11.2) et Boosters de confort (11.4)
  Widget _buildBoostersEtPubTab() {
    return ListView(
      children: [
        // Publicité récompensée opt-in (Roadmap 11.2 : Double XP 15 min + 30 Coins, jamais en plein duel)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: OtakuColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.play_circle_fill_rounded, color: Colors.greenAccent, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PUBLICITÉ RÉCOMPENSÉE (OPT-IN)', style: OtakuTypo.headlineSmall.copyWith(color: Colors.greenAccent, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      'Regarde un spot de 5s -> Double XP pendant 15 min + 30 Verse Coins gratuits (max 1 pub / 3 quiz).',
                      style: OtakuTypo.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                onPressed: _simulerVisionnagePub,
                child: const Text('REGARDER', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
        // Booster Double XP 60 minutes
        _buildBoosterItem(
          id: 'booster_xp_60m',
          nom: 'Booster Double XP (60 minutes)',
          desc: 'Double tes gains d\'XP sur tous les quiz pendant 1 heure + 150 XP immédiats.',
          cout: 120,
          xpBonus: 150,
          minutesDoubleXp: 60,
        ),
        // Slot de défi supplémentaire (Roadmap 11.4)
        _buildBoosterItem(
          id: 'slot_defi_supp',
          nom: 'Slot de Défi Quotidien Supplémentaire',
          desc: 'Débloque un 4e défi quotidien permanent (+100 XP immédiats).',
          cout: 180,
          xpBonus: 100,
        ),
        // Accès illimité au Quiz Personnalisé (Roadmap 11.4 : gratuit = 5/jour)
        _buildBoosterItem(
          id: 'quiz_perso_illimite',
          nom: 'Pass Quiz Personnalisé Illimité',
          desc: 'Lève la limite de 5 salons personnalisés par jour.',
          cout: 100,
        ),
      ],
    );
  }

  Widget _buildBoosterItem({
    required String id,
    required String nom,
    required String desc,
    required int cout,
    int xpBonus = 0,
    int minutesDoubleXp = 0,
  }) {
    final List<String> possedes = (_portefeuille['articlesPossedes'] as List<String>?) ?? [];
    final bool possede = minutesDoubleXp == 0 && possedes.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OtakuColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OtakuColors.glassBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: OtakuColors.accent, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom, style: OtakuTypo.headlineSmall.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: OtakuTypo.bodySmall.copyWith(fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (possede)
            const Text('ACTIF', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11))
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.accent),
              onPressed: () async {
                try {
                  final msg = await _v4Service.acheterArticleBoutique(
                    articleId: id,
                    nom: nom,
                    coutCoins: cout,
                    xpBonus: xpBonus,
                    minutesDoubleXp: minutesDoubleXp,
                  );
                  setState(() => _message = msg);
                  await _charger();
                } catch (e) {
                  setState(() => _message = e.toString().replaceAll('Exception: ', ''));
                }
              },
              child: Text('$cout COINS', style: const TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Future<void> _simulerVisionnagePub() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: OtakuColors.surface,
        title: Text('SPOT PUBLICITAIRE OPT-IN', style: TextStyle(color: Colors.white, fontSize: 15)),
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.greenAccent),
            SizedBox(width: 16),
            Expanded(child: Text('Lecture de la publicité récompensée en cours (3 secondes)...', style: TextStyle(color: Colors.white70, fontSize: 12))),
          ],
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context).pop();

    try {
      final msg = await _v4Service.validerPubRecompensee();
      setState(() => _message = msg);
      await _charger();
    } catch (e) {
      setState(() => _message = e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Onglet 3 : Pass Premium mensuel (11.3) & Packs de Verse Coins (11.1)
  Widget _buildPassEtCoinsTab() {
    final bool passActif = _portefeuille['passPremium'] == true;
    final packs = [
      {'coins': 500, 'prix': '1 500 FCFA', 'bonus': 'Pack Découverte'},
      {'coins': 1500, 'prix': '3 500 FCFA', 'bonus': 'Populaire (+10%)'},
      {'coins': 5000, 'prix': '9 900 FCFA', 'bonus': 'Pack Yonko (+25%)'},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pass Premium mensuel (Roadmap 11.3)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OtakuColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.7), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PASS PREMIUM MENSUEL', style: OtakuTypo.headlineSmall.copyWith(color: Colors.amber)),
                      const SizedBox(height: 4),
                      Text(
                        'Zéro publicité, +20% XP sur tous les quiz, +50 Verse Coins/jour, Cadre exclusif "Premium", accès anticipé aux événements et file matchmaking prioritaire.',
                        style: OtakuTypo.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: passActif ? Colors.green[700] : Colors.amber[800]),
                      onPressed: passActif
                          ? null
                          : () async {
                              await _v4Service.activerPassPremium();
                              setState(() => _message = 'Pass Premium activé ! +50 Verse Coins et Cadre Premium reçus.');
                              await _charger();
                            },
                      child: Text(passActif ? 'ABONNÉ' : 'ACTIVER (TEST)', style: const TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () async {
                        try {
                          final msg = await _v4Service.reclamerBonusQuotidienCoins();
                          setState(() => _message = msg);
                          await _charger();
                        } catch (e) {
                          setState(() => _message = e.toString().replaceAll('Exception: ', ''));
                        }
                      },
                      child: Text(
                        passActif ? 'RÉCLAMER +50/J' : 'BONUS GRATUIT +15/J',
                        style: const TextStyle(color: Colors.amber, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('PACKS VERSE COINS (MODE TEST)', style: OtakuTypo.headlineSmall.copyWith(fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: packs.map((p) {
              final int coins = p['coins'] as int;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: OtakuColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OtakuColors.glassBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 28),
                      const SizedBox(height: 4),
                      Text('$coins COINS', style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: Colors.amber)),
                      Text(p['bonus'] as String, style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OtakuColors.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () async {
                          await _v4Service.acheterPackCoins(coins);
                          setState(() => _message = '+$coins Verse Coins crédités sur ton compte !');
                          await _charger();
                        },
                        child: Text(p['prix'] as String, style: const TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final actif = _tabActive == index;
    return GestureDetector(
      onTap: () => setState(() => _tabActive = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: actif ? OtakuColors.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: actif ? OtakuColors.accent.withValues(alpha: 0.5) : OtakuColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: actif ? OtakuColors.accent : OtakuColors.textMuted),
            const SizedBox(width: 6),
            Text(label, style: OtakuTypo.label.copyWith(fontSize: 11, color: actif ? OtakuColors.accent : OtakuColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinCard(Skin skin) {
    final couleur = _couleurRarete(skin.rarity);
    final largeur = MediaQuery.of(context).size.width * 0.3;

    return GestureDetector(
      onTap: () => _ouvrirDetail(skin),
      child: Container(
        width: largeur,
        decoration: BoxDecoration(
          color: OtakuColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: skin.equipped ? OtakuColors.accent : couleur.withValues(alpha: 0.4),
            width: skin.equipped ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Visuel du skin
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  gradient: LinearGradient(
                    colors: [couleur.withValues(alpha: 0.08), OtakuColors.surface],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_iconRarete(skin.rarity), size: 36, color: couleur),
                    if (skin.equipped) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: OtakuColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('EQUIPE', style: OtakuTypo.label.copyWith(fontSize: 7, color: OtakuColors.accent)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Nom + rarete
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                children: [
                  Text(skin.name, style: OtakuTypo.headlineSmall.copyWith(fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(skin.rarity.toUpperCase(), style: OtakuTypo.label.copyWith(fontSize: 8, color: couleur)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre l'ecran detail d'un skin (apercu 3D, description, bouton action)
  void _ouvrirDetail(Skin skin) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _SkinDetailPage(
        skin: skin,
        onAction: () {
          _charger();
          Navigator.pop(context);
        },
      )),
    );
  }

  Color _couleurRarete(String rarity) {
    switch (rarity) {
      case 'commun': return OtakuColors.textMuted;
      case 'rare': return const Color(0xFF4FC3F7);
      case 'epique': return OtakuColors.accent;
      case 'legendaire': return const Color(0xFFFFD700);
      default: return OtakuColors.textMuted;
    }
  }

  IconData _iconRarete(String rarity) {
    switch (rarity) {
      case 'commun': return Icons.person_rounded;
      case 'rare': return Icons.auto_awesome_rounded;
      case 'epique': return Icons.whatshot_rounded;
      case 'legendaire': return Icons.military_tech_rounded;
      default: return Icons.person_rounded;
    }
  }
}

/// Ecran detail d'un skin — apercu 3D rotatif, description, bouton acheter/equiper
class _SkinDetailPage extends StatefulWidget {
  final Skin skin;
  final VoidCallback onAction;

  const _SkinDetailPage({required this.skin, required this.onAction});

  @override
  State<_SkinDetailPage> createState() => _SkinDetailPageState();
}

class _SkinDetailPageState extends State<_SkinDetailPage> with SingleTickerProviderStateMixin {
  final _skinService = SkinService();
  late AnimationController _rotationController;
  double _dragRotation = 0;
  String? _erreur;
  bool _chargement = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _action() async {
    setState(() => _chargement = true);

    if (widget.skin.owned) {
      // Equiper
      await _skinService.equiper(widget.skin.id);
      widget.onAction();
    } else {
      // Debloquer
      final erreur = await _skinService.debloquer(widget.skin);
      if (erreur != null) {
        setState(() { _erreur = erreur; _chargement = false; });
        return;
      }
      widget.onAction();
    }
  }

  Color get _couleur {
    switch (widget.skin.rarity) {
      case 'commun': return OtakuColors.textMuted;
      case 'rare': return const Color(0xFF4FC3F7);
      case 'epique': return OtakuColors.accent;
      case 'legendaire': return const Color(0xFFFFD700);
      default: return OtakuColors.textMuted;
    }
  }

  IconData get _icon {
    switch (widget.skin.rarity) {
      case 'commun': return Icons.person_rounded;
      case 'rare': return Icons.auto_awesome_rounded;
      case 'epique': return Icons.whatshot_rounded;
      case 'legendaire': return Icons.military_tech_rounded;
      default: return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              // Gauche : apercu 3D rotatif
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() => _dragRotation += details.delta.dx * 0.01);
                  },
                  child: AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      final angle = _dragRotation + (_rotationController.value * 2 * pi);
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: child,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            _couleur.withValues(alpha: 0.12),
                            OtakuColors.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: _couleur.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Icon(_icon, size: 80, color: _couleur.withValues(alpha: 0.8)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Droite : infos + bouton
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bouton retour
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_rounded, color: OtakuColors.textPrimary, size: 22),
                    ),
                    const SizedBox(height: 12),

                    // Nom
                    Text(skin.name, style: OtakuTypo.headlineLarge.copyWith(fontSize: 22)),
                    const SizedBox(height: 6),

                    // Rarete
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _couleur.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _couleur.withValues(alpha: 0.4)),
                      ),
                      child: Text(skin.rarity.toUpperCase(), style: OtakuTypo.label.copyWith(fontSize: 10, color: _couleur)),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(skin.description, style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted)),
                    const SizedBox(height: 16),

                    // Condition
                    if (!skin.owned) ...[
                      Row(
                        children: [
                          Icon(
                            skin.unlockType == 'level' ? Icons.trending_up_rounded : Icons.star_rounded,
                            size: 16,
                            color: _couleur,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Condition : ${skin.conditionTexte}',
                            style: OtakuTypo.hud.copyWith(fontSize: 12, color: _couleur),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Erreur
                    if (_erreur != null) ...[
                      Text(_erreur!, style: TextStyle(color: OtakuColors.error, fontSize: 11)),
                      const SizedBox(height: 10),
                    ],

                    const Spacer(),

                    // Bouton action
                    if (!skin.equipped)
                      GestureDetector(
                        onTap: _chargement ? null : _action,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: skin.owned
                                ? OtakuColors.accent.withValues(alpha: 0.15)
                                : _couleur.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: skin.owned
                                  ? OtakuColors.accent.withValues(alpha: 0.5)
                                  : _couleur.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Center(
                            child: _chargement
                                ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _couleur))
                                : Text(
                                    skin.owned ? 'EQUIPER' : 'DEBLOQUER',
                                    style: OtakuTypo.label.copyWith(
                                      color: skin.owned ? OtakuColors.accent : _couleur,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: OtakuColors.pvHaut.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: OtakuColors.pvHaut.withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: Text('EQUIPE ACTUELLEMENT', style: OtakuTypo.label.copyWith(color: OtakuColors.pvHaut, fontSize: 11)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
