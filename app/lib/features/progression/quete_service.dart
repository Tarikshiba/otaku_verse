import 'package:supabase_flutter/supabase_flutter.dart';

class QueteService {
  final _supabase = Supabase.instance.client;

  Future<void> syncQuete(String titre, int progression, bool recupere) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('user_quests').upsert({
      'user_id': userId,
      'quete_titre': titre,
      'progression': progression,
      'recupere': recupere,
    }, onConflict: 'user_id, quete_titre');
  }

  Future<Map<String, Map<String, dynamic>>> getQuetesState() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {};

    final data = await _supabase.from('user_quests').select().eq('user_id', userId);
    
    final Map<String, Map<String, dynamic>> result = {};
    for (var row in data) {
      result[row['quete_titre']] = {
        'progression': row['progression'] ?? 0,
        'recupere': row['recupere'] ?? false,
      };
    }
    return result;
  }
}
