import 'package:supabase_flutter/supabase_flutter.dart';
import 'friend_model.dart';

/// Service qui gere tout le systeme d'amis :
/// recherche, demandes, acceptation, suppression, statut.
class FriendsService {
  final _supabase = Supabase.instance.client;

  /// ID du joueur connecte
  String? get _myId => _supabase.auth.currentUser?.id;

  // ==========================================================
  // RECHERCHE DE JOUEURS
  // ==========================================================

  /// Cherche un joueur par pseudo (recherche partielle, insensible a la casse).
  /// Exclut le joueur connecte des resultats.
  Future<List<Map<String, dynamic>>> rechercherJoueur(String query) async {
    if (query.length < 2) return [];

    final results = await _supabase
        .from('profiles')
        .select('id, pseudo, niveau, rang')
        .neq('id', _myId!)
        .ilike('pseudo', '%$query%')
        .limit(10);

    return List<Map<String, dynamic>>.from(results);
  }

  // ==========================================================
  // DEMANDES D'AMITIE
  // ==========================================================

  /// Envoie une demande d'ami a un joueur (par son ID).
  /// Retourne null si OK, ou un message d'erreur.
  Future<String?> envoyerDemande(String receiverId) async {
    try {
      // Verifier qu'une relation n'existe pas deja (dans les 2 sens)
      final existante = await _supabase
          .from('friends')
          .select('id, status')
          .or('and(sender_id.eq.$_myId,receiver_id.eq.$receiverId),and(sender_id.eq.$receiverId,receiver_id.eq.$_myId)')
          .maybeSingle();

      if (existante != null) {
        final status = existante['status'];
        if (status == 'accepted') return 'Vous etes deja amis';
        if (status == 'pending') return 'Demande deja envoyee';
      }

      await _supabase.from('friends').insert({
        'sender_id': _myId,
        'receiver_id': receiverId,
        'status': 'pending',
      });

      return null;
    } catch (e) {
      return 'Erreur : $e';
    }
  }

  /// Liste les demandes recues en attente (les gens qui veulent etre mon ami)
  Future<List<FriendRequest>> demandesRecues() async {
    final data = await _supabase
        .from('friends')
        .select('id, created_at, sender:sender_id(id, pseudo, niveau, rang)')
        .eq('receiver_id', _myId!)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data)
        .map((json) => FriendRequest.fromJson(json))
        .toList();
  }

  /// Accepter une demande d'ami
  Future<void> accepterDemande(String friendRelationId) async {
    await _supabase
        .from('friends')
        .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', friendRelationId);
  }

  /// Refuser une demande d'ami
  Future<void> refuserDemande(String friendRelationId) async {
    await _supabase
        .from('friends')
        .delete()
        .eq('id', friendRelationId);
  }

  // ==========================================================
  // LISTE D'AMIS
  // ==========================================================

  /// Recupere la liste de tous mes amis (relations acceptees)
  Future<List<Friend>> mesAmis() async {
    // Relations ou je suis sender
    final envoyees = await _supabase
        .from('friends')
        .select('id, status, receiver:receiver_id(id, pseudo, niveau, rang, last_seen, is_in_combat)')
        .eq('sender_id', _myId!)
        .eq('status', 'accepted');

    // Relations ou je suis receiver
    final recues = await _supabase
        .from('friends')
        .select('id, status, sender:sender_id(id, pseudo, niveau, rang, last_seen, is_in_combat)')
        .eq('receiver_id', _myId!)
        .eq('status', 'accepted');

    final amis = <Friend>[];

    for (final json in List<Map<String, dynamic>>.from(envoyees)) {
      amis.add(Friend.fromJson(json, isSender: true));
    }
    for (final json in List<Map<String, dynamic>>.from(recues)) {
      amis.add(Friend.fromJson(json, isSender: false));
    }

    // Trier : en combat d'abord, puis en ligne, puis hors ligne
    amis.sort((a, b) {
      if (a.isInCombat && !b.isInCombat) return -1;
      if (!a.isInCombat && b.isInCombat) return 1;
      if (a.estEnLigne && !b.estEnLigne) return -1;
      if (!a.estEnLigne && b.estEnLigne) return 1;
      return 0;
    });

    return amis;
  }

  /// Supprimer un ami (supprimer la relation)
  Future<void> supprimerAmi(String friendRelationId) async {
    await _supabase
        .from('friends')
        .delete()
        .eq('id', friendRelationId);
  }

  // ==========================================================
  // STATUT EN LIGNE
  // ==========================================================

  /// Met a jour mon "last_seen" (a appeler a chaque ouverture de l'app)
  Future<void> mettreAJourPresence() async {
    if (_myId == null) return;
    await _supabase.from('profiles').update({
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', _myId!);
  }

  /// Signaler que je suis en combat (true) ou que j'ai fini (false)
  Future<void> setEnCombat(bool enCombat) async {
    if (_myId == null) return;
    await _supabase.from('profiles').update({
      'is_in_combat': enCombat,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', _myId!);
  }

  // ==========================================================
  // PSEUDO
  // ==========================================================

  /// Change le pseudo du joueur connecte.
  /// Retourne null si OK, ou un message d'erreur si le pseudo est pris.
  Future<String?> changerPseudo(String nouveauPseudo) async {
    try {
      // Verifier disponibilite
      final pris = await _supabase
          .from('profiles')
          .select('id')
          .eq('pseudo', nouveauPseudo)
          .neq('id', _myId!)
          .maybeSingle();

      if (pris != null) {
        return 'Ce pseudo est deja pris';
      }

      await _supabase.from('profiles').update({
        'pseudo': nouveauPseudo,
      }).eq('id', _myId!);

      return null;
    } catch (e) {
      return 'Erreur : $e';
    }
  }
}
