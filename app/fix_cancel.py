import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/verse/matchmaking_service.dart', 'r') as f:
    content = f.read()

content = content.replace("sub.cancel();", "sub?.cancel();")

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/verse/matchmaking_service.dart', 'w') as f:
    f.write(content)
