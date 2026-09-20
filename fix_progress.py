import re

with open('/mnt/c/All-projects/2026/Otaku_verse/PROGRESS.md', 'r') as f:
    content = f.read()

old_next = """### Prochaine session — Corrections post-test
- Appliquer les retours de Tariq et Heat apres test sur telephone (bugs, UI, UX)
- Importer les questions .md en masse dans Supabase (fichiers deja prets)
- Si le temps le permet : entamer la V2"""

new_next = """### Prochaine session — Dashboard Admin & Import en Masse
- Coder la fonctionnalite d'importation de questions en masse (via upload de fichier .md ou .csv) directement depuis le Dashboard Admin (Next.js).
- Parser et inserer les nouveaux fichiers fournis par Heat (`naruto introduction quiz.md` et `otaku verse east blue v2.md`) via ce nouveau systeme.
- Si le temps le permet : entamer la V2"""

content = content.replace(old_next, new_next)

with open('/mnt/c/All-projects/2026/Otaku_verse/PROGRESS.md', 'w') as f:
    f.write(content)
