import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_service.dart', 'r') as f:
    content = f.read()

content = content.replace("anime: params.anime,\n      difficulte:", "anime: params.anime,\n      arc: params.arc,\n      difficulte:")

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_service.dart', 'w') as f:
    f.write(content)
