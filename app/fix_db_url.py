import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/verse/matchmaking_service.dart', 'r') as f:
    content = f.read()

content = content.replace("import 'package:firebase_database/firebase_database.dart';", "import 'package:firebase_core/firebase_core.dart';\nimport 'package:firebase_database/firebase_database.dart';")
content = content.replace("final FirebaseDatabase _db = FirebaseDatabase.instance;", "final FirebaseDatabase _db = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://otaku-verse-6e05e-default-rtdb.europe-west1.firebasedatabase.app');")

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/verse/matchmaking_service.dart', 'w') as f:
    f.write(content)
