import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'foodlink_logo.dart';

/// The app's main sections.
enum AppTab {
  home('Home', Icons.home_rounded),
  explore('Explore', Icons.search_rounded),
  events('Events', Icons.calendar_today_rounded),
  community('Community', Icons.sentiment_satisfied_alt_rounded),
  profile('Profile', Icons.person_outline_rounded);

  const AppTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The coordinator's main sections.
enum CoordinatorTab {
  home('Home', Icons.home_rounded),
  events('Events', Icons.calendar_today_rounded),
  volunteers('Volunteers', Icons.supervised_user_circle_outlined),
  reports('Reports', Icons.bar_chart_rounded),
  profile('Profile', Icons.person_outline_rounded);

  const CoordinatorTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// One section in a navigation bar or rail.
typedef NavEntry = ({
  String label,
  IconData icon,
  bool selected,
  VoidCallback onTap,
});

/// Phones: the coordinator's sections along the bottom, [current] in green.
class CoordinatorBottomBar extends StatelessWidget {
  const CoordinatorBottomBar({
    super.key,
    required this.current,
    required this.scale,
    required this.onSelect,
  });

  final CoordinatorTab current;
  final double scale;
  final ValueChanged<CoordinatorTab> onSelect;

  @override
  Widget build(BuildContext context) => NavBottomBar(
    scale: scale,
    entries: [
      for (final tab in CoordinatorTab.values)
        (
          label: tab.label,
          icon: tab.icon,
          selected: tab == current,
          onTap: () => onSelect(tab),
        ),
    ],
  );
}

/// Laptops: brand mark and the coordinator's sections down the left side.
class CoordinatorSideRail extends StatelessWidget {
  const CoordinatorSideRail({
    super.key,
    required this.current,
    required this.scale,
    required this.onSelect,
  });

  final CoordinatorTab current;
  final double scale;
  final ValueChanged<CoordinatorTab> onSelect;

  @override
  Widget build(BuildContext context) => NavSideRail(
    scale: scale,
    entries: [
      for (final tab in CoordinatorTab.values)
        (
          label: tab.label,
          icon: tab.icon,
          selected: tab == current,
          onTap: () => onSelect(tab),
        ),
    ],
  );
}

/// Phones: the sections along the bottom of the screen, [current] in green.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.current,
    required this.scale,
    required this.onSelect,
  });

  final AppTab current;
  final double scale;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) => NavBottomBar(
    scale: scale,
    entries: [
      for (final tab in AppTab.values)
        (
          label: tab.label,
          icon: tab.icon,
          selected: tab == current,
          onTap: () => onSelect(tab),
        ),
    ],
  );
}

/// Laptops: brand mark and the sections down the left side.
class AppSideRail extends StatelessWidget {
  const AppSideRail({
    super.key,
    required this.current,
    required this.scale,
    required this.onSelect,
  });

  final AppTab current;
  final double scale;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) => NavSideRail(
    scale: scale,
    entries: [
      for (final tab in AppTab.values)
        (
          label: tab.label,
          icon: tab.icon,
          selected: tab == current,
          onTap: () => onSelect(tab),
        ),
    ],
  );
}

/// A bar of [entries] along the bottom of the screen.
class NavBottomBar extends StatelessWidget {
  const NavBottomBar({super.key, required this.entries, required this.scale});

  final List<NavEntry> entries;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: AppColors.fieldBorder)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.06),
            blurRadius: 18 * s,
            offset: Offset(0, -4 * s),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(6 * s, 8 * s, 6 * s, 8 * s),
          child: Row(
            children: [
              for (final entry in entries)
                Expanded(
                  child: _NavItem(
                    label: entry.label,
                    icon: entry.icon,
                    selected: entry.selected,
                    scale: s,
                    rail: false,
                    onTap: entry.onTap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The brand mark and [entries] down the left side.
class NavSideRail extends StatelessWidget {
  const NavSideRail({super.key, required this.entries, required this.scale});

  final List<NavEntry> entries;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        border: const Border(right: BorderSide(color: AppColors.fieldBorder)),
      ),
      padding: EdgeInsets.fromLTRB(16 * s, 30 * s, 16 * s, 20 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 10 * s),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  FoodLinkLogo(width: 34 * s),
                  SizedBox(width: 10 * s),
                  Text(
                    'FoodLink',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 23 * s,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3 * s,
                      color: AppColors.brandDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 30 * s),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in entries)
                    Padding(
                      padding: EdgeInsets.only(bottom: 6 * s),
                      child: _NavItem(
                        label: entry.label,
                        icon: entry.icon,
                        selected: entry.selected,
                        scale: s,
                        rail: true,
                        onTap: entry.onTap,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One section in the navigation: icon over label in the phone's bottom bar,
/// or icon beside label in the laptop's side [rail].
class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.scale,
    required this.rail,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final double scale;
  final bool rail;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final selected = widget.selected;
    final color = selected ? AppColors.brand : AppColors.fieldIcon;
    final icon = Icon(
      widget.icon,
      size: (widget.rail ? 21 : 25) * s,
      color: color,
    );
    final label = Text(
      widget.label,
      maxLines: 1,
      style: TextStyle(
        fontSize: (widget.rail ? 15 : 12) * s,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: color,
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: '${widget.label} tab',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: widget.rail
                ? EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s)
                : EdgeInsets.symmetric(vertical: 5 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14 * s),
              color: selected && widget.rail
                  ? AppColors.roleChosenFill
                  : _hovered
                  ? AppColors.socialFill.withValues(alpha: 0.7)
                  : AppColors.white.withValues(alpha: 0),
            ),
            child: widget.rail
                ? Row(
                    children: [
                      icon,
                      SizedBox(width: 12 * s),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: label,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon,
                      SizedBox(height: 4 * s),
                      FittedBox(fit: BoxFit.scaleDown, child: label),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
