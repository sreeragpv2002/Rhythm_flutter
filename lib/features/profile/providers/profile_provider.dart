import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rhythm_flutter/core/services/storage_service.dart';
import 'package:rhythm_flutter/features/auth/providers/auth_provider.dart';
import 'package:rhythm_flutter/features/profile/data/models/artist.dart';
import 'package:rhythm_flutter/features/profile/data/models/language.dart';
import 'package:rhythm_flutter/features/profile/data/models/profile_request.dart';
import 'package:rhythm_flutter/features/profile/data/repositories/profile_repository.dart';

part 'profile_provider.freezed.dart';
part 'profile_provider.g.dart';

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default('') String displayName,
    @Default('') String bio,
    @Default('') String listeningPreferences,
    @Default([]) List<Artist> artists,
    @Default([]) List<Language> languages,
    @Default([]) List<int> selectedArtistIds,
    String? selectedLanguageCode,
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    @Default(false) bool hasProfile,
    String? error,
  }) = _ProfileState;
}

@riverpod
class Profile extends _$Profile {
  late ProfileRepository _repository;
  late StorageService _storage;

  @override
  FutureOr<ProfileState> build() async {
    _repository = ref.watch(profileRepositoryProvider);
    _storage = ref.watch(storageServiceProvider);
    
    return _init();
  }

  Future<ProfileState> _init() async {
    final hasProfile = _storage.hasProfile;
    final displayName = _storage.userEmail?.split('@').first ?? ''; // Fallback for name
    
    // Fetch initial data (artists, languages)
    final results = await Future.wait([
      _repository.getArtists(),
      _repository.getLanguages(),
    ]);

    return ProfileState(
      displayName: hasProfile ? displayName : '',
      artists: results[0] as List<Artist>,
      languages: results[1] as List<Language>,
      hasProfile: hasProfile,
    );
  }

  void toggleArtist(int id) {
    if (state.value == null) return;
    final currentIds = List<int>.from(state.value!.selectedArtistIds);
    if (currentIds.contains(id)) {
      currentIds.remove(id);
    } else {
      currentIds.add(id);
    }
    state = AsyncData(state.value!.copyWith(selectedArtistIds: currentIds));
  }

  void setLanguage(String code) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(selectedLanguageCode: code));
  }

  Future<void> saveProfile(String displayName, String bio, String listeningPreferences) async {
    if (state.value == null) return;
    final currentState = state.value!;

    if (currentState.selectedLanguageCode == null) {
      state = AsyncData(currentState.copyWith(error: 'Please select a language'));
      return;
    }

    state = AsyncData(currentState.copyWith(isSaving: true, error: null));

    try {
      final request = ProfileRequest(
        language: currentState.selectedLanguageCode!,
        profileImage: "",
        bio: bio,
        favoriteArtists: currentState.selectedArtistIds,
        listeningPreferences: listeningPreferences,
      );

      final success = await _repository.updateProfile(request);

      if (success) {
        await _storage.setHasProfile(true);
        // We could store name/bio in StorageService too if needed for offline
        
        state = AsyncData(currentState.copyWith(
          displayName: displayName,
          bio: bio,
          listeningPreferences: listeningPreferences,
          isSaving: false,
          hasProfile: true,
        ));

        // Update auth state so the router navigates to home
        ref.read(authProvider.notifier).setHasProfile(true);
      } else {
        state = AsyncData(currentState.copyWith(isSaving: false, error: 'Failed to update profile'));
      }
    } catch (e) {
      state = AsyncData(currentState.copyWith(
        isSaving: false,
        error: e.toString(),
      ));
    }
  }

  void markProfileDone() {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(hasProfile: true));
    ref.read(authProvider.notifier).setHasProfile(true);
  }
}
