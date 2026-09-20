import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/shared/app_shell.dart', 'r') as f:
    content = f.read()

# 1. Unlock modes
old_division = "_buildModeOption('DIVISION — Monte en rang', Icons.military_tech_rounded, OtakuColors.modeDivision, false, 'DIVISION')"
new_division = "_buildModeOption('DIVISION — Monte en rang', Icons.military_tech_rounded, OtakuColors.modeDivision, true, 'DIVISION')"

old_duel = "_buildModeOption('DUEL — Defi un ami', Icons.people_alt_rounded, OtakuColors.modeDuel, false, 'DUEL')"
new_duel = "_buildModeOption('DUEL — Defi un ami', Icons.people_alt_rounded, OtakuColors.modeDuel, true, 'DUEL')"

content = content.replace(old_division, new_division)
content = content.replace(old_duel, new_duel)

# 2. Add imports if needed
if "import '../features/verse/verse_division_page.dart';" not in content:
    content = content.replace("import '../features/combat/combat_setup_page.dart';", "import '../features/combat/combat_setup_page.dart';\nimport '../features/verse/verse_division_page.dart';\nimport '../features/verse/verse_duel_setup_page.dart';")

# 3. Modify the big button routing
old_routing = """              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CombatSetupPage()),
              ),"""
new_routing = """              onTap: () {
                if (_modeActif == 'SOLO') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CombatSetupPage()));
                } else if (_modeActif == 'DIVISION') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseDivisionPage()));
                } else if (_modeActif == 'DUEL') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseDuelSetupPage()));
                }
              },"""
content = content.replace(old_routing, new_routing)

# Also update the icon/color for the big button based on mode if needed
# Wait, it's already using _modeActif:
# _modeActif == 'SOLO' ? Icons.bolt_rounded : Icons.lock_rounded
# Let's fix this so it doesn't show a lock for unlocked modes!
old_icon_logic = """Icon(
                          _modeActif == 'SOLO' ? Icons.bolt_rounded : Icons.lock_rounded, 
                          color: _modeActif == 'SOLO' ? OtakuColors.modeSolo : OtakuColors.textMuted, 
                          size: 24,
                        ),"""
new_icon_logic = """Icon(
                          _modeActif == 'SOLO' ? Icons.bolt_rounded : 
                          _modeActif == 'DIVISION' ? Icons.military_tech_rounded :
                          _modeActif == 'DUEL' ? Icons.people_alt_rounded : Icons.lock_rounded, 
                          color: _modeActif == 'SOLO' ? OtakuColors.modeSolo : 
                                 _modeActif == 'DIVISION' ? OtakuColors.modeDivision :
                                 _modeActif == 'DUEL' ? OtakuColors.modeDuel : OtakuColors.textMuted, 
                          size: 24,
                        ),"""
content = content.replace(old_icon_logic, new_icon_logic)

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/shared/app_shell.dart', 'w') as f:
    f.write(content)
