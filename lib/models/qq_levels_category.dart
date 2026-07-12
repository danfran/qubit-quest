// lib/models/level.dart
class QQLevelsCategory {
  final String groupName;
  final int from;
  final int to;
  final String?
      categoryIntro; // plain-English explanation shown once before the first level
  final String phaseTitle;
  final String phasePurpose;
  final bool isMasteryPhase;

  const QQLevelsCategory({
    required this.groupName,
    required this.from,
    required this.to,
    this.categoryIntro,
    this.phaseTitle = 'Phase 1 - Guided Discovery',
    this.phasePurpose = 'Concept Acquisition',
    this.isMasteryPhase = false,
  });
}
