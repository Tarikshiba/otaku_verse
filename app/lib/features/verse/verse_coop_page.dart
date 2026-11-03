import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../quiz/quiz_service.dart';
import 'matchmaking_service.dart';

/// Page de configuration et de lancement du Mode Coopératif (2 joueurs alliés contre le Boss Quiz)
class VerseCoopPage extends StatefulWidget {
  const VerseCoopPage({super.key});

  @override
  State<VerseCoopPage> createState() => _VerseCoopPageState();
}

class _VerseCoopPageState extends State<VerseCoopPage> {
  final MatchmakingService _matchmaking = MatchmakingService();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _creerSalon({required bool avecBot}) async {
    setState(() => _isLoading = true);
    try {
      final res = await _matchmaking.creerSalonCoop(avecBot: avecBot);
      final String roomId = res['roomId'];
      final String code = res['code'];
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (avecBot) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => VerseCoopArenaPage(roomId: roomId)),
        );
      } else {
        _afficherAttenteAllie(roomId, code);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejoindreSalon() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entre un code à 6 chiffres."), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final roomId = await _matchmaking.rejoindreSalonCoop(code);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (roomId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => VerseCoopArenaPage(roomId: roomId)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _afficherAttenteAllie(String roomId, String code) {
    final db = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL: 'https://otaku-verse-6e05e-default-rtdb.europe-west1.firebasedatabase.app',
    );
    StreamSubscription? sub;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        sub = db.ref('coop/$roomId/status').onValue.listen((event) {
          if (event.snapshot.value == 'starting' && mounted) {
            sub?.cancel();
            Navigator.of(ctx).pop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => VerseCoopArenaPage(roomId: roomId)),
            );
          }
        });
        return AlertDialog(
          backgroundColor: OtakuColors.surface,
          title: Text("SALON COOP CRÉÉ", style: OtakuTypo.headlineSmall, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Partage ce code avec ton coéquipier :", style: OtakuTypo.bodySmall),
              const SizedBox(height: 16),
              Text(code, style: OtakuTypo.headlineLarge.copyWith(color: OtakuColors.modeCoop, letterSpacing: 6)),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: OtakuColors.modeCoop),
              const SizedBox(height: 12),
              Text("En attente de ton allié...", style: OtakuTypo.bodySmall),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                sub?.cancel();
                Navigator.of(ctx).pop();
              },
              child: const Text("ANNULER", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("MODE COOPÉRATIF", style: OtakuTypo.headlineSmall),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_work_rounded, size: 64, color: OtakuColors.modeCoop),
                const SizedBox(height: 12),
                Text("FAITES ÉQUIPE CONTRE LE BOSS", style: OtakuTypo.headlineLarge, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  "Unissez vos réponses pour tomber les 200 PV du Gardien du Verse.",
                  style: OtakuTypo.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const CircularProgressIndicator(color: OtakuColors.modeCoop)
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.modeCoop),
                        onPressed: () => _creerSalon(avecBot: false),
                        icon: const Icon(Icons.people_rounded),
                        label: const Text("CRÉER SALON 2 JOUEURS"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.surface),
                        onPressed: () => _creerSalon(avecBot: true),
                        icon: const Icon(Icons.smart_toy_rounded, color: OtakuColors.modeCoop),
                        label: const Text("JOUER AVEC A.K.I.N.A"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: OtakuTypo.headlineSmall,
                      decoration: InputDecoration(
                        hintText: "CODE ALLIÉ (6 CHIFFRES)",
                        counterText: "",
                        filled: true,
                        fillColor: OtakuColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                    onPressed: _rejoindreSalon,
                    child: const Text("REJOINDRE MON ALLIÉ"),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Arène de combat Coopératif synchronisée via Firebase Realtime Database
class VerseCoopArenaPage extends StatefulWidget {
  final String roomId;
  const VerseCoopArenaPage({super.key, required this.roomId});

  @override
  State<VerseCoopArenaPage> createState() => _VerseCoopArenaPageState();
}

class _VerseCoopArenaPageState extends State<VerseCoopArenaPage> {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://otaku-verse-6e05e-default-rtdb.europe-west1.firebasedatabase.app',
  );
  final QuizService _quizService = QuizService();
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;

  Map<dynamic, dynamic>? _roomData;
  StreamSubscription? _sub;
  Timer? _timer;
  int _timeLeft = 15;
  bool _hasAnswered = false;
  String? _selectedAnswer;
  bool? _lastCorrect;
  int _mesBonnesReponses = 0;
  int _transitioningIndex = -1;
  bool _cloture = false;
  int? _xpPartagee;

  @override
  void initState() {
    super.initState();
    _sub = _db.ref('coop/${widget.roomId}').onValue.listen((event) {
      if (event.snapshot.value is Map && mounted) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final bool first = _roomData == null;
        final bool nextQ = _roomData != null &&
            _roomData!['currentQuestionIndex'] != data['currentQuestionIndex'];

        setState(() {
          _roomData = data;
          if (nextQ) {
            _hasAnswered = false;
            _selectedAnswer = null;
            _lastCorrect = null;
            _timeLeft = 15;
            _demarrerTimer();
          }
        });

        if (first) {
          _demarrerTimer();
        }

        final int idx = data['currentQuestionIndex'] ?? 0;
        final Map p1 = data['player1'] ?? {};
        final Map p2 = data['player2'] ?? {};
        final bool p1Done = p1['answeredIndex'] == idx;
        final bool p2Done = (p2['isBot'] == true) || (p2['answeredIndex'] == idx);

        if (data['status'] != 'finished' && p1Done && p2Done) {
          _timer?.cancel();
          _passerQuestionSuivante(idx);
        }
      }
    });
  }

  void _demarrerTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          t.cancel();
          if (!_hasAnswered) {
            _repondre('');
          }
          _passerQuestionSuivante(_roomData?['currentQuestionIndex'] ?? 0);
        }
      });
    });
  }

  void _passerQuestionSuivante(int idx) {
    if (_transitioningIndex == idx) return;
    _transitioningIndex = idx;
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted || _roomData == null) return;
      final questions = _roomData!['questions'] as List<dynamic>? ?? [];
      if (_roomData!['status'] != 'finished' && (_roomData!['currentQuestionIndex'] ?? 0) == idx) {
        if (idx + 1 >= questions.length) {
          await _db.ref('coop/${widget.roomId}').update({'status': 'finished'});
        } else {
          await _db.ref('coop/${widget.roomId}').update({'currentQuestionIndex': idx + 1});
        }
      }
    });
  }

  Future<void> _repondre(String choix) async {
    if (_hasAnswered || _roomData == null) return;
    setState(() {
      _hasAnswered = true;
      _selectedAnswer = choix;
    });

    final int idx = _roomData!['currentQuestionIndex'] ?? 0;
    final List<dynamic> questions = _roomData!['questions'] ?? [];
    if (idx >= questions.length) return;
    final q = questions[idx];

    final bool isP1 = _roomData!['player1']?['id'] == _currentUserId;
    final String myKey = isP1 ? 'player1' : 'player2';
    final Map p2 = _roomData!['player2'] ?? {};

    bool correct = false;
    bool botAllieCorrect = false;

    if (choix.isNotEmpty) {
      try {
        final res = await _quizService.validerReponse(
          questionId: q['id'],
          reponse: choix,
          comboJoueur: 0,
          comboBot: 0,
          difficulte: 'difficile', // l'allié bot a 70% de réussite
        );
        correct = res.joueurCorrect;
        botAllieCorrect = res.botCorrect;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _lastCorrect = correct;
        if (correct) _mesBonnesReponses++;
      });
    }

    final int mesBonnes = (_roomData![myKey]?['bonnesReponses'] ?? 0) + (correct ? 1 : 0);
    await _db.ref('coop/${widget.roomId}/$myKey').update({
      'answeredIndex': idx,
      'bonnesReponses': mesBonnes,
    });

    int bossPv = _roomData!['bossPv'] ?? 200;
    int teamPv = _roomData!['teamPv'] ?? 100;

    // Dégâts du joueur humain
    if (correct) {
      bossPv = (bossPv - 20).clamp(0, 200);
    } else {
      teamPv = (teamPv - 15).clamp(0, 100);
    }

    // Si le coéquipier est l'IA A.K.I.N.A, appliquer aussi son tour d'équipe
    if (p2['isBot'] == true) {
      if (botAllieCorrect) {
        // Bonus de synergie (+10 PV) si les deux alliés ont juste sur le même tour
        final int degatsAllie = correct ? 30 : 20;
        bossPv = (bossPv - degatsAllie).clamp(0, 200);
        await _db.ref('coop/${widget.roomId}/player2').update({
          'bonnesReponses': (p2['bonnesReponses'] ?? 0) + 1,
        });
      } else {
        teamPv = (teamPv - 10).clamp(0, 100);
      }
    }

    await _db.ref('coop/${widget.roomId}').update({
      'bossPv': bossPv,
      'teamPv': teamPv,
      if (bossPv == 0 || teamPv == 0) 'status': 'finished',
    });
  }

  Future<void> _cloturerCoop(bool victoire) async {
    if (_cloture) return;
    _cloture = true;
    int xp = 25 + (_mesBonnesReponses * 10) + (victoire ? 30 : 0);
    try {
      final resp = await Supabase.instance.client.functions.invoke(
        'valider-reponse',
        body: {
          'action': 'cloturer_match_verse',
          'user_id': _currentUserId,
          'resultat': victoire ? 'victoire' : 'defaite',
          'mode': 'coop',
          'ko': victoire,
          'bonnes_reponses': _mesBonnesReponses,
        },
      );
      if (resp.status == 200 && resp.data is Map) {
        xp = (resp.data['xp_gagne'] as int?) ?? xp;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _xpPartagee = xp);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_roomData == null) {
      return const Scaffold(
        backgroundColor: OtakuColors.background,
        body: Center(child: CircularProgressIndicator(color: OtakuColors.modeCoop)),
      );
    }

    final int bossPv = _roomData!['bossPv'] ?? 200;
    final int teamPv = _roomData!['teamPv'] ?? 100;
    final List<dynamic> questions = _roomData!['questions'] ?? [];
    final int idx = _roomData!['currentQuestionIndex'] ?? 0;

    if (_roomData!['status'] == 'finished' || idx >= questions.length) {
      final bool victoire = bossPv == 0 || (teamPv > 0 && bossPv < 100);
      _cloturerCoop(victoire);
      final Map p1 = _roomData!['player1'] ?? {};
      final Map p2 = _roomData!['player2'] ?? {};
      final int scoreEquipe = (p1['bonnesReponses'] ?? 0) + (p2['bonnesReponses'] ?? 0);

      return Scaffold(
        backgroundColor: OtakuColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                victoire ? "BOSS TERRASSÉ EN ÉQUIPE !" : "ÉQUIPE VAINCUE...",
                style: OtakuTypo.headlineLarge.copyWith(
                  color: victoire ? OtakuColors.modeCoop : Colors.redAccent,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text("Score combiné : $scoreEquipe bonnes réponses", style: OtakuTypo.bodySmall),
              if (_xpPartagee != null) ...[
                const SizedBox(height: 10),
                Text("+$_xpPartagee XP COOP", style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.accent)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.modeCoop),
                onPressed: () => Navigator.pop(context),
                child: const Text("RETOUR AU HUB"),
              ),
            ],
          ),
        ),
      );
    }

    final q = questions[idx];
    final Map p1 = _roomData!['player1'] ?? {};
    final Map p2 = _roomData!['player2'] ?? {};

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/skins/skin_default.png',
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ClipOval(
                        child: Image.asset(
                          'assets/images/skins/bot_akina.png',
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "ÉQUIPE (${p1['pseudo'] ?? 'J1'} & ${p2['pseudo'] ?? 'J2'}) : $teamPv PV",
                        style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.modeCoop, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text("$_timeLeft s", style: OtakuTypo.headlineSmall),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "GARDIEN DU VERSE : $bossPv / 200 PV",
                        style: OtakuTypo.bodySmall.copyWith(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      ClipOval(
                        child: Image.asset(
                          'assets/images/skins/boss_gardien.png',
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OtakuColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OtakuColors.modeCoop.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    if (q['imageUrl'] != null && (q['imageUrl'] as String).isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(q['imageUrl'] as String, height: 95, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(q['question'] ?? '', style: OtakuTypo.headlineSmall.copyWith(fontSize: 15), textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildBtn('A', q['choixA'] ?? '')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildBtn('B', q['choixB'] ?? '')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildBtn('C', q['choixC'] ?? '')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildBtn('D', q['choixD'] ?? '')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBtn(String lettre, String texte) {
    final bool selected = _selectedAnswer == lettre;
    Color bg = OtakuColors.surface;
    Color border = Colors.transparent;
    if (_hasAnswered && selected && _lastCorrect != null) {
      bg = _lastCorrect! ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3);
      border = _lastCorrect! ? Colors.green : Colors.red;
    }
    return GestureDetector(
      onTap: () {
        if (!_hasAnswered && _timeLeft > 0) _repondre(lettre);
      },
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 2),
        ),
        child: Center(
          child: Text(texte, style: OtakuTypo.bodySmall.copyWith(fontSize: 12), textAlign: TextAlign.center, maxLines: 2),
        ),
      ),
    );
  }
}
