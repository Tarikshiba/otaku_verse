import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

/// === SERVICE DE STREAMING & CACHE LOCAL 3D (.glb) FACON FREE FIRE ===
/// - `skin_kio` (Kio, skin par defaut) est embarque dans l'APK (~0,9 Mo) pour un affichage 3D instantane.
/// - Les autres skins (Mazu, Tavik, Ruve, Hesk, Ilka, Vael, Dakore, Ysae, Cassio Vey)
///   sont telecharges une seule fois depuis Cloudflare R2 (`/models/<imageKey>.glb`)
///   et stockes en cache persistant sur le telephone.
/// - En cas d'absence reseau ou de modele non encore uploade (404), retourne null
///   pour un repli propre et immediat sur le portrait 2D transparent.
class Skin3DCacheService {
  Skin3DCacheService._();
  static final Skin3DCacheService instance = Skin3DCacheService._();

  /// Version du pack 3D (incrementee a chaque nouvelle vague d'animations R2 pour invalider le cache local/CDN)
  static const String modelCacheVersion = 'v2_anim';

  /// Skins embarques directement dans les assets de l'APK (poids minimal)
  static const Set<String> embeddedAssetSkins = {'skin_kio'};

  /// Skins disposant d'un modele 3D .glb compresse sur R2
  static const Set<String> available3DSkins = {
    'skin_kio',
    'skin_mazu',
    'skin_tavik',
    'skin_ruve',
    'skin_hesk',
    'skin_ilka',
    'skin_vael',
    'skin_dakore',
    'skin_ysae',
    'skin_cassio_vey',
  };

  final Map<String, Future<String?>> _inFlight = {};

  static String get _baseApiUrl {
    final fromEnv = dotenv.isInitialized ? dotenv.env['QUIZ_API_URL'] : null;
    if (fromEnv != null && fromEnv.trim().isNotEmpty) {
      return fromEnv.trim().replaceAll(RegExp(r'/$'), '');
    }
    return 'https://otaku-verse-quiz-api.otakuverse-221.workers.dev';
  }

  /// Indique si ce skin possede un modele 3D (embarque ou sur R2)
  bool aModele3D(String imageKey) => available3DSkins.contains(imageKey);

  /// Retourne la source prete pour ModelViewer :
  /// - `'assets/models/skins/skin_kio.glb'` si embarque dans l'APK
  /// - `'file:///.../models_3d/<imageKey>.glb'` si deja en cache local ou telecharge depuis R2
  /// - `null` si indisponible (le widget reste sur le portrait 2D transparent)
  Future<String?> obtenirSource3D(String imageKey) async {
    if (!available3DSkins.contains(imageKey)) return null;

    if (embeddedAssetSkins.contains(imageKey)) {
      return 'assets/models/skins/$imageKey.glb';
    }

    if (kIsWeb) {
      return '$_baseApiUrl/models/$imageKey.glb?v=$modelCacheVersion';
    }

    // Evite les telechargements paralleles du meme modele
    return _inFlight.putIfAbsent(imageKey, () async {
      try {
        return await _resoudreOuTelechargerLocal(imageKey);
      } finally {
        _inFlight.remove(imageKey);
      }
    });
  }

  Future<String?> _resoudreOuTelechargerLocal(String imageKey) async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final cacheDir = Directory('${supportDir.path}/models_3d');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final localFile = File('${cacheDir.path}/${imageKey}_$modelCacheVersion.glb');
      if (await localFile.exists() && await localFile.length() > 1024) {
        return localFile.uri.toString();
      }

      // Nettoyer l'eventuelle ancienne version statique T-Pose si presente
      final legacyFile = File('${cacheDir.path}/$imageKey.glb');
      if (await legacyFile.exists()) {
        await legacyFile.delete();
      }

      // Telechargement streaming depuis Cloudflare R2 (zero frais egress, ?v= invalide le cache CDN)
      final uri = Uri.parse('$_baseApiUrl/models/$imageKey.glb?v=$modelCacheVersion');
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      try {
        final req = await client.getUrl(uri);
        final res = await req.close().timeout(const Duration(seconds: 25));
        if (res.statusCode != 200) {
          return null;
        }

        final tmpFile = File('${cacheDir.path}/$imageKey.glb.tmp');
        final sink = tmpFile.openWrite();
        await res.pipe(sink);

        final size = await tmpFile.length();
        if (size < 1024) {
          if (await tmpFile.exists()) await tmpFile.delete();
          return null;
        }
        await tmpFile.rename(localFile.path);
        return localFile.uri.toString();
      } finally {
        client.close();
      }
    } catch (_) {
      return null;
    }
  }

  /// Taille actuelle du cache 3D sur le telephone en Mo (pour l'ecran Parametres)
  Future<double> tailleCacheMo() async {
    if (kIsWeb) return 0;
    try {
      final supportDir = await getApplicationSupportDirectory();
      final cacheDir = Directory('${supportDir.path}/models_3d');
      if (!await cacheDir.exists()) return 0;
      int totalBytes = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      return totalBytes / (1024 * 1024);
    } catch (_) {
      return 0;
    }
  }

  /// Vide le cache local des modeles 3D telecharges (garde Kio embarque dans l'APK)
  Future<void> viderCache3D() async {
    if (kIsWeb) return;
    try {
      final supportDir = await getApplicationSupportDirectory();
      final cacheDir = Directory('${supportDir.path}/models_3d');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
