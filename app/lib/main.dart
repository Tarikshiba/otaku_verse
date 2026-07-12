import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/combat/combat_setup_page.dart';
import 'features/profile/profile_page.dart';
import 'features/progression/progression_service.dart';
import 'features/rewards/rewards_page.dart';
import 'features/rewards/rewards_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Forcer le mode paysage sur TOUTE l'app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const OtakuVerseApp());
}

class OtakuVerseApp extends StatelessWidget {
  const OtakuVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Otaku Verse',
      debugShowCheckedModeBanner: false,
      theme: otakuTheme,
      home: const AuthGate(),
    );
  }
}

/// Decide quel ecran afficher selon l'etat de connexion.
/// Reste TOUJOURS dans l'arbre — ecoute le stream auth en continu.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  bool _afficherInscription = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authService.onAuthStateChange,
      builder: (context, snapshot) {
        // Utilisateur connecte → accueil temporaire
        if (_authService.utilisateurActuel != null) {
          return AccueilTemporaire(authService: _authService);
        }

        // Pas connecte → connexion ou inscription
        if (_afficherInscription) {
          return RegisterPage(
            onBasculeConnexion: () => setState(() => _afficherInscription = false),
          );
        }
        return LoginPage(
          onBasculeInscription: () => setState(() => _afficherInscription = true),
        );
      },
    );
  }
}

/// Ecran d'accueil — style eFootball : top bar, banniere, boutons raccourcis.
class AccueilTemporaire extends StatefulWidget {
  final AuthService authService;

  const AccueilTemporaire({super.key, required this.authService});

  @override
  State<AccueilTemporaire> createState() => _AccueilTemporaireState();
}

class _AccueilTemporaireState extends State<AccueilTemporaire> {
  final ProgressionService _progressionService = ProgressionService();
  final RewardsService _rewardsService = RewardsService();

