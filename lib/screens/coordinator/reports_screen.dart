import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/coordinator.dart';
import '../../navigation/transitions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/app_nav.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/coordinator_page.dart';
import '../../widgets/coordinator_widgets.dart';
import 'beneficiaries_screen.dart';
import 'event_details_screen.dart';
import 'events_screen.dart';
import 'volunteers_screen.dart';

/// Impact Reports, as in the Figma: a period picker (This Month, Last 3
/// Months, This Year), meals distributed, volunteers engaged and
/// communities served counting up, a bar chart of meals by month (the
/// period's months picked out; tap or hover a bar for its number), and
/// Download Report.
///
/// Each number opens the page behind it: Events, Volunteers or
/// Beneficiaries. Download Report copies the figures as CSV.
///
/// A photo of volunteers packing food fades into the backdrop.
class ImpactReportsScreen extends StatefulWidget {
  const ImpactReportsScreen({super.key});

  static const String routeName = 'coordinator-reports';

  @override
  State<ImpactReportsScreen> createState() => _ImpactReportsScreenState();
}

class _ImpactReportsScreenState extends State<ImpactReportsScreen> {
  ReportPeriod _period = reportPeriods.first;
  bool _choosing = false;
  int? _bar;

  void _download() {
    final csv = [
      'Period,${_period.label}',
      'Meals distributed,${_period.meals}',
      'Volunteers engaged,${_period.volunteers}',
      'Communities served,${_period.communities}',
      '',
      'Month,Meals',
      for (final (month, meals) in reportMonths) '$month,$meals',
    ].join('\n');
    Clipboard.setData(ClipboardData(text: csv));
    HapticFeedback.mediumImpact();
    showAuthNotice(
      context,
      'Report for ${_period.label.toLowerCase()} copied. Paste it into a '
      'spreadsheet.',
    );
  }

  void _share() {
    final text =
        '${CoordinatorBoard.organisation.value.name} · ${_period.label}: '
        '${formatCount(_period.meals)} meals shared by '
        '${_period.volunteers} volunteers across '
        '${_period.communities} communities. Thank you! 💚';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    showAuthNotice(context, 'Summary copied. Paste it anywhere to share.');
  }

