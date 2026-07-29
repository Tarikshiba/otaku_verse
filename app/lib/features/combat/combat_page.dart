import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../quiz/quiz_service.dart';
import '../progression/progression_service.dart';
import '../rewards/rewards_service.dart';
import 'combat_models.dart';
import 'combat_service.dart';

/// === ECRAN DE COMBAT ===
/// Mode PAYSAGE force : deux personnages face a face,
/// barres de PV, question au centre, 4 choix, timer.
/// Inclut des animations de shake et des onomatopees visuelles.

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

class _CombatPageState extends State<CombatPage> with TickerProviderStateMixin {
  final CombatService _combatService = CombatService();

  // Etat du combat
  late CombatState _etat;

  // Nombre reel de questions pour ce combat
  late int _nbQuestionsReelles;

  // Timer par question (20 secondes)
  static const int _tempsParQuestion = 20;
  int _tempsRestant = _tempsParQuestion;
  Timer? _timer;

  // Reponse du joueur ce tour (null = pas encore repondu)
  String? _reponseChoisie;

  // Resultat du dernier tour (pour afficher le feedback)
  ResultatTour? _dernierResultat;

  // Phase d'affichage : 'question', 'feedback', 'termine'
  String _phase = 'question';

  // Compteur de bonnes reponses (pour le calcul d'XP)
  int _bonnesReponses = 0;

  // Donnees de progression (remplies a la fin du combat)
  int _xpGagne = 0;
  Map<String, dynamic>? _profilMisAJour;
  bool _progressionChargee = false;

  // --- ANIMATIONS (DA V2.1 : nerveuses, ~350ms) ---
  // Shake quand le joueur prend des degats (court et violent)
  late AnimationController _shakeJoueur;
  // Shake quand le bot prend des degats
  late AnimationController _shakeBot;
  // Onomatopee qui apparait et disparait (overshoot elastic)
  late AnimationController _onomatopeeController;
  late Animation<double> _onomatopeeOpacity;
  late Animation<double> _onomatopeeScale;
  String _onomatopeeTexte = '';
  Color _onomatopeeCouleur = OtakuColors.accent;
  // Flash d'impact (blanc, bref)
  bool _flashActif = false;
  // Etat combo special (fond rouge/or, screen shake)
  bool _comboSpecialActif = false;
  // Etat critique (PV < 20%)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  // Screen shake global pour combo
  late AnimationController _screenShakeController;

