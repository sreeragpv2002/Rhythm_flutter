// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Music _$MusicFromJson(Map<String, dynamic> json) {
  return _Music.fromJson(json);
}

/// @nodoc
mixin _$Music {
  int get id => throw _privateConstructorUsedError;
  Map<String, String> get titles => throw _privateConstructorUsedError;
  @JsonKey(name: 'artist_names')
  List<Map<String, String>> get artistNames =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'album_titles')
  Map<String, String>? get albumTitles => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumb_url')
  String? get thumbUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'audio_url')
  String? get audioUrl => throw _privateConstructorUsedError;
  int get duration => throw _privateConstructorUsedError;
  String get language => throw _privateConstructorUsedError;
  @JsonKey(name: 'language_display')
  String get languageDisplay => throw _privateConstructorUsedError;
  List<Tag> get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'play_count')
  int get playCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_favorited')
  bool get isFavorited => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_favorite')
  bool get isFavorite => throw _privateConstructorUsedError;
  @JsonKey(name: 'related_by_album')
  List<Music>? get relatedByAlbum => throw _privateConstructorUsedError;
  @JsonKey(name: 'related_by_artist')
  List<Music>? get relatedByArtist => throw _privateConstructorUsedError;
  @JsonKey(name: 'related_by_tags')
  List<Music>? get relatedByTags => throw _privateConstructorUsedError;

  /// Serializes this Music to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Music
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MusicCopyWith<Music> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MusicCopyWith<$Res> {
  factory $MusicCopyWith(Music value, $Res Function(Music) then) =
      _$MusicCopyWithImpl<$Res, Music>;
  @useResult
  $Res call(
      {int id,
      Map<String, String> titles,
      @JsonKey(name: 'artist_names') List<Map<String, String>> artistNames,
      @JsonKey(name: 'album_titles') Map<String, String>? albumTitles,
      @JsonKey(name: 'thumb_url') String? thumbUrl,
      @JsonKey(name: 'audio_url') String? audioUrl,
      int duration,
      String language,
      @JsonKey(name: 'language_display') String languageDisplay,
      List<Tag> tags,
      @JsonKey(name: 'play_count') int playCount,
      @JsonKey(name: 'is_favorited') bool isFavorited,
      @JsonKey(name: 'is_favorite') bool isFavorite,
      @JsonKey(name: 'related_by_album') List<Music>? relatedByAlbum,
      @JsonKey(name: 'related_by_artist') List<Music>? relatedByArtist,
      @JsonKey(name: 'related_by_tags') List<Music>? relatedByTags});
}

