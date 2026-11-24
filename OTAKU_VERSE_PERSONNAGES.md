# OTAKU VERSE — Personnages et assets

Fichier de travail : tu modifies l'apparence, la technique, les prompts etc. au fur et à mesure.
Chaque fiche suit le même modèle. Remplace les "(à définir)" quand tu as décidé.

## CORRESPONDANCE ANCIENS NOMS → NOUVEAUX NOMS (à lire en premier si tu es une IA de développement)

Les noms de départ des skins, qui figuraient dans `ASSETS_A_CREER_VISUEL_3D.txt`, ont été **remplacés**. Plusieurs étaient des références à des œuvres existantes (Naruto, One Piece, Bleach, L'Attaque des Titans…), ce qui est un risque de droits d'auteur pour une publication sur les stores.

**Ce qui change** : le nom affiché du perso, son apparence, son pouvoir et son lore (tout est dans les fiches ci-dessous).

**Ce qui ne change pas** : l'identifiant technique (`skin_xxx`), les noms de fichiers `.png` et `.glb`, le prix et la rareté.

**À faire côté code, base de données et interface** : remplace partout l'ancien nom par le nouveau (boutique, collection, profil, traductions, données de test). Toute mention des anciens noms est obsolète.

| Identifiant / fichier | Ancien nom | Rareté et prix | Nouveau nom |
|---|---|---|---|
| `skin_default` | Guerrier du Verse | gratuit de départ | **Kio** |
| `skin_ninja` | Ninja de Konoha | 1er Goodies Tuto, 300 OC | **Mazú** |
| `skin_pirate` | Capitaine Pirate | Classique, 350 VC | **Tavik** |
| `skin_samourai` | Ronin de Wano | Classique, 400 VC | **Ruvé** |
| `skin_ermite` | Ermite des Cimes | Classique, 450 VC | **Hesk** |
| `skin_titan` | Chasseur de Titans | Classique, 500 VC | **Ilka** |
| `skin_demon` | Pourfendeur Démoniaque | Épique, 700 VC | **Vael** |
| `skin_hokage` | Ombre du Hokage | Épique, 800 VC | **Dakoré** |
| `skin_dragon` | Guerrier Dragon | Épique, 850 VC | **Ysaé** |
| `skin_roi` | Souverain des Ombres | Épique, 900 VC | **Cassio Vey** |
| `avatar_soryn_ether_watcher` | Soryn, Gardien de l'Ether | Fondateur, 1200 VC | **Soryn** (nom inchangé, design à refaire) |
| `avatar_nyxara_twin_fangs` | Nyxara, Crocs Jumeaux | Fondateur, 1500 VC | **Nyxara** (nom inchangé, design à refaire) |

Rappel : en match classé, les pouvoirs des skins sont **100 % visuels** (règle R1, zéro pay-to-win).

---

## Règles communes

- **Concept** : chaque skin est un *Rescapé*, quelqu'un qui porte le dernier objet ou le dernier savoir d'un monde effacé par l'Oubli. Les cultures sont mélangées, tout joueur doit pouvoir s'identifier.
- **R1 (zéro pay-to-win)** : en mode classé, les pouvoirs sont **100 % visuels** (habillage des slots Lecture / Garde / Frappe, bonus Haya!!, Combo x3, Finisher). Ils deviennent de vraies mécaniques seulement quand on affronte le perso en Boss ou en Donjon.
- **Visuel** : style black art / manga moderne, fond saturé, peau travaillée (ombres brun-violet, lumière chaude), pose de combat, pas de "fiche de perso" debout.
- **Fichiers à produire par perso** : `skin_xxx.png` (768x1024, fond transparent, < 350 Ko) et `skin_xxx.glb` (< 2,5 Mo).

### Prompt maître (à coller avant le prompt du perso)

```
Dynamic fighting game key art, shonen/seinen manga style, powerful battle
stance, low-angle camera, strong foreshortening, aggressive readable
silhouette, visible energy effect in the character's signature color,
torn clothes and battle damage, fierce determined expression, dramatic
rim lighting, bold inked linework, high contrast, speed lines and impact
particles, flat saturated solid color background.
NOT a character sheet, NOT a turnaround, NOT standing idle,
no text, no labels, no measurements.
```

---

## 1. KIO

- **Fichier** : `skin_default` (gratuit, skin de départ)
- **Couleur dominante** : gris-bleu `#6F8499`
- **Rôle** : le novice, celui que tout joueur incarne au début
- **Apparence** : adolescent d'environ 17 ans, corps sec et musclé, dos large et veiné, peau brune moyenne à foncée, cheveux afro bouclés courts avec de petits anneaux et cuffs dorés dans les mèches, petite créole dorée à l'oreille, regard par-dessus l'épaule, bouche légèrement entrouverte (tendu, aux aguets). Pantalon noir à ceinture bleue. Vêtement du haut : (à définir, ex. veste patchwork posée sur l'avant-bras ou nouée à la taille).
- **Objet signature** : aucun, c'est son corps
- **Pouvoir : Mémoire Musculaire (Copie Imparfaite)**
  - Ses **fibres musculaires** enregistrent les gestes des attaques qu'il encaisse ou observe, puis il les rejoue. En physique quantique, on ne peut pas copier parfaitement un état (théorème de non-clonage) : la copie sort toujours déformée, parfois en pire, parfois en mieux.
- **Au combat** : il commence le duel plus faible et devient dangereux au fil des coups, car il se bat avec les gestes de l'adversaire. Les fibres de ses bras et de son dos s'illuminent en lignes gris-bleu quand elles enregistrent un mouvement.
- **Dans le quiz** :
  - Lecture : son corps frissonne (muscles qui tressaillent) quand une réponse est fausse
  - Haya!! : il rejoue instantanément le dernier geste adverse
  - Ultime : **« Corps Complet »**, toutes les attaques mémorisées enchaînées en un seul coup