  /// Progress towards the year's meal goal, as a ring.
  Widget _goal(double s, double time) {
    final year = reportPeriods.last.meals;
    final share = year / coordinatorMealGoal;
    return CoordinatorCard(
      scale: s,
      child: Row(
        children: [
          Semantics(
            label: '${(share * 100).round()} percent of the year’s goal',
            excludeSemantics: true,
            child: SizedBox.square(
              dimension: 92 * s,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: share),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 9 * s,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.stepTodo,
                      color: AppColors.brand,
                    ),
                    Center(
                      child: Text(
                        '${(value * 100).round()}%',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 22 * s,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 16 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2026 goal',
                  style: TextStyle(
                    fontSize: 13 * s,
                    color: AppColors.fieldIcon,
                  ),
                ),
                Text(
                  '${formatCount(coordinatorMealGoal)} meals',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 21 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 4 * s),
                Text(
                  '${formatCount(coordinatorMealGoal - year)} to go. Keep it up!',
                  style: TextStyle(
                    fontSize: 13.5 * s,
                    color: AppColors.bodyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// How the period's meals split across kinds of event.
  Widget _categories(double s) {
    return CoordinatorCard(
      scale: s,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Meals by kind of event',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 18 * s,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 14 * s),
          for (final (i, (label, share, icon)) in mealsByCategory.indexed)
            Padding(
              padding: EdgeInsets.only(bottom: 12 * s),
              child: Semantics(
                label:
                    '$label: ${formatCount((_period.meals * share).round())} '
                    'meals, ${(share * 100).round()} percent',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 17 * s, color: AppColors.leafLight),
                        SizedBox(width: 8 * s),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14 * s,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Text(
                          '${formatCount((_period.meals * share).round())} · '
                          '${(share * 100).round()}%',
                          style: TextStyle(
                            fontSize: 13 * s,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6 * s),
                    TweenAnimationBuilder<double>(
                      key: ValueKey('${_period.label}/$label'),
                      tween: Tween(begin: 0, end: share),
                      duration: Duration(milliseconds: 800 + i * 150),
                      curve: Curves.easeOutCubic,
                      builder: (context, fill, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(4 * s),
                        child: SizedBox(
                          height: 8 * s,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              const ColoredBox(color: AppColors.stepTodo),
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: fill,
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: AppColors.accentGradient,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  /// The events that served the most meals, each opening its page.
  Widget _topEvents(double s) {
    final events = [
      for (final managed in CoordinatorBoard.events.value)
        if (managed.mealsSoFar > 0) managed,
    ]..sort((a, b) => b.mealsSoFar.compareTo(a.mealsSoFar));
    return CoordinatorCard(
      scale: s,
      padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 6 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Top events',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 18 * s,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 6 * s),
          for (final (i, managed) in events.take(4).indexed) ...[
            if (i > 0) rowDivider(),
            TappableRow(
              label: '${managed.title}, ${managed.mealsSoFar} meals',
              scale: s,
              onTap: () => Navigator.of(context).push(
                softRoute(CoordinatorEventDetailsScreen(title: managed.title)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28 * s,
                    height: 28 * s,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == 0 ? AppColors.sun : AppColors.roleChosenFill,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12.5 * s,
                        fontWeight: FontWeight.w800,
                        color: i == 0 ? AppColors.white : AppColors.brand,
                      ),
                    ),
                  ),
                  SizedBox(width: 12 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          managed.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5 * s,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          '${managed.roster.length} volunteers · ${managed.event.when}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5 * s,
                            color: AppColors.fieldIcon,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${managed.mealsSoFar}',
                    style: TextStyle(
                      fontSize: 16 * s,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                  SizedBox(width: 4 * s),
                  Icon(
                    Icons.restaurant_rounded,
                    size: 14 * s,
                    color: AppColors.brand,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _open(Widget page, String? name) =>
      Navigator.of(context).push(softRoute(page, name: name));

  @override
  Widget build(BuildContext context) {
    return CoordinatorPage(
      tab: CoordinatorTab.reports,
      title: 'Impact Reports',
      photo: 'assets/images/impact_packing.jpg',
      action: (c) => Row(
        children: [
          Expanded(
            child: _DownloadButton(scale: c.scale, onTap: _download),
          ),
          SizedBox(width: 10 * c.scale),
          Semantics(
            button: true,
            label: 'Share summary',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: _share,
              child: Container(
                width: 58 * c.scale,
                height: 58 * c.scale,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(18 * c.scale),
                ),
                child: Icon(
                  Icons.ios_share_rounded,
                  size: 22 * c.scale,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: (context, c) {
        final s = c.scale;
        return [
          _periodPicker(s),
          SizedBox(height: 16 * s),
          for (final (i, (value, previous, label, icon, page, name)) in [
            (
              _period.meals,
              _period.previous.$1,
              'Meals Distributed',
              Icons.restaurant_rounded,
              const CoordinatorEventsScreen() as Widget,
              CoordinatorEventsScreen.routeName,
            ),
            (
              _period.volunteers,
              _period.previous.$2,
              'Volunteers Engaged',
              Icons.volunteer_activism_outlined,
              const CoordinatorVolunteersScreen(),
              CoordinatorVolunteersScreen.routeName,
            ),
            (
              _period.communities,
              _period.previous.$3,
              'Communities Served',
              Icons.groups_rounded,
              const BeneficiariesScreen(),
              BeneficiariesScreen.routeName,
            ),
          ].indexed)
            Padding(
              padding: EdgeInsets.only(bottom: 12 * s),
              child: _StatCard(
                key: ValueKey('${_period.label}/$label'),
                value: value,
                label: label,
                icon: icon,
                delay: i,
                change: ((value - previous) / previous * 100).round(),
                compare: _period.compareLabel,
                scale: s,
                onTap: () => _open(page, name),
              ),
            ),
          SizedBox(height: 10 * s),
          _chart(s),
          SizedBox(height: 16 * s),
          _goal(s, c.time),
          SizedBox(height: 16 * s),
          _categories(s),
          SizedBox(height: 16 * s),
          _topEvents(s),
        ];
      },
    );
  }

  /// The Figma's "This Month" box; opens the periods just below.
  Widget _periodPicker(double s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _choosing,
          label: 'Period: ${_period.label}',
          excludeSemantics: true,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _choosing = !_choosing);
              },
              child: Container(
                height: 52 * s,
                padding: EdgeInsets.symmetric(horizontal: 16 * s),
                decoration: BoxDecoration(
                  color: AppColors.socialFill.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14 * s),
                  border: Border.all(
                    color: _choosing ? AppColors.brand : AppColors.white,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 19 * s,
                      color: AppColors.leafLight,
                    ),
                    SizedBox(width: 10 * s),
                    Expanded(
                      child: Text(
                        _period.label,
                        style: TextStyle(
                          fontSize: 15.5 * s,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _choosing ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 24 * s,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_choosing
              ? const SizedBox(width: double.infinity)
              : Container(
                  margin: EdgeInsets.only(top: 8 * s),
                  padding: EdgeInsets.all(6 * s),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16 * s),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Column(
                    children: [
                      for (final period in reportPeriods)
                        Semantics(
                          button: true,
                          selected: period == _period,
                          label: period.label,
                          excludeSemantics: true,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _period = period;
                                _choosing = false;
                                _bar = null;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(12 * s),
                              decoration: BoxDecoration(
                                color: period == _period
                                    ? AppColors.roleChosenFill
                                    : AppColors.white.withValues(alpha: 0),
                                borderRadius: BorderRadius.circular(12 * s),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      period.label,
                                      style: TextStyle(
                                        fontSize: 15 * s,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  if (period == _period)
                                    Icon(
                                      Icons.check_rounded,
                                      size: 19 * s,
                                      color: AppColors.brand,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  /// Meals by month, the period's months in green and the rest pale.
  Widget _chart(double s) {
    final max = reportMonths.fold(0, (m, e) => e.$2 > m ? e.$2 : m);
    final inPeriod = reportMonths.length - _period.months;
    final selected = _bar ?? reportMonths.length - 1;
    final (month, meals) = reportMonths[selected];
    final chartHeight = 150 * s;
    return CoordinatorCard(
      scale: s,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Row(
              key: ValueKey(selected),
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formatCount(meals),
                  style: TextStyle(
                    fontSize: 22 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(width: 6 * s),
                Expanded(
                  child: Text(
                    'meals in $month',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14 * s,
                      color: AppColors.bodyText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14 * s),
          SizedBox(
            height: chartHeight + 28 * s,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, (label, value)) in reportMonths.indexed)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == selected,
                      label: '$label: ${formatCount(value)} meals',
                      excludeSemantics: true,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => setState(() => _bar = i),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _bar = i);
                          },
                          child: Column(
                            children: [
                              SizedBox(
                                height: chartHeight,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey('${_period.label}/$i'),
                                    tween: Tween(begin: 0, end: value / max),
                                    duration: Duration(
                                      milliseconds: 650 + i * 80,
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, grown, _) =>
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          width: (i == selected ? 30 : 26) * s,
                                          height: chartHeight * grown,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(5 * s),
                                            ),
                                            color: i >= inPeriod
                                                ? (i == selected
                                                      ? AppColors.brand
                                                      : AppColors.leafLight)
                                                : AppColors.roleChosenBorder,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8 * s),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12 * s,
                                    fontWeight: i == selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: i == selected
                                        ? AppColors.ink
                                        : AppColors.fieldIcon,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

/// A Figma stat card: icon in a pale circle, the number counting up, and
/// its label; opens the page behind the number.
class _StatCard extends StatefulWidget {
  const _StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.delay,
    required this.change,
    required this.compare,
    required this.scale,
    required this.onTap,
  });

  final int value;
  final String label;
  final IconData icon;
  final int delay;

  /// Percent change from the period before, and what it's compared with.
  final int change;
  final String compare;
  final double scale;
  final VoidCallback onTap;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Semantics(
      button: true,
      label: '${formatCount(widget.value)} ${widget.label}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.all(14 * s),
            transform: Matrix4.translationValues(0, _hovered ? -2 * s : 0, 0),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.white
                  : AppColors.roleChosenFill.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18 * s),
              border: Border.all(color: AppColors.white),
            ),
            child: Row(
              children: [
                Container(
                  width: 46 * s,
                  height: 46 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 22 * s,
                    color: AppColors.brand,
                  ),
                ),
                SizedBox(width: 14 * s),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: widget.value.toDouble()),
                    duration: Duration(milliseconds: 900 + widget.delay * 150),
                    curve: Curves.easeOutCubic,
                    builder: (context, shown, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatCount(shown.round()),
                          style: TextStyle(
                            fontSize: 22 * s,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 13.5 * s,
                            color: AppColors.bodyText,
                          ),
                        ),
                        SizedBox(height: 4 * s),
                        Row(
                          children: [
                            Icon(
                              widget.change >= 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 15 * s,
                              color: widget.change >= 0
                                  ? AppColors.leafMid
                                  : AppColors.badge,
                            ),
                            SizedBox(width: 4 * s),
                            Flexible(
                              child: Text(
                                '${widget.change >= 0 ? '+' : ''}${widget.change}% '
                                '${widget.compare}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12 * s,
                                  fontWeight: FontWeight.w600,
                                  color: widget.change >= 0
                                      ? AppColors.leafMid
                                      : AppColors.badge,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22 * s,
                  color: _hovered ? AppColors.brand : AppColors.fieldHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Figma's pale green Download Report button.
class _DownloadButton extends StatefulWidget {
  const _DownloadButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Semantics(
      button: true,
      label: 'Download Report',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            child: Container(
              height: 58 * s,
              decoration: BoxDecoration(
                color: AppColors.roleChosenFill,
                borderRadius: BorderRadius.circular(18 * s),
                border: Border.all(color: AppColors.roleChosenBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_rounded,
                    size: 21 * s,
                    color: AppColors.brand,
                  ),
                  SizedBox(width: 8 * s),
                  Text(
                    'Download Report',
                    style: TextStyle(
                      fontSize: 16.5 * s,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
