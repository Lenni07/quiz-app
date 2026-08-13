import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class GroupSortItem {
  final String word;
  final String category;

  GroupSortItem({required this.word, required this.category});

  factory GroupSortItem.fromJson(Map<String, dynamic> json) {
    return GroupSortItem(word: json['word'] as String, category: json['category'] as String);
  }
}

class GroupSortData {
  final List<String> categories;
  final List<GroupSortItem> items;

  GroupSortData({required this.categories, required this.items});
}

Future<GroupSortData> loadGroupSortData() async {
  final jsonString = await rootBundle.loadString('assets/group_sort.json');
  final Map<String, dynamic> data = jsonDecode(jsonString);
  return GroupSortData(
    categories: List<String>.from(data['categories'] as List),
    items: (data['items'] as List).map((e) => GroupSortItem.fromJson(e as Map<String, dynamic>)).toList(),
  );
}
