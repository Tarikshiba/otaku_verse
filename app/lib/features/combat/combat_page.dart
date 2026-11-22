import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../shared/rank_badge.dart';
import '../../shared/victory_share_card.dart';
import '../economy/economy_v92_service.dart';
import '../progression/progression_service.dart';
import '../quiz/quiz_service.dart';
import '../rewards/rewards_service.dart';
import '../skins/skin_service.dart';
import '../social/friends_service.dart';
import 'combat_models.dart';
import 'combat_service.dart';

/// === ECRAN DE COMBAT V9.2 (350 PV / 40 Q / DOUBLE TIMER 2 MIN / 5 MALUS) ===
/// - Chrono Global 02:00 en haut (en pause pendant les animations) + Timer 20s/question
/// - Auto-sizing des textes longs (Ticket UI-03) et anti-overflow (UI-02)
/// - Badge de Rang officiel permanent (ECO-04)
/// - 5 Malus Flutter : Texte Inverse, Miroir, Sans Voyelles, Brouillard d'Encre, Eclipse 2,5s
/// - Seconde Chance Solo (+100 PV) et Bouton Roi "Doubler mes OC (x2)" en fin de match
class CombatPage extends StatefulWidget {
  final List<Question> questions;
  final CombatParams params;

  const CombatPage({
    super.key,
    required this.questions,
    required this.params,
  });

  @override
  State<CombatPage> createState() => _CombatPageState();
}

enum _MalusType { aucun, inverse, miroir, sansVoyelles, brouillard, eclipse }

class _CombatPageState extends State<CombatPage> with TickerProviderStateMixin {
  final CombatService _combatService = CombatService();
  final EconomyV92Service _economyService = EconomyV92Service();
  final ProgressionService _progressionService = ProgressionService();
  final Random _rng = Random();

  late CombatState _etat;
  late int _nbQuestionsReelles;

  // Double Timer officiel V9.2 (§7.2)
  static const int _tempsParQuestion = 20;
  int _tempsRestantQuestion = _tempsParQuestion;
  int _chronoGlobalRestantSec = CombatState.chronoGlobalSec;
  Timer? _timer;
  DateTime _questionStartTime = DateTime.now();

  String? _reponseChoisie;
  ResultatTour? _dernierResultat;
  String _phase = 'question'; // 'question', 'feedback', 'termine'
  int _bonnesReponses = 0;
  int _questionsRepondues = 0;
  int _hayaCount = 0;
  int _maxCombo = 0;
  int _totalResponseMs = 0;
  bool _estMortSubite = false;

  // 5 Malus (§7.5)
  _MalusType _malusActif = _MalusType.aucun;
  bool _brouillardGratte = false;
  bool _eclipseCachee = false;

  // Profil & bilan serveur fin de match
  int _monNiveau = 1;
  String _monPseudo = 'TOI';
  String _monSkinKey = 'skin_default';
  Map<String, dynamic>? _summaryServeur;
  bool _doubleOcDejaReclame = false;
  bool _doublageEnCours = false;
  bool _secondeChanceActive = false;

  // Animations nerveuses (< 350ms)
  late AnimationController _shakeJoueur;
  late AnimationController _shakeBot;
  late AnimationController _onomatopeeController;
  late Animation<double> _onomatopeeOpacity;
  late Animation<double> _onomatopeeScale;
  String _onomatopeeTexte = '';
  Color _onomatopeeCouleur = OtakuColors.accent;
  bool _flashActif = false;
  bool _comboSpecialActif = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _screenShakeController;

