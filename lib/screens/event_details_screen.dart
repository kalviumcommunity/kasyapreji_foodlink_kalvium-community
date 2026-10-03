import 'dart:math' as math;

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
/// numbers, how many spots are left, what to bring and who runs it.
///
/// The photo grows out of the tapped tile ([heroTag]) and drifts slowly;
/// on phones it sits behind a sheet that scrolls up over it with a gentle
/// parallax, and a compact title bar fades in once the photo has scrolled
/// away. Joining pops a little burst of colour, counts the volunteer in,
/// and puts a check on the event's tile in every list; the heart saves it.
///
/// Phones follow the Figma frame, with Join Event pinned to the bottom;
/// laptops get the side navigation rail ([tab] highlighted) and the photo
/// beside the details.
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
    duration: const Duration(milliseconds: 1500),
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
    final start = (0.15 + n * 0.06).clamp(0.0, 0.6);
    return Curves.easeOutCubic.transform(
      ((_intro.value - start) / 0.4).clamp(0.0, 1.0),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _intro.dispose();
    _ambient.dispose();
    _burst.dispose();
    super.dispose();
  }

  // No pop-up notices here: they would cover the pinned Join bar, and the
  // button, burst and counts already show what happened.
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
    final joinBarHeight = (_joined ? 96 : 104) * s + bottom;

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
                            color: AppColors.ink.withValues(alpha: 0.12),
                            blurRadius: 30 * s,
                            offset: Offset(0, -6 * s),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(painter: DotTexturePainter()),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              24 * s,
                              26 * s,
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RiseIn(
              progress: _rise(4),
              distance: 40 * s,
              child: Container(
                padding: EdgeInsets.fromLTRB(24 * s, 22 * s, 24 * s, 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.surface.withValues(alpha: 0),
                      AppColors.surface,
                    ],
                    stops: const [0, 0.3],
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
        ? (size.height - 150 * s).clamp(420 * s, 640 * s)
        : 360 * s;

    final photo = SizedBox(
      height: photoHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32 * s),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.18),
              blurRadius: 40 * s,
              offset: Offset(0, 18 * s),
            ),
          ],
        ),
        child: _photo(s, radius: 32 * s),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _details(s, titleSize: 42 * s),
        SizedBox(height: 26 * s),
        RiseIn(progress: _rise(8), distance: 20 * s, child: _joinArea(s)),
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
  /// buttons, with soft light specks rising through it.
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
                    AppColors.splashScrim.withValues(alpha: 0.55),
                    AppColors.splashScrim.withValues(alpha: 0),
                    AppColors.splashScrim.withValues(alpha: 0),
                    AppColors.splashScrim.withValues(alpha: 0.35),
                  ],
                  stops: const [0, 0.35, 0.6, 1],
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
    var n = 0;
    Widget rise(Widget child) =>
        RiseIn(progress: _rise(n++), distance: 18 * s, child: child);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rise(
          Align(
            alignment: Alignment.centerLeft,
            child: EventCategoryTag(
              category: event.category,
              scale: s,
              fontSize: 15,
            ),
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
          Column(
            children: [
              for (final (icon, text) in [
                (Icons.event_available_rounded, event.date),
                (Icons.schedule_rounded, event.hours),
                (Icons.place_outlined, event.address),
              ])
                Padding(
                  padding: EdgeInsets.only(bottom: 12 * s),
                  child: _InfoRow(icon: icon, text: text, scale: s),
                ),
            ],
          ),
        ),
        SizedBox(height: 8 * s),
        rise(
          Text(
            event.about,
            style: TextStyle(
              fontSize: 16 * s,
              height: 1.65,
              color: AppColors.bodyText,
            ),
          ),
        ),
        SizedBox(height: 24 * s),
        rise(
          SizedBox(
            height: 96 * s,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _going.toDouble()),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, _) => _StatTile(
                      value: '${value.round()}',
                      label: 'Volunteers',
                      scale: s,
                    ),
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: _StatTile(
                    value: event.impact.$1,
                    label: event.impact.$2,
                    scale: s,
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: _StatTile(
                    value: event.duration,
                    label: 'Duration',
                    scale: s,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24 * s),
        rise(
          _SpotsBar(
            going: _going,
            capacity: event.capacity,
            left: _spotsLeft,
            scale: s,
          ),
        ),
        SizedBox(height: 26 * s),
        rise(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _subheading('What to bring', s),
              SizedBox(height: 12 * s),
              Wrap(
                spacing: 8 * s,
                runSpacing: 8 * s,
                children: [
                  for (final item in event.bring)
                    _BringChip(label: item, scale: s),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 24 * s),
        rise(_OrganiserCard(name: event.organiser, scale: s)),
      ],
    );
  }

  Widget _subheading(String text, double s) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 19 * s,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
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
          // Full width for both buttons, not just their content.
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.center,
            children: [
              for (final child in [...previous, ?current])
                SizedBox(width: double.infinity, child: child),
            ],
          ),
          duration: const Duration(milliseconds: 320),
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

/// An icon in a soft green square beside one line of detail.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, required this.scale});

  final IconData icon;
  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Row(
      children: [
        Container(
          width: 40 * s,
          height: 40 * s,
          decoration: BoxDecoration(
            color: AppColors.roleChosenFill,
            borderRadius: BorderRadius.circular(12 * s),
          ),
          child: Icon(icon, size: 21 * s, color: AppColors.brand),
        ),
        SizedBox(width: 16 * s),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16.5 * s,
              fontWeight: FontWeight.w500,
              color: AppColors.bodyText,
            ),
          ),
        ),
      ],
    );
  }
}

/// One of the event's numbers over its label.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.scale,
  });

  final String value;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8 * s),
        decoration: BoxDecoration(
          color: AppColors.socialFill.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20 * s),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.9)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 25 * s,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 4 * s),
              Text(
                label,
                style: TextStyle(fontSize: 13.5 * s, color: AppColors.bodyText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How full the event is: a bar that fills as the page opens, and how many
/// spots are left (in amber when only a few remain).
class _SpotsBar extends StatelessWidget {
  const _SpotsBar({
    required this.going,
    required this.capacity,
    required this.left,
    required this.scale,
  });

  final int going;
  final int capacity;
  final int left;
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
    return Semantics(
      label: '$going of $capacity spots filled. $note',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Spots filled',
                style: TextStyle(
                  fontSize: 14.5 * s,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                '$going / $capacity',
                style: TextStyle(
                  fontSize: 14.5 * s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * s),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: going / capacity),
            duration: const Duration(milliseconds: 1200),
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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5 * s),
                    gradient: LinearGradient(
                      colors: few
                          ? [AppColors.sun, AppColors.earthLight]
                          : AppColors.accentGradient,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8 * s),
          Text(
            note,
            style: TextStyle(
              fontSize: 13.5 * s,
              fontWeight: few ? FontWeight.w600 : FontWeight.w400,
              color: few ? AppColors.tagFoodText : AppColors.fieldIcon,
            ),
          ),
        ],
      ),
    );
  }
}

class _BringChip extends StatelessWidget {
  const _BringChip({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16 * s,
            color: AppColors.leafLight,
          ),
          SizedBox(width: 6 * s),
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
      child: Container(
        padding: EdgeInsets.all(14 * s),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20 * s),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 46 * s,
              height: 46 * s,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.accentGradient,
                ),
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
            Icon(Icons.verified_rounded, size: 22 * s, color: AppColors.brand),
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
