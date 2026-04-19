import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScanEntry {
  final String name;
  final String brand;
  final int score;
  final String grade;
  final DateTime scannedAt;

  ScanEntry({
    required this.name,
    required this.brand,
    required this.score,
    required this.grade,
    required this.scannedAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'brand': brand,
        'score': score,
        'grade': grade,
        'scannedAt': scannedAt.toIso8601String(),
      };

  factory ScanEntry.fromJson(Map<String, dynamic> j) => ScanEntry(
        name: j['name'] ?? '',
        brand: j['brand'] ?? '',
        score: (j['score'] as num?)?.toInt() ?? 0,
        grade: j['grade'] ?? '?',
        scannedAt: DateTime.tryParse(j['scannedAt'] ?? '') ?? DateTime.now(),
      );
}

class ScanStorage {
  static const _key = 'scan_history';

  static Future<List<ScanEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => ScanEntry.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
  }

  static Future<void> save(ScanEntry entry) async {
    final entries = await load();
    entries.insert(0, entry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  static int computeStreak(List<ScanEntry> entries) {
    if (entries.isEmpty) return 0;
    final days = entries
        .map((e) => DateTime(e.scannedAt.year, e.scannedAt.month, e.scannedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (days.first != todayDate && days.first != todayDate.subtract(const Duration(days: 1))) {
      return 0;
    }

    int streak = 1;
    for (int i = 1; i < days.length; i++) {
      if (days[i - 1].difference(days[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
