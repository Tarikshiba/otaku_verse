/// Represente un Goodies (skin de personnage) dans la Boutique V9.2.
/// Regle ECO-02 / SHOP-03 : ZERO achat en XP.
/// - 1 seul Goodies de depart en OC (300 OC, Tutoriel Phase A)
/// - 100% des autres Goodies vendus exclusivement en Verse Coins (VC)
class Skin {
  final String id;
  final String name;
  final String description;
  final String rarity; // commun, classique, epique, legendaire
  final String currency; // free, oc, vc
  final int price; // 0 si gratuit, 300 si OC tuto, 350..1500 si VC
  final String imageKey;
  final bool owned;
  final bool equipped;
  final bool isTutorialStarter;
  final bool isFounderLegendary;

  // Alias retrocompatibles avec les anciens ecrans
  String get unlockType => currency;
  int get unlockValue => price;

  const Skin({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.currency,
    required this.price,
    required this.imageKey,
    this.owned = false,
    this.equipped = false,
    this.isTutorialStarter = false,
    this.isFounderLegendary = false,
  });

  Skin copyWith({bool? owned, bool? equipped}) {
    return Skin(
      id: id,
      name: name,
      description: description,
      rarity: rarity,
      currency: currency,
      price: price,
      imageKey: imageKey,
      owned: owned ?? this.owned,
      equipped: equipped ?? this.equipped,
      isTutorialStarter: isTutorialStarter,
      isFounderLegendary: isFounderLegendary,
    );
  }

  /// Texte de prix affiche en boutique (jamais d'XP)
  String get conditionTexte {
    switch (currency) {
      case 'free':
        return 'Gratuit';
      case 'oc':
        return '$price OC';
      case 'vc':
        return '$price VC';
      default:
        return '$price VC';
    }
  }
}
