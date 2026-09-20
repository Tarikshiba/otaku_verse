import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/verse/verse_duel_setup_page.dart', 'r') as f:
    content = f.read()

old_body = """      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column("""

new_body = """      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column("""

content = content.replace(old_body, new_body)

# Add closing parenthesis for SingleChildScrollView
content = content.replace("          ),\n        ),\n      ),\n    );\n  }\n}", "            ),\n          ),\n        ),\n      ),\n    );\n  }\n}")

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/verse/verse_duel_setup_page.dart', 'w') as f:
    f.write(content)
