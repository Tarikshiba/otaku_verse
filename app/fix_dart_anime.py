import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_service.dart', 'r') as f:
    content = f.read()

# Fix recupererAnimesDisponibles
old_recuperer = """    final animes = (reponse as List)
        .map((row) => row['anime'] as String)
        .toSet()
        .toList();
    animes.sort();
    return animes;"""

new_recuperer = """    final animes = (reponse as List)
        .map((row) => (row['anime'] as String).toLowerCase())
        .toSet()
        .toList();
    animes.sort();
    return animes;"""

content = content.replace(old_recuperer, new_recuperer)

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_service.dart', 'w') as f:
    f.write(content)
