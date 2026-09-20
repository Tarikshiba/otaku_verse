import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_setup_page.dart', 'r') as f:
    content = f.read()

# Shrink top header paddings
content = content.replace("padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),", "padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),")
content = content.replace("const SizedBox(height: 24),", "const SizedBox(height: 12),")

# Page Anime layout fixes
content = content.replace("padding: const EdgeInsets.symmetric(horizontal: 24),", "padding: const EdgeInsets.symmetric(horizontal: 16),")
content = content.replace("fontSize: 24", "fontSize: 18") # Make titles slightly smaller
content = content.replace("const SizedBox(height: 32),", "const SizedBox(height: 16),")
content = content.replace("padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),", "padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),")

# Page Difficulte layout fixes
content = content.replace("padding: const EdgeInsets.all(16),", "padding: const EdgeInsets.all(10),")
content = content.replace("const SizedBox(height: 12)", "const SizedBox(height: 6)")
content = content.replace("fontSize: 16", "fontSize: 14")

# Footer buttons fixes
content = content.replace("padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),", "padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),")
content = content.replace("padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),", "padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),")

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_setup_page.dart', 'w') as f:
    f.write(content)