/// @nodoc
class _$MusicCopyWithImpl<$Res, $Val extends Music>
    implements $MusicCopyWith<$Res> {
  _$MusicCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Music
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? titles = null,
    Object? artistNames = null,
    Object? albumTitles = freezed,
    Object? thumbUrl = freezed,
    Object? audioUrl = freezed,
    Object? duration = null,
    Object? language = null,
    Object? languageDisplay = null,
    Object? tags = null,
    Object? playCount = null,
    Object? isFavorited = null,
    Object? isFavorite = null,
    Object? relatedByAlbum = freezed,
    Object? relatedByArtist = freezed,
    Object? relatedByTags = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      titles: null == titles
          ? _value.titles
          : titles // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      artistNames: null == artistNames
          ? _value.artistNames
          : artistNames // ignore: cast_nullable_to_non_nullable
              as List<Map<String, String>>,
      albumTitles: freezed == albumTitles
          ? _value.albumTitles
          : albumTitles // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
      thumbUrl: freezed == thumbUrl
          ? _value.thumbUrl
          : thumbUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      audioUrl: freezed == audioUrl
          ? _value.audioUrl
          : audioUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      languageDisplay: null == languageDisplay
          ? _value.languageDisplay
          : languageDisplay // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<Tag>,
      playCount: null == playCount
          ? _value.playCount
          : playCount // ignore: cast_nullable_to_non_nullable
              as int,
      isFavorited: null == isFavorited
          ? _value.isFavorited
          : isFavorited // ignore: cast_nullable_to_non_nullable
              as bool,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      relatedByAlbum: freezed == relatedByAlbum
          ? _value.relatedByAlbum
          : relatedByAlbum // ignore: cast_nullable_to_non_nullable
              as List<Music>?,
      relatedByArtist: freezed == relatedByArtist
          ? _value.relatedByArtist
          : relatedByArtist // ignore: cast_nullable_to_non_nullable
              as List<Music>?,
      relatedByTags: freezed == relatedByTags
          ? _value.relatedByTags
          : relatedByTags // ignore: cast_nullable_to_non_nullable
              as List<Music>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MusicImplCopyWith<$Res> implements $MusicCopyWith<$Res> {
  factory _$$MusicImplCopyWith(
          _$MusicImpl value, $Res Function(_$MusicImpl) then) =
      __$$MusicImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      Map<String, String> titles,
      @JsonKey(name: 'artist_names') List<Map<String, String>> artistNames,
      @JsonKey(name: 'album_titles') Map<String, String>? albumTitles,
      @JsonKey(name: 'thumb_url') String? thumbUrl,
      @JsonKey(name: 'audio_url') String? audioUrl,
      int duration,
      String language,
      @JsonKey(name: 'language_display') String languageDisplay,
      List<Tag> tags,
      @JsonKey(name: 'play_count') int playCount,
      @JsonKey(name: 'is_favorited') bool isFavorited,
      @JsonKey(name: 'is_favorite') bool isFavorite,
      @JsonKey(name: 'related_by_album') List<Music>? relatedByAlbum,
      @JsonKey(name: 'related_by_artist') List<Music>? relatedByArtist,
      @JsonKey(name: 'related_by_tags') List<Music>? relatedByTags});
}

