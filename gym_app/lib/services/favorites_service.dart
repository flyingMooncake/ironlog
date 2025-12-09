import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_template_groups';

  static FavoritesService? _instance;
  static FavoritesService get instance {
    _instance ??= FavoritesService();
    return _instance!;
  }

  Set<int> _favoriteGroupIds = {};
  bool _isInitialized = false;

  /// Initialize favorites from SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final favoritesList = prefs.getStringList(_favoritesKey) ?? [];
    _favoriteGroupIds = favoritesList.map((id) => int.parse(id)).toSet();
    _isInitialized = true;
  }

  /// Check if a group is favorited
  Future<bool> isFavorite(int groupId) async {
    await initialize();
    return _favoriteGroupIds.contains(groupId);
  }

  /// Toggle favorite status for a group
  Future<void> toggleFavorite(int groupId) async {
    await initialize();

    if (_favoriteGroupIds.contains(groupId)) {
      _favoriteGroupIds.remove(groupId);
    } else {
      _favoriteGroupIds.add(groupId);
    }

    await _saveFavorites();
  }

  /// Add a group to favorites
  Future<void> addFavorite(int groupId) async {
    await initialize();
    _favoriteGroupIds.add(groupId);
    await _saveFavorites();
  }

  /// Remove a group from favorites
  Future<void> removeFavorite(int groupId) async {
    await initialize();
    _favoriteGroupIds.remove(groupId);
    await _saveFavorites();
  }

  /// Get all favorite group IDs
  Future<Set<int>> getFavorites() async {
    await initialize();
    return Set.from(_favoriteGroupIds);
  }

  /// Check if ungrouped templates are favorited (using -1 as special ID)
  Future<bool> isUngroupedFavorite() async {
    await initialize();
    return _favoriteGroupIds.contains(-1);
  }

  /// Toggle favorite status for ungrouped templates
  Future<void> toggleUngroupedFavorite() async {
    await initialize();

    if (_favoriteGroupIds.contains(-1)) {
      _favoriteGroupIds.remove(-1);
    } else {
      _favoriteGroupIds.add(-1);
    }

    await _saveFavorites();
  }

  /// Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesList = _favoriteGroupIds.map((id) => id.toString()).toList();
    await prefs.setStringList(_favoritesKey, favoritesList);
  }

  /// Clear all favorites
  Future<void> clearAll() async {
    await initialize();
    _favoriteGroupIds.clear();
    await _saveFavorites();
  }
}
