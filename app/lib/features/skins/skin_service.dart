import 'package:supabase_flutter/supabase_flutter.dart';
import 'skin_model.dart';

/// === SERVICE GOODIES (SKINS) V9.2 (ECO-02 & SHOP-03) ===
/// - ZERO achat de skin en XP (regle inviolable §1.2)
/// - 1 seul Goodies gratuit de base + 1 seul Goodies de depart Tuto a 300 OC
/// - 100% des autres Goodies (Classiques 350-500 VC, Epiques 700-900 VC,
///   Fondateurs Legendaires Soryn & Nyxara 1200-1500 VC) achetes via `shop-tutorial-engine`
class SkinService {
  final _supabase = Supabase.instance.client;
  String? get _myId => _supabase.auth.currentUser?.id;

  /// Catalogue officiel V9.2 des Goodies (miroir exact de shop-tutorial-engine)
  static const List<Skin> catalogueOfficiel = [
    Skin(
      id: 'skin_default',
      name: 'Guerrier du Verse',
      description: 'Tenue d\'entree gratuite remise a tous les combattants.',
      rarity: 'commun',
      currency: 'free',
      price: 0,
      imageKey: 'skin_default',
    ),
    Skin(
      id: 'starter_tuto_ninja',
      name: 'Ninja de Konoha',
      description: 'Premier Goodies du Tutoriel : deblocable avec les 300 OC d\'accueil.',
      rarity: 'classique',
      currency: 'oc',
      price: 300,
      imageKey: 'skin_ninja',
      isTutorialStarter: true,
    ),
    Skin(
      id: 'skin_pirate',
      name: 'Capitaine Pirate',
      description: 'Goodies Classique inspire des mers de Grand Line.',
      rarity: 'classique',
      currency: 'vc',
      price: 350,
      imageKey: 'skin_pirate',
    ),
    Skin(
      id: 'skin_samourai',
      name: 'Ronin de Wano',
      description: 'Lame affutee et discipline shonen pour les duels rapides.',
      rarity: 'classique',
      currency: 'vc',
      price: 400,
      imageKey: 'skin_samourai',
    ),
    Skin(
      id: 'skin_ermite',
      name: 'Ermite des Cimes',
      description: 'Maitrise des arts anciens et sang-froid face aux Malus.',
      rarity: 'classique',
      currency: 'vc',
      price: 450,
      imageKey: 'skin_ermite',
    ),
    Skin(
      id: 'skin_titan',
      name: 'Chasseur de Titans',
      description: 'Equipement tridimensionnel pret pour le Money Time.',
      rarity: 'classique',
      currency: 'vc',
      price: 500,
      imageKey: 'skin_titan',
    ),
    Skin(
      id: 'skin_demon',
      name: 'Pourfendeur Demoniaque',
      description: 'Goodies Epique forge pour briser les series adverses.',
      rarity: 'epique',
      currency: 'vc',
      price: 700,
      imageKey: 'skin_demon',
    ),
    Skin(
      id: 'skin_hokage',
      name: 'Ombre du Hokage',
      description: 'Cape de chef de village reserves aux erudits des arcs.',
      rarity: 'epique',
      currency: 'vc',
      price: 800,
      imageKey: 'skin_hokage',
    ),
    Skin(
      id: 'skin_dragon',
      name: 'Guerrier Dragon',
      description: 'Aura ardente declenchee sur chaque Combo x3.',
      rarity: 'epique',
      currency: 'vc',
      price: 850,
      imageKey: 'skin_dragon',
    ),
    Skin(
      id: 'skin_roi',
      name: 'Souverain des Ombres',
      description: 'Armure sombre des maitres de donjons et d\'arenes.',
      rarity: 'epique',
      currency: 'vc',
      price: 900,
      imageKey: 'skin_roi',
    ),
    Skin(
      id: 'avatar_soryn_ether_watcher',
      name: 'Soryn, Gardien de l\'Ether',
      description: 'Personnage Fondateur Legendaire d\'Otaku Verse (edition signature).',
      rarity: 'legendaire',
      currency: 'vc',
      price: 1200,
      imageKey: 'bot_akina',
      isFounderLegendary: true,
    ),
    Skin(
      id: 'avatar_nyxara_twin_fangs',
      name: 'Nyxara, Crocs Jumeaux',
      description: 'Personnage Fondateur Legendaire aux lames jumelles du Verse.',
      rarity: 'legendaire',
      currency: 'vc',
      price: 1500,
      imageKey: 'boss_gardien',
      isFounderLegendary: true,
    ),
  ];