/// @nodoc
class __$$MusicImplCopyWithImpl<$Res>
    extends _$MusicCopyWithImpl<$Res, _$MusicImpl>
    implements _$$MusicImplCopyWith<$Res> {
  __$$MusicImplCopyWithImpl(
      _$MusicImpl _value, $Res Function(_$MusicImpl) _then)
      : super(_value, _then);

  /// Create a copy of Music
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? titles = null,
    Object? artistNames = null,
    Object? albumTitles = freezed,
    Object? thumbUrl = freezed,
    Object? audioUrl = freezed,
    Object? duration = null,
    Object? language = null,
    Object? languageDisplay = null,
    Object? tags = null,
    Object? playCount = null,
    Object? isFavorited = null,
    Object? isFavorite = null,
    Object? relatedByAlbum = freezed,
    Object? relatedByArtist = freezed,
    Object? relatedByTags = freezed,
  }) {
    return _then(_$MusicImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      titles: null == titles
          ? _value._titles
          : titles // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      artistNames: null == artistNames
          ? _value._artistNames
          : artistNames // ignore: cast_nullable_to_non_nullable
              as List<Map<String, String>>,
      albumTitles: freezed == albumTitles
          ? _value._albumTitles
          : albumTitles // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
      thumbUrl: freezed == thumbUrl
          ? _value.thumbUrl
          : thumbUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      audioUrl: freezed == audioUrl
          ? _value.audioUrl
          : audioUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      languageDisplay: null == languageDisplay
          ? _value.languageDisplay
          : languageDisplay // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<Tag>,
      playCount: null == playCount
          ? _value.playCount
          : playCount // ignore: cast_nullable_to_non_nullable
              as int,
      isFavorited: null == isFavorited
          ? _value.isFavorited
          : isFavorited // ignore: cast_nullable_to_non_nullable
              as bool,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      relatedByAlbum: freezed == relatedByAlbum
          ? _value._relatedByAlbum
          : relatedByAlbum // ignore: cast_nullable_to_non_nullable
              as List<Music>?,
      relatedByArtist: freezed == relatedByArtist
          ? _value._relatedByArtist
          : relatedByArtist // ignore: cast_nullable_to_non_nullable
              as List<Music>?,
      relatedByTags: freezed == relatedByTags
          ? _value._relatedByTags
          : relatedByTags // ignore: cast_nullable_to_non_nullable
              as List<Music>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MusicImpl extends _Music {
  const _$MusicImpl(
      {required this.id,
      required final Map<String, String> titles,
      @JsonKey(name: 'artist_names')
      required final List<Map<String, String>> artistNames,
      @JsonKey(name: 'album_titles') final Map<String, String>? albumTitles,
      @JsonKey(name: 'thumb_url') this.thumbUrl,
      @JsonKey(name: 'audio_url') this.audioUrl,
      required this.duration,
      required this.language,
      @JsonKey(name: 'language_display') required this.languageDisplay,
      final List<Tag> tags = const [],
      @JsonKey(name: 'play_count') this.playCount = 0,
      @JsonKey(name: 'is_favorited') this.isFavorited = false,
      @JsonKey(name: 'is_favorite') this.isFavorite = false,
      @JsonKey(name: 'related_by_album') final List<Music>? relatedByAlbum,
      @JsonKey(name: 'related_by_artist') final List<Music>? relatedByArtist,
      @JsonKey(name: 'related_by_tags') final List<Music>? relatedByTags})
      : _titles = titles,
        _artistNames = artistNames,
        _albumTitles = albumTitles,
        _tags = tags,
        _relatedByAlbum = relatedByAlbum,
        _relatedByArtist = relatedByArtist,
        _relatedByTags = relatedByTags,
        super._();

  factory _$MusicImpl.fromJson(Map<String, dynamic> json) =>
      _$$MusicImplFromJson(json);

  @override
  final int id;
  final Map<String, String> _titles;
  @override
  Map<String, String> get titles {
    if (_titles is EqualUnmodifiableMapView) return _titles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_titles);
  }

  final List<Map<String, String>> _artistNames;
  @override
  @JsonKey(name: 'artist_names')
  List<Map<String, String>> get artistNames {
    if (_artistNames is EqualUnmodifiableListView) return _artistNames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_artistNames);
  }

  final Map<String, String>? _albumTitles;
  @override
  @JsonKey(name: 'album_titles')
  Map<String, String>? get albumTitles {
    final value = _albumTitles;
    if (value == null) return null;
    if (_albumTitles is EqualUnmodifiableMapView) return _albumTitles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'thumb_url')
  final String? thumbUrl;
  @override
  @JsonKey(name: 'audio_url')
  final String? audioUrl;
  @override
  final int duration;
  @override
  final String language;
  @override
  @JsonKey(name: 'language_display')
  final String languageDisplay;
  final List<Tag> _tags;
  @override
  @JsonKey()
  List<Tag> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey(name: 'play_count')
  final int playCount;
  @override
  @JsonKey(name: 'is_favorited')
  final bool isFavorited;
  @override
  @JsonKey(name: 'is_favorite')
  final bool isFavorite;
  final List<Music>? _relatedByAlbum;
  @override
  @JsonKey(name: 'related_by_album')
  List<Music>? get relatedByAlbum {
    final value = _relatedByAlbum;
    if (value == null) return null;
    if (_relatedByAlbum is EqualUnmodifiableListView) return _relatedByAlbum;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Music>? _relatedByArtist;
  @override
  @JsonKey(name: 'related_by_artist')
  List<Music>? get relatedByArtist {
    final value = _relatedByArtist;
    if (value == null) return null;
    if (_relatedByArtist is EqualUnmodifiableListView) return _relatedByArtist;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Music>? _relatedByTags;
  @override
  @JsonKey(name: 'related_by_tags')
  List<Music>? get relatedByTags {
    final value = _relatedByTags;
    if (value == null) return null;
    if (_relatedByTags is EqualUnmodifiableListView) return _relatedByTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'Music(id: $id, titles: $titles, artistNames: $artistNames, albumTitles: $albumTitles, thumbUrl: $thumbUrl, audioUrl: $audioUrl, duration: $duration, language: $language, languageDisplay: $languageDisplay, tags: $tags, playCount: $playCount, isFavorited: $isFavorited, isFavorite: $isFavorite, relatedByAlbum: $relatedByAlbum, relatedByArtist: $relatedByArtist, relatedByTags: $relatedByTags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MusicImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._titles, _titles) &&
            const DeepCollectionEquality()
                .equals(other._artistNames, _artistNames) &&
            const DeepCollectionEquality()
                .equals(other._albumTitles, _albumTitles) &&
            (identical(other.thumbUrl, thumbUrl) ||
                other.thumbUrl == thumbUrl) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.languageDisplay, languageDisplay) ||
                other.languageDisplay == languageDisplay) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.playCount, playCount) ||
                other.playCount == playCount) &&
            (identical(other.isFavorited, isFavorited) ||
                other.isFavorited == isFavorited) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            const DeepCollectionEquality()
                .equals(other._relatedByAlbum, _relatedByAlbum) &&
            const DeepCollectionEquality()
                .equals(other._relatedByArtist, _relatedByArtist) &&
            const DeepCollectionEquality()
                .equals(other._relatedByTags, _relatedByTags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_titles),
      const DeepCollectionEquality().hash(_artistNames),
      const DeepCollectionEquality().hash(_albumTitles),
      thumbUrl,
      audioUrl,
      duration,
      language,
      languageDisplay,
      const DeepCollectionEquality().hash(_tags),
      playCount,
      isFavorited,
      isFavorite,
      const DeepCollectionEquality().hash(_relatedByAlbum),
      const DeepCollectionEquality().hash(_relatedByArtist),
      const DeepCollectionEquality().hash(_relatedByTags));

  /// Create a copy of Music
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MusicImplCopyWith<_$MusicImpl> get copyWith =>
      __$$MusicImplCopyWithImpl<_$MusicImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MusicImplToJson(
      this,
    );
  }
}

