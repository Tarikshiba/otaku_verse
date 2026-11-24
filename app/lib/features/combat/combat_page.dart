import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../shared/rank_badge.dart';
import '../../shared/victory_share_card.dart';
import '../core/analytics_service.dart';
import '../economy/economy_v92_service.dart';
import '../progression/progression_service.dart';
import '../quiz/quiz_service.dart';
import '../rewards/rewards_service.dart';
import '../skins/skin_service.dart';
import '../social/friends_service.dart';
import '../verse/verse_division_page.dart';
import 'combat_models.dart';
import 'combat_service.dart';
import 'combat_setup_page.dart';

/// === ECRAN DE COMBAT V9.2 CONSOLIDE (TESTS 4, 10, 15, 16, 17, 18, 20, 21, 22, 23, 24, 30) ===
/// - 350 PV / 40 Q / Double Timer 02:00 + 20s par question
/// - Nom propre de l'oeuvre affiche sur chaque question (jamais le slug technique)
/// - Badge de Rang + Niveau credible sur le joueur ET le Bot IA
/// - 4 Malus propres (Texte Inverse, Sans Voyelles max 1/mot avec •, Brouillard d'Encre, Eclipse 5s)
/// - Double securite melange aleatoire des choix A/B/C/D cote app
/// - Animations HAYA!! / COMBO x3 / KECCHAKU! ralenties et visibles + temps de lecture reponse/degats
/// - Avertissement 2e timeout AFK en Solo + Seconde Chance Solo 5s (Video ou 30 OC)
/// - Bilan complet Puits de Confiance + gros bouton REJOUER prioritaire en fin de match
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

// 4 Malus propres (Effet Miroir supprime definitivement — Test 17)
enum _MalusType { aucun, inverse, sansVoyelles, brouillard, eclipse }

class _CombatPageState extends State<CombatPage> with TickerProviderStateMixin {
  final CombatService _combatService = CombatService();
  final EconomyV92Service _economyService = EconomyV92Service();
  final ProgressionService _progressionService = ProgressionService();
  final Random _rng = Random();

  late CombatState _etat;
  late int _nbQuestionsReelles;
  late List<ShuffledChoice> _choixTour;

  // Double Timer officiel V9.2 (§7.2)
  static const int _tempsParQuestion = 20;
  int _tempsRestantQuestion = _tempsParQuestion;
  int _chronoGlobalRestantSec = CombatState.chronoGlobalSec;
  Timer? _timer;
  DateTime _questionStartTime = DateTime.now();

  String? _reponseChoisieOriginale;
  ResultatTour? _dernierResultat;
  String _phase = 'question'; // 'question', 'feedback', 'termine'
  int _bonnesReponses = 0;
  int _questionsRepondues = 0;
  int _hayaCount = 0;
  int _maxCombo = 0;
  int _totalResponseMs = 0;
  bool _estMortSubite = false;
  bool _afkAvertissementActif = false;
  bool _rejouerEnCours = false;

  // 4 Malus propres (Test 17)
  _MalusType _malusActif = _MalusType.aucun;
  bool _brouillardGratte = false;
  bool _eclipseCachee = false;

  // Profil & bilan serveur fin de match
  int _monNiveau = 1;
  String _monPseudo = 'TOI';
  String _monSkinKey = 'skin_kio';
  Map<String, dynamic>? _summaryServeur;
  bool _doubleOcDejaReclame = false;
  bool _doublageEnCours = false;
  bool _secondeChanceActive = false;
  bool _secondeChanceUtilisee = false;

  // Animations visibles et fluides (Tests 4 & 18)
  late AnimationController _shakeJoueur;
  late AnimationController _shakeBot;
  late AnimationController _onomatopeeController;
  late Animation<double> _onomatopeeOpacity;
  late Animation<double> _onomatopeeScale;
  String _onomatopeeTexte = '';
  String _onomatopeeSousTexte = '';
  Color _onomatopeeCouleur = OtakuColors.accent;
  bool _flashActif = false;
  bool _comboSpecialActif = false;
  bool _faceOffVisible = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _screenShakeController;