- **Prix** : face à un adversaire passif, il n'a rien à copier. Chaque copie fatigue ses muscles (crampes, tremblements).
- **Prompt IA** :
```
Young Black male fighter around 17, lean muscular build, wide veined back, medium-dark brown skin, short curly afro with small gold hair rings and cuffs, small gold hoop earring, looking over his shoulder with a tense alert expression, black pants with blue waistband, glowing gray-blue lines running along his muscle fibers as they record a movement, mid-combat stance, copying the enemy's last strike with his own body.
```
- **Statut** : [ ] apparence validée   [ ] png fait   [ ] glb fait

---

## 2. MAZÚ

- **Fichier** : `skin_ninja` (Goodies Tuto, 300 OC)
- **Couleur dominante** : orange
- **Rôle** : coursière des zones effacées
- **Apparence** : jeune femme d'environ 24 ans, peau brune moyenne, locks courtes orange corail mi-longues, regard vert-jaune sévère et provocateur, petits piercings (sourcil, nez, oreilles), lunettes à verres ambrés, fines chaînes argentées avec pendentif croix, bagues, vernis coloré. Tenue streetwear : sweat crop blanc oversize à rayures brunes, cargo beige très large taille basse, ceinture marron à breloque étoile, doudoune noire ouverte, sac à dos vert (sa sacoche de livraison), baskets blanches et rouges. En combat : doudoune déchirée, une manche arrachée, enveloppes qui dépassent du sac.
- **Objet signature** : enveloppes scellées à la cire grise (idée optionnelle : son téléphone orange comme « terminal » qui envoie les lettres)
- **Pouvoir : Courrier Intriqué**
  - Chaque lettre a une jumelle posée en secret chez l'adversaire. Quand Mazú froisse l'une, l'autre frappe instantanément, quelle que soit la distance (intrication quantique).
- **Au combat** : l'impact apparaît avant qu'elle ait lancé la lettre.
- **Dans le quiz** : Haya!! = le coup touche « avant » la réponse (image rémanente) ; Garde = la lettre renvoie le coup à l'expéditeur ; Ultime = **« Tournée Générale »**, des centaines de lettres livrées d'un coup.
- **Prix** : une lettre dont la jumelle est détruite ne frappe plus.
- **Prompt IA** :
```
Young woman fighter around 24, medium golden-brown skin, shoulder-length coral-orange locs, sharp green-yellow eyes, small piercings (eyebrow, nose, ears), amber tinted sunglasses pushed up on her head, thin silver chains with cross pendant, rings and colorful nail art, oversized cropped white sweatshirt with brown stripes and one sleeve torn off, very baggy low-rise beige cargo pants, brown belt with star charm, torn black puffer jacket, green backpack stuffed with wax-sealed envelopes, white and red sneakers, mid low-slide attack, a fan of letters flying from her hand like throwing blades with orange trails, orange sparks under her soles, cocky provocative expression.
```
- **Statut** : [ ] apparence validée   [ ] png fait   [ ] glb fait

---

## 3. TAVIK

- **Fichier** : `skin_pirate` (Classique, 350 VC)
- **Couleur dominante** : vert tilleul
- **Rôle** : mécano-bidouilleur, la « radio » vivante des Rescapés
- **Apparence** : homme d'environ 38 ans, grand, peau très foncée, barbe pleine et soignée, lunettes de soleil rondes, locks attachées en chignon haut avec de longues mèches fines qui retombent (elles servent d'antennes). Colliers superposés (perles de bois, chaînes dorées, pendentif rond en forme de cadran de radio), bracelets noirs épais, bracelets dorés, bagues. Veste ample à motif tissé rouge-orange-violet, nouée à la taille avec son propre pan de tissu, gilet beige en maille ouvert sur le torse, énorme pantalon sarouel gris anthracite froissé et resserré aux chevilles, bottines noires en cuir à lacets. En combat : veste déchirée aux manches, fissures lumineuses vert tilleul qui courent sur sa peau et ses colliers.
- **Objet signature** : une énorme clé à molette qu'il porte sur l'épaule comme un bâton. **La radio cassée, c'est lui-même.**
- **Pouvoir : Fréquences Mortes**
  - Tavik est la radio cassée : son corps est un récepteur, et les voix des disparus passent à travers lui en grésillant. Il capte la fréquence exacte d'une attaque et lui oppose son contraire pour l'annuler (interférence destructive).