abstract class _Music extends Music {
  const factory _Music(
      {required final int id,
      required final Map<String, String> titles,
      @JsonKey(name: 'artist_names')
      required final List<Map<String, String>> artistNames,
      @JsonKey(name: 'album_titles') final Map<String, String>? albumTitles,
      @JsonKey(name: 'thumb_url') final String? thumbUrl,
      @JsonKey(name: 'audio_url') final String? audioUrl,
      required final int duration,
      required final String language,
      @JsonKey(name: 'language_display') required final String languageDisplay,
      final List<Tag> tags,
      @JsonKey(name: 'play_count') final int playCount,
      @JsonKey(name: 'is_favorited') final bool isFavorited,
      @JsonKey(name: 'is_favorite') final bool isFavorite,
      @JsonKey(name: 'related_by_album') final List<Music>? relatedByAlbum,
      @JsonKey(name: 'related_by_artist') final List<Music>? relatedByArtist,
      @JsonKey(name: 'related_by_tags')
      final List<Music>? relatedByTags}) = _$MusicImpl;
  const _Music._() : super._();

  factory _Music.fromJson(Map<String, dynamic> json) = _$MusicImpl.fromJson;

  @override
  int get id;
  @override
  Map<String, String> get titles;
  @override
  @JsonKey(name: 'artist_names')
  List<Map<String, String>> get artistNames;
  @override
  @JsonKey(name: 'album_titles')
  Map<String, String>? get albumTitles;
  @override
  @JsonKey(name: 'thumb_url')
  String? get thumbUrl;
  @override
  @JsonKey(name: 'audio_url')
  String? get audioUrl;
  @override
  int get duration;
  @override
  String get language;
  @override
  @JsonKey(name: 'language_display')
  String get languageDisplay;
  @override
  List<Tag> get tags;
  @override
  @JsonKey(name: 'play_count')
  int get playCount;
  @override
  @JsonKey(name: 'is_favorited')
  bool get isFavorited;
  @override
  @JsonKey(name: 'is_favorite')
  bool get isFavorite;
  @override
  @JsonKey(name: 'related_by_album')
  List<Music>? get relatedByAlbum;
  @override
  @JsonKey(name: 'related_by_artist')
  List<Music>? get relatedByArtist;
  @override
  @JsonKey(name: 'related_by_tags')
  List<Music>? get relatedByTags;

  /// Create a copy of Music
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MusicImplCopyWith<_$MusicImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
