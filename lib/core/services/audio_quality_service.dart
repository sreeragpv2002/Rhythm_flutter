import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/services/storage_service.dart';

/// Represents a single audio stream download URL item from the API response
class SongDownloadUrl {
  final String quality; // e.g., '12kbps', '48kbps', '96kbps', '160kbps', '320kbps'
  final String url;

  const SongDownloadUrl({
    required this.quality,
    required this.url,
  });

  /// Extracts numeric bitrate in kbps (e.g., '320kbps' -> 320)
  int get bitrateKbps {
    final digits = RegExp(r'\d+').firstMatch(quality)?.group(0);
    return int.tryParse(digits ?? '') ?? 160;
  }

  /// Formatted display label (e.g., "320 kbps (Very High)")
  String get displayLabel {
    switch (bitrateKbps) {
      case 320:
        return '320 kbps (Very High)';
      case 160:
        return '160 kbps (High)';
      case 96:
        return '96 kbps (Medium)';
      case 48:
        return '48 kbps (Data Saver)';
      case 12:
        return '12 kbps (Low)';
      default:
        return '$quality (Standard)';
    }
  }

  String get shortLabel => '${bitrateKbps} kbps';

  factory SongDownloadUrl.fromJson(Map<String, dynamic> json) {
    return SongDownloadUrl(
      quality: json['quality']?.toString() ?? '160kbps',
      url: json['url']?.toString() ?? json['link']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'quality': quality,
    'url': url,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongDownloadUrl &&
          runtimeType == other.runtimeType &&
          quality == other.quality &&
          url == other.url;

  @override
  int get hashCode => quality.hashCode ^ url.hashCode;

  @override
  String toString() => 'SongDownloadUrl($quality, $url)';
}

/// User's preference for audio streaming quality
enum AudioQualityPreference {
  auto('auto', 'Auto (Recommended)', 'Adapts seamlessly to your network speed'),
  veryHigh320('320kbps', 'Very High (320 kbps)', 'Best sound fidelity, uses more data'),
  high160('160kbps', 'High (160 kbps)', 'Great balance of quality and data usage'),
  medium96('96kbps', 'Medium (96 kbps)', 'Good for moderate cellular connections'),
  low48('48kbps', 'Data Saver (48 kbps)', 'Minimal data usage, ideal for weak signals');

  final String code;
  final String title;
  final String subtitle;

  const AudioQualityPreference(this.code, this.title, this.subtitle);

  int? get targetBitrateKbps {
    switch (this) {
      case AudioQualityPreference.veryHigh320:
        return 320;
      case AudioQualityPreference.high160:
        return 160;
      case AudioQualityPreference.medium96:
        return 96;
      case AudioQualityPreference.low48:
        return 48;
      case AudioQualityPreference.auto:
        return null; // Adaptive
    }
  }

  static AudioQualityPreference fromCode(String? code) {
    if (code == null) return AudioQualityPreference.auto;
    for (final pref in AudioQualityPreference.values) {
      if (pref.code == code) return pref;
    }
    return AudioQualityPreference.auto;
  }
}

/// Network speed category classification
enum NetworkSpeedGrade {
  excellent(320, 'Excellent (> 3 Mbps)'),
  good(160, 'Good (1.2 - 3 Mbps)'),
  moderate(96, 'Moderate (400 Kbps - 1.2 Mbps)'),
  poor(48, 'Weak (< 400 Kbps)');

  final int targetBitrateKbps;
  final String label;

  const NetworkSpeedGrade(this.targetBitrateKbps, this.label);

  static NetworkSpeedGrade fromKbps(double kbps) {
    if (kbps >= 3000) return NetworkSpeedGrade.excellent;
    if (kbps >= 1200) return NetworkSpeedGrade.good;
    if (kbps >= 400) return NetworkSpeedGrade.moderate;
    return NetworkSpeedGrade.poor;
  }
}

/// Lightweight service measuring real-time network throughput and classifying speed grade.
class NetworkSpeedService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 6),
  ));

  // Current estimated speed in kbps (starts with default 2500 kbps = Good)
  double _currentSpeedKbps = 2500.0;
  final _speedStreamController = StreamController<double>.broadcast();
  final _gradeStreamController = StreamController<NetworkSpeedGrade>.broadcast();

  // Exponential Moving Average weight (alpha: 0.35)
  static const double _emaAlpha = 0.35;

  NetworkSpeedService() {
    _speedStreamController.add(_currentSpeedKbps);
    _gradeStreamController.add(currentGrade);
  }

  double get currentSpeedKbps => _currentSpeedKbps;
  double get currentSpeedMbps => _currentSpeedKbps / 1000.0;
  NetworkSpeedGrade get currentGrade => NetworkSpeedGrade.fromKbps(_currentSpeedKbps);

  Stream<double> get speedStream => _speedStreamController.stream;
  Stream<NetworkSpeedGrade> get gradeStream => _gradeStreamController.stream;

  /// Feeds an active sample (e.g. from network requests or streaming buffer)
  void recordSample(int bytes, Duration elapsed) {
    if (elapsed.inMilliseconds <= 10 || bytes <= 0) return;

    final seconds = elapsed.inMilliseconds / 1000.0;
    final sampleKbps = (bytes * 8.0) / (seconds * 1000.0);

    // Apply EMA filter
    _currentSpeedKbps = (_emaAlpha * sampleKbps) + ((1.0 - _emaAlpha) * _currentSpeedKbps);
    _notifyUpdates();
  }

  /// Runs a lightweight non-intrusive probe (ping / small chunk) to measure actual bandwidth
  Future<double> runSpeedProbe() async {
    try {
      final stopwatch = Stopwatch()..start();
      // Use small CDN asset or fast ping endpoint to measure latency + bandwidth
      final response = await _dio.get<List<int>>(
        'https://c.saavncdn.com/artists/ARJN_000_20251212123838_50x50.jpg',
        options: Options(responseType: ResponseType.bytes),
      );
      stopwatch.stop();

      final bytes = response.data?.length ?? 0;
      final elapsedMs = max(stopwatch.elapsedMilliseconds, 20);
      final sampleKbps = (bytes * 8.0) / (elapsedMs / 1000.0 * 1000.0);

      _currentSpeedKbps = (_emaAlpha * sampleKbps) + ((1.0 - _emaAlpha) * _currentSpeedKbps);
      _notifyUpdates();
      return _currentSpeedKbps;
    } catch (e) {
      debugPrint('NetworkSpeedService: Probe note: $e');
      return _currentSpeedKbps;
    }
  }

  void _notifyUpdates() {
    if (!_speedStreamController.isClosed) {
      _speedStreamController.add(_currentSpeedKbps);
    }
    if (!_gradeStreamController.isClosed) {
      _gradeStreamController.add(currentGrade);
    }
  }

  void dispose() {
    _speedStreamController.close();
    _gradeStreamController.close();
  }
}

