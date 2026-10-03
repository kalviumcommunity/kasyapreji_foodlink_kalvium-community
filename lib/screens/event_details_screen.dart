import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/event_plans.dart';
import '../data/sample_events.dart';
import '../navigation/tab_navigation.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/app_nav.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/event_tile.dart';
import '../widgets/light_particles.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/primary_button.dart';
import '../widgets/rise_in.dart';
import '../widgets/soft_backdrop.dart';

/// One event in full: its photo, when and where, what it's about, its
/// numbers, who's going, where it is, what to bring and who runs it.
///
/// The photo grows out of the tapped tile ([heroTag]) and drifts slowly,
/// with a calendar badge for the date. On phones it sits behind a sheet
/// that scrolls up over it with a gentle parallax, and a compact title bar
/// fades in once the photo has scrolled away. The sheet glows softly in the
/// event's category colour; numbers count up, the spots bar shimmers and the
/// pin on the little painted map pulses.
///
/// Joining pops a burst of colour, puts the volunteer at the front of the
/// "who's going" avatars, and checks the event's tile in every list; the
/// heart saves it.
///
/// Phones follow the Figma frame, with Join Event pinned to the bottom on
/// frosted glass; laptops get the side navigation rail ([tab] highlighted)
/// and the photo beside the details.
class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({
    super.key,
    required this.event,
    this.tab = AppTab.explore,
    this.heroTag,
  });

  final VolunteerEvent event;

  /// The section the event was opened from.
  final AppTab tab;
  final Object? heroTag;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen>
    with TickerProviderStateMixin {
  final _scroll = ScrollController();

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  /// The burst of colour when the volunteer joins.
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  VolunteerEvent get _event => widget.event;
  Object get _heroTag => widget.heroTag ?? 'details/${_event.title}';
  bool get _joined => EventPlans.hasJoined(_event.title);
  bool get _saved => EventPlans.hasSaved(_event.title);

  /// Volunteers going, counting this one once they've joined.
  int get _going => _event.going + (_joined ? 1 : 0);
  int get _spotsLeft => math.max(0, _event.capacity - _going);

  /// Staggered entrance progress (0–1) for the n-th element.
  double _rise(int n) {
    final start = (0.12 + n * 0.055).clamp(0.0, 0.62);
    return Curves.easeOutCubic.transform(
      ((_intro.value - start) / 0.38).clamp(0.0, 1.0),
    );
  }

  /// How far the numbers have counted up (0–1).
  double get _count => Curves.easeOutCubic.transform(
    ((_intro.value - 0.3) / 0.7).clamp(0.0, 1.0),
  );

  @override
  void dispose() {
    _scroll.dispose();
    _intro.dispose();
    _ambient.dispose();
    _burst.dispose();
    super.dispose();
  }

  // No pop-up notices here: they would cover the pinned Join bar, and the
  // button, burst, avatars and counts already show what happened.
  void _join() {
    HapticFeedback.mediumImpact();
    EventPlans.toggleJoined(_event.title);
    _burst.forward(from: 0);
  }

  void _leave() {
    HapticFeedback.selectionClick();
    EventPlans.toggleJoined(_event.title);
  }

  void _toggleSaved() {
    HapticFeedback.selectionClick();
    EventPlans.toggleSaved(_event.title);
  }

  void _openTab(AppTab tab) => openAppTab(context, null, tab);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backdrop.first,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final wide =
              size.width >= OnboardingLayout.wideBreakpoint &&
              size.width > size.height;
          final s = wide
              ? math.min(size.width / 1280, size.height / 800).clamp(0.75, 1.25)
              : math.min(
                  size.width / OnboardingLayout.designWidth,
                  size.height / OnboardingLayout.designHeight,
                );
          return AnimatedBuilder(
            animation: Listenable.merge([
              _intro,
              _ambient,
              _burst,
              _scroll,
              EventPlans.joined,
              EventPlans.saved,
            ]),
            builder: (context, _) =>
                wide ? _buildWide(size, s) : _buildCompact(size, s),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone layout
  // ---------------------------------------------------------------------------

  Widget _buildCompact(Size size, double s) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final photoHeight = 330 * s + top * 0.5;
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    // How far the compact title bar has faded in, once the photo is gone.
    final bar = ((offset - (photoHeight - 130 * s)) / (60 * s)).clamp(0.0, 1.0);
    final barHeight = top + 64 * s;
    final joinBarHeight = 104 * s + bottom;
    // The details keep a comfortable width on tablets held upright; the date
    // badge lines up with their right edge.
    final contentWidth = math.min(size.width - 48 * s, 480 * s);
    final badgeRight = (size.width - contentWidth) / 2;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: bar > 0.5 ? Brightness.dark : Brightness.light,
        statusBarBrightness: bar > 0.5 ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Stack(
        children: [
          // The photo, drifting up at half speed as the sheet scrolls, and
          // stretching when pulled down.
          Positioned(
            left: 0,
            right: 0,
            top: offset > 0 ? -offset * 0.45 : 0,
            height: photoHeight + 40 * s + (offset < 0 ? -offset : 0),
            child: _photo(s, radius: 0),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Column(
                children: [
                  SizedBox(height: photoHeight),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: size.height - photoHeight + 32 * s,
                    ),
                    child: Container(
                      width: double.infinity,
                      transform: Matrix4.translationValues(0, -32 * s, 0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32 * s),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.14),
                            blurRadius: 30 * s,
                            offset: Offset(0, -6 * s),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(32 * s),
                              ),
                              child: CustomPaint(
                                painter: _SheetGlowPainter(
                                  color: _event.category.glow,
                                  time: _ambient.value,
                                ),
                              ),
                            ),
                          ),
                          const Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(painter: DotTexturePainter()),
                            ),
                          ),
                          // Grab handle.
                          Positioned(
                            top: 10 * s,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 40 * s,
                                height: 5 * s,
                                decoration: BoxDecoration(
                                  color: AppColors.fieldBorder,
                                  borderRadius: BorderRadius.circular(3 * s),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              24 * s,
                              30 * s,
                              24 * s,
                              joinBarHeight + 8 * s,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 480 * s),
                                child: _details(s, titleSize: 30 * s),
                              ),
                            ),
                          ),
                          // The date, half over the photo.
                          Positioned(
                            right: badgeRight,
                            top: -40 * s,
                            child: RiseIn(
                              progress: _rise(1),
                              distance: 16 * s,
                              child: _DateBadge(event: _event, scale: s),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Title bar: clear over the photo, solid once it's scrolled away.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: barHeight,
            child: Container(
              padding: EdgeInsets.fromLTRB(20 * s, top, 20 * s, 0),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.97 * bar),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.fieldBorder.withValues(alpha: bar),
                  ),
                ),
              ),
              child: RiseIn(
                progress: Curves.easeOut.transform(
                  (_intro.value / 0.4).clamp(0.0, 1.0),
                ),
                distance: -10 * s,
                child: _headerRow(s, onDark: bar < 0.5, titleOpacity: bar),
              ),
            ),
          ),
          // Join Event on frosted glass.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RiseIn(
              progress: _rise(5),
              distance: 40 * s,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(24 * s, 16 * s, 24 * s, 0),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.8),
                      border: const Border(
                        top: BorderSide(color: AppColors.fieldBorder),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      minimum: EdgeInsets.only(bottom: 16 * s),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 480 * s),
                          child: _joinArea(s),
                        ),
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

  // ---------------------------------------------------------------------------
  // Laptop layout
  // ---------------------------------------------------------------------------

  Widget _buildWide(Size size, double s) {
    final railWidth = 224 * s;
    final mainWidth = math.min(size.width - railWidth, 1180 * s);
    final content = mainWidth - 96 * s;
    final sideBySide = content >= 760;
    final photoHeight = sideBySide
        ? (size.height - 150 * s).clamp(440 * s, 660 * s)
        : 380 * s;

    final photo = SizedBox(
      height: photoHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32 * s),
          boxShadow: [
            BoxShadow(
              color: Color.lerp(
                AppColors.ink,
                _event.category.text,
                0.4,
              )!.withValues(alpha: 0.24),
              blurRadius: 44 * s,
              offset: Offset(0, 20 * s),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _photo(s, radius: 32 * s),
            Positioned(
              left: 22 * s,
              top: 22 * s,
              child: RiseIn(
                progress: _rise(1),
                distance: 16 * s,
                child: _DateBadge(event: _event, scale: s),
              ),
            ),
            Positioned(
              left: 18 * s,
              right: 18 * s,
              bottom: 18 * s,
              child: RiseIn(
                progress: _rise(3),
                distance: 16 * s,
                child: _PhotoCaption(
                  place: _event.place,
                  spotsLeft: _spotsLeft,
                  scale: s,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _details(s, titleSize: 42 * s),
        SizedBox(height: 28 * s),
        RiseIn(progress: _rise(11), distance: 20 * s, child: _joinArea(s)),
      ],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: SoftBackdropPainter(time: _ambient.value),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _SheetGlowPainter(
                color: _event.category.glow,
                time: _ambient.value,
              ),
            ),
          ),
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: DotTexturePainter()),
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: railWidth,
                child: AppSideRail(
                  current: widget.tab,
                  scale: s,
                  onSelect: _openTab,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
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
                              child: _headerRow(s, onDark: false),
                            ),
                            SizedBox(height: 24 * s),
                            if (sideBySide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 11, child: photo),
                                  SizedBox(width: 44 * s),
                                  Expanded(flex: 10, child: details),
                                ],
                              )
                            else ...[
                              photo,
                              SizedBox(height: 30 * s),
                              details,
                            ],
                          ],
                        ),
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

  // ---------------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------------

  /// The event's photo, slowly drifting, darkened at the top for the
  /// buttons and at the foot for depth, with soft light specks rising
  /// through it.
  Widget _photo(double s, {required double radius}) {
    final t = _ambient.value * 2 * math.pi;
    return Hero(
      tag: _heroTag,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: 1.08 + 0.04 * math.sin(t),
              alignment: Alignment(math.cos(t) * 0.3, 0),
              child: EventPhoto(event: _event),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.splashScrim.withValues(alpha: 0.6),
                    AppColors.splashScrim.withValues(alpha: 0),
                    AppColors.splashScrim.withValues(alpha: 0),
                    AppColors.splashScrim.withValues(alpha: 0.45),
                  ],
                  stops: const [0, 0.32, 0.58, 1],
                ),
              ),
            ),
            IgnorePointer(
              child: CustomPaint(
                painter: _SpecksPainter(
                  time: _ambient.value,
                  opacity: _rise(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Back, the event's title (once [titleOpacity] > 0), save and avatar.
  Widget _headerRow(double s, {required bool onDark, double titleOpacity = 0}) {
    final iconColor = onDark ? AppColors.white : AppColors.ink;
    return Row(
      children: [
        if (Navigator.of(context).canPop())
          AuthIconButton(
            label: 'Back',
            scale: s,
            onDark: onDark,
            onTap: () => Navigator.of(context).maybePop(),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18 * s,
              color: iconColor,
            ),
          ),
        Expanded(
          child: Opacity(
            opacity: titleOpacity,
            child: Text(
              _event.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17 * s,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        AuthIconButton(
          label: _saved ? 'Remove from saved' : 'Save event',
          scale: s,
          onDark: onDark,
          onTap: _toggleSaved,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: child,
            ),
            child: Icon(
              _saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(_saved),
              size: 20 * s,
              color: _saved ? AppColors.badge : iconColor,
            ),
          ),
        ),
        SizedBox(width: 10 * s),
        AuthAvatar(scale: s * 1.1),
      ],
    );
  }

  /// Everything about the event, from its tag down to the organiser.
  Widget _details(double s, {required double titleSize}) {
    final event = _event;
    final category = event.category;
    var n = 0;
    Widget rise(Widget child) =>
        RiseIn(progress: _rise(n++), distance: 18 * s, child: child);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rise(
          Align(
            alignment: Alignment.centerLeft,
            child: EventCategoryTag(category: category, scale: s, fontSize: 15),
          ),
        ),
        SizedBox(height: 16 * s),
        rise(
          Semantics(
            header: true,
            child: Text(
              event.title,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: titleSize,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -titleSize * 0.01,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        SizedBox(height: 20 * s),
        rise(
          _GlassCard(
            scale: s,
            padding: EdgeInsets.symmetric(horizontal: 16 * s),
            child: Column(
              children: [
                for (final (i, (icon, label, text)) in [
                  (Icons.event_available_rounded, 'Date', event.date),
                  (Icons.schedule_rounded, 'Time', event.hours),
                  (Icons.place_outlined, 'Location', event.address),
                ].indexed) ...[
                  if (i > 0)
                    Container(
                      height: 1,
                      margin: EdgeInsets.only(left: 58 * s),
                      color: AppColors.fieldBorder.withValues(alpha: 0.8),
                    ),
                  _InfoRow(
                    icon: icon,
                    label: label,
                    text: text,
                    category: category,
                    scale: s,
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: 26 * s),
        rise(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Subheading(text: 'About this event', scale: s),
              SizedBox(height: 10 * s),
              Text(
                event.about,
                style: TextStyle(
                  fontSize: 16 * s,
                  height: 1.65,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24 * s),
        rise(
          SizedBox(
            height: 118 * s,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _going.toDouble()),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, _) => _StatTile(
                      value: '$_going',
                      shown: '${(value * _count).round()}',
                      label: 'Volunteers',
                      icon: Icons.groups_rounded,
                      category: category,
                      scale: s,
                    ),
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: _StatTile(
                    value: event.impact.$1,
                    shown: _countUp(event.impact.$1, _count),
                    label: event.impact.$2,
                    icon: category.icon,
                    category: category,
                    scale: s,
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: _StatTile(
                    value: event.duration,
                    shown: _countUp(event.duration, _count),
                    label: 'Duration',
                    icon: Icons.hourglass_bottom_rounded,
                    category: category,
                    scale: s,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16 * s),
        rise(
          _GlassCard(
            scale: s,
            padding: EdgeInsets.all(16 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GoingAvatars(going: _going, joined: _joined, scale: s),
                SizedBox(height: 16 * s),
                _SpotsBar(
                  going: _going,
                  capacity: event.capacity,
                  left: _spotsLeft,
                  time: _ambient.value,
                  scale: s,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 26 * s),
        rise(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Subheading(text: 'Location', scale: s),
              SizedBox(height: 12 * s),
              _MapPreview(event: event, time: _ambient.value, scale: s),
            ],
          ),
        ),
        SizedBox(height: 26 * s),
        rise(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Subheading(text: 'What to bring', scale: s),
              SizedBox(height: 12 * s),
              Wrap(
                spacing: 8 * s,
                runSpacing: 8 * s,
                children: [
                  for (final item in event.bring)
                    _BringChip(label: item, category: category, scale: s),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 26 * s),
        rise(_OrganiserCard(name: event.organiser, scale: s)),
      ],
    );
  }

  /// Join Event, or "You're Going" with a way to leave, or a full notice.
  Widget _joinArea(double s) {
    final Widget child;
    if (_joined) {
      child = _GoingButton(
        key: const ValueKey('going'),
        scale: s,
        onLeave: _leave,
      );
    } else {
      final full = _spotsLeft == 0;
      child = PrimaryButton(
        key: const ValueKey('join'),
        label: full ? 'Event Full' : 'Join Event',
        scale: s,
        time: _ambient.value,
        onPressed: full ? null : _join,
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          // Full width for both buttons, not just their content.
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.center,
            children: [
              for (final child in [...previous, ?current])
                SizedBox(width: double.infinity, child: child),
            ],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: child,
        ),
        if (_burst.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BurstPainter(progress: _burst.value, scale: s),
              ),
            ),
          ),
      ],
    );
  }
}

/// [value] ("500+", "2.5 hrs") with its number scaled by [progress], so it
/// can count up from zero.
String _countUp(String value, double progress) {
  final match = RegExp(r'^(\d+(?:\.\d+)?)(.*)$').firstMatch(value);
  if (match == null || progress >= 1) return value;
  final number = double.parse(match.group(1)!) * progress;
  final decimals = match.group(1)!.contains('.');
  return '${decimals ? number.toStringAsFixed(1) : number.round()}'
      '${match.group(2)}';
}

/// An icon for each thing to bring, matched on its name.
IconData _bringIcon(String item) {
  final name = item.toLowerCase();
  for (final (word, icon) in const [
    ('water', Icons.water_drop_outlined),
    ('shoe', Icons.hiking_rounded),
    ('glove', Icons.back_hand_outlined),
    ('hat', Icons.wb_sunny_outlined),
    ('cap', Icons.wb_sunny_outlined),
    ('apron', Icons.checkroom_rounded),
    ('notebook', Icons.menu_book_outlined),
    ('pen', Icons.edit_outlined),
    ('id', Icons.badge_outlined),
    ('bag', Icons.shopping_bag_outlined),
    ('smile', Icons.sentiment_satisfied_alt_rounded),
    ('curiosity', Icons.lightbulb_outline_rounded),
  ]) {
    if (name.contains(word)) return icon;
  }
  return Icons.check_circle_outline_rounded;
}

/// Frosted white card used for groups of details.
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.scale,
    required this.padding,
    required this.child,
  });

  final double scale;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: AppColors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.07),
            blurRadius: 24 * s,
            offset: Offset(0, 8 * s),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A section title with a small leaf before it.
class _Subheading extends StatelessWidget {
  const _Subheading({required this.text, required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      header: true,
      label: text,
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(Icons.eco_rounded, size: 18 * s, color: AppColors.leafLight),
          SizedBox(width: 8 * s),
          Text(
            text,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 19 * s,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Calendar-page badge: month on a coloured strip, the day large, then the
/// weekday.
class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.event, required this.scale});

  final VolunteerEvent event;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    // "Sat, 20 Sep 2026" → Sat, 20, Sep.
    final parts = event.date.replaceAll(',', '').split(' ');
    final (weekday, day, month) = parts.length >= 3
        ? (parts[0], parts[1], parts[2])
        : ('', event.date, '');
    return Semantics(
      label: event.date,
      excludeSemantics: true,
      child: Container(
        width: 72 * s,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18 * s),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.2),
              blurRadius: 22 * s,
              offset: Offset(0, 8 * s),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 5 * s),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.accentGradient),
              ),
              child: Text(
                month.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12 * s,
                  letterSpacing: 1.2 * s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
            SizedBox(height: 4 * s),
            Text(
              day,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 28 * s,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 8 * s),
              child: Text(
                weekday.toUpperCase(),
                style: TextStyle(
                  fontSize: 11 * s,
                  letterSpacing: 1 * s,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fieldIcon,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Laptops: frosted strip over the foot of the photo with the place and
/// how many spots are left.
class _PhotoCaption extends StatelessWidget {
  const _PhotoCaption({
    required this.place,
    required this.spotsLeft,
    required this.scale,
  });

  final String place;
  final int spotsLeft;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final style = TextStyle(
      fontSize: 15 * s,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(20 * s),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 14 * s),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20 * s),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.place_rounded, size: 19 * s, color: AppColors.white),
              SizedBox(width: 8 * s),
              Expanded(
                child: Text(
                  place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              Icon(
                Icons.event_seat_rounded,
                size: 18 * s,
                color: AppColors.white,
              ),
              SizedBox(width: 8 * s),
              Text(
                spotsLeft == 0 ? 'Full' : '$spotsLeft spots left',
                style: style,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A labelled detail with its icon in a square of the category's colour.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.text,
    required this.category,
    required this.scale,
  });

  final IconData icon;
  final String label;
  final String text;
  final EventCategory category;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 13 * s),
      child: Row(
        children: [
          Container(
            width: 42 * s,
            height: 42 * s,
            decoration: BoxDecoration(
              color: category.fill,
              borderRadius: BorderRadius.circular(13 * s),
            ),
            child: Icon(icon, size: 21 * s, color: category.text),
          ),
          SizedBox(width: 16 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5 * s,
                    fontWeight: FontWeight.w500,
                    color: AppColors.fieldIcon,
                  ),
                ),
                SizedBox(height: 2 * s),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16 * s,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
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

/// One of the event's numbers, with an icon, counting up to [value].
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.shown,
    required this.label,
    required this.icon,
    required this.category,
    required this.scale,
  });

  /// The real value, and what's on screen while it counts up.
  final String value;
  final String shown;
  final String label;
  final IconData icon;
  final EventCategory category;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: _GlassCard(
        scale: s,
        padding: EdgeInsets.symmetric(horizontal: 8 * s),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                shown,
                style: TextStyle(
                  fontSize: 24 * s,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 3 * s),
              Text(
                label,
                style: TextStyle(fontSize: 13 * s, color: AppColors.bodyText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlapping avatars of volunteers who are going, with the volunteer
/// themselves at the front once they've joined.
class _GoingAvatars extends StatelessWidget {
  const _GoingAvatars({
    required this.going,
    required this.joined,
    required this.scale,
  });

  final int going;
  final bool joined;
  final double scale;

  /// Sample faces until accounts exist: initials and colours.
  static const _people = [
    ('AR', [Color(0xFFC99C74), Color(0xFF6E4A33)]),
    ('SK', AppColors.accentGradient),
    ('MP', [Color(0xFF7FA6C4), Color(0xFF3D6683)]),
    ('RD', [Color(0xFFE0A63A), Color(0xFFB0702A)]),
  ];

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final d = 36 * s;
    final step = 27 * s;
    final shownFaces = math.min(_people.length, going);
    final others = going - shownFaces;

    Widget circle({required Widget child, required Gradient gradient}) =>
        Container(
          width: d,
          height: d,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            border: Border.all(color: AppColors.white, width: 2.5),
          ),
          child: child,
        );

    final faces = [
      for (var i = 0; i < shownFaces; i++)
        if (i == 0 && joined)
          circle(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.avatar,
            ),
            child: Icon(
              Icons.person_rounded,
              size: 20 * s,
              color: const Color(0xFFF3E4D6),
            ),
          )
        else
          circle(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _people[i].$2,
            ),
            child: Text(
              _people[i].$1,
              style: TextStyle(
                fontSize: 11.5 * s,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
      if (others > 0)
        circle(
          gradient: const LinearGradient(
            colors: [AppColors.roleChosenFill, AppColors.roleChosenCircle],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.all(3 * s),
              child: Text(
                '+$others',
                style: TextStyle(
                  fontSize: 11.5 * s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ),
          ),
        ),
    ];

    final text = joined
        ? 'You and ${going - 1} others are going'
        : '$going volunteers are going';
    return Row(
      children: [
        SizedBox(
          width: d + step * (faces.length - 1),
          height: d,
          child: Stack(
            children: [
              for (final (i, face) in faces.indexed)
                Positioned(left: i * step, child: face),
            ],
          ),
        ),
        SizedBox(width: 12 * s),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previous, ?current],
            ),
            child: Text(
              text,
              key: ValueKey(text),
              style: TextStyle(
                fontSize: 14.5 * s,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// How full the event is: a bar that fills as the page opens with a light
/// sweeping across it, and how many spots are left (in amber when only a
/// few remain).
class _SpotsBar extends StatelessWidget {
  const _SpotsBar({
    required this.going,
    required this.capacity,
    required this.left,
    required this.time,
    required this.scale,
  });

  final int going;
  final int capacity;
  final int left;
  final double time;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final few = left <= 5;
    final note = left == 0
        ? 'No spots left'
        : few
        ? 'Only $left ${left == 1 ? 'spot' : 'spots'} left!'
        : '$left spots left';
    final sweep = (time * 2) % 1.0;
    return Semantics(
      label: '$going of $capacity spots filled. $note',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: going / capacity),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (context, fill, _) => Container(
              height: 10 * s,
              decoration: BoxDecoration(
                color: AppColors.stepTodo,
                borderRadius: BorderRadius.circular(5 * s),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fill.clamp(0.0, 1.0),
                heightFactor: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5 * s),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: few
                            ? [AppColors.sun, AppColors.earthLight]
                            : AppColors.accentGradient,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1 + sweep * 4 - 1, 0),
                          end: Alignment(-1 + sweep * 4, 0),
                          colors: [
                            AppColors.white.withValues(alpha: 0),
                            AppColors.white.withValues(alpha: 0.45),
                            AppColors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10 * s),
          Row(
            children: [
              Expanded(
                child: Text(
                  note,
                  style: TextStyle(
                    fontSize: 13.5 * s,
                    fontWeight: few ? FontWeight.w700 : FontWeight.w500,
                    color: few ? AppColors.tagFoodText : AppColors.fieldIcon,
                  ),
                ),
              ),
              SizedBox(width: 8 * s),
              Text(
                '$going / $capacity spots',
                style: TextStyle(
                  fontSize: 13.5 * s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small painted map of the neighbourhood with a pin bobbing over the
/// event's place and a ring pulsing out from it.
class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.event,
    required this.time,
    required this.scale,
  });

  final VolunteerEvent event;
  final double time;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      label: 'Map showing ${event.address}',
      excludeSemantics: true,
      child: Container(
        height: 160 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22 * s),
          border: Border.all(color: AppColors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.08),
              blurRadius: 24 * s,
              offset: Offset(0, 8 * s),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _MapPainter(
                seed: event.title.length * 31 + event.place.length,
                water: event.place.contains('River'),
                time: time,
                accent: event.category.text,
                scale: s,
              ),
            ),
            Positioned(
              left: 12 * s,
              bottom: 12 * s,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * s,
                  vertical: 7 * s,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14 * s),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.1),
                      blurRadius: 10 * s,
                      offset: Offset(0, 3 * s),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.near_me_rounded,
                      size: 15 * s,
                      color: AppColors.brand,
                    ),
                    SizedBox(width: 6 * s),
                    Text(
                      event.place,
                      style: TextStyle(
                        fontSize: 13.5 * s,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.seed,
    required this.water,
    required this.time,
    required this.accent,
    required this.scale,
  });

  final int seed;

  /// Whether a river runs through (for riverside places).
  final bool water;
  final double time;
  final Color accent;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final s = scale;
    final w = size.width;
    final h = size.height;
    final rnd = math.Random(seed);
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.mapLand);

    // City blocks.
    final block = Paint()..color = AppColors.mapBlock;
    for (var x = -20 * s; x < w; x += 64 * s) {
      for (var y = -14 * s; y < h; y += 46 * s) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x + rnd.nextDouble() * 8 * s,
              y + rnd.nextDouble() * 6 * s,
              (40 + rnd.nextDouble() * 12) * s,
              (28 + rnd.nextDouble() * 8) * s,
            ),
            Radius.circular(6 * s),
          ),
          block,
        );
      }
    }

    // Parks.
    final park = Paint()..color = AppColors.mapPark;
    for (var i = 0; i < 2; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            w * (0.15 + 0.7 * rnd.nextDouble()),
            h * (0.2 + 0.6 * rnd.nextDouble()),
          ),
          width: (70 + rnd.nextDouble() * 50) * s,
          height: (40 + rnd.nextDouble() * 30) * s,
        ),
        park,
      );
    }

    // A river for riverside places.
    if (water) {
      canvas.drawPath(
        Path()
          ..moveTo(-10, h * 0.82)
          ..cubicTo(w * 0.3, h * 0.6, w * 0.6, h * 1.05, w + 10, h * 0.7),
        Paint()
          ..color = AppColors.mapWater
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22 * s,
      );
    }

    // Roads: two main ones and a few side streets.
    final road = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final tilt = (rnd.nextDouble() - 0.5) * 0.3;
    canvas.drawPath(
      Path()
        ..moveTo(-10, h * (0.42 + tilt))
        ..quadraticBezierTo(w * 0.5, h * (0.5 - tilt), w + 10, h * 0.4),
      road..strokeWidth = 8 * s,
    );
    canvas.drawLine(
      Offset(w * (0.55 + tilt), -10),
      Offset(w * (0.62 - tilt), h + 10),
      road..strokeWidth = 7 * s,
    );
    road.strokeWidth = 3.5 * s;
    for (var i = 0; i < 3; i++) {
      final x = w * (0.15 + 0.3 * i + rnd.nextDouble() * 0.08);
      canvas.drawLine(Offset(x, -10), Offset(x + 12 * s, h + 10), road);
    }
    canvas.drawLine(Offset(-10, h * 0.16), Offset(w + 10, h * 0.2), road);

    // The pin, bobbing, with rings pulsing out beneath it.
    final pin = Offset(
      w * 0.6,
      h * 0.44 + math.sin(time * 2 * math.pi * 3) * 2.5 * s,
    );
    final base = Offset(w * 0.6, h * 0.44);
    for (var k = 0; k < 2; k++) {
      final p = (time * 3 + k * 0.5) % 1.0;
      canvas.drawCircle(
        base,
        (8 + 34 * p) * s,
        Paint()..color = accent.withValues(alpha: 0.32 * (1 - p)),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: base, width: 16 * s, height: 6 * s),
      Paint()..color = AppColors.ink.withValues(alpha: 0.18),
    );
    final head = pin - Offset(0, 22 * s);
    final r = 12 * s;
    canvas.drawPath(
      Path()
        ..moveTo(pin.dx, pin.dy)
        ..lineTo(head.dx - r * 0.78, head.dy + r * 0.62)
        ..arcToPoint(
          Offset(head.dx + r * 0.78, head.dy + r * 0.62),
          radius: Radius.circular(r),
          largeArc: true,
        )
        ..close(),
      Paint()..color = AppColors.brand,
    );
    canvas.drawCircle(head, 4.5 * s, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.scale != scale;
}

class _BringChip extends StatelessWidget {
  const _BringChip({
    required this.label,
    required this.category,
    required this.scale,
  });

  final String label;
  final EventCategory category;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.fromLTRB(6 * s, 6 * s, 14 * s, 6 * s),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28 * s,
            height: 28 * s,
            decoration: BoxDecoration(
              color: category.fill,
              shape: BoxShape.circle,
            ),
            child: Icon(_bringIcon(label), size: 15 * s, color: category.text),
          ),
          SizedBox(width: 8 * s),
          Text(
            label,
            style: TextStyle(
              fontSize: 14 * s,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Who runs the event, with their initials in a green circle.
class _OrganiserCard extends StatelessWidget {
  const _OrganiserCard({required this.name, required this.scale});

  final String name;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final initials = name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0])
        .join();
    return Semantics(
      label: 'Organised by $name',
      excludeSemantics: true,
      child: _GlassCard(
        scale: s,
        padding: EdgeInsets.all(14 * s),
        child: Row(
          children: [
            Container(
              width: 48 * s,
              height: 48 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.accentGradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.3),
                    blurRadius: 10 * s,
                    offset: Offset(0, 4 * s),
                  ),
                ],
              ),
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 16 * s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
            SizedBox(width: 14 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Organised by',
                    style: TextStyle(
                      fontSize: 13 * s,
                      color: AppColors.fieldIcon,
                    ),
                  ),
                  SizedBox(height: 2 * s),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16 * s,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * s,
                vertical: 6 * s,
              ),
              decoration: BoxDecoration(
                color: AppColors.roleChosenFill,
                borderRadius: BorderRadius.circular(14 * s),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 16 * s,
                    color: AppColors.brand,
                  ),
                  SizedBox(width: 4 * s),
                  Text(
                    'Verified',
                    style: TextStyle(
                      fontSize: 12.5 * s,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brand,
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

/// Pale green pill shown once the volunteer has joined, with a Leave link.
class _GoingButton extends StatelessWidget {
  const _GoingButton({super.key, required this.scale, required this.onLeave});

  final double scale;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      height: 60 * s,
      padding: EdgeInsets.only(left: 10 * s, right: 22 * s),
      decoration: BoxDecoration(
        color: AppColors.roleChosenFill,
        borderRadius: BorderRadius.circular(30 * s),
        border: Border.all(color: AppColors.roleChosenBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40 * s,
            height: 40 * s,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brand,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 22 * s,
              color: AppColors.white,
            ),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                "You're Going",
                style: TextStyle(
                  fontSize: 17 * s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ),
          ),
          AuthTextLink(
            label: 'Leave event',
            scale: s,
            fontSize: 14,
            onTap: onLeave,
          ),
        ],
      ),
    );
  }
}

/// A soft glow of the event's category colour drifting across the top of
/// the sheet, fading to nothing further down.
class _SheetGlowPainter extends CustomPainter {
  _SheetGlowPainter({required this.color, required this.time});

  final Color color;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final a = 2 * math.pi * time;
    for (final (anchor, radius, alpha) in [
      (Offset(0.85 + 0.05 * math.sin(a), 0.05), 0.75, 0.75),
      (Offset(0.1 + 0.05 * math.cos(a), 0.4), 0.55, 0.4),
    ]) {
      final centre = Offset(
        anchor.dx * size.width,
        math.min(anchor.dy * size.height, 520),
      );
      final r = radius * size.width.clamp(0, 900);
      canvas.drawCircle(
        centre,
        r,
        Paint()
          ..shader = ui.Gradient.radial(centre, r, [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ]),
      );
    }
  }

  @override
  bool shouldRepaint(_SheetGlowPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.color != color;
}

/// Soft white specks rising through the event's photo.
class _SpecksPainter extends CustomPainter {
  _SpecksPainter({required this.time, required this.opacity});

  final double time;
  final double opacity;

  static final _specks = LightParticles(top: 40, bottom: 420, count: 12);

  @override
  void paint(Canvas canvas, Size size) {
    _specks.paint(
      canvas,
      sx: size.width / OnboardingLayout.designWidth,
      sy: size.height / 420,
      time: time,
      opacity: opacity * 0.8,
    );
  }

  @override
  bool shouldRepaint(_SpecksPainter oldDelegate) => true;
}

/// Dots of green and amber flying out from the join button.
class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress, required this.scale});

  final double progress;
  final double scale;

  static const _colors = [
    AppColors.leafLight,
    AppColors.sun,
    AppColors.brand,
    AppColors.onboardingLeaf,
    AppColors.earthLight,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(5);
    final centre = size.center(Offset.zero);
    final travel = Curves.easeOutCubic.transform(progress);
    final fade = 1 - Curves.easeIn.transform(progress);
    for (var i = 0; i < 22; i++) {
      // Mostly upwards, spread across the button's width.
      final angle = -math.pi * (0.05 + 0.9 * rnd.nextDouble());
      final distance = (50 + rnd.nextDouble() * 80) * scale;
      final start = Offset(
        centre.dx + (rnd.nextDouble() - 0.5) * size.width * 0.6,
        centre.dy,
      );
      final point =
          start +
          Offset(math.cos(angle), math.sin(angle)) * distance * travel +
          Offset(0, 30 * scale * travel * travel);
      canvas.drawCircle(
        point,
        (2.5 + rnd.nextDouble() * 2.5) * scale,
        Paint()..color = _colors[i % _colors.length].withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
