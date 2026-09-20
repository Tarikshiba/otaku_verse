import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'combat_models.dart';
import 'combat_service.dart';
import 'combat_page.dart';

class CombatSetupPage extends StatefulWidget {
  const CombatSetupPage({super.key});

  @override
  State<CombatSetupPage> createState() => _CombatSetupPageState();
}

class _CombatSetupPageState extends State<CombatSetupPage> {
  final CombatService _combatService = CombatService();
  final PageController _pageController = PageController();

  String? _animeChoisi;
  String? _arcChoisi;
  List<String> _arcsDisponibles = [];
  bool _chargementArcs = false;
  String _difficulteChoisie = 'moyen';
  List<String> _animesDisponibles = [];
  bool _chargementAnimes = true;
  bool _lancementCombat = false;
  int _currentPage = 0;

  static const List<Map<String, String>> _difficultes = [
    {'id': 'facile', 'label': 'FACILE', 'desc': "Bot faible — pour s'echauffer"},
    {'id': 'moyen', 'label': 'MOYEN', 'desc': 'Bot equilibre — 50/50'},
    {'id': 'difficile', 'label': 'DIFFICILE', 'desc': 'Bot redoutable'},
    {'id': 'expert', 'label': 'EXPERT', 'desc': 'Bot quasi-imbattable'},
    {'id': 'adaptatif', 'label': 'ADAPTATIF', 'desc': "S'ajuste a ton niveau"},
  ];

  @override
  void initState() {
    super.initState();
    _chargerAnimes();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _chargerAnimes() async {
    try {
      final animes = await _combatService.recupererAnimesDisponibles();
      if (!mounted) return;
      setState(() {
        _animesDisponibles = animes;
        _chargementAnimes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargementAnimes = false);
    }
  }

  Future<void> _lancerCombat() async {
    setState(() => _lancementCombat = true);
    try {
      final params = CombatParams(anime: _animeChoisi, arc: _arcChoisi, difficulte: _difficulteChoisie);
      final questions = await _combatService.preparerCombat(params);
      if (!mounted) return;
      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune question disponible pour ces parametres.')));
        setState(() => _lancementCombat = false);
        return;
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CombatPage(questions: questions, params: params)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur de connexion')));
      setState(() => _lancementCombat = false);
    }
  }

  Future<void> _chargerArcs() async {
    if (_animeChoisi == null) return;
    setState(() => _chargementArcs = true);
    try {
      final arcs = await _combatService.recupererArcsDisponibles(_animeChoisi!);
      if (!mounted) return;
      setState(() {
        _arcsDisponibles = arcs;
        _chargementArcs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargementArcs = false);
    }
  }

  void _nextPage() async {
    if (_currentPage == 0) {
      if (_animeChoisi != null) {
        _chargerArcs();
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        setState(() => _currentPage++);
      } else {
        _arcChoisi = null; // Tous les animes -> pas d'arc possible
        // On saute la page des arcs
        _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        setState(() => _currentPage = 2);
      }
    } else if (_currentPage == 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header minimaliste
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text('PARAMETRES', style: OtakuTypo.headlineLarge.copyWith(fontSize: 18)),
                  const Spacer(),
                  Text(
                  _animeChoisi == null 
                      ? '${_currentPage == 0 ? 1 : 2}/2' 
                      : '${_currentPage + 1}/3',
                  style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted),
                ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            
            // Contenu (PageView sans defilement libre)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPageAnime(),
                  _buildPageArc(),
                  _buildPageDifficulte(),
                ],
              ),
            ),
            
            // Footer : Boutons Retour / Suivant (façon eFootball)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _prevPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OtakuColors.border),
                      ),
                      child: Text('RETOUR', style: OtakuTypo.label),
                    ),
                  ),
                  if (_currentPage < 2)
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: OtakuColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('SUIVANT', style: OtakuTypo.label.copyWith(color: Colors.black)),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _lancementCombat ? null : _lancerCombat,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [OtakuColors.accent, OtakuColors.accentDark]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: OtakuColors.accent.withValues(alpha: 0.5), blurRadius: 12),
                          ],
                        ),
                        child: _lancementCombat
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('LANCER', style: OtakuTypo.label.copyWith(color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageAnime() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CHOISIS TON TERRAIN', style: OtakuTypo.headlineLarge.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text("L'univers des questions de ce combat.", style: OtakuTypo.bodySmall),
          const SizedBox(height: 16),
          if (_chargementAnimes)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildChipAnime(null, 'TOUS LES ANIMES'),
                    ..._animesDisponibles.map((anime) => _buildChipAnime(anime, anime.toUpperCase())),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChipAnime(String? anime, String label) {
    final estSelectionne = _animeChoisi == anime;
    return GestureDetector(
      onTap: () => setState(() => _animeChoisi = anime),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: estSelectionne ? OtakuColors.accent : OtakuColors.surface,
          border: Border.all(
            color: estSelectionne ? OtakuColors.accent : OtakuColors.border,
            width: estSelectionne ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: OtakuTypo.headlineSmall.copyWith(
            fontSize: 12,
            color: estSelectionne ? Colors.black : OtakuColors.textPrimary,
          ),
        ),
      ),
    );
  }


  Widget _buildPageArc() {
    if (_animeChoisi == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHOISIS L\'ARC', style: OtakuTypo.headlineLarge.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text("Tu as choisi 'Tous les animes'. Tu ne peux pas filtrer par arc.", style: OtakuTypo.bodySmall),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CHOISIS L\'ARC', style: OtakuTypo.headlineLarge.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text("Filtre les questions sur un moment precis de l'histoire.", style: OtakuTypo.bodySmall),
          const SizedBox(height: 16),
          if (_chargementArcs)
            const Center(child: CircularProgressIndicator())
          else if (_arcsDisponibles.isEmpty)
            Text("Aucun arc specifique disponible pour cet anime.", style: OtakuTypo.bodySmall)
          else
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildChipArc(null, 'TOUS LES ARCS'),
                    ..._arcsDisponibles.map((arc) => _buildChipArc(arc, arc.toUpperCase())),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChipArc(String? arc, String label) {
    final estSelectionne = _arcChoisi == arc;
    return GestureDetector(
      onTap: () => setState(() => _arcChoisi = arc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: estSelectionne ? OtakuColors.accent : OtakuColors.surface,
          border: Border.all(
            color: estSelectionne ? OtakuColors.accent : OtakuColors.border,
            width: estSelectionne ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: OtakuTypo.headlineSmall.copyWith(
            fontSize: 12,
            color: estSelectionne ? Colors.black : OtakuColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildPageDifficulte() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("FORCE DE L'ADVERSAIRE", style: OtakuTypo.headlineLarge.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text("Definis la difficulte de l'IA.", style: OtakuTypo.bodySmall),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _difficultes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final diff = _difficultes[index];
                final estSelectionne = _difficulteChoisie == diff['id'];
                return GestureDetector(
                  onTap: () => setState(() => _difficulteChoisie = diff['id']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: estSelectionne ? OtakuColors.accent.withValues(alpha: 0.1) : OtakuColors.surface,
                      border: Border.all(
                        color: estSelectionne ? OtakuColors.accent : OtakuColors.border,
                        width: estSelectionne ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          estSelectionne ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: estSelectionne ? OtakuColors.accent : OtakuColors.textMuted,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(diff['label']!, style: OtakuTypo.headlineLarge.copyWith(
                              fontSize: 14,
                              color: estSelectionne ? OtakuColors.accent : OtakuColors.textPrimary,
                            )),
                            Text(diff['desc']!, style: OtakuTypo.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
