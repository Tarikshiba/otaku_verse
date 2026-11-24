import 'package:supabase_flutter/supabase_flutter.dart';
import 'friends_service.dart';

/// Service de classement V9.2 :
/// - Classement General XP (Mondial, National, Amis — sans recompense/cagnotte)
/// - Classement Competitif Division (Points Division, K.O. saison, 10 Divisions)
class ClassementService {
  final _supabase = Supabase.instance.client;
  final _friendsService = FriendsService();

  static const String _selectFields =
      'id, pseudo, niveau, rang, xp_totale, combats_gagnes, combats_joues, country, pts_division, division_id, ko_wins_season, season_matches_played, equipped_skin_key';

  String? get _myId => _supabase.auth.currentUser?.id;
  String? get monId => _myId;

  /// Enrichit chaque ligne avec un skin par defaut si la colonne n'est pas encore renseignee
  List<Map<String, dynamic>> _normaliserLignes(List<dynamic> raw) {
    return raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      m['equipped_skin_key'] = (m['equipped_skin_key']?.toString().isNotEmpty ?? false)
          ? m['equipped_skin_key'].toString()
          : 'skin_kio';
      return m;
    }).toList();
  }

  /// Requete securisee qui retombe sans equipped_skin_key si la migration SQL n'est pas encore executee
  Future<List<Map<String, dynamic>>> _queryProfiles(
    Future<List<dynamic>> Function(String fields) runner,
  ) async {
    try {
      final data = await runner(_selectFields);
      return _normaliserLignes(data);
    } catch (_) {
      final fallbackFields =
          'id, pseudo, niveau, rang, xp_totale, combats_gagnes, combats_joues, country, pts_division, division_id, ko_wins_season, season_matches_played';
      final data = await runner(fallbackFields);
      return _normaliserLignes(data);
    }
  }

  /// Classement mondial XP — top 50 joueurs par XP
  Future<List<Map<String, dynamic>>> classementMondial() async {
    return _queryProfiles((fields) async {
      final res = await _supabase
          .from('profiles')
          .select(fields)
          .not('pseudo', 'is', null)
          .order('xp_totale', ascending: false)
          .limit(50);
      return res as List;
    });
  }

  /// Classement national XP — top 50 joueurs du meme pays que moi
  Future<List<Map<String, dynamic>>> classementNational() async {
    if (_myId == null) return [];
    final monProfil = await _supabase
        .from('profiles')
        .select('country')
        .eq('id', _myId!)
        .maybeSingle();

    final monPays = monProfil?['country'];
    if (monPays == null) return [];

    return _queryProfiles((fields) async {
      final res = await _supabase
          .from('profiles')
          .select(fields)
          .eq('country', monPays)
          .not('pseudo', 'is', null)
          .order('xp_totale', ascending: false)
          .limit(50);
      return res as List;
    });
  }

  /// Classement amis XP — uniquement parmi mes amis + moi
  Future<List<Map<String, dynamic>>> classementAmis() async {
    if (_myId == null) return [];
    final amis = await _friendsService.mesAmis();
    final amisIds = amis.map((a) => a.userId).toList();
    amisIds.add(_myId!);

    return _queryProfiles((fields) async {
      final res = await _supabase
          .from('profiles')
          .select(fields)
          .inFilter('id', amisIds)
          .order('xp_totale', ascending: false);
      return res as List;
    });
  }

  /// Classement Division (Palier 1 — trie par pts_division DESC, ko_wins_season DESC)
  Future<List<Map<String, dynamic>>> classementDivision({bool nationalUniquement = false}) async {
    String? monPays;
    if (nationalUniquement && _myId != null) {
      final p = await _supabase.from('profiles').select('country').eq('id', _myId!).maybeSingle();
      monPays = p?['country']?.toString();
      if (monPays == null) return [];
    }

    return _queryProfiles((fields) async {
      var q = _supabase.from('profiles').select(fields).not('pseudo', 'is', null);
      if (monPays != null) {
        q = q.eq('country', monPays);
      }
      final res = await q
          .order('pts_division', ascending: false)
          .order('ko_wins_season', ascending: false)
          .limit(50);
      return res as List;
    });
  }

  /// Ma position dans le classement mondial XP
  Future<int> maPositionMondiale() async {
    if (_myId == null) return 0;
    final monProfil = await _supabase
        .from('profiles')
        .select('xp_totale')
        .eq('id', _myId!)
        .maybeSingle();

    if (monProfil == null) return 0;
    final monXp = (monProfil['xp_totale'] as num?)?.toInt() ?? 0;

    final result = await _supabase
        .from('profiles')
        .select('id')
        .gt('xp_totale', monXp)
        .not('pseudo', 'is', null);

    return (result as List).length + 1;
  }

  /// Ma position dans le classement mondial Division
  Future<int> maPositionDivision() async {
    if (_myId == null) return 0;
    final monProfil = await _supabase
        .from('profiles')
        .select('pts_division')
        .eq('id', _myId!)
        .maybeSingle();

    if (monProfil == null) return 0;
    final mesPts = (monProfil['pts_division'] as num?)?.toInt() ?? 0;

    final result = await _supabase
        .from('profiles')
        .select('id')
        .gt('pts_division', mesPts)
        .not('pseudo', 'is', null);

    return (result as List).length + 1;
  }

  /// Recupere mes stats Division actuelles (pts, division_id, niveau)
  Future<Map<String, dynamic>?> monProfilDivision() async {
    if (_myId == null) return null;
    try {
      return await _supabase
          .from('profiles')
          .select('pseudo, niveau, rang, pts_division, division_id, ko_wins_season, season_matches_played')
          .eq('id', _myId!)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }
}
