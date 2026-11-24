import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../economy/economy_v92_service.dart';
import '../skins/monetisation_v4_service.dart';

/// === VERSE ANALYTICS : PAGE DEDIEE PLEIN ECRAN 7 STATS PRO VIP (§2.3 #4, TEST 39) ===
/// Remplace l'ancienne modale texte de 5 lignes par une vraie page interactive :
/// 1. Radar 5 axes (Précision, Vitesse, Haya!!, Résistance Malus, Combativité)
/// 2. Réussite détaillée par difficulté & par mode
/// 3. Chrono moyen de réaction & ratio Haya!! (< 2s)
/// 4. Résistance aux Malus
/// 5. Courbe d'évolution des 50 derniers matchs (graphique peint)
/// 6. Carnet d'erreurs révisable avec filtres par anime et bouton "Marquer révisée"
/// 7. Comparateur Head-to-Head vs moyenne de la Division
class VerseAnalyticsPage extends StatefulWidget {
  const VerseAnalyticsPage({super.key});

  @override
  State<VerseAnalyticsPage> createState() => _VerseAnalyticsPageState();
}

class _VerseAnalyticsPageState extends State<VerseAnalyticsPage> {
  final MonetisationV4Service _shopService = MonetisationV4Service();
  Map<String, dynamic>? _data;
  bool _chargement = true;
  String? _erreur;
  int _onglet = 0; // 0 = Vue globale & Graphiques, 1 = Carnet d'erreurs, 2 = Comparateur H2H
  String _filtreAnime = 'TOUS';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final res = await _shopService.recupererVerseAnalyticsVip();
      if (!mounted) return;
      setState(() {
        _data = res;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e.toString().replaceAll('Exception: ', '');
        _chargement = false;
      });
    }
  }

  Future<void> _marquerErreurRevisee(String errorId) async {
    try {
      await Supabase.instance.client
          .from('player_question_errors')
          .update({'reviewed': true})
          .eq('id', errorId);
      await _charger();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
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
                      child: const Icon(Icons.arrow_back_rounded, color: OtakuColors.textPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.insights_rounded, color: Color(0xFFFFD700), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'VERSE ANALYTICS · 7 STATS PRO',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OtakuTypo.headlineLarge.copyWith(fontSize: 18, color: const Color(0xFFFFD700)),
                    ),
                  ),
                  if (_data != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        '${_data!['sample_size'] ?? 0} matchs analysés',
                        style: OtakuTypo.hud.copyWith(fontSize: 11, color: const Color(0xFFFFD700)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // 3 sous-onglets clairs
              Row(
                children: [
                  _buildTab('Radar & Courbes', 0, Icons.radar_rounded),
                  const SizedBox(width: 8),
                  _buildTab('Carnet d\'erreurs', 1, Icons.menu_book_rounded),
                  const SizedBox(width: 8),
                  _buildTab('Comparateur H2H', 2, Icons.compare_arrows_rounded),
                ],
              ),
              const SizedBox(height: 10),

              Expanded(
                child: _chargement
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                    : _erreur != null
                        ? Center(child: Text(_erreur!, style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.error)))
                        : _onglet == 0
                            ? _buildVueGraphiques()
                            : _onglet == 1
                                ? _buildCarnetErreurs()
                                : _buildComparateurH2H(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int idx, IconData icon) {
    final actif = _onglet == idx;
    return GestureDetector(
      onTap: () => setState(() => _onglet = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: actif ? const Color(0xFFFFD700).withValues(alpha: 0.18) : OtakuColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: actif ? const Color(0xFFFFD700) : OtakuColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: actif ? const Color(0xFFFFD700) : OtakuColors.textMuted),
            const SizedBox(width: 6),
            Text(label, style: OtakuTypo.label.copyWith(fontSize: 11, color: actif ? const Color(0xFFFFD700) : OtakuColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildVueGraphiques() {
    final radar = Map<String, dynamic>.from(_data?['radar_5_axes'] as Map? ?? {});
    final byDiff = Map<String, dynamic>.from(_data?['by_difficulty'] as Map? ?? {});
    final history = List<Map<String, dynamic>>.from(
      (_data?['history_50'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
    );

    final double avgSec = (_data?['avg_reaction_sec'] as num?)?.toDouble() ?? 0.0;
    final int hayaPct = (_data?['haya_ratio_pct'] as num?)?.toInt() ?? 0;
    final int malusRes = (_data?['malus_resistance_pct'] as num?)?.toInt() ?? 100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Colonne gauche : Stat #1 Radar 5 axes + Stats #3 & #4 KPIs
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OtakuColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: OtakuColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. RADAR 5 AXES DU COMBATTANT', style: OtakuTypo.headlineSmall.copyWith(fontSize: 12, color: const Color(0xFFFFD700))),
                const SizedBox(height: 6),
                Expanded(
                  child: CustomPaint(
                    painter: _RadarPainter(
                      values: [
                        ((radar['precision'] as num?)?.toDouble() ?? 0) / 100.0,
                        ((radar['vitesse'] as num?)?.toDouble() ?? 0) / 100.0,
                        ((radar['haya'] as num?)?.toDouble() ?? 0) / 100.0,
                        ((radar['resistance_malus'] as num?)?.toDouble() ?? 0) / 100.0,
                        ((radar['combativite'] as num?)?.toDouble() ?? 0) / 100.0,
                      ],
                      labels: const ['Précision', 'Vitesse', 'Haya!!', 'Malus', 'Combativité'],
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _kpiTile('3. Chrono moy.', '${avgSec.toStringAsFixed(2)} s', const Color(0xFF4CC9F0))),
                    const SizedBox(width: 6),
                    Expanded(child: _kpiTile('3b. Ratio Haya!!', '$hayaPct %', const Color(0xFF3FFFB0))),
                    const SizedBox(width: 6),
                    Expanded(child: _kpiTile('4. Résist. Malus', '$malusRes %', OtakuColors.modeDuel)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Colonne droite : Stat #5 Courbe 50 derniers matchs + Stat #2 Par difficulte
        Expanded(
          flex: 6,
          child: Column(
            children: [
              // Courbe 50 derniers matchs
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: OtakuColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: OtakuColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('5. COURBE DE PRÉCISION (50 DERNIERS MATCHS)', style: OtakuTypo.headlineSmall.copyWith(fontSize: 12, color: OtakuColors.accent)),
                      const SizedBox(height: 6),
                      Expanded(
                        child: history.isEmpty
                            ? Center(child: Text('Joue tes premiers matchs pour tracer ta courbe !', style: OtakuTypo.bodySmall))
                            : CustomPaint(
                                painter: _HistoryLinePainter(
                                  points: history.map((m) => ((m['accuracy'] as num?)?.toDouble() ?? 0) / 100.0).toList(),
                                  wins: history.map((m) => m['won'] == true).toList(),
                                ),
                                child: const SizedBox.expand(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Reussite par difficulte
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: OtakuColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: OtakuColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('2. PRÉCISION PAR DIFFICULTÉ', style: OtakuTypo.headlineSmall.copyWith(fontSize: 12, color: Colors.white)),
                      const SizedBox(height: 6),
                      Expanded(
                        child: byDiff.isEmpty
                            ? Center(child: Text('Aucune donnée par difficulté pour l\'instant.', style: OtakuTypo.bodySmall))
                            : ListView(
                                children: byDiff.entries.map((entry) {
                                  final m = Map<String, dynamic>.from(entry.value as Map);
                                  final total = max(1, (m['total'] as num?)?.toInt() ?? 1);
                                  final correct = (m['correct'] as num?)?.toInt() ?? 0;
                                  final pct = ((correct / total) * 100).round();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 72,
                                          child: Text(entry.key.toUpperCase(), style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.textSecondary)),
                                        ),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: (pct / 100.0).clamp(0.0, 1.0),
                                              minHeight: 7,
                                              backgroundColor: OtakuColors.border,
                                              valueColor: AlwaysStoppedAnimation(pct >= 75 ? OtakuColors.pvHaut : OtakuColors.accent),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 64,
                                          child: Text(
                                            '$pct % (${m['played']}m)',
                                            textAlign: TextAlign.right,
                                            style: OtakuTypo.hud.copyWith(fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
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
    );
  }

  Widget _buildCarnetErreurs() {
    final allErrors = List<Map<String, dynamic>>.from(
      (_data?['error_notebook'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final works = <String>{'TOUS', ...allErrors.map((e) => EconomyV92Service.nomPropreOeuvre(e['work_slug']?.toString()))}.toList();
    final filtered = _filtreAnime == 'TOUS'
        ? allErrors
        : allErrors.where((e) => EconomyV92Service.nomPropreOeuvre(e['work_slug']?.toString()) == _filtreAnime).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '6. CARNET D\'ERREURS RÉVISABLE (${_data?['total_errors_recent'] ?? allErrors.length} erreurs récentes)',
              style: OtakuTypo.headlineSmall.copyWith(fontSize: 12, color: const Color(0xFFFFD700)),
            ),
            const Spacer(),
            if (works.length > 1)
              DropdownButton<String>(
                value: works.contains(_filtreAnime) ? _filtreAnime : 'TOUS',
                dropdownColor: OtakuColors.surface,
                underline: const SizedBox.shrink(),
                style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.accent, fontSize: 11),
                items: works.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                onChanged: (v) => setState(() => _filtreAnime = v ?? 'TOUS'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'Aucune erreur enregistrée dans ce filtre. Tes prochaines erreurs en combat apparaîtront ici avec la bonne réponse et l\'explication lore pour réviser !',
                    textAlign: TextAlign.center,
                    style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted),
                  ),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final err = filtered[i];
                    final reviewed = err['reviewed'] == true;
                    final workName = EconomyV92Service.nomPropreOeuvre(err['work_slug']?.toString());
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: reviewed ? OtakuColors.pvHaut.withValues(alpha: 0.5) : OtakuColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$workName${err['arc_name'] != null ? " · ${err['arc_name']}" : ""}',
                                  style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.accent),
                                ),
                                const SizedBox(height: 3),
                                Text(err['question_text']?.toString() ?? '', style: OtakuTypo.bodySmall.copyWith(color: Colors.white, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  'Ta réponse : ${err['chosen_answer'] ?? "-"}   |   Bonne réponse : ${err['correct_answer'] ?? "?"}',
                                  style: OtakuTypo.hud.copyWith(fontSize: 10, color: OtakuColors.pvHaut),
                                ),
                                if (err['explanation'] != null && err['explanation'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    err['explanation'].toString(),
                                    style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (reviewed)
                            const Icon(Icons.check_circle_rounded, color: OtakuColors.pvHaut)
                          else if (err['id'] != null)
                            TextButton(
                              onPressed: () => _marquerErreurRevisee(err['id'].toString()),
                              child: const Text('RÉVISÉE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildComparateurH2H() {
    final h2h = Map<String, dynamic>.from(_data?['head_to_head_summary'] as Map? ?? {});
    final radar = Map<String, dynamic>.from(_data?['radar_5_axes'] as Map? ?? {});
    final int myWinRate = (h2h['win_rate_pct'] as num?)?.toInt() ?? 0;
    final int divAvgWr = (h2h['division_avg_win_rate'] as num?)?.toInt() ?? 52;
    final int myAcc = (radar['precision'] as num?)?.toInt() ?? 0;
    final int divAvgAcc = (h2h['division_avg_accuracy'] as num?)?.toInt() ?? 64;
    final int koRate = (h2h['ko_rate_pct'] as num?)?.toInt() ?? 0;
    final int divId = (h2h['division_id'] as num?)?.toInt() ?? 10;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7. COMPARATEUR HEAD-TO-HEAD VS MOYENNE DIVISION $divId (${EconomyV92Service.nomDivision(divId)})',
            style: OtakuTypo.headlineSmall.copyWith(fontSize: 12, color: const Color(0xFFFFD700)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _kpiTile('Victoires', '${h2h['wins'] ?? 0}', OtakuColors.pvHaut)),
              const SizedBox(width: 8),
              Expanded(child: _kpiTile('Défaites', '${h2h['losses'] ?? 0}', OtakuColors.error)),
              const SizedBox(width: 8),
              Expanded(child: _kpiTile('Taux K.O.', '$koRate %', const Color(0xFFFFD700))),
              const SizedBox(width: 8),
              Expanded(child: _kpiTile('Taux Victoire', '$myWinRate %', OtakuColors.accent)),
            ],
          ),
          const SizedBox(height: 14),
          _buildCompareBar('Taux de victoire', myWinRate, divAvgWr, 'Toi', 'Moy. D$divId'),
          const SizedBox(height: 10),
          _buildCompareBar('Précision globale', myAcc, divAvgAcc, 'Toi', 'Moy. D$divId'),
        ],
      ),
    );
  }

  Widget _buildCompareBar(String label, int mine, int avg, String myTag, String avgTag) {
    final diff = mine - avg;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OtakuColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OtakuColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: OtakuTypo.headlineSmall.copyWith(fontSize: 12)),
              const Spacer(),
              Text(
                '${diff >= 0 ? "+" : ""}$diff % vs $avgTag',
                style: OtakuTypo.hud.copyWith(fontSize: 11, color: diff >= 0 ? OtakuColors.pvHaut : OtakuColors.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(width: 58, child: Text('$myTag ($mine%)', style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.accent))),
              Expanded(
                child: LinearProgressIndicator(
                  value: (mine / 100.0).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: OtakuColors.border,
                  valueColor: const AlwaysStoppedAnimation(OtakuColors.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              SizedBox(width: 58, child: Text('$avgTag ($avg%)', style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted))),
              Expanded(
                child: LinearProgressIndicator(
                  value: (avg / 100.0).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: OtakuColors.border,
                  valueColor: const AlwaysStoppedAnimation(Colors.amber),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(value, style: OtakuTypo.hud.copyWith(fontSize: 15, color: color)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: OtakuTypo.bodySmall.copyWith(fontSize: 9, color: OtakuColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Peintre Radar 5 axes pour Verse Analytics (sans dependance externe lourde)
class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  _RadarPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.34;
    final gridPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 4 anneaux concentriques
    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * (ring / 4);
      final path = Path();
      for (int i = 0; i < 5; i++) {
        final angle = -pi / 2 + (2 * pi * i / 5);
        final pt = Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r);
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axes + etiquettes
    final dataPath = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (2 * pi * i / 5);
      final outer = Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius);
      canvas.drawLine(center, outer, gridPaint);

      final v = values[i].clamp(0.08, 1.0);
      final dp = Offset(center.dx + cos(angle) * radius * v, center.dy + sin(angle) * radius * v);
      if (i == 0) {
        dataPath.moveTo(dp.dx, dp.dy);
      } else {
        dataPath.lineTo(dp.dx, dp.dy);
      }

      final lblPt = Offset(center.dx + cos(angle) * (radius + 22), center.dy + sin(angle) * (radius + 16));
      final tp = TextPainter(
        text: TextSpan(
          text: '${labels[i]} ${(values[i] * 100).round()}%',
          style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lblPt.dx - tp.width / 2, lblPt.dy - tp.height / 2));
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.28)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}

/// Peintre Courbe des 50 derniers matchs
class _HistoryLinePainter extends CustomPainter {
  final List<double> points;
  final List<bool> wins;
  _HistoryLinePainter({required this.points, required this.wins});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final gridPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), gridPaint);

    final linePaint = Paint()
      ..color = OtakuColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final stepX = points.length > 1 ? size.width / (points.length - 1) : size.width / 2;

    for (int i = 0; i < points.length; i++) {
      final x = points.length > 1 ? i * stepX : size.width / 2;
      final y = size.height - (points[i].clamp(0.0, 1.0) * (size.height - 12)) - 6;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      final x = points.length > 1 ? i * stepX : size.width / 2;
      final y = size.height - (points[i].clamp(0.0, 1.0) * (size.height - 12)) - 6;
      canvas.drawCircle(
        Offset(x, y),
        3.5,
        Paint()..color = wins[i] ? OtakuColors.pvHaut : OtakuColors.error,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryLinePainter oldDelegate) => true;
}
