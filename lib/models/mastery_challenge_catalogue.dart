import 'package:flutter/foundation.dart';
import 'package:quantumquiz/models/qq_level.dart';

enum MasteryDifficulty {
  foundation,
  application,
  integration,
  advanced,
}

enum MasteryConceptTag {
  reversibility,
  physicalState,
  operatorAction,
  inverseOrder,
  globalPhase,
  relativePhase,
  superposition,
  interference,
  measurementBasis,
  classicalMixture,
  entanglement,
  control,
  ghz,
  kickback,
  oracle,
  amplification,
  iteration,
  algorithmStructure,
}

enum MasteryInteractionType {
  prediction,
  construction,
  debugging,
  evidence,
  measurement,
  fillGate,
  uncomputation,
  algorithm,
}

@immutable
class MasteryChallengeDefinition {
  MasteryChallengeDefinition({
    required this.semanticId,
    required this.displayOrder,
    required this.title,
    required this.difficulty,
    required Set<MasteryConceptTag> conceptTags,
    required this.interactionType,
    required this.levelDefinition,
    this.contentVersion = 1,
  }) : conceptTags = Set.unmodifiable(conceptTags) {
    if (!isValidSemanticId(semanticId)) {
      throw ArgumentError.value(
        semanticId,
        'semanticId',
        'Use a non-empty lower_snake_case semantic identity.',
      );
    }
    if (displayOrder < 0) {
      throw ArgumentError.value(
        displayOrder,
        'displayOrder',
        'Display order cannot be negative.',
      );
    }
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'Title cannot be empty.');
    }
    if (contentVersion < 1) {
      throw ArgumentError.value(
        contentVersion,
        'contentVersion',
        'Content version must be at least 1.',
      );
    }
  }

  static final RegExp _semanticIdPattern = RegExp(
    r'^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$',
  );

  final String semanticId;
  final int displayOrder;
  final String title;
  final MasteryDifficulty difficulty;
  final Set<MasteryConceptTag> conceptTags;
  final MasteryInteractionType interactionType;
  final QQLevel levelDefinition;
  final int contentVersion;

  static bool isValidSemanticId(String value) =>
      value.isNotEmpty && _semanticIdPattern.hasMatch(value);

  MasteryChallengeDefinition copyWith({
    int? displayOrder,
    String? title,
    MasteryDifficulty? difficulty,
    Set<MasteryConceptTag>? conceptTags,
    MasteryInteractionType? interactionType,
    QQLevel? levelDefinition,
    int? contentVersion,
  }) {
    return MasteryChallengeDefinition(
      semanticId: semanticId,
      displayOrder: displayOrder ?? this.displayOrder,
      title: title ?? this.title,
      difficulty: difficulty ?? this.difficulty,
      conceptTags: conceptTags ?? this.conceptTags,
      interactionType: interactionType ?? this.interactionType,
      levelDefinition: levelDefinition ?? this.levelDefinition,
      contentVersion: contentVersion ?? this.contentVersion,
    );
  }
}

class MasteryChallengeCatalogue {
  MasteryChallengeCatalogue(Iterable<MasteryChallengeDefinition> definitions)
      : _definitionsById = _indexDefinitions(definitions);

  final Map<String, MasteryChallengeDefinition> _definitionsById;

  static Map<String, MasteryChallengeDefinition> _indexDefinitions(
    Iterable<MasteryChallengeDefinition> definitions,
  ) {
    final indexed = <String, MasteryChallengeDefinition>{};
    for (final definition in definitions) {
      if (indexed.containsKey(definition.semanticId)) {
        throw StateError(
          'Duplicate Mastery semantic ID: ${definition.semanticId}',
        );
      }
      indexed[definition.semanticId] = definition;
    }
    return Map.unmodifiable(indexed);
  }

  int get length => _definitionsById.length;

  Iterable<String> get semanticIds => _definitionsById.keys;

  List<MasteryChallengeDefinition> get orderedDefinitions {
    final definitions = _definitionsById.values.toList(growable: false);
    definitions.sort((left, right) {
      final orderComparison = left.displayOrder.compareTo(right.displayOrder);
      return orderComparison != 0
          ? orderComparison
          : left.semanticId.compareTo(right.semanticId);
    });
    return definitions;
  }

  MasteryChallengeDefinition? bySemanticId(String semanticId) =>
      _definitionsById[semanticId];

  MasteryChallengeDefinition requireBySemanticId(String semanticId) {
    final definition = bySemanticId(semanticId);
    if (definition == null) {
      throw StateError('Unknown Mastery semantic ID: $semanticId');
    }
    return definition;
  }

  bool isAccessible(String semanticId) =>
      _definitionsById.containsKey(semanticId);
}
