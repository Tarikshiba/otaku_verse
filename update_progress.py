import re

with open('/mnt/c/All-projects/2026/Otaku_verse/PROGRESS.md', 'r') as f:
    content = f.read()

# Replace work in progress/completed
old_dashboard = "- [ ] **V1 — Tableau de bord (Next.js)**"
new_dashboard = "- [x] **V1 — Tableau de bord (Next.js)** (Importation en masse `.md` OK)"
content = content.replace(old_dashboard, new_dashboard)

if "- [ ] Ajout de l'Arc dans l'interface Solo" in content:
    content = content.replace("- [ ] Ajout de l'Arc dans l'interface Solo", "- [x] Ajout de l'Arc dans l'interface Solo (et fix doublons animes)")
else:
    # Append to MVP section
    content = content.replace("## 3. V1 — MVP Solo & Base", "## 3. V1 — MVP Solo & Base\n- [x] Ajout de l'Arc dans l'interface Solo (et fix doublons animes)")

old_v2 = "- [ ] **V2 — Le Verse (Matchmaking)**"
new_v2 = "- [x] **V2 — Le Verse (Matchmaking)** (Firebase configuré, UI déverrouillée, Bot Fallback OK)"
content = content.replace(old_v2, new_v2)

# Update Next Steps
next_steps_start = content.find("## 5. PROCHAINES ÉTAPES IMMÉDIATES")
next_steps_text = """## 5. PROCHAINES ÉTAPES IMMÉDIATES

1. **Mécanique de combat V2 (Realtime)**
   - Récupérer les questions depuis Supabase et les injecter dans le match Firebase.
   - Synchroniser le timer (15s) et l'affichage des questions entre les deux joueurs.
   - Calculer les dégâts et mettre à jour les PV en temps réel.
2. **Mode Duel Amical**
   - Finaliser l'interface de création de salon (Choix Anime/Arc/Diff).
   - Générer le code à 6 chiffres et permettre à un ami de le rejoindre.
3. **Supabase Edge Functions**
   - Sécuriser la fin du match et le calcul des points/divisions côté serveur.
4. **Finalisation du Dashboard Admin**
   - Permettre l'ajout d'images dans les questions (si besoin).
"""
content = content[:next_steps_start] + next_steps_text

with open('/mnt/c/All-projects/2026/Otaku_verse/PROGRESS.md', 'w') as f:
    f.write(content)
