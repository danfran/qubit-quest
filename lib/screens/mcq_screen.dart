import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quantumquiz/models/level_completion_action.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/widgets/latex_text.dart';

class McqScreen extends StatefulWidget {
  final int levelId;
  final McqLevel level;
  final Function(int)? onLevelUnlocked;

  const McqScreen({
    super.key,
    required this.levelId,
    required this.level,
    required this.onLevelUnlocked,
  });

  @override
  State<McqScreen> createState() => _McqScreenState();
}

class _McqScreenState extends State<McqScreen> {
  int? _selected;
  bool _answered = false;

  bool get _isCorrect => _selected == widget.level.correctOptionIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/logo_mini.svg',
              height: 32,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            const SizedBox(width: 8),
            Text(
              'Level ${widget.levelId}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),

      // ── Scrollable body + pinned footer ────────────────────────────────
      body: CustomScrollView(
        slivers: [
          // All scrollable content
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              24, 24, 24, 0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Concept intro banner
                if (widget.level.conceptIntro != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2E40),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF5D5FE6)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF5D5FE6), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.level.conceptIntro!,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Text('Question',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                LatexText(
                  math: widget.level.taskDescription,
                  textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4),
                  inlineMathHeight: 22,
                ),
                const SizedBox(height: 28),

                // Options
                ...List.generate(widget.level.options.length, (idx) {
                  final bool isCorrect = idx == widget.level.correctOptionIndex;
                  final bool isSelected = _selected == idx;

                  Color borderColor = Colors.transparent;
                  Color bgColor = const Color(0xFF2D2E40);
                  Widget? trailing;

                  if (_answered) {
                    if (isCorrect) {
                      borderColor = Colors.green;
                      bgColor = Colors.green.withValues(alpha: 0.15);
                      trailing =
                          const Icon(Icons.check_circle, color: Colors.green);
                    } else if (isSelected) {
                      borderColor = Colors.red;
                      bgColor = Colors.red.withValues(alpha: 0.15);
                      trailing =
                          const Icon(Icons.cancel, color: Colors.red);
                    }
                  } else if (isSelected) {
                    borderColor = const Color(0xFF5D5FE6);
                    bgColor =
                        const Color(0xFF5D5FE6).withValues(alpha: 0.15);
                  }

                  return Padding(
                    padding: EdgeInsets.only(
                        bottom:
                            idx < widget.level.options.length - 1 ? 10 : 0),
                    child: GestureDetector(
                      onTap: _answered
                          ? null
                          : () => setState(() => _selected = idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${String.fromCharCode(65 + idx)}.  ',
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            Expanded(
                              child: Text(
                                widget.level.options[idx],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    height: 1.4),
                              ),
                            ),
                            if (trailing != null) trailing,
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Solution explanation
                if (_answered && widget.level.solutionExplanation != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2E40),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      widget.level.solutionExplanation!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14, height: 1.5),
                    ),
                  ),
              ]),
            ),
          ),

          // Sticky footer: always at bottom, scrolls into view if content is long
          SliverFillRemaining(
            hasScrollBody: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _answered
                          ? () {
                              if (_isCorrect) {
                                widget.onLevelUnlocked
                                    ?.call(widget.levelId + 1);
                              }
                              Navigator.of(context).pop(
                                _isCorrect
                                    ? LevelCompletionAction.nextLevel
                                    : LevelCompletionAction.levelSelect,
                              );
                            }
                          : _selected == null
                              ? null
                              : () => setState(() => _answered = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _answered
                            ? (_isCorrect ? Colors.green : Colors.orange)
                            : const Color(0xFF5D5FE6),
                        disabledBackgroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _answered
                            ? (_isCorrect
                                ? 'Next Level →'
                                : 'Back to Level Select')
                            : 'Confirm',
                        style: const TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

    );
  }
}

