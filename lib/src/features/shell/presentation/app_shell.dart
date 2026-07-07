import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/motion/water_curves.dart';
import '../../../design_system/motion/water_reveal_transition.dart';
import '../../../localization/app_localizations.dart';
import '../../altar/presentation/altar_screen.dart';
import '../../community/presentation/community_screen.dart';
import '../../intentions/presentation/widgets/amen_background.dart';
import '../../journal/presentation/journal_screen.dart';
import '../../pray/presentation/pray_wall_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'widgets/amen_top_bar.dart';
import 'widgets/water_bottom_navigation.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  static const _prayTabIndex = 2;

  var _selectedIndex = _prayTabIndex;
  int? _outgoingIndex;
  var _transitionGeneration = 0;
  late AnimationController _revealController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: AmenWaterCurves.screenRevealDuration,
      value: 1.0, // Initial state: fully revealed
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    if (index == _selectedIndex) return;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final generation = ++_transitionGeneration;

    setState(() {
      _outgoingIndex = _selectedIndex;
      _selectedIndex = index;
    });

    _revealController.duration = reduceMotion
        ? AmenWaterCurves.reducedMotionDuration
        : AmenWaterCurves.screenRevealDuration;
    _revealController.forward(from: 0.0).whenComplete(() {
      if (!mounted || generation != _transitionGeneration) return;
      setState(() => _outgoingIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final pages = <Widget>[
      const AltarScreen(),
      const CommunityScreen(),
      const PrayWallScreen(),
      const JournalScreen(),
      const ProfileScreen(),
    ];

    final labels = <String>[
      l10n.altar,
      l10n.community,
      l10n.pray,
      l10n.journal,
      l10n.profile,
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background Layer
          const Positioned.fill(child: AmenBackground()),

          // Screen Content Layer with Water Reveal Transition & State Preservation
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const AmenTopBar(),
                Expanded(
                  child: _WaterTabStack(
                    selectedIndex: _selectedIndex,
                    outgoingIndex: _outgoingIndex,
                    animation: _revealController,
                    children: pages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Peaceful Water-Inspired Navigation Bar
      bottomNavigationBar: WaterBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: _selectDestination,
        labels: labels,
      ),
    );
  }
}

class _WaterTabStack extends StatelessWidget {
  const _WaterTabStack({
    required this.selectedIndex,
    required this.outgoingIndex,
    required this.animation,
    required this.children,
  });

  final int selectedIndex;
  final int? outgoingIndex;
  final Animation<double> animation;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var index = 0; index < children.length; index++)
          _WaterTabStage(
            key: ValueKey('water-tab-stage-$index'),
            selected: index == selectedIndex,
            outgoing: index == outgoingIndex && index != selectedIndex,
            animation: index == selectedIndex || index == outgoingIndex
                ? animation
                : const AlwaysStoppedAnimation<double>(1.0),
            child: children[index],
          ),
      ],
    );
  }
}

class _WaterTabStage extends StatelessWidget {
  const _WaterTabStage({
    super.key,
    required this.selected,
    required this.outgoing,
    required this.animation,
    required this.child,
  });

  final bool selected;
  final bool outgoing;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final participating = selected || outgoing;

    return Offstage(
      offstage: !participating,
      child: TickerMode(
        enabled: selected,
        child: IgnorePointer(
          ignoring: !selected,
          child: RepaintBoundary(
            child: WaterRevealTransition(
              animation: animation,
              isExiting: outgoing,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
