import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme.dart';
import 'rank_badge.dart';

/// === CARTE VERTICALE 9:16 DE PARTAGE DE VICTOIRE EN 1 CLIC (UI-05, §3.3 & §7.6) ===
/// - Format exporte : 1080 x 1920 px (360 x 640 logique * pixelRatio 3.0) en < 400 ms
/// - Privacy by Design obligatoire :
///   * Adversaire vaincu ANONYMISE par defaut ("adversaire de Division X")
///   * Option d'afficher le pseudo adverse UNIQUEMENT en duel d'amis mutuels si l'ami a active opt-in
///   * ZERO email, telephone, UUID, geolocalisation ou solde total OC/VC
class VictoryShareData {
  final String modeLabel;
  final String workAndArc;
  final String winnerPseudo;
  final String winnerSkinKey;
  final int winnerLevel;
  final int? winnerDivisionId;
  final bool isKo;
  final int winnerHpRemaining;
  final int initialHp;
  final int correctAnswers;
  final int totalQuestionsPlayed;
  final double avgResponseSec;
  final int hayaCount;
  final int maxCombo;
  final int matchOcGained;
  final String? inviteCode;

  // Garde-fous vie privee adversaire
  final int opponentDivisionId;
  final String? opponentRankTitle;
  final bool isMutualFriendDuel;
  final bool opponentAllowsSharePseudo;
  final String? opponentPseudoIfOptedIn;

  const VictoryShareData({
    required this.modeLabel,
    required this.workAndArc,
    required this.winnerPseudo,
    required this.winnerSkinKey,
    required this.winnerLevel,
    this.winnerDivisionId,
    required this.isKo,
    required this.winnerHpRemaining,
    this.initialHp = 350,
    required this.correctAnswers,
    required this.totalQuestionsPlayed,
    required this.avgResponseSec,
    required this.hayaCount,
    required this.maxCombo,
    this.matchOcGained = 0,
    this.inviteCode,
    this.opponentDivisionId = 10,
    this.opponentRankTitle,
    this.isMutualFriendDuel = false,
    this.opponentAllowsSharePseudo = false,
    this.opponentPseudoIfOptedIn,
  });
}

/// Affiche l'apercu de la carte verticale 9:16 et permet l'export 1080x1920 en 1 clic.
class VictoryShareCardDialog extends StatefulWidget {
  final VictoryShareData data;
  const VictoryShareCardDialog({super.key, required this.data});

  @override
  State<VictoryShareCardDialog> createState() => _VictoryShareCardDialogState();
}

class _VictoryShareCardDialogState extends State<VictoryShareCardDialog> {
  final GlobalKey _cardBoundaryKey = GlobalKey();
  bool _showFriendPseudo = false; // Desactive par defaut (Privacy by Design)
  bool _exporting = false;

  bool get _canShowFriendToggle =>
      widget.data.isMutualFriendDuel &&
      widget.data.opponentAllowsSharePseudo &&
      (widget.data.opponentPseudoIfOptedIn?.isNotEmpty ?? false);

  String get _opponentMention {
    if (_canShowFriendToggle && _showFriendPseudo) {
      return 'Victoire face a @${widget.data.opponentPseudoIfOptedIn}';
    }
    final rankPart = widget.data.opponentRankTitle != null
        ? ' (${widget.data.opponentRankTitle})'
        : '';
    return 'Victoire face a un adversaire de Division ${widget.data.opponentDivisionId}$rankPart';
  }

