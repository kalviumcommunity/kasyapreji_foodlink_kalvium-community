import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/community.dart';
import '../data/my_events.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'auth_widgets.dart';
import 'community_widgets.dart';

/// "48,250".
String formatThousands(int value) {
  final digits = '$value';
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

int get _mealsThisYear => monthlyMeals.fold(0, (sum, month) => sum + month.$2);

/// Community's Impact tab: what everyone has achieved together this year.
class CommunityImpact extends StatelessWidget {
  const CommunityImpact({
    super.key,
    required this.scale,
    required this.wide,
    required this.time,
    required this.onSeeYourEvents,
  });

  final double scale;
  final bool wide;
  final double time;
  final VoidCallback onSeeYourEvents;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final together = _TogetherCard(scale: s, time: time);
    final goal = _GoalCard(scale: s, time: time);
    final chart = _MonthlyChart(scale: s);
    final share = _YourShareCard(scale: s, onTap: onSeeYourEvents);
    final top = TopVolunteersCard(scale: s);
    final gap = SizedBox(height: 18 * s);

    // Each card rises in a moment after the one before.
    Widget rise(int n, Widget child) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + n * 110),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 22 * s),
          child: child,
        ),
      ),
      child: child,
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          rise(0, together),
          gap,
          rise(1, goal),
          gap,
          rise(2, chart),
          gap,
          rise(3, share),
          gap,
          rise(4, top),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [rise(0, together), gap, rise(2, chart)],
          ),
        ),
        SizedBox(width: 22 * s),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [rise(1, goal), gap, rise(3, share), gap, rise(4, top)],
          ),
        ),
      ],
    );
  }
}

/// Frosted white card for the impact pieces.
class _Card extends StatelessWidget {
  const _Card({required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.all(18 * s),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24 * s),
        border: Border.all(color: AppColors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.07),
            blurRadius: 26 * s,
            offset: Offset(0, 10 * s),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.title,
    required this.scale,
    this.subtitle,
    this.icon = Icons.eco_rounded,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18 * s, color: AppColors.leafLight),
            SizedBox(width: 8 * s),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18.5 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (subtitle case final subtitle?) ...[
          SizedBox(height: 3 * s),
          Padding(
            padding: EdgeInsets.only(left: 26 * s),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 13 * s, color: AppColors.fieldIcon),
            ),
          ),
        ],
      ],
    );
  }
}

/// The year's headline on deep green: meals shared, counting up, then
/// volunteers, food saved and events.
class _TogetherCard extends StatelessWidget {
  const _TogetherCard({required this.scale, required this.time});