- **Au combat** : ses longues mèches fines se dressent comme des antennes quand il capte une fréquence, une grille de haut-parleur fissurée s'allume dans sa poitrine, et chaque coup de clé crée une onde stationnaire qui fait vibrer et paralyse la cible. Entre deux coups, il rappuie la clé sur son épaule, calme.
- **Dans le quiz** : Garde = dôme de brouillage ; Lecture = les mauvaises réponses « grésillent » ; Ultime = **« Fréquence Fantôme »**, toutes les voix des disparus parlent à travers lui en même temps et font trembler l'arène.
- **Prix** : tout ce qui est silencieux lui échappe, et plus il capte, plus sa propre voix se brouille (parfois il parle avec la voix d'un autre).
- **Prompt IA** :
```
Tall Black man fighter around 38, very dark skin, full groomed beard, round sunglasses, locs tied in a high bun with long thin locs hanging down like antennas, layered necklaces (wooden beads, gold chains, round radio-dial pendant), thick black bangles and gold bracelets, rings, oversized red-orange-purple woven jacket tied at the waist and torn at the sleeves, beige knit vest open on the chest revealing a cracked speaker grille glowing lime-green with static, huge drop-crotch charcoal harem pants gathered at the ankles, black lace-up leather boots, carrying a giant oversized wrench on his shoulder like a staff, lime-green sound waves rippling around his body, calm menacing stance.
```
- **Statut** : [ ] apparence validée   [ ] png fait   [ ] glb fait

---

## 4. RUVÉ

- **Fichier** : `skin_samourai` (Classique, 400 VC)
- **Couleur dominante** : rouge brique
- **Rôle** : cuisinière de rue, la plus âgée des Rescapés
- **Apparence** : femme d'environ 60 ans, petite mais large, peau brun profond, paupières lourdes à moitié fermées, sourire en coin sournois qui montre des **dents en or**, locks épaisses et hirsutes en partie relevées sous un **foulard rouge brique**. **Pas de tablier** : costume noir cintré, chemise blanche, cravate noire, manches retroussées jusqu'aux coudes, avant-bras marqués de cicatrices de vapeur, bottes de travail. (Costume repris de la référence, à confirmer.)
- **Objet signature** : une **énorme louche**, presque aussi grande qu'elle, portée comme une masse de guerre. Sa marmite en fonte est sanglée dans son dos et crache la vapeur.
- **Pouvoir : Cuisson Lente**
  - Elle remue le temps avec sa louche : dans la vapeur de sa marmite, les attaques adverses se déroulent au ralenti pendant qu'elle agit à vitesse normale (dilatation temporelle).
- **Au combat** : elle pose des zones de vapeur, les remue à coups de louche et cuit l'adversaire à petit feu. La louche sert aussi de massue.
- **Dans le quiz** : Garde = elle brandit la louche et un dôme de vapeur se forme ; Ultime = **« Le Plat de Famille »**, une table de convives venus de son monde disparu, qui frappent chacun une fois.
- **Prix** : plus la vapeur dure, plus elle se fatigue.
- **Prompt IA** :
```
Elderly Black woman fighter around 60, short and broad, deep brown skin, heavy-lidded half-closed eyes, sly half-smile showing gold teeth, thick graying locs partly pulled up under a brick-red headscarf, tailored black suit jacket with white shirt and black tie, sleeves rolled to the elbows, steam-scarred forearms, work boots, wielding an enormous ladle as big as herself like a war hammer, cast-iron pot strapped to her back venting scalding brick-red steam with faint faces inside, mid-swing smashing the ladle down, steam swirling around the impact.
```
- **Statut** : [ ] apparence validée   [ ] png fait   [ ] glb fait

---

## 5. HESK

- **Fichier** : `skin_ermite` (Classique, 450 VC)
- **Couleur dominante** : violet aubergine
- **Rôle** : jeune tatoueur-cartographe
- **Apparence** : homme d'environ 26 ans, mince, peau très foncée, visage calme et fermé, regard fixe. **Grosses locks sculptées qui se dressent en cornes** sur le haut de la tête (pas de crâne rasé), quelques longues mèches fines qui pendent sur les côtés. **Lunettes rondes** à fine monture métallique, verres clairs. Longue boucle d'oreille en spirale de cuivre avec un petit **coquillage cauri** qui pend près de la joue, fin collier de perles vertes et noires. Tunique blanche ample avec des pièces noires cousues et des coutures apparentes, étole en tissu à motifs géométriques bruns, noirs et blancs (type tissu boue) jetée sur l'épaule. Tatouages en forme de cartes sur le cou, les mains et les avant-bras. **Pas d'accessoire.**
- **Objet signature** : aucun, tout passe par sa peau
- **Pouvoir : Cartographie Pliée**
  - Ses tatouages sont les cartes de lieux effacés. Il trace du doigt un trait entre deux points de l'arène et les deux points se touchent (pliage de l'espace).
- **Au combat** : des lignes de lumière violette se détachent de ses tatouages (mains, avant-bras, cou), traversent l'arène et se fixent sur l'adversaire. Il se téléporte entre deux traits ou plie l'espace pour renvoyer une attaque sur son lanceur.
- **Dans le quiz** : Lecture = un trait lumineux indique le chemin vers la bonne réponse ; Ultime = **« Atlas Perdu »**, toute l'arène se réécrit sur la carte de sa peau.
- **Prix** : chaque trait tracé s'efface de sa peau, donc de sa mémoire.
- **Prompt IA** :
```
Young Black man fighter around 26, very dark skin, calm closed expression, big sculpted locs standing up like horns on top of his head with a few long thin locs hanging at the sides, round thin metal-framed glasses with clear lenses, long copper spiral earring with a small cowrie shell dangling near his cheek, thin green and black bead necklace, loose white tunic with black patches and visible stitching, brown black and white geometric mud-cloth shawl draped over one shoulder, map-like tattoos on his neck, hands and forearms with glowing violet lines peeling off his skin and shooting across the arena, arm outstretched tracing a line through the air, no weapon, no accessories.
```
- **Statut** : [ ] apparence validée   [ ] png fait   [ ] glb fait

---

## 6. ILKA

