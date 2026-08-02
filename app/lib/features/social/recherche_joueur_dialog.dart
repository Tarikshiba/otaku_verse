import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'friends_service.dart';

/// Dialogue de recherche de joueur pour envoyer une demande d'ami.
/// S'affiche quand on appuie sur "AJOUTER" dans l'ecran Amis.
class RechercheJoueurDialog extends StatefulWidget {
  final VoidCallback onDemandeEnvoyee;

  const RechercheJoueurDialog({super.key, required this.onDemandeEnvoyee});

  @override
  State<RechercheJoueurDialog> createState() => _RechercheJoueurDialogState();
}

class _RechercheJoueurDialogState extends State<RechercheJoueurDialog> {
  final _controller = TextEditingController();
  final _friendsService = FriendsService();

  List<Map<String, dynamic>> _resultats = [];
  bool _recherche = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Lance la recherche quand le texte change
  Future<void> _chercher(String query) async {
    if (query.length < 2) {
      setState(() => _resultats = []);
      return;
    }

    setState(() => _recherche = true);
    try {
      final resultats = await _friendsService.rechercherJoueur(query);
      if (mounted) setState(() => _resultats = resultats);
    } catch (_) {}
    if (mounted) setState(() => _recherche = false);
  }

  /// Envoie une demande d'ami
  Future<void> _envoyer(String userId, String pseudo) async {
    final erreur = await _friendsService.envoyerDemande(userId);
    if (!mounted) return;

    if (erreur != null) {
      setState(() => _message = erreur);
    } else {
      setState(() => _message = 'Demande envoyee a $pseudo !');
      widget.onDemandeEnvoyee();
    }

    // Effacer le message apres 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _message = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: OtakuColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text('AJOUTER UN AMI', style: OtakuTypo.headlineLarge.copyWith(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              'Cherche par pseudo',
              style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted),
            ),
            const SizedBox(height: 16),

            // Champ de recherche
            TextField(
              controller: _controller,
              onChanged: _chercher,
              autofocus: true,
              style: const TextStyle(color: OtakuColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Pseudo...',
                hintStyle: const TextStyle(color: OtakuColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: OtakuColors.textMuted, size: 20),
                filled: true,
                fillColor: OtakuColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: OtakuColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: OtakuColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: OtakuColors.accent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Message (succes ou erreur)
            if (_message != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: OtakuColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.accent),
                ),
              ),

            // Resultats de recherche
            if (_recherche)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: OtakuColors.accent, strokeWidth: 2)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _resultats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: OtakuColors.border),
                  itemBuilder: (_, i) {
                    final joueur = _resultats[i];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: OtakuColors.surface,
                          border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.4)),
                        ),
                        child: Icon(Icons.person, size: 16, color: OtakuColors.accent.withValues(alpha: 0.7)),
                      ),
                      title: Text(
                        joueur['pseudo'] ?? '???',
                        style: OtakuTypo.headlineSmall.copyWith(fontSize: 13),
                      ),
                      subtitle: Text(
                        'Nv.${joueur['niveau']} · ${joueur['rang']}',
                        style: OtakuTypo.bodySmall.copyWith(fontSize: 10),
                      ),
                      trailing: GestureDetector(
                        onTap: () => _envoyer(joueur['id'], joueur['pseudo'] ?? ''),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: OtakuColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.person_add_rounded, size: 16, color: OtakuColors.accent),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),
            // Bouton fermer
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('FERMER', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
