import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ShareTripLocalStore {
  static const _chatPrefix = 'sharetrip_chat_';
  static const _driverProfileKey = 'sharetrip_driver_profile';

  static Future<void> saveDriverProfile(Map<String, String> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_driverProfileKey, jsonEncode(profile));
  }

  static Future<Map<String, dynamic>?> getDriverProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_driverProfileKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static Future<void> addMessage(String conversationId, Map<String, dynamic> message) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_chatPrefix$conversationId';
    final messages = (jsonDecode(prefs.getString(key) ?? '[]') as List)
        .map((item) => Map<String, dynamic>.from(item as Map)).toList();
    messages.add(message);
    await prefs.setString(key, jsonEncode(messages));
  }

  static Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_chatPrefix$conversationId') ?? '[]';
    return (jsonDecode(raw) as List)
        .map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static Future<Map<String, List<Map<String, dynamic>>>> getAllChats() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, List<Map<String, dynamic>>>{};
    for (final key in prefs.getKeys().where((key) => key.startsWith(_chatPrefix))) {
      final id = key.substring(_chatPrefix.length);
      final raw = prefs.getString(key);
      if (raw == null) continue;
      result[id] = (jsonDecode(raw) as List)
          .map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return result;
  }
}
