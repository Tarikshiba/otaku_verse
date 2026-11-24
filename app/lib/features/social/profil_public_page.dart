import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../shared/rank_badge.dart';
import '../../shared/skin_3d_viewer.dart';
import '../economy/economy_v92_service.dart';
import '../skins/skin_model.dart';
import '../skins/skin_service.dart';
import 'friends_service.dart';

/// === PROFIL PUBLIC JOUEUR 3D EN LECTURE SEULE (3.1 — STYLE FREE FIRE) ===
/// - Fond podium `profil_podium_bg.webp` + personnage 3D anime du joueur au centre
/// - Affiche uniquement les donnees publiques autorisees (via RPC `get_public_player_profile`) :
///   pseudo, medaille de rang PNG, Division, pays, titre, stats publiques, collection de skins
/// - ZERO edition possible, ZERO email, ZERO solde OC/VC expose
class ProfilPublicPage extends StatefulWidget {
  final String userId;
  final String pseudo;
  final int niveau;
  final String rang;
  final bool isFriend;

  const ProfilPublicPage({
    super.key,
    required this.userId,
    required this.pseudo,
    required this.niveau,
    required this.rang,
    this.isFriend = false,
  });

  @override
  State<ProfilPublicPage> createState() => _ProfilPublicPageState();
}

class _ProfilPublicPageState extends State<ProfilPublicPage> {
  final _supabase = Supabase.instance.client;
  final _friendsService = FriendsService();

  bool _chargement = true;
  int _onglet = 0; // 0 = Apercu, 1 = Collection
  Map<String, dynamic> _data = {};
  List<Skin> _skinsPossedes = [SkinService.catalogueOfficiel.first];
  Skin _skinEquipe = SkinService.catalogueOfficiel.first;
  String? _cadreEquipe;

  String? _message;
  bool _demandeEnvoyee = false;
  late bool _estAmi;

  @override
  void initState() {
    super.initState();
    _estAmi = widget.isFriend;
    _chargerProfilPublic();
  }

  Future<void> _chargerProfilPublic() async {
    Map<String, dynamic>? loaded;

    // 1. Appel RPC securisee (inclut collection publique + cadre equipe)
    try {
      final rpcRes = await _supabase.rpc(
        'get_public_player_profile',
        params: {'p_target_user_id': widget.userId},
      );
      if (rpcRes is Map) {
        loaded = Map<String, dynamic>.from(rpcRes);
      }
    } catch (_) {
      // Repli si la migration SQL v93 n'est pas encore executee sur Supabase
      try {
        final row = await _supabase
            .from('profiles')
            .select('id, pseudo, niveau, rang, xp_totale, combats_joues, combats_gagnes, division_id, pts_division, ko_wins_season, country, active_title, equipped_skin_key, is_vip')
            .eq('id', widget.userId)
            .maybeSingle();
        if (row != null) {
          loaded = Map<String, dynamic>.from(row);
        }
      } catch (_) {}
    }

    // Verifier si deja ami quand l'appel vient du Classement (isFriend = false par defaut)
    if (!_estAmi) {
      try {
        final amis = await _friendsService.mesAmis();
        if (amis.any((a) => a.userId == widget.userId)) {
          _estAmi = true;
        }
      } catch (_) {}
    }

    if (!mounted) return;

    final map = loaded ??
        {
          'pseudo': widget.pseudo,
          'niveau': widget.niveau,
          'rang': widget.rang,
          'xp_totale': 0,
          'combats_joues': 0,
          'combats_gagnes': 0,
          'division_id': 10,
          'pts_division': 0,
          'ko_wins_season': 0,
          'equipped_skin_key': 'skin_kio',
        };

    final skinKey = SkinService.normaliserCle(map['equipped_skin_key']?.toString());
    final skinObj = SkinService.parImageKey(skinKey);

    final rawOwned = (map['owned_skins'] as List?)?.map((e) => e.toString()).toSet() ?? <String>{};
    final normalizedOwned = <String>{'skin_kio', skinObj.id};
    for (final rawId in rawOwned) {
      normalizedOwned.add(SkinService.normaliserCle(rawId));
      normalizedOwned.add(rawId);
    }

    final ownedList = SkinService.catalogueOfficiel
        .where((s) => normalizedOwned.contains(s.id) || normalizedOwned.contains(s.imageKey))
        .toList();

    setState(() {
      _data = map;
      _skinEquipe = skinObj;
      _skinsPossedes = ownedList.isEmpty ? [SkinService.catalogueOfficiel.first] : ownedList;
      _cadreEquipe = map['equipped_frame']?.toString() ??
          (map['is_vip'] == true ? 'cadre_vip_or_violet' : null);
      _chargement = false;
    });
  }