  @override
  void initState() {
    super.initState();
    FriendsService().setEnCombat(true);
    _nbQuestionsReelles = widget.questions.length;
    _etat = CombatState(nbQuestions: _nbQuestionsReelles);
    _chargerInfosJoueur();

    _shakeJoueur = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _shakeBot = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _onomatopeeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _onomatopeeOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _onomatopeeController, curve: const Interval(0.6, 1.0)),
    );
    _onomatopeeScale = Tween<double>(begin: 0.3, end: 1.2).animate(
      CurvedAnimation(parent: _onomatopeeController, curve: Curves.elasticOut),
    );
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _screenShakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    _demarrerTour();
  }

  Future<void> _chargerInfosJoueur() async {
    try {
      final p = await _progressionService.recupererProfil();
      final skins = await SkinService().tousLesSkins();
      final equipe = skins.where((s) => s.equipped).firstOrNull;
      if (!mounted) return;
      setState(() {
        if (p != null) {
          _monNiveau = (p['niveau'] as num?)?.toInt() ?? 1;
          _monPseudo = p['pseudo']?.toString() ?? 'TOI';
        }
        if (equipe != null && equipe.imageKey.isNotEmpty) {
          _monSkinKey = equipe.imageKey;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    FriendsService().setEnCombat(false);
    _timer?.cancel();
    _shakeJoueur.dispose();
    _shakeBot.dispose();
    _onomatopeeController.dispose();
    _pulseController.dispose();
    _screenShakeController.dispose();
    super.dispose();
  }

  /// Tire un Malus selon le contrat choisi (Zen = 0%, Normal = 20%, Malicieux = 55%)
  _MalusType _tirerMalusPourTour() {
    if (widget.params.malusMode == 'zen' || _estMortSubite) return _MalusType.aucun;
    final proba = widget.params.malusMode == 'malicieux' ? 0.55 : 0.20;
    if (_rng.nextDouble() >= proba) return _MalusType.aucun;
    const pool = [
      _MalusType.inverse,
      _MalusType.miroir,
      _MalusType.sansVoyelles,
      _MalusType.brouillard,
      _MalusType.eclipse,
    ];
    return pool[_rng.nextInt(pool.length)];
  }

  void _demarrerTour({bool mortSubite = false}) {
    _estMortSubite = mortSubite;
    _tempsRestantQuestion = mortSubite ? 5 : _tempsParQuestion;
    _reponseChoisie = null;
    _dernierResultat = null;
    _phase = 'question';
    _malusActif = _tirerMalusPourTour();
    _brouillardGratte = false;
    _eclipseCachee = false;
    _questionStartTime = DateTime.now();

    // Si Malus Eclipse : cache la question apres 2,5 secondes
    if (_malusActif == _MalusType.eclipse) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted && _phase == 'question' && _reponseChoisie == null) {
          setState(() => _eclipseCachee = true);
        }
      });
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_tempsRestantQuestion <= 0) {
        timer.cancel();
        _validerReponse(null);
      } else {
        setState(() {
          _tempsRestantQuestion--;
          if (!_estMortSubite && _chronoGlobalRestantSec > 0) {
            _chronoGlobalRestantSec--;
          }
        });
      }
    });
  }

  void _onChoixSelectionne(String lettre) {
    if (_reponseChoisie != null || _secondeChanceActive) return;
    _timer?.cancel();
    _validerReponse(lettre);
  }

  void _afficherOnomatopee(String texte, Color couleur) {
    _onomatopeeTexte = texte;
    _onomatopeeCouleur = couleur;
    _onomatopeeController.reset();
    _onomatopeeController.forward();
  }

  Future<void> _validerReponse(String? reponse) async {
    final question = widget.questions[_indexQuestion];
    final elapsedMs = DateTime.now().difference(_questionStartTime).inMilliseconds;

    setState(() {
      _reponseChoisie = reponse ?? '';
    });

    try {
      final resultat = await _combatService.jouerTourV92(
        etat: _etat,
        matchId: widget.params.matchId,
        question: question,
        reponseJoueur: reponse,
        responseTimeMs: elapsedMs,
        difficulte: widget.params.difficulte,
      );

      if (!mounted) return;

      _questionsRepondues++;
      _totalResponseMs += elapsedMs.clamp(100, 20000);
      if (resultat.joueurCorrect) _bonnesReponses++;
      if (resultat.hayaTriggered) _hayaCount++;
      if (_etat.comboJoueur > _maxCombo) _maxCombo = _etat.comboJoueur;
      if (resultat.remainingGlobalMs != null) {
        _chronoGlobalRestantSec = (resultat.remainingGlobalMs! / 1000).ceil();
      }

      // Flash & vibration haptique (< 350ms)
      if (resultat.degatsInfliges > 0 || resultat.degatsSubis > 0) {
        HapticFeedback.heavyImpact();
        setState(() => _flashActif = true);
        await Future.delayed(const Duration(milliseconds: 60));
        if (!mounted) return;
        setState(() => _flashActif = false);
      }

      if (resultat.degatsInfliges > 0) {
        _shakeBot.reset();
        _shakeBot.forward();
      }
      if (resultat.degatsSubis > 0) {
        _shakeJoueur.reset();
        _shakeJoueur.forward();
      }

      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;

      // Onomatopees officielles V9.2 (HAYA!!, CLASH!, COMBO x3, MISS)
      if (resultat.comboJoueurDeclenche || resultat.comboBotDeclenche) {
        setState(() => _comboSpecialActif = true);
        _screenShakeController.reset();
        _screenShakeController.forward();
        _afficherOnomatopee(
          resultat.comboJoueurDeclenche
              ? (resultat.hayaTriggered ? 'COMBO + HAYA!!' : 'COMBO ×3!')
              : 'BOOM!',
          resultat.comboJoueurDeclenche ? OtakuColors.combo3 : OtakuColors.error,
        );
        await Future.delayed(const Duration(milliseconds: 360));
        if (!mounted) return;
        setState(() => _comboSpecialActif = false);
      } else if (resultat.clashWinner != null) {
        _afficherOnomatopee(
          resultat.clashWinner == 'p1' ? 'CLASH · 1ER!' : 'CLASH!',
          const Color(0xFF4CC9F0),
        );
      } else if (resultat.hayaTriggered) {
        _afficherOnomatopee('HAYA!!', const Color(0xFF3FFFB0));
      } else if (resultat.joueurCorrect) {
        _afficherOnomatopee('HIT!', OtakuColors.pvHaut);
      } else {
        _afficherOnomatopee('AUTO-FAUTE -5', OtakuColors.error);
      }

      setState(() {
        _dernierResultat = resultat;
        _phase = 'feedback';
        if (resultat.summary != null) {
          _summaryServeur = resultat.summary;
        }
      });

      await Future.delayed(const Duration(milliseconds: 1050));
      if (!mounted) return;

      // Cas 1 : Seconde Chance Solo (+100 PV pendant 5s)
      if (resultat.canSecondChance && widget.params.matchId != null) {
        await _proposerSecondeChance();
        return;
      }

      // Cas 2 : Question Unique de Mort Subite (0 PV simultane)
      if (resultat.suddenDeathTriggered) {
        _afficherOnomatopee('MORT SUBITE!', OtakuColors.pvCritique);
        if (_etat.questionActuelle < _nbQuestionsReelles) {
          _etat.questionActuelle++;
        }
        _demarrerTour(mortSubite: true);
        setState(() {});
        return;
      }

      // Cas 3 : Match termine cote serveur ou plus de questions
      if (resultat.matchFinished || _etat.estTermine || _chronoGlobalRestantSec <= 0) {
        if (_etat.pvBot <= 0 || _etat.pvJoueur <= 0) {
          _afficherOnomatopee('KECCHAKU!', OtakuColors.combo3);
        }
        await _finaliserSiNecessaire();
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        setState(() => _phase = 'termine');
        return;
      }

      // Tour suivant
      _etat.questionActuelle++;
      _demarrerTour();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur reseau : $e')),
      );
      _etat.questionActuelle++;
      if (_etat.estTermine) {
        setState(() => _phase = 'termine');
      } else {
        _demarrerTour();
        setState(() {});
      }
    }
  }

  /// Popup Seconde Chance (Mode Solo uniquement : +100 PV sur 350 PV, 1 fois/match)
  Future<void> _proposerSecondeChance() async {
    _secondeChanceActive = true;
    final bool? revive = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: OtakuColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: OtakuColors.combo3),
        ),
        title: Text('SECONDE CHANCE !', style: OtakuTypo.headlineLarge.copyWith(color: OtakuColors.combo3)),
        content: Text(
          'Tu es tombe a 0 PV ! Regarde une pub volontaire (ou paie 30 OC) pour ressusciter avec 100 PV sur 350 PV et continuer le duel.',
          style: OtakuTypo.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ABANDONNER', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.combo3, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.favorite_rounded, size: 16),
            label: const Text('+100 PV (PUB)'),
          ),
        ],
      ),
    );
    _secondeChanceActive = false;

    if (!mounted) return;
    if (revive == true && widget.params.matchId != null) {
      try {
        await _economyService.activerSecondeChance(widget.params.matchId!, payWithOc: false);
        setState(() => _etat.pvJoueur = 100);
        _etat.questionActuelle++;
        _demarrerTour();
        setState(() {});
        return;
      } catch (_) {}
    }

    // Refus de Seconde Chance -> cloture definitive cote serveur
    await _finaliserSiNecessaire();
    if (mounted) setState(() => _phase = 'termine');
  }

  Future<void> _finaliserSiNecessaire() async {
    if (_summaryServeur == null && widget.params.matchId != null) {
      try {
        final res = await _economyService.cloturerMatch(
          matchId: widget.params.matchId!,
          abandon: false,
        );
        if (res['summary'] is Map) {
          _summaryServeur = Map<String, dynamic>.from(res['summary']);
        }
      } catch (_) {}
    }
    try {
      final won = _summaryServeur?['won'] == true || _etat.vainqueur == 'joueur';
      await RewardsService().mettreAJourDefis(
        victoire: won,
        ko: _etat.pvBot <= 0,
        bonnesReponses: _bonnesReponses,
      );
    } catch (_) {}
  }

  Future<void> _confirmerQuitter() async {
    final bool? quitter = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OtakuColors.surface,
        title: Text('ABANDONNER LE MATCH ?', style: OtakuTypo.headlineSmall),
        content: Text(
          'Un abandon retire -50 XP a tous les niveaux, detruit les frais OC et applique un cooldown de 5 minutes.',
          style: OtakuTypo.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CONTINUER', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ABANDONNER'),
          ),
        ],
      ),
    );

    if (quitter == true) {
      _timer?.cancel();
      if (widget.params.matchId != null) {
        try {
          await _economyService.cloturerMatch(matchId: widget.params.matchId!, abandon: true);
        } catch (_) {}
      }
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  /// Formate le texte selon le Malus actif (§7.5)
  String _appliquerTexteMalus(String texte) {
    if (_malusActif == _MalusType.inverse) {
      return String.fromCharCodes(texte.runes.toList().reversed);
    }
    if (_malusActif == _MalusType.sansVoyelles) {
      return texte.replaceAll(RegExp(r'[aeiouyAEIOUYàâäéèêëîïôöùûü]'), '_');
    }
    return texte;
  }

  /// Auto-sizing de la police selon la longueur du texte (Ticket UI-03)
  double _taillePoliceQuestion(String texte) {
    if (texte.length > 150) return 12.0;
    if (texte.length > 110) return 13.5;
    return 15.0;
  }

  double _taillePoliceChoix(String texte) {
    if (texte.length > 65) return 11.0;
    if (texte.length > 40) return 12.0;
    return 13.0;
  }

  String _formatChronoGlobal() {
    final mins = (_chronoGlobalRestantSec ~/ 60).toString().padLeft(2, '0');
    final secs = (_chronoGlobalRestantSec % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  int get _indexQuestion => (_etat.questionActuelle - 1).clamp(0, widget.questions.length - 1);

  @override
  Widget build(BuildContext context) {
    if (_phase == 'termine') {
      return _buildEcranResultat();
    }

    final question = widget.questions[_indexQuestion];
    final texteAffiche = _appliquerTexteMalus(question.question);

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _screenShakeController,
          builder: (context, child) {
            final shake = _screenShakeController.isAnimating
                ? sin(_screenShakeController.value * pi * 6) * 4
                : 0.0;
            return Transform.translate(offset: Offset(shake, shake * 0.5), child: child);
          },
          child: Stack(
            children: [
              if (_comboSpecialActif)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        OtakuColors.combo3.withValues(alpha: 0.16),
                        OtakuColors.error.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(
                  children: [
                    // === BARRES DE PV 350 + CHRONO GLOBAL 02:00 + BADGE RANG ===
                    _buildBarresPV(),
                    const SizedBox(height: 6),

                    // === ZONE QUESTION + CHOIX (scrollable si texte tres long : UI-02/UI-03) ===
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Ligne info : Qx/40, Timer 20s, badge Malus, Quitter
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _estMortSubite
                                      ? 'MORT SUBITE (1 PV)'
                                      : 'Q${_etat.questionActuelle}/$_nbQuestionsReelles',
                                  style: OtakuTypo.label.copyWith(
                                    color: _estMortSubite ? OtakuColors.pvCritique : OtakuColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _buildTimer(),
                                if (_malusActif != _MalusType.aucun) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: OtakuColors.modeDuel.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: OtakuColors.modeDuel),
                                    ),
                                    child: Text(
                                      'MALUS : ${_malusActif.name.toUpperCase()}',
                                      style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.modeDuel),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: _confirmerQuitter,
                                  child: const Icon(Icons.flag_outlined, size: 18, color: OtakuColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Carte question avec gestion des 5 Malus et auto-sizing (UI-03)
                            _buildQuestionCard(texteAffiche),
                            const SizedBox(height: 10),

                            // Grille des choix (2 ou 4 selon variante V9.2)
                            _buildChoix(question),

                            if (_phase == 'feedback' && _dernierResultat != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _buildFeedback(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _buildFlashOverlay(),
              _buildOnomatopeeOverlay(),

              // Vignette PV critique (< 20 % = 70 PV sur 350)
              if (_etat.pvJoueur <= 70 || _etat.pvBot <= 70)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) => IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.transparent,
                            OtakuColors.pvCritique.withValues(alpha: 0.14 * _pulseAnimation.value),
                          ],
                          radius: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(String texteAffiche) {
    Widget textWidget = Text(
      _eclipseCachee ? 'ECLIPSE ACTIVE ! Reponds de memoire !' : texteAffiche,
      style: OtakuTypo.bodyLarge.copyWith(
        fontSize: _taillePoliceQuestion(texteAffiche),
        height: 1.35,
      ),
      textAlign: TextAlign.center,
    );

    if (_malusActif == _MalusType.miroir && !_eclipseCachee) {
      textWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(pi),
        child: textWidget,
      );
    }

    if (_malusActif == _MalusType.brouillard && !_brouillardGratte) {
      return GestureDetector(
        onTap: () => setState(() => _brouillardGratte = true),
        onPanUpdate: (_) => setState(() => _brouillardGratte = true),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: OtakuColors.modeDuel),
          ),
          child: Text(
            'BROUILLARD D\'ENCRE : Touche ou gratte pour reveler la question !',
            textAlign: TextAlign.center,
            style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: OtakuColors.modeDuel),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: OtakuColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OtakuColors.border),
      ),
      child: textWidget,
    );
  }

  Widget _buildOnomatopeeOverlay() {
    return AnimatedBuilder(
      animation: _onomatopeeController,
      builder: (context, child) {
        if (!_onomatopeeController.isAnimating && _onomatopeeController.status != AnimationStatus.forward) {
          return const SizedBox.shrink();
        }
        return IgnorePointer(
          child: Center(
            child: Opacity(
              opacity: _onomatopeeOpacity.value,
              child: Transform.scale(
                scale: _onomatopeeScale.value,
                child: Text(
                  _onomatopeeTexte,
                  style: OtakuTypo.impact.copyWith(
                    fontSize: 48,
                    color: _onomatopeeCouleur,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(color: _onomatopeeCouleur.withValues(alpha: 0.7), blurRadius: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlashOverlay() {
    if (!_flashActif) return const SizedBox.shrink();
    return IgnorePointer(child: Container(color: Colors.white.withValues(alpha: 0.28)));
  }

  Widget _buildBarresPV() {
    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _shakeJoueur,
            builder: (context, child) {
              final offset = _shakeJoueur.isAnimating ? sin(_shakeJoueur.value * pi * 8) * 8 : 0.0;
              return Transform.translate(offset: Offset(offset, 0), child: child);
            },
            child: _buildBarrePV(
              label: _monPseudo,
              niveau: _monNiveau,
              pv: _etat.pvJoueur,
              combo: _etat.comboJoueur,
              alignDroite: false,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Chrono Global 02:00 au centre (§7.2)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _chronoGlobalRestantSec <= 20
                ? OtakuColors.pvCritique.withValues(alpha: 0.2)
                : OtakuColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _chronoGlobalRestantSec <= 20 ? OtakuColors.pvCritique : OtakuColors.accent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatChronoGlobal(),
                style: OtakuTypo.hud.copyWith(
                  fontSize: 13,
                  color: _chronoGlobalRestantSec <= 20 ? OtakuColors.pvCritique : OtakuColors.textPrimary,
                ),
              ),
              Text('VS', style: OtakuTypo.label.copyWith(fontSize: 8, color: OtakuColors.accent)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedBuilder(
            animation: _shakeBot,
            builder: (context, child) {
              final offset = _shakeBot.isAnimating ? sin(_shakeBot.value * pi * 8) * 8 : 0.0;
              return Transform.translate(offset: Offset(offset, 0), child: child);
            },
            child: _buildBarrePV(
              label: widget.params.opponentPseudo,
              divisionId: widget.params.opponentDivisionId,
              pv: _etat.pvBot,
              combo: _etat.comboBot,
              alignDroite: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarrePV({
    required String label,
    int? niveau,
    int? divisionId,
    required int pv,
    required int combo,
    required bool alignDroite,
  }) {
    final pourcentage = (pv / CombatState.pvDepart).clamp(0.0, 1.0);
    Color couleurPV = OtakuColors.pvHaut;
    if (pourcentage <= 0.2) {
      couleurPV = OtakuColors.pvCritique;
    } else if (pourcentage <= 0.5) {
      couleurPV = OtakuColors.pvMoyen;
    }

    return Column(
      crossAxisAlignment: alignDroite ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: alignDroite ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OtakuTypo.hud.copyWith(fontSize: 11),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$pv/${CombatState.pvDepart}',
              style: OtakuTypo.hud.copyWith(fontSize: 12, color: couleurPV),
            ),
            if (combo > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (combo % 3 == 2 ? OtakuColors.combo3 : OtakuColors.combo2).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '×$combo',
                  style: OtakuTypo.hud.copyWith(
                    fontSize: 10,
                    color: combo % 3 == 2 ? OtakuColors.combo3 : OtakuColors.combo2,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (niveau != null) ...[
          const SizedBox(height: 2),
          OfficialRankBadge(niveau: niveau, divisionId: divisionId, compact: true),
        ],
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pourcentage,
            minHeight: 8,
            backgroundColor: OtakuColors.border,
            valueColor: AlwaysStoppedAnimation(couleurPV),
          ),
        ),
      ],
    );
  }

  Widget _buildTimer() {
    final enDanger = _tempsRestantQuestion <= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: enDanger ? OtakuColors.pvCritique.withValues(alpha: 0.16) : OtakuColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: enDanger ? OtakuColors.pvCritique : OtakuColors.border),
      ),
      child: Text(
        '${_tempsRestantQuestion}s',
        style: OtakuTypo.hud.copyWith(
          fontSize: 13,
          color: enDanger ? OtakuColors.pvCritique : OtakuColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildChoix(Question question) {
    final aRepondu = _reponseChoisie != null;
    final bonneReponseServeur = _dernierResultat?.bonneReponse ?? '';
    final choix = question.choix;

    if (choix.length <= 2) {
      return Row(
        children: [
          Expanded(child: _buildBoutonChoix(choix[0], bonneReponseServeur, aRepondu)),
          const SizedBox(width: 8),
          if (choix.length > 1)
            Expanded(child: _buildBoutonChoix(choix[1], bonneReponseServeur, aRepondu)),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildBoutonChoix(choix[0], bonneReponseServeur, aRepondu)),
            const SizedBox(width: 8),
            Expanded(child: _buildBoutonChoix(choix[1], bonneReponseServeur, aRepondu)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildBoutonChoix(choix[2], bonneReponseServeur, aRepondu)),
            const SizedBox(width: 8),
            if (choix.length > 3)
              Expanded(child: _buildBoutonChoix(choix[3], bonneReponseServeur, aRepondu))
            else
              const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildBoutonChoix(MapEntry<String, String> choix, String bonneReponse, bool aRepondu) {
    Color couleurBordure = OtakuColors.border;
    Color couleurFond = OtakuColors.surface;

    if (aRepondu && _dernierResultat != null) {
      if (bonneReponse.isNotEmpty && choix.key == bonneReponse) {
        couleurBordure = OtakuColors.success;
        couleurFond = OtakuColors.success.withValues(alpha: 0.14);
      } else if (choix.key == _reponseChoisie) {
        couleurBordure = _dernierResultat!.joueurCorrect ? OtakuColors.success : OtakuColors.error;
        couleurFond = couleurBordure.withValues(alpha: 0.14);
      }
    }

    return GestureDetector(
      onTap: aRepondu ? null : () => _onChoixSelectionne(choix.key),
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: couleurFond,
          border: Border.all(color: couleurBordure, width: aRepondu ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: couleurBordure, width: 1.5),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                choix.key,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: couleurBordure == OtakuColors.border ? OtakuColors.textSecondary : couleurBordure,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                choix.value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _taillePoliceChoix(choix.value),
                  color: couleurBordure == OtakuColors.border ? OtakuColors.textPrimary : couleurBordure,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final r = _dernierResultat!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: Text(
            r.joueurCorrect
                ? 'Tu infliges -${r.degatsInfliges} PV${r.hayaTriggered ? " (HAYA!!)" : ""}'
                : 'Rate (-5 PV Auto-faute)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OtakuTypo.bodySmall.copyWith(
              color: r.joueurCorrect ? OtakuColors.success : OtakuColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Flexible(
          child: Text(
            r.botCorrect
                ? '${widget.params.opponentPseudo} inflige -${r.degatsSubis} PV'
                : '${widget.params.opponentPseudo} rate (-5 PV)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OtakuTypo.bodySmall.copyWith(
              color: r.botCorrect ? OtakuColors.error : OtakuColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEcranResultat() {
    final s = _summaryServeur;
    final bool victoire = s != null ? s['won'] == true : _etat.vainqueur == 'joueur';
    final int scenario = (s?['scenario_code'] as num?)?.toInt() ?? 3;
    final bool egalite = scenario == 4 || scenario == 5 || (s == null && _etat.vainqueur == 'egalite');
    final bool ko = s?['ended_by_ko'] == true || _etat.pvBot <= 0 || _etat.pvJoueur <= 0;

    final int deltaXp = (s?['delta_xp'] as num?)?.toInt() ?? 0;
    final int newLevel = (s?['new_level'] as num?)?.toInt() ?? _monNiveau;
    final int ocPerf = (s?['oc_performance_net'] as num?)?.toInt() ?? 0;
    final int ocRefund = (s?['oc_refund'] as num?)?.toInt() ?? 0;
    final int deltaDiv = (s?['delta_division_pts'] as num?)?.toInt() ?? 0;
    final bool canDoubleOc = s?['can_double_oc'] == true && !_doubleOcDejaReclame && widget.params.matchId != null;

    final couleurTitre = victoire ? OtakuColors.victoire : (egalite ? OtakuColors.pvMoyen : OtakuColors.defaite);

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    victoire ? (ko ? 'VICTOIRE K.O.!' : 'VICTOIRE!') : (egalite ? 'MATCH NUL' : 'DEFAITE'),
                    style: OtakuTypo.impact.copyWith(fontSize: 42, color: couleurTitre),
                  ),
                  const SizedBox(height: 6),
                  OfficialRankBadge(
                    niveau: newLevel,
                    divisionId: (s?['new_division_id'] as num?)?.toInt(),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatResultat(_monPseudo, _etat.pvJoueur, CombatState.pvDepart),
                      const SizedBox(width: 28),
                      Text('VS', style: OtakuTypo.hud.copyWith(color: OtakuColors.textMuted)),
                      const SizedBox(width: 28),
                      _buildStatResultat(widget.params.opponentPseudo, _etat.pvBot, CombatState.pvDepart),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Bilan serveur XP / OC / Division
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildRewardChip(
                        '${deltaXp >= 0 ? "+" : ""}$deltaXp XP',
                        deltaXp >= 0 ? OtakuColors.accent : OtakuColors.error,
                      ),
                      if (ocPerf > 0 || ocRefund > 0)
                        _buildRewardChip(
                          '+${ocPerf + ocRefund} OC${_doubleOcDejaReclame ? " (×2)" : ""}',
                          const Color(0xFF4CC9F0),
                        ),
                      if (widget.params.mode == 'division')
                        _buildRewardChip(
                          '${deltaDiv >= 0 ? "+" : ""}$deltaDiv PTS DIV',
                          deltaDiv >= 0 ? OtakuColors.victoire : OtakuColors.error,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bouton Roi : Doubler mes OC (x2) via pub volontaire (ECO-06)
                  if (canDoubleOc) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CC9F0),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _doublageEnCours ? null : _activerDoubleOc,
                      icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                      label: Text('DOUBLER MES OC (+$ocPerf OC · PUB)'),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _partagerResultat,
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: Text(
                          victoire ? 'PARTAGER MA VICTOIRE (9:16)' : 'PARTAGER',
                          style: OtakuTypo.label.copyWith(color: OtakuColors.accent),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                        child: Text('ACCUEIL', style: OtakuTypo.label.copyWith(color: Colors.black)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Future<void> _activerDoubleOc() async {
    if (widget.params.matchId == null) return;
    setState(() => _doublageEnCours = true);
    try {
      final res = await _economyService.doublerOcMatch(widget.params.matchId!);
      if (!mounted) return;
      final bonus = (res['bonus_oc'] as num?)?.toInt() ?? 0;
      setState(() {
        _doubleOcDejaReclame = true;
        _doublageEnCours = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+$bonus Otaku Coins bonus credites !')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _doublageEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Widget _buildRewardChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(text, style: OtakuTypo.hud.copyWith(fontSize: 14, color: color)),
    );
  }

  Future<void> _partagerResultat() async {
    final s = _summaryServeur;
    final int newLevel = (s?['new_level'] as num?)?.toInt() ?? _monNiveau;
    final int? divId = (s?['new_division_id'] as num?)?.toInt();
    final bool ko = s?['ended_by_ko'] == true || _etat.pvBot <= 0;
    final int ocPerf = (s?['oc_performance_net'] as num?)?.toInt() ?? 0;
    final double avgSec = _questionsRepondues > 0 ? (_totalResponseMs / _questionsRepondues / 1000.0) : 0.0;

    final String modeLabel = widget.params.mode == 'division' ? 'Division Mondiale' : 'Combat Solo';
    final String animeNom = widget.params.anime ?? 'TOUS';
    final String workLabel = animeNom == 'TOUS'
        ? 'Mix 21 Oeuvres'
        : (widget.params.arc != null ? '$animeNom (${widget.params.arc})' : animeNom);

    await showDialog(
      context: context,
      builder: (_) => VictoryShareCardDialog(
        data: VictoryShareData(
          modeLabel: modeLabel,
          workAndArc: workLabel,
          winnerPseudo: _monPseudo,
          winnerSkinKey: _monSkinKey,
          winnerLevel: newLevel,
          winnerDivisionId: divId,
          isKo: ko,
          winnerHpRemaining: _etat.pvJoueur,
          initialHp: CombatState.pvDepart,
          correctAnswers: _bonnesReponses,
          totalQuestionsPlayed: _questionsRepondues > 0 ? _questionsRepondues : _etat.questionActuelle,
          avgResponseSec: avgSec,
          hayaCount: _hayaCount,
          maxCombo: _maxCombo,
          matchOcGained: ocPerf,
          opponentDivisionId: divId ?? 10,
          opponentRankTitle: EconomyV92Service.titreRangOfficiel(newLevel),
        ),
      ),
    );
  }

  Widget _buildStatResultat(String label, int pv, int pvMax) {
    final pct = pv / pvMax;
    final couleur = pct <= 0.2 ? OtakuColors.pvCritique : (pct <= 0.5 ? OtakuColors.pvMoyen : OtakuColors.pvHaut);
    return Column(
      children: [
        Text(label, style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),
        const SizedBox(height: 2),
        Text('$pv', style: OtakuTypo.hud.copyWith(fontSize: 22, color: couleur)),
        Text('/$pvMax', style: OtakuTypo.bodySmall.copyWith(fontSize: 10)),
      ],
    );
  }
}
