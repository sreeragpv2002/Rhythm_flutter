class ProfileRequest {
  final String language;
  final String profileImage;
  final String bio;
  final List<int> favoriteArtists;
  final String listeningPreferences;

  ProfileRequest({
    required this.language,
    required this.profileImage,
    required this.bio,
    required this.favoriteArtists,
    required this.listeningPreferences,
  });

  Map<String, dynamic> toJson() {
    return {
      "language": language,
      "profile_image": profileImage,
      "bio": bio,
      "favorite_artists": favoriteArtists,
      "listening_preferences": listeningPreferences,
    };
  }
}
