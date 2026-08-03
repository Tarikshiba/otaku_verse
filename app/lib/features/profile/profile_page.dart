import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/theme.dart';
import '../progression/progression_service.dart';
import '../skins/skin_model.dart';
import '../skins/skin_service.dart';
import '../social/classement_screen.dart';
import 'parametres_page.dart';

/// === ECRAN PROFIL — Fidele au PDF ===
/// Colonne gauche : skin 3D rotatif + nom du skin + bouton changer
/// Colonne droite : identite, barre XP, 4 stats en ligne, collection + classement

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final ProgressionService _progressionService = ProgressionService();
  late AnimationController _skinRotation;
  double _dragRotation = 0;

  Map<String, dynamic>? _profil;
  bool _chargement = true;
  List<Skin> _mesSkins = [];
  String _skinActifNom = 'GUERRIER BASIQUE';

  @override
  void initState() {
    super.initState();
    _chargerProfil();
    _chargerSkins();
    _skinRotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _skinRotation.dispose();
    super.dispose();
  }

  Future<void> _chargerProfil() async {
    try {
      await _progressionService.creerProfilSiAbsent();
      final profil = await _progressionService.recupererProfil();
      if (!mounted) return;
      setState(() {
        _profil = profil;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _chargerSkins() async {
    try {
      final skins = await SkinService().tousLesSkins();
      if (!mounted) return;
      final possedes = skins.where((s) => s.owned).toList();
      final equipe = possedes.where((s) => s.equipped).firstOrNull;
      setState(() {
        _mesSkins = possedes;
        if (equipe != null) _skinActifNom = equipe.name.toUpperCase();
      });
    } catch (_) {}
  }

  void _changerSkinSuivant() async {
    if (_mesSkins.length <= 1) return;
    final indexActuel = _mesSkins.indexWhere((s) => s.equipped);
    final prochain = (indexActuel + 1) % _mesSkins.length;
    await SkinService().equiper(_mesSkins[prochain].id);
    _chargerSkins();
  }

  void _ouvrirCollectionModal() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: OtakuColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('COLLECTION DE SKINS', style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, size: 20, color: OtakuColors.textMuted),
                  ),
                ],
              ),
              const Divider(color: OtakuColors.border, height: 20),
              SizedBox(
                height: 140,
                child: _mesSkins.isEmpty
                    ? Center(child: Text('Aucun skin', style: OtakuTypo.bodySmall))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _mesSkins.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final skin = _mesSkins[i];
                          return Container(
                            width: 110,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: skin.equipped ? OtakuColors.modeEvent : OtakuColors.border,
                                width: skin.equipped ? 2 : 1,
                              ),
                              color: OtakuColors.background,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person, size: 36, color: OtakuColors.accent.withValues(alpha: 0.7)),
                                const SizedBox(height: 6),
                                Text(skin.name, style: OtakuTypo.headlineSmall.copyWith(fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (skin.equipped) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: OtakuColors.pvHaut.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('EQUIPE', style: OtakuTypo.label.copyWith(fontSize: 7, color: OtakuColors.pvHaut)),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: _chargement
            ? const Center(child: CircularProgressIndicator())
            : _buildContenu(),
      ),
    );
  }

  Widget _buildContenu() {
    final xpTotale = _profil?['xp_totale'] ?? 0;
    final niveau = _profil?['niveau'] ?? 1;
    final rangActuel = _profil?['rang'] ?? 'Debutant';
    final combatsJoues = _profil?['combats_joues'] ?? 0;
    final combatsGagnes = _profil?['combats_gagnes'] ?? 0;
    final pseudo = _profil?['pseudo'] ?? 'Joueur';
    final country = _profil?['country'];

    final xpDansNiveau = ProgressionService.xpDansNiveauActuel(xpTotale as int);
    final xpPourProchain = ProgressionService.xpRequise(niveau as int);
    final progressionXp = xpPourProchain > 0 ? xpDansNiveau / xpPourProchain : 0.0;

    final tauxVictoire = combatsJoues > 0
        ? ((combatsGagnes / combatsJoues) * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // === TOP BAR ===
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: OtakuColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: OtakuColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, size: 18, color: OtakuColors.textMuted),
                ),
              ),
              const SizedBox(width: 12),
              Text('PROFIL', style: OtakuTypo.headlineLarge.copyWith(fontSize: 20)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ParametresPage(
                    profil: _profil,
                    onProfilChange: _chargerProfil,
                  )),
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: OtakuColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: OtakuColors.border),
                  ),
                  child: const Icon(Icons.settings_rounded, size: 18, color: OtakuColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // === CONTENU 2 COLONNES ===
          Expanded(
            child: Row(
              children: [
                // ====== COLONNE GAUCHE : Skin 3D ======
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      // Header skin : badge + titre
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: OtakuColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.4)),
                            ),
                            child: Text('Skin Actif', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.accent)),
                          ),
                          const Spacer(),
                          Text('Titre: $rangActuel', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.modeEvent)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Nom du skin
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_skinActifNom, style: OtakuTypo.headlineLarge.copyWith(fontSize: 18)),
                      ),
                      const SizedBox(height: 8),

                      // Zone skin 3D rotatif
                      Expanded(
                        child: LiquidGlass(
                          tintColor: OtakuColors.accent,
                          borderRadius: 16,
                          padding: EdgeInsets.zero,
                          child: GestureDetector(
                            onPanUpdate: (d) => setState(() => _dragRotation += d.delta.dx * 0.01),
                            child: AnimatedBuilder(
                              animation: _skinRotation,
                              builder: (context, child) {
                                final angle = _dragRotation + (_skinRotation.value * 2 * pi);
                                return Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(angle),
                                  child: child,
                                );
                              },
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person, size: 70, color: OtakuColors.accent.withValues(alpha: 0.7)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.threesixty_rounded, size: 12, color: OtakuColors.textMuted.withValues(alpha: 0.6)),
                                        const SizedBox(width: 4),
                                        Text('Glisser pour pivoter', style: OtakuTypo.bodySmall.copyWith(fontSize: 9, color: OtakuColors.textMuted)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Bouton CHANGER DE SKIN — cycle au skin suivant
                      GestureDetector(
                        onTap: _changerSkinSuivant,
                        child: LiquidGlass(
                          tintColor: OtakuColors.modeEvent,
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.checkroom_rounded, size: 16, color: OtakuColors.modeEvent),
                              const SizedBox(width: 8),
                              Text('CHANGER DE SKIN', style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.modeEvent)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // ====== COLONNE DROITE : Infos + Stats ======
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    child: Column(
                    children: [
                      // Identite
                      LiquidGlass(
                        tintColor: OtakuColors.accent,
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('@$pseudo', style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text('Niveau $niveau ($rangActuel)', style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.accent)),
                                  const SizedBox(height: 6),
                                  // Barre XP
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progressionXp,
                                            minHeight: 6,
                                            backgroundColor: OtakuColors.border,
                                            valueColor: const AlwaysStoppedAnimation(OtakuColors.accent),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('$xpDansNiveau / $xpPourProchain XP', style: OtakuTypo.hud.copyWith(fontSize: 9, color: OtakuColors.modeEvent)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (country != null) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: OtakuColors.border),
                                ),
                                child: Text(country, style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.textSecondary)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 4 Stats en ligne horizontale
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

                      // Collection — ouvre un modal
                      LiquidGlass(
                        tintColor: OtakuColors.accent,
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('MA COLLECTION DE SKINS', style: OtakuTypo.headlineLarge.copyWith(fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text('${_mesSkins.length} skins debloques', style: OtakuTypo.bodySmall.copyWith(fontSize: 9)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _ouvrirCollectionModal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: OtakuColors.accent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.5)),
                                ),
                                child: Text('VOIR', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.accent)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Classement
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ClassementScreen()),
                        ),
                        child: LiquidGlass(
                          tintColor: OtakuColors.modeEvent,
                          borderRadius: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.leaderboard_rounded, size: 18, color: OtakuColors.modeEvent),
                              const SizedBox(width: 10),
                              Text('CLASSEMENT', style: OtakuTypo.label.copyWith(fontSize: 11, color: OtakuColors.modeEvent)),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: OtakuColors.modeEvent),
                            ],
                          ),
                        ),
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
    );
  }

  Widget _buildStatCard(String label, String valeur, Color couleur, IconData icon) {
    return LiquidGlass(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: couleur.withValues(alpha: 0.7)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(valeur, style: OtakuTypo.hud.copyWith(fontSize: 18, color: couleur)),
          ),
          const SizedBox(height: 2),
          Text(label, style: OtakuTypo.label.copyWith(fontSize: 7, color: OtakuColors.textMuted)),
        ],
      ),
    );
  }
}
