import 'package:flutter/material.dart';
import 'package:quantumquiz/models/discovery_progress.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

enum DiscoveryDialogAction {
  continueFlow,
  whyItMatters,
}

class ChapterIntroScreen extends StatelessWidget {
  const ChapterIntroScreen({
    super.key,
    required this.title,
    required this.text,
    this.buttonLabel = 'Begin',
  });

  final String title;
  final String text;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return _LearningScaffold(
      child: _LearningCard(
        title: title,
        body: text,
        icon: Icons.auto_stories_outlined,
        actions: [
          QubitQuestDialogButton.primary(
            label: buttonLabel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class MysteryPanel extends StatelessWidget {
  const MysteryPanel({
    super.key,
    required this.level,
  });

  final QQLevel level;

  @override
  Widget build(BuildContext context) {
    return _LearningScaffold(
      child: _LearningCard(
        title: level.mysteryTitle ?? 'Mystery',
        body: level.mysteryText ?? '',
        icon: Icons.travel_explore_outlined,
        actions: [
          QubitQuestDialogButton.primary(
            label: 'Experiment',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class DiscoveryDialog extends StatelessWidget {
  const DiscoveryDialog({
    super.key,
    required this.level,
  });

  final QQLevel level;

  @override
  Widget build(BuildContext context) {
    return QubitQuestDialog(
      title: level.discoveryTitle ?? 'Discovery',
      maxWidth: 560,
      actions: [
        QubitQuestDialogButton.secondary(
          label: 'Continue',
          onPressed: () {
            Navigator.of(context).pop(DiscoveryDialogAction.continueFlow);
          },
        ),
        if (level.hasWhyItMatters)
          QubitQuestDialogButton.primary(
            label: 'Why It Matters',
            onPressed: () {
              Navigator.of(context).pop(DiscoveryDialogAction.whyItMatters);
            },
          ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if ((level.discoveryText ?? '').trim().isNotEmpty)
            _LearningText(level.discoveryText!),
          if ((level.keyInsight ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _InsightBox(text: level.keyInsight!),
          ],
        ],
      ),
    );
  }
}

class WhyItMattersScreen extends StatelessWidget {
  const WhyItMattersScreen({
    super.key,
    required this.level,
  });

  final QQLevel level;

  @override
  Widget build(BuildContext context) {
    return _LearningScaffold(
      child: _LearningCard(
        title: 'Why It Matters',
        body: level.whyItMatters ?? '',
        icon: Icons.lightbulb_outline,
        footer: (level.nextMystery ?? '').trim().isEmpty
            ? null
            : _NextMysteryBox(text: level.nextMystery!),
        actions: [
          QubitQuestDialogButton.primary(
            label: 'Next Level',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class DiscoveriesScreen extends StatefulWidget {
  const DiscoveriesScreen({
    super.key,
    this.onStartPrototypeLevel,
    this.prototypeLevelNumber,
    this.prototypeChapters = const [],
  });

  final Future<void> Function(int levelNumber)? onStartPrototypeLevel;
  final int? prototypeLevelNumber;
  final List<DiscoveryPrototypeChapter> prototypeChapters;

  @override
  State<DiscoveriesScreen> createState() => _DiscoveriesScreenState();
}

class _DiscoveriesScreenState extends State<DiscoveriesScreen> {
  Set<String> _unlocked = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final unlocked = await DiscoveryProgress.loadUnlocked();
    if (!mounted) return;
    setState(() {
      _unlocked = unlocked;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prototypeChapters = [
      if (widget.prototypeLevelNumber != null)
        DiscoveryPrototypeChapter(
          title: 'Chapter 4 Prototype',
          subtitle: 'Try Conditional Phase Flip',
          levelNumber: widget.prototypeLevelNumber!,
        ),
      ...widget.prototypeChapters,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF00030A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00030A),
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Discoveries',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  if (widget.onStartPrototypeLevel != null &&
                      prototypeChapters.isNotEmpty) ...[
                    for (final chapter in prototypeChapters) ...[
                      _PrototypeChapterCard(
                        title: chapter.title,
                        subtitle: chapter.subtitle,
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await widget.onStartPrototypeLevel!(
                            chapter.levelNumber,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 14),
                  ],
                  for (final title in DiscoveryProgress.discoveryOrder) ...[
                    _DiscoveryTile(
                      title: title,
                      unlocked: _unlocked.contains(title),
                    ),
                    if (title != DiscoveryProgress.discoveryOrder.last)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
      ),
    );
  }
}

class DiscoveryPrototypeChapter {
  const DiscoveryPrototypeChapter({
    required this.title,
    required this.subtitle,
    required this.levelNumber,
  });

  final String title;
  final String subtitle;
  final int levelNumber;
}

class _PrototypeChapterCard extends StatelessWidget {
  const _PrototypeChapterCard({
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: QubitQuestDialog.purple.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: QubitQuestDialog.purple.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: QubitQuestDialog.borderColor),
              ),
              child: const Icon(
                Icons.science_outlined,
                color: QubitQuestDialog.purple,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFD6E3F8),
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            QubitQuestDialogButton.primary(
              label: 'Start',
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningScaffold extends StatelessWidget {
  const _LearningScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00030A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.actions,
    this.footer,
  });

  final String title;
  final String body;
  final IconData icon;
  final List<Widget> actions;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: QubitQuestDialog.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.36),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: QubitQuestDialog.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: QubitQuestDialog.borderColor),
                  ),
                  child: Icon(icon, color: QubitQuestDialog.cyan, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            if (body.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _LearningText(body),
            ],
            if (footer != null) ...[
              const SizedBox(height: 14),
              footer!,
            ],
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningText extends StatelessWidget {
  const _LearningText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFD6E3F8),
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InsightBox extends StatelessWidget {
  const _InsightBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.purple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: QubitQuestDialog.purple.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _NextMysteryBox extends StatelessWidget {
  const _NextMysteryBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.innerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QubitQuestDialog.borderSoftColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Next Mystery',
              style: TextStyle(
                color: QubitQuestDialog.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFFD6E3F8),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryTile extends StatelessWidget {
  const _DiscoveryTile({
    required this.title,
    required this.unlocked,
  });

  final String title;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            unlocked ? QubitQuestDialog.cardColor : QubitQuestDialog.innerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? QubitQuestDialog.cyan.withValues(alpha: 0.38)
              : QubitQuestDialog.borderSoftColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Text(
              unlocked ? '✓' : '□',
              style: TextStyle(
                color: unlocked
                    ? QubitQuestDialog.cyan
                    : QubitQuestDialog.mutedText,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: unlocked ? Colors.white : QubitQuestDialog.mutedText,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
