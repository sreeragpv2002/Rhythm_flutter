import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple provider to signal that a session has expired (e.g., token refresh failed).
/// This allows the networking layer to trigger a logout without creating a circular
/// dependency with the Auth provider.
final unauthorizedEventProvider = StateProvider<bool>((ref) => false);
