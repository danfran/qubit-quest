import 'package:flutter/material.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/qq_levels_category.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

class LearningMapConceptLink {
  const LearningMapConceptLink({
    required this.fromChapter,
    required this.toChapter,
    required this.description,
  });

  final int fromChapter;
  final int toChapter;
  final String description;

  String get label => toChapter == 13
      ? '$fromChapter -> Mastery'
      : '$fromChapter -> $toChapter';
}

class LearningMapScreen extends StatelessWidget {
  const LearningMapScreen({
    super.key,
    required this.maxUnlockedLevel,
    required this.onStartChapter,
  });

  static const List<LearningMapConceptLink> conceptLinks = [
    LearningMapConceptLink(
      fromChapter: 2,
      toChapter: 4,
      description: 'Hidden phase supports interference',
    ),
    LearningMapConceptLink(
      fromChapter: 3,
      toChapter: 4,
      description: 'Superposition gives paths to interfere',
    ),
    LearningMapConceptLink(
      fromChapter: 5,
      toChapter: 7,
      description: 'Entanglement scales to GHZ',
    ),
    LearningMapConceptLink(
      fromChapter: 9,
      toChapter: 11,
      description: 'Oracle abstraction feeds Grover loops',
    ),
    LearningMapConceptLink(
      fromChapter: 10,
      toChapter: 11,
      description: 'Amplification becomes an iterative pattern',
    ),
    LearningMapConceptLink(
      fromChapter: 12,
      toChapter: 13,
      description: 'Synthesis leads into integrated mastery',
    ),
  ];

  final int maxUnlockedLevel;
  final Future<void> Function(int levelNumber) onStartChapter;

  @override
  Widget build(BuildContext context) {
    final chapters = groupedLevels.toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFF00030A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 28,
                compact ? 14 : 22,
                compact ? 16 : 28,
                28,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LearningHeaderSystem(compact: compact),
                        SizedBox(height: compact ? 18 : 24),
                        _LearningMapPath(
                          chapters: chapters,
                          maxUnlockedLevel: maxUnlockedLevel,
                          compact: compact,
                          onStartChapter: onStartChapter,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class LearningHeaderSystem extends StatelessWidget {
  const LearningHeaderSystem({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: QubitQuestDialog.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 14 : 18,
          compact ? 12 : 16,
          compact ? 14 : 18,
          compact ? 14 : 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LearningHeaderNavigation(compact: compact),
            SizedBox(height: compact ? 16 : 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 42 : 48,
                  height: compact ? 42 : 48,
                  decoration: BoxDecoration(
                    color: QubitQuestDialog.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: QubitQuestDialog.borderColor),
                  ),
                  child: const Icon(
                    Icons.account_tree_outlined,
                    color: QubitQuestDialog.cyan,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantum Learning Journey',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 22 : 30,
                          height: 1.04,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Learn concepts, combine concepts, then master them through integrated challenges. The path stays continuous from Guided Discovery into Mastery Challenges.',
                        style: TextStyle(
                          color: Color(0xFFD6E3F8),
                          fontSize: 14,
                          height: 1.42,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 16 : 18),
            const Divider(height: 1, color: QubitQuestDialog.borderSoftColor),
            SizedBox(height: compact ? 12 : 14),
            _LearningHeaderConceptLinks(compact: compact),
          ],
        ),
      ),
    );
  }
}

class _LearningHeaderNavigation extends StatelessWidget {
  const _LearningHeaderNavigation({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: QubitQuestDialog.innerColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: QubitQuestDialog.borderSoftColor),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFFD6E3F8),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Learning Map',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 17 : 19,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Concept graph and chapter progress',
                style: TextStyle(
                  color: QubitQuestDialog.mutedText,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: QubitQuestDialog.cyan.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: QubitQuestDialog.cyan.withValues(alpha: 0.28),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              'MAP',
              style: TextStyle(
                color: QubitQuestDialog.cyan,
                fontSize: 11,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LearningHeaderConceptLinks extends StatelessWidget {
  const _LearningHeaderConceptLinks({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LegendLabel(),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final link in LearningMapScreen.conceptLinks)
              _DependencyChip(link: link.label, text: link.description),
          ],
        ),
      ],
    );
  }
}

