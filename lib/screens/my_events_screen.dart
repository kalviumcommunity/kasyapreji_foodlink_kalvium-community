import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/event_plans.dart';
import '../data/join_options.dart';
import '../data/my_events.dart';
import '../data/sample_events.dart';
import '../navigation/tab_navigation.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/app_nav.dart';
import '../widgets/asset_photo.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/event_tile.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/page_scene.dart';
import '../widgets/primary_button.dart';
import '../widgets/rise_in.dart';
import '../widgets/soft_backdrop.dart';

/// My Events: what the volunteer has signed up for, and what they've done.
///
/// Upcoming leads with their next event on a green card, then lists every
/// event they've joined by month, each with the role they chose. Opening one
/// shows its details, where they can also leave it; it drops off the list
/// straight away. Past starts with their impact so far, counting up, and
/// lists the events they went to with the role and hours given; opening one
/// shows a recap with the organiser's thank-you note and any certificate.
///
/// The tabs slide between Upcoming and Past, and phones can also swipe
/// between them. A photo of a harvest fades into the soft backdrop behind
/// the title.
///
/// Phones follow the Figma frame with the bottom navigation bar; laptops get
/// the side navigation rail and the events as a two-column grid of cards.
class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key, this.showPast = false});

  static const String routeName = 'my-events';

  static const String photo = 'assets/images/event_harvest_greens.jpg';

  /// Opens on the Past tab.
  final bool showPast;

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen>
    with TickerProviderStateMixin {
  final _photo = AssetPhoto(MyEventsScreen.photo);
  late bool _past = widget.showPast;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  /// Staggered entrance progress (0–1) for the n-th element.
  double _rise(int n) {
    final start = (n * 0.07).clamp(0.0, 0.6);
    return Curves.easeOutCubic.transform(
      ((_intro.value - start) / 0.4).clamp(0.0, 1.0),
    );
  }

  /// The events the volunteer has joined, soonest first.
  List<VolunteerEvent> get _upcoming => [
    for (final event in sampleEvents)
      if (EventPlans.hasJoined(event.title)) event,
  ]..sort((a, b) => eventDay(a).compareTo(eventDay(b)));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _photo.resolve(context, () {
      if (mounted) setState(() {});
    });
    for (final event in sampleEvents) {
      precacheImage(AssetImage(event.photo), context);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _photo.dispose();
    super.dispose();
  }

  void _openTab(AppTab tab) => openAppTab(context, AppTab.events, tab);

  void _show({required bool past}) {
    if (past == _past) return;
    HapticFeedback.selectionClick();
    setState(() => _past = past);
  }

  static Object _heroTag(VolunteerEvent event) => 'events/${event.title}';

  void _openEvent(VolunteerEvent event) => openEventDetails(
    context,
    event,
    from: AppTab.events,
    heroTag: _heroTag(event),
  );

  void _openVisit(PastVisit visit, {required bool wide, required double s}) {
    HapticFeedback.selectionClick();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: AppColors.ink.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, _, _) => _VisitRecap(
        visit: visit,
        wide: wide,
        scale: s,
        onFindSimilar: () {
          Navigator.of(context).pop();
          _openTab(AppTab.explore);
        },
      ),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: wide
              ? ScaleTransition(
                  scale: Tween(begin: 0.94, end: 1.0).animate(curved),
                  child: child,
                )
              : SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backdrop.first,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final wide =
                size.width >= OnboardingLayout.wideBreakpoint &&
                size.width > size.height;
            final s = wide
                ? math
                      .min(size.width / 1280, size.height / 800)
                      .clamp(0.75, 1.25)
                : math.min(
                    size.width / OnboardingLayout.designWidth,
                    size.height / OnboardingLayout.designHeight,
                  );
            final railWidth = wide ? 224 * s : 0.0;
            return AnimatedBuilder(
              animation: Listenable.merge([
                _intro,
                _ambient,
                EventPlans.joined,
              ]),
              builder: (context, _) => Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SoftBackdropPainter(
                        time: _ambient.value,
                        palette: SoftBackdropPalette.warm,
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(painter: DotTexturePainter()),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: PageScenePainter(
                          photo: _photo.image,
                          time: _ambient.value,
                          reveal: _rise(0),
                          appear: _rise(4),
                          left: railWidth,
                          scale: s,
                          height: 300,
                          focus: const Alignment(0, 0.3),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: wide
                        ? _buildWide(size, s, railWidth)
                        : _buildCompact(size, s),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone layout
  // ---------------------------------------------------------------------------

  Widget _buildCompact(Size size, double s) {
    // On tablets held upright, keep things a comfortable width.
    final width = math.min(size.width, 520 * s);
    return Column(
      children: [
        Expanded(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24 * s, 14 * s, 24 * s, 28 * s),
              child: Center(
                child: SizedBox(
                  width: width - 48 * s,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RiseIn(
                        progress: _rise(0),
                        distance: -10 * s,
                        child: _headerRow(s),
                      ),
                      SizedBox(height: 22 * s),
                      RiseIn(
                        progress: _rise(1),
                        distance: 18 * s,
                        child: _title(s, 40 * s),
                      ),
                      SizedBox(height: 22 * s),
                      RiseIn(
                        progress: _rise(2),
                        distance: 18 * s,
                        child: _segments(s),
                      ),
                      SizedBox(height: 22 * s),
                      // Swipe sideways to change tab.
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragEnd: (details) {
                          final v = details.primaryVelocity ?? 0;
                          if (v < -250) _show(past: true);
                          if (v > 250) _show(past: false);
                        },
                        child: _content(s, wide: false, columns: 1, gap: 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        AppBottomBar(current: AppTab.events, scale: s, onSelect: _openTab),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Laptop layout
  // ---------------------------------------------------------------------------

  Widget _buildWide(Size size, double s, double railWidth) {
    final mainWidth = math.min(size.width - railWidth, 1080 * s);
    final content = mainWidth - 96 * s;
    final columns = content >= 720 ? 2 : 1;

    return Row(
      children: [
        SizedBox(
          width: railWidth,
          child: AppSideRail(
            current: AppTab.events,
            scale: s,
            onSelect: _openTab,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 30 * s),
            child: Center(
              child: SizedBox(
                width: mainWidth,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RiseIn(
                        progress: _rise(0),
                        distance: -10 * s,
                        child: _headerRow(s),
                      ),
                      SizedBox(height: 22 * s),
                      RiseIn(
                        progress: _rise(1),
                        distance: 20 * s,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _title(s, 52 * s),
                            SizedBox(height: 6 * s),
                            Text(
                              'Everything you’ve signed up for, and all '
                              'you’ve given so far.',
                              style: TextStyle(
                                fontSize: 17 * s,
                                color: AppColors.bodyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 26 * s),
                      RiseIn(
                        progress: _rise(2),
                        distance: 20 * s,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 460 * s),
                            child: _segments(s),
                          ),
                        ),
                      ),
                      SizedBox(height: 26 * s),
                      _content(s, wide: true, columns: columns, gap: 20 * s),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------------

  /// Back button (when there's somewhere to go back to) and the avatar.
  Widget _headerRow(double s) {
    return Row(
      children: [
        if (Navigator.of(context).canPop())
          AuthIconButton(
            label: 'Back',
            scale: s,
            onTap: () => Navigator.of(context).maybePop(),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18 * s,
              color: AppColors.ink,
            ),
          ),
        const Spacer(),
        AuthAvatar(scale: s * 1.1),
      ],
    );
  }

  Widget _title(double s, double fontSize) {
    return Semantics(
      header: true,
      child: Text(
        'My Events',
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: fontSize,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -fontSize * 0.01,
          color: AppColors.ink,
        ),
      ),
    );
  }

  Widget _segments(double s) {
    return _Segments(
      past: _past,
      upcomingCount: _upcoming.length,
      pastCount: pastVisits.length,
      scale: s,
      onChanged: (past) => _show(past: past),
    );
  }

  /// The chosen tab's events, sliding in from the side they're on.
  Widget _content(
    double s, {
    required bool wide,
    required int columns,
    required double gap,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        final fromRight = child.key == const ValueKey('past');
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: Offset(fromRight ? 0.08 : -0.08, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_past ? 'past' : 'upcoming'),
        child: _past
            ? _pastList(s, wide: wide, columns: columns, gap: gap)
            : _upcomingList(s, wide: wide, columns: columns, gap: gap),
      ),
    );
  }

  Widget _upcomingList(
    double s, {
    required bool wide,
    required int columns,
    required double gap,
  }) {
    final events = _upcoming;
    if (events.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 30 * s),
        child: _EmptyUpcoming(
          scale: s,
          time: _ambient.value,
          onExplore: () => _openTab(AppTab.explore),
        ),
      );
    }
    final next = events.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RiseIn(
          progress: _rise(3),
          distance: 20 * s,
          child: _NextUpCard(
            event: next,
            details: EventPlans.detailsFor(next.title),
            count: events.length,
            hours: _plannedHours(events),
            time: _ambient.value,
            scale: s,
            onTap: () => _openEvent(next),
          ),
        ),
        ..._byMonth(
          s,
          items: events,
          day: eventDay,
          wide: wide,
          columns: columns,
          gap: gap,
          first: 4,
          row: (event) => _EventRow(
            event: event,
            heroTag: _heroTag(event),
            chips: [
              if (EventPlans.detailsFor(event.title) case final details?) ...[
                (details.role.icon, details.role.name),
                (details.slot.icon, details.slot.name),
              ],
            ],
            badge: null,
            card: wide,
            scale: s,
            onTap: () => _openEvent(event),
          ),
        ),
      ],
    );
  }

  Widget _pastList(
    double s, {
    required bool wide,
    required int columns,
    required double gap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ImpactCard(visits: pastVisits, time: _ambient.value, scale: s),
        ..._byMonth(
          s,
          items: pastVisits,
          day: (visit) => eventDay(visit.event),
          wide: wide,
          columns: columns,
          gap: gap,
          first: 0,
          row: (visit) => _EventRow(
            event: visit.event,
            heroTag: 'past/${visit.event.title}',
            chips: [
              (visit.roleIcon, visit.role),
              (Icons.schedule_rounded, '${visit.hours} hrs'),
            ],
            badge: visit.certificate
                ? Icons.workspace_premium_rounded
                : Icons.check_circle_rounded,
            card: wide,
            scale: s,
            onTap: () => _openVisit(visit, wide: wide, s: s),
          ),
        ),
      ],
    );
  }

  /// [items] under a heading for each month, as rows with lines between
  /// them (phones) or a grid of cards (laptops).
  List<Widget> _byMonth<T>(
    double s, {
    required List<T> items,
    required DateTime Function(T) day,
    required Widget Function(T) row,
    required bool wide,
    required int columns,
    required double gap,
    required int first,
  }) {
    final months = <String, List<T>>{};
    for (final item in items) {
      months.putIfAbsent(monthLabel(day(item)), () => []).add(item);
    }
    var n = first;
    final children = <Widget>[];
    for (final MapEntry(key: month, value: entries) in months.entries) {
      children.add(
        RiseIn(
          progress: _rise(n),
          distance: 18 * s,
          child: Padding(
            padding: EdgeInsets.only(
              top: 26 * s,
              bottom: wide ? 16 * s : 4 * s,
            ),
            child: _MonthLabel(label: month, count: entries.length, scale: s),
          ),
        ),
      );
      if (wide) {
        children.add(
          LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final (i, item) in entries.indexed)
                    SizedBox(
                      width: width,
                      child: RiseIn(
                        progress: _rise(n + 1 + i ~/ columns),
                        distance: 22 * s,
                        child: row(item),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      } else {
        for (final (i, item) in entries.indexed) {
          children.add(
            RiseIn(
              progress: _rise(n + 1 + i),
              distance: 20 * s,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (i > 0)
                    Container(
                      height: 1,
                      margin: EdgeInsets.symmetric(vertical: 16 * s),
                      color: AppColors.fieldBorder,
                    )
                  else
                    SizedBox(height: 14 * s),
                  row(item),
                ],
              ),
            ),
          );
        }
      }
      n += 1 + entries.length;
    }
    return children;
  }

  /// Hours the volunteer will give across [events], halving those where
  /// they come for half the time.
  double _plannedHours(List<VolunteerEvent> events) {
    var total = 0.0;
    for (final event in events) {
      final hours = double.tryParse(event.duration.split(' ').first) ?? 0;
      final slot = EventPlans.detailsFor(event.title)?.slot;
      total += slot == null || slot.name == 'Full Event' ? hours : hours / 2;
    }
    return total;
  }
}

/// "4" or "2.5".
String _hours(double value) => value == value.roundToDouble()
    ? '${value.round()}'
    : value.toStringAsFixed(1);

/// "1,810".
String _thousands(int value) {
  final digits = '$value';
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// Upcoming | Past on a grey track, with a white pill and a green underline
/// sliding to the chosen one, and how many events each holds.
class _Segments extends StatelessWidget {
  const _Segments({
    required this.past,
    required this.upcomingCount,
    required this.pastCount,
    required this.scale,
    required this.onChanged,
  });

  final bool past;
  final int upcomingCount;
  final int pastCount;
  final double scale;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      height: 58 * s,
      padding: EdgeInsets.all(5 * s),
      decoration: BoxDecoration(
        color: AppColors.socialFill.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18 * s),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.7)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            alignment: past ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14 * s),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.08),
                      blurRadius: 12 * s,
                      offset: Offset(0, 3 * s),
                    ),
                  ],
                ),
                alignment: Alignment.bottomCenter,
                padding: EdgeInsets.only(bottom: 4 * s),
                // The green underline from the Figma.
                child: FractionallySizedBox(
                  widthFactor: 0.62,
                  child: Container(
                    height: 3 * s,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.accentGradient,
                      ),
                      borderRadius: BorderRadius.circular(2 * s),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (isPast, label, count) in [
                (false, 'Upcoming', upcomingCount),
                (true, 'Past', pastCount),
              ])
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: isPast == past,
                    label: '$label events',
                    excludeSemantics: true,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(isPast),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 17 * s,
                                fontWeight: isPast == past
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isPast == past
                                    ? AppColors.brand
                                    : AppColors.bodyText,
                              ),
                              child: Text(label),
                            ),
                            SizedBox(width: 8 * s),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: EdgeInsets.symmetric(
                                horizontal: 7 * s,
                                vertical: 2 * s,
                              ),
                              decoration: BoxDecoration(
                                color: isPast == past
                                    ? AppColors.roleChosenFill
                                    : AppColors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(10 * s),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 12.5 * s,
                                  fontWeight: FontWeight.w700,
                                  color: isPast == past
                                      ? AppColors.brand
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
        ],
      ),
    );
  }
}

