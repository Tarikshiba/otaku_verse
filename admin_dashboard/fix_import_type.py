import re

with open('/mnt/c/All-projects/2026/Otaku_verse/admin_dashboard/app/api/questions/import/route.ts', 'r') as f:
    content = f.read()

old_insert = """        bonne_reponse,
        explication,
        statut: "actif"
      });"""

new_insert = """        bonne_reponse,
        explication,
        statut: "actif",
        type: "general"
      });"""

content = content.replace(old_insert, new_insert)

with open('/mnt/c/All-projects/2026/Otaku_verse/admin_dashboard/app/api/questions/import/route.ts', 'w') as f:
    f.write(content)
