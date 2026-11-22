import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../core/feature_flags_service.dart';
import '../quiz/quiz_service.dart';
import '../skins/monetisation_v4_service.dart';

/// === HUB COMMUNAUTE V9.2 : DONJONS OTAKU FORGE & SALONS LIVE JKLM (COMM-01 §5.1) ===
/// Grille tarifaire unifiee sans aucun ecart :
/// - Creation d'un DONJON COMMUNAUTAIRE (asynchrone, Public 1-5 etoiles ou Prive) :
///   100 VC a l'acte pour un non-VIP | GRATUIT & ILLIMITE pour un abonne VIP
/// - Creation d'un SALON LIVE SYNCHRONE (style JKLM.fun, 2 a 10 joueurs par code 6 chiffres) :
///   150 VC a l'acte pour un non-VIP | GRATUIT & ILLIMITE pour un abonne VIP
/// - Rejoindre un Salon Live ou jouer un Donjon d'un autre joueur : 100 % GRATUIT (0 VC)
class VerseCommunautePage extends StatefulWidget {
  const VerseCommunautePage({super.key});

  @override
  State<VerseCommunautePage> createState() => _VerseCommunautePageState();
}

class _VerseCommunautePageState extends State<VerseCommunautePage> {
  final MonetisationV4Service _shopService = MonetisationV4Service();
  final FeatureFlagsService _flags = FeatureFlagsService();
  final QuizService _quizService = QuizService();
  final TextEditingController _joinCodeCtrl = TextEditingController();

