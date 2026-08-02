import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'friends_service.dart';

/// Ecran profil public d'un joueur.
/// Affiche : pseudo, niveau, rang, stats publiques.
/// Bouton "Ajouter en ami" si pas deja ami.
class ProfilPublicPage extends StatefulWidget {
  final String userId;
  final String pseudo;
  final int niveau;
  final String rang;

  const ProfilPublicPage({
    super.key,
    required this.userId,
    required this.pseudo,
    required this.niveau,
    required this.rang,
  });

  @override
  State<ProfilPublicPage> createState() => _ProfilPublicPageState();
}

class _ProfilPublicPageState extends State<ProfilPublicPage> {
  final _friendsService = FriendsService();
  String? _message;
  bool _demandeEnvoyee = false;

  Future<void> _envoyerDemande() async {
    final erreur = await _friendsService.envoyerDemande(widget.userId);
    if (!mounted) return;
    setState(() {
      if (erreur != null) {
        _message = erreur;
      } else {
        _message = 'Demande envoyee !';
        _demandeEnvoyee = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              // Header avec bouton retour
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
                  const SizedBox(width: 16),
                  Text('PROFIL JOUEUR', style: OtakuTypo.headlineLarge.copyWith(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 24),

              // Avatar + pseudo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OtakuColors.surface,
                  border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.5), width: 2),
                ),
                child: Icon(Icons.person, size: 36, color: OtakuColors.accent.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 12),
              Text('@${widget.pseudo}', style: OtakuTypo.headlineLarge.copyWith(fontSize: 20)),
              const SizedBox(height: 6),
              // Rang
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: OtakuColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  widget.rang.toUpperCase(),
                  style: OtakuTypo.label.copyWith(color: OtakuColors.accent, fontSize: 11),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Niveau ${widget.niveau}',
                style: OtakuTypo.hud.copyWith(fontSize: 14, color: OtakuColors.textMuted),
              ),
              const SizedBox(height: 24),

              // Bouton ajouter en ami
              if (!_demandeEnvoyee)
                GestureDetector(
                  onTap: _envoyerDemande,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: OtakuColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add_rounded, size: 18, color: OtakuColors.accent),
                        const SizedBox(width: 10),
                        Text('AJOUTER EN AMI', style: OtakuTypo.label.copyWith(color: OtakuColors.accent)),
                      ],
                    ),
                  ),
                ),

              // Message feedback
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  style: OtakuTypo.bodySmall.copyWith(
                    color: _demandeEnvoyee ? OtakuColors.pvHaut : OtakuColors.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
