import re

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Replace bad apostrophe escaping with double quotes
    content = content.replace("Text('RECHERCHE D\\'ADVERSAIRE...'", 'Text("RECHERCHE D\'ADVERSAIRE..."')
    content = content.replace("Text('Recherche d\\'un joueur de ton rang'", 'Text("Recherche d\'un joueur de ton rang"')
    content = content.replace("hintText: 'ENTRER LE CODE D\\'UN AMI'", 'hintText: "ENTRER LE CODE D\'UN AMI"')

    with open(filepath, 'w') as f:
        f.write(content)

fix_file('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/verse/verse_division_page.dart')
fix_file('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/verse/verse_duel_setup_page.dart')
