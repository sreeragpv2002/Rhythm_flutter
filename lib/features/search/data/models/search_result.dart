import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';

/// Model representing search response from GET /api/v1/search?query=...&limit=...
class SearchResult {
  final String query;
  final List<HomeItem> topQuery;
  final List<HomeItem> songs;
  final List<HomeItem> albums;
  final List<HomeItem> artists;
  final List<HomeItem> playlists;

  const SearchResult({
    this.query = '',
    this.topQuery = const [],
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
  });

  bool get isEmpty =>
      topQuery.isEmpty &&
      songs.isEmpty &&
      albums.isEmpty &&
      artists.isEmpty &&
      playlists.isEmpty;

  bool get isNotEmpty => !isEmpty;

  int get totalCount =>
      topQuery.length +
      songs.length +
      albums.length +
      artists.length +
      playlists.length;

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'] ?? json;
    final Map<String, dynamic> data =
        rawData is Map<String, dynamic> ? rawData : <String, dynamic>{};

    return SearchResult(
      query: json['query']?.toString() ?? '',
      topQuery: _parseList(data['top_query'] ?? data['topQuery']),
      songs: _parseList(data['songs']),
      albums: _parseList(data['albums']),
      artists: _parseList(data['artists']),
      playlists: _parseList(data['playlists']),
    );
  }

  static List<HomeItem> _parseList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => HomeItem.fromJson(e))
          .toList();
    }
    return const [];
  }

  Map<String, dynamic> toJson() => {
        'query': query,
        'data': {
          'top_query': topQuery.map((e) => e.toJson()).toList(),
          'songs': songs.map((e) => e.toJson()).toList(),
          'albums': albums.map((e) => e.toJson()).toList(),
          'artists': artists.map((e) => e.toJson()).toList(),
          'playlists': playlists.map((e) => e.toJson()).toList(),
        }
      };
}