  Future<void> _exporterEtPartager() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final boundary = _cardBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) setState(() => _exporting = false);
        return;
      }
      // 360 x 640 logique * pixelRatio 3.0 = 1080 x 1920 px exact (9:16 Story HD)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) setState(() => _exporting = false);
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/otaku_verse_victory_9_16.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Viens me defier sur Otaku Verse !',
      );
    } catch (_) {}
    if (mounted) setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final int accuracyPct = d.totalQuestionsPlayed > 0
        ? ((d.correctAnswers / d.totalQuestionsPlayed) * 100).round()
        : 0;
    final double hpRatio = (d.winnerHpRemaining / d.initialHp).clamp(0.0, 1.0);

    return Dialog(
      backgroundColor: OtakuColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: 560,
          height: 310,
          child: Row(
            children: [
              // Apercu reduit a l'ecran de la carte verticale 9:16 (rendu natif 360x640 -> 1080x1920)
              AspectRatio(
                aspectRatio: 9 / 16,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: RepaintBoundary(
                    key: _cardBoundaryKey,
                    child: Container(
                      width: 360,
                      height: 640,
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0A0F1D), Color(0xFF141B34), Color(0xFF0B0E18)],
                        ),
                        border: Border.all(color: const Color(0xFFFFD700), width: 3),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. En-tete officiel : Logo sombre + Mode + Oeuvre/Arc
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/images/logos/logo_sombre.jpg',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(Icons.flash_on_rounded, color: Color(0xFFFFD700), size: 36),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('OTAKU VERSE', style: OtakuTypo.headlineLarge.copyWith(fontSize: 18, color: const Color(0xFFFFD700))),
                                    Text(
                                      '${d.modeLabel}  |  ${d.workAndArc}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: OtakuTypo.bodySmall.copyWith(fontSize: 11, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 2. Zone Heros : Goodies non coupe + Pseudo + Badge de Rang Officiel
                          Expanded(
                            child: SafeAvatarBox(
                              assetPath: 'assets/images/skins/${d.winnerSkinKey}.png',
                              borderColor: const Color(0xFFFFD700),
                              borderRadius: 18,
                              topPadding: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              '@${d.winnerPseudo}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: OtakuTypo.headlineLarge.copyWith(fontSize: 20, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: OfficialRankBadge(
                              niveau: d.winnerLevel,
                              divisionId: d.winnerDivisionId,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 3. Bandeau de Verdict + PV restants
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFFD700)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  d.isKo ? 'VICTOIRE PAR K.O. : KECCHAKU!' : 'VICTOIRE AUX POINTS !',
                                  textAlign: TextAlign.center,
                                  style: OtakuTypo.headlineSmall.copyWith(fontSize: 15, color: const Color(0xFFFFD700)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _opponentMention,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: Colors.white70),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: hpRatio,
                                    minHeight: 7,
                                    backgroundColor: Colors.white12,
                                    valueColor: const AlwaysStoppedAnimation(OtakuColors.pvHaut),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${d.winnerHpRemaining} / ${d.initialHp} PV restants',
                                  style: OtakuTypo.hud.copyWith(fontSize: 11, color: OtakuColors.pvHaut),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 4. Cartouche de Performance (aucun solde total OC/VC)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: OtakuColors.border),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _miniStat('PRECISION', '${d.correctAnswers}/${d.totalQuestionsPlayed} ($accuracyPct%)'),
                                    _miniStat('CHRONO MOY.', '${d.avgResponseSec.toStringAsFixed(2)} s'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _miniStat('HAYA!! (<2s)', '${d.hayaCount} coups'),
                                    _miniStat('SERIE MAX', 'Combo x${d.maxCombo}'),
                                  ],
                                ),
                                if (d.matchOcGained > 0) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Gain du match : +${d.matchOcGained} OC',
                                    style: OtakuTypo.hud.copyWith(fontSize: 11, color: const Color(0xFF4CC9F0)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 5. Pied de carte viral
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: OtakuColors.accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 32),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Viens me defier sur Otaku Verse !', style: OtakuTypo.headlineSmall.copyWith(fontSize: 11, color: Colors.white)),
                                      Text(
                                        d.inviteCode != null ? 'Code : ${d.inviteCode}' : 'Telecharge l\'app & rejoins l\'arene',
                                        style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.accent),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Colonne droite : controles Privacy & bouton partage 1 clic
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('PARTAGER MA VICTOIRE (9:16)', style: OtakuTypo.headlineSmall.copyWith(fontSize: 14, color: const Color(0xFFFFD700))),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: OtakuColors.textMuted),
                        ),
                      ],
                    ),
                    Text(
                      'Format Story HD 1080x1920 pret pour WhatsApp, TikTok et Instagram.',
                      style: OtakuTypo.bodySmall.copyWith(fontSize: 11, color: OtakuColors.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: OtakuColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: OtakuColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GARDE-FOUS VIE PRIVEE ACTIFS', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.pvHaut)),
                          const SizedBox(height: 4),
                          Text(
                            'Adversaire anonymise par defaut. Aucun email, UUID ou solde total OC/VC n\'apparait sur l\'image.',
                            style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: Colors.white70),
                          ),
                          if (_canShowFriendToggle) ...[
                            const SizedBox(height: 6),
                            SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Afficher le pseudo de @${d.opponentPseudoIfOptedIn}',
                                style: OtakuTypo.bodySmall.copyWith(fontSize: 11),
                              ),
                              value: _showFriendPseudo,
                              onChanged: (v) => setState(() => _showFriendPseudo = v),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _exporting ? null : _exporterEtPartager,
                        icon: _exporting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.share_rounded, size: 18),
                        label: Text(
                          _exporting ? 'GENERATION HD...' : 'PARTAGER EN 1 CLIC (1080x1920)',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
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
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OtakuTypo.label.copyWith(fontSize: 8, color: OtakuColors.textMuted)),
        Text(value, style: OtakuTypo.hud.copyWith(fontSize: 12, color: Colors.white)),
      ],
    );
  }
}