- **Fichier** : `skin_titan` (Classique, 500 VC)
- **Couleur dominante** : or pâle
- **Rôle** : guerrière qui porte la lignée de ses ancêtres
- **Apparence** : femme d'environ 28 ans, mince et élancée, **pas musclée**, posture calme de combattante. Queue de cheval très haute et très lisse, couleur or pâle, qui retombe dans le dos, avec une frange droite. Côtés et nuque rasés, ornés d'un **motif tatoué entrelacé** (la carte de ses ancêtres). Yeux fermés ou mi-clos, trait d'eye-liner allongé, petit piercing au nez avec une fine chaîne. Grosses créoles dorées et ear cuffs, **épais collier rigide doré** posé sur des cascades de chaînes dorées qui retombent sur les épaules et le torse. Tenue : (à définir, simple et claire pour laisser les bijoux ressortir). Peau brune chaude (à ajuster).
- **Objet signature** : aucun objet à elle. Ses bijoux dorés sont les **reliques de ses ancêtres**.
- **Pouvoir : Lignée Invoquée**
  - Ilka porte en elle toutes ses ancêtres à la fois, des guerrières redoutables (superposition). À chaque instant, elle en « observe » une et celle-ci prend le dessus : Ilka se transforme en elle ou l'invoque dans son dos. Chaque ancêtre a son pouvoir et son bijou-relique :
    1. **La Fouetteuse** : les chaînes deviennent des fouets d'or qui frappent de loin
    2. **Mère-Collier** : le collier rigide devient un bouclier
    3. **L'Aveugle d'Or** : elle combat les yeux fermés et lit les attaques avant qu'elles arrivent
    4. **La Chanteuse de Guerre** : chant de guerre qui la rend fulgurante
    5. **La Première** : la plus ancienne, rarement invoquée, la plus dangereuse
- **Au combat** : les combats d'Ilka sont précis et gracieux, pas brutaux. Le motif tatoué sur sa tête et sa nuque s'allume, et la silhouette dorée de l'ancêtre invoquée se superpose à elle.
- **Dans le quiz** : Lecture = L'Aveugle d'Or ; Garde = Mère-Collier ; Frappe = La Fouetteuse ; Haya!! = La Chanteuse de Guerre ; Ultime = **« Procession d'Or »**, les cinq ancêtres apparaissent derrière elle et frappent à la suite.
- **Prix** : plus l'ancêtre reste, moins Ilka reste. Sa voix change, ses souvenirs se brouillent, et si elle laisse la même ancêtre trop longtemps, il faut la rappeler à elle-même.
- **Prompt IA** :
```
Slender elegant woman fighter around 28, warm brown skin, calm closed eyes with long winged eyeliner, very high sleek ponytail in pale gold falling down her back with straight blunt bangs, shaved sides and nape with intricate tattooed ornament glowing gold, small nose stud with fine chain, large gold hoop earrings and ear cuffs, thick rigid gold collar over cascades of gold chains draped on shoulders and chest, golden ghost silhouettes of five warrior ancestors rising behind her, a whip of gold chain links lashing from her hand, graceful precise battle stance, pale gold palette.
```
- **Statut** : [ ] apparence validée   [ ] png fait   [ ] glb fait

---

## 7. VAEL

