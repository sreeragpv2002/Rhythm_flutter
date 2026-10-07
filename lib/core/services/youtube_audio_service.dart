import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:rhythm_flutter/core/services/audio_quality_service.dart';

/// Represents resolved YouTube audio streaming information with multiple quality streams
class YouTubeAudioResult {
  final String videoId;
  final String bestAudioUrl;
  final List<SongDownloadUrl> downloadUrls;
  final int? durationSeconds;
  final String? title;
  final String? author;

  const YouTubeAudioResult({
    required this.videoId,
    required this.bestAudioUrl,
    required this.downloadUrls,
    this.durationSeconds,
    this.title,
    this.author,
  });
}

class _CachedYouTubeStream {
  final YouTubeAudioResult result;
  final DateTime expiresAt;

  _CachedYouTubeStream(this.result, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Service dedicated to resolving direct audio streams for YouTube & YouTube Music tracks.
///
/// Designed with cross-platform compatibility:
/// - Web: Resolves streams from CORS-enabled endpoints (e.g. Piped/Invidious mirrors)
/// - Desktop (Windows, macOS, Linux): Streams via media_kit / just_audio
/// - Mobile (Android, iOS): Native playback with background notification controls
class YouTubeAudioService {
  final Dio _dio;
  final Map<String, _CachedYouTubeStream> _cache = {};

  YouTubeAudioService([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
                sendTimeout: kIsWeb ? null : const Duration(seconds: 4),
                headers: {
                  'Accept': 'application/json',
                },
              ),
            );

  /// Checks if a song identifier or URL is a YouTube Music / YouTube video.
  bool isYouTubeTrack(String id, {String? songUrl, bool? explicitIsYouTube}) {
    if (explicitIsYouTube == true) return true;
    if (songUrl != null &&
        (songUrl.contains('youtube.com') ||
            songUrl.contains('youtu.be') ||
            songUrl.contains('music.youtube.com'))) {
      return true;
    }
    final cleanId = id.trim();
    if (cleanId.startsWith('yt_')) return true;
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(cleanId)) return true;
    return false;
  }

  /// Extracts the standard 11-character YouTube video ID from an ID or URL.
  String? extractVideoId(String idOrUrl) {
    final clean = idOrUrl.trim();
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(clean)) {
      return clean;
    }

    if (clean.startsWith('yt_')) {
      final stripped = clean.substring(3);
      if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(stripped)) {
        return stripped;
      }
    }

    // Try YouTube URLs
    try {
      final uri = Uri.parse(clean);
      if (uri.host.contains('youtube.com') || uri.host.contains('music.youtube.com')) {
        final v = uri.queryParameters['v'];
        if (v != null && v.length == 11) return v;
      } else if (uri.host.contains('youtu.be')) {
        final path = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
        if (path.length == 11) return path;
      }
    } catch (_) {}