  @override
  void initState() {
    super.initState();
    FriendsService().setEnCombat(true);
    _nbQuestionsReelles = widget.questions.length;
    _etat = CombatState(nbQuestions: _nbQuestionsReelles);
    _choixTour = widget.questions.first.choixMelanges(_rng);
    _chargerInfosJoueur();

    _shakeJoueur = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _shakeBot = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    // Duree augmentee a 1050 ms pour que HAYA!!, COMBO x3 et KECCHAKU! soient bien visibles (Test 4 & 18)
    _onomatopeeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1050));
    _onomatopeeOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_onomatopeeController);
    _onomatopeeScale = Tween<double>(begin: 0.45, end: 1.12).animate(
      CurvedAnimation(parent: _onomatopeeController, curve: Curves.elasticOut),
    );
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _screenShakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

    // Animation Face-Off rapide au demarrage (Test 18)
    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) {
        setState(() => _faceOffVisible = false);
        _demarrerTour();
      }
    });
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

  /// Tire un des 4 Malus propres selon le contrat choisi (Zen = 0%, Normal = 20%, Malicieux = 55%)
  _MalusType _tirerMalusPourTour() {
    if (widget.params.malusMode == 'zen' || _estMortSubite) return _MalusType.aucun;
    final proba = widget.params.malusMode == 'malicieux' ? 0.55 : 0.20;
    if (_rng.nextDouble() >= proba) return _MalusType.aucun;
    const pool = [
      _MalusType.inverse,
      _MalusType.sansVoyelles,
      _MalusType.brouillard,
      _MalusType.eclipse,
    ];
    return pool[_rng.nextInt(pool.length)];
  }

  /// Nom propre affiche dans le badge Malus (Test 17 : SANS VOYELLES avec espace)
  String _labelMalus(_MalusType m) {
    switch (m) {
      case _MalusType.inverse:
        return 'TEXTE INVERSÉ';
      case _MalusType.sansVoyelles:
        return 'SANS VOYELLES';
      case _MalusType.brouillard:
        return 'BROUILLARD D\'ENCRE';
      case _MalusType.eclipse:
        return 'ÉCLIPSE (5s)';
      case _MalusType.aucun:
        return '';
    }
  }

  void _demarrerTour({bool mortSubite = false}) {
    _estMortSubite = mortSubite;
    _tempsRestantQuestion = mortSubite ? 5 : _tempsParQuestion;
    _reponseChoisieOriginale = null;
    _dernierResultat = null;
    _phase = 'question';
    _malusActif = _tirerMalusPourTour();
    _brouillardGratte = false;
    _eclipseCachee = false;
    _choixTour = widget.questions[_indexQuestion].choixMelanges(_rng);
    _questionStartTime = DateTime.now();

    // Malus Eclipse : 5 secondes de lecture avant masquage (Test 17 : passe de 2,5s a 5s)
    if (_malusActif == _MalusType.eclipse) {
      final tourCapture = _etat.questionActuelle;
      Future.delayed(const Duration(milliseconds: 5000), () {
        if (mounted &&
            _phase == 'question' &&
            _reponseChoisieOriginale == null &&
            _etat.questionActuelle == tourCapture) {
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

  void _onChoixSelectionne(String originalKey) {
    if (_reponseChoisieOriginale != null || _secondeChanceActive || _faceOffVisible) return;
    _timer?.cancel();
    _validerReponse(originalKey);
  }

  void _afficherOnomatopee(String texte, Color couleur, {String sousTexte = ''}) {
    _onomatopeeTexte = texte;
    _onomatopeeSousTexte = sousTexte;
    _onomatopeeCouleur = couleur;
    _onomatopeeController.reset();
    _onomatopeeController.forward();
  }

  Future<void> _validerReponse(String? reponseOriginale) async {
    final question = widget.questions[_indexQuestion];
    final elapsedMs = DateTime.now().difference(_questionStartTime).inMilliseconds;

    setState(() {
      _reponseChoisieOriginale = reponseOriginale ?? '';
    });

    try {
      final resultat = await _combatService.jouerTourV92(
        etat: _etat,
        matchId: widget.params.matchId,
        question: question,
        reponseJoueur: reponseOriginale,
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
      _afkAvertissementActif = resultat.afkWarning;

      // Flash & vibration haptique
      if (resultat.degatsInfliges > 0 || resultat.degatsSubis > 0) {
        HapticFeedback.heavyImpact();
        setState(() => _flashActif = true);
        await Future.delayed(const Duration(milliseconds: 80));
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

      // Onomatopees officielles V9.2 agrandies & lisibles (Tests 4, 16, 18)
      if (resultat.comboJoueurDeclenche || resultat.comboBotDeclenche) {
        setState(() => _comboSpecialActif = true);
        _screenShakeController.reset();
        _screenShakeController.forward();
        if (resultat.comboJoueurDeclenche) {
          _afficherOnomatopee(
            resultat.hayaTriggered ? 'COMBO ×3 + HAYA!!' : 'COMBO ×3!',
            OtakuColors.combo3,
            sousTexte: '-${resultat.degatsInfliges} PV infligés',
          );
        } else {
          _afficherOnomatopee(
            'COMBO ADVERSE!',
            OtakuColors.error,
            sousTexte: '-${resultat.degatsSubis} PV subis',
          );
        }
        await Future.delayed(const Duration(milliseconds: 520));
        if (!mounted) return;
        setState(() => _comboSpecialActif = false);
      } else if (resultat.clashWinner != null) {
        _afficherOnomatopee(
          resultat.clashWinner == 'p1' ? 'CLASH · 1ER!' : 'CLASH!',
          const Color(0xFF4CC9F0),
          sousTexte: '-${resultat.degatsInfliges} PV  /  Riposte -${resultat.degatsSubis} PV',
        );
      } else if (resultat.hayaTriggered) {
        _afficherOnomatopee(
          'HAYA!!',
          const Color(0xFF3FFFB0),
          sousTexte: '-${resultat.degatsInfliges} PV (Réponse < 2s)',
        );
      } else if (resultat.joueurCorrect) {
        _afficherOnomatopee(
          'FRAPPE!',
          OtakuColors.pvHaut,
          sousTexte: '-${resultat.degatsInfliges} PV',
        );
      } else {
        _afficherOnomatopee(
          'AUTO-FAUTE',
          OtakuColors.error,
          sousTexte: '-${resultat.degatsSubis} PV subis',
        );
      }

      setState(() {
        _dernierResultat = resultat;
        _phase = 'feedback';
        if (resultat.summary != null) {
          _summaryServeur = resultat.summary;
        }
      });

      // Temps de lecture confortable de la bonne reponse et des degats (Test 22 : 1,45s)
      await Future.delayed(const Duration(milliseconds: 1450));
      if (!mounted) return;

      // Cas 1 : Seconde Chance Solo (5 secondes a 0 PV, Video ou 30 OC — Test 20)
      final bool eligibleSecondeChance = widget.params.mode == 'solo' &&
          !_secondeChanceUtilisee &&
          (resultat.canSecondChance || (_etat.pvJoueur <= 0 && _etat.pvBot > 0));
      if (eligibleSecondeChance) {
        await _proposerSecondeChance();
        return;
      }

      // Cas 2 : Question Unique de Mort Subite (0 PV simultane)
      if (resultat.suddenDeathTriggered) {
        _afficherOnomatopee('MORT SUBITE!', OtakuColors.pvCritique, sousTexte: '1 PV chacun · 5 secondes');
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
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
          _afficherOnomatopee(
            'K.O. · KECCHAKU!',
            OtakuColors.combo3,
            sousTexte: _etat.pvBot <= 0 ? 'VICTOIRE PAR K.O. !' : 'K.O. SUBI',
          );
        }
        await _finaliserSiNecessaire();
        await Future.delayed(const Duration(milliseconds: 1100));
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
        const SnackBar(content: Text('Connexion instable, passage à la question suivante.')),
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

  /// Popup Seconde Chance Solo avec vrai decompte 5 secondes + Video OU 30 OC (Test 20)
  Future<void> _proposerSecondeChance() async {
    _secondeChanceActive = true;
    _secondeChanceUtilisee = true;

    final String? choix = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SecondChanceCountdownDialog(),
    );

    _secondeChanceActive = false;
    if (!mounted) return;

    if (choix == 'video' || choix == 'oc') {
      try {
        if (widget.params.matchId != null) {
          await _economyService.activerSecondeChance(
            widget.params.matchId!,
            payWithOc: choix == 'oc',
          );
        }
        if (!mounted) return;
        setState(() {
          _etat.pvJoueur = 100;
          _afkAvertissementActif = false;
        });
        _afficherOnomatopee('SECONDE CHANCE!', OtakuColors.pvHaut, sousTexte: '+100 PV restaurés');
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        if (_etat.questionActuelle < _nbQuestionsReelles) {
          _etat.questionActuelle++;
        }
        _demarrerTour();
        setState(() {});
        return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      }
    }

    // Refus ou fin des 5 secondes -> cloture definitive cote serveur
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
    final bool isSolo = widget.params.mode == 'solo';
    final bool? quitter = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OtakuColors.surface,
        title: Text('ABANDONNER LE MATCH ?', style: OtakuTypo.headlineSmall),
        content: Text(
          isSolo
              ? 'Un abandon volontaire retire -50 XP et détruit la mise du match (sans cooldown de 5 min en Solo).'
              : 'Un abandon en Division retire -50 XP, -30 pts Division, détruit les frais OC et applique un cooldown de 5 minutes.',
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

  /// Relance immediatement une nouvelle partie avec les memes reglages (Bouton REJOUER — Test 21)
  Future<void> _rejouerMemeMode() async {
    if (_rejouerEnCours) return;
    setState(() => _rejouerEnCours = true);

    try {
      final p = widget.params;
      final startData = await _economyService.demarrerMatch(
        mode: p.mode,
        difficulty: p.difficulte,
        malusMode: p.malusMode,
        xpInsurance: _monNiveau >= 6 && p.xpInsurance,
        confidencePotOc: p.confidencePotOc,
      );

      final opp = startData['opponent'] is Map ? startData['opponent'] as Map : const {};
      final newParams = CombatParams(
        mode: p.mode,
        anime: p.anime,
        arc: p.arc,
        difficulte: p.difficulte,
        malusMode: p.malusMode,
        xpInsurance: _monNiveau >= 6 && p.xpInsurance,
        confidencePotOc: p.confidencePotOc,
        matchId: startData['match_id']?.toString(),
        opponentPseudo: opp['pseudo']?.toString() ?? 'A.K.I.N.A',
        opponentLevel: (opp['level'] as num?)?.toInt() ?? _monNiveau,
        opponentDivisionId: (opp['division_id'] as num?)?.toInt() ?? p.opponentDivisionId,
      );

      final questions = await _combatService.preparerCombat(newParams);
      if (!mounted) return;
      if (questions.isEmpty) {
        setState(() => _rejouerEnCours = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => p.mode == 'division' ? const VerseDivisionPage() : const CombatSetupPage(),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CombatPage(questions: questions, params: newParams)),
      );
    } on MatchStartException catch (e) {
      if (!mounted) return;
      setState(() => _rejouerEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => widget.params.mode == 'division' ? const VerseDivisionPage() : const CombatSetupPage(),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _rejouerEnCours = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => widget.params.mode == 'division' ? const VerseDivisionPage() : const CombatSetupPage(),
        ),
      );
    }
  }

  /// Formate le texte selon les 4 Malus propres (Test 17 : Sans Voyelles max 1 voyelle par mot avec •)
  String _appliquerTexteMalus(String texte) {
    if (_malusActif == _MalusType.inverse) {
      return String.fromCharCodes(texte.runes.toList().reversed);
    }
    if (_malusActif == _MalusType.sansVoyelles) {
      final vowelRe = RegExp(r'[aeiouyAEIOUYàâäéèêëîïôöùûü]');
      final words = texte.split(' ');
      final masked = words.map((word) {
        if (word.length < 3) return word;
        final matches = vowelRe.allMatches(word).toList();
        if (matches.isEmpty) return word;
        // Choisir une voyelle a l'interieur du mot (max 1 seule par mot) remplacee par •
        final target = matches.length > 1 ? matches[matches.length ~/ 2] : matches.first;
        return word.replaceRange(target.start, target.end, '•');
      });
      return masked.join(' ');
    }
    return texte;
  }

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
    final nomOeuvre = EconomyV92Service.nomPropreOeuvre(question.workSlug ?? question.anime);

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _screenShakeController,
          builder: (context, child) {
            final shake = _screenShakeController.isAnimating
                ? sin(_screenShakeController.value * pi * 6) * 5
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
                        OtakuColors.combo3.withValues(alpha: 0.2),
                        OtakuColors.error.withValues(alpha: 0.12),
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
                    // === BARRES DE PV 350 + CHRONO GLOBAL 02:00 + BADGE RANG JOUEUR & BOT ===
                    _buildBarresPV(),
                    const SizedBox(height: 6),

                    // Avertissement AFK Solo au 2e timeout consecutif (Test 23)
                    if (_afkAvertissementActif)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Text(
                          'Attention : encore 1 question sans réponse = forfait AFK !',
                          textAlign: TextAlign.center,
                          style: OtakuTypo.headlineSmall.copyWith(fontSize: 11, color: Colors.amber),
                        ),
                      ),

                    // === ZONE QUESTION + CHOIX ===
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
                                const SizedBox(width: 10),
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
                                      'MALUS : ${_labelMalus(_malusActif)}',
                                      style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.modeDuel),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: _confirmerQuitter,
                                  child: const Icon(Icons.flag_outlined, size: 18, color: OtakuColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Carte question avec NOM PROPRE DE L'OEUVRE en haut (Test 15) + 4 Malus
                            _buildQuestionCard(texteAffiche, nomOeuvre, question.arc),
                            const SizedBox(height: 8),

                            // Grille des choix melanges (Double securite V4.0)
                            _buildChoix(),

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

              // Banniere Face-Off de lancement (Test 18)
              if (_faceOffVisible)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.78),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.params.mode == 'division' ? 'DUEL CLASSÉ · DIVISION' : 'COMBAT SOLO · 350 PV',
                            style: OtakuTypo.label.copyWith(fontSize: 12, color: OtakuColors.accent, letterSpacing: 2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_monPseudo  VS  ${widget.params.opponentPseudo}',
                            style: OtakuTypo.impact.copyWith(fontSize: 32, color: const Color(0xFFFFD700)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'PRÉPARE-TOI !',
                            style: OtakuTypo.headlineSmall.copyWith(fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

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

  Widget _buildQuestionCard(String texteAffiche, String nomOeuvre, String? arc) {
    final Widget headerOeuvre = Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: OtakuColors.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.55)),
            ),
            child: Text(
              arc != null && arc.isNotEmpty && arc.toLowerCase() != 'global' && arc.toLowerCase() != 'général'
                  ? '$nomOeuvre · $arc'
                  : nomOeuvre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.accent, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (_malusActif == _MalusType.brouillard && !_brouillardGratte) {
      return GestureDetector(
        onTap: () => setState(() => _brouillardGratte = true),
        onPanUpdate: (_) => setState(() => _brouillardGratte = true),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: OtakuColors.modeDuel),
          ),
          child: Column(
            children: [
              headerOeuvre,
              Text(
                'BROUILLARD D\'ENCRE : Appuie ou gratte pour lire la question !',
                textAlign: TextAlign.center,
                style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: OtakuColors.modeDuel),
              ),
            ],
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
      child: Column(
        children: [
          headerOeuvre,
          Text(
            _eclipseCachee ? 'ÉCLIPSE ACTIVE ! Réponds de mémoire !' : texteAffiche,
            style: OtakuTypo.bodyLarge.copyWith(
              fontSize: _taillePoliceQuestion(texteAffiche),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _onomatopeeCouleur, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _onomatopeeTexte,
                        textAlign: TextAlign.center,
                        style: OtakuTypo.impact.copyWith(
                          fontSize: 44,
                          color: _onomatopeeCouleur,
                          letterSpacing: 2.5,
                          shadows: [
                            Shadow(color: _onomatopeeCouleur.withValues(alpha: 0.8), blurRadius: 24),
                          ],
                        ),
                      ),
                      if (_onomatopeeSousTexte.isNotEmpty)
                        Text(
                          _onomatopeeSousTexte,
                          textAlign: TextAlign.center,
                          style: OtakuTypo.hud.copyWith(fontSize: 13, color: Colors.white),
                        ),
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
    // Niveau credible du Bot IA (Test 10) : toujours renseigne pour afficher son OfficialRankBadge
    final int botLevel = widget.params.opponentLevel ?? _monNiveau;

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
              divisionId: widget.params.mode == 'division' ? widget.params.opponentDivisionId : null,
              pv: _etat.pvJoueur,
              combo: _etat.comboJoueur,
              alignDroite: false,
            ),
          ),
        ),
        const SizedBox(width: 12),
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
              niveau: botLevel,
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
    required int niveau,
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
        const SizedBox(height: 2),
        OfficialRankBadge(niveau: niveau, divisionId: divisionId, compact: true),
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

  Widget _buildChoix() {
    final aRepondu = _reponseChoisieOriginale != null;
    final bonneReponseServeur = _dernierResultat?.bonneReponse ?? '';

    if (_choixTour.length <= 2) {
      return Row(
        children: [
          Expanded(child: _buildBoutonChoix(_choixTour[0], bonneReponseServeur, aRepondu)),
          const SizedBox(width: 8),
          if (_choixTour.length > 1)
            Expanded(child: _buildBoutonChoix(_choixTour[1], bonneReponseServeur, aRepondu)),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildBoutonChoix(_choixTour[0], bonneReponseServeur, aRepondu)),
            const SizedBox(width: 8),
            Expanded(child: _buildBoutonChoix(_choixTour[1], bonneReponseServeur, aRepondu)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildBoutonChoix(_choixTour[2], bonneReponseServeur, aRepondu)),
            const SizedBox(width: 8),
            if (_choixTour.length > 3)
              Expanded(child: _buildBoutonChoix(_choixTour[3], bonneReponseServeur, aRepondu))
            else
              const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildBoutonChoix(ShuffledChoice choix, String bonneReponseOriginale, bool aRepondu) {
    Color couleurBordure = OtakuColors.border;
    Color couleurFond = OtakuColors.surface;

    if (aRepondu && _dernierResultat != null) {
      if (bonneReponseOriginale.isNotEmpty && choix.originalKey == bonneReponseOriginale) {
        couleurBordure = OtakuColors.success;
        couleurFond = OtakuColors.success.withValues(alpha: 0.18);
      } else if (choix.originalKey == _reponseChoisieOriginale) {
        couleurBordure = _dernierResultat!.joueurCorrect ? OtakuColors.success : OtakuColors.error;
        couleurFond = couleurBordure.withValues(alpha: 0.16);
      }
    }

    return GestureDetector(
      onTap: aRepondu ? null : () => _onChoixSelectionne(choix.originalKey),
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
                choix.displayLetter,
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
                choix.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _taillePoliceChoix(choix.text),
                  color: couleurBordure == OtakuColors.border ? OtakuColors.textPrimary : couleurBordure,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Feedback detaille des PV infliges et subis a chaque question (Test 16 & 22)
  Widget _buildFeedback() {
    final r = _dernierResultat!;
    final String tagJoueur = r.comboJoueurDeclenche && r.hayaTriggered
        ? 'COMBO ×3 + HAYA!!'
        : r.comboJoueurDeclenche
            ? 'COMBO ×3'
            : r.hayaTriggered
                ? 'HAYA!!'
                : (r.clashWinner != null ? 'CLASH' : 'NORMAL');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: OtakuColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: r.joueurCorrect ? OtakuColors.success.withValues(alpha: 0.5) : OtakuColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: Text(
              r.joueurCorrect
                  ? 'Toi ($tagJoueur) : -${r.degatsInfliges} PV infligés${r.degatsSubis > 0 ? " · Riposte -${r.degatsSubis} PV" : ""}'
                  : 'Raté : -${r.degatsSubis} PV subis (dont -5 Auto-faute)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: OtakuTypo.bodySmall.copyWith(
                fontSize: 11,
                color: r.joueurCorrect ? OtakuColors.success : OtakuColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              r.botCorrect
                  ? '${widget.params.opponentPseudo} : bonne réponse (-${r.degatsSubis} PV)'
                  : '${widget.params.opponentPseudo} : raté (-5 PV Auto-faute)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: OtakuTypo.bodySmall.copyWith(
                fontSize: 11,
                color: r.botCorrect ? OtakuColors.error : OtakuColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bouton discret "Signaler une erreur" (Phase B4)
          GestureDetector(
            onTap: _ouvrirSignalementQuestion,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: OtakuColors.background,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: OtakuColors.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.report_problem_outlined, size: 12, color: OtakuColors.textMuted),
                  SizedBox(width: 3),
                  Text('Signaler', style: TextStyle(fontSize: 9, color: OtakuColors.textMuted, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Modal de signalement d'erreur sur une question (table Supabase `question_reports` — Phase B4)
  Future<void> _ouvrirSignalementQuestion() async {
    if (widget.questions.isEmpty) return;
    final q = widget.questions[_indexQuestion];
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    String selectedReason = 'mauvaise_reponse';
    final commentCtrl = TextEditingController();
    const reasons = [
      {'code': 'mauvaise_reponse', 'label': 'Bonne réponse incorrecte'},
      {'code': 'faute_orthographe', 'label': 'Faute d\'orthographe ou texte cassé'},
      {'code': 'hors_sujet', 'label': 'Mauvaise œuvre / Hors-sujet'},
      {'code': 'spoiler_incorrect', 'label': 'Spoiler mal classé'},
      {'code': 'autre', 'label': 'Autre problème'},
    ];

    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: OtakuColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('SIGNALER CETTE QUESTION', style: OtakuTypo.headlineSmall.copyWith(fontSize: 14, color: OtakuColors.modeEvent)),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: OtakuTypo.bodySmall.copyWith(fontSize: 10.5, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: reasons.map((r) {
                      final active = selectedReason == r['code'];
                      return GestureDetector(
                        onTap: () => setDlgState(() => selectedReason = r['code']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: active ? OtakuColors.modeEvent.withValues(alpha: 0.22) : OtakuColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: active ? OtakuColors.modeEvent : OtakuColors.border),
                          ),
                          child: Text(
                            r['label']!,
                            style: TextStyle(fontSize: 10, color: active ? OtakuColors.modeEvent : Colors.white70),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Détail optionnel (ex: la vraie réponse est...)',
                      hintStyle: const TextStyle(color: OtakuColors.textMuted, fontSize: 10),
                      filled: true,
                      fillColor: OtakuColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('ANNULER', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.modeEvent, foregroundColor: Colors.black),
              onPressed: () async {
                try {
                  await Supabase.instance.client.from('question_reports').insert({
                    'user_id': uid,
                    'question_id': q.id,
                    'work_slug': q.anime,
                    'question_text': q.question,
                    'reason': selectedReason,
                    'comment': commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
                  });
                  AnalyticsService.instance.logQuestionReport(selectedReason);
                } catch (_) {}
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('ENVOYER', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );

    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci ! Ton signalement a été transmis à l\'équipe.'),
          backgroundColor: OtakuColors.pvHaut,
        ),
      );
    }
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
    final int ocPotReturn = (s?['oc_pot_return'] as num?)?.toInt() ?? 0;
    final int ocPotStake = (s?['oc_pot_stake'] as num?)?.toInt() ?? widget.params.confidencePotOc;
    final String potReason = s?['pot_reason']?.toString() ?? '';
    final int totalOcMatch = ocPerf + ocRefund + ocPotReturn;
    final int deltaDiv = (s?['delta_division_pts'] as num?)?.toInt() ?? 0;
    final bool canDoubleOc = s?['can_double_oc'] == true && !_doubleOcDejaReclame && widget.params.matchId != null;

    final couleurTitre = victoire ? OtakuColors.victoire : (egalite ? OtakuColors.pvMoyen : OtakuColors.defaite);

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  victoire
                      ? (ko ? 'VICTOIRE PAR K.O. · KECCHAKU!' : 'VICTOIRE AUX POINTS!')
                      : (egalite ? 'MATCH NUL' : (ko ? 'DÉFAITE PAR K.O.' : 'DÉFAITE')),
                  textAlign: TextAlign.center,
                  style: OtakuTypo.impact.copyWith(fontSize: 36, color: couleurTitre),
                ),
                const SizedBox(height: 6),
                OfficialRankBadge(
                  niveau: newLevel,
                  divisionId: (s?['new_division_id'] as num?)?.toInt(),
                  prominent: true,
                ),
                const SizedBox(height: 10),

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
                const SizedBox(height: 12),

                // Bilan serveur XP / OC (incluant Puits de Confiance x2!) / Division
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildRewardChip(
                      '${deltaXp >= 0 ? "+" : ""}$deltaXp XP',
                      deltaXp >= 0 ? OtakuColors.accent : OtakuColors.error,
                    ),
                    if (totalOcMatch > 0)
                      _buildRewardChip(
                        '+$totalOcMatch OC${_doubleOcDejaReclame ? " (+$ocPerf pub)" : ""}',
                        const Color(0xFF4CC9F0),
                      ),
                    if (ocPotReturn > 0)
                      _buildRewardChip(
                        'Puits : +$ocPotReturn OC',
                        const Color(0xFFFFD700),
                      ),
                    if (widget.params.mode == 'division')
                      _buildRewardChip(
                        '${deltaDiv >= 0 ? "+" : ""}$deltaDiv PTS DIV',
                        deltaDiv >= 0 ? OtakuColors.victoire : OtakuColors.error,
                      ),
                  ],
                ),

                // Detail clair du Puits de Confiance si une mise a ete posee (Tests 21 & 30)
                if (ocPotStake > 0 && potReason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    potReason,
                    textAlign: TextAlign.center,
                    style: OtakuTypo.bodySmall.copyWith(
                      fontSize: 11,
                      color: ocPotReturn > 0 ? const Color(0xFFFFD700) : OtakuColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Bouton Roi : Doubler mes OC (x2) via pub volontaire (ECO-06)
                if (canDoubleOc) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CC9F0),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _doublageEnCours ? null : _activerDoubleOc,
                    icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                    label: Text('DOUBLER MES OC (×2 : +$ocPerf OC · PUB)', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 12),
                ],

                // GROS BOUTON REJOUER PRIORITAIRE (Test 21) + Partager + Accueil
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OtakuColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                      ),
                      onPressed: _rejouerEnCours ? null : _rejouerMemeMode,
                      icon: _rejouerEnCours
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.replay_rounded, size: 20),
                      label: const Text('REJOUER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                    ),
                    OutlinedButton.icon(
                      onPressed: _partagerResultat,
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: Text(
                        victoire ? 'PARTAGER MA VICTOIRE (9:16)' : 'PARTAGER',
                        style: OtakuTypo.label.copyWith(color: OtakuColors.accent),
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OtakuColors.textSecondary,
                        side: const BorderSide(color: OtakuColors.border),
                      ),
                      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                      child: Text('ACCUEIL', style: OtakuTypo.label.copyWith(color: OtakuColors.textSecondary)),
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
        SnackBar(content: Text('+$bonus Otaku Coins bonus crédités !')),
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
    final String workClean = widget.params.anime == null
        ? 'Mix 21 Œuvres'
        : EconomyV92Service.nomPropreOeuvre(widget.params.anime);
    final String workLabel = widget.params.arc != null ? '$workClean (${widget.params.arc})' : workClean;
    final int oppLvl = widget.params.opponentLevel ?? newLevel;

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
          opponentDivisionId: widget.params.opponentDivisionId ?? divId ?? 10,
          opponentRankTitle: EconomyV92Service.titreRangOfficiel(oppLvl),
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

/// Dialog Seconde Chance Solo avec decompte actif de 5 secondes + Video ou 30 OC (Test 20)
class _SecondChanceCountdownDialog extends StatefulWidget {
  @override
  State<_SecondChanceCountdownDialog> createState() => _SecondChanceCountdownDialogState();
}

class _SecondChanceCountdownDialogState extends State<_SecondChanceCountdownDialog> {
  int _secondesRestantes = 5;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondesRestantes <= 1) {
        t.cancel();
        Navigator.of(context).pop('abandon');
      } else {
        setState(() => _secondesRestantes--);
      }
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: OtakuColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: OtakuColors.combo3, width: 1.8),
      ),
      title: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: OtakuColors.combo3),
          const SizedBox(width: 8),
          Expanded(
            child: Text('SECONDE CHANCE ! ($_secondesRestantes s)', style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.combo3)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _secondesRestantes / 5.0,
            minHeight: 6,
            backgroundColor: OtakuColors.border,
            valueColor: const AlwaysStoppedAnimation(OtakuColors.combo3),
          ),
          const SizedBox(height: 10),
          Text(
            'Tu es tombé à 0 PV ! Repars immédiatement avec +100 PV sur 350 PV grâce à une vidéo ou 30 OC (1 fois par match).',
            style: OtakuTypo.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'abandon'),
          child: Text('ABANDONNER', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4CC9F0),
            side: const BorderSide(color: Color(0xFF4CC9F0)),
          ),
          onPressed: () => Navigator.pop(context, 'oc'),
          icon: const Icon(Icons.toll_rounded, size: 16),
          label: const Text('+100 PV (30 OC)'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.combo3, foregroundColor: Colors.black),
          onPressed: () => Navigator.pop(context, 'video'),
          icon: const Icon(Icons.play_circle_filled_rounded, size: 16),
          label: const Text('+100 PV (VIDÉO)'),
        ),
      ],
    );
  }
}
