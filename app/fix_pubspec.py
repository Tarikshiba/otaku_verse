import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/pubspec.yaml', 'r') as f:
    content = f.read()

content = content.replace("firebase_database: ^11.4.1", "firebase_database: ^11.3.10")

with open('/mnt/c/All-projects/2026/Otaku_verse/app/pubspec.yaml', 'w') as f:
    f.write(content)
