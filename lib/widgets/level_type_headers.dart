import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ComposerHeader extends StatelessWidget implements PreferredSizeWidget {
  const ComposerHeader({
    super.key,
    required this.compact,
    required this.title,
    required this.subtitle,
    required this.isMastery,
    required this.isCompleted,
    required this.actions,
  });

  final bool compact;
  final String title;
  final String subtitle;
  final bool isMastery;
  final bool isCompleted;
  final List<Widget> actions;

  @override
  Size get preferredSize => Size.fromHeight(compact ? 60 : 56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: preferredSize.height,
      backgroundColor: LevelHeaderTokens.black,
      leadingWidth: compact ? 42 : 50,
      leading: _LevelHeaderBackButton(compact: compact),
      flexibleSpace: const ColoredBox(color: LevelHeaderTokens.black),
      elevation: 0,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      titleSpacing: compact ? 0 : 8,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isMastery
              ? _LevelHeaderMasteryIcon(compact: compact)
              : _LevelHeaderAtomLogo(compact: compact),
          SizedBox(width: compact ? 11 : 12),
          Flexible(
            child: _LevelHeaderTitleBlock(
              compact: compact,
              title: title,
              subtitle: subtitle,
              isCompleted: isCompleted,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}

class ConceptCheckHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const ConceptCheckHeader({
    super.key,
    required this.compact,
    required this.displayLabel,
    required this.title,
    required this.isMastery,
    required this.isCompleted,
    required this.actions,
  });

  final bool compact;
  final String displayLabel;
  final String title;
  final bool isMastery;
  final bool isCompleted;
  final List<Widget> actions;

  @override
  Size get preferredSize => Size.fromHeight(compact ? 60 : 56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: preferredSize.height,
      backgroundColor: LevelHeaderTokens.black,
      leadingWidth: compact ? 42 : 50,
      leading: _LevelHeaderBackButton(compact: compact),
      flexibleSpace: const ColoredBox(color: LevelHeaderTokens.black),
      elevation: 0,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      titleSpacing: compact ? 0 : 8,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isMastery
              ? _LevelHeaderMasteryIcon(compact: compact)
              : _LevelHeaderAtomLogo(compact: compact),
          SizedBox(width: compact ? 11 : 12),
          Flexible(
            child: _LevelHeaderTitleBlock(
              compact: compact,
              title: displayLabel,
              subtitle: title,
              isCompleted: isCompleted,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}

class FillGateHeader extends StatelessWidget implements PreferredSizeWidget {
  const FillGateHeader({
    super.key,
    required this.displayLabel,
    required this.title,
    required this.isMastery,
    required this.isCompleted,
  });

  final String displayLabel;
  final String title;
  final bool isMastery;
  final bool isCompleted;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return _CompactLearningHeader(
      displayLabel: displayLabel,
      title: title,
      icon: isMastery
          ? Icons.workspace_premium_outlined
          : Icons.extension_outlined,
      isMastery: isMastery,
      isCompleted: isCompleted,
    );
  }
}

class ReadingHeader extends StatelessWidget implements PreferredSizeWidget {
  const ReadingHeader({
    super.key,
    required this.displayLabel,
    required this.title,
    required this.isMastery,
    required this.isCompleted,
  });

  final String displayLabel;
  final String title;
  final bool isMastery;
  final bool isCompleted;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return _CompactLearningHeader(
      displayLabel: displayLabel,
      title: title,
      icon: isMastery
          ? Icons.workspace_premium_outlined
          : Icons.visibility_outlined,
      isMastery: isMastery,
      isCompleted: isCompleted,
    );
  }
}

class ExperimentHeader extends StatelessWidget implements PreferredSizeWidget {
  const ExperimentHeader({
    super.key,
    required this.displayLabel,
    required this.title,
    required this.isMastery,
    required this.isCompleted,
  });

  final String displayLabel;
  final String title;
  final bool isMastery;
  final bool isCompleted;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return _CompactLearningHeader(
      displayLabel: displayLabel,
      title: title,
      icon:
          isMastery ? Icons.workspace_premium_outlined : Icons.science_outlined,
      isMastery: isMastery,
      isCompleted: isCompleted,
    );
  }
}

class LevelHeaderActionShell extends StatelessWidget {
  const LevelHeaderActionShell({
    super.key,
    required this.child,
    this.size = 34,
    this.subdued = false,
  });

  final Widget child;
  final double size;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: subdued
            ? LevelHeaderTokens.inner.withValues(alpha: 0.54)
            : LevelHeaderTokens.card,
        shape: BoxShape.circle,
        border: Border.all(
          color:
              subdued ? LevelHeaderTokens.borderSoft : LevelHeaderTokens.border,
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class LevelHeaderAttentionBadge extends StatelessWidget {
  const LevelHeaderAttentionBadge({
    super.key,
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (visible)
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: LevelHeaderTokens.yellow,
                shape: BoxShape.circle,
                border: Border.all(
                  color: LevelHeaderTokens.black,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class LevelHeaderTokens {
  const LevelHeaderTokens._();

  static const Color black = Color(0xFF00030A);
  static const Color card = Color(0xFF18233A);
  static const Color inner = Color(0xFF101A2D);
  static const Color border = Color(0x66344A73);
  static const Color borderSoft = Color(0x3D344A73);
  static const Color cyan = Color(0xFF56CCF2);
  static const Color purple = Color(0xFFB388FF);
  static const Color green = Color(0xFF7CFFB2);
  static const Color yellow = Color(0xFFFFD54F);
}

class _CompactLearningHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const _CompactLearningHeader({
    required this.displayLabel,
    required this.title,
    required this.icon,
    required this.isMastery,
    required this.isCompleted,
  });

  final String displayLabel;
  final String title;
  final IconData icon;
  final bool isMastery;
  final bool isCompleted;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1E1E2C),
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
                isMastery ? LevelHeaderTokens.green : const Color(0xFF5D5FE6),
            size: 26,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCompleted) const _CompletedHeaderLabel(),
                Text(
                  displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.08,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelHeaderTitleBlock extends StatelessWidget {
  const _LevelHeaderTitleBlock({
    required this.compact,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
  });

  final bool compact;
  final String title;
  final String subtitle;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCompleted) const _CompletedHeaderLabel(),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 16 : 19,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.08,
          ),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 11 : 12.5,
            fontWeight: FontWeight.w700,
            color: LevelHeaderTokens.purple,
            height: 1.18,
          ),
        ),
      ],
    );
  }
}

