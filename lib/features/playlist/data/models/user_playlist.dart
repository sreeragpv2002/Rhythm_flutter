import 'package:audio_service/audio_service.dart';
import 'package:rhythm_flutter/core/services/media_item_mapper.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';

/// Model representing a User's custom Playlist from Firestore /api/v1/user-playlists
class UserPlaylist {
  final String id;
  final String name;
  final String description;
  final bool isFavorite;
  final String userId;
  final int songCount;
  final String? image;
  final String? imageUrl;
  final String? createdAt;
  final String? updatedAt;
  final List<HomeItem> songs;

  const UserPlaylist({
    required this.id,
    required this.name,
    this.description = '',
    this.isFavorite = false,
    required this.userId,
    this.songCount = 0,
    this.image,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.songs = const [],
  });

  factory UserPlaylist.fromJson(Map<String, dynamic> json) {
    final rawSongs = json['songs'];
    final parsedSongs = <HomeItem>[];

    if (rawSongs is List) {
      for (final item in rawSongs) {
        if (item is Map<String, dynamic>) {
          parsedSongs.add(HomeItem.fromJson(item));
        }
      }
    }

    return UserPlaylist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled Playlist',
      description: json['description']?.toString() ?? '',
      isFavorite: json['is_favorite'] == true,
      userId: json['user_id']?.toString() ?? '',
      songCount: json['song_count'] is int
          ? json['song_count'] as int
          : (int.tryParse(json['song_count']?.toString() ?? '') ?? parsedSongs.length),
      image: json['image']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      songs: parsedSongs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'is_favorite': isFavorite,
    'user_id': userId,
    'song_count': songCount,
    'image': image,
    'image_url': imageUrl,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'songs': songs.map((s) => s.toJson()).toList(),
  };

  String? get displayImage => imageUrl ?? image;
  String get displayTitle => name.isNotEmpty ? name : 'My Playlist';

  List<MediaItem> toMediaItems() {
    return songs.map((s) => homeItemToMediaItem(s)).toList();
  }
}
