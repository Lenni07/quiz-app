import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'has_department.dart';

class GroupSortItem {
  final String word;
  final String category;

  GroupSortItem({required this.word, required this.category});

  factory GroupSortItem.fromJson(Map<String, dynamic> json) {
    return GroupSortItem(word: json['word'] as String, category: json['category'] as String);
  }
}

/// Eine Group-Sort-Aktivität (Kategorien + zuzuordnende Wörter). Das
/// Department-Tag gilt für die ganze Aktivität (siehe ROADMAP_QuizApp.md
/// Abschnitt 18c). Sobald mehrere Aktivitäten eingepflegt sind, wird die
/// Auswahl nach Department gefiltert; solange es nur eine gibt, greift der
/// Filter faktisch nicht.
class GroupSortData implements HasDepartment {
  final List<String> categories;
  final List<GroupSortItem> items;

  @override
  final String department;

  GroupSortData({
    required this.categories,
    required this.items,
    this.department = 'general',
  });
}

Future<GroupSortData> loadGroupSortData() async {
  final jsonString = await rootBundle.loadString('assets/group_sort.json');
  final Map<String, dynamic> data = jsonDecode(jsonString);
  return GroupSortData(
    categories: List<String>.from(data['categories'] as List),
    items: (data['items'] as List).map((e) => GroupSortItem.fromJson(e as Map<String, dynamic>)).toList(),
    department: data['department'] as String? ?? 'general',
  );
}