class _LegendLabel extends StatelessWidget {
  const _LegendLabel();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Concept links',
      style: TextStyle(
        color: QubitQuestDialog.mutedText,
        fontSize: 12,
        letterSpacing: 0.7,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _DependencyChip extends StatelessWidget {
  const _DependencyChip({required this.link, required this.text});

  final String link;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.innerColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: QubitQuestDialog.purple.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: link,
                style: const TextStyle(color: QubitQuestDialog.purple),
              ),
              TextSpan(
                text: '  $text',
                style: const TextStyle(color: Color(0xFFD6E3F8)),
              ),
            ],
          ),
          style: const TextStyle(
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LearningMapPath extends StatelessWidget {
  const _LearningMapPath({
    required this.chapters,
    required this.maxUnlockedLevel,
    required this.compact,
    required this.onStartChapter,
  });

  final List<QQLevelsCategory> chapters;
  final int maxUnlockedLevel;
  final bool compact;
  final Future<void> Function(int levelNumber) onStartChapter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _LearningMapConnectionsPainter(
                chapterCount: chapters.length,
                compact: compact,
              ),
            ),
          ),
        ),
        Column(
          children: [
            for (int index = 0; index < chapters.length; index++) ...[
              _LearningMapNode(
                chapterNumber: index + 1,
                category: chapters[index],
                status: _statusFor(chapters[index]),
                compact: compact,
                onTap: () async {
                  final firstLevel = chapters[index].from + 1;
                  if (_statusFor(chapters[index]) == _ChapterMapStatus.locked) {
                    return;
                  }
                  await onStartChapter(firstLevel);
                },
              ),
              if (index < chapters.length - 1)
                SizedBox(height: compact ? 16 : 18),
            ],
          ],
        ),
      ],
    );
  }

  _ChapterMapStatus _statusFor(QQLevelsCategory category) {
    final firstLevel = category.from + 1;
    final lastLevel = category.to + 1;
    if (maxUnlockedLevel > lastLevel) return _ChapterMapStatus.completed;
    if (maxUnlockedLevel >= firstLevel) return _ChapterMapStatus.current;
    return _ChapterMapStatus.locked;
  }
}

enum _ChapterMapStatus { completed, current, locked }

class _LearningMapNode extends StatelessWidget {
  const _LearningMapNode({
    required this.chapterNumber,
    required this.category,
    required this.status,
    required this.compact,
    required this.onTap,
  });

  final int chapterNumber;
  final QQLevelsCategory category;
  final _ChapterMapStatus status;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = status == _ChapterMapStatus.locked;
    final accent = switch (status) {
      _ChapterMapStatus.completed => const Color(0xFF7CFFB2),
      _ChapterMapStatus.current => QubitQuestDialog.cyan,
      _ChapterMapStatus.locked => QubitQuestDialog.mutedText,
    };

