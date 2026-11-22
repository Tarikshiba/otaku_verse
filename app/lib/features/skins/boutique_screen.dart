import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/rank_badge.dart';
import 'monetisation_v4_service.dart';
import 'skin_model.dart';
import 'skin_service.dart';

/// === BOUTIQUE OFFICIELLE V9.2 (ECO-02, SHOP-01, SHOP-02, SHOP-03, UI-01) ===
/// - ZERO achat de skin en XP, ZERO Booster XP, ZERO Coffre Mystere XP, ZERO VC contre pub
/// - Onglet 0 : Goodies (1 starter tuto 300 OC + Classiques/Epiques/Fondateurs Soryn & Nyxara en VC)
/// - Onglet 1 : Cosmetiques (Cadres, Finishers K.O., Emotes, Titres — 100% VC)
/// - Onglet 2 : Calendrier 21 jours (plafond 150 VC/saison, swap 250 OC cycle 2) & Coup de Pouce +40 OC
/// - Onglet 3 : Offres & Packs VC (3 offres claires + 5 Packs VC exacts 6,00 FCFA/VC)
class BoutiqueScreen extends StatefulWidget {
  final bool showBack;
  final int initialTab;
  const BoutiqueScreen({super.key, this.showBack = false, this.initialTab = 0});

  @override
  State<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends State<BoutiqueScreen> {
  final _skinService = SkinService();
  final _shopService = MonetisationV4Service();

  List<Skin> _skins = [];
  Map<String, dynamic> _wallet = {
    'ocBalance': 0,
    'verseCoins': 0,
    'vcBonus': 0,
    'vcPaid': 0,
    'seasonFreeVcEarned': 0,
    'passPremium': false,
    'noAdsActif': false,
    'starterPackClaimed': false,
    'articlesPossedes': <String>[],
    'calendarDay': 0,
    'calendarCycle': 1,
    'calendarClaimedToday': false,
  };
  bool _chargement = true;
  bool _actionEnCours = false;
  late int _tabActive;
  String? _message;

  @override
  void initState() {
    super.initState();
    _tabActive = widget.initialTab.clamp(0, 3);
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      final results = await Future.wait([
        _skinService.tousLesSkins(),
        _shopService.recupererPortefeuille(),
      ]);
      if (!mounted) return;
      setState(() {
        _skins = results[0] as List<Skin>;
        _wallet = results[1] as Map<String, dynamic>;
        _chargement = false;
      });
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _executerAction(Future<String> Function() fn) async {
    if (_actionEnCours) return;
    setState(() {
      _actionEnCours = true;
      _message = null;
    });
    try {
      final msg = await fn();
      if (!mounted) return;
      setState(() {
        _message = msg;
        _actionEnCours = false;
      });
      await _charger();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = e.toString().replaceAll('Exception: ', '');
        _actionEnCours = false;
      });
    }
  }

