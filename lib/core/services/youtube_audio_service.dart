import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;
import 'package:rhythm_flutter/core/config/app_config.dart';
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
/// - Native (Android, iOS, Desktop): Direct on-device extraction via YoutubeExplode (eliminating remote-IP 403 blocks)
/// - Web: Resolves streams from CORS-enabled endpoints
class YouTubeAudioService {
  final Dio _dio;
  final yt_exp.YoutubeExplode _yt = yt_exp.YoutubeExplode();
  final Map<String, _CachedYouTubeStream> _cache = {};

  YouTubeAudioService([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 5),
                sendTimeout: kIsWeb ? null : const Duration(seconds: 5),
                headers: {
                  'Accept': 'application/json',
                  'User-Agent':
                      'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
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

    // 2. Query FastAPI Backend stream endpoint (Path A: Server-Side Stream Resolver)
    try {
      final backendStreamUrl = '${AppConfig.baseUrl}/api/v1/streams/$videoId';
      final response = await _dio.get<Map<String, dynamic>>(
        backendStreamUrl,
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      if (response.data != null && response.data!['audio_url'] != null) {
        final data = response.data!;
        final audioUrl = data['audio_url'] as String;
        final rawDownloads = data['download_urls'];
        final downloadUrls = <SongDownloadUrl>[];
        if (rawDownloads is List) {
          for (final item in rawDownloads) {
            if (item is Map<String, dynamic> && item['url'] != null) {
              downloadUrls.add(SongDownloadUrl(
                quality: item['quality']?.toString() ?? '160kbps',
                url: item['url'].toString(),
              ));
            }
          }
        }
        if (downloadUrls.isEmpty) {
          downloadUrls.add(SongDownloadUrl(quality: '160kbps', url: audioUrl));
        }

        final result = YouTubeAudioResult(
          videoId: videoId,
          bestAudioUrl: audioUrl,
          downloadUrls: downloadUrls,
          durationSeconds: data['duration'] is int ? data['duration'] as int : null,
          title: data['title'] as String?,
          author: data['author'] as String?,
        );
        _cache[videoId] = _CachedYouTubeStream(
          result,
          DateTime.now().add(const Duration(hours: 1)),
        );
        debugPrint('YouTubeAudioService: Successfully resolved stream via backend for $videoId');
        return result;
      }
    } catch (e) {
      debugPrint('YouTubeAudioService: Backend stream resolution skipped ($e), trying fallback extractors...');
    }

    // 2. Direct on-device extraction via YoutubeExplode (Safari Mobile Web client)
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [
          yt_exp.YoutubeApiClient.safari,
        ],
      ).timeout(const Duration(milliseconds: 2500));

      final audioStreams = manifest.audioOnly.sortByBitrate();
      final targetStreams = audioStreams.isNotEmpty ? audioStreams : manifest.muxed.sortByBitrate();

      if (targetStreams.isNotEmpty) {
        final bestStream = targetStreams.last;
        final downloadUrls = targetStreams.reversed.map((s) {
          final bitrateKbps = s.bitrate.kiloBitsPerSecond.round();
          return SongDownloadUrl(
            quality: '${bitrateKbps}kbps',
            url: s.url.toString(),
          );
        }).toList();

        final result = YouTubeAudioResult(
          videoId: videoId,
          bestAudioUrl: bestStream.url.toString(),
          downloadUrls: downloadUrls,
        );

        _cache[videoId] = _CachedYouTubeStream(
          result,
          DateTime.now().add(const Duration(hours: 1)),
        );
        debugPrint(
            'YouTubeAudioService: Successfully resolved client-side stream via YoutubeExplode for $videoId');
        return result;
      }
    } catch (e) {
      debugPrint(
          'YouTubeAudioService: YoutubeExplode resolution skipped ($e), attempting fastest proxy mirror fallback...');
    }

    // 3. Fallback: Fast parallel mirror race with stream proxying to avoid 403 IP blocks
    final activeMirrors = [
      'https://invidious.nerdvpn.de',
      'https://inv.nadeko.net',
      'https://invidious.drgns.space',
      'https://vid.puffyan.us',
      'https://api.piped.privacydev.net',
      'https://pipedapi.adminforge.de',
      'https://piped-api.garudalinux.org',
      'https://pipedapi.tokhmi.xyz',
    ];

    final completer = Completer<YouTubeAudioResult?>();
    int pending = activeMirrors.length;

    for (final mirror in activeMirrors) {
      _fetchFromMirror(mirror, videoId).then((res) {
        if (res != null && res.bestAudioUrl.isNotEmpty && !completer.isCompleted) {
          completer.complete(res);
        } else {
          pending--;
          if (pending == 0 && !completer.isCompleted) {
            completer.complete(null);
          }
        }
      }).catchError((_) {
        pending--;
        if (pending == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    try {
      final resolved = await completer.future.timeout(const Duration(milliseconds: 3000));
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

  Future<YouTubeAudioResult?> _fetchFromMirror(String mirror, String videoId) async {
    try {
      final isPiped = mirror.contains('piped') ||
          mirror.contains('privacydev') ||
          mirror.contains('adminforge') ||
          mirror.contains('garudalinux') ||
          mirror.contains('tokhmi');
      final streamUrl = isPiped
          ? '$mirror/streams/$videoId'
          : '$mirror/api/v1/videos/$videoId';

      final response = await _dio.get<Map<String, dynamic>>(
        streamUrl,
        options: Options(
          receiveTimeout: const Duration(milliseconds: 2500),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          },
        ),
      );

      if (response.data != null) {
        if (isPiped && response.data!['audioStreams'] is List) {
          return _parsePipedStreams(videoId, response.data!, mirror);
        } else if (response.data!['adaptiveFormats'] is List) {
          return _parseInvidiousStreams(videoId, response.data!, mirror);
        }
      }
    } catch (_) {}
    return null;
  }

  YouTubeAudioResult? _parsePipedStreams(String videoId, Map<String, dynamic> data, [String? mirror]) {
    final rawAudio = data['audioStreams'] as List?;
    if (rawAudio == null || rawAudio.isEmpty) return null;

    final downloadUrls = <SongDownloadUrl>[];
    String? bestUrl;
    int maxBitrate = 0;

    for (final item in rawAudio) {
      if (item is Map<String, dynamic>) {
        var url = item['url']?.toString();
        if (url == null || url.isEmpty) continue;

        // Proxy through mirror if direct googlevideo to prevent 403 IP mismatch on phone
        if (url.contains('googlevideo.com') && mirror != null) {
          url = '$mirror/proxy?url=${Uri.encodeQueryComponent(url)}';
        } else if (url.startsWith('/') && mirror != null) {
          url = '$mirror$url';
        }

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

  YouTubeAudioResult? _parseInvidiousStreams(String videoId, Map<String, dynamic> data, [String? mirror]) {
    final rawFormats = data['adaptiveFormats'] as List?;
    if (rawFormats == null || rawFormats.isEmpty) return null;

    final downloadUrls = <SongDownloadUrl>[];
    String? bestUrl;
    int maxBitrate = 0;

    for (final item in rawFormats) {
      if (item is Map<String, dynamic>) {
        final type = item['type']?.toString() ?? '';
        if (!type.startsWith('audio/')) continue;

        var url = item['url']?.toString();
        if (url == null || url.isEmpty) continue;

        // Route through Invidious videoplayback proxy to avoid 403 IP block
        if (url.contains('googlevideo.com') && mirror != null) {
          final itag = item['itag']?.toString() ?? '140';
          url = '$mirror/videoplayback?id=$videoId&itag=$itag';
        } else if (url.startsWith('/') && mirror != null) {
          url = '$mirror$url';
        }

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
