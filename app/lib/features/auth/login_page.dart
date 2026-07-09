import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'auth_service.dart';

/// Ecran de connexion (email + mot de passe).
/// onBasculeInscription : callback pour passer a l'ecran inscription
class LoginPage extends StatefulWidget {
  final VoidCallback onBasculeInscription;

  const LoginPage({super.key, required this.onBasculeInscription});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final _authService = AuthService();
  bool _chargement = false;
  String? _erreur;

  @override
  void dispose() {
    _emailController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    if (_emailController.text.trim().isEmpty || _motDePasseController.text.isEmpty) {
      setState(() => _erreur = 'Remplis tous les champs');
      return;
    }

    setState(() {
      _chargement = true;
      _erreur = null;
    });

    final erreur = await _authService.connexion(
      _emailController.text.trim(),
      _motDePasseController.text,
    );

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
                  'CONNEXION',
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
                  onPressed: _chargement ? null : _seConnecter,
                  child: _chargement
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('SE CONNECTER'),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: GestureDetector(
                  onTap: widget.onBasculeInscription,
                  child: RichText(
                    text: TextSpan(
                      text: 'Pas encore de compte ? ',
                      style: OtakuTypo.bodySmall,
                      children: [
                        TextSpan(
                          text: 'Inscription',
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
