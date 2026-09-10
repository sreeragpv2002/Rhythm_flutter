/// Model representing a language from GET /api/v1/languages
class LanguageModel {
  final String id;
  final String name;
  final String title;
  final String? image;
  final String? imageUrl;
  final String? nativeTitle;

  const LanguageModel({
    required this.id,
    required this.name,
    required this.title,
    this.image,
    this.imageUrl,
    this.nativeTitle,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['language'] ?? json['code'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final name = (json['name'] ?? json['title'] ?? id).toString().trim();
    final title = (json['title'] ?? name).toString().trim();

    return LanguageModel(
      id: id,
      name: name,
      title: title,
      image: json['image']?.toString(),
      imageUrl: json['image_url']?.toString(),
      nativeTitle: json['native_title']?.toString() ?? _defaultNative(id),
    );
  }

  factory LanguageModel.fromCode(String code) {
    final lower = code.toLowerCase().trim();
    final defaults = defaultSupportedLanguages();
    final match = defaults.where((l) => l.id.toLowerCase() == lower).firstOrNull;
    if (match != null) return match;

    final formattedName = lower.isEmpty
        ? ''
        : '${lower[0].toUpperCase()}${lower.substring(1)}';
    return LanguageModel(
      id: lower,
      name: formattedName,
      title: formattedName,
      nativeTitle: _defaultNative(lower),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'image': image,
        'image_url': imageUrl,
        if (nativeTitle != null) 'native_title': nativeTitle,
      };

  String get displayTitle => title.isNotEmpty ? title : name;
  String? get displayImage => imageUrl ?? image;

  static String? _defaultNative(String id) {
    switch (id.toLowerCase()) {
      case 'malayalam':
        return 'മലയാളം';
      case 'tamil':
        return 'தமிழ்';
      case 'hindi':
        return 'हिंदी';
      case 'telugu':
        return 'తెలుగు';
      case 'kannada':
        return 'ಕನ್ನಡ';
      case 'punjabi':
        return 'ਪੰਜਾਬੀ';
      case 'bengali':
        return 'বাংলা';
      case 'gujarati':
        return 'ગુજરાતી';
      case 'marathi':
        return 'मराठी';
      case 'english':
        return 'English';
      default:
        return null;
    }
  }

  static List<LanguageModel> defaultSupportedLanguages() {
    return const [
      LanguageModel(
        id: 'malayalam',
        name: 'Malayalam',
        title: 'Malayalam',
        nativeTitle: 'മലയാളം',
        image: 'https://c.saavncdn.com/editorial/charts_Malayalam2000s_160867_20240408063713_500x500.jpg',
        imageUrl: 'https://c.saavncdn.com/editorial/charts_Malayalam2000s_160867_20240408063713_500x500.jpg',
      ),
      LanguageModel(
        id: 'tamil',
        name: 'Tamil',
        title: 'Tamil',
        nativeTitle: 'தமிழ்',
        image: 'https://c.saavncdn.com/editorial/charts_Tamil1990s_190250_20240408062124_500x500.jpg',
        imageUrl: 'https://c.saavncdn.com/editorial/charts_Tamil1990s_190250_20240408062124_500x500.jpg',
      ),
      LanguageModel(
        id: 'english',
        name: 'English',
        title: 'English',
        nativeTitle: 'English',
        image: 'https://c.saavncdn.com/editorial/charts_English2010s_178363_20240408065247_500x500.jpg',
        imageUrl: 'https://c.saavncdn.com/editorial/charts_English2010s_178363_20240408065247_500x500.jpg',
      ),
      LanguageModel(
        id: 'hindi',
        name: 'Hindi',
        title: 'Hindi',
        nativeTitle: 'हिंदी',
        image: 'https://c.saavncdn.com/editorial/charts_Hindi1990s_160453_20240408064434_500x500.jpg',
        imageUrl: 'https://c.saavncdn.com/editorial/charts_Hindi1990s_160453_20240408064434_500x500.jpg',
      ),
      LanguageModel(
        id: 'telugu',
        name: 'Telugu',
        title: 'Telugu',
        nativeTitle: 'తెలుగు',
        image: 'https://c.saavncdn.com/editorial/charts_Telugu2000s_160855_20240408063852_500x500.jpg',
        imageUrl: 'https://c.saavncdn.com/editorial/charts_Telugu2000s_160855_20240408063852_500x500.jpg',
      ),
      LanguageModel(
        id: 'kannada',
        name: 'Kannada',
        title: 'Kannada',
        nativeTitle: 'ಕನ್ನಡ',
        image: 'https://c.saavncdn.com/editorial/charts_Kannada2000s_160861_20240408064115_500x500.jpg',
        imageUrl: 'https://c.saavncdn.com/editorial/charts_Kannada2000s_160861_20240408064115_500x500.jpg',
      ),
      LanguageModel(
        id: 'punjabi',
        name: 'Punjabi',
        title: 'Punjabi',
        nativeTitle: 'ਪੰਜਾਬੀ',
        image: 'https://c.saavncdn.com/editorial/charts_Punjabi2010s_178369_20240408064718_500x500.jpg',
        imageUrl: 'https://c.saavncdn.com/editorial/charts_Punjabi2010s_178369_20240408064718_500x500.jpg',
      ),
    ];
  }
}
