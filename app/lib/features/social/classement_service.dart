import 'package:supabase_flutter/supabase_flutter.dart';
import 'friends_service.dart';

/// Service de classement — mondial, national, amis.
/// Trie les joueurs par XP totale (descendant).
class ClassementService {
  final _supabase = Supabase.instance.client;
  final _friendsService = FriendsService();

  String? get _myId => _supabase.auth.currentUser?.id;
  String? get monId => _myId;

  /// Classement mondial — top 50 joueurs par XP
  Future<List<Map<String, dynamic>>> classementMondial() async {
    final data = await _supabase
        .from('profiles')
        .select('id, pseudo, niveau, rang, xp_totale, combats_gagnes, country')
        .not('pseudo', 'is', null)
        .order('xp_totale', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Classement national — top 50 joueurs du meme pays que moi
  Future<List<Map<String, dynamic>>> classementNational() async {
    // Recuperer mon pays
    final monProfil = await _supabase
        .from('profiles')
        .select('country')
        .eq('id', _myId!)
        .maybeSingle();

    final monPays = monProfil?['country'];
    if (monPays == null) return [];

    final data = await _supabase
        .from('profiles')
        .select('id, pseudo, niveau, rang, xp_totale, combats_gagnes, country')
        .eq('country', monPays)
        .not('pseudo', 'is', null)
        .order('xp_totale', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Classement amis — uniquement parmi mes amis + moi
  Future<List<Map<String, dynamic>>> classementAmis() async {
    // Recuperer la liste de mes amis
    final amis = await _friendsService.mesAmis();
    final amisIds = amis.map((a) => a.userId).toList();
    amisIds.add(_myId!); // M'inclure dans le classement

    final data = await _supabase
        .from('profiles')
        .select('id, pseudo, niveau, rang, xp_totale, combats_gagnes, country')
        .inFilter('id', amisIds)
        .order('xp_totale', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Ma position dans le classement mondial
  Future<int> maPositionMondiale() async {
    final monProfil = await _supabase
        .from('profiles')
        .select('xp_totale')
        .eq('id', _myId!)
        .maybeSingle();

    if (monProfil == null) return 0;
    final monXp = monProfil['xp_totale'] as int;

    // Compter combien de joueurs ont plus d'XP que moi
    final result = await _supabase
        .from('profiles')
        .select('id')
        .gt('xp_totale', monXp)
        .not('pseudo', 'is', null);

    return (result as List).length + 1;
  }
}
