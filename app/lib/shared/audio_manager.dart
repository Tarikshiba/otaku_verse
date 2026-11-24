import 'package:shared_preferences/shared_preferences.dart';

/// === GESTIONNAIRE AUDIO & SFX OTAKU VERSE (PRET POUR LES 8 PISTES MP3) ===
/// Enregistre les preferences utilisateur (musique / effets sonores) dans SharedPreferences.
/// Les 8 chemins officiels de `OTAKU_VERSE_PERSONNAGES.md` sont centralises ici :
/// des que les fichiers .mp3 seront deposes dans `app/assets/audio/`,
/// il suffira de brancher `audioplayers` ou `just_audio` dans ces methodes.
class OtakuAudioManager {
  OtakuAudioManager._();
  static final OtakuAudioManager instance = OtakuAudioManager._();

  static const String _prefMusicEnabled = 'otaku_audio_music_enabled';
  static const String _prefSfxEnabled = 'otaku_audio_sfx_enabled';

  // Les 8 pistes officielles definies dans OTAKU_VERSE_PERSONNAGES.md
  static const String bgmLobby = 'assets/audio/bgm_lobby.mp3';
  static const String bgmCombat = 'assets/audio/bgm_combat.mp3';
  static const String sfxClic = 'assets/audio/sfx_clic.mp3';
  static const String sfxBonneReponse = 'assets/audio/sfx_bonne_reponse.mp3';
  static const String sfxHaya = 'assets/audio/sfx_haya.mp3';
  static const String sfxCombo = 'assets/audio/sfx_combo.mp3';
  static const String sfxErreur = 'assets/audio/sfx_erreur.mp3';
  static const String sfxKoKecchaku = 'assets/audio/sfx_ko_kecchaku.mp3';

  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _loaded = false;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;

  Future<void> chargerPreferences() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _musicEnabled = prefs.getBool(_prefMusicEnabled) ?? true;
      _sfxEnabled = prefs.getBool(_prefSfxEnabled) ?? true;
      _loaded = true;
    } catch (_) {}
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefMusicEnabled, enabled);
    } catch (_) {}
  }

  Future<void> setSfxEnabled(bool enabled) async {
    _sfxEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefSfxEnabled, enabled);
    } catch (_) {}
  }

  /// Points d'entree prets pour lecture des que app/assets/audio/*.mp3 est depose
  Future<void> jouerSfx(String assetPath) async {
    if (!_sfxEnabled) return;
  }

  Future<void> jouerBgm(String assetPath) async {
    if (!_musicEnabled) return;
  }
}
