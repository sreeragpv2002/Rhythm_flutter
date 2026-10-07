import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/services/storage_service.dart';
import 'package:rhythm_flutter/features/home/data/models/home_feed.dart';
import 'package:rhythm_flutter/features/home/data/repositories/music_repository.dart';
import 'package:rhythm_flutter/features/home/providers/home_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SectionSongsState — immutable state for a section's paginated item list
// ─────────────────────────────────────────────────────────────────────────────

class SectionSongsState {
  final List<HomeItem> items;
  final bool isLoadingMore;
  final bool hasMore;
  final int pageIndex; // which language page we are on
  final String? error;

  const SectionSongsState({
    this.items = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.pageIndex = 0,
    this.error,
  });

  SectionSongsState copyWith({
    List<HomeItem>? items,
    bool? isLoadingMore,
    bool? hasMore,
    int? pageIndex,
    String? error,
  }) {
    return SectionSongsState(
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      pageIndex: pageIndex ?? this.pageIndex,
      error: error,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SectionSongsNotifier
// ─────────────────────────────────────────────────────────────────────────────

class SectionSongsNotifier
    extends StateNotifier<AsyncValue<SectionSongsState>> {
  final String slugOrTitle;
  final MusicRepository _musicRepo;
  final StorageService _storage;
  final Ref _ref;

  static const int _pageSize = 50;
  static const List<String> _defaultLanguages = ['english', 'malayalam', 'tamil'];

  /// Each entry represents one "page": { query, language? }
  /// Page 0 = broad (no lang filter), Pages 1-N = one language each
  late final List<Map<String, String?>> _queryPages;

  SectionSongsNotifier({
    required this.slugOrTitle,
    required MusicRepository musicRepo,
    required StorageService storage,
    required Ref ref,
  })  : _musicRepo = musicRepo,
        _storage = storage,
        _ref = ref,
        super(const AsyncValue.loading()) {
    _initQueryPages();
    _initialFetch();
  }

  List<String> get _effectiveLanguages {
    final stored = _storage.userLanguages;
    return stored.isNotEmpty ? stored : _defaultLanguages;
  }

  bool get _isPlaylistSection {
    final n = slugOrTitle.toLowerCase().trim();
    return n == 'featured_playlists' ||
        n == 'playlists' ||
        n.contains('playlist');
  }

  String get _baseQuery {
    final n = slugOrTitle.toLowerCase().trim();
    if (_isPlaylistSection) {
      return n == 'featured_playlists'
          ? 'trending'
          : slugOrTitle.replaceAll('_', ' ');
    }
    if (n.isEmpty ||
        n == 'trending_songs' ||
        n.contains('trending') ||
        n == 'top trending') {
      return 'top trending';
    }
    if (n.contains('recent')) return 'top trending';
    return slugOrTitle.replaceAll('_', ' ');
  }

  void _initQueryPages() {
    final langs = _effectiveLanguages;
    final base = _baseQuery;
    _queryPages = [
      {'query': base, 'language': null},
      ...langs.map((l) => {'query': base, 'language': l}),
    ];
  }

  Future<void> _initialFetch() async {
    try {
      final items = await _fetchPage(0);
      state = AsyncValue.data(SectionSongsState(
        items: items,
        isLoadingMore: false,
        hasMore: _queryPages.length > 1 && items.length >= _pageSize,
        pageIndex: 1,
      ));
    } catch (e, st) {
      // Fallback to home feed cache
      final homeFeed = _ref.read(homeProvider).valueOrNull;
      if (homeFeed != null) {
        final n = slugOrTitle.toLowerCase().trim();
        final section = homeFeed.sections.firstWhere(
          (s) => s.slug == slugOrTitle || s.title.toLowerCase() == n,
          orElse: () =>
              HomeSection(title: slugOrTitle, slug: slugOrTitle, items: []),
        );
        if (section.items.isNotEmpty) {
          state = AsyncValue.data(SectionSongsState(
            items: section.items,
            isLoadingMore: false,
            hasMore: false,
            pageIndex: 1,
          ));
          return;
        }
      }
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<HomeItem>> _fetchPage(int pageIndex) async {
    if (pageIndex >= _queryPages.length) return [];

    final page = _queryPages[pageIndex];
    final query = page['query'] ?? _baseQuery;
    final language = page['language'];

    if (_isPlaylistSection) {
      return _musicRepo.getPlaylistsByQuery(
        query: query,
        limit: _pageSize,
        language: language,
      );
    } else {
      return _musicRepo.getSongsByQuery(
        query: query,
        limit: _pageSize,
        language: language,
      );
    }
  }

  Future<void> fetchMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.isLoadingMore) return;
    if (!current.hasMore) return;

    final nextPage = current.pageIndex;
    if (nextPage >= _queryPages.length) {
      state = AsyncValue.data(current.copyWith(hasMore: false));
      return;
    }

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    try {
      final newItems = await _fetchPage(nextPage);
      final existingIds = current.items.map((i) => i.id).toSet();
      final deduped =
          newItems.where((i) => !existingIds.contains(i.id)).toList();
      final updatedItems = [...current.items, ...deduped];
      final nextIndex = nextPage + 1;
      final hasMore =
          nextIndex < _queryPages.length && newItems.length >= _pageSize;

      state = AsyncValue.data(SectionSongsState(
        items: updatedItems,
        isLoadingMore: false,
        hasMore: hasMore,
        pageIndex: nextIndex,
      ));
    } catch (e) {
      debugPrint(
          'SectionSongsNotifier: Error fetching page $nextPage: $e');
      state = AsyncValue.data(
          current.copyWith(isLoadingMore: false, hasMore: false));
    }
  }

  void retry() {
    state = const AsyncValue.loading();
    _initQueryPages();
    _initialFetch();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider Family
// ─────────────────────────────────────────────────────────────────────────────

final sectionSongsNotifierProvider = StateNotifierProvider.autoDispose
    .family<SectionSongsNotifier, AsyncValue<SectionSongsState>, String>(
  (ref, slugOrTitle) {
    final musicRepo = ref.watch(musicRepositoryProvider);
    final storage = ref.watch(storageServiceProvider);
    return SectionSongsNotifier(
      slugOrTitle: slugOrTitle,
      musicRepo: musicRepo,
      storage: storage,
      ref: ref,
    );
  },
);
