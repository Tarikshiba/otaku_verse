import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/shared/app_shell.dart', 'r') as f:
    content = f.read()

# Add import
if "import '../features/progression/quete_service.dart';" not in content:
    content = content.replace("import 'textures.dart';", "import 'textures.dart';\nimport '../features/progression/quete_service.dart';")

quete_code = """class _QuetePageState extends State<_QuetePage> {
  final QueteService _queteService = QueteService();
  bool _chargement = true;

  List<_Quete> _quetes = [
    _Quete(titre: 'Joue 3 combats', recompense: '+30 XP', progression: 2, objectif: 3, icon: Icons.bolt_rounded, couleur: OtakuColors.modeSolo),
    _Quete(titre: 'Gagne 1 combat', recompense: '+50 XP', progression: 0, objectif: 1, icon: Icons.emoji_events_rounded, couleur: OtakuColors.modeEvent),
    _Quete(titre: 'Connecte-toi 3 jours', recompense: '+20 XP', progression: 3, objectif: 3, icon: Icons.calendar_today_rounded, couleur: OtakuColors.pvHaut),
    _Quete(titre: 'Fais un combo x3', recompense: 'Skin Rare', progression: 0, objectif: 1, icon: Icons.local_fire_department_rounded, couleur: OtakuColors.modeDuel),
    _Quete(titre: 'Ajoute 2 amis', recompense: '+25 XP', progression: 1, objectif: 2, icon: Icons.people_rounded, couleur: OtakuColors.modeCoop),
  ];

  @override
  void initState() {
    super.initState();
    _chargerQuetes();
  }

  Future<void> _chargerQuetes() async {
    final state = await _queteService.getQuetesState();
    if (!mounted) return;
    
    setState(() {
      for (int i = 0; i < _quetes.length; i++) {
        final q = _quetes[i];
        if (state.containsKey(q.titre)) {
          _quetes[i] = _Quete(
            titre: q.titre,
            recompense: q.recompense,
            progression: state[q.titre]!['progression'] ?? q.progression,
            objectif: q.objectif,
            icon: q.icon,
            couleur: q.couleur,
            recupere: state[q.titre]!['recupere'] ?? false,
          );
        }
      }
      _chargement = false;
    });
  }

  void _recuperer(int index) {
    final q = _quetes[index];
    setState(() => _quetes[index] = q.copyRecupere());
    
    // Sync with Supabase in background
    _queteService.syncQuete(q.titre, q.progression, true);
  }

  @override
  Widget build(BuildContext context) {"""

# Replace old _QuetePageState start with new one
old_quete_code = """class _QuetePageState extends State<_QuetePage> {
  final List<_Quete> _quetes = [
    _Quete(titre: 'Joue 3 combats', recompense: '+30 XP', progression: 2, objectif: 3, icon: Icons.bolt_rounded, couleur: OtakuColors.modeSolo),
    _Quete(titre: 'Gagne 1 combat', recompense: '+50 XP', progression: 0, objectif: 1, icon: Icons.emoji_events_rounded, couleur: OtakuColors.modeEvent),
    _Quete(titre: 'Connecte-toi 3 jours', recompense: '+20 XP', progression: 3, objectif: 3, icon: Icons.calendar_today_rounded, couleur: OtakuColors.pvHaut),
    _Quete(titre: 'Fais un combo x3', recompense: 'Skin Rare', progression: 0, objectif: 1, icon: Icons.local_fire_department_rounded, couleur: OtakuColors.modeDuel),
    _Quete(titre: 'Ajoute 2 amis', recompense: '+25 XP', progression: 1, objectif: 2, icon: Icons.people_rounded, couleur: OtakuColors.modeCoop),
  ];

  void _recuperer(int index) {
    setState(() => _quetes[index] = _quetes[index].copyRecupere());
  }

  @override
  Widget build(BuildContext context) {"""

content = content.replace(old_quete_code, quete_code)

# Add loading spinner to build
content = content.replace("""              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _quetes.length,""",
"""              const SizedBox(height: 12),
              _chargement ? const Center(child: CircularProgressIndicator()) : Expanded(
                child: ListView.separated(
                  itemCount: _quetes.length,""")

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/shared/app_shell.dart', 'w') as f:
    f.write(content)

