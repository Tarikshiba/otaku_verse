/// Represente un skin dans la boutique.
class Skin {
  final String id;
  final String name;
  final String description;
  final String rarity;     // commun, rare, epique, legendaire
  final String unlockType; // free, level, xp
  final int unlockValue;   // niveau requis ou cout XP
  final String imageKey;   // cle pour l'asset (placeholder pour l'instant)
  final bool owned;        // le joueur le possede ?
  final bool equipped;     // actuellement equipe ?

  Skin({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.unlockType,
    required this.unlockValue,
    required this.imageKey,
    this.owned = false,
    this.equipped = false,
  });

  factory Skin.fromJson(Map<String, dynamic> json, {bool owned = false, bool equipped = false}) {
    return Skin(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      rarity: json['rarity'] ?? 'commun',
      unlockType: json['unlock_type'] ?? 'free',
      unlockValue: json['unlock_value'] ?? 0,
      imageKey: json['image_key'] ?? 'skin_default',
      owned: owned,
      equipped: equipped,
    );
  }

  /// Condition de deblocage affichee dans la boutique
  String get conditionTexte {
    switch (unlockType) {
      case 'free':
        return 'Gratuit';
      case 'level':
        return 'Niveau $unlockValue';
      case 'xp':
        return '$unlockValue XP';
      default:
        return '???';
    }
  }
}
