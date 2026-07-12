import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../quiz/quiz_service.dart';
import '../progression/progression_service.dart';
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

  // --- ANIMATIONS ---
  // Shake quand le joueur prend des degats
  late AnimationController _shakeJoueur;
  // Shake quand le bot prend des degats
  late AnimationController _shakeBot;
  // Onomatopee qui apparait et disparait
  late AnimationController _onomatopeeController;
  late Animation<double> _onomatopeeOpacity;
  late Animation<double> _onomatopeeScale;
  String _onomatopeeTexte = '';
  Color _onomatopeeCouleur = OtakuColors.accent;

  @override
  void initState() {
    super.initState();
    _nbQuestionsReelles = widget.questions.length;
    _etat = CombatState(nbQuestions: _nbQuestionsReelles);

    // Shake joueur (court, rapide)
    _shakeJoueur = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Shake bot
    _shakeBot = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Onomatopee (apparait en gros, puis disparait)
    _onomatopeeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _onomatopeeOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _onomatopeeController,
        curve: const Interval(0.5, 1.0), // Reste visible 50% du temps, puis fade
      ),
    );
    _onomatopeeScale = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _onomatopeeController,
        curve: Curves.elasticOut,
      ),
    );

    _demarrerTour();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeJoueur.dispose();
    _shakeBot.dispose();
    _onomatopeeController.dispose();
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

  /// Valide la reponse, joue le tour, declenche les animations
  void _validerReponse(String? reponse) {
    final question = widget.questions[_indexQuestion];
    final joueurCorrect = reponse == question.bonneReponse;

    setState(() {
      _reponseChoisie = reponse ?? '';
    });

    // Jouer le tour (calcul degats, combo, etc.)
    final resultat = _combatService.jouerTour(
      etat: _etat,
      joueurCorrect: joueurCorrect,
      difficulte: widget.params.difficulte,
    );

    // Compter les bonnes reponses
    if (joueurCorrect) _bonnesReponses++;

    setState(() {
      _dernierResultat = resultat;
      _phase = 'feedback';
    });

    // --- Declencher les animations selon le resultat ---
    if (resultat.degatsInfliges > 0) {
      _shakeBot.reset();
      _shakeBot.forward();
    }
    if (resultat.degatsSubis > 0) {
      _shakeJoueur.reset();
      _shakeJoueur.forward();
    }

    // Onomatopee selon le cas
    if (resultat.comboJoueurDeclenche) {
      _afficherOnomatopee('COMBO !', OtakuColors.accent);
    } else if (resultat.comboBotDeclenche) {
      _afficherOnomatopee('BOOM !', OtakuColors.error);
    } else if (resultat.joueurCorrect && resultat.degatsInfliges > 0) {
      _afficherOnomatopee('HIT !', OtakuColors.success);
    } else if (!joueurCorrect && reponse != null) {
      _afficherOnomatopee('MISS...', OtakuColors.textMuted);
    }

    // Apres 2.5 secondes, passer au tour suivant ou terminer
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;

      _etat.questionActuelle++;

      if (_etat.estTermine) {
        // Onomatopee de fin
        if (_etat.pvBot <= 0 || _etat.pvJoueur <= 0) {
          _afficherOnomatopee('K.O. !', OtakuColors.warning);
        }
        // Calculer et sauvegarder la progression
        _finaliserCombat();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() => _phase = 'termine');
        });
      } else {
        _demarrerTour();
        setState(() {});
      }
    });
  }

  /// Calcule l'XP gagnee et met a jour le profil dans Supabase
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
        child: Stack(
          children: [
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

            // --- ONOMATOPEE EN OVERLAY ---
            _buildOnomatopeeOverlay(),
          ],
        ),
      ),
    );
  }

  /// Overlay des onomatopees (COMBO!, HIT!, BOOM!, K.O.!)
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
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: _onomatopeeCouleur,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: _onomatopeeCouleur.withValues(alpha: 0.5),
                      blurRadius: 20,
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

  /// Barres de PV joueur (gauche) et bot (droite) avec shake
  Widget _buildBarresPV() {
    return Row(
      children: [
        // Joueur (gauche) — shake si touche
        Expanded(
          child: AnimatedBuilder(
            animation: _shakeJoueur,
            builder: (context, child) {
              final offset = _shakeJoueur.isAnimating
                  ? sin(_shakeJoueur.value * pi * 6) * 4
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
        const Text('VS', style: OtakuTypo.impact),
        const SizedBox(width: 24),
        // Bot (droite) — shake si touche
        Expanded(
          child: AnimatedBuilder(
            animation: _shakeBot,
            builder: (context, child) {
              final offset = _shakeBot.isAnimating
                  ? sin(_shakeBot.value * pi * 6) * 4
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
    Color couleurPV = OtakuColors.success;
    if (pourcentage <= 0.25) {
      couleurPV = OtakuColors.error;
    } else if (pourcentage <= 0.5) {
      couleurPV = OtakuColors.warning;
    }

    return Column(
      crossAxisAlignment: alignDroite ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: alignDroite ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Text(label, style: OtakuTypo.label),
            const SizedBox(width: 8),
            Text(
              '$pv/${CombatState.pvDepart}',
              style: OtakuTypo.bodySmall.copyWith(color: couleurPV),
            ),
            if (combo > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: OtakuColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: OtakuColors.accent),
                ),
                child: Text(
                  '×$combo',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: OtakuColors.accent,
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

  /// Ecran de resultat quand le combat est termine
  Widget _buildEcranResultat() {
    final victoire = _etat.vainqueur == 'joueur';
    final egalite = _etat.vainqueur == 'egalite';
    final ko = _etat.pvBot <= 0 || _etat.pvJoueur <= 0;

    // Infos de progression
    final niveau = _profilMisAJour?['niveau'] ?? 1;
    final ancienNiveau = _profilMisAJour?['ancien_niveau'] ?? niveau;
    final aMonteDeNiveau = niveau > ancienNiveau;
    final rangActuel = _profilMisAJour?['rang'] ?? 'Debutant';

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Titre victoire/defaite
                Text(
                  victoire ? 'VICTOIRE !' : (egalite ? 'EGALITE' : 'DEFAITE...'),
                  style: OtakuTypo.impact.copyWith(
                    fontSize: 36,
                    color: victoire ? OtakuColors.success : (egalite ? OtakuColors.warning : OtakuColors.error),
                  ),
                ),
                const SizedBox(height: 8),

                if (ko)
                  Text(
                    'K.O. !',
                    style: OtakuTypo.headlineLarge.copyWith(color: OtakuColors.warning),
                  ),

                const SizedBox(height: 20),

                // Stats PV
                Text('PV restants : ${_etat.pvJoueur}/${CombatState.pvDepart}',
                    style: OtakuTypo.bodyLarge),
                Text('PV du bot : ${_etat.pvBot}/${CombatState.pvDepart}',
                    style: OtakuTypo.bodySmall),

                const SizedBox(height: 20),

                // --- XP GAGNEE ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: OtakuColors.surface,
                    border: Border.all(color: OtakuColors.accent),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '+$_xpGagne XP',
                        style: OtakuTypo.headlineLarge.copyWith(color: OtakuColors.accent),
                      ),
                      const SizedBox(height: 4),
                      if (_progressionChargee) ...[
                        Text(
                          'Niveau $niveau — $rangActuel',
                          style: OtakuTypo.bodySmall,
                        ),
                        if (aMonteDeNiveau)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'LEVEL UP !',
                              style: OtakuTypo.impact.copyWith(fontSize: 18),
                            ),
                          ),
                      ] else
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Boutons
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
                      child: const Text('REJOUER'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text('ACCUEIL'),
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
}
