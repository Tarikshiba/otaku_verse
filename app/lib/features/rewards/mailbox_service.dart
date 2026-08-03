import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour la boite a lettres (mailbox).
/// Chaque recompense est stockee dans la table `mailbox` :
/// - id, user_id, type, titre, description, xp_amount, claimed, created_at
///
/// Types de recompenses : daily_login, combat_win, quest_complete, badge, gift

class MailboxService {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  /// Recuperer toutes les recompenses non reclamees
  Future<List<MailboxItem>> mesRecompenses() async {
    final data = await _supabase
        .from('mailbox')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => MailboxItem.fromJson(e)).toList();
  }

  /// Reclamer une recompense (marquer comme claimed + donner XP)
  Future<void> reclamer(String id) async {
    // Recuperer l'item
    final item = await _supabase
        .from('mailbox')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .single();

    if (item['claimed'] == true) return;

    // Marquer comme reclamee
    await _supabase
        .from('mailbox')
        .update({'claimed': true, 'claimed_at': DateTime.now().toIso8601String()})
        .eq('id', id);

    // Donner l'XP si > 0
    final xp = item['xp_amount'] as int? ?? 0;
    if (xp > 0) {
      await _supabase.rpc('ajouter_xp', params: {
        'p_user_id': _userId,
        'p_xp': xp,
      });
    }
  }

  /// Reclamer toutes les recompenses non reclamees
  Future<void> reclamerTout() async {
    final items = await mesRecompenses();
    final nonReclamees = items.where((i) => !i.claimed);
    for (final item in nonReclamees) {
      await reclamer(item.id);
    }
  }

  /// Nombre de recompenses non reclamees (pour badge notification)
  Future<int> countNonReclamees() async {
    final data = await _supabase
        .from('mailbox')
        .select('id')
        .eq('user_id', _userId)
        .eq('claimed', false);

    return (data as List).length;
  }

  /// Ajouter une recompense dans la boite (appele cote serveur normalement,
  /// mais on peut aussi l'appeler localement pour daily login etc.)
  Future<void> ajouterRecompense({
    required String type,
    required String titre,
    required String description,
    int xpAmount = 0,
  }) async {
    await _supabase.from('mailbox').insert({
      'user_id': _userId,
      'type': type,
      'titre': titre,
      'description': description,
      'xp_amount': xpAmount,
      'claimed': false,
    });
  }

  /// Verifier et ajouter la recompense de connexion quotidienne
  /// (si pas deja ajoutee aujourd'hui)
  Future<void> verifierDailyLogin() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final existing = await _supabase
        .from('mailbox')
        .select('id')
        .eq('user_id', _userId)
        .eq('type', 'daily_login')
        .gte('created_at', '${today}T00:00:00');

    if ((existing as List).isEmpty) {
      await ajouterRecompense(
        type: 'daily_login',
        titre: 'Connexion quotidienne',
        description: '+15 XP — Reviens demain !',
        xpAmount: 15,
      );
    }
  }

  /// Ajouter une recompense de victoire au combat
  Future<void> ajouterVictoireCombat() async {
    await ajouterRecompense(
      type: 'combat_win',
      titre: 'Victoire combat',
      description: '+30 XP — Bien joue !',
      xpAmount: 30,
    );
  }
}

class MailboxItem {
  final String id;
  final String type;
  final String titre;
  final String description;
  final int xpAmount;
  final bool claimed;
  final DateTime createdAt;

  MailboxItem({
    required this.id,
    required this.type,
    required this.titre,
    required this.description,
    required this.xpAmount,
    required this.claimed,
    required this.createdAt,
  });

  factory MailboxItem.fromJson(Map<String, dynamic> json) => MailboxItem(
    id: json['id'],
    type: json['type'] ?? '',
    titre: json['titre'] ?? '',
    description: json['description'] ?? '',
    xpAmount: json['xp_amount'] ?? 0,
    claimed: json['claimed'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
  );
}
