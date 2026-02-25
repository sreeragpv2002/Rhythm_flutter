// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_feed.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HomeSection _$HomeSectionFromJson(Map<String, dynamic> json) {
  return _HomeSection.fromJson(json);
}

/// @nodoc
mixin _$HomeSection {
  String get title => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  List<int> get items => throw _privateConstructorUsedError;

  /// Serializes this HomeSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HomeSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HomeSectionCopyWith<HomeSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeSectionCopyWith<$Res> {
  factory $HomeSectionCopyWith(
          HomeSection value, $Res Function(HomeSection) then) =
      _$HomeSectionCopyWithImpl<$Res, HomeSection>;
  @useResult
  $Res call({String title, String slug, List<int> items});
}

/// @nodoc
class _$HomeSectionCopyWithImpl<$Res, $Val extends HomeSection>
    implements $HomeSectionCopyWith<$Res> {
  _$HomeSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HomeSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? slug = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HomeSectionImplCopyWith<$Res>
    implements $HomeSectionCopyWith<$Res> {
  factory _$$HomeSectionImplCopyWith(
          _$HomeSectionImpl value, $Res Function(_$HomeSectionImpl) then) =
      __$$HomeSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String title, String slug, List<int> items});
}

/// @nodoc
class __$$HomeSectionImplCopyWithImpl<$Res>
    extends _$HomeSectionCopyWithImpl<$Res, _$HomeSectionImpl>
    implements _$$HomeSectionImplCopyWith<$Res> {
  __$$HomeSectionImplCopyWithImpl(
      _$HomeSectionImpl _value, $Res Function(_$HomeSectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of HomeSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? slug = null,
    Object? items = null,
  }) {
    return _then(_$HomeSectionImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HomeSectionImpl implements _HomeSection {
  const _$HomeSectionImpl(
      {required this.title, required this.slug, required final List<int> items})
      : _items = items;

  factory _$HomeSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$HomeSectionImplFromJson(json);

  @override
  final String title;
  @override
  final String slug;
  final List<int> _items;
  @override
  List<int> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'HomeSection(title: $title, slug: $slug, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeSectionImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, title, slug, const DeepCollectionEquality().hash(_items));

  /// Create a copy of HomeSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeSectionImplCopyWith<_$HomeSectionImpl> get copyWith =>
      __$$HomeSectionImplCopyWithImpl<_$HomeSectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HomeSectionImplToJson(
      this,
    );
  }
}

abstract class _HomeSection implements HomeSection {
  const factory _HomeSection(
      {required final String title,
      required final String slug,
      required final List<int> items}) = _$HomeSectionImpl;

  factory _HomeSection.fromJson(Map<String, dynamic> json) =
      _$HomeSectionImpl.fromJson;

  @override
  String get title;
  @override
  String get slug;
  @override
  List<int> get items;

  /// Create a copy of HomeSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HomeSectionImplCopyWith<_$HomeSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HomeFeed _$HomeFeedFromJson(Map<String, dynamic> json) {
  return _HomeFeed.fromJson(json);
}

/// @nodoc
mixin _$HomeFeed {
  List<HomeSection> get sections => throw _privateConstructorUsedError;
  @JsonKey(name: 'music_map')
  Map<String, Music> get musicMap => throw _privateConstructorUsedError;

  /// Serializes this HomeFeed to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HomeFeed
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HomeFeedCopyWith<HomeFeed> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeFeedCopyWith<$Res> {
  factory $HomeFeedCopyWith(HomeFeed value, $Res Function(HomeFeed) then) =
      _$HomeFeedCopyWithImpl<$Res, HomeFeed>;
  @useResult
  $Res call(
      {List<HomeSection> sections,
      @JsonKey(name: 'music_map') Map<String, Music> musicMap});
}

/// @nodoc
class _$HomeFeedCopyWithImpl<$Res, $Val extends HomeFeed>
    implements $HomeFeedCopyWith<$Res> {
  _$HomeFeedCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HomeFeed
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sections = null,
    Object? musicMap = null,
  }) {
    return _then(_value.copyWith(
      sections: null == sections
          ? _value.sections
          : sections // ignore: cast_nullable_to_non_nullable
              as List<HomeSection>,
      musicMap: null == musicMap
          ? _value.musicMap
          : musicMap // ignore: cast_nullable_to_non_nullable
              as Map<String, Music>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HomeFeedImplCopyWith<$Res>
    implements $HomeFeedCopyWith<$Res> {
  factory _$$HomeFeedImplCopyWith(
          _$HomeFeedImpl value, $Res Function(_$HomeFeedImpl) then) =
      __$$HomeFeedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<HomeSection> sections,
      @JsonKey(name: 'music_map') Map<String, Music> musicMap});
}

/// @nodoc
class __$$HomeFeedImplCopyWithImpl<$Res>
    extends _$HomeFeedCopyWithImpl<$Res, _$HomeFeedImpl>
    implements _$$HomeFeedImplCopyWith<$Res> {
  __$$HomeFeedImplCopyWithImpl(
      _$HomeFeedImpl _value, $Res Function(_$HomeFeedImpl) _then)
      : super(_value, _then);

  /// Create a copy of HomeFeed
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sections = null,
    Object? musicMap = null,
  }) {
    return _then(_$HomeFeedImpl(
      sections: null == sections
          ? _value._sections
          : sections // ignore: cast_nullable_to_non_nullable
              as List<HomeSection>,
      musicMap: null == musicMap
          ? _value._musicMap
          : musicMap // ignore: cast_nullable_to_non_nullable
              as Map<String, Music>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HomeFeedImpl implements _HomeFeed {
  const _$HomeFeedImpl(
      {required final List<HomeSection> sections,
      @JsonKey(name: 'music_map') required final Map<String, Music> musicMap})
      : _sections = sections,
        _musicMap = musicMap;

  factory _$HomeFeedImpl.fromJson(Map<String, dynamic> json) =>
      _$$HomeFeedImplFromJson(json);

  final List<HomeSection> _sections;
  @override
  List<HomeSection> get sections {
    if (_sections is EqualUnmodifiableListView) return _sections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sections);
  }

  final Map<String, Music> _musicMap;
  @override
  @JsonKey(name: 'music_map')
  Map<String, Music> get musicMap {
    if (_musicMap is EqualUnmodifiableMapView) return _musicMap;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_musicMap);
  }

  @override
  String toString() {
    return 'HomeFeed(sections: $sections, musicMap: $musicMap)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeFeedImpl &&
            const DeepCollectionEquality().equals(other._sections, _sections) &&
            const DeepCollectionEquality().equals(other._musicMap, _musicMap));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_sections),
      const DeepCollectionEquality().hash(_musicMap));

  /// Create a copy of HomeFeed
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeFeedImplCopyWith<_$HomeFeedImpl> get copyWith =>
      __$$HomeFeedImplCopyWithImpl<_$HomeFeedImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HomeFeedImplToJson(
      this,
    );
  }
}

abstract class _HomeFeed implements HomeFeed {
  const factory _HomeFeed(
      {required final List<HomeSection> sections,
      @JsonKey(name: 'music_map')
      required final Map<String, Music> musicMap}) = _$HomeFeedImpl;

  factory _HomeFeed.fromJson(Map<String, dynamic> json) =
      _$HomeFeedImpl.fromJson;

  @override
  List<HomeSection> get sections;
  @override
  @JsonKey(name: 'music_map')
  Map<String, Music> get musicMap;

  /// Create a copy of HomeFeed
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HomeFeedImplCopyWith<_$HomeFeedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