  final double scale;
  final double time;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final meals = _mealsThisYear;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26 * s),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brand, AppColors.leafMid],
          stops: [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.28),
            blurRadius: 30 * s,
            spreadRadius: -6 * s,
            offset: Offset(0, 16 * s),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _RipplePainter(time: time)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20 * s),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1600),
              curve: Curves.easeOutCubic,
              builder: (context, count, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.public_rounded,
                        size: 18 * s,
                        color: AppColors.logoOnDark,
                      ),
                      SizedBox(width: 8 * s),
                      Text(
                        'Together this year',
                        style: TextStyle(
                          fontSize: 14.5 * s,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10 * s),
                  Semantics(
                    container: true,
                    label: '${formatThousands(meals)} meals shared',
                    excludeSemantics: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatThousands((meals * count).round()),
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 46 * s,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(width: 10 * s),
                        Flexible(
                          child: Text(
                            'meals shared',
                            style: TextStyle(
                              fontSize: 16 * s,
                              fontWeight: FontWeight.w600,
                              color: AppColors.logoOnDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18 * s),
                  Row(
                    children: [
                      for (final (i, (value, unit, label, icon)) in [
                        (2140.0, '', 'Volunteers', Icons.groups_rounded),
                        (18.6, ' t', 'Food saved', Icons.eco_rounded),
                        (312.0, '', 'Events', Icons.event_available_rounded),
                      ].indexed) ...[
                        if (i > 0)
                          Container(
                            width: 1,
                            height: 40 * s,
                            margin: EdgeInsets.symmetric(horizontal: 12 * s),
                            color: AppColors.white.withValues(alpha: 0.2),
                          ),
                        Expanded(
                          child: Semantics(
                            container: true,
                            label: '${_number(value, unit)} $label',
                            excludeSemantics: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      icon,
                                      size: 14 * s,
                                      color: AppColors.logoOnDark,
                                    ),
                                    SizedBox(width: 5 * s),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _number(value * count, unit),
                                          style: TextStyle(
                                            fontSize: 19 * s,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2 * s),
                                Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5 * s,
                                    color: AppColors.white.withValues(
                                      alpha: 0.78,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _number(double value, String unit) => unit.isEmpty
      ? formatThousands(value.round())
      : '${value.toStringAsFixed(1)}$unit';
}

/// Soft rings spreading from a corner of a green card.
class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.time});

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width * 0.95, size.height * 0.05);
    for (var k = 0; k < 4; k++) {
      final p = (time * 2 + k / 4) % 1.0;
      canvas.drawCircle(
        centre,
        40 + p * size.width * 0.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = AppColors.white.withValues(alpha: 0.12 * (1 - p)),
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) => oldDelegate.time != time;
}

/// Progress towards the year's meal goal, as a ring that fills.
class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.scale, required this.time});

  final double scale;
  final double time;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final meals = _mealsThisYear;
    final share = meals / mealGoal;
    return _Card(
      scale: s,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: share),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) => Row(
          children: [
            Semantics(
              label: '${(share * 100).round()} percent of the goal',
              excludeSemantics: true,
              child: SizedBox.square(
                dimension: 104 * s,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: progress,
                    time: time,
                    width: 11 * s,
                  ),
                  child: Center(
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 26 * s,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 18 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2026 goal',
                    style: TextStyle(
                      fontSize: 13 * s,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4 * s,
                      color: AppColors.fieldIcon,
                    ),
                  ),
                  SizedBox(height: 2 * s),
                  Text(
                    '${formatThousands(mealGoal)} meals',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 22 * s,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 6 * s),
                  Text(
                    '${formatThousands(mealGoal - meals)} to go. At this '
                    'pace we’ll get there in November.',
                    style: TextStyle(
                      fontSize: 13.5 * s,
                      height: 1.45,
                      color: AppColors.bodyText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.time,
    required this.width,
  });

  final double progress;
  final double time;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(width / 2 + 2);
    canvas.drawArc(
      arc,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = AppColors.stepTodo,
    );
    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      arc,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.sweep(
          arc.center,
          [AppColors.leafLight, AppColors.brand],
          [0, 1],
          TileMode.clamp,
          -math.pi / 2,
          -math.pi / 2 + sweep,
        ),
    );
    // A soft glow pulsing at the leading end.
    final end = -math.pi / 2 + sweep;
    final tip =
        arc.center + Offset(math.cos(end), math.sin(end)) * (arc.width / 2);
    final pulse = (time * 4) % 1.0;
    canvas.drawCircle(
      tip,
      width * (0.6 + pulse),
      Paint()
        ..color = AppColors.leafLight.withValues(alpha: 0.35 * (1 - pulse)),
    );
    canvas.drawCircle(tip, width * 0.3, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => true;
}

/// Meals shared each month this year, as bars that grow in. The latest
/// month is picked out; tapping or hovering a bar shows its number.
class _MonthlyChart extends StatefulWidget {
  const _MonthlyChart({required this.scale});

  final double scale;

  @override
  State<_MonthlyChart> createState() => _MonthlyChartState();
}

class _MonthlyChartState extends State<_MonthlyChart> {
  late int _selected = monthlyMeals.length - 1;

  void _select(int i) {
    if (i == _selected) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = i);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    const ceiling = 8000;
    final chartHeight = 170 * s;
    final (month, meals) = monthlyMeals[_selected];
    final previous = _selected > 0 ? monthlyMeals[_selected - 1].$2 : null;
    final growth = previous == null
        ? null
        : ((meals - previous) / previous * 100).round();

    return _Card(
      scale: s,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(
            title: 'Meals shared each month',
            subtitle: '2026 so far · tap a month',
            icon: Icons.bar_chart_rounded,
            scale: s,
          ),
          SizedBox(height: 16 * s),
          // The chosen month's figure.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Row(
              key: ValueKey(_selected),
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formatThousands(meals),
                  style: TextStyle(
                    fontSize: 26 * s,
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
                if (growth != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * s,
                      vertical: 3 * s,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.roleChosenFill,
                      borderRadius: BorderRadius.circular(10 * s),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 14 * s,
                          color: AppColors.brand,
                        ),
                        SizedBox(width: 3 * s),
                        Text(
                          '+$growth%',
                          style: TextStyle(
                            fontSize: 12.5 * s,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 14 * s),
          SizedBox(
            height: chartHeight + 30 * s,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Recessive y-axis labels.
                SizedBox(
                  width: 28 * s,
                  child: Stack(
                    children: [
                      for (final value in [0, 4000, 8000])
                        Positioned(
                          left: 0,
                          top: math.max(
                            0,
                            chartHeight * (1 - value / ceiling) - 7 * s,
                          ),
                          child: Text(
                            value == 0 ? '0' : '${value ~/ 1000}k',
                            style: TextStyle(
                              fontSize: 11 * s,
                              color: AppColors.fieldHint,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      for (final value in [0, 4000, 8000])
                        Positioned(
                          left: 0,
                          right: 0,
                          top: chartHeight * (1 - value / ceiling),
                          child: Container(
                            height: 1,
                            color: AppColors.fieldBorder.withValues(
                              alpha: value == 0 ? 1 : 0.6,
                            ),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, (label, value))
                              in monthlyMeals.indexed)
                            Expanded(
                              child: _Bar(
                                label: label,
                                value: value,
                                fraction: value / ceiling,
                                selected: i == _selected,
                                delay: i,
                                chartHeight: chartHeight,
                                scale: s,
                                onSelect: () => _select(i),
                              ),
                            ),
                        ],
                      ),
                    ],
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

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.selected,
    required this.delay,
    required this.chartHeight,
    required this.scale,
    required this.onSelect,
  });

  final String label;
  final int value;
  final double fraction;
  final bool selected;
  final int delay;
  final double chartHeight;
  final double scale;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label: ${formatThousands(value)} meals',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onSelect(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSelect,
          child: Column(
            children: [
              SizedBox(
                height: chartHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction),
                    duration: Duration(milliseconds: 700 + delay * 70),
                    curve: Curves.easeOutCubic,
                    builder: (context, grown, _) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: (selected ? 18 : 14) * s,
                      height: chartHeight * grown,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(5 * s),
                        ),
                        gradient: selected
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [AppColors.leafLight, AppColors.brand],
                              )
                            : null,
                        color: selected ? null : AppColors.roleChosenBorder,
                        boxShadow: [
                          if (selected)
                            BoxShadow(
                              color: AppColors.brand.withValues(alpha: 0.3),
                              blurRadius: 10 * s,
                              offset: Offset(0, 4 * s),
                            ),
                        ],
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
                    fontSize: 11.5 * s,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.ink : AppColors.fieldIcon,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The volunteer's own part in the year's total.
class _YourShareCard extends StatelessWidget {
  const _YourShareCard({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final hours = pastVisits.fold(0, (sum, visit) => sum + visit.hours);
    final helped = pastVisits.fold(0, (sum, visit) => sum + visit.helped);
    return _Card(
      scale: s,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MemberAvatar(member: you, size: 46 * s),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your share',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 18.5 * s,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 2 * s),
                    Text(
                      'Top 10% of volunteers this year',
                      style: TextStyle(
                        fontSize: 13 * s,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tagFoodText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40 * s,
                height: 40 * s,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tagFoodFill,
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 22 * s,
                  color: AppColors.sun,
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * s),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'You’ve given '),
                TextSpan(
                  text: '$hours hours',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
                const TextSpan(text: ' across '),
                TextSpan(
                  text: '${pastVisits.length} events',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
                const TextSpan(text: ' and helped '),
                TextSpan(
                  text: '${formatThousands(helped)} people',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
                const TextSpan(text: '. Thank you!'),
              ],
            ),
            style: TextStyle(
              fontSize: 15 * s,
              height: 1.5,
              color: AppColors.bodyText,
            ),
          ),
          SizedBox(height: 12 * s),
          Align(
            alignment: Alignment.centerLeft,
            child: AuthTextLink(
              label: 'See your events',
              scale: s,
              fontSize: 15,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

/// This month's volunteers with the most hours, the volunteer's own row
/// picked out.
class TopVolunteersCard extends StatelessWidget {
  const TopVolunteersCard({super.key, required this.scale});

  final double scale;

  static const _medals = [
    Color(0xFFE0A63A),
    Color(0xFFA9B4BE),
    Color(0xFFC08457),
  ];

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final most = topVolunteers.first.$2;
    return _Card(
      scale: s,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(
            title: 'Top volunteers this month',
            subtitle: 'By hours given',
            icon: Icons.emoji_events_outlined,
            scale: s,
          ),
          SizedBox(height: 12 * s),
          for (final (i, (member, hours)) in topVolunteers.indexed)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: hours / most),
              duration: Duration(milliseconds: 900 + i * 100),
              curve: Curves.easeOutCubic,
              builder: (context, fill, _) => Container(
                margin: EdgeInsets.only(top: 6 * s),
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * s,
                  vertical: 8 * s,
                ),
                decoration: BoxDecoration(
                  color: member.you
                      ? AppColors.roleChosenFill
                      : AppColors.white.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(14 * s),
                  border: Border.all(
                    color: member.you
                        ? AppColors.roleChosenBorder
                        : AppColors.white.withValues(alpha: 0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24 * s,
                      height: 24 * s,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < 3 ? _medals[i] : AppColors.socialFill,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12 * s,
                          fontWeight: FontWeight.w700,
                          color: i < 3 ? AppColors.white : AppColors.bodyText,
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * s),
                    MemberAvatar(member: member, size: 34 * s),
                    SizedBox(width: 10 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.you ? 'You' : member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5 * s,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 5 * s),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3 * s),
                            child: SizedBox(
                              height: 6 * s,
                              child: Stack(
                                children: [
                                  Container(color: AppColors.stepTodo),
                                  FractionallySizedBox(
                                    widthFactor: fill,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: member.you
                                              ? const [
                                                  AppColors.sun,
                                                  AppColors.earthLight,
                                                ]
                                              : AppColors.accentGradient,
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
                    ),
                    SizedBox(width: 12 * s),
                    Text(
                      '$hours hrs',
                      style: TextStyle(
                        fontSize: 13.5 * s,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
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

/// Laptops, beside the feed: this month at a glance.
class CommunityPulseCard extends StatelessWidget {
  const CommunityPulseCard({
    super.key,
    required this.scale,
    required this.time,
  });

  final double scale;
  final double time;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final (month, meals) = monthlyMeals.last;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24 * s),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brand, AppColors.leafMid],
          stops: [0, 0.55, 1],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _RipplePainter(time: time)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(18 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This month in $month',
                  style: TextStyle(
                    fontSize: 13.5 * s,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
                SizedBox(height: 6 * s),
                Text(
                  '${formatThousands(meals)} meals',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 30 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 4 * s),
                Text(
                  'shared by our community across 14 events',
                  style: TextStyle(
                    fontSize: 13.5 * s,
                    color: AppColors.logoOnDark,
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
