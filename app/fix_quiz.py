import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/quiz/quiz_service.dart', 'r') as f:
    content = f.read()

content = content.replace("String? anime,\n    String? difficulte,", "String? anime,\n    String? arc,\n    String? difficulte,")

if "requete.eq('arc', arc);" not in content:
    content = content.replace("if (anime != null) {\n      requete = requete.eq('anime', anime);\n    }", "if (anime != null) {\n      requete = requete.ilike('anime', anime);\n    }\n    if (arc != null) {\n      requete = requete.ilike('arc', arc);\n    }")

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/quiz/quiz_service.dart', 'w') as f:
    f.write(content)