  Future<void> _envoyerDemande() async {
    final erreur = await _friendsService.envoyerDemande(widget.userId);
    if (!mounted) return;
    setState(() {
      if (erreur != null) {
        _message = erreur;
      } else {
        _message = 'Demande d\'ami envoyée !';
        _demandeEnvoyee = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pseudo = _data['pseudo']?.toString() ?? widget.pseudo;
    final niveau = (_data['niveau'] as num?)?.toInt() ?? widget.niveau;
    final xpTotale = (_data['xp_totale'] as num?)?.toInt() ?? 0;
    final combatsJoues = (_data['combats_joues'] as num?)?.toInt() ?? 0;
    final combatsGagnes = (_data['combats_gagnes'] as num?)?.toInt() ?? 0;
    final ptsDiv = (_data['pts_division'] as num?)?.toInt() ?? 0;
    final divisionId = (_data['division_id'] as num?)?.toInt() ?? EconomyV92Service.calculerDivision(ptsDiv);
    final koSeason = (_data['ko_wins_season'] as num?)?.toInt() ?? 0;
    final country = _data['country']?.toString();
    final activeTitle = _data['active_title']?.toString();
    final isVip = _data['is_vip'] == true;
    final tauxVictoire = combatsJoues > 0 ? ((combatsGagnes / combatsJoues) * 100).round() : 0;

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/backgrounds/profil_podium_bg.webp',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: OtakuColors.background),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.68),
                  Colors.black.withValues(alpha: 0.36),
                  Colors.black.withValues(alpha: 0.80),
                ],
              ),
            ),
          ),
          SafeArea(
            child: _chargement
                ? const Center(child: CircularProgressIndicator(color: OtakuColors.accent))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 14, 12),
                    child: Column(
                      children: [
                        // Top bar
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: LiquidGlass(
                                padding: const EdgeInsets.all(8),
                                borderRadius: 10,
                                child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('PROFIL PUBLIC · @$pseudo', style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
                            const Spacer(),
                            if (isVip)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFFD700)),
                                ),
                                child: Text('VIP', style: OtakuTypo.label.copyWith(fontSize: 9, color: const Color(0xFFFFD700))),
                              ),
                            if (activeTitle != null && activeTitle.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: OtakuColors.modeEvent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: OtakuColors.modeEvent.withValues(alpha: 0.7)),
                                ),
                                child: Text(activeTitle, style: OtakuTypo.label.copyWith(fontSize: 9.5, color: OtakuColors.modeEvent)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Corps 3 colonnes (lecture seule)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Colonne gauche : Apercu / Collection + Action Ami
                              SizedBox(
                                width: 136,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildNavPill('Aperçu', Icons.badge_rounded, selected: _onglet == 0, onTap: () => setState(() => _onglet = 0)),
                                    const SizedBox(height: 6),
                                    _buildNavPill(
                                      'Skins (${_skinsPossedes.length})',
                                      Icons.checkroom_rounded,
                                      selected: _onglet == 1,
                                      onTap: () => setState(() => _onglet = 1),
                                    ),
                                    const Spacer(),
                                    if (_estAmi)
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: OtakuColors.pvHaut.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: OtakuColors.pvHaut.withValues(alpha: 0.7)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.check_circle_rounded, size: 15, color: OtakuColors.pvHaut),
                                            const SizedBox(width: 6),
                                            Text('AMI', style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.pvHaut)),
                                          ],
                                        ),
                                      )
                                    else if (!_demandeEnvoyee)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: OtakuColors.accent,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: _envoyerDemande,
                                        icon: const Icon(Icons.person_add_rounded, size: 15),
                                        label: const Text('AJOUTER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          'DEMANDE ENVOYÉE',
                                          textAlign: TextAlign.center,
                                          style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.accent),
                                        ),
                                      ),
                                    if (_message != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        _message!,
                                        textAlign: TextAlign.center,
                                        style: OtakuTypo.bodySmall.copyWith(fontSize: 9.5, color: OtakuColors.pvHaut),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // 2. Colonne centrale : Personnage 3D anime du joueur
                              Expanded(
                                flex: 5,
                                child: OtakuSkin3DViewer(
                                  imageKey: _skinEquipe.imageKey,
                                  accentColor: _skinEquipe.accentColor,
                                  characterName: _skinEquipe.name,
                                  characterSubtitle: _skinEquipe.powerName.isNotEmpty
                                      ? 'Skin équipé · ${_skinEquipe.powerName}'
                                      : 'Skin équipé',
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 3. Colonne droite : Fiche publique OU Collection lecture seule
                              Expanded(
                                flex: 6,
                                child: _onglet == 0
                                    ? SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            LiquidGlass(
                                              tintColor: _skinEquipe.accentColor,
                                              borderRadius: 16,
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                children: [
                                                  SafeAvatarBox(
                                                    assetPath: 'assets/images/skins/${_skinEquipe.imageKey}.png',
                                                    frameId: _cadreEquipe,
                                                    width: 60,
                                                    height: 60,
                                                    topPadding: 4,
                                                    borderRadius: 14,
                                                    borderColor: _skinEquipe.accentColor,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                '@$pseudo',
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: OtakuTypo.headlineLarge.copyWith(fontSize: 16),
                                                              ),
                                                            ),
                                                            if (country != null && country.isNotEmpty)
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                                decoration: BoxDecoration(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  border: Border.all(color: OtakuColors.border),
                                                                ),
                                                                child: Text(country, style: OtakuTypo.label.copyWith(fontSize: 8.5, color: Colors.white70)),
                                                              ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 6),
                                                        OfficialRankBadge(
                                                          niveau: niveau,
                                                          divisionId: divisionId,
                                                          prominent: true,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Expanded(child: _buildStatCard('XP TOTALE', '$xpTotale', OtakuColors.accent, Icons.bolt_rounded)),
                                                const SizedBox(width: 6),
                                                Expanded(child: _buildStatCard('COMBATS', '$combatsJoues', OtakuColors.modeDuel, Icons.sports_mma_rounded)),
                                                const SizedBox(width: 6),
                                                Expanded(child: _buildStatCard('VICTOIRES', '$combatsGagnes', OtakuColors.victoire, Icons.emoji_events_rounded)),
                                                const SizedBox(width: 6),
                                                Expanded(child: _buildStatCard('TAUX', '$tauxVictoire%', OtakuColors.pvMoyen, Icons.pie_chart_rounded)),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            LiquidGlass(
                                              borderRadius: 14,
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('SAISON DIVISION', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.textMuted)),
                                                        const SizedBox(height: 3),
                                                        Text(
                                                          'Division $divisionId · $ptsDiv pts',
                                                          style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: OtakuColors.modeDivision),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: OtakuColors.modeEvent.withValues(alpha: 0.16),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: OtakuColors.modeEvent.withValues(alpha: 0.5)),
                                                    ),
                                                    child: Text(
                                                      '$koSeason K.O.',
                                                      style: OtakuTypo.hud.copyWith(fontSize: 12, color: OtakuColors.modeEvent),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'COLLECTION PUBLIQUE (${_skinsPossedes.length} SKINS)',
                                              style: OtakuTypo.headlineSmall.copyWith(fontSize: 12),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: _skinsPossedes.map((skin) {
                                                final eq = skin.id == _skinEquipe.id;
                                                return Container(
                                                  width: 96,
                                                  padding: const EdgeInsets.all(7),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withValues(alpha: 0.52),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: eq ? skin.accentColor : OtakuColors.border,
                                                      width: eq ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      SafeAvatarBox(
                                                        assetPath: 'assets/images/skins/${skin.imageKey}.png',
                                                        width: 64,
                                                        height: 64,
                                                        topPadding: 4,
                                                        borderRadius: 10,
                                                        borderColor: skin.accentColor,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        skin.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: OtakuTypo.headlineSmall.copyWith(fontSize: 10),
                                                      ),
                                                      if (eq)
                                                        Text(
                                                          'ÉQUIPÉ',
                                                          style: OtakuTypo.label.copyWith(fontSize: 7.5, color: OtakuColors.pvHaut),
                                                        ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavPill(String label, IconData icon, {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? OtakuColors.accent.withValues(alpha: 0.24) : Colors.black.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? OtakuColors.accent : Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: selected ? OtakuColors.accent : Colors.white70),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OtakuTypo.headlineSmall.copyWith(fontSize: 11, color: selected ? Colors.white : OtakuColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String valeur, Color couleur, IconData icon) {
    return LiquidGlass(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: couleur.withValues(alpha: 0.85)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(valeur, style: OtakuTypo.hud.copyWith(fontSize: 17, color: couleur)),
          ),
          const SizedBox(height: 2),
          Text(label, style: OtakuTypo.label.copyWith(fontSize: 7, color: OtakuColors.textMuted)),
        ],
      ),
    );
  }
}
