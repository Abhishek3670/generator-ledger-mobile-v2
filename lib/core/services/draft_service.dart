import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing local auto-save drafts of forms.
class DraftService {
  static const String _prefix = 'draft_';

  /// Saves the given form data as a JSON draft.
  Future<void> saveDraft(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonEncode(data));
  }

  /// Loads the saved form data draft if it exists.
  Future<Map<String, dynamic>?> loadDraft(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_prefix$key');
    if (json != null) {
      try {
        return jsonDecode(json) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Clears the saved draft associated with the given key.
  Future<void> clearDraft(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }
}
