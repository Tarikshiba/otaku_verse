import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_models.dart', 'r') as f:
    content = f.read()

content = content.replace("final String? anime;\n  final String difficulte;", "final String? anime;\n  final String? arc;\n  final String difficulte;")
content = content.replace("this.anime, required this.difficulte", "this.anime, this.arc, required this.difficulte")

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_models.dart', 'w') as f:
    f.write(content)