  Color _couleurRarete(String rarity) {
    switch (rarity) {
      case 'commun':
        return OtakuColors.textMuted;
      case 'classique':
        return const Color(0xFF4FC3F7);
      case 'epique':
        return OtakuColors.accent;
      case 'legendaire':
        return const Color(0xFFFFD700);
      default:
        return OtakuColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int oc = (_wallet['ocBalance'] as num?)?.toInt() ?? 0;
    final int vc = (_wallet['verseCoins'] as num?)?.toInt() ?? 0;
    final bool isVip = _wallet['passPremium'] == true;
    final bool noAds = _wallet['noAdsActif'] == true;

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === TOP BAR ANTI-OVERFLOW (UI-02) ===
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
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      'BOUTIQUE DU VERSE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OtakuTypo.headlineLarge.copyWith(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isVip) ...[
                    _buildStatusPill('VIP ACTIF', const Color(0xFFFFD700)),
                    const SizedBox(width: 6),
                  ] else if (noAds) ...[
                    _buildStatusPill('SANS PUB', OtakuColors.pvHaut),
                    const SizedBox(width: 6),
                  ],
                  // Compteur OC
                  GestureDetector(
                    onTap: () => setState(() => _tabActive = 2),
                    child: _buildCurrencyChip(Icons.toll_rounded, '$oc OC', OtakuColors.pvMoyen),
                  ),
                  const SizedBox(width: 6),
                  // Compteur VC
                  GestureDetector(
                    onTap: () => setState(() => _tabActive = 3),
                    child: _buildCurrencyChip(Icons.diamond_rounded, '$vc VC', const Color(0xFFFFD700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // === ONGLETS V9.2 ===
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTab('Goodies (Skins)', 0, Icons.person_rounded),
                    const SizedBox(width: 8),
                    _buildTab('Cosmetiques VC', 1, Icons.auto_awesome_rounded),
                    const SizedBox(width: 8),
                    _buildTab('Calendrier 21j & OC', 2, Icons.calendar_month_rounded),
                    const SizedBox(width: 8),
                    _buildTab('Offres & Packs VC', 3, Icons.workspace_premium_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (_message != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: OtakuColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _message!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: OtakuTypo.bodySmall.copyWith(color: Colors.white, fontSize: 11),
                  ),
                ),

              Expanded(
                child: _chargement
                    ? const Center(child: CircularProgressIndicator(color: OtakuColors.accent))
                    : _buildTabContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(label, style: OtakuTypo.label.copyWith(fontSize: 9, color: color)),
    );
  }

  Widget _buildCurrencyChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: OtakuTypo.hud.copyWith(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildTab(String titre, int index, IconData icon) {
    final actif = _tabActive == index;
    return GestureDetector(
      onTap: () => setState(() => _tabActive = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: actif ? OtakuColors.accent.withValues(alpha: 0.18) : OtakuColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: actif ? OtakuColors.accent : OtakuColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: actif ? OtakuColors.accent : OtakuColors.textMuted),
            const SizedBox(width: 6),
            Text(
              titre,
              style: OtakuTypo.label.copyWith(
                fontSize: 10,
                color: actif ? Colors.white : OtakuColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabActive) {
      case 0:
        return _buildGoodiesTab();
      case 1:
        return _buildCosmetiquesTab();
      case 2:
        return _buildCalendrierOcTab();
      case 3:
        return _buildOffresEtPacksVcTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ===========================================================================
  // ONGLET 0 : GOODIES (SKINS) — 100% VC SAUF 1 STARTER TUTO A 300 OC (SHOP-03)
  // ===========================================================================
  Widget _buildGoodiesTab() {
    if (_skins.isEmpty) {
      return Center(
        child: Text('Catalogue Goodies indisponible.', style: OtakuTypo.bodySmall),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _skins.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, i) => _buildSkinCard(_skins[i]),
    );
  }

  Widget _buildSkinCard(Skin skin) {
    final couleur = _couleurRarete(skin.rarity);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _SkinDetailPage(
              skin: skin,
              onAction: () {
                Navigator.pop(context);
                _charger();
              },
            ),
          ),
        );
      },
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: OtakuColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: skin.equipped ? OtakuColors.pvHaut : couleur.withValues(alpha: 0.5),
            width: skin.equipped ? 2 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Badge rarete + fondateur
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    skin.isTutorialStarter
                        ? 'TUTO'
                        : skin.isFounderLegendary
                            ? 'FONDATEUR'
                            : skin.rarity.toUpperCase(),
                    style: OtakuTypo.label.copyWith(fontSize: 8, color: couleur),
                  ),
                ),
                const Spacer(),
                if (skin.equipped)
                  Text('EQUIPE', style: OtakuTypo.label.copyWith(fontSize: 8, color: OtakuColors.pvHaut))
                else if (skin.owned)
                  Text('POSSEDE', style: OtakuTypo.label.copyWith(fontSize: 8, color: OtakuColors.accent)),
              ],
            ),
            const SizedBox(height: 6),

            // Avatar non coupe (Ticket UI-01 : BoxFit.contain + Alignment.topCenter + padding >= 12px)
            Expanded(
              child: SafeAvatarBox(
                assetPath: 'assets/images/skins/${skin.imageKey}.png',
                borderColor: couleur,
                borderRadius: 12,
                topPadding: 12,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              skin.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OtakuTypo.headlineSmall.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: skin.owned
                    ? OtakuColors.accent.withValues(alpha: 0.16)
                    : (skin.currency == 'oc' ? OtakuColors.pvMoyen : const Color(0xFFFFD700)).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: skin.owned
                      ? OtakuColors.accent.withValues(alpha: 0.5)
                      : (skin.currency == 'oc' ? OtakuColors.pvMoyen : const Color(0xFFFFD700)).withValues(alpha: 0.5),
                ),
              ),
              child: Center(
                child: Text(
                  skin.equipped
                      ? 'EQUIPE'
                      : skin.owned
                          ? 'EQUIPER'
                          : skin.conditionTexte,
                  style: OtakuTypo.hud.copyWith(
                    fontSize: 11,
                    color: skin.owned
                        ? OtakuColors.accent
                        : (skin.currency == 'oc' ? OtakuColors.pvMoyen : const Color(0xFFFFD700)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ONGLET 1 : COSMETIQUES SECONDAIRES (100% VC, ZERO COFFRE XP — SHOP-03)
  // ===========================================================================
  Widget _buildCosmetiquesTab() {
    final List<String> possedes = List<String>.from(_wallet['articlesPossedes'] as List? ?? []);
    const items = [
      // Cadres (150-350 VC)
      {'id': 'cadre_neon_shonen', 'cat': 'Cadre', 'nom': 'Cadre Neon Shonen', 'desc': 'Bordure lumineuse autour de ton portrait (sans masquer ton Badge de Rang).', 'vc': 150},
      {'id': 'cadre_flamme_astral', 'cat': 'Cadre', 'nom': 'Cadre Flamme Astrale', 'desc': 'Halo cyan anime sur ta fiche Profil et avant-match VS.', 'vc': 250},
      {'id': 'cadre_eclipse_or', 'cat': 'Cadre', 'nom': 'Cadre Eclipse d\'Or', 'desc': 'Contour dore signature pour les duellistes d\'elite.', 'vc': 350},
      // Effets K.O. / Finishers (400-700 VC)
      {'id': 'ko_eclairs_haki', 'cat': 'Finisher K.O.', 'nom': 'Finisher Eclairs du Haki', 'desc': 'Impact visuel special sur l\'ecran KECCHAKU! en fin de duel.', 'vc': 400},
      {'id': 'ko_tranche_dimension', 'cat': 'Finisher K.O.', 'nom': 'Finisher Tranche Dimensionnelle', 'desc': 'Coupure manga cinematique lors d\'un K.O. franc.', 'vc': 550},
      {'id': 'ko_supernova_verse', 'cat': 'Finisher K.O.', 'nom': 'Finisher Supernova du Verse', 'desc': 'Animation ultime de victoire K.O. haute intensite.', 'vc': 700},
      // Emotes / Danses de victoire (250-500 VC)
      {'id': 'emote_salut_shinobi', 'cat': 'Emote', 'nom': 'Emote Salut Shinobi', 'desc': 'Geste de respect affiche sur l\'ecran de victoire.', 'vc': 250},
      {'id': 'emote_aura_gear', 'cat': 'Emote', 'nom': 'Emote Aura Gear', 'desc': 'Pose d\'eveil energetique en fin de combat.', 'vc': 350},
      {'id': 'emote_trone_empereur', 'cat': 'Emote', 'nom': 'Emote Trone de l\'Empereur', 'desc': 'Celebration royale dans les salons et classements.', 'vc': 500},
      // Titres (150-250 VC)
      {'id': 'titre_chasseur_arcs', 'cat': 'Titre', 'nom': 'Titre : Chasseur d\'Arcs', 'desc': 'Titre cosmetique affiche sous ton pseudo.', 'vc': 150},
      {'id': 'titre_foudre_haya', 'cat': 'Titre', 'nom': 'Titre : Foudre Haya!!', 'desc': 'Signature des specialistes de la reponse sous 2 secondes.', 'vc': 200},
      {'id': 'titre_champion_encre', 'cat': 'Titre', 'nom': 'Titre : Champion de l\'Encre', 'desc': 'Titre d\'apparat inspire des mangas classiques.', 'vc': 250},
    ];

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final it = items[index];
        final id = it['id'] as String;
        final owned = possedes.contains(id);
        final vcPrice = it['vc'] as int;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: OtakuColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: owned ? OtakuColors.pvHaut.withValues(alpha: 0.5) : OtakuColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: OtakuColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(it['cat'] as String, style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.accent)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it['nom'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: OtakuTypo.headlineSmall.copyWith(fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(it['desc'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (owned)
                Text('POSSEDE', style: OtakuTypo.label.copyWith(color: OtakuColors.pvHaut, fontSize: 10))
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: _actionEnCours
                      ? null
                      : () => _executerAction(() => _shopService.acheterArticleBoutiqueV92(id, autoEquip: true)),
                  child: Text('$vcPrice VC', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // ONGLET 2 : CALENDRIER 21 JOURS & COUP DE POUCE OC (ZERO BOOSTER XP / ZERO VC PUB)
  // ===========================================================================
  Widget _buildCalendrierOcTab() {
    final int day = (_wallet['calendarDay'] as num?)?.toInt() ?? 0;
    final int cycle = (_wallet['calendarCycle'] as num?)?.toInt() ?? 1;
    final bool claimedToday = _wallet['calendarClaimedToday'] == true;
    final int freeVc = (_wallet['seasonFreeVcEarned'] as num?)?.toInt() ?? 0;
    final bool isVip = _wallet['passPremium'] == true;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banniere Calendrier 21 jours
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OtakuColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CALENDRIER D\'ASSIDUITE 21 JOURS (CYCLE $cycle)',
                        style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cycle == 1
                            ? 'Cycle 1 : Jours 7, 14 et 21 offrent 100 VC au total (condition : 1 match fini le jour meme). Plafond saison : $freeVc / 150 VC gratuits.'
                            : 'Cycle $cycle : Les cases VC sont remplacees par +250 OC (plafond 150 VC gratuits/saison respecte).',
                        style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                      ),
                      if (isVip) ...[
                        const SizedBox(height: 4),
                        Text('Bonus VIP actif : +25 OC supplementaires a chaque reclamation !', style: OtakuTypo.label.copyWith(fontSize: 9, color: const Color(0xFFFFD700))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: claimedToday ? OtakuColors.border : OtakuColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: (claimedToday || _actionEnCours)
                      ? null
                      : () => _executerAction(_shopService.reclamerJourCalendrier21),
                  child: Text(
                    claimedToday ? 'PRIS AUJOURD\'HUI' : 'RECLAMER JOUR ${day >= 21 ? 1 : day + 1}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Grille compacte 21 jours
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(21, (i) {
              final d = i + 1;
              final done = d <= day;
              final isMilestone = d == 7 || d == 14 || d == 21;
              final rewardLabel = isMilestone
                  ? (cycle == 1 ? (d == 7 ? '25 VC' : d == 14 ? '35 VC' : '40 VC') : '250 OC')
                  : (d % 5 == 0 ? '60 OC' : '30 OC');
              return Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: done
                      ? OtakuColors.pvHaut.withValues(alpha: 0.16)
                      : isMilestone
                          ? const Color(0xFFFFD700).withValues(alpha: 0.12)
                          : OtakuColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: done
                        ? OtakuColors.pvHaut
                        : isMilestone
                            ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                            : OtakuColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text('J$d', style: OtakuTypo.label.copyWith(fontSize: 9, color: done ? OtakuColors.pvHaut : OtakuColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      rewardLabel,
                      style: OtakuTypo.hud.copyWith(
                        fontSize: 10,
                        color: isMilestone ? const Color(0xFFFFD700) : Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Coup de Pouce OC (anti-soft-lock : +40 OC, 0 VC, max 3/jour)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OtakuColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: OtakuColors.pvMoyen.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded, color: OtakuColors.pvMoyen, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COUP DE POUCE OTAKU COINS (+40 OC)', style: OtakuTypo.headlineSmall.copyWith(fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        'Pub volontaire anti-blocage pour payer tes frais d\'arene (max 3/jour). Aucun Verse Coin et aucun Booster XP ne sont distribues par pub.',
                        style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.pvMoyen, foregroundColor: Colors.black),
                  onPressed: _actionEnCours ? null : () => _executerAction(_shopService.reclamerCoupDePouceOc),
                  child: const Text('+40 OC', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ONGLET 3 : LES 3 OFFRES MONETISATION (§2.2) + LES 5 PACKS VC EXACTS (§2.1)
  // ===========================================================================
  Widget _buildOffresEtPacksVcTab() {
    final bool isVip = _wallet['passPremium'] == true;
    final bool noAds = _wallet['noAdsActif'] == true;
    final bool starterDone = _wallet['starterPackClaimed'] == true;

    const packs = [
      {
        'id': 'pack_eclat',
        'nom': 'Pack Eclat',
        'total': '150 VC',
        'detail': '150 VC base + 0 VC bonus',
        'prix': '900 FCFA  |  1,49 EUR',
        'badge': 'Tarif Standard (6,00 FCFA/VC)',
        'highlight': false,
      },
      {
        'id': 'pack_decouverte',
        'nom': 'Pack Decouverte',
        'total': '350 VC',
        'detail': '317 VC base + 33 VC offerts',
        'prix': '1 900 FCFA  |  2,99 EUR',
        'badge': '-9,5 % sur le prix / VC (+33 VC offerts)',
        'highlight': false,
      },
      {
        'id': 'pack_populaire',
        'nom': 'Pack Populaire (Erudit)',
        'total': '800 VC',
        'detail': '650 VC base + 150 VC offerts',
        'prix': '3 900 FCFA  |  5,99 EUR',
        'badge': '-18,8 % sur le prix / VC (+150 VC offerts)',
        'highlight': true,
      },
      {
        'id': 'pack_seigneur',
        'nom': 'Pack Seigneur du Verse',
        'total': '1 800 VC',
        'detail': '1 317 VC base + 483 VC offerts',
        'prix': '7 900 FCFA  |  11,99 EUR',
        'badge': '-26,9 % sur le prix / VC (+483 VC offerts)',
        'highlight': false,
      },
      {
        'id': 'pack_arche',
        'nom': 'Pack Arche du Verse',
        'total': '4 500 VC',
        'detail': '2 983 VC base + 1 517 VC offerts',
        'prix': '17 900 FCFA  |  26,99 EUR',
        'badge': '-33,7 % sur le prix / VC (+1 517 VC offerts)',
        'highlight': true,
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('LES 3 OFFRES OFFICIELLES', style: OtakuTypo.headlineSmall.copyWith(fontSize: 13)),
              const Spacer(),
              TextButton.icon(
                onPressed: _ouvrirModalPrivilegesVip,
                icon: const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFFFD700)),
                label: Text('Voir les 8 privileges VIP', style: OtakuTypo.label.copyWith(fontSize: 10, color: const Color(0xFFFFD700))),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Offre 1 : Pass Sans Pub 1 An (4 500 FCFA / 7,99 EUR)
          _buildOfferCard(
            titre: '1. Pass Sans Pub (No Ads 1 An)',
            prix: '4 500 FCFA  |  7,99 EUR',
            desc: 'Supprime 100 % des pubs interstitielles automatiques pendant 365 jours. Pubs volontaires x2 OC conservees. 0 VC et aucun avantage VIP.',
            accent: OtakuColors.pvHaut,
            boutonLabel: noAds ? 'ACTIF' : 'ACTIVER',
            disabled: noAds,
            onTap: () => _executerAction(() => _shopService.acheterOffreOfficielle('no_ads_1y')),
          ),
          const SizedBox(height: 8),

          // Offre 2 : Pack Demarrage (6 500 FCFA / 9,99 EUR, 1x/compte)
          _buildOfferCard(
            titre: '2. Pack Demarrage (1x / compte)',
            prix: '6 500 FCFA  |  9,99 EUR',
            desc: 'Sans Pub automatique pendant 1 an + 400 VC + 500 OC credites immediatement. Aucun avantage VIP.',
            accent: OtakuColors.accent,
            boutonLabel: starterDone ? 'DEJA OBTENU' : 'OBTENIR',
            disabled: starterDone,
            onTap: () => _executerAction(() => _shopService.acheterOffreOfficielle('starter_pack')),
          ),
          const SizedBox(height: 8),

          // Offre 3 : Abonnement VIP Mensuel & Annuel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.65), width: 1.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '3. Abonnement VIP "Pass Premium du Verse" (8 Privileges + Sans Pub)',
                        style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: const Color(0xFFFFD700)),
                      ),
                    ),
                    if (isVip) _buildStatusPill('ABONNE VIP', const Color(0xFFFFD700)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Salons Live & Donjons gratuits, 7 Stats Pro Verse Analytics, +25 OC/jour, franchise erosion XP 14 jours, Cadre VIP anime et 0 pub automatique.',
                  style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        ),
                        onPressed: _actionEnCours
                            ? null
                            : () => _executerAction(() => _shopService.acheterOffreOfficielle('vip_monthly')),
                        child: const Text(
                          'MENSUEL : 3 500 FCFA (1er mois 2 500 FCFA) | +200/+250 VC',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OtakuColors.modeEvent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        ),
                        onPressed: _actionEnCours
                            ? null
                            : () => _executerAction(() => _shopService.acheterOffreOfficielle('vip_yearly')),
                        child: const Text(
                          'ANNUEL (-29 %) : 29 900 FCFA | 3 200 VC/an + Titre',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          Text('PACKS DE VERSE COINS (BASE 6,00 FCFA / VC)', style: OtakuTypo.headlineSmall.copyWith(fontSize: 13)),
          const SizedBox(height: 8),

          ...packs.map((p) {
            final highlight = p['highlight'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: highlight ? const Color(0xFFFFD700).withValues(alpha: 0.08) : OtakuColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: highlight ? const Color(0xFFFFD700).withValues(alpha: 0.6) : OtakuColors.border,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.diamond_rounded, color: Color(0xFFFFD700), size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${p['nom']} — ${p['total']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: OtakuTypo.headlineSmall.copyWith(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(p['detail'] as String, style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: Colors.white70)),
                        const SizedBox(height: 2),
                        Text(
                          p['badge'] as String,
                          style: OtakuTypo.label.copyWith(
                            fontSize: 9,
                            color: highlight ? const Color(0xFFFFD700) : OtakuColors.pvHaut,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: _actionEnCours
                        ? null
                        : () => _executerAction(() => _shopService.acheterPackVcOfficiel(p['id'] as String)),
                    child: Text(p['prix'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOfferCard({
    required String titre,
    required String prix,
    required String desc,
    required Color accent,
    required String boutonLabel,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OtakuColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$titre ($prix)', style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: accent)),
                const SizedBox(height: 3),
                Text(desc, style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: disabled ? OtakuColors.border : accent,
              foregroundColor: disabled ? Colors.white60 : Colors.black,
            ),
            onPressed: (disabled || _actionEnCours) ? null : onTap,
            child: Text(boutonLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _ouvrirModalPrivilegesVip() {
    const privileges = [
      '1. Creation illimitee et gratuite de Salons Live JKLM (150 VC non-VIP).',
      '2. Creation illimitee et gratuite de Donjons Otaku Forge (100 VC non-VIP).',
      '3. Acces complet au Generateur Hybride de questions sur mesure.',
      '4. Deblocage des 7 Statistiques Pro "Verse Analytics" dans ton Profil.',
      '5. Bonus quotidien +25 OC et 1 recharge gratuite de defi manque par semaine.',
      '6. Franchise d\'erosion hebdomadaire d\'XP doublee a 14 jours (au lieu de 7).',
      '7. Cadre d\'Avatar Anime VIP Or/Violet (sans jamais masquer ton Badge de Rang).',
      '8. Suppression 100 % des publicites interstitielles automatiques incluse.',
    ];

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: OtakuColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'LES 8 PRIVILEGES EXCLUSIFS VIP',
                        style: OtakuTypo.headlineSmall.copyWith(fontSize: 14, color: const Color(0xFFFFD700)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: OtakuColors.textMuted),
                    ),
                  ],
                ),
                const Divider(color: OtakuColors.border),
                ...privileges.map(
                  (p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(p, style: OtakuTypo.bodySmall.copyWith(fontSize: 11, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page detail Goodies 3D avec cadrage non coupe (UI-01 : BoxFit.contain + Alignment.topCenter + padding >= 12px)
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
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    if (widget.skin.owned) {
      await _skinService.equiper(widget.skin.id);
      widget.onAction();
    } else {
      final erreur = await _skinService.debloquer(widget.skin, autoEquip: true);
      if (erreur != null) {
        if (mounted) {
          setState(() {
            _erreur = erreur;
            _chargement = false;
          });
        }
        return;
      }
      widget.onAction();
    }
  }

  Color get _couleur {
    switch (widget.skin.rarity) {
      case 'commun':
        return OtakuColors.textMuted;
      case 'classique':
        return const Color(0xFF4FC3F7);
      case 'epique':
        return OtakuColors.accent;
      case 'legendaire':
        return const Color(0xFFFFD700);
      default:
        return OtakuColors.textMuted;
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
              // Gauche : apercu 3D rotatif non coupe (UI-01)
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onPanUpdate: (details) => setState(() => _dragRotation += details.delta.dx * 0.01),
                  child: AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      final angle = sin(_dragRotation + (_rotationController.value * 2 * pi)) * 0.2;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: child,
                      );
                    },
                    child: SafeAvatarBox(
                      assetPath: 'assets/images/skins/${skin.imageKey}.png',
                      borderColor: _couleur,
                      borderRadius: 20,
                      topPadding: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Droite : infos + bouton achat VC/OC
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_rounded, color: OtakuColors.textPrimary, size: 22),
                    ),
                    const SizedBox(height: 12),
                    Text(skin.name, style: OtakuTypo.headlineLarge.copyWith(fontSize: 22)),
                    const SizedBox(height: 6),
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
                    Text(skin.description, style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted)),
                    const SizedBox(height: 16),
                    if (!skin.owned)
                      Text(
                        'Tarif officiel : ${skin.conditionTexte}',
                        style: OtakuTypo.hud.copyWith(
                          fontSize: 14,
                          color: skin.currency == 'oc' ? OtakuColors.pvMoyen : const Color(0xFFFFD700),
                        ),
                      ),
                    if (_erreur != null) ...[
                      const SizedBox(height: 10),
                      Text(_erreur!, style: const TextStyle(color: OtakuColors.error, fontSize: 11)),
                    ],
                    const Spacer(),
                    if (!skin.equipped)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: skin.owned ? OtakuColors.accent : _couleur,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _chargement ? null : _action,
                          child: _chargement
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(
                                  skin.owned ? 'EQUIPER CE GOODIES' : 'DEBLOQUER (${skin.conditionTexte})',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: OtakuColors.pvHaut.withValues(alpha: 0.12),
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