/// "SEPTEMBER 2026 ───── 3".
class _MonthLabel extends StatelessWidget {
  const _MonthLabel({
    required this.label,
    required this.count,
    required this.scale,
  });

  final String label;
  final int count;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      header: true,
      label: label,
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_rounded,
            size: 16 * s,
            color: AppColors.leafLight,
          ),
          SizedBox(width: 8 * s),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 13 * s,
              letterSpacing: 1.4 * s,
              fontWeight: FontWeight.w700,
              color: AppColors.fieldIcon,
            ),
          ),
          SizedBox(width: 12 * s),
          Expanded(child: Container(height: 1, color: AppColors.fieldBorder)),
          SizedBox(width: 12 * s),
          Text(
            count == 1 ? '1 event' : '$count events',
            style: TextStyle(
              fontSize: 12.5 * s,
              fontWeight: FontWeight.w600,
              color: AppColors.fieldHint,
            ),
          ),
        ],
      ),
    );
  }
}

/// One event in the Figma's row style: the square photo, then the title,
/// date and time, and place, with small [chips] below (role, slot or hours)
/// and an optional [badge] on the photo. On laptops it sits in a [card].
class _EventRow extends StatefulWidget {
  const _EventRow({
    required this.event,
    required this.heroTag,
    required this.chips,
    required this.badge,
    required this.card,
    required this.scale,
    required this.onTap,
  });