- **Fichier** : `skin_demon` (Épique, 700 VC)
- **Couleur dominante** : vert foncé, blanc cassé et noir
- **Rôle** : androgyne à moitié oublié, combattant de MMA
- **Apparence** : personne androgyne d'environ 24 ans, silhouette athlétique mais fine, **teint clair**, traits fins, regard froid et calme, **pas de lunettes**. **Bandana vert foncé** noué sur la tête. Boucles d'oreilles et pendentif en forme d'**ancre**. Noms écrits à la main, tatoués sur le cou et les avant-bras. Tenue de **combattant MMA** : haut de compression noir sans manches, short de combat blanc cassé à ceinture épaisse, bandes de mains noires, pieds nus. Les noms des disparus sont brodés sur ses bandes de mains et sur la ceinture du short.
- **Objet signature** : l'ancre qu'il porte au cou et aux oreilles, qui le retient dans la mémoire des vivants
- **Pouvoir : Présence Incertaine**
  - Vael est à moitié oublié, donc à moitié absent. Plus on le fixe, moins il est solide, et inversement (effet de l'observateur inversé). Ses prises de MMA sont presque impossibles à saisir parce qu'il n'est qu'à moitié là.
- **Au combat** : il enchaîne frappes, projections et soumissions, clignote et réapparaît dans le dos. Les noms brodés sur ses bandes de mains sont des fantômes qui se battent pour lui.
- **Dans le quiz** : Garde = il s'efface et le piège le traverse ; Ultime = **« Appel des Noms »**, chaque nom est appelé et son fantôme frappe.
- **Prix** : si quelqu'un prononce son vrai nom, il redevient entièrement solide, donc vulnérable. Si on lui arrache son ancre, il s'efface.
- **Prompt IA** :
```
Androgynous MMA fighter around 24, light skin, fine features, calm cold gaze, no glasses, dark green bandana tied on head, small anchor earrings and anchor pendant, handwritten name tattoos on neck and forearms, sleeveless black compression top, off-white fight shorts with thick waistband, black hand wraps with embroidered names, barefoot, mid-combat grappling stance, flickering double-image afterimage, faint ghost silhouettes rising behind him, dark green and off-white palette.
```
- **Statut** : [ ] apparence validée   [ ] png fait   [ ] glb fait

---

## 8. DAKORÉ

- **Fichier** : `skin_hokage` (Épique, 800 VC)
- **Couleur dominante** : noir profond, accent bordeaux
- **Rôle** : ancien champion d'arène, bagarreur en costume
- **Apparence** : homme d'environ 30 ans, peau foncée brillante, visage fermé, regard dur, tresses courtes remontées sur le haut de la tête avec quelques boucles aux tempes, petites boucles d'oreilles. **Costume noir** parfaitement coupé, chemise blanche, cravate noire, doublure bordeaux. **Pas de manteau.** Posture calme, mains près des poches.
- **Objet signature** : sa veste, dans laquelle il cache **toutes sortes d'armes à feu**
- **Pouvoir : Partout à la Fois**
  - Dakoré est présent à plusieurs endroits en même temps (comme une particule dans plusieurs positions à la fois). Il n'y a qu'un seul vrai Dakoré, mais l'adversaire ne sait jamais lequel. Il a aussi une **excellente maîtrise du corps à corps**.
- **Au combat** : plusieurs Dakoré encadrent l'adversaire, chacun frappe de son côté (corps à corps net et sec) et sort une arme à feu de sa veste quand il le faut.
- **Dans le quiz** : Garde = un Dakoré apparaît devant le piège et encaisse à sa place ; Haya!! = un Dakoré déjà à la bonne place frappe avant ; Ultime = **« Salle Pleine »**, des dizaines de Dakoré remplissent l'arène et ouvrent le feu de tous les côtés.
- **Prix** : plus il se multiplie, moins chaque présence est solide. Si l'adversaire touche le vrai, toutes les autres disparaissent.
- **Prompt IA** :
```
Calm lethal man around 30 in a perfectly tailored black suit, white shirt and black tie, no coat, glossy dark skin, hard stare, short braids pulled up on top of his head with loose curls at the temples, small stud earrings, burgundy jacket lining revealing hidden holstered firearms, several identical copies of him standing in the arena at the same time, one in a sharp close-combat strike stance, cold bluish lighting, black and burgundy palette.
```
- **Statut** : [ ] apparence validée   [ ] png fait   [ ] glb fait

---

## 9. YSAÉ

- **Fichier** : `skin_dragon` (Épique, 850 VC)
- **Couleur dominante** : crème, noir et cyan (cyan = lueur des serpents)
- **Rôle** : adolescent turbulent, petit frère d'Ilka et fils de Cassio Vey
- **Apparence** : adolescent d'environ 16 ans, svelte, peau brune dorée couverte de motifs d'encre (lignes, boucles, symboles) sur le torse et les bras, torse nu, large pantalon sarouel crème noué à la taille, pieds nus. Cheveux courts en désordre avec une longue tresse, anneau au nez, boucles d'oreilles. Sourire de chenapan, regard vif. **Plusieurs bras supplémentaires** couverts des mêmes motifs : ils ressemblent à des bras avec des mains, mais ce sont en réalité des **serpents qu'il matérialise**.
- **Objet signature** : aucun, ses bras-serpents
- **Pouvoir : Hostilité Renvoyée**
  - Il ressent toute hostilité dirigée contre lui. Impossible de l'attaquer : l'attaque se retourne contre son auteur. Il est aussi **extrêmement rapide et fort en arts martiaux**.
- **Au combat** : arts martiaux ultra-rapides, bras-serpents qui s'enroulent et frappent. Quand quelqu'un l'attaque avec hostilité, une onde cyan l'entoure et le coup revient sur l'attaquant.
- **Dans le quiz** : Garde = le piège adverse se retourne contre son lanceur (visuellement) ; Haya!! = frappe d'arts martiaux ultra-rapide ; Frappe = les bras-serpents ; Ultime = **« Nid de Serpents »**, tous ses bras-serpents se matérialisent et enlacent l'arène.
- **Prix** : il ne sent que l'hostilité. Un coup sans méchanceté (un jeu, un accident, une main amie) le touche de plein fouet.
- **Prompt IA** :
```
Skinny teenage martial artist around 16, shirtless, golden-brown skin covered in intricate ink patterns, loose cream-white harem pants, barefoot, short messy hair with one long braid, nose ring and earrings, mischievous grin, extra arms covered in the same patterns that are actually snakes with hands, glowing cyan, fast martial arts stance, an enemy's attack bouncing back with a cyan reflection ripple.
```
- **Statut** : [ ] apparence validée   [ ] png fait   [ ] glb fait

---

## 10. CASSIO VEY

- **Fichier** : `skin_roi` (Épique, 900 VC)
- **Couleur dominante** : blanc, gris-bleu et or
- **Rôle** : père d'Ilka et d'Ysaé, le Dernier Écouteur
- **Apparence** : homme d'environ 55 ans, grand et mince, **oreilles pointues**, yeux couverts d'un **bandeau blanc** orné d'une pièce dorée. Peau foncée marquée de **grandes rayures blanches et grises** sur le visage, le cou, les épaules et les bras : ce sont les voix possibles. Bijoux dorés ouvragés : large collier rigide, chaînes et pendentifs, bracelets de bras et de poignets, bagues sur presque tous les doigts. Tenue : tissu clair ample sur les épaules (à définir).
- **Objet signature** : aucun, ses marques sur le corps
- **Pouvoir : Somme des Futurs**
  - Il entend toutes les issues possibles du combat en même temps (somme sur les histoires possibles). Chaque rayure de sa peau est une voix, un futur possible. Il écoute celle qui murmure la victoire et fait taire les autres.
- **Au combat** : il reste immobile, tête inclinée, pendant que ses rayures s'allument et que les voix se superposent autour de lui en ondes lumineuses.
- **Dans le quiz** : Lecture = les rayures s'allument et la voix de la bonne réponse parle plus fort ; Garde = il fait taire la pire voix, le pire futur n'arrive pas ; Ultime = **« Dernière Voix »**, toutes les voix parlent à l'unisson et l'écran rembobine la dernière seconde.
- **Prix** : à chaque voix écoutée, il perd la mémoire d'un instant de son propre passé (parfois des souvenirs de ses enfants).
- **Prompt IA** :
```
Tall slender man around 55, pointed elf-like ears, eyes covered by a white blindfold with a gold ornament, dark skin marked with bold white and gray stripes across face, neck, shoulders and arms like glowing voices, ornate gold collar, chains and pendants, gold armbands and bracelets, many rings, flowing pale cloth over his shoulders, calm listening stance with head tilted, faint luminous whispers rippling off his stripes, white, blue-gray and gold palette.
```
- **Statut** : [ ] apparence validée   [ ] png fait   [ ] glb fait

---

## LIENS ENTRE PERSOS

- **Famille** : Cassio Vey est le père d'Ilka (28 ans) et d'Ysaé (16 ans, turbulent). Ilka est la grande sœur d'Ysaé.

---

## FONDATEURS (lore dans les dossiers PDF)

### SORYN — Le Veilleur des Âmes Perdues
- **Fichier** : `avatar_soryn_ether_watcher` (Fondateur, 1200 VC)
- **Dossier de lore** : `Soryn_Veilleur_des_Ames_Perdues_Otaku_Verse.pdf`
- **Apparence** : à redessiner (le visuel actuel est jugé trop générique)
- **Statut** : [ ] apparence validée   [ ] png fait   [ ] glb fait

### NYXARA — La Souveraine des Deux Crocs
- **Fichier** : `avatar_nyxara_twin_fangs` (Fondateur, 1500 VC)
- **Dossier de lore** : `Dossier_Personnage_Nyxara_Otaku_Verse.pdf`
- **Apparence** : à redessiner (le visuel actuel est jugé trop générique)
- **Statut** : [ ] apparence validée   [ ] png fait   [ ] glb fait

---

## ASSETS VISUELS ET AUDIO (hors personnages)

### Style commun (décors, cartes, icônes)

- **Direction** : manga noir moderne, peinture à la gouache avec traits d'encre, grain de film, composition asymétrique. Pas de rendu lisse ou plastique.
- **Règles** : **aucun texte dans l'image** (les titres sont ajoutés par l'app), aucun personnage ou logo existant, aucune capture d'anime officiel.
- **Palette générale** : violet sombre et cyan (comme dans le .txt), avec une couleur d'accent par mode.
- **Astuce personnages** : pour mettre tes propres persos sur une carte, donne leur fiche de design en image de référence au générateur.
- **Format** : les générateurs sortent du PNG. Convertis en .webp avec Squoosh (squoosh.app) et vérifie le poids.

