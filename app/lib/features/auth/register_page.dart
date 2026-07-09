import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'auth_service.dart';

/// Ecran d'inscription (email + mot de passe + confirmation).
/// onBasculeConnexion : callback pour revenir a l'ecran connexion
class RegisterPage extends StatefulWidget {
  final VoidCallback onBasculeConnexion;

  const RegisterPage({super.key, required this.onBasculeConnexion});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  bool _chargement = false;
  String? _erreur;

  @override
  void dispose() {
    _emailController.dispose();
    _motDePasseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sInscrire() async {
    final email = _emailController.text.trim();
    final mdp = _motDePasseController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || mdp.isEmpty || confirm.isEmpty) {
      setState(() => _erreur = 'Remplis tous les champs');
      return;
    }
    if (mdp.length < 6) {
      setState(() => _erreur = 'Le mot de passe doit faire au moins 6 caracteres');
      return;
    }
    if (mdp != confirm) {
      setState(() => _erreur = 'Les mots de passe ne correspondent pas');
      return;
    }

    setState(() {
      _chargement = true;
      _erreur = null;
    });

    final erreur = await _authService.inscription(email, mdp);

    if (!mounted) return;
    setState(() => _chargement = false);

    if (erreur != null) {
      setState(() => _erreur = erreur);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Center(
                child: Text('OTAKU VERSE', style: OtakuTypo.displayLarge),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'INSCRIPTION',
                  style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted),
                ),
              ),
              const SizedBox(height: 48),

              _buildTextField(
                controller: _emailController,
                label: 'EMAIL',
                hint: 'ton@email.com',
                clavier: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _motDePasseController,
                label: 'MOT DE PASSE',
                hint: 'Minimum 6 caracteres',
                obscure: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _confirmController,
                label: 'CONFIRMER LE MOT DE PASSE',
                hint: '••••••••',
                obscure: true,
              ),
              const SizedBox(height: 24),

              if (_erreur != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: OtakuColors.error),
                    borderRadius: BorderRadius.circular(2),
                    color: OtakuColors.error.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    _erreur!,
                    style: const TextStyle(color: OtakuColors.error, fontSize: 13),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _chargement ? null : _sInscrire,
                  child: _chargement
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('CREER MON COMPTE'),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: GestureDetector(
                  onTap: widget.onBasculeConnexion,
                  child: RichText(
                    text: TextSpan(
                      text: 'Deja un compte ? ',
                      style: OtakuTypo.bodySmall,
                      children: [
                        TextSpan(
                          text: 'Connexion',
                          style: OtakuTypo.bodySmall.copyWith(
                            color: OtakuColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscure = false,
    TextInputType clavier = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: clavier,
          style: const TextStyle(color: OtakuColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: OtakuColors.textMuted),
            filled: true,
            fillColor: OtakuColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: OtakuColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: OtakuColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: OtakuColors.accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