  final VolunteerEvent event;
  final Object heroTag;
  final List<(IconData, String)> chips;
  final IconData? badge;
  final bool card;
  final double scale;
  final VoidCallback onTap;

  @override
  State<_EventRow> createState() => _EventRowState();
}

class _EventRowState extends State<_EventRow> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final event = widget.event;
    final grey = TextStyle(fontSize: 15 * s, color: AppColors.fieldIcon);

    final row = Row(
      children: [
        SizedBox.square(
          dimension: 104 * s,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: widget.heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20 * s),
                  child: AnimatedScale(
                    scale: _hovered ? 1.07 : 1,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    child: EventPhoto(event: event),
                  ),
                ),
              ),
              if (widget.badge case final badge?)
                Positioned(
                  right: 6 * s,
                  top: 6 * s,
                  child: Container(
                    width: 26 * s,
                    height: 26 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badge == Icons.workspace_premium_rounded
                          ? AppColors.sun
                          : AppColors.brand,
                      border: Border.all(color: AppColors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.25),
                          blurRadius: 6 * s,
                        ),
                      ],
                    ),
                    child: Icon(badge, size: 15 * s, color: AppColors.white),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 18 * s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17.5 * s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 8 * s),
              Text(
                event.when,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: grey,
              ),
              SizedBox(height: 5 * s),
              Text(
                event.place,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: grey,
              ),
              if (widget.chips.isNotEmpty) ...[
                SizedBox(height: 9 * s),
                Wrap(
                  spacing: 6 * s,
                  runSpacing: 6 * s,
                  children: [
                    for (final (icon, label) in widget.chips)
                      _Chip(icon: icon, label: label, scale: s),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 6 * s),
        AnimatedSlide(
          offset: Offset(_hovered ? 0.25 : 0, 0),
          duration: const Duration(milliseconds: 250),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 24 * s,
            color: _hovered ? AppColors.brand : AppColors.fieldHint,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      label: '${event.title}. ${event.when}. ${event.place}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(
                0,
                widget.card && _hovered ? -4 * s : 0,
                0,
              ),
              padding: widget.card ? EdgeInsets.all(12 * s) : EdgeInsets.zero,
              decoration: widget.card
                  ? BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(24 * s),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(
                            alpha: _hovered ? 0.14 : 0.06,
                          ),
                          blurRadius: 26 * s,
                          offset: Offset(0, 10 * s),
                        ),
                      ],
                    )
                  : null,
              child: row,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small pale green pill: the role, time slot or hours.
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.scale});

  final IconData icon;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
      decoration: BoxDecoration(
        color: AppColors.roleChosenFill,
        borderRadius: BorderRadius.circular(10 * s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13 * s, color: AppColors.brand),
          SizedBox(width: 4 * s),
          Text(
            label,
            style: TextStyle(
              fontSize: 12 * s,
              fontWeight: FontWeight.w600,
              color: AppColors.brand,
            ),
          ),
        ],
      ),
    );
  }
}