/// Adaptive audio quality selector: selects optimal [SongDownloadUrl] from API response.
class AdaptiveAudioQualitySelector {
  AdaptiveAudioQualitySelector._();

  /// Resolves the optimal [SongDownloadUrl] based on user preference and real-time network grade.
  static SongDownloadUrl? resolveQuality({
    required List<SongDownloadUrl> availableQualities,
    required AudioQualityPreference preference,
    required NetworkSpeedGrade currentGrade,
  }) {
    if (availableQualities.isEmpty) return null;

    // 1. Sort available qualities in ascending order of bitrate
    final sorted = List<SongDownloadUrl>.from(availableQualities)
      ..sort((a, b) => a.bitrateKbps.compareTo(b.bitrateKbps));

    // 2. Determine target bitrate
    final int targetBitrate = switch (preference) {
      AudioQualityPreference.auto => currentGrade.targetBitrateKbps,
      _ => preference.targetBitrateKbps ?? 160,
    };

    // 3. Exact match
    final exact = sorted.where((q) => q.bitrateKbps == targetBitrate).firstOrNull;
    if (exact != null) return exact;

    // 4. Closest available quality <= targetBitrate (to prevent buffering on slow networks)
    final lowerOrEqual = sorted.where((q) => q.bitrateKbps <= targetBitrate).toList();
    if (lowerOrEqual.isNotEmpty) {
      return lowerOrEqual.last; // Highest quality that fits within target
    }

    // 5. If all available are higher than target, pick the lowest available
    return sorted.first;
  }

  /// Helper to extract List<SongDownloadUrl> from dynamic JSON/extras
  static List<SongDownloadUrl> parseDownloadUrls(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      final list = <SongDownloadUrl>[];
      for (final item in raw) {
        if (item is SongDownloadUrl) {
          list.add(item);
        } else if (item is Map) {
          list.add(SongDownloadUrl.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return list.where((e) => e.url.isNotEmpty).toList();
    }
    return [];
  }
}

// ── Riverpod Providers ──

/// Singleton provider for the NetworkSpeedService
final networkSpeedServiceProvider = Provider<NetworkSpeedService>((ref) {
  final service = NetworkSpeedService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream of real-time network speed in kbps
final networkSpeedKbpsProvider = StreamProvider<double>((ref) {
  final service = ref.watch(networkSpeedServiceProvider);
  return service.speedStream;
});

/// Stream of real-time network speed grade
final networkSpeedGradeProvider = StreamProvider<NetworkSpeedGrade>((ref) {
  final service = ref.watch(networkSpeedServiceProvider);
  return service.gradeStream;
});

/// StateNotifier provider for User Audio Quality Preference
final audioQualityPreferenceProvider =
    StateNotifierProvider<AudioQualityPreferenceNotifier, AudioQualityPreference>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AudioQualityPreferenceNotifier(storage);
});

class AudioQualityPreferenceNotifier extends StateNotifier<AudioQualityPreference> {
  final StorageService _storage;

  AudioQualityPreferenceNotifier(this._storage)
      : super(AudioQualityPreference.fromCode(_storage.getString('audio_quality_preference'))) {
    // Initial sync from storage
  }

  Future<void> setPreference(AudioQualityPreference preference) async {
    state = preference;
    await _storage.setString('audio_quality_preference', preference.code);
  }
}
