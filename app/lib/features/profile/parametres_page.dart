import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../social/friends_service.dart';

/// Ecran Parametres — accessible depuis le profil.
/// Regroupe : pseudo, pays, deconnexion, et futurs reglages.
class ParametresPage extends StatefulWidget {
  final Map<String, dynamic>? profil;
  final VoidCallback onProfilChange;

  const ParametresPage({super.key, required this.profil, required this.onProfilChange});

  @override
  State<ParametresPage> createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage> {
  String? _message;

  static const List<String> _pays = [
    'Senegal', 'France', 'Cote d\'Ivoire', 'Cameroun', 'Mali',
    'Guinee', 'Burkina Faso', 'Congo', 'Gabon', 'Togo',
    'Benin', 'Niger', 'Mauritanie', 'Maroc', 'Algerie',
    'Tunisie', 'Belgique', 'Canada', 'Suisse', 'Haiti',
    'Madagascar', 'Comores', 'RDC', 'Tchad', 'Centrafrique',
    'Autre',
  ];

  @override
  Widget build(BuildContext context) {
    final pseudo = widget.profil?['pseudo'];
    final country = widget.profil?['country'];
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: OtakuColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: OtakuColors.textPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('PARAMETRES', style: OtakuTypo.headlineLarge.copyWith(fontSize: 20)),
                ],
              ),
              const SizedBox(height: 20),

              // Message feedback
              if (_message != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: OtakuColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_message!, style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.accent)),
                ),

              // Liste des parametres
              Expanded(
                child: ListView(
                  children: [
                    // Section Compte & Identite
                    _buildSectionTitle('COMPTE & IDENTITE'),
                    const SizedBox(height: 8),

                    _buildItem(
                      icon: Icons.alternate_email_rounded,
                      label: 'Pseudo',
                      value: pseudo != null ? '@$pseudo' : 'Non defini',
                      onTap: () => _modifierPseudo(pseudo),
                    ),
                    const SizedBox(height: 8),

                    _buildItem(
                      icon: Icons.flag_rounded,
                      label: 'Pays',
                      value: country ?? 'Non defini',
                      onTap: country == null ? _choisirPays : null,
                      trailing: country != null
                          ? Text('Non modifiable', style: OtakuTypo.label.copyWith(fontSize: 8, color: OtakuColors.textMuted))
                          : null,
                    ),
                    const SizedBox(height: 8),

                    _buildItem(
                      icon: Icons.email_rounded,
                      label: 'Email',
                      value: email,
                    ),
                    const SizedBox(height: 20),

                    // Section Graphismes
                    _buildSectionTitle('GRAPHISMES & PERFORMANCE'),
                    const SizedBox(height: 8),

                    _buildItem(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Qualite Liquid Glass',
                      value: 'Haute (actif)',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: OtakuColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('HD', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.accent)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildItem(
                      icon: Icons.speed_rounded,
                      label: 'Frequence affichage',
                      value: '60 FPS',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: OtakuColors.modeEvent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('60', style: OtakuTypo.hud.copyWith(fontSize: 10, color: OtakuColors.modeEvent)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Audio
                    _buildSectionTitle('AUDIO & SON'),
                    const SizedBox(height: 8),

                    _buildItem(
                      icon: Icons.music_note_rounded,
                      label: 'Musique',
                      value: 'Active',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: OtakuColors.pvHaut.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('ON', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.pvHaut)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildItem(
                      icon: Icons.volume_up_rounded,
                      label: 'Effets sonores (SFX)',
                      value: 'Actifs',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: OtakuColors.pvHaut.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('ON', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.pvHaut)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Session
                    _buildSectionTitle('SESSION'),
                    const SizedBox(height: 8),

                    _buildItem(
                      icon: Icons.logout_rounded,
                      label: 'Deconnexion',
                      value: 'Se deconnecter du compte',
                      couleur: OtakuColors.error,
                      onTap: () => _deconnexion(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.textMuted));
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required String value,
    Color couleur = OtakuColors.textPrimary,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: OtakuColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OtakuColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: couleur.withValues(alpha: 0.7)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(value, style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: couleur)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              Icon(Icons.chevron_right_rounded, size: 18, color: OtakuColors.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _modifierPseudo(String? currentPseudo) async {
    final controller = TextEditingController(text: currentPseudo ?? '');
    String? erreur;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: OtakuColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('CHANGER DE PSEUDO', style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: OtakuColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Nouveau_Pseudo',
                  prefixText: '@ ',
                  prefixStyle: TextStyle(color: OtakuColors.accent.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: OtakuColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
              const SizedBox(height: 6),
              Text('3-20 caracteres, lettres/chiffres/underscore', style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('ANNULER', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted))),
            ElevatedButton(
              onPressed: () async {
                final pseudo = controller.text.trim();
                if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(pseudo)) {
                  setDialogState(() => erreur = '3-20 caracteres (lettres, chiffres, _)');
                  return;
                }
                final res = await FriendsService().changerPseudo(pseudo);
                if (res != null) {
                  setDialogState(() => erreur = res);
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

    if (result != null) {
      setState(() => _message = 'Pseudo change en @$result');
      widget.onProfilChange();
    }
  }

  Future<void> _choisirPays() async {
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
            itemCount: _pays.length,
            itemBuilder: (_, i) => ListTile(
              dense: true,
              title: Text(_pays[i], style: const TextStyle(color: OtakuColors.textPrimary)),
              onTap: () => Navigator.pop(context, _pays[i]),
            ),
          ),
        ),
      ),
    );

    if (choix == null) return;

    // Confirmer
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OtakuColors.background,
        title: Text('Confirmer : $choix ?', style: OtakuTypo.headlineLarge.copyWith(fontSize: 15)),
        content: Text('Le pays ne peut pas etre change apres.', style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ANNULER', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('CONFIRMER')),
        ],
      ),
    );

    if (confirme != true) return;

    await Supabase.instance.client.from('profiles').update({
      'country': choix,
    }).eq('id', Supabase.instance.client.auth.currentUser!.id);

    setState(() => _message = 'Pays defini : $choix');
    widget.onProfilChange();
  }

  Future<void> _deconnexion() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
