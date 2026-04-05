// lib/models/level.dart
class QQLevelsCategory {
  final String groupName;
  final int from;
  final int to;
  final String? categoryIntro; // plain-English explanation shown once before the first level

  const QQLevelsCategory({
    required this.groupName,
    required this.from,
    required this.to,
    this.categoryIntro,
  });
}