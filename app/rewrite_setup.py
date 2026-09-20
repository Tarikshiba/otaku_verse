import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_setup_page.dart', 'r') as f:
    content = f.read()

# Add states for arcs
if "String? _arcChoisi;" not in content:
    content = content.replace("String? _animeChoisi;", "String? _animeChoisi;\n  String? _arcChoisi;\n  List<String> _arcsDisponibles = [];\n  bool _chargementArcs = false;")

# Fetch arcs when next page is clicked from anime (if an anime is chosen)
old_next = """  void _nextPage() {
    if (_currentPage < 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    }
  }"""

new_next = """  Future<void> _chargerArcs() async {
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
      } else {
        _arcChoisi = null; // Tous les animes -> pas d'arc possible
      }
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    } else if (_currentPage == 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    }
  }"""
if "_chargerArcs" not in content:
    content = content.replace(old_next, new_next)

# Params Update
content = content.replace("CombatParams(anime: _animeChoisi, difficulte: _difficulteChoisie)", "CombatParams(anime: _animeChoisi, arc: _arcChoisi, difficulte: _difficulteChoisie)")

# Update Max pages
content = content.replace("Text('${_currentPage + 1}/2'", "Text('${_currentPage + 1}/3'")

# Update PageView children
old_pageview = """              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Pas de swipe, on utilise les boutons
                children: [
                  _buildPageAnime(),
                  _buildPageDifficulte(),
                ],
              ),"""
new_pageview = """              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPageAnime(),
                  _buildPageArc(),
                  _buildPageDifficulte(),
                ],
              ),"""
if "_buildPageArc()" not in content:
    content = content.replace(old_pageview, new_pageview)

# Update Next/Launch button logic
old_footer_btns = """                  if (_currentPage == 0)
                    GestureDetector(
                      onTap: _nextPage,"""
new_footer_btns = """                  if (_currentPage < 2)
                    GestureDetector(
                      onTap: _nextPage,"""
content = content.replace(old_footer_btns, new_footer_btns)

# Build Page Arc
page_arc_code = """
  Widget _buildPageArc() {
    if (_animeChoisi == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHOISIS L\\'ARC', style: OtakuTypo.headlineLarge.copyWith(fontSize: 18)),
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
          Text('CHOISIS L\\'ARC', style: OtakuTypo.headlineLarge.copyWith(fontSize: 18)),
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
"""

if "_buildPageArc" not in content:
    content = content.replace("  Widget _buildPageDifficulte() {", page_arc_code + "\n  Widget _buildPageDifficulte() {")

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_setup_page.dart', 'w') as f:
    f.write(content)
