import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_flutter/core/services/storage_service.dart';
import 'package:rhythm_flutter/features/home/providers/home_provider.dart';
import 'package:rhythm_flutter/features/language/data/models/language_model.dart';
import 'package:rhythm_flutter/features/language/data/repositories/language_repository.dart';

class LanguageState {
  final List<LanguageModel> availableLanguages;
  final List<String> selectedLanguages;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const LanguageState({
    this.availableLanguages = const [],
    this.selectedLanguages = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  LanguageState copyWith({
    List<LanguageModel>? availableLanguages,
    List<String>? selectedLanguages,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return LanguageState(
      availableLanguages: availableLanguages ?? this.availableLanguages,
      selectedLanguages: selectedLanguages ?? this.selectedLanguages,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  final repo = ref.watch(languageRepositoryProvider);
  final storage = ref.watch(storageServiceProvider);
  return LanguageNotifier(repo, storage, ref);
});

class LanguageNotifier extends StateNotifier<LanguageState> {
  final LanguageRepository _repo;
  final StorageService _storage;
  final Ref _ref;

  LanguageNotifier(this._repo, this._storage, this._ref)
      : super(const LanguageState()) {
    init();
  }

  String get effectiveUserId {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid != null && firebaseUid.isNotEmpty) return firebaseUid;

    final storedId = _storage.currentUserId;
    if (storedId != null && storedId.isNotEmpty) return storedId;

    return 'dZnjYn0Ku1X9vleSQYmyczZvcLL2';
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final available = await _repo.getAvailableLanguages();

      // Check local storage first
      var userLangs = _storage.userLanguages;
      final bool alreadySetLocally = _storage.hasSetLanguages && userLangs.isNotEmpty;

      // If not set locally, attempt fetching from user endpoint
      if (!alreadySetLocally) {
        final serverLangs = await _repo.getUserLanguages(effectiveUserId);
        if (serverLangs.isNotEmpty) {
          userLangs = serverLangs;
          await _storage.setUserLanguages(serverLangs);
          await _storage.setHasSetLanguages(true);
        }
      }

      // Default fallback selections if still empty
      if (userLangs.isEmpty) {
        userLangs = ['malayalam', 'tamil', 'english'];
      }

      state = state.copyWith(
        availableLanguages: available,
        selectedLanguages: userLangs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        availableLanguages: LanguageModel.defaultSupportedLanguages(),
        selectedLanguages: _storage.userLanguages.isNotEmpty
            ? _storage.userLanguages
            : ['malayalam', 'tamil', 'english'],
        isLoading: false,
      );
    }
  }

  void toggleLanguage(String code) {
    final lower = code.toLowerCase().trim();
    final current = List<String>.from(state.selectedLanguages);

    if (current.contains(lower)) {
      if (current.length > 1) {
        current.remove(lower);
      }
    } else {
      current.add(lower);
    }

    state = state.copyWith(selectedLanguages: current);
  }

  void setLanguages(List<String> codes) {
    state = state.copyWith(
      selectedLanguages:
          codes.map((e) => e.toLowerCase().trim()).toList(),
    );
  }

  /// Save preferences via POST /api/v1/languages/user and refresh home feed
  Future<bool> savePreferences([List<String>? overrideCodes]) async {
    final toSave = overrideCodes ?? state.selectedLanguages;
    if (toSave.isEmpty) return false;

    state = state.copyWith(isSaving: true, error: null);

    try {
      final success = await _repo.saveUserLanguages(
        userId: effectiveUserId,
        languages: toSave,
      );

      await _storage.setUserLanguages(toSave);
      await _storage.setHasSetLanguages(true);

      state = state.copyWith(
        selectedLanguages: toSave,
        isSaving: false,
      );

      // Invalidate and refresh home feed to reflect new language selections
      _ref.read(homeProvider.notifier).fetchHomeFeed();

      return success;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return false;
    }
  }
}
