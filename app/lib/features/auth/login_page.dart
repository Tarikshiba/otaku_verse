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

  static final RegExp _emailRegex = RegExp(r'^[\w\.\-\+]+@([\w\-]+\.)+[\w\-]{2,}$');

  Future<void> _seConnecter() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _motDePasseController.text.isEmpty) {
      setState(() => _erreur = 'Remplis ton email et ton mot de passe.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _erreur = 'Adresse email invalide (ex. pseudo@domaine.com).');
      return;
    }

    setState(() {
      _chargement = true;
      _erreur = null;
    });

    final erreur = await _authService.connexion(
      email,
      _motDePasseController.text,
    );

    if (!mounted) return;
    setState(() => _chargement = false);

    if (erreur != null) {
      setState(() => _erreur = erreur);
    }
  }

  /// Fenetre "Mot de passe oublie" (Test 3)
  Future<void> _ouvrirMotDePasseOublie() async {
    final resetController = TextEditingController(text: _emailController.text.trim());
    String? feedback;
    bool envoi = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: OtakuColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('MOT DE PASSE OUBLIÉ', style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.accent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saisis l\'adresse email de ton compte pour recevoir un lien de réinitialisation.',
                style: OtakuTypo.bodySmall,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: resetController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: OtakuColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'ton@email.com',
                  filled: true,
                  fillColor: OtakuColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (feedback != null) ...[
                const SizedBox(height: 8),
                Text(feedback!, style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.accent)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('FERMER', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: envoi
                  ? null
                  : () async {
                      final mail = resetController.text.trim();
                      if (!_emailRegex.hasMatch(mail)) {
                        setDialogState(() => feedback = 'Entre une adresse email valide.');
                        return;
                      }
                      setDialogState(() => envoi = true);
                      final err = await _authService.reinitialiserMotDePasse(mail);
                      setDialogState(() {
                        envoi = false;
                        feedback = err ?? 'Lien envoyé ! Vérifie ta boîte mail (et tes spams).';
                      });
                    },
              child: Text(envoi ? 'ENVOI...' : 'ENVOYER LE LIEN'),
            ),
          ],
        ),
      ),
    );
    resetController.dispose();
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
              Center(
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _ouvrirMotDePasseOublie,
                  child: Text(
                    'Mot de passe oublié ?',
                    style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.accent, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

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
