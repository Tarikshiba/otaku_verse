import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_setup_page.dart', 'r') as f:
    content = f.read()

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

if "Widget _buildPageArc()" not in content:
    content = content.replace("  Widget _buildPageDifficulte() {", page_arc_code + "\n  Widget _buildPageDifficulte() {")

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_setup_page.dart', 'w') as f:
    f.write(content)