  /// Recupere tous les Goodies V9.2 avec leur etat possede / equipe depuis Supabase.
  Future<List<Skin>> tousLesSkins() async {
    final uid = _myId;
    if (uid == null) {
      return catalogueOfficiel
          .map((s) => s.copyWith(owned: s.currency == 'free', equipped: s.currency == 'free'))
          .toList();
    }

    final ownedMap = <String, bool>{};
    try {
      final rows = await _supabase
          .from('player_cosmetics')
          .select('item_id, equipped')
          .eq('user_id', uid)
          .eq('category', 'skin');

      for (final row in List<Map<String, dynamic>>.from(rows)) {
        final itemId = row['item_id']?.toString() ?? '';
        if (itemId.isNotEmpty) {
          ownedMap[itemId] = row['equipped'] == true;
        }
      }
    } catch (_) {}

    // Retrocompatibilite avec d'eventuels skins deja debloques en V1 (player_skins)
    try {
      final legacyRows = await _supabase
          .from('player_skins')
          .select('equipped, skins(image_key)')
          .eq('player_id', uid);

      for (final row in List<Map<String, dynamic>>.from(legacyRows)) {
        final imageKey = (row['skins'] as Map?)?['image_key']?.toString();
        if (imageKey == null) continue;
        final match = catalogueOfficiel.where((s) => s.imageKey == imageKey).firstOrNull;
        if (match != null && !ownedMap.containsKey(match.id)) {
          ownedMap[match.id] = row['equipped'] == true;
        }
      }
    } catch (_) {}

    // Le skin de base gratuit est toujours possede
    ownedMap.putIfAbsent('skin_default', () => false);
    final hasAnyEquipped = ownedMap.values.any((e) => e);
    if (!hasAnyEquipped) {
      ownedMap['skin_default'] = true;
    }

    return catalogueOfficiel.map((s) {
      final owned = ownedMap.containsKey(s.id);
      final equipped = ownedMap[s.id] == true;
      return s.copyWith(owned: owned, equipped: equipped);
    }).toList();
  }

  /// Acheter / debloquer un Goodies via le serveur (`shop-tutorial-engine`).
  /// Retourne null si OK, sinon un message d'erreur clair.
  Future<String?> debloquer(Skin skin, {bool autoEquip = true}) async {
    if (skin.owned) return 'Tu possedes deja ce Goodies';
    if (skin.currency == 'free') return null;

    try {
      final res = await _supabase.functions.invoke(
        'shop-tutorial-engine',
        body: {
          'action': 'purchase_goodie',
          'item_id': skin.id,
          'auto_equip': autoEquip,
        },
      );
      final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      if (res.status >= 400 || data['error'] != null) {
        return data['error']?.toString() ?? 'Achat impossible';
      }
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Equiper un Goodies possede (met a jour player_cosmetics)
  Future<void> equiper(String skinId) async {
    final uid = _myId;
    if (uid == null) return;

    try {
      await _supabase
          .from('player_cosmetics')
          .update({'equipped': false})
          .eq('user_id', uid)
          .eq('category', 'skin');

      if (skinId != 'skin_default') {
        await _supabase
            .from('player_cosmetics')
            .update({'equipped': true})
            .eq('user_id', uid)
            .eq('item_id', skinId);
      }
    } catch (_) {}
  }

  /// Compatibilite ascendante (le skin gratuit de base est garanti dans tousLesSkins)
  Future<void> donnerSkinGratuit() async {}
}
