import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../shared/audio_manager.dart';
import '../auth/auth_service.dart';
import '../skins/skin_3d_cache_service.dart';
import '../social/friends_service.dart';
import '../tutorial/tutorial_service.dart';
import 'legal_pages.dart';

/// Ecran Parametres V9.2 :
/// Pseudo, Pays, Garde-fous Vie Privee (UI-05), Notifications Depassement Ami (RANK-02), Audio et Deconnexion.
class ParametresPage extends StatefulWidget {
  final Map<String, dynamic>? profil;
  final VoidCallback onProfilChange;

  const ParametresPage({super.key, required this.profil, required this.onProfilChange});

  @override
  State<ParametresPage> createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage> {
  String? _message;
  late bool _allowSharePseudoFriends;
  late bool _notifOvertakeEnabled;
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _cache3DMo = 0;

  static const List<String> _pays = [
    'Senegal', 'France', 'Cote d\'Ivoire', 'Cameroun', 'Mali',
    'Guinee', 'Burkina Faso', 'Congo', 'Gabon', 'Togo',
    'Benin', 'Niger', 'Mauritanie', 'Maroc', 'Algerie',
    'Tunisie', 'Belgique', 'Canada', 'Suisse', 'Haiti',
    'Madagascar', 'Comores', 'RDC', 'Tchad', 'Centrafrique',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _allowSharePseudoFriends = widget.profil?['allow_share_pseudo_friends'] == true;
    _notifOvertakeEnabled = widget.profil?['notif_overtake_enabled'] != false;
    _chargerAudioEtCache();
  }

  Future<void> _chargerAudioEtCache() async {
    await OtakuAudioManager.instance.chargerPreferences();
    final cacheMo = await Skin3DCacheService.instance.tailleCacheMo();
    if (!mounted) return;
    setState(() {
      _musicEnabled = OtakuAudioManager.instance.musicEnabled;
      _sfxEnabled = OtakuAudioManager.instance.sfxEnabled;
      _cache3DMo = cacheMo;
    });
  }

  Future<void> _sauvegarderPreferencesViePrivee() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final tzOffset = DateTime.now().timeZoneOffset.inMinutes;
    try {
      await Supabase.instance.client.from('profiles').update({
        'allow_share_pseudo_friends': _allowSharePseudoFriends,
        'notif_overtake_enabled': _notifOvertakeEnabled,
        'timezone_offset_minutes': tzOffset,
      }).eq('id', uid);
      if (!mounted) return;
      setState(() => _message = 'Preferences vie privee et notifications enregistrees.');
      widget.onProfilChange();
    } catch (_) {}
  }

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
              const SizedBox(height: 16),

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

