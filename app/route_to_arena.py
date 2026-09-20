import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/verse/verse_division_page.dart', 'r') as f:
    content = f.read()

# Add import
if "import 'verse_combat_page.dart';" not in content:
    content = content.replace("import 'matchmaking_service.dart';", "import 'matchmaking_service.dart';\nimport 'verse_combat_page.dart';")

# Update routing
old_todo = """      // TODO: Naviguer vers l'ecran du combat V2 avec le matchId
      // Future.delayed(const Duration(seconds: 2), () {
      //   Navigator.pushReplacement(...);
      // });"""
new_routing = """      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => VerseCombatPage(matchId: matchId)),
        );
      });"""

content = content.replace(old_todo, new_routing)

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/verse/verse_division_page.dart', 'w') as f:
    f.write(content)