    return Align(
      alignment: compact || chapterNumber.isOdd
          ? Alignment.centerLeft
          : Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: compact ? 1 : 0.74,
        child: InkWell(
          onTap: locked ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.all(compact ? 14 : 16),
            decoration: BoxDecoration(
              color: locked
                  ? QubitQuestDialog.innerColor
                  : QubitQuestDialog.panelColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: locked
                    ? QubitQuestDialog.borderSoftColor
                    : accent.withValues(alpha: 0.48),
                width: status == _ChapterMapStatus.current ? 1.5 : 1,
              ),
              boxShadow: [
                if (!locked)
                  BoxShadow(
                    color: accent.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: Row(
              children: [
                _ChapterOrb(
                  chapterNumber: chapterNumber,
                  status: status,
                  accent: accent,
                  isMasteryPhase: category.isMasteryPhase,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _chapterTitle(category.groupName),
                        style: TextStyle(
                          color: locked
                              ? QubitQuestDialog.mutedText
                              : Colors.white,
                          fontSize: compact ? 17 : 19,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _chapterIdentity(category),
                        style: TextStyle(
                          color: locked
                              ? QubitQuestDialog.mutedText
                                  .withValues(alpha: 0.58)
                              : const Color(0xFFD6E3F8),
                          fontSize: compact ? 12.5 : 13.5,
                          height: 1.32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _StatusPill(status: status, accent: accent),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  locked ? Icons.lock_outline : Icons.chevron_right_rounded,
                  color: accent.withValues(alpha: locked ? 0.56 : 0.90),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _chapterTitle(String groupName) =>
      groupName.replaceFirst(' - ', ' — ');

  String _chapterIdentity(QQLevelsCategory category) {
    for (final entry in notebookEntries) {
      if (entry.chapterTitle == category.groupName) {
        return entry.chapterIdentity;
      }
    }
    return category.categoryIntro ?? category.phasePurpose;
  }
}

class _ChapterOrb extends StatelessWidget {
  const _ChapterOrb({
    required this.chapterNumber,
    required this.status,
    required this.accent,
    required this.isMasteryPhase,
  });

  final int chapterNumber;
  final _ChapterMapStatus status;
  final Color accent;
  final bool isMasteryPhase;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(
            alpha: status == _ChapterMapStatus.locked ? 0.08 : 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.44)),
      ),
      child: isMasteryPhase && status != _ChapterMapStatus.completed
          ? Icon(Icons.workspace_premium_outlined, color: accent, size: 25)
          : status == _ChapterMapStatus.completed
              ? const Icon(Icons.check_rounded,
                  color: Color(0xFF7CFFB2), size: 26)
              : Text(
                  '$chapterNumber',
                  style: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.accent});

  final _ChapterMapStatus status;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      _ChapterMapStatus.completed => 'completed',
      _ChapterMapStatus.current => 'current',
      _ChapterMapStatus.locked => 'locked',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.36)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LearningMapConnectionsPainter extends CustomPainter {
  const _LearningMapConnectionsPainter({
    required this.chapterCount,
    required this.compact,
  });

  final int chapterCount;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    if (chapterCount < 2) return;

    final paint = Paint()
      ..color = QubitQuestDialog.borderColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final dependencyPaint = Paint()
      ..color = QubitQuestDialog.purple.withValues(alpha: 0.22)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final centers = _centers(size);
    for (int i = 0; i < centers.length - 1; i++) {
      canvas.drawLine(centers[i], centers[i + 1], paint);
    }

    for (final (from, to) in const [
      (2, 4),
      (3, 4),
      (5, 7),
      (9, 11),
      (10, 11),
      (12, 13),
    ]) {
      if (from <= centers.length && to <= centers.length) {
        final start = centers[from - 1];
        final end = centers[to - 1];
        final control = Offset(
          compact ? size.width - 18 : size.width / 2,
          (start.dy + end.dy) / 2,
        );
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
        canvas.drawPath(path, dependencyPaint);
      }
    }
  }

  List<Offset> _centers(Size size) {
    final gap = compact ? 16.0 : 18.0;
    final approximateNodeHeight = compact ? 154.0 : 146.0;
    final step = approximateNodeHeight + gap;
    return List.generate(chapterCount, (index) {
      final alignLeft = compact || (index + 1).isOdd;
      final x = compact
          ? 24.0
          : alignLeft
              ? size.width * 0.13
              : size.width * 0.87;
      final y = approximateNodeHeight / 2 + index * step;
      return Offset(x, y);
    });
  }

  @override
  bool shouldRepaint(covariant _LearningMapConnectionsPainter oldDelegate) {
    return oldDelegate.chapterCount != chapterCount ||
        oldDelegate.compact != compact;
  }
}