/// The volunteer's next event on deep green: what it is, when and where,
/// their role, and how many events and hours they've planned in all.
class _NextUpCard extends StatefulWidget {
  const _NextUpCard({
    required this.event,
    required this.details,
    required this.count,
    required this.hours,
    required this.time,
    required this.scale,
    required this.onTap,
  });

  final VolunteerEvent event;
  final JoinDetails? details;
  final int count;
  final double hours;
  final double time;
  final double scale;
  final VoidCallback onTap;

  @override
  State<_NextUpCard> createState() => _NextUpCardState();
}

class _NextUpCardState extends State<_NextUpCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final event = widget.event;
    final details = widget.details;
    final white = AppColors.white;
    final soft = AppColors.white.withValues(alpha: 0.82);
    // "Sat, 20 Sep 2026" → Sat, 20, Sep.
    final parts = event.date.replaceAll(',', '').split(' ');
    final (weekday, day, month) = parts.length >= 3
        ? (parts[0], parts[1], parts[2])
        : ('', event.date, '');

    return Semantics(
      button: true,
      label: 'Next up: ${event.title}, ${event.date}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            transform: Matrix4.translationValues(0, _hovered ? -3 * s : 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26 * s),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandDark,
                  AppColors.brand,
                  AppColors.leafMid,
                ],
                stops: [0, 0.55, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(
                    alpha: _hovered ? 0.4 : 0.28,
                  ),
                  blurRadius: 30 * s,
                  spreadRadius: -6 * s,
                  offset: Offset(0, 16 * s),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // The event's photo glowing through on the right.
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: 0.48,
                      heightFactor: 1,
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [Color(0x00FFFFFF), Color(0x66FFFFFF)],
                        ).createShader(rect),
                        child: EventPhoto(event: event),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _GlintPainter(time: widget.time),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(18 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10 * s,
                                    vertical: 4 * s,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withValues(
                                      alpha: 0.18,
                                    ),
                                    borderRadius: BorderRadius.circular(12 * s),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _PulseDot(time: widget.time, scale: s),
                                      SizedBox(width: 6 * s),
                                      Text(
                                        'Next up',
                                        style: TextStyle(
                                          fontSize: 12.5 * s,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4 * s,
                                          color: white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 12 * s),
                                Text(
                                  event.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppFonts.display,
                                    fontSize: 22 * s,
                                    height: 1.15,
                                    fontWeight: FontWeight.w700,
                                    color: white,
                                  ),
                                ),
                                SizedBox(height: 8 * s),
                                for (final (icon, text) in [
                                  (Icons.schedule_rounded, event.hours),
                                  (Icons.place_outlined, event.place),
                                ])
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 4 * s),
                                    child: Row(
                                      children: [
                                        Icon(icon, size: 15 * s, color: soft),
                                        SizedBox(width: 6 * s),
                                        Expanded(
                                          child: Text(
                                            text,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14 * s,
                                              color: soft,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12 * s),
                          // Calendar page.
                          Container(
                            width: 64 * s,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16 * s),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.ink.withValues(alpha: 0.25),
                                  blurRadius: 16 * s,
                                  offset: Offset(0, 6 * s),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 4 * s,
                                  ),
                                  color: AppColors.sun,
                                  child: Text(
                                    month.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11.5 * s,
                                      letterSpacing: 1.1 * s,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 2 * s),
                                Text(
                                  day,
                                  style: TextStyle(
                                    fontFamily: AppFonts.display,
                                    fontSize: 26 * s,
                                    height: 1.1,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 7 * s),
                                  child: Text(
                                    weekday.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.5 * s,
                                      letterSpacing: 1 * s,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.fieldIcon,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12 * s),
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: details == null
                                  ? null
                                  : Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10 * s,
                                        vertical: 6 * s,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.white.withValues(
                                          alpha: 0.16,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12 * s,
                                        ),
                                        border: Border.all(
                                          color: AppColors.white.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            details.role.icon,
                                            size: 14 * s,
                                            color: white,
                                          ),
                                          SizedBox(width: 6 * s),
                                          Flexible(
                                            child: Text(
                                              '${details.role.name} · '
                                              '${details.slot.name}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12.5 * s,
                                                fontWeight: FontWeight.w600,
                                                color: white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(width: 10 * s),
                          Text(
                            '${widget.count} planned · '
                            '${_hours(widget.hours)} hrs',
                            style: TextStyle(
                              fontSize: 12.5 * s,
                              fontWeight: FontWeight.w600,
                              color: soft,
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
        ),
      ),
    );
  }
}

/// A soft white dot that breathes.
class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.time, required this.scale});

  final double time;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final pulse = (time * 4) % 1.0;
    return SizedBox.square(
      dimension: 10 * s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 10 * s * (0.6 + 0.4 * pulse),
            height: 10 * s * (0.6 + 0.4 * pulse),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.logoOnDark.withValues(alpha: 0.6 * (1 - pulse)),
            ),
          ),
          Container(
            width: 6 * s,
            height: 6 * s,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.logoOnDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Faint rings and a slow diagonal glint across a green card.
class _GlintPainter extends CustomPainter {
  _GlintPainter({required this.time});

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.white.withValues(alpha: 0.07);
    final centre = Offset(size.width * 0.08, size.height * 1.05);
    for (var r = 60.0; r < size.width; r += 46) {
      canvas.drawCircle(centre, r + 6 * math.sin(time * 2 * math.pi), ring);
    }
    // A glint sweeps across once in each loop.
    final t = (time * 2) % 1.0;
    if (t < 0.35) {
      final x = (t / 0.35) * (size.width + 200) - 100;
      canvas.save();
      canvas.translate(x, size.height / 2);
      canvas.rotate(math.pi / 7);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 70,
          height: size.height * 3,
        ),
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(-35, 0),
            const Offset(35, 0),
            [
              AppColors.white.withValues(alpha: 0),
              AppColors.white.withValues(alpha: 0.12),
              AppColors.white.withValues(alpha: 0),
            ],
            [0, 0.5, 1],
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GlintPainter oldDelegate) => oldDelegate.time != time;
}