  bool _loading = true;
  bool _busy = false;
  bool _isVip = false;
  int _vcBalance = 0;
  int _tab = 0; // 0 = Salons Live JKLM (150 VC), 1 = Donjons Otaku Forge (100 VC)
  String _modeCreation = 'hybride'; // manuel, filtres, hybride
  String _sousModeLive = 'Tous Ensemble (PopQuiz)';
  String _sousModeDonjon = 'Defi Classique (20 Q)';
  bool _donjonPublic = true;
  String? _statusMessage;
  String? _dernierCodeCree;
  List<String> _oeuvres = ['Mix 21 Oeuvres'];
  String _oeuvreChoisie = 'Mix 21 Oeuvres';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _joinCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _shopService.recupererPortefeuille(),
        _quizService.recupererCatalogueR2(),
      ]);
      final wallet = results[0] as Map<String, dynamic>;
      final works = results[1] as List<Map<String, dynamic>>;
      if (!mounted) return;
      setState(() {
        _isVip = wallet['passPremium'] == true;
        _vcBalance = (wallet['verseCoins'] as num?)?.toInt() ?? 0;
        if (works.isNotEmpty) {
          _oeuvres = ['Mix 21 Oeuvres', ...works.map((w) => w['title']?.toString() ?? '')].where((e) => e.isNotEmpty).toList();
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _creerSession({required bool isDonjon}) async {
    final flagKey = isDonjon ? 'mode_donjons' : 'mode_salon_live';
    if (!_flags.estOuvert(flagKey)) {
      setState(() => _statusMessage = 'Verrouille pour le moment : ${_flags.labelLancement(flagKey)}');
      return;
    }

    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      final feature = isDonjon ? 'donjon' : 'salon_live';
      final res = await _shopService.payerCreationCommunaute(feature);
      final code = (100000 + Random().nextInt(900000)).toString();
      final cost = (res['cost_vc'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      setState(() {
        _dernierCodeCree = code;
        _statusMessage = isDonjon
            ? 'Donjon Otaku Forge cree (${_donjonPublic ? "Public 1-5 etoiles" : "Prive"}, $_sousModeDonjon, $_oeuvreChoisie) ! Cout : ${cost == 0 ? "GRATUIT VIP" : "$cost VC"}. Code : $code'
            : 'Salon Live JKLM ouvert ($_sousModeLive, 2-10 joueurs, $_oeuvreChoisie) ! Cout : ${cost == 0 ? "GRATUIT VIP" : "$cost VC"}. Code d\'invitation : $code';
        _busy = false;
      });
      await _charger();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = e.toString().replaceAll('Exception: ', '');
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDonjon = _tab == 1;
    final int coutVc = _isVip ? 0 : (isDonjon ? 100 : 150);

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'COMMUNAUTE : SALONS LIVE & DONJONS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OtakuTypo.headlineLarge.copyWith(fontSize: 17),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _isVip ? 'VIP ILLIMITE (0 VC)' : '$_vcBalance VC',
                      style: OtakuTypo.hud.copyWith(fontSize: 11, color: const Color(0xFFFFD700)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  _buildTabChip('Salons Live JKLM (150 VC / VIP 0 VC)', 0),
                  const SizedBox(width: 8),
                  _buildTabChip('Donjons Otaku Forge (100 VC / VIP 0 VC)', 1),
                ],
              ),
              const SizedBox(height: 10),

              if (_statusMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: OtakuColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.45)),
                  ),
                  child: Text(_statusMessage!, style: OtakuTypo.bodySmall.copyWith(color: Colors.white, fontSize: 11)),
                ),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: OtakuColors.accent))
                    : Row(
                        children: [
                          // Gauche : Creer avec Generateur Hybride (§5.2)
                          Expanded(
                            flex: 6,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: OtakuColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: OtakuColors.border),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isDonjon ? 'CREER UN DONJON (OTAKU FORGE)' : 'CREER UN SALON LIVE (STYLE JKLM.FUN)',
                                      style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: OtakuColors.accent),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Generateur Hybride : choisis entre saisie manuelle, filtres sur les 21 oeuvres R2 ou mode hybride.',
                                      style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      children: ['manuel', 'filtres', 'hybride'].map((m) {
                                        final sel = _modeCreation == m;
                                        return ChoiceChip(
                                          label: Text(m.toUpperCase(), style: const TextStyle(fontSize: 10)),
                                          selected: sel,
                                          onSelected: (_) => setState(() => _modeCreation = m),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      key: ValueKey('oeuvre-$_oeuvreChoisie'),
                                      initialValue: _oeuvres.contains(_oeuvreChoisie) ? _oeuvreChoisie : _oeuvres.first,
                                      dropdownColor: OtakuColors.surface,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        labelText: 'Oeuvre cible',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      items: _oeuvres.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 12)))).toList(),
                                      onChanged: (v) {
                                        if (v != null) setState(() => _oeuvreChoisie = v);
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    if (!isDonjon)
                                      DropdownButtonFormField<String>(
                                        key: ValueKey('live-$_sousModeLive'),
                                        initialValue: _sousModeLive,
                                        dropdownColor: OtakuColors.surface,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          labelText: 'Sous-mode Live (2-10 joueurs)',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'Tous Ensemble (PopQuiz)', child: Text('1) Tous Ensemble (PopQuiz rapidite)')),
                                          DropdownMenuItem(value: 'La Bombe Otaku (3 Coeurs)', child: Text('2) La Bombe Otaku (3 Coeurs survie)')),
                                          DropdownMenuItem(value: 'Arbre de Tournoi Amis', child: Text('3) Arbre de Tournoi (Quarts -> Finale)')),
                                        ],
                                        onChanged: (v) {
                                          if (v != null) setState(() => _sousModeLive = v);
                                        },
                                      )
                                    else ...[
                                      DropdownButtonFormField<String>(
                                        key: ValueKey('donjon-$_sousModeDonjon'),
                                        initialValue: _sousModeDonjon,
                                        dropdownColor: OtakuColors.surface,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          labelText: 'Format Donjon',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'Defi Classique (10 Q)', child: Text('Defi Classique (10 Q)')),
                                          DropdownMenuItem(value: 'Defi Classique (20 Q)', child: Text('Defi Classique (20 Q)')),
                                          DropdownMenuItem(value: 'Defi Classique (40 Q)', child: Text('Defi Classique (40 Q)')),
                                          DropdownMenuItem(value: 'Survie (3 Coeurs)', child: Text('Survie (3 Coeurs)')),
                                          DropdownMenuItem(value: 'Boss Rush', child: Text('Boss Rush')),
                                        ],
                                        onChanged: (v) {
                                          if (v != null) setState(() => _sousModeDonjon = v);
                                        },
                                      ),
                                      SwitchListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Donjon Public (note 1 a 5 etoiles)', style: TextStyle(fontSize: 11)),
                                        value: _donjonPublic,
                                        onChanged: (v) => setState(() => _donjonPublic = v),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFFD700),
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        onPressed: _busy ? null : () => _creerSession(isDonjon: isDonjon),
                                        child: Text(
                                          coutVc == 0
                                              ? 'CREER GRATUITEMENT (PRIVILEGE VIP)'
                                              : 'CREER POUR $coutVc VC',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Droite : Rejoindre gratuitement (0 VC) par code 6 chiffres
                          Expanded(
                            flex: 4,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: OtakuColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: OtakuColors.pvHaut.withValues(alpha: 0.45)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('REJOINDRE UN AMI (0 VC)', style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: OtakuColors.pvHaut)),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Rejoindre un Salon Live ou affronter le Donjon d\'un autre joueur est 100 % GRATUIT (0 VC) pour tous.',
                                    style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _joinCodeCtrl,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      hintText: 'CODE A 6 CHIFFRES',
                                      counterText: '',
                                      filled: true,
                                      fillColor: OtakuColors.background,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.pvHaut, foregroundColor: Colors.black),
                                    onPressed: () {
                                      final code = _joinCodeCtrl.text.trim();
                                      if (code.length != 6) {
                                        setState(() => _statusMessage = 'Entre un code valide a 6 chiffres.');
                                        return;
                                      }
                                      setState(() => _statusMessage = 'Connexion gratuite (0 VC) au code $code prete des ouverture du Palier !');
                                    },
                                    child: const Text('REJOINDRE GRATUITEMENT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                                  ),
                                  if (_dernierCodeCree != null) ...[
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: OtakuColors.background,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: OtakuColors.accent),
                                      ),
                                      child: Text(
                                        'Dernier code cree : $_dernierCodeCree',
                                        textAlign: TextAlign.center,
                                        style: OtakuTypo.hud.copyWith(fontSize: 13, color: OtakuColors.accent),
                                      ),
                                    ),
                                  ],
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
    );
  }

  Widget _buildTabChip(String label, int idx) {
    final active = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: active ? OtakuColors.accent.withValues(alpha: 0.18) : OtakuColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? OtakuColors.accent : OtakuColors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OtakuTypo.label.copyWith(fontSize: 10, color: active ? Colors.white : OtakuColors.textMuted),
          ),
        ),
      ),
    );
  }
}
