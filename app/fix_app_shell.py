import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/shared/app_shell.dart', 'r') as f:
    content = f.read()

# 1. Remove Collection button
content = re.sub(r"const SizedBox\(height: 12\),\s*_buildSideNavButton\('Collection', Icons\.style_rounded, \(\) \{\}\),", "", content)

# 2. Add _modeActif variable
content = content.replace("  int _unreadMails = 0; // Pastille boite de reception (simulation pour l'instant)", 
"""  int _unreadMails = 0; // Pastille boite de reception (simulation pour l'instant)
  String _modeActif = 'SOLO';""")

# 3. Add _showModeDrawer method
drawer_code = """
  void _showModeDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: OtakuColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: OtakuColors.glassBorder),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: OtakuColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 10),
            Text('SELECTIONNER LE MODE', style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeOption('SOLO — Affronte l\\'IA', Icons.bolt_rounded, OtakuColors.modeSolo, true, 'SOLO'),
                    const SizedBox(height: 8),
                    _buildModeOption('DIVISION — Monte en rang', Icons.military_tech_rounded, OtakuColors.modeDivision, false, 'DIVISION'),
                    const SizedBox(height: 8),
                    _buildModeOption('DUEL — Defi un ami', Icons.people_alt_rounded, OtakuColors.modeDuel, false, 'DUEL'),
                    const SizedBox(height: 8),
                    _buildModeOption('COOP — Faites equipe', Icons.group_work_rounded, OtakuColors.modeCoop, false, 'COOP'),
                    const SizedBox(height: 8),
                    _buildModeOption('EVENEMENT — Defis limites', Icons.local_fire_department_rounded, OtakuColors.modeEvent, false, 'EVENTS'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(String label, IconData icon, Color couleur, bool actif, String mode) {
    return GestureDetector(
      onTap: actif ? () {
        setState(() => _modeActif = mode);
        Navigator.pop(context);
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: actif ? couleur.withValues(alpha: 0.12) : OtakuColors.glassBackground,
          border: Border.all(
            color: actif ? couleur.withValues(alpha: 0.6) : OtakuColors.glassBorder,
            width: actif ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: couleur.withValues(alpha: 0.15),
                border: Border.all(color: couleur.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, size: 18, color: couleur),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: OtakuTypo.headlineSmall.copyWith(fontSize: 12, color: actif ? OtakuColors.textPrimary : OtakuColors.textMuted)),
            ),
            if (actif)
              Icon(Icons.check_circle_rounded, size: 18, color: couleur)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: OtakuColors.border, borderRadius: BorderRadius.circular(4)),
                child: Text('BIENTOT', style: OtakuTypo.label.copyWith(fontSize: 7, color: OtakuColors.textMuted)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {"""

content = content.replace("  @override\n  Widget build(BuildContext context) {", drawer_code)

# 4. Make the Mode box clickable and dynamic
mode_box_old = """        // Mode de jeu actuel (en bas a gauche)
        Positioned(
          bottom: 24,
          left: 24,
          child: SafeArea(
            child: LiquidGlass(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('MODE SELECTIONNE', style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.textMuted)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: OtakuColors.modeSolo, size: 20),
                      const SizedBox(width: 8),
                      Text('SOLO', style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),"""

mode_box_new = """        // Mode de jeu actuel (en bas a gauche)
        Positioned(
          bottom: 24,
          left: 24,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => _showModeDrawer(context),
              child: LiquidGlass(
                tintColor: OtakuColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('MODE SELECTIONNE', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.textMuted)),
                        const SizedBox(width: 8),
                        const Icon(Icons.expand_less_rounded, color: OtakuColors.textMuted, size: 14),
                      ]
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _modeActif == 'SOLO' ? Icons.bolt_rounded : Icons.lock_rounded, 
                          color: _modeActif == 'SOLO' ? OtakuColors.modeSolo : OtakuColors.textMuted, 
                          size: 18
                        ),
                        const SizedBox(width: 6),
                        Text(_modeActif, style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),"""

content = content.replace(mode_box_old, mode_box_new)

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/shared/app_shell.dart', 'w') as f:
    f.write(content)

