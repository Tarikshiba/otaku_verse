import re

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_service.dart', 'r') as f:
    content = f.read()

new_method = """  /// Retourne la liste des arcs pour un anime.
  Future<List<String>> recupererArcsDisponibles(String anime) async {
    final supabase = _quizService.supabaseClient;
    final reponse = await supabase
        .from('questions')
        .select('arc')
        .ilike('anime', anime)
        .eq('statut', 'actif');

    final arcs = (reponse as List)
        .map((row) => row['arc'] as String?)
        .where((arc) => arc != null && arc.isNotEmpty)
        .map((arc) => arc!)
        .toSet()
        .toList();
    arcs.sort();
    return arcs;
  }
}"""

content = content.replace("}\n", new_method)

with open('/mnt/c/All-projects/2026/Otaku_verse/app/lib/features/combat/combat_service.dart', 'w') as f:
    f.write(content)
