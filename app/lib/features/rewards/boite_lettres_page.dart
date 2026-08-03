import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'mailbox_service.dart';

/// Ecran Boite a lettres — affiche les recompenses depuis Supabase.
/// L'utilisateur peut reclamer ses rewards un par un ou tous d'un coup.
class BoiteLettresPage extends StatefulWidget {
  const BoiteLettresPage({super.key});

  @override
  State<BoiteLettresPage> createState() => _BoiteLettresPageState();
}

class _BoiteLettresPageState extends State<BoiteLettresPage> {
  final _mailboxService = MailboxService();
  List<MailboxItem> _items = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      // Verifier et ajouter le daily login si pas fait aujourd'hui
      await _mailboxService.verifierDailyLogin();
      final items = await _mailboxService.mesRecompenses();
      if (mounted) setState(() { _items = items; _chargement = false; });
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _recuperer(MailboxItem item) async {
    await _mailboxService.reclamer(item.id);
    _charger();
  }

  Future<void> _recupererTout() async {
    await _mailboxService.reclamerTout();
    _charger();
  }

  int get _enAttente => _items.where((i) => !i.claimed).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                      child: const Icon(Icons.arrow_back_rounded, color: OtakuColors.textPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('BOITE A LETTRES', style: OtakuTypo.headlineLarge.copyWith(fontSize: 18)),
                  const SizedBox(width: 10),
                  if (_enAttente > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: OtakuColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$_enAttente', style: OtakuTypo.hud.copyWith(fontSize: 11, color: OtakuColors.error)),
                    ),
                  const Spacer(),
                  if (_enAttente > 0)
                    GestureDetector(
                      onTap: _recupererTout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: OtakuColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.4)),
                        ),
                        child: Text('TOUT RECUPERER', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.accent)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Contenu
              Expanded(
                child: _chargement
                    ? const Center(child: CircularProgressIndicator(color: OtakuColors.accent))
                    : _items.isEmpty
                        ? Center(child: Text('Aucune recompense', style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted)))
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _buildRewardCard(_items[i]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard(MailboxItem item) {
    final couleur = _couleurType(item.type);
    final icon = _iconType(item.type);

    return LiquidGlass(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      tintColor: item.claimed ? null : couleur,
      child: Row(
        children: [
          // Icone
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: couleur.withValues(alpha: item.claimed ? 0.05 : 0.15),
              border: Border.all(color: couleur.withValues(alpha: item.claimed ? 0.1 : 0.4)),
            ),
            child: Icon(icon, size: 18, color: couleur.withValues(alpha: item.claimed ? 0.4 : 1.0)),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.titre,
                  style: OtakuTypo.headlineSmall.copyWith(
                    fontSize: 12,
                    color: item.claimed ? OtakuColors.textMuted : OtakuColors.textPrimary,
                  ),
                ),
                Text(
                  item.description,
                  style: OtakuTypo.bodySmall.copyWith(
                    fontSize: 10,
                    color: item.claimed ? OtakuColors.textMuted : OtakuColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Bouton recuperer ou check
          if (!item.claimed)
            GestureDetector(
              onTap: () => _recuperer(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: couleur.withValues(alpha: 0.5)),
                ),
                child: Text('RECUPERER', style: OtakuTypo.label.copyWith(fontSize: 9, color: couleur)),
              ),
            )
          else
            Icon(Icons.check_circle_rounded, size: 18, color: OtakuColors.pvHaut.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Color _couleurType(String type) {
    switch (type) {
      case 'daily_login': return OtakuColors.accent;
      case 'combat_win': return OtakuColors.modeEvent;
      case 'quest_complete': return OtakuColors.pvHaut;
      case 'badge': return OtakuColors.modeDuel;
      default: return OtakuColors.victoire;
    }
  }

  IconData _iconType(String type) {
    switch (type) {
      case 'daily_login': return Icons.calendar_today_rounded;
      case 'combat_win': return Icons.emoji_events_rounded;
      case 'quest_complete': return Icons.task_alt_rounded;
      case 'badge': return Icons.military_tech_rounded;
      default: return Icons.card_giftcard_rounded;
    }
  }
}