Prompt de base (à coller avant chaque prompt ci-dessous) :
```
Hand-painted manga illustration, gouache texture with bold ink linework, film grain, asymmetrical composition, dramatic lighting, high contrast, original design, no text, no letters, no logos, no existing franchise elements.
```

---

### A. DÉCORS 16:9 (4)

Dossier : `app\assets\images\backgrounds\` | Format : .webp, 1920x1080, moins de 400 Ko

#### A1. `lobby_arene_principale.webp`
- **Description** : le hall du Hub, un sanctuaire sombre fait de morceaux de mondes effacés qui flottent (une porte en bois, une étagère de livres, un panneau de rue, une arche de pierre), brume d'encre violette, lumière cyan. Au centre, un sol d'arène circulaire, dégagé et sombre, bordé d'un fin cercle cyan lumineux. Les détails sont sur les bords, le centre reste vide pour que le personnage ressorte.
- **Prompt** :
```
Wide 16:9 background of a dark sanctuary hall built from floating fragments of erased worlds (a wooden gate, bookshelves, a street sign, a stone arch), purple ink fog, cyan rim light, empty circular arena floor in the exact center softly lit by a thin cyan ring, center of the frame dark and clear for a standing character, busy details only on the left and right edges, cyberpunk meets manga ruins, no characters.
```
- **Statut** : [ ] fait   [ ] converti en .webp

#### A2. `profil_podium_bg.webp`
- **Description** : un podium rond sombre au centre, éclairé par trois projecteurs discrets (violet, cyan, blanc chaud), de la fumée au sol. Sur les murs, de petites vitrines avec des reliques à peine visibles (une enveloppe scellée, une louche, une clé à molette, une ancre). Le centre est libre pour le personnage.
- **Prompt** :
```
Wide 16:9 background of a dark round podium in the center lit by three discreet spotlights (violet, cyan, warm white) from above, low smoke on the floor, small glass display cases on the side walls holding barely visible relics (a wax-sealed envelope, a ladle, a wrench, an anchor), center of the frame empty and dark for a character, moody and elegant, no characters.
```
- **Statut** : [ ] fait   [ ] converti en .webp

#### A3. `modes_selector_bg.webp`
- **Description** : fond très sombre et très peu contrasté pour que les cartes de modes ressortent. Dégradé indigo vers noir, lignes de carte et rose des vents à peine visibles, quelques traînées de lumière en diagonale, vignettage doux. Presque rien au centre.
- **Prompt** :
```
Wide 16:9 very dark background, deep indigo fading to black, extremely faint ink map lines and compass roses, a few thin diagonal light streaks, soft vignette, very low contrast, almost empty in the center so that cards placed on top stand out, subtle and elegant, no characters.
```
- **Statut** : [ ] fait   [ ] converti en .webp

#### A4. `boutique_showroom_bg.webp`
- **Description** : un showroom de luxe de rue. Sol sombre et brillant qui reflète les lumières, piédestaux en verre de chaque côté éclairés d'or, un grand piédestal central vide avec un anneau violet lumineux. Murs avec des fresques d'encre abstraites.
- **Prompt** :
```
Wide 16:9 background of a dark luxury street showroom, polished black floor with reflections, glass pedestals along both sides lit by warm gold spotlights, one large empty pedestal in the center with a glowing violet ring, abstract ink murals on the walls, warm gold and violet palette, center of the frame empty for a character, no characters, no products.
```
- **Statut** : [ ] fait   [ ] converti en .webp

---

### B. CARTES DES MODES (8)

Dossier : `app\assets\images\modes\` | Format : .webp, moins de 250 Ko | **Pas de texte dans l'image**

| Fichier | Mode | Format | Couleur d'accent |
|---|---|---|---|
| `mode_division_tall` | Division Mondiale | 600x800 (3:4) | or et violet |
| `mode_solo_tall` | Combat Solo | 600x800 (3:4) | rouge cramoisi |
| `mode_duel_card` | Duel 1v1 Amis | 800x450 (16:9) | cyan contre magenta |
| `mode_coop_card` | Coop 2v2 / Boss | 800x450 (16:9) | vert et orange |
| `mode_br_card` | Battle Royale 10J | 800x450 (16:9) | vert toxique et noir |
| `mode_events_card` | Saisons et Tournois | 800x450 (16:9) | or et turquoise |
| `mode_salon_live_card` | Salons Live | 800x450 (16:9) | rose néon et jaune |
| `mode_donjon_card` | Donjons Otaku Forge | 800x450 (16:9) | orange forge et sombre |

#### B1. `mode_division_tall.webp`
- **Description** : le mode classé. Une spirale de plateformes monte vers un ciel d'orage, de minuscules silhouettes grimpent, et tout en haut un combattant seul tient une médaille lumineuse.
- **Prompt** :
```
Vertical 3:4 illustration of a huge spiral of stone platforms rising into a stormy sky, tiny silhouettes of fighters climbing, a lone fighter at the very top holding a glowing medal, gold and violet lighting, epic and vertiginous, no text.
```
- **Statut** : [ ] fait

#### B2. `mode_solo_tall.webp`
- **Description** : un combattant seul face à une ombre géante dans une arène vide, un seul projecteur sur lui, ambiance rouge cramoisi. Silhouette lisible, tension.
- **Prompt** :
```
Vertical 3:4 illustration of a lone fighter in a low stance facing a gigantic looming shadow in an empty arena, a single spotlight on the fighter, crimson red palette, dust particles, tense and cinematic, no text.
```
- **Statut** : [ ] fait

#### B3. `mode_duel_card.webp`
- **Description** : deux combattants face à face, composition coupée en diagonale : cyan à gauche, magenta à droite, un impact au centre.
- **Prompt** :
```
Horizontal 16:9 illustration of two fighters facing each other, composition split by a diagonal, cyan on the left and magenta on the right, a bright impact burst in the center where their fists meet, speed lines, no text.
```
- **Statut** : [ ] fait

#### B4. `mode_coop_card.webp`
- **Description** : deux combattants dos à dos face à une énorme silhouette de boss qui occupe le fond. Lumière chaude orange d'un côté, vert de l'autre.
- **Prompt** :
```
Horizontal 16:9 illustration of two fighters standing back to back in a ready stance facing a huge boss silhouette filling the background, warm orange light on one side and green on the other, dramatic teamwork feeling, no text.
```
- **Statut** : [ ] fait

#### B5. `mode_br_card.webp`
- **Description** : vue de dessus d'une arène circulaire avec dix silhouettes dispersées et un cercle de tempête verte qui se resserre.
- **Prompt** :
```
Horizontal 16:9 top-down view of a circular arena with ten small fighter silhouettes scattered around, a toxic green storm ring closing in from the edges, dark background, tense survival mood, no text.
```
- **Statut** : [ ] fait

#### B6. `mode_events_card.webp`
- **Description** : un trophée au centre d'une arène en fête, bannières de saison, lanternes, foule en silhouette, or et turquoise.
- **Prompt** :
```
Horizontal 16:9 illustration of a glowing golden trophy at the center of a festive arena, season banners, hanging lanterns, a cheering crowd in silhouette, gold and turquoise palette, celebratory and epic, no text.
```
- **Statut** : [ ] fait

#### B7. `mode_salon_live_card.webp`
- **Description** : un salon en direct. Des silhouettes d'avatars assis autour d'un grand écran qui affiche un point d'interrogation lumineux, bulles de discussion, rose néon et jaune, ambiance de soirée entre amis.
- **Prompt** :
```
Horizontal 16:9 illustration of a lively live room, many playful avatar silhouettes sitting around a big glowing screen showing a bright question mark, floating chat bubbles without text, neon pink and yellow palette, fun party atmosphere, no text.
```
- **Statut** : [ ] fait

#### B8. `mode_donjon_card.webp`
- **Description** : la porte d'un donjon-forge. Lourde porte de métal avec des chaînes et des runes lumineuses, une enclume au premier plan, de la lave en arrière-plan, orange forge sur fond sombre.
- **Prompt** :
```
Horizontal 16:9 illustration of a massive iron dungeon door wrapped in chains with glowing runes, an anvil in the foreground, lava glow in the background, sparks flying, forge orange on a dark palette, ominous and inviting, no text.
```
- **Statut** : [ ] fait

---

### C. RANGS (6)

Dossier : `app\assets\images\ranks\` | Format : .png fond transparent, 256x256, moins de 60 Ko

Prompt de base (à coller avant chaque prompt) :
```
Single game rank emblem icon, centered, transparent background, bold ink outline, flat shading with a few highlights, readable at small size, no text, no numbers, original design.
```

Principe : chaque rang garde la **goutte d'encre** au centre (le symbole du jeu) et ajoute des éléments en montant.

| Fichier | Rang | Niveaux | Description et prompt |
|---|---|---|---|
| `rank_1_bronze` | Novice du Verse | 1-5 | Petite médaille ronde en bronze martelé, une seule goutte d'encre au centre. `small round hammered bronze medal with a single ink drop in the center, rough edges` |
| `rank_2_acier` | Apprenti Otaku | 6-15 | Médaille d'acier gris-bleu, goutte d'encre et deux chevrons en dessous. `cold blue-gray steel medal with an ink drop and two chevrons below, clean cut edges` |
| `rank_3_argent` | Érudit des Arcs | 16-30 | Blason d'argent avec un livre ouvert qui entoure la goutte d'encre. `silver shield medal with an open book silhouette around an ink drop, engraved arcs` |
| `rank_4_or` | Maître de l'Encre | 31-50 | Emblème doré, pinceau et plume croisés derrière la goutte, éclaboussures d'encre. `golden emblem with a crossed brush and quill behind an ink drop, small ink splashes, warm glow` |
| `rank_5_platine` | Seigneur du Verse | 51-75 | Blason de platine ailé, couronne de pointes et petits anneaux en orbite autour de la goutte. `platinum winged crest with a crown of spikes and small orbiting rings around a central ink drop, icy white-blue glow` |
| `rank_6_legende` | Légende Éternelle | 76+ | Emblème noir et or aux reflets violets, grandes ailes, flamme d'encre qui monte, éclats flottants. `black and gold emblem with violet iridescence, large wings, a rising flame of ink, floating shards, cosmic aura` |

Statut : [ ] 1   [ ] 2   [ ] 3   [ ] 4   [ ] 5   [ ] 6

---

### D. CADRES D'AVATAR (4)

Dossier : `app\assets\images\frames\` | Format : .png fond transparent, 512x512, **intérieur entièrement vide** pour voir l'avatar

Prompt de base :
```
Circular avatar frame ring, transparent background, completely transparent empty center, bold ink outline, glowing details, no text, original design.
```

| Fichier | Prix | Description et prompt |
|---|---|---|
| `cadre_neon_shonen` | 150 VC | Double anneau néon cyan et magenta avec des étincelles en traits de vitesse. `double neon ring in cyan and magenta with speed-line sparks and small angular corner accents` |
| `cadre_flamme_astral` | 250 VC | Anneau de flammes violet-bleu avec de petites étoiles et des constellations. `ring of violet-blue flames with tiny stars and constellations` |
| `cadre_eclipse_or` | 350 VC | Bord d'éclipse noir avec une couronne de rayons dorés et un fin anneau d'or. `black eclipse edge with a golden corona of rays and a thin gold ring` |
| `cadre_vip_or_violet` | VIP exclusif | Anneau d'or ouvragé avec des gemmes violettes, filigrane et petite couronne en haut. `ornate gold ring with violet gems, fine filigree and a small crown at the top, subtle sparkle` |

Statut : [ ] 1   [ ] 2   [ ] 3   [ ] 4

---

### E. AUDIO (8)

Dossier : `app\assets\audio\` | Format : .mp3, 128 kbps | Musiques : moins de 1,5 Mo (boucle de 30 à 60 s) | Effets : moins de 80 Ko

**Poids** : à 128 kbps, 1 seconde pèse environ 16 Ko. Un effet doit donc durer **5 secondes maximum**, et une musique ne doit pas dépasser environ 90 secondes.

**Où chercher** (vérifie toujours la licence sur la page de chaque son : usage commercial autorisé, et attribution requise ou non) :

| Site | Quoi y chercher | Résultat attendu |
|---|---|---|
| pixabay.com (Sound Effects et Music) | tous les sons et musiques | une mention de licence « usage commercial autorisé » sur la page du fichier |
| freesound.org | effets sonores | filtre Licence = « Creative Commons 0 » : aucune attribution à donner |
| kenney.nl/assets (catégorie Audio) | packs « Interface Sounds », « UI Audio », « Impact Sounds » | packs gratuits sous licence CC0 |
| mixkit.co | effets et musiques | une licence Mixkit qui autorise l'usage commercial |
| opengameart.org | musiques et effets de jeu | filtre CC0 ; lis la licence de chaque fichier |
| incompetech.com | musiques (Kevin MacLeod) | licence CC-BY : **attribution obligatoire** dans les crédits de l'app |

Les musiques générées par IA (Suno, Udio, Stable Audio) : cherche dans leurs conditions d'utilisation « commercial use » et assure-toi que **ton plan** autorise l'usage commercial avant de les mettre dans l'app.

| Fichier | Rôle | Mots-clés à chercher | Résultat attendu |
|---|---|---|---|
| `bgm_lobby.mp3` | boucle calme et épique du Hub (30-60 s) | `ambient epic loop`, `fantasy ambient loop`, `cyberpunk ambient loop` | une boucle sans cassure, ambiance mystérieuse, pas de batterie forte |
| `bgm_combat.mp3` | boucle nerveuse de combat (45-60 s) | `battle loop`, `tense action loop`, `drum action loop` | rythme rapide qui boucle proprement |
| `sfx_clic.mp3` | clic de bouton | `ui click`, `button click` | un son sec de moins de 0,5 s |
| `sfx_bonne_reponse.mp3` | impact positif | `correct answer`, `positive hit`, `success chime` | un son court et satisfaisant, 1 s environ |
| `sfx_haya.mp3` | éclair rapide (moins de 2 s) | `whoosh fast`, `dash`, `lightning swoosh` | un souffle rapide, aigu, qui part vite |
| `sfx_combo.mp3` | combo x3 puissant | `power up impact`, `combo hit`, `boom impact` | un son qui monte puis tape fort, 2 à 3 s |
| `sfx_erreur.mp3` | erreur / auto-faute | `error buzzer`, `wrong answer`, `fail sound` | un son grave et court, clairement négatif |
| `sfx_ko_kecchaku.mp3` | K.O. final / victoire | `knockout`, `final hit`, `victory sting` | un coup lourd suivi d'une résonance, 3 à 4 s |

**Pour convertir** (ffmpeg) : `ffmpeg -i entree.wav -b:a 128k sortie.mp3`. Pour les boucles, coupe-les proprement avec Audacity et écoute-les en boucle avant de les garder.

Statut : [ ] bgm_lobby   [ ] bgm_combat   [ ] sfx_clic   [ ] sfx_bonne_reponse   [ ] sfx_haya   [ ] sfx_combo   [ ] sfx_erreur   [ ] sfx_ko_kecchaku

---

## Journal des changements

- 23/11/2026 : les noms de départ des 10 skins sont remplacés (voir la table de correspondance en haut du fichier)
- (date) : (ce que tu as modifié)