/// The volunteer's totals from their past events, counting up: events,
/// hours and people helped.
class _ImpactCard extends StatelessWidget {
  const _ImpactCard({
    required this.visits,
    required this.time,
    required this.scale,
  });

  final List<PastVisit> visits;
  final double time;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final hours = visits.fold(0, (sum, visit) => sum + visit.hours);
    final helped = visits.fold(0, (sum, visit) => sum + visit.helped);
    final certificates = visits.where((visit) => visit.certificate).length;
    final stats = [
      (visits.length, 'Events', Icons.event_available_rounded),
      (hours, 'Hours', Icons.schedule_rounded),
      (helped, 'People helped', Icons.favorite_rounded),
    ];

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
              child: CustomPaint(painter: _GlintPainter(time: time)),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20 * s, 18 * s, 20 * s, 18 * s),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (context, count, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.eco_rounded,
                        size: 18 * s,
                        color: AppColors.logoOnDark,
                      ),
                      SizedBox(width: 8 * s),
                      Expanded(
                        child: Text(
                          'Your impact so far',
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 19 * s,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      if (certificates > 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 9 * s,
                            vertical: 4 * s,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sun,
                            borderRadius: BorderRadius.circular(12 * s),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.workspace_premium_rounded,
                                size: 14 * s,
                                color: AppColors.white,
                              ),
                              SizedBox(width: 4 * s),
                              Text(
                                '$certificates certificates',
                                style: TextStyle(
                                  fontSize: 12 * s,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16 * s),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        for (final (i, (value, label, icon))
                            in stats.indexed) ...[
                          if (i > 0)
                            Container(
                              width: 1,
                              margin: EdgeInsets.symmetric(horizontal: 12 * s),
                              color: AppColors.white.withValues(alpha: 0.2),
                            ),
                          Expanded(
                            child: Semantics(
                              container: true,
                              label: '$value $label',
                              excludeSemantics: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    icon,
                                    size: 17 * s,
                                    color: AppColors.logoOnDark,
                                  ),
                                  SizedBox(height: 6 * s),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _thousands((value * count).round()),
                                      style: TextStyle(
                                        fontSize: 26 * s,
                                        height: 1.1,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 2 * s),
                                  Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5 * s,
                                      color: AppColors.white.withValues(
                                        alpha: 0.8,
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

/// No upcoming events: a calendar that gently bobs, and a way to Explore.
class _EmptyUpcoming extends StatelessWidget {
  const _EmptyUpcoming({
    required this.scale,
    required this.time,
    required this.onExplore,
  });

  final double scale;
  final double time;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Column(
      children: [
        Transform.translate(
          offset: Offset(0, math.sin(time * 2 * math.pi * 2) * 4 * s),
          child: Container(
            width: 88 * s,
            height: 88 * s,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.roleChosenFill, AppColors.roleChosenCircle],
              ),
            ),
            child: Icon(
              Icons.event_note_rounded,
              size: 40 * s,
              color: AppColors.brand,
            ),
          ),
        ),
        SizedBox(height: 18 * s),
        Text(
          'No upcoming events',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 22 * s,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        SizedBox(height: 6 * s),
        Text(
          'Join an event and it will show up here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15 * s, color: AppColors.bodyText),
        ),
        SizedBox(height: 20 * s),
        SizedBox(
          width: 240 * s,
          child: PrimaryButton(
            label: 'Explore Events',
            scale: s * 0.85,
            time: time,
            onPressed: onExplore,
          ),
        ),
      ],
    );
  }
}

/// A past event's recap: its photo, what the volunteer did, the
/// organiser's thank-you note, any certificate, and a way to find more like
/// it. A sheet from the bottom on phones, a card in the middle on laptops.
class _VisitRecap extends StatelessWidget {
  const _VisitRecap({
    required this.visit,
    required this.wide,
    required this.scale,
    required this.onFindSimilar,
  });

  final PastVisit visit;
  final bool wide;
  final double scale;
  final VoidCallback onFindSimilar;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final event = visit.event;
    final size = MediaQuery.sizeOf(context);
    final radius = Radius.circular(30 * s);

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 210 * s,
          child: Stack(
            fit: StackFit.expand,
            children: [
              EventPhoto(event: event),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.splashScrim.withValues(alpha: 0.35),
                      AppColors.splashScrim.withValues(alpha: 0),
                      AppColors.splashScrim.withValues(alpha: 0.75),
                    ],
                    stops: const [0, 0.35, 1],
                  ),
                ),
              ),
              Positioned(
                left: 18 * s,
                top: 16 * s,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * s,
                    vertical: 5 * s,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(14 * s),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 15 * s,
                        color: AppColors.white,
                      ),
                      SizedBox(width: 5 * s),
                      Text(
                        'Attended',
                        style: TextStyle(
                          fontSize: 12.5 * s,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 14 * s,
                top: 12 * s,
                child: AuthIconButton(
                  label: 'Close',
                  scale: s,
                  onDark: true,
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20 * s,
                    color: AppColors.white,
                  ),
                ),
              ),
              Positioned(
                left: 20 * s,
                right: 20 * s,
                bottom: 16 * s,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EventCategoryTag(category: event.category, scale: s),
                    SizedBox(height: 8 * s),
                    Semantics(
                      header: true,
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 24 * s,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 4 * s),
                    Text(
                      '${event.date}  ·  ${event.address}',
                      style: TextStyle(
                        fontSize: 13.5 * s,
                        color: AppColors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20 * s, 20 * s, 20 * s, 20 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, (icon, value, label)) in [
                      (visit.roleIcon, visit.role, 'Your role'),
                      (
                        Icons.schedule_rounded,
                        '${visit.hours} hrs',
                        event.hours,
                      ),
                      (
                        Icons.auto_awesome_rounded,
                        visit.contribution.$1,
                        visit.contribution.$2,
                      ),
                    ].indexed) ...[
                      if (i > 0) SizedBox(width: 10 * s),
                      Expanded(
                        child: _RecapStat(
                          icon: icon,
                          value: value,
                          label: label,
                          category: event.category,
                          scale: s,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16 * s),
              Container(
                padding: EdgeInsets.all(16 * s),
                decoration: BoxDecoration(
                  color: AppColors.roleChosenFill,
                  borderRadius: BorderRadius.circular(20 * s),
                  border: Border.all(color: AppColors.roleChosenBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 26 * s,
                      color: AppColors.leafLight,
                    ),
                    SizedBox(height: 4 * s),
                    Text(
                      visit.thanks,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 16.5 * s,
                        height: 1.45,
                        fontStyle: FontStyle.italic,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 10 * s),
                    Text(
                      '— ${event.organiser}',
                      style: TextStyle(
                        fontSize: 13.5 * s,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ),
              if (visit.certificate) ...[
                SizedBox(height: 12 * s),
                _CertificateRow(event: event, scale: s),
              ],
              SizedBox(height: 18 * s),
              PrimaryButton(
                label: 'Find Similar Events',
                scale: s * 0.9,
                onPressed: onFindSimilar,
              ),
            ],
          ),
        ),
      ],
    );

    final sheet = Material(
      color: AppColors.surface,
      borderRadius: wide
          ? BorderRadius.all(radius)
          : BorderRadius.vertical(top: radius),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: size.height * (wide ? 0.9 : 0.92),
          maxWidth: wide ? 540 * s : 560 * s,
        ),
        child: SingleChildScrollView(
          child: SafeArea(top: false, bottom: !wide, child: body),
        ),
      ),
    );

    return wide
        ? Center(child: sheet)
        : Align(alignment: Alignment.bottomCenter, child: sheet);
  }
}

