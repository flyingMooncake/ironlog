import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../repositories/user_repository.dart';

// Provider for user repository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// Provider for user profile
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return await repo.getOrCreateProfile();
});

// Provider for rest timer default
final restTimerDefaultProvider = FutureProvider<int>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile.restTimerDefault;
});

// Provider for unit system
final unitSystemProvider = FutureProvider<UnitSystem>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile.unitSystem;
});
