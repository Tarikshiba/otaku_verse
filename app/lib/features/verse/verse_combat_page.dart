import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../quiz/quiz_service.dart';
import 'matchmaking_service.dart';

class VerseCombatPage extends StatefulWidget {
  final String matchId;
  const VerseCombatPage({super.key, required this.matchId});

  @override
  State<VerseCombatPage> createState() => _VerseCombatPageState();
}

class _VerseCombatPageState extends State<VerseCombatPage> {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app, 
      databaseURL: 'https://otaku-verse-6e05e-default-rtdb.europe-west1.firebasedatabase.app'
  );
  
  Map<dynamic, dynamic>? _matchData;
  late StreamSubscription _matchSub;
  String _currentUserId = Supabase.instance.client.auth.currentUser!.id;

  String? _selectedAnswer;
  bool _hasAnswered = false;
  bool? _lastAnswerCorrect;
  int _bonnesReponses = 0;
  bool _matchCloture = false;
  int? _xpGagne;
  int? _deltaPoints;
  String? _labelDivisionFinale;
  int _timeLeft = 15;
  Timer? _timer;
  int _transitioningIndex = -1; // Evite de lancer plusieurs transitions pour la meme question
  final QuizService _quizService = QuizService();
  final MatchmakingService _matchmakingService = MatchmakingService();

  @override
  void initState() {
    super.initState();
    _matchSub = _db.ref('matches/${widget.matchId}').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final bool isFirstLoad = _matchData == null;
        final bool questionChanged = _matchData != null &&
            _matchData!['currentQuestionIndex'] != data['currentQuestionIndex'];

        setState(() {
          _matchData = data;
          if (questionChanged) {
            _resetTurn();
          }
        });

        if (isFirstLoad) {
          _startTimer();
        }

        // Verifier si les deux joueurs ont repondu a la question actuelle
        final int currentIdx = data['currentQuestionIndex'] ?? 0;
        final Map p1 = data['player1'] ?? {};
        final Map p2 = data['player2'] ?? {};
        final bool p1Answered = p1['answeredIndex'] == currentIdx;
        final bool p2Answered = (p2['isBot'] == true) || (p2['answeredIndex'] == currentIdx);

        if (data['status'] != 'finished' && p1Answered && p2Answered) {
          _timer?.cancel();
          _passerQuestionSuivante(currentIdx);
        }
      }
    });
  }

  void _resetTurn() {
    _selectedAnswer = null;
    _hasAnswered = false;
    _lastAnswerCorrect = null;
    _timeLeft = 15;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          // Fin du chronometre : on valide une reponse vide si le joueur n'a pas joue et on avance
          timer.cancel();
          if (!_hasAnswered) {
            _validerReponse('');
          }
          _passerQuestionSuivante(_matchData?['currentQuestionIndex'] ?? 0);
        }
      });
    });
  }

  // Passe a la question suivante une seule fois par tour apres 2 secondes d'affichage du resultat
  void _passerQuestionSuivante(int questionIndex) {
    if (_transitioningIndex == questionIndex) return;
    _transitioningIndex = questionIndex;

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted || _matchData == null) return;
      final currentStatus = _matchData!['status'];
      final currentIdx = _matchData!['currentQuestionIndex'] ?? 0;
      final questions = _matchData!['questions'] as List<dynamic>? ?? [];

      if (currentStatus != 'finished' && currentIdx == questionIndex) {
        if (questionIndex + 1 >= questions.length) {
          await _db.ref('matches/${widget.matchId}').update({
            'status': 'finished',
          });
        } else {
          await _db.ref('matches/${widget.matchId}').update({
            'currentQuestionIndex': questionIndex + 1,
          });
        }
      }
    });
  }

  void _validerReponse(String reponse) async {
    if (_hasAnswered) return;
    setState(() {
      _selectedAnswer = reponse;
      _hasAnswered = true;
    });

    final currentQuestionIndex = _matchData!['currentQuestionIndex'] ?? 0;
    final questions = _matchData!['questions'] as List<dynamic>;
    
    if (currentQuestionIndex >= questions.length) return;

    final question = questions[currentQuestionIndex];

    // Identifier qui je suis (player1 ou player2)
    final isPlayer1 = _matchData!['player1']['id'] == _currentUserId;
    final myPlayerKey = isPlayer1 ? 'player1' : 'player2';
    final opponentKey = isPlayer1 ? 'player2' : 'player1';

    bool isCorrect = false;
    int degatsInfliges = 0;
    int degatsSubis = 0;
    int nouveauComboJoueur = 0;
    int nouveauComboBot = _matchData![opponentKey]['combo'] ?? 0;

    // Validation cote serveur via l'Edge Function Supabase (sans bonneReponse en clair)
    if (reponse.isNotEmpty) {
      try {
        final validation = await _quizService.validerReponse(
          questionId: question['id'],
          reponse: reponse,
          comboJoueur: _matchData![myPlayerKey]['combo'] ?? 0,
          comboBot: _matchData![opponentKey]['combo'] ?? 0,
          difficulte: 'moyen',
        );
        isCorrect = validation.joueurCorrect;
        degatsInfliges = validation.degatsInfliges;
        degatsSubis = validation.degatsSubis;
        nouveauComboJoueur = validation.nouveauComboJoueur;
        nouveauComboBot = validation.nouveauComboBot;
      } catch (_) {
        isCorrect = false;
      }
    }

    if (mounted) {
      setState(() {
        _lastAnswerCorrect = isCorrect;
        if (isCorrect) _bonnesReponses++;
      });
    }

    // Enregistrer dans Firebase que ce joueur a repondu et mettre a jour son combo
    await _db.ref('matches/${widget.matchId}/$myPlayerKey').update({
      'answeredIndex': currentQuestionIndex,
      'combo': nouveauComboJoueur,
    });

    // Infliger les degats calcules par le serveur si la reponse est bonne
    if (degatsInfliges > 0) {
      final int currentOpponentPv = _matchData![opponentKey]['pv'] ?? 100;
      final int newPv = (currentOpponentPv - degatsInfliges).clamp(0, 100);
      
      await _db.ref('matches/${widget.matchId}/$opponentKey').update({
        'pv': newPv,
      });

      if (newPv == 0) {
        await _db.ref('matches/${widget.matchId}').update({'status': 'finished', 'winner': _currentUserId});
        return;
      }
    }

    // Si l'adversaire est un bot, appliquer aussi sa contre-attaque calculee par le serveur
    if (_matchData![opponentKey]['isBot'] == true) {
      final int currentMyPv = _matchData![myPlayerKey]['pv'] ?? 100;
      final int newMyPv = (currentMyPv - degatsSubis).clamp(0, 100);

      await _db.ref('matches/${widget.matchId}/$opponentKey').update({
        'combo': nouveauComboBot,
      });

      if (degatsSubis > 0) {
        await _db.ref('matches/${widget.matchId}/$myPlayerKey').update({
          'pv': newMyPv,
        });

        if (newMyPv == 0) {
          await _db.ref('matches/${widget.matchId}').update({
            'status': 'finished',
            'winner': _matchData![opponentKey]['id'],
          });
        }
      }
    }
  }

  Future<void> _cloturerMatchServeur({
    required String resultat,
    required bool ko,
  }) async {
    if (_matchCloture) return;
    _matchCloture = true;

    final String mode = _matchData?['mode'] ?? 'amical';
    int xpCalcule = 20 + (_bonnesReponses * 10) + (resultat == 'victoire' && ko ? 30 : 0);
    int deltaCalcule = 0;
    if (mode == 'division') {
      if (resultat == 'victoire') deltaCalcule = 25;
      else if (resultat == 'defaite') deltaCalcule = -15;
      else if (resultat == 'egalite') deltaCalcule = 5;
      else if (resultat == 'abandon') deltaCalcule = -30;
    }

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'valider-reponse',
        body: {
          'action': 'cloturer_match_verse',
          'user_id': _currentUserId,
          'resultat': resultat,
          'mode': mode,
          'ko': ko,
          'bonnes_reponses': _bonnesReponses,
        },
      );
      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        xpCalcule = (data['xp_gagne'] as int?) ?? xpCalcule;
        deltaCalcule = (data['delta_points'] as int?) ?? deltaCalcule;
      }
    } catch (_) {}

    String? labelDiv;
    if (mode == 'division') {
      try {
        final statsDiv = await _matchmakingService.mettreAJourDivisionApresMatch(
          deltaPoints: deltaCalcule,
          xpGagne: xpCalcule,
          resultat: resultat,
        );
        labelDiv = "DIVISION ${statsDiv['division']} : ${(statsDiv['nomDivision'] as String).toUpperCase()} (${statsDiv['points']} PTS)";
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _xpGagne = xpCalcule;
        _deltaPoints = deltaCalcule;
        _labelDivisionFinale = labelDiv;
      });
    }
  }

  @override
  void dispose() {
    _matchSub.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_matchData == null) {
      return const Scaffold(
        backgroundColor: OtakuColors.background,
        body: Center(child: CircularProgressIndicator(color: OtakuColors.accent)),
      );
    }

    final status = _matchData!['status'];
    if (status == 'finished') {
      return _buildFinishedScreen();
    }

    final player1 = _matchData!['player1'] ?? {};
    final player2 = _matchData!['player2'] ?? {};
    final isPlayer1 = player1['id'] == _currentUserId;

    final int index = _matchData!['currentQuestionIndex'] ?? 0;
    final List<dynamic> questions = _matchData!['questions'] ?? [];
    
    if (index >= questions.length) {
      // S'il n'y a plus de questions
      return _buildFinishedScreen();
    }

    final question = questions[index];

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // BARRES DE VIE (TEMPS RÉEL)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPlayerAvatar(player1['pseudo'] ?? 'Joueur 1', player1['pv'] ?? 100, isMe: isPlayer1, isBot: player1['isBot'] == true),
                      const Text('VS', style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                      _buildPlayerAvatar(player2['pseudo'] ?? 'Adversaire', player2['pv'] ?? 100, isMe: !isPlayer1, isBot: player2['isBot'] == true),
                    ],
                  ),
                ),
                
                // MINUTEUR
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: _timeLeft / 15,
                        backgroundColor: Colors.grey[800],
                        color: _timeLeft <= 5 ? Colors.redAccent : OtakuColors.accent,
                      ),
                    ),
                    Text('$_timeLeft', style: OtakuTypo.headlineSmall.copyWith(fontSize: 16)),
                  ],
                ),
                
                // QUESTION
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: OtakuColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OtakuColors.accent.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (question['imageUrl'] != null &&
                            (question['imageUrl'] as String).isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              question['imageUrl'] as String,
                              height: 110,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          question['question'] ?? '',
                          style: OtakuTypo.headlineSmall.copyWith(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // RÉPONSES
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildAnswerButton('A', question['choixA'] ?? '')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildAnswerButton('B', question['choixB'] ?? '')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildAnswerButton('C', question['choixC'] ?? '')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildAnswerButton('D', question['choixD'] ?? '')),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // BOUTON QUITTER (avec système Anti-abandon Roadmap 9.6)
                TextButton(
                  onPressed: _confirmerAbandon,
                  child: const Text('QUITTER LE MATCH', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Affiche une confirmation d'abandon et applique la pénalité (-30 pts + cooldown + victoire adverse)
  Future<void> _confirmerAbandon() async {
    final String mode = _matchData?['mode'] ?? 'amical';
    final bool? quitter = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OtakuColors.surface,
        title: Text('ABANDONNER LE MATCH ?', style: OtakuTypo.headlineSmall),
        content: Text(
          mode == 'division'
              ? 'Attention : abandonner un match classé entraîne une pénalité de -30 PTS de division, une victoire immédiate pour ton adversaire et un blocage temporaire (5 min, ou 30 min après 3 abandons).'
              : 'Ton adversaire remportera immédiatement la victoire.',
          style: OtakuTypo.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CONTINUER LE COMBAT', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ABANDONNER', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (quitter != true || !mounted) return;
    _timer?.cancel();

    final player1 = _matchData?['player1'] ?? {};
    final player2 = _matchData?['player2'] ?? {};
    final bool isPlayer1 = player1['id'] == _currentUserId;
    final String opponentId = (isPlayer1 ? player2['id'] : player1['id']) ?? 'opponent';

    await _db.ref('matches/${widget.matchId}').update({
      'status': 'finished',
      'abandonedBy': _currentUserId,
      'winner': opponentId,
    });

    await _cloturerMatchServeur(resultat: 'abandon', ko: false);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildAnswerButton(String prefix, String texte) {
    final bool isSelected = _selectedAnswer == prefix;
    final bool showResult = _hasAnswered;

    Color bgColor = OtakuColors.surface;
    Color borderColor = Colors.transparent;

    if (showResult && isSelected && _lastAnswerCorrect != null) {
      if (_lastAnswerCorrect!) {
        bgColor = Colors.green.withOpacity(0.3);
        borderColor = Colors.green;
      } else {
        bgColor = Colors.red.withOpacity(0.3);
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      bgColor = OtakuColors.accent.withOpacity(0.3);
      borderColor = OtakuColors.accent;
    }

    return GestureDetector(
      onTap: () {
        if (!_hasAnswered && _timeLeft > 0) {
          _validerReponse(prefix);
        }
      },
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Center(
          child: Text(
            texte,
            style: OtakuTypo.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedScreen() {
    final player1 = _matchData!['player1'];
    final player2 = _matchData!['player2'];
    final winnerId = _matchData!['winner'];
    final abandonedBy = _matchData!['abandonedBy'];
    
    final bool iWon = winnerId == _currentUserId;
    // Si pas de winner (ex: fin des questions), on compare les PV
    final bool draw = winnerId == null && player1['pv'] == player2['pv'];
    final bool iWonByPv = winnerId == null && 
        (player1['id'] == _currentUserId ? player1['pv'] > player2['pv'] : player2['pv'] > player1['pv']);

    final bool victory = iWon || (!draw && iWonByPv);
    final String resultatServeur = abandonedBy == _currentUserId
        ? 'abandon'
        : (draw ? 'egalite' : (victory ? 'victoire' : 'defaite'));
    _cloturerMatchServeur(resultat: resultatServeur, ko: winnerId != null && abandonedBy == null);

    final String titre = draw ? "ÉGALITÉ" : (victory ? "VICTOIRE !" : "DÉFAITE...");
    final Color color = draw ? Colors.grey : (victory ? Colors.green : Colors.red);

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(titre, style: OtakuTypo.headlineLarge.copyWith(color: color, fontSize: 40)),
            if (_xpGagne != null) ...[
              const SizedBox(height: 16),
              Text('+$_xpGagne XP', style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.accent)),
            ],
            if (_deltaPoints != null && _deltaPoints != 0) ...[
              const SizedBox(height: 8),
              Text(
                '${_deltaPoints! > 0 ? '+' : ''}$_deltaPoints PTS DIVISION',
                style: OtakuTypo.bodySmall.copyWith(
                  color: _deltaPoints! > 0 ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ],
            if (_labelDivisionFinale != null) ...[
              const SizedBox(height: 8),
              Text(
                _labelDivisionFinale!,
                style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.modeDivision),
              ),
            ],
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.accent),
              onPressed: () => Navigator.pop(context),
              child: const Text('RETOUR AU MENU'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar(String pseudo, int pv, {required bool isMe, bool isBot = false}) {
    final String portraitPath = isBot
        ? 'assets/images/skins/bot_akina.png'
        : (isMe ? 'assets/images/skins/skin_default.png' : 'assets/images/skins/skin_ninja.png');
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isMe ? OtakuColors.modeSolo : Colors.redAccent,
              width: 2.5,
            ),
          ),
          child: Image.asset(
            portraitPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 6),
        Text(pseudo, style: OtakuTypo.headlineSmall.copyWith(fontSize: 14)),
        const SizedBox(height: 4),
        Container(
          width: 100,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
            widthFactor: (pv / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: isMe ? OtakuColors.modeSolo : Colors.redAccent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('$pv PV', style: OtakuTypo.label.copyWith(color: isMe ? OtakuColors.modeSolo : Colors.redAccent)),
      ],
    );
  }
}