class _CompletedHeaderLabel extends StatelessWidget {
  const _CompletedHeaderLabel();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '✓ Completed',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: LevelHeaderTokens.green,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        height: 1.05,
      ),
    );
  }
}

class _LevelHeaderAtomLogo extends StatelessWidget {
  const _LevelHeaderAtomLogo({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 38.0;

    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/images/qubit_quest_atom_logo.svg',
        fit: BoxFit.contain,
        colorFilter: const ColorFilter.mode(
          LevelHeaderTokens.cyan,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _LevelHeaderMasteryIcon extends StatelessWidget {
  const _LevelHeaderMasteryIcon({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 38.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: LevelHeaderTokens.green.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: LevelHeaderTokens.green.withValues(alpha: 0.44),
        ),
      ),
      child: Icon(
        Icons.workspace_premium_outlined,
        color: LevelHeaderTokens.green,
        size: compact ? 19 : 21,
      ),
    );
  }
}

class _LevelHeaderBackButton extends StatelessWidget {
  const _LevelHeaderBackButton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!(ModalRoute.of(context)?.canPop ?? false)) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_rounded),
      iconSize: compact ? 21 : 22,
      color: Colors.white.withValues(alpha: 0.90),
      padding: EdgeInsets.only(left: compact ? 2 : 4),
      splashRadius: 22,
      tooltip: 'Back',
    );
  }
}
