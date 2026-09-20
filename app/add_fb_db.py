with open('/mnt/c/All-projects/2026/Otaku_verse/app/pubspec.yaml', 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    new_lines.append(line)
    if "firebase_messaging" in line:
        new_lines.append("  firebase_database: ^11.4.1\n")

with open('/mnt/c/All-projects/2026/Otaku_verse/app/pubspec.yaml', 'w') as f:
    f.writelines(new_lines)
