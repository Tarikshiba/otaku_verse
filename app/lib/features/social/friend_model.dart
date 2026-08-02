/// Represente un ami dans la liste du joueur.
/// Contient les infos affichees sur la carte ami.
class Friend {
  final String id;          // ID unique de la relation (table friends)
  final String userId;      // ID du joueur ami
  final String pseudo;      // Son pseudo
  final int niveau;         // Son niveau actuel
  final String rang;        // Son rang (Debutant, Passionne, etc.)
  final DateTime lastSeen;  // Derniere activite (pour "en ligne")
  final bool isInCombat;    // En combat ou pas

  Friend({
    required this.id,
    required this.userId,
    required this.pseudo,
    required this.niveau,
    required this.rang,
    required this.lastSeen,
    required this.isInCombat,
  });

  /// Construit un Friend depuis les donnees Supabase (JSON)
  factory Friend.fromJson(Map<String, dynamic> json, {required bool isSender}) {
    // Si je suis le sender, l'ami est le receiver (et vice versa)
    final amiData = isSender ? json['receiver'] : json['sender'];
    return Friend(
      id: json['id'],
      userId: amiData['id'],
      pseudo: amiData['pseudo'] ?? 'Inconnu',
      niveau: amiData['niveau'] ?? 1,
      rang: amiData['rang'] ?? 'Debutant',
      lastSeen: DateTime.parse(amiData['last_seen'] ?? DateTime.now().toIso8601String()),
      isInCombat: amiData['is_in_combat'] ?? false,
    );
  }

  /// "En ligne" si derniere activite < 5 minutes
  bool get estEnLigne {
    final diff = DateTime.now().difference(lastSeen);
    return diff.inMinutes < 5;
  }

  /// Statut affiche dans l'UI
  String get statut {
    if (isInCombat) return 'En combat';
    if (estEnLigne) return 'En ligne';
    return 'Hors ligne';
  }
}

/// Represente une demande d'ami en attente
class FriendRequest {
  final String id;          // ID de la relation
  final String senderId;    // Qui a envoye la demande
  final String pseudo;      // Pseudo de l'envoyeur
  final int niveau;
  final String rang;
  final DateTime createdAt; // Quand la demande a ete envoyee

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.pseudo,
    required this.niveau,
    required this.rang,
    required this.createdAt,
  });

  /// Construit depuis les donnees Supabase
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    return FriendRequest(
      id: json['id'],
      senderId: sender['id'],
      pseudo: sender['pseudo'] ?? 'Inconnu',
      niveau: sender['niveau'] ?? 1,
      rang: sender['rang'] ?? 'Debutant',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