              Expanded(
                child: ListView(
                  children: [
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
                    _buildItem(icon: Icons.email_rounded, label: 'Email', value: email),
                    const SizedBox(height: 18),

                    // Section Vie Privee & Notifications V9.2 (UI-05 & RANK-02)
                    _buildSectionTitle('VIE PRIVEE & NOTIFICATIONS (V9.2)'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OtakuColors.border),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: OtakuColors.accent,
                        title: Text(
                          'Autoriser l\'affichage de mon pseudo sur les cartes de partage d\'amis',
                          style: OtakuTypo.headlineSmall.copyWith(fontSize: 12),
                        ),
                        subtitle: Text(
                          'Desactive par defaut (anonymisation automatique sur les cartes 9:16).',
                          style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                        ),
                        value: _allowSharePseudoFriends,
                        onChanged: (v) {
                          setState(() => _allowSharePseudoFriends = v);
                          _sauvegarderPreferencesViePrivee();
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OtakuColors.border),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: OtakuColors.accent,
                        title: Text(
                          'Notification "Un ami t\'a depasse au classement"',
                          style: OtakuTypo.headlineSmall.copyWith(fontSize: 12),
                        ),
                        subtitle: Text(
                          'Plafonnee a 1x/24h par ami, max 2/jour global et silence garanti de 22h a 08h.',
                          style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                        ),
                        value: _notifOvertakeEnabled,
                        onChanged: (v) {
                          setState(() => _notifOvertakeEnabled = v);
                          _sauvegarderPreferencesViePrivee();
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildSectionTitle('GRAPHISMES, 3D & AUDIO'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OtakuColors.border),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: OtakuColors.accent,
                        title: Text('Musiques d\'ambiance (Lobby & Combat)', style: OtakuTypo.headlineSmall.copyWith(fontSize: 12)),
                        value: _musicEnabled,
                        onChanged: (v) async {
                          setState(() => _musicEnabled = v);
                          await OtakuAudioManager.instance.setMusicEnabled(v);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OtakuColors.border),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: OtakuColors.accent,
                        title: Text('Effets sonores (Haya!!, Combo, K.O.)', style: OtakuTypo.headlineSmall.copyWith(fontSize: 12)),
                        value: _sfxEnabled,
                        onChanged: (v) async {
                          setState(() => _sfxEnabled = v);
                          await OtakuAudioManager.instance.setSfxEnabled(v);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildItem(
                      icon: Icons.view_in_ar_rounded,
                      label: 'Cache local modèles 3D (.glb)',
                      value: '${_cache3DMo.toStringAsFixed(1)} Mo téléchargés à la demande',
                      onTap: () async {
                        await Skin3DCacheService.instance.viderCache3D();
                        final mo = await Skin3DCacheService.instance.tailleCacheMo();
                        if (!mounted) return;
                        setState(() {
                          _cache3DMo = mo;
                          _message = 'Cache des modèles 3D vidé.';
                        });
                      },
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: OtakuColors.accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('VIDER', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.accent)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildSectionTitle('SUPPORT & LÉGAL (STORES)'),
                    const SizedBox(height: 8),
                    _buildItem(
                      icon: Icons.privacy_tip_rounded,
                      label: 'Politique de Confidentialité',
                      value: 'Données collectées, anonymisation et droits',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LegalDocumentPage(isPrivacyPolicy: true)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildItem(
                      icon: Icons.description_rounded,
                      label: 'Conditions Générales d\'Utilisation (CGU)',
                      value: 'Règles d\'équité, monnaies et propriété',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LegalDocumentPage(isPrivacyPolicy: false)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildItem(
                      icon: Icons.support_agent_rounded,
                      label: 'Support & Contact',
                      value: LegalDocumentPage.supportEmail,
                      onTap: _afficherModalSupport,
                    ),
                    const SizedBox(height: 18),

                    _buildSectionTitle('SESSION & COMPTE'),
                    const SizedBox(height: 8),
                    _buildItem(
                      icon: Icons.logout_rounded,
                      label: 'Déconnexion',
                      value: 'Se déconnecter du compte',
                      couleur: OtakuColors.error,
                      onTap: _deconnexion,
                    ),
                    const SizedBox(height: 8),
                    _buildItem(
                      icon: Icons.delete_forever_rounded,
                      label: 'Supprimer définitivement mon compte',
                      value: 'Efface ton profil, tes stats et tes données (irréversible)',
                      couleur: OtakuColors.error,
                      onTap: _confirmerSuppressionCompte,
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
            ?trailing,
            if (onTap != null && trailing == null)
              const Icon(Icons.chevron_right_rounded, size: 18, color: OtakuColors.textMuted),
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
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
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
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text('ANNULER', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted))),
            ElevatedButton(
              onPressed: () async {
                final pseudo = controller.text.trim();
                if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(pseudo)) {
                  setDialogState(() => erreur = '3-20 caracteres (lettres, chiffres, _)');
                  return;
                }
                final res = await FriendsService().changerPseudo(pseudo);
                if (!dialogCtx.mounted) return;
                if (res != null) {
                  setDialogState(() => erreur = res);
                } else {
                  Navigator.pop(dialogCtx, pseudo);
                }
              },
              child: const Text('VALIDER'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _message = 'Pseudo change en @$result');
      widget.onProfilChange();
    }
  }

  Future<void> _choisirPays() async {
    final choix = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
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
              onTap: () => Navigator.pop(dialogCtx, _pays[i]),
            ),
          ),
        ),
      ),
    );

    if (choix == null || !mounted) return;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: OtakuColors.background,
        title: Text('Confirmer : $choix ?', style: OtakuTypo.headlineLarge.copyWith(fontSize: 15)),
        content: Text('Le pays ne peut pas etre change apres.', style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text('ANNULER', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted))),
          ElevatedButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('CONFIRMER')),
        ],
      ),
    );

    if (confirme == true) {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        await Supabase.instance.client.from('profiles').update({'country': choix}).eq('id', uid);
        if (mounted) {
          setState(() => _message = 'Pays enregistre : $choix');
          widget.onProfilChange();
        }
      }
    }
  }

  void _afficherModalSupport() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OtakuColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('SUPPORT OTAKU VERSE', style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.accent)),
        content: Text(
          'Un bug, une question sur ton compte ou une suggestion ?\n\nÉcris-nous à : ${LegalDocumentPage.supportEmail}\n\nPour signaler une question de quiz erronée, utilise directement le bouton « Signaler » après ta réponse en combat.',
          style: OtakuTypo.bodySmall.copyWith(color: Colors.white70, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('FERMER'),
          ),
        ],
      ),
    );
  }

  /// Suppression definitive du compte in-app (Obligatoire Google Play & Apple — Phase C1)
  Future<void> _confirmerSuppressionCompte() async {
    final confirmCtrl = TextEditingController();
    String? erreur;
    bool enCours = false;

    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: OtakuColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: OtakuColors.error.withValues(alpha: 0.7)),
          ),
          title: Text(
            'SUPPRIMER DÉFINITIVEMENT MON COMPTE',
            style: OtakuTypo.headlineSmall.copyWith(fontSize: 13.5, color: OtakuColors.error),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cette action est irréversible. Ton profil, ton niveau, tes classements, tes skins et tes soldes OC/VC seront définitivement effacés.',
                style: OtakuTypo.bodySmall.copyWith(fontSize: 11, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 10),
              Text(
                'Tape SUPPRIMER ci-dessous pour confirmer :',
                style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.error),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: confirmCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'SUPPRIMER',
                  hintStyle: const TextStyle(color: OtakuColors.textMuted),
                  filled: true,
                  fillColor: OtakuColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (erreur != null) ...[
                const SizedBox(height: 8),
                Text(erreur!, style: const TextStyle(color: OtakuColors.error, fontSize: 11)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: enCours ? null : () => Navigator.pop(dialogCtx, false),
              child: Text('ANNULER', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.error, foregroundColor: Colors.white),
              onPressed: enCours
                  ? null
                  : () async {
                      if (confirmCtrl.text.trim().toUpperCase() != 'SUPPRIMER') {
                        setDlgState(() => erreur = 'Tape exactement SUPPRIMER pour continuer.');
                        return;
                      }
                      setDlgState(() {
                        enCours = true;
                        erreur = null;
                      });
                      try {
                        final res = await Supabase.instance.client.functions.invoke(
                          'shop-tutorial-engine',
                          body: {'action': 'delete_account', 'confirm': 'SUPPRIMER'},
                        );
                        final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
                        if (res.status >= 400 || data['error'] != null) {
                          setDlgState(() {
                            enCours = false;
                            erreur = data['error']?.toString() ?? 'Suppression impossible.';
                          });
                          return;
                        }
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
                      } on FunctionException catch (e) {
                        final details = e.details is Map ? Map<String, dynamic>.from(e.details as Map) : <String, dynamic>{};
                        setDlgState(() {
                          enCours = false;
                          erreur = details['error']?.toString() ?? 'Erreur serveur (${e.status}).';
                        });
                      } catch (e) {
                        setDlgState(() {
                          enCours = false;
                          erreur = e.toString().replaceAll('Exception: ', '');
                        });
                      }
                    },
              child: enCours
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('SUPPRIMER', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );

    if (deleted == true) {
      await TutorialService().resetLocalStateOnLogout();
      await AuthService().deconnexion();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _deconnexion() async {
    await AuthService().deconnexion();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
