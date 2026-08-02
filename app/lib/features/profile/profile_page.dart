import 'package:flutter/material.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../progression/progression_service.dart';
import '../skins/boutique_screen.dart';
import '../social/friends_service.dart';

/// === ECRAN PROFIL — DA V2.1 ===
/// Capsule verre pour le skin, stats en cartes Liquid Glass,
/// typo HUD, texture seigaiha en fond (gere par AppShell).

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProgressionService _progressionService = ProgressionService();

  Map<String, dynamic>? _profil;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  Future<void> _chargerProfil() async {
    try {
      await _progressionService.creerProfilSiAbsent();
      final profil = await _progressionService.recupererProfil();
      if (!mounted) return;
      setState(() {
        _profil = profil;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  /// Popup pour changer ou definir son pseudo
  Future<void> _modifierPseudo() async {
    final controller = TextEditingController(
      text: _profil?['pseudo'] ?? '',
    );
    String? erreur;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: OtakuColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            _profil?['pseudo'] != null ? 'CHANGER DE PSEUDO' : 'CHOISIS TON PSEUDO',
            style: OtakuTypo.headlineLarge.copyWith(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ton pseudo est ton @, visible par tous.',
                style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: OtakuColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ton_Pseudo',
                  hintStyle: const TextStyle(color: OtakuColors.textMuted),
                  prefixText: '@ ',
                  prefixStyle: TextStyle(color: OtakuColors.accent.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: OtakuColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: OtakuColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: OtakuColors.accent, width: 1.5),
                  ),
                ),
              ),
              if (erreur != null) ...[
                const SizedBox(height: 8),
                Text(erreur!, style: const TextStyle(color: OtakuColors.error, fontSize: 12)),
              ],
              const SizedBox(height: 8),
              Text(
                '3-20 caracteres, lettres/chiffres/underscore',
                style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ANNULER', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final pseudo = controller.text.trim();
                final regex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
                if (!regex.hasMatch(pseudo)) {
                  setDialogState(() => erreur = '3-20 caracteres (lettres, chiffres, _)');
                  return;
                }
                // Verifier dispo et sauvegarder
                final result = await FriendsService().changerPseudo(pseudo);
                if (result != null) {
                  setDialogState(() => erreur = result);
                } else {
                  Navigator.pop(context, pseudo);
                }
              },
              child: const Text('VALIDER'),
            ),
          ],
        ),
      ),
    );

    // Si le pseudo a ete change, recharger le profil
    if (result != null) {
      _chargerProfil();
    }
  }

  /// Popup pour choisir son pays (une seule fois, non modifiable)
  Future<void> _choisirPays() async {
    const pays = [
      'Senegal', 'France', 'Cote d\'Ivoire', 'Cameroun', 'Mali',
      'Guinee', 'Burkina Faso', 'Congo', 'Gabon', 'Togo',
      'Benin', 'Niger', 'Mauritanie', 'Maroc', 'Algerie',
      'Tunisie', 'Belgique', 'Canada', 'Suisse', 'Haiti',
      'Madagascar', 'Comores', 'RDC', 'Tchad', 'Centrafrique',
      'Autre',
    ];

    final choix = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OtakuColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('CHOISIS TON PAYS', style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: pays.length,
            itemBuilder: (_, i) => ListTile(
              dense: true,
              title: Text(pays[i], style: const TextStyle(color: OtakuColors.textPrimary)),
              onTap: () => Navigator.pop(context, pays[i]),
            ),
          ),
        ),
      ),
    );

    if (choix == null) return;

    // Confirmer (non modifiable)
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OtakuColors.background,
        title: Text('Confirmer : $choix ?', style: OtakuTypo.headlineLarge.copyWith(fontSize: 15)),
        content: Text(
          'Attention : le pays ne peut pas etre change apres.',
          style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ANNULER', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    // Sauvegarder dans Supabase
    await Supabase.instance.client.from('profiles').update({
      'country': choix,
    }).eq('id', Supabase.instance.client.auth.currentUser!.id);

    _chargerProfil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: _chargement
            ? const Center(child: CircularProgressIndicator())
            : _buildContenu(),
      ),
    );
  }

  Widget _buildContenu() {
    final xpTotale = _profil?['xp_totale'] ?? 0;
    final niveau = _profil?['niveau'] ?? 1;
    final rangActuel = _profil?['rang'] ?? 'Debutant';
    final combatsJoues = _profil?['combats_joues'] ?? 0;
    final combatsGagnes = _profil?['combats_gagnes'] ?? 0;

    final xpDansNiveau = ProgressionService.xpDansNiveauActuel(xpTotale as int);
    final xpPourProchain = ProgressionService.xpRequise(niveau as int);
    final progressionXp = xpPourProchain > 0 ? xpDansNiveau / xpPourProchain : 0.0;

    final tauxVictoire = combatsJoues > 0
        ? ((combatsGagnes / combatsJoues) * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 72),
      child: Row(
        children: [
          // === COLONNE GAUCHE : Capsule verre + skin ===
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: LiquidGlass(
                    tintColor: OtakuColors.accent,
                    borderRadius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Skin rotatif dans la capsule
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BoutiqueScreen()),
                            ),
                            child: const _SkinRotatif(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Bouton collection
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BoutiqueScreen()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: OtakuColors.modeDuel.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: OtakuColors.modeDuel.withValues(alpha: 0.4)),
                            ),
                            child: Text('COLLECTION', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.modeDuel)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Rang
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: OtakuColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            rangActuel.toString().toUpperCase(),
                            style: OtakuTypo.label.copyWith(color: OtakuColors.accent, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // === COLONNE DROITE : Stats ===
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text('PROFIL', style: OtakuTypo.headlineLarge.copyWith(fontSize: 22)),
                    const Spacer(),
                    // Deconnexion
                    GestureDetector(
                      onTap: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (!mounted) return;
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: OtakuColors.error.withValues(alpha: 0.4)),
                        ),
                        child: Text('DECONNEXION', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.error)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Pseudo (@ du joueur — tap pour modifier)
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _modifierPseudo(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _profil?['pseudo'] == null
                              ? OtakuColors.accent.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _profil?['pseudo'] == null
                                ? OtakuColors.accent.withValues(alpha: 0.6)
                                : OtakuColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _profil?['pseudo'] != null
                                  ? '@${_profil!['pseudo']}'
                                  : 'Choisis ton pseudo !',
                              style: OtakuTypo.hud.copyWith(
                                fontSize: 12,
                                color: _profil?['pseudo'] != null
                                    ? OtakuColors.textPrimary
                                    : OtakuColors.accent,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit_rounded,
                              size: 12,
                              color: _profil?['pseudo'] != null
                                  ? OtakuColors.textMuted
                                  : OtakuColors.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Pays (affiche si defini, bouton si pas encore choisi)
                    if (_profil?['country'] == null)
                      GestureDetector(
                        onTap: () => _choisirPays(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: OtakuColors.modeEvent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: OtakuColors.modeEvent.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag_rounded, size: 12, color: OtakuColors.modeEvent),
                              const SizedBox(width: 4),
                              Text('Pays ?', style: OtakuTypo.hud.copyWith(fontSize: 11, color: OtakuColors.modeEvent)),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: OtakuColors.border),
                        ),
                        child: Text(
                          _profil!['country'],
                          style: OtakuTypo.hud.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Niveau + barre XP
                LiquidGlass(
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Text('Nv.$niveau', style: OtakuTypo.hud.copyWith(fontSize: 18, color: OtakuColors.accent)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$xpDansNiveau / $xpPourProchain XP',
                              style: OtakuTypo.hud.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressionXp,
                                minHeight: 6,
                                backgroundColor: OtakuColors.border,
                                valueColor: const AlwaysStoppedAnimation(OtakuColors.accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Stats en grille 2x2
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: _buildStatCard('XP TOTALE', '$xpTotale', OtakuColors.accent)),
                            const SizedBox(height: 8),
                            Expanded(child: _buildStatCard('VICTOIRES', '$combatsGagnes', OtakuColors.victoire)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: _buildStatCard('COMBATS', '$combatsJoues', OtakuColors.modeDuel)),
                            const SizedBox(height: 8),
                            Expanded(child: _buildStatCard('TAUX', '$tauxVictoire%', OtakuColors.pvMoyen)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String valeur, Color couleur) {
    return LiquidGlass(
      borderRadius: 12,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.textMuted)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(valeur, style: OtakuTypo.hud.copyWith(fontSize: 18, color: couleur)),
          ),
        ],
      ),
    );
  }
}

/// Skin rotatif — capsule verre, rotation douce + drag
class _SkinRotatif extends StatefulWidget {
  const _SkinRotatif();

  @override
  State<_SkinRotatif> createState() => _SkinRotatifState();
}

class _SkinRotatifState extends State<_SkinRotatif> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotation = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _rotation += details.delta.dx * 0.01;
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _rotation + (_controller.value * 2 * pi);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: child,
          );
        },
        child: Container(
          width: 100,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                OtakuColors.accent.withValues(alpha: 0.15),
                OtakuColors.accentDark.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 50, color: OtakuColors.accent.withValues(alpha: 0.7)),
              const SizedBox(height: 6),
              Text('SKIN V1', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