  Map<String, dynamic>? _profil;
  bool _connexionDispo = false;
  int _ongletActif = 0; // 0 = Accueil

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    try {
      await _progressionService.creerProfilSiAbsent();
      final profil = await _progressionService.recupererProfil();
      final dejaPrise = await _rewardsService.connexionDejaPrise();
      if (!mounted) return;
      setState(() {
        _profil = profil;
        _connexionDispo = !dejaPrise;
      });
    } catch (_) {}
  }

  Future<void> _reclamerConnexion() async {
    final reussi = await _rewardsService.reclamerConnexionQuotidienne();
    if (reussi && mounted) {
      setState(() => _connexionDispo = false);
      _chargerDonnees();
    }
  }

  void _confirmerQuitter() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OtakuColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('QUITTER', style: OtakuTypo.headlineSmall),
        content: const Text('Tu veux vraiment quitter le jeu ?', style: OtakuTypo.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ANNULER', style: TextStyle(color: OtakuColors.textMuted)),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('QUITTER', style: TextStyle(color: OtakuColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final niveau = _profil?['niveau'] ?? 1;
    final rang = _profil?['rang'] ?? 'Debutant';
    final xpTotale = _profil?['xp_totale'] ?? 0;
    final xpDansNiveau = ProgressionService.xpDansNiveauActuel(xpTotale as int);
    final xpPourProchain = ProgressionService.xpRequise(niveau as int);
    final progressionXp = xpPourProchain > 0 ? xpDansNiveau / xpPourProchain : 0.0;

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // === 1. TOP BAR ===
            _buildTopBar(niveau, rang, xpDansNiveau, xpPourProchain, progressionXp),

            // === 2. NAVIGATION TABS ===
            _buildNavTabs(),

            // === 3. ZONE CENTRALE (banniere + bouton combat) ===
            Expanded(child: _buildZoneCentrale()),

            // === 4. RANGEE DE BOUTONS INFERIEURE ===
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  /// Top bar : avatar + niveau a gauche, titre au centre, ressources a droite
  Widget _buildTopBar(int niveau, dynamic rang, int xpDans, int xpPour, double progression) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: OtakuColors.surface,
        border: Border(bottom: BorderSide(color: OtakuColors.border)),
      ),
      child: Row(
        children: [
          // Gauche : avatar + niveau + XP
          GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
              _chargerDonnees();
            },
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: OtakuColors.accent, width: 2),
                    borderRadius: BorderRadius.circular(4),
                    color: OtakuColors.background,
                  ),
                  child: const Icon(Icons.person, color: OtakuColors.accent, size: 18),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nv.$niveau — ${rang.toString()}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: OtakuColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progression,
                          minHeight: 4,
                          backgroundColor: OtakuColors.border,
                          valueColor: const AlwaysStoppedAnimation(OtakuColors.accent),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Text('$xpDans/$xpPour',
                    style: const TextStyle(fontSize: 9, color: OtakuColors.textMuted)),
              ],
            ),
          ),

          const Spacer(),

          // Centre : titre
          const Text('OTAKU VERSE', style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: OtakuColors.textPrimary,
            letterSpacing: 4,
          )),

          const Spacer(),

          // Droite : ressources (placeholder V1)
          Row(
            children: [
              _buildRessource(Icons.monetization_on, '0', OtakuColors.warning),
              const SizedBox(width: 10),
              _buildRessource(Icons.diamond, '0', Colors.cyanAccent),
              const SizedBox(width: 10),
              _buildRessource(Icons.confirmation_number, '3', OtakuColors.accent),
            ],
          ),
        ],
      ),
    );
  }

  /// Petite ressource affichee dans la top bar
  Widget _buildRessource(IconData icon, String valeur, Color couleur) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: couleur),
        const SizedBox(width: 3),
        Text(valeur, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: couleur)),
      ],
    );
  }

  /// Onglets de navigation horizontaux
  Widget _buildNavTabs() {
    final tabs = ['ACCUEIL', 'MISSIONS', 'BOUTIQUE', 'PARAMETRES'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: OtakuColors.border, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(tabs.length, (i) {
          final actif = i == _ongletActif;
          return GestureDetector(
            onTap: () {
              if (i == 1) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsPage()));
              } else if (i == 0) {
                setState(() => _ongletActif = 0);
              }
              // Boutique et Parametres : pas encore dispo (V1.5+)
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: actif ? OtakuColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
                border: actif ? null : Border.all(color: OtakuColors.border, width: 0.5),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: actif ? Colors.black : (i > 1 ? OtakuColors.textMuted : OtakuColors.textPrimary),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Zone centrale : banniere evenement + bouton combat
  Widget _buildZoneCentrale() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Banniere evenement (grande)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.5)),
                gradient: LinearGradient(
                  colors: [
                    OtakuColors.accentDark.withValues(alpha: 0.3),
                    OtakuColors.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Contenu banniere
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: OtakuColors.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text('EVENEMENT', style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: 1,
                          )),
                        ),
                        const SizedBox(height: 8),
                        const Text('QUIZ SHONEN', style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900, color: OtakuColors.textPrimary, letterSpacing: 2,
                        )),
                        const SizedBox(height: 4),
                        const Text('Special One Piece — Double XP !', style: TextStyle(
                          fontSize: 12, color: OtakuColors.textSecondary,
                        )),
                        const SizedBox(height: 8),
                        // Connexion quotidienne integree
                        if (_connexionDispo)
                          GestureDetector(
                            onTap: _reclamerConnexion,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: OtakuColors.warning.withValues(alpha: 0.15),
                                border: Border.all(color: OtakuColors.warning),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_fire_department, size: 14, color: OtakuColors.warning),
                                  SizedBox(width: 6),
                                  Text('Connexion quotidienne +15 XP', style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700, color: OtakuColors.warning,
                                  )),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Bouton COMBAT (gros, vertical)
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const CombatSetupPage()));
                _chargerDonnees();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [OtakuColors.accent, OtakuColors.accentDark],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: OtakuColors.accent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, size: 36, color: Colors.black),
                    SizedBox(height: 8),
                    Text('LANCER UN', style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black, letterSpacing: 1,
                    )),
                    Text('COMBAT', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 2,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Rangee de boutons raccourcis en bas (style eFootball)
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: OtakuColors.surface,
        border: Border(top: BorderSide(color: OtakuColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomBtn(
            icon: Icons.today,
            label: 'Defis',
            couleur: OtakuColors.warning,
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsPage()));
              _chargerDonnees();
            },
          ),
          _buildBottomBtn(
            icon: Icons.collections_bookmark,
            label: 'Collection',
            couleur: OtakuColors.accent,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
            },
          ),
          _buildBottomBtn(
            icon: Icons.fitness_center,
            label: 'Solo',
            couleur: OtakuColors.success,
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const CombatSetupPage()));
              _chargerDonnees();
            },
          ),
          _buildBottomBtn(
            icon: Icons.group,
            label: 'Amis',
            couleur: Colors.cyanAccent,
            onTap: null, // V1.5
          ),
          _buildBottomBtn(
            icon: Icons.exit_to_app,
            label: 'Quitter',
            couleur: OtakuColors.error,
            onTap: () => _confirmerQuitter(),
          ),
        ],
      ),
    );
  }

  /// Un bouton carre du bas avec icone + label
  Widget _buildBottomBtn({
    required IconData icon,
    required String label,
    required Color couleur,
    VoidCallback? onTap,
  }) {
    final dispo = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: dispo ? couleur.withValues(alpha: 0.15) : OtakuColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: dispo ? couleur : OtakuColors.border,
                width: dispo ? 2 : 1,
              ),
            ),
            child: Icon(icon, color: dispo ? couleur : OtakuColors.textMuted, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: dispo ? OtakuColors.textPrimary : OtakuColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
