import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rhythm_flutter/core/constants/app_constants.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized in main.dart');
});

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Auth
  bool get isLoggedIn => _prefs.getBool(AppConstants.isLoggedInKey) ?? false;
  Future<void> setLoggedIn(bool value) => _prefs.setBool(AppConstants.isLoggedInKey, value);

  String? get accessToken => _prefs.getString(AppConstants.accessTokenKey);
  Future<void> setAccessToken(String? value) => value != null 
    ? _prefs.setString(AppConstants.accessTokenKey, value)
    : _prefs.remove(AppConstants.accessTokenKey);

  String? get refreshToken => _prefs.getString(AppConstants.refreshTokenKey);
  Future<void> setRefreshToken(String? value) => value != null 
    ? _prefs.setString(AppConstants.refreshTokenKey, value)
    : _prefs.remove(AppConstants.refreshTokenKey);

  bool get hasProfile => _prefs.getBool(AppConstants.hasProfileKey) ?? false;
  Future<void> setHasProfile(bool value) => _prefs.setBool(AppConstants.hasProfileKey, value);

  String? get userEmail => _prefs.getString('user_email');
  Future<void> setUserEmail(String? value) => value != null 
    ? _prefs.setString('user_email', value)
    : _prefs.remove('user_email');

  // Languages (tracks whether user has explicitly selected/updated music languages)
  bool get hasSetLanguages => _prefs.getBool('has_updated_languages_v2') ?? false;
  Future<void> setHasSetLanguages(bool value) => _prefs.setBool('has_updated_languages_v2', value);

  List<String> get userLanguages => _prefs.getStringList('user_languages') ?? [];
  Future<void> setUserLanguages(List<String> langs) => _prefs.setStringList('user_languages', langs);

  String? get currentUserId => _prefs.getString('user_id') ?? _prefs.getString('firebase_user_id');
  Future<void> setUserId(String? value) => value != null
      ? _prefs.setString('user_id', value)
      : _prefs.remove('user_id');

  // Audio Quality Preference ('auto', '320kbps', '160kbps', '96kbps', '48kbps')
  String get audioQualityPreference => _prefs.getString('audio_quality_preference') ?? 'auto';
  Future<void> setAudioQualityPreference(String value) => _prefs.setString('audio_quality_preference', value);

  // General
  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
