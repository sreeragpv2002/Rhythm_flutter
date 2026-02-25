class Artist {
  final int id;
  final String name;
  final String? image;
  final String? imageUrl;

  Artist({
    required this.id,
    required this.name,
    this.image,
    this.imageUrl,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'image_url': imageUrl,
    };
  }
}
