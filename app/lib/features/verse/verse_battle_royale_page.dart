import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../quiz/quiz_service.dart';
import 'verse_v5_service.dart';

/// Écran d'accueil du mode Battle Royale Quiz (V5 : 10 joueurs, survie par élimination)
class VerseBattleRoyalePage extends StatefulWidget {
  const VerseBattleRoyalePage({super.key});

  @override
  State<VerseBattleRoyalePage> createState() => _VerseBattleRoyalePageState();
}

class _VerseBattleRoyalePageState extends State<VerseBattleRoyalePage> {
  final VerseV5Service _service = VerseV5Service();
  final TextEditingController _codeCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _lancer({String? code}) async {
    setState(() => _loading = true);
    try {
      final res = await _service.creerOuRejoindreBattleRoyale(codeSalon: code);
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerseBattleRoyaleArenaPage(
            lobbyId: res['lobbyId'] as String,
            code: res['code'] as String,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("BATTLE ROYALE QUIZ (10 JOUEURS)", style: OtakuTypo.headlineSmall),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department_rounded, size: 64, color: Colors.deepOrangeAccent),
                const SizedBox(height: 10),
                Text("SURVIS JUSQU'AU TOP #1", style: OtakuTypo.headlineLarge),
                const SizedBox(height: 6),
                Text(
                  "10 combattants entrent dans l'arène. Chaque mauvaise réponse retire 35 PV. À 0 PV, c'est l'élimination immédiate.",
                  style: OtakuTypo.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                if (_loading)
                  const CircularProgressIndicator(color: Colors.deepOrangeAccent)
                else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent),
                    onPressed: () => _lancer(),
                    icon: const Icon(Icons.flash_on_rounded),
                    label: const Text("LANCER UNE ARÈNE 10 JOUEURS"),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: OtakuTypo.headlineSmall,
                      decoration: InputDecoration(
                        hintText: "CODE SALON BR (6 CHIFFRES)",
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
                    onPressed: () => _lancer(code: _codeCtrl.text),
                    child: const Text("REJOINDRE LE SALON BR"),
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

/// Arène Battle Royale en temps réel (10 joueurs, élimination progressive)
class VerseBattleRoyaleArenaPage extends StatefulWidget {
  final String lobbyId;
  final String code;
  const VerseBattleRoyaleArenaPage({super.key, required this.lobbyId, required this.code});

  @override
  State<VerseBattleRoyaleArenaPage> createState() => _VerseBattleRoyaleArenaPageState();
}

class _VerseBattleRoyaleArenaPageState extends State<VerseBattleRoyaleArenaPage> {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://otaku-verse-6e05e-default-rtdb.europe-west1.firebasedatabase.app',
  );
  final QuizService _quizService = QuizService();
  final VerseV5Service _v5Service = VerseV5Service();
  final String _myId = Supabase.instance.client.auth.currentUser!.id;

  Map<dynamic, dynamic>? _data;
  StreamSubscription? _sub;
  Timer? _timer;
  int _timeLeft = 15;
  bool _answered = false;
  String? _selected;
  bool? _lastCorrect;
  int _bonnesReponses = 0;
  int _transitionIdx = -1;
  bool _rewardDone = false;
  Map<String, int>? _rewards;

  @override
  void initState() {
    super.initState();
    _sub = _db.ref('battle_royale/${widget.lobbyId}').onValue.listen((event) {
      if (event.snapshot.value is Map && mounted) {
        final d = event.snapshot.value as Map<dynamic, dynamic>;
        final bool first = _data == null;
        final bool changed = _data != null &&
            _data!['currentQuestionIndex'] != d['currentQuestionIndex'];

        setState(() {
          _data = d;
          if (changed) {
            _answered = false;
            _selected = null;
            _lastCorrect = null;
            _timeLeft = 15;
            _startTimer();
          }
        });

        if (first) _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          t.cancel();
          if (!_answered) _valider('');
        }
      });
    });
  }

  Future<void> _valider(String choix) async {
    if (_answered || _data == null) return;
    setState(() {
      _answered = true;
      _selected = choix;
    });
    _timer?.cancel();

    final int idx = _data!['currentQuestionIndex'] ?? 0;
    final List<dynamic> questions = _data!['questions'] ?? [];
    if (idx >= questions.length) return;
    final q = questions[idx];

    bool correct = false;
    if (choix.isNotEmpty) {
      try {
        final v = await _quizService.validerReponse(
          questionId: q['id'],
          reponse: choix,
          comboJoueur: 0,
          comboBot: 0,
          difficulte: 'moyen',
        );
        correct = v.joueurCorrect;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _lastCorrect = correct;
        if (correct) _bonnesReponses++;
      });
    }

    // Mettre à jour les PV de tous les joueurs (humain + bots survivants)
    final Map rawJoueurs = (_data!['joueurs'] is Map) ? Map.from(_data!['joueurs'] as Map) : {};
    final Map<String, dynamic> updatedJoueurs = {};
    final rng = Random();

    int survivantsRestants = 0;

    for (final entry in rawJoueurs.entries) {
      final String jId = entry.key.toString();
      final Map jData = Map.from(entry.value as Map);
      int pv = jData['pv'] ?? 100;
      int score = jData['score'] ?? 0;
      bool elimine = jData['elimine'] == true;

      if (!elimine) {
        if (jId == _myId) {
          if (correct) {
            score += 100;
          } else {
            pv = (pv - 35).clamp(0, 100);
          }
        } else if (jData['isBot'] == true) {
          // Chaque bot a 55% de chance de survivre au tour sans perdre de PV
          final bool botReussit = rng.nextDouble() < 0.55;
          if (botReussit) {
            score += 80;
          } else {
            pv = (pv - 35).clamp(0, 100);
          }
        }
        if (pv == 0) {
          elimine = true;
        }
      }

      if (!elimine) survivantsRestants++;
      updatedJoueurs[jId] = {
        ...jData,
        'pv': pv,
        'score': score,
        'elimine': elimine,
      };
    }

    final bool jeSuisElimine = updatedJoueurs[_myId]?['elimine'] == true;
    final bool partieFinie = survivantsRestants <= 1 || jeSuisElimine || (idx + 1 >= questions.length);

    await _db.ref('battle_royale/${widget.lobbyId}/joueurs').set(updatedJoueurs);

    if (_transitionIdx == idx) return;
    _transitionIdx = idx;

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      if (partieFinie) {
        await _db.ref('battle_royale/${widget.lobbyId}').update({'status': 'finished'});
      } else {
        await _db.ref('battle_royale/${widget.lobbyId}').update({'currentQuestionIndex': idx + 1});
      }
    });
  }

  Future<void> _calculerRecompenses(int rang) async {
    if (_rewardDone) return;
    _rewardDone = true;
    final r = await _v5Service.attribuerRecompensesBattleRoyale(rang, _bonnesReponses);
    if (mounted) setState(() => _rewards = r);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return const Scaffold(
        backgroundColor: OtakuColors.background,
        body: Center(child: CircularProgressIndicator(color: Colors.deepOrangeAccent)),
      );
    }

    final Map rawJoueurs = (_data!['joueurs'] is Map) ? Map.from(_data!['joueurs'] as Map) : {};
    final List<Map<String, dynamic>> listeJoueurs = rawJoueurs.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    listeJoueurs.sort((a, b) {
      final int pvCmp = ((b['pv'] ?? 0) as int).compareTo((a['pv'] ?? 0) as int);
      if (pvCmp != 0) return pvCmp;
      return ((b['score'] ?? 0) as int).compareTo((a['score'] ?? 0) as int);
    });

    final int survivants = listeJoueurs.where((j) => j['elimine'] != true).length;
    final int monRang = listeJoueurs.indexWhere((j) => j['id'] == _myId) + 1;
    final Map<String, dynamic> moi = listeJoueurs.firstWhere(
      (j) => j['id'] == _myId,
      orElse: () => {'pv': 0, 'elimine': true},
    );

    final List<dynamic> questions = _data!['questions'] ?? [];
    final int idx = _data!['currentQuestionIndex'] ?? 0;

    if (_data!['status'] == 'finished' || moi['elimine'] == true || idx >= questions.length) {
      final int rangFinal = monRang > 0 ? monRang : 10;
      _calculerRecompenses(rangFinal);

      return Scaffold(
        backgroundColor: OtakuColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                rangFinal == 1 ? "TOP #1 SURVIVANT DU VERSE !" : "FIN DU BATTLE ROYALE (TOP #$rangFinal / ${listeJoueurs.length})",
                style: OtakuTypo.headlineLarge.copyWith(
                  color: rangFinal == 1 ? Colors.amber : Colors.deepOrangeAccent,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 12),
              if (_rewards != null)
                Text(
                  "+${_rewards!['xp']} XP  |  +${_rewards!['coins']} VERSE COINS",
                  style: OtakuTypo.headlineSmall.copyWith(color: Colors.greenAccent),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent),
                onPressed: () => Navigator.pop(context),
                child: const Text("RETOUR AU HUB"),
              ),
            ],
          ),
        ),
      );
    }

    final q = questions[idx];

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
                  Text(
                    "SURVIVANTS : $survivants / ${listeJoueurs.length} (CODE ${widget.code})",
                    style: OtakuTypo.bodySmall.copyWith(color: Colors.deepOrangeAccent, fontWeight: FontWeight.bold),
                  ),
                  Text("$_timeLeft s", style: OtakuTypo.headlineSmall),
                  Text(
                    "MES PV : ${moi['pv']} / 100",
                    style: OtakuTypo.bodySmall.copyWith(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Bandeau temps réel des 10 survivants
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: listeJoueurs.map((j) {
                    final bool elim = j['elimine'] == true;
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: elim ? Colors.red.withValues(alpha: 0.15) : OtakuColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: elim ? Colors.redAccent : Colors.greenAccent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        elim ? "${j['pseudo']} (K.O.)" : "${j['pseudo']} (${j['pv']} PV)",
                        style: TextStyle(
                          fontSize: 10,
                          color: elim ? Colors.redAccent : Colors.white,
                          decoration: elim ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OtakuColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrangeAccent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    if (q['imageUrl'] != null && (q['imageUrl'] as String).isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(q['imageUrl'] as String, height: 90, fit: BoxFit.contain),
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
    final bool selected = _selected == lettre;
    Color bg = OtakuColors.surface;
    Color border = Colors.transparent;
    if (_answered && selected && _lastCorrect != null) {
      bg = _lastCorrect! ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3);
      border = _lastCorrect! ? Colors.green : Colors.red;
    }
    return GestureDetector(
      onTap: () {
        if (!_answered && _timeLeft > 0) _valider(lettre);
      },
      child: Container(
        height: 52,
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