class _RecapStat extends StatelessWidget {
  const _RecapStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.category,
    required this.scale,
  });

  final IconData icon;
  final String value;
  final String label;
  final EventCategory category;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.all(12 * s),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18 * s),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30 * s,
            height: 30 * s,
            decoration: BoxDecoration(
              color: category.fill,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16 * s, color: category.text),
          ),
          SizedBox(height: 8 * s),
          Text(
            value,
            maxLines: 2,
            style: TextStyle(
              fontSize: 15.5 * s,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 2 * s),
          Text(
            label,
            maxLines: 2,
            style: TextStyle(fontSize: 12 * s, color: AppColors.fieldIcon),
          ),
        ],
      ),
    );
  }
}

/// "Certificate earned", with View opening a preview of the certificate
/// just below.
class _CertificateRow extends StatefulWidget {
  const _CertificateRow({required this.event, required this.scale});

  final VolunteerEvent event;
  final double scale;

  @override
  State<_CertificateRow> createState() => _CertificateRowState();
}

class _CertificateRowState extends State<_CertificateRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final event = widget.event;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(12 * s, 10 * s, 16 * s, 10 * s),
          decoration: BoxDecoration(
            color: AppColors.tagFoodFill,
            borderRadius: BorderRadius.circular(18 * s),
          ),
          child: Row(
            children: [
              Container(
                width: 38 * s,
                height: 38 * s,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sun,
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 21 * s,
                  color: AppColors.white,
                ),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Certificate earned',
                      style: TextStyle(
                        fontSize: 15 * s,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'Certificate of participation',
                      style: TextStyle(
                        fontSize: 12.5 * s,
                        color: AppColors.tagFoodText,
                      ),
                    ),
                  ],
                ),
              ),
              AuthTextLink(
                label: _open ? 'Hide' : 'View',
                scale: s,
                fontSize: 15,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _open = !_open);
                },
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Container(
                  margin: EdgeInsets.only(top: 10 * s),
                  padding: EdgeInsets.all(6 * s),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16 * s),
                    border: Border.all(color: AppColors.earthLight, width: 1.5),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * s,
                      vertical: 18 * s,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFCF5),
                      borderRadius: BorderRadius.circular(11 * s),
                      border: Border.all(
                        color: AppColors.earthLight.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.eco_rounded,
                          size: 22 * s,
                          color: AppColors.leafLight,
                        ),
                        SizedBox(height: 6 * s),
                        Text(
                          'CERTIFICATE OF PARTICIPATION',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5 * s,
                            letterSpacing: 1.6 * s,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tagFoodText,
                          ),
                        ),
                        SizedBox(height: 10 * s),
                        Text(
                          'This certifies that you took part in',
                          style: TextStyle(
                            fontSize: 12.5 * s,
                            color: AppColors.fieldIcon,
                          ),
                        ),
                        SizedBox(height: 4 * s),
                        Text(
                          event.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 20 * s,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 4 * s),
                        Text(
                          '${event.date} · ${event.organiser}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5 * s,
                            color: AppColors.bodyText,
                          ),
                        ),
                        SizedBox(height: 12 * s),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 16 * s,
                              color: AppColors.brand,
                            ),
                            SizedBox(width: 5 * s),
                            Text(
                              'Verified by FoodLink',
                              style: TextStyle(
                                fontSize: 12.5 * s,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brand,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