  @override
  void initState() {
    super.initState();
    _nbQuestionsReelles = widget.questions.length;
    _etat = CombatState(nbQuestions: _nbQuestionsReelles);

    // Shake joueur — 150ms, violent
    _shakeJoueur = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Shake bot — 150ms, violent
    _shakeBot = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Onomatopee — rapide avec overshoot
    _onomatopeeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _onomatopeeOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _onomatopeeController,
        curve: const Interval(0.6, 1.0),
      ),
    );
    _onomatopeeScale = Tween<double>(begin: 0.3, end: 1.2).animate(
      CurvedAnimation(
        parent: _onomatopeeController,
        curve: Curves.elasticOut,
      ),
    );

    // Pulse pour PV critique
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Screen shake global pour combo x3
    _screenShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _demarrerTour();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeJoueur.dispose();
    _shakeBot.dispose();
    _onomatopeeController.dispose();
    _pulseController.dispose();
    _screenShakeController.dispose();
    super.dispose();
  }

  /// Demarre un nouveau tour (timer + attente de reponse)
  void _demarrerTour() {
    _tempsRestant = _tempsParQuestion;
    _reponseChoisie = null;
    _dernierResultat = null;
    _phase = 'question';
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_tempsRestant <= 0) {
        timer.cancel();
        _validerReponse(null);
      } else {
        setState(() => _tempsRestant--);
      }
    });
  }

  /// Le joueur clique sur un choix
  void _onChoixSelectionne(String lettre) {
    if (_reponseChoisie != null) return;
    _timer?.cancel();
    _validerReponse(lettre);
  }

  /// Affiche une onomatopee animee
  void _afficherOnomatopee(String texte, Color couleur) {
    _onomatopeeTexte = texte;
    _onomatopeeCouleur = couleur;
    _onomatopeeController.reset();
    _onomatopeeController.forward();
  }

  /// Valide la reponse via le serveur — feedback nerveux DA V2.1
  /// Sequence : flash (60ms) → shake (100ms) → onomatopee overshoot → barre PV → tour suivant
  void _validerReponse(String? reponse) {
    final question = widget.questions[_indexQuestion];

    setState(() {
      _reponseChoisie = reponse ?? '';
    });

    _combatService.jouerTourServeur(
      etat: _etat,
      questionId: question.id,
      reponseJoueur: reponse,
      difficulte: widget.params.difficulte,
    ).then((resultat) async {
      if (!mounted) return;

      if (resultat.joueurCorrect) _bonnesReponses++;

      // === FLASH D'IMPACT (60ms) ===
      if (resultat.degatsInfliges > 0 || resultat.degatsSubis > 0) {
        setState(() => _flashActif = true);
        await Future.delayed(const Duration(milliseconds: 60));
        if (!mounted) return;
        setState(() => _flashActif = false);
      }

      // === SHAKE (100ms, en parallele du reste) ===
      if (resultat.degatsInfliges > 0) {
        _shakeBot.reset();
        _shakeBot.forward();
      }
      if (resultat.degatsSubis > 0) {
        _shakeJoueur.reset();
        _shakeJoueur.forward();
      }

      // === ONOMATOPEE AVEC OVERSHOOT (demarre 60ms apres le shake) ===
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;

      if (resultat.comboJoueurDeclenche || resultat.comboBotDeclenche) {
        // === COMBO x3 : CHANGEMENT D'ETAT TOTAL ===
        setState(() => _comboSpecialActif = true);
        _screenShakeController.reset();
        _screenShakeController.forward();

        // Flash blanc intense
        setState(() => _flashActif = true);
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        setState(() => _flashActif = false);

        // Onomatopee geante
        _afficherOnomatopee(
          resultat.comboJoueurDeclenche ? 'SPECIAL!' : 'BOOM!',
          resultat.comboJoueurDeclenche ? OtakuColors.combo3 : OtakuColors.error,
        );

        // Garder l'etat special visible un moment
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        setState(() => _comboSpecialActif = false);
      } else if (resultat.joueurCorrect && resultat.degatsInfliges > 0) {
        _afficherOnomatopee('HIT!', OtakuColors.pvHaut);
      } else if (!resultat.joueurCorrect && reponse != null) {
        _afficherOnomatopee('MISS', OtakuColors.textMuted);
      }

      // === MISE A JOUR ETAT (barre PV se vide) ===
      setState(() {
        _dernierResultat = resultat;
        _phase = 'feedback';
      });

      // === 1.2 secondes de feedback visible puis tour suivant ===
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      _etat.questionActuelle++;

      if (_etat.estTermine) {
        if (_etat.pvBot <= 0 || _etat.pvJoueur <= 0) {
          _afficherOnomatopee('K.O.!', OtakuColors.warning);
        }
        _finaliserCombat();
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        setState(() => _phase = 'termine');
      } else {
        _demarrerTour();
        setState(() {});
      }
    });
  }

  /// Calcule l'XP gagnee et met a jour le profil + defis + badges dans Supabase
  Future<void> _finaliserCombat() async {
    final victoire = _etat.vainqueur == 'joueur';
    final ko = _etat.pvBot <= 0;
    final sansDegat = _etat.pvJoueur == CombatState.pvDepart;

    _xpGagne = ProgressionService.calculerXpCombat(
      bonnesReponses: _bonnesReponses,
      victoire: victoire,
      ko: ko,
      sansDegat: sansDegat,
    );

    try {
      final progressionService = ProgressionService();
      _profilMisAJour = await progressionService.mettreAJourApresComabat(
        xpGagne: _xpGagne,
        victoire: victoire,
      );

      // Mettre a jour les defis quotidiens
      final rewardsService = RewardsService();
      await rewardsService.mettreAJourDefis(
        victoire: victoire,
        ko: ko,
        bonnesReponses: _bonnesReponses,
      );
    } catch (_) {
      // En cas d'erreur reseau, on affiche quand meme le resultat
    }

    if (mounted) setState(() => _progressionChargee = true);
  }

  /// Index de la question actuelle (0-based pour acceder a la liste)
  int get _indexQuestion => (_etat.questionActuelle - 1).clamp(0, widget.questions.length - 1);

  @override
  Widget build(BuildContext context) {
    if (_phase == 'termine') {
      return _buildEcranResultat();
    }

    final question = widget.questions[_indexQuestion];

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _screenShakeController,
          builder: (context, child) {
            final shake = _screenShakeController.isAnimating
                ? sin(_screenShakeController.value * pi * 6) * 3
                : 0.0;
            return Transform.translate(
              offset: Offset(shake, shake * 0.5),
              child: child,
            );
          },
          child: Stack(
          children: [
            // Overlay fond combo special (rouge/or)
            if (_comboSpecialActif)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      OtakuColors.combo3.withValues(alpha: 0.15),
                      OtakuColors.error.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

            // Contenu principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // --- BARRES DE PV ---
                  _buildBarresPV(),
                  const SizedBox(height: 12),

                  // --- QUESTION ---
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Timer + numero de question
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Q${_etat.questionActuelle}/$_nbQuestionsReelles',
                              style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted),
                            ),
                            const SizedBox(width: 16),
                            _buildTimer(),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Texte de la question
                        Text(
                          question.question,
                          style: OtakuTypo.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // 4 choix en grille 2x2
                        _buildChoix(question),

                        // Feedback du tour
                        if (_phase == 'feedback' && _dernierResultat != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildFeedback(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- FLASH D'IMPACT ---
            _buildFlashOverlay(),

            // --- ONOMATOPEE EN OVERLAY ---
            _buildOnomatopeeOverlay(),

            // --- VIGNETTE PV CRITIQUE ---
            if (_etat.pvJoueur <= 20 || _etat.pvBot <= 20)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) => IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.transparent,
                          OtakuColors.pvCritique.withValues(alpha: 0.12 * _pulseAnimation.value),
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

  /// Overlay des onomatopees — style Bangers, overshoot, glow
  Widget _buildOnomatopeeOverlay() {
    return AnimatedBuilder(
      animation: _onomatopeeController,
      builder: (context, child) {
        if (!_onomatopeeController.isAnimating && _onomatopeeController.status != AnimationStatus.forward) {
          return const SizedBox.shrink();
        }
        return Center(
          child: Opacity(
            opacity: _onomatopeeOpacity.value,
            child: Transform.scale(
              scale: _onomatopeeScale.value,
              child: Text(
                _onomatopeeTexte,
                style: OtakuTypo.impact.copyWith(
                  fontSize: 56,
                  color: _onomatopeeCouleur,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: _onomatopeeCouleur.withValues(alpha: 0.7),
                      blurRadius: 24,
                    ),
                    Shadow(
                      color: _onomatopeeCouleur.withValues(alpha: 0.4),
                      blurRadius: 48,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Overlay flash blanc d'impact
  Widget _buildFlashOverlay() {
    if (!_flashActif) return const SizedBox.shrink();
    return Container(color: Colors.white.withValues(alpha: 0.3));
  }

  /// Barres de PV joueur (gauche) et bot (droite) avec shake
  Widget _buildBarresPV() {
    return Row(
      children: [
        // Joueur (gauche) — shake violent si touche
        Expanded(
          child: AnimatedBuilder(
            animation: _shakeJoueur,
            builder: (context, child) {
              final offset = _shakeJoueur.isAnimating
                  ? sin(_shakeJoueur.value * pi * 8) * 8
                  : 0.0;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: _buildBarrePV(
              label: 'TOI',
              pv: _etat.pvJoueur,
              combo: _etat.comboJoueur,
              alignDroite: false,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Text('VS', style: OtakuTypo.impact.copyWith(fontSize: 20)),
        const SizedBox(width: 24),
        // Bot (droite) — shake violent si touche
        Expanded(
          child: AnimatedBuilder(
            animation: _shakeBot,
            builder: (context, child) {
              final offset = _shakeBot.isAnimating
                  ? sin(_shakeBot.value * pi * 8) * 8
                  : 0.0;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: _buildBarrePV(
              label: 'BOT',
              pv: _etat.pvBot,
              combo: _etat.comboBot,
              alignDroite: true,
            ),
          ),
        ),
      ],
    );
  }

  /// Barre de PV d'un combattant
  Widget _buildBarrePV({
    required String label,
    required int pv,
    required int combo,
    required bool alignDroite,
  }) {
    final pourcentage = pv / CombatState.pvDepart;
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
            Text(label, style: OtakuTypo.hud.copyWith(fontSize: 12)),
            const SizedBox(width: 8),
            Text(
              '$pv/${CombatState.pvDepart}',
              style: OtakuTypo.hud.copyWith(fontSize: 13, color: couleurPV),
            ),
            if (combo > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (combo >= 2 ? OtakuColors.combo3 : OtakuColors.combo2).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: combo >= 2 ? OtakuColors.combo3 : OtakuColors.combo2),
                ),
                child: Text(
                  '×$combo',
                  style: OtakuTypo.hud.copyWith(
                    fontSize: 12,
                    color: combo >= 2 ? OtakuColors.combo3 : OtakuColors.combo2,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
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

  /// Timer visuel
  Widget _buildTimer() {
    final enDanger = _tempsRestant <= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: enDanger ? OtakuColors.error.withValues(alpha: 0.15) : OtakuColors.surface,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: enDanger ? OtakuColors.error : OtakuColors.border),
      ),
      child: Text(
        '${_tempsRestant}s',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: enDanger ? OtakuColors.error : OtakuColors.textPrimary,
        ),
      ),
    );
  }

  /// Grille 2x2 des choix de reponse
  Widget _buildChoix(Question question) {
    final aRepondu = _reponseChoisie != null;
    final choix = question.choix;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildBoutonChoix(choix[0], question.bonneReponse, aRepondu)),
            const SizedBox(width: 8),
            Expanded(child: _buildBoutonChoix(choix[1], question.bonneReponse, aRepondu)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildBoutonChoix(choix[2], question.bonneReponse, aRepondu)),
            const SizedBox(width: 8),
            Expanded(child: _buildBoutonChoix(choix[3], question.bonneReponse, aRepondu)),
          ],
        ),
      ],
    );
  }

  /// Un bouton de choix individuel
  Widget _buildBoutonChoix(MapEntry<String, String> choix, String bonneReponse, bool aRepondu) {
    Color couleurBordure = OtakuColors.border;
    Color couleurFond = Colors.transparent;

    if (aRepondu) {
      if (choix.key == bonneReponse) {
        couleurBordure = OtakuColors.success;
        couleurFond = OtakuColors.success.withValues(alpha: 0.1);
      } else if (choix.key == _reponseChoisie) {
        couleurBordure = OtakuColors.error;
        couleurFond = OtakuColors.error.withValues(alpha: 0.1);
      }
    }

    return GestureDetector(
      onTap: aRepondu ? null : () => _onChoixSelectionne(choix.key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: couleurFond,
          border: Border.all(color: couleurBordure, width: aRepondu ? 2 : 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: couleurBordure, width: 1.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                choix.key,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: couleurBordure == OtakuColors.border
                      ? OtakuColors.textSecondary
                      : couleurBordure,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                choix.value,
                style: TextStyle(
                  fontSize: 13,
                  color: couleurBordure == OtakuColors.border
                      ? OtakuColors.textPrimary
                      : couleurBordure,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Feedback apres reponse (degats infliges/subis, combo)
  Widget _buildFeedback() {
    final r = _dernierResultat!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Feedback joueur (gauche)
        Column(
          children: [
            if (r.joueurCorrect) ...[
              if (r.comboJoueurDeclenche)
                const Text('ATTAQUE SPECIALE !',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OtakuColors.accent)),
              Text(
                'Tu infliges -${r.degatsInfliges} PV',
                style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.success),
              ),
            ] else
              Text(
                'Tu rates...',
                style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted),
              ),
          ],
        ),
        // Feedback bot (droite)
        Column(
          children: [
            if (r.botCorrect) ...[
              if (r.comboBotDeclenche)
                const Text('BOT SPECIAL !',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OtakuColors.error)),
              Text(
                'Bot inflige -${r.degatsSubis} PV',
                style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.error),
              ),
            ] else
              Text(
                'Bot rate !',
                style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted),
              ),
          ],
        ),
      ],
    );
  }

  /// Ecran de resultat — DA V2.1 : victoire explosive, defaite sobre
  Widget _buildEcranResultat() {
    final victoire = _etat.vainqueur == 'joueur';
    final egalite = _etat.vainqueur == 'egalite';
    final ko = _etat.pvBot <= 0 || _etat.pvJoueur <= 0;

    final niveau = _profilMisAJour?['niveau'] ?? 1;
    final ancienNiveau = _profilMisAJour?['ancien_niveau'] ?? niveau;
    final aMonteDeNiveau = niveau > ancienNiveau;
    final rangActuel = _profilMisAJour?['rang'] ?? 'Debutant';

    final couleurTitre = victoire ? OtakuColors.victoire : (egalite ? OtakuColors.pvMoyen : OtakuColors.defaite);

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Fond stylise selon le resultat
            if (victoire)
              // Victoire : radial glow vert/violet
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      OtakuColors.victoire.withValues(alpha: 0.08),
                      OtakuColors.background,
                    ],
                    radius: 1.0,
                  ),
                ),
              )
            else if (!egalite)
              // Defaite : vignette sombre + craquelures visuelles (bandes)
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.transparent,
                      OtakuColors.defaite.withValues(alpha: 0.08),
                    ],
                    radius: 0.8,
                  ),
                ),
              ),

            // Contenu principal
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Titre avec glow
                    Text(
                      victoire ? 'VICTOIRE!' : (egalite ? 'EGALITE' : 'DEFAITE'),
                      style: OtakuTypo.impact.copyWith(
                        fontSize: victoire ? 48 : 40,
                        color: couleurTitre,
                        shadows: [
                          Shadow(color: couleurTitre.withValues(alpha: 0.6), blurRadius: 24),
                          Shadow(color: couleurTitre.withValues(alpha: 0.3), blurRadius: 48),
                        ],
                      ),
                    ),

                    if (ko) ...[
                      const SizedBox(height: 2),
                      Text(
                        'K.O.!',
                        style: OtakuTypo.impact.copyWith(
                          fontSize: 24,
                          color: OtakuColors.combo3,
                          shadows: [Shadow(color: OtakuColors.combo3.withValues(alpha: 0.5), blurRadius: 16)],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Stats PV en row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatResultat('TOI', _etat.pvJoueur, CombatState.pvDepart),
                        const SizedBox(width: 32),
                        Text('VS', style: OtakuTypo.hud.copyWith(color: OtakuColors.textMuted)),
                        const SizedBox(width: 32),
                        _buildStatResultat('BOT', _etat.pvBot, CombatState.pvDepart),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // XP gagnee — carte en verre
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: OtakuColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+$_xpGagne XP',
                            style: OtakuTypo.hud.copyWith(fontSize: 22, color: OtakuColors.accent),
                          ),
                          if (_progressionChargee) ...[
                            const SizedBox(width: 16),
                            Text(
                              'Nv.$niveau · $rangActuel',
                              style: OtakuTypo.bodySmall,
                            ),
                          ],
                          if (aMonteDeNiveau) ...[
                            const SizedBox(width: 12),
                            Text(
                              'LEVEL UP!',
                              style: OtakuTypo.impact.copyWith(fontSize: 16, color: OtakuColors.combo3),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Boutons — REJOUER gros, ACCUEIL subtil
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CombatPage(
                                  questions: widget.questions..shuffle(),
                                  params: widget.params,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          ),
                          child: Text('REJOUER', style: OtakuTypo.label.copyWith(color: Colors.black)),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          child: Text('ACCUEIL', style: OtakuTypo.label.copyWith(color: OtakuColors.accent)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mini stat pour l'ecran resultat (PV restants)
  Widget _buildStatResultat(String label, int pv, int pvMax) {
    final pourcentage = pv / pvMax;
    final couleur = pourcentage <= 0.2 ? OtakuColors.pvCritique : (pourcentage <= 0.5 ? OtakuColors.pvMoyen : OtakuColors.pvHaut);
    return Column(
      children: [
        Text(label, style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),
        const SizedBox(height: 4),
        Text('$pv', style: OtakuTypo.hud.copyWith(fontSize: 24, color: couleur)),
        Text('/$pvMax', style: OtakuTypo.bodySmall.copyWith(fontSize: 11)),
      ],
    );
  }
}