    final match = RegExp(r'(?:v=|\/)([a-zA-Z0-9_-]{11})(?:\?|&|$)').firstMatch(clean);
    return match?.group(1);
  }

  /// Resolves direct audio streams for a YouTube track with quality fallbacks.
  Future<YouTubeAudioResult?> resolveStream(
    String songId, {
    String? songUrl,
  }) async {
    final videoId = extractVideoId(songUrl ?? songId) ?? extractVideoId(songId);
    if (videoId == null) return null;

    // Web fast-path: In browser, playback is handled directly via YouTube IFrame player
    // to bypass browser CORS restrictions and eliminate mirror request latency.
    if (kIsWeb) {
      final webWatchUrl = 'https://www.youtube.com/watch?v=$videoId';
      return YouTubeAudioResult(
        videoId: videoId,
        bestAudioUrl: webWatchUrl,
        downloadUrls: [
          SongDownloadUrl(quality: '160kbps', url: webWatchUrl),
        ],
      );
    }

    // 1. Check cache (valid for 1 hour)
    final cached = _cache[videoId];
    if (cached != null && !cached.isExpired) {
      debugPrint('YouTubeAudioService: Returning cached stream for $videoId');
      return cached.result;
    }

    debugPrint('YouTubeAudioService: Resolving YouTube stream for $videoId...');

    // 2. Fast parallel check of top working mirrors with 2.5s timeout
    final activeMirrors = ['https://pipedapi.leptons.xyz', 'https://pa.il.ax', 'https://inv.nadeko.net'];
    final futures = activeMirrors.map((mirror) async {
      try {
        final streamUrl = mirror.contains('piped')
            ? '$mirror/streams/$videoId'
            : '$mirror/api/v1/videos/$videoId';
        final response = await _dio.get<Map<String, dynamic>>(
          streamUrl,
          options: Options(receiveTimeout: const Duration(milliseconds: 2500)),
        );
        if (response.data != null) {
          if (mirror.contains('piped') && response.data!['audioStreams'] is List) {
            return _parsePipedStreams(videoId, response.data!);
          } else if (response.data!['adaptiveFormats'] is List) {
            return _parseInvidiousStreams(videoId, response.data!);
          }
        }
      } catch (_) {}
      return null;
    });

    try {
      final results = await Future.wait(futures).timeout(const Duration(seconds: 3));
      final resolved = results.firstWhere((r) => r != null && r.bestAudioUrl.isNotEmpty, orElse: () => null);
      if (resolved != null) {
        _cache[videoId] = _CachedYouTubeStream(
          resolved,
          DateTime.now().add(const Duration(hours: 1)),
        );
        return resolved;
      }
    } catch (_) {}

    return null;
  }

  YouTubeAudioResult? _parsePipedStreams(String videoId, Map<String, dynamic> data) {
    final rawAudio = data['audioStreams'] as List?;
    if (rawAudio == null || rawAudio.isEmpty) return null;

    final downloadUrls = <SongDownloadUrl>[];
    String? bestUrl;
    int maxBitrate = 0;

    for (final item in rawAudio) {
      if (item is Map<String, dynamic>) {
        final url = item['url']?.toString();
        if (url == null || url.isEmpty) continue;

        final bitrate = item['bitrate'] is num ? (item['bitrate'] as num).toInt() : 0;
        final qualityStr = item['quality']?.toString() ?? '${(bitrate / 1000).round()}kbps';

        final cleanQuality = qualityStr.replaceAll(' ', '');
        downloadUrls.add(SongDownloadUrl(quality: cleanQuality, url: url));

        if (bitrate > maxBitrate) {
          maxBitrate = bitrate;
          bestUrl = url;
        }
      }
    }

    if (downloadUrls.isEmpty) return null;
    bestUrl ??= downloadUrls.last.url;

    final durationSeconds = data['duration'] is num
        ? (data['duration'] as num).toInt()
        : null;

    return YouTubeAudioResult(
      videoId: videoId,
      bestAudioUrl: bestUrl,
      downloadUrls: downloadUrls,
      durationSeconds: durationSeconds,
      title: data['title']?.toString(),
      author: data['uploader']?.toString(),
    );
  }

  YouTubeAudioResult? _parseInvidiousStreams(String videoId, Map<String, dynamic> data) {
    final rawFormats = data['adaptiveFormats'] as List?;
    if (rawFormats == null || rawFormats.isEmpty) return null;

    final downloadUrls = <SongDownloadUrl>[];
    String? bestUrl;
    int maxBitrate = 0;

    for (final item in rawFormats) {
      if (item is Map<String, dynamic>) {
        final type = item['type']?.toString() ?? '';
        if (!type.startsWith('audio/')) continue;

        final url = item['url']?.toString();
        if (url == null || url.isEmpty) continue;

        final bitrate = item['bitrate'] is num
            ? (item['bitrate'] as num).toInt()
            : int.tryParse(item['bitrate']?.toString() ?? '') ?? 0;
        final quality = '${(bitrate / 1000).round()}kbps';

        downloadUrls.add(SongDownloadUrl(quality: quality, url: url));

        if (bitrate > maxBitrate) {
          maxBitrate = bitrate;
          bestUrl = url;
        }
      }
    }

    if (downloadUrls.isEmpty) return null;
    bestUrl ??= downloadUrls.last.url;

    final lengthSeconds = data['lengthSeconds'] is num
        ? (data['lengthSeconds'] as num).toInt()
        : null;

    return YouTubeAudioResult(
      videoId: videoId,
      bestAudioUrl: bestUrl,
      downloadUrls: downloadUrls,
      durationSeconds: lengthSeconds,
      title: data['title']?.toString(),
      author: data['author']?.toString(),
    );
  }
}
