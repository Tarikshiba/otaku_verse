import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_models.dart', 'r') as f:
    content = f.read()

# Replace variables
if "final String? arc;" not in content:
    content = content.replace("final String? anime;", "final String? anime;\n  final String? arc;")

# Replace constructor
if "this.arc," not in content:
    content = content.replace("this.anime,\n    required this.difficulte,", "this.anime,\n    this.arc,\n    required this.difficulte,")

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_models.dart', 'w') as f:
    f.write(content)
