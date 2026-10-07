import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/coordinator.dart';
import '../../navigation/tab_navigation.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/app_nav.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/coordinator_page.dart';
import '../../widgets/coordinator_widgets.dart';
import '../../widgets/event_tile.dart';
import '../../widgets/onboarding_layout.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rise_in.dart';
import '../../widgets/soft_backdrop.dart';

/// One of the coordinator's events in full, the coordinator's side of the
/// volunteer's event page.
///
/// The photo (grown from the tapped row) sits behind a sheet that scrolls
/// up over it; a title bar fades in once it's gone. The sheet shows the
/// status, when and where, the numbers (signed up, checked in or spots
/// left, meals), how full the event is, the team, how roles are covered,
/// a prep checklist to tick off, and what it's about. Actions: manage
/// check-ins (or message the team), share, mark complete, and cancel.
///
/// Laptops get the coordinator's side rail with the photo beside the
/// details.
class CoordinatorEventDetailsScreen extends StatefulWidget {
  const CoordinatorEventDetailsScreen({
    super.key,
    required this.title,
    this.heroTag,
  });

  /// The event, looked up live so changes show at once.
  final String title;
  final Object? heroTag;

  @override
  State<CoordinatorEventDetailsScreen> createState() =>
      _CoordinatorEventDetailsScreenState();
}

class _CoordinatorEventDetailsScreenState
    extends State<CoordinatorEventDetailsScreen>
    with TickerProviderStateMixin {
  final _scroll = ScrollController();

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  /// The last known version, kept so the page can close gracefully if the
  /// event is cancelled.
  late ManagedEvent _last = CoordinatorBoard.eventNamed(widget.title)!;

  ManagedEvent get _managed =>
      CoordinatorBoard.eventNamed(widget.title) ?? _last;

  Object get _heroTag => widget.heroTag ?? 'coord/${widget.title}';

  double _rise(int n) {
    final start = (0.12 + n * 0.055).clamp(0.0, 0.62);
    return Curves.easeOutCubic.transform(
      ((_intro.value - start) / 0.38).clamp(0.0, 1.0),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _openTab(CoordinatorTab tab) => openCoordinatorTab(context, null, tab);

  void _manage(double s) =>
      showManageSheet(context, managed: _managed, scale: s);

  Future<void> _message(double s) async {
    final sent = await showBroadcastSheet(context, scale: s, event: _managed);
    if (sent != null && mounted) {
      showAuthNotice(context, 'Message sent to $sent volunteers.');
    }
  }

  void _share() {
    final slug = widget.title.toLowerCase().replaceAll(' ', '-');
    Clipboard.setData(ClipboardData(text: 'https://foodlink.app/events/$slug'));
    HapticFeedback.selectionClick();
    showAuthNotice(context, 'Event link copied. Share it with volunteers.');
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final sure = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.42),
      builder: (dialogContext) => _ConfirmDialog(
        title: title,
        message: message,
        action: action,
        danger: action.startsWith('Cancel'),
      ),
    );
    return sure == true && mounted;
  }

  Future<void> _complete() async {
    if (!await _confirm(
      'Mark as complete?',
      'The event moves to Completed and volunteers get a thank-you.',
      'Complete',
    )) {
      return;
    }
    HapticFeedback.mediumImpact();
    CoordinatorBoard.complete(widget.title);
    if (mounted) {
      showAuthNotice(context, '${widget.title} is complete. Thank you!');
    }
  }

  Future<void> _cancel() async {
    if (!await _confirm(
      'Cancel this event?',
      'Everyone signed up will be told it’s off. This can’t be undone.',
      'Cancel Event',
    )) {
      return;
    }
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final title = widget.title;
    _last = _managed;
    // Tell them on the page they go back to.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    CoordinatorBoard.cancel(title);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.brandDark,
          content: Text('$title was cancelled. Volunteers have been told.'),
        ),
      );
  }

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
              _scroll,
              CoordinatorBoard.events,
              CoordinatorBoard.checkedIn,
              CoordinatorBoard.doneTasks,
            ]),
            builder: (context, _) {
              if (CoordinatorBoard.eventNamed(widget.title) case final m?) {
                _last = m;
              }
              return wide ? _buildWide(size, s) : _buildCompact(size, s);
            },
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
    final photoHeight = 320 * s + top * 0.5;
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    final bar = ((offset - (photoHeight - 130 * s)) / (60 * s)).clamp(0.0, 1.0);
    final width = math.min(size.width - 48 * s, 480 * s);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: bar > 0.5 ? Brightness.dark : Brightness.light,
        statusBarBrightness: bar > 0.5 ? Brightness.light : Brightness.dark,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: offset > 0 ? -offset * 0.45 : 0,
            height: photoHeight + 40 * s + (offset < 0 ? -offset : 0),
            child: _photo(radius: 0),
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
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: size.height - photoHeight + 32 * s,
                    ),
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
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(32 * s),
                            ),
                            child: CustomPaint(
                              painter: SoftBackdropPainter(
                                time: _ambient.value,
                              ),
                            ),
                          ),
                        ),
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
                            110 * s + bottom,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: width,
                              child: _details(s, titleSize: 29 * s),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top + 64 * s,
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
              child: _headerRow(s, onDark: bar < 0.5, titleOpacity: bar),
            ),
          ),
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
                    padding: EdgeInsets.fromLTRB(24 * s, 14 * s, 24 * s, 0),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.82),
                      border: const Border(
                        top: BorderSide(color: AppColors.fieldBorder),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      minimum: EdgeInsets.only(bottom: 14 * s),
                      child: Center(
                        child: SizedBox(width: width, child: _mainAction(s)),
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
    final photoHeight = (size.height - 150 * s).clamp(420 * s, 620 * s);
    return Stack(
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
              child: CoordinatorSideRail(
                current: CoordinatorTab.events,
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
                          _headerRow(s, onDark: false),
                          SizedBox(height: 22 * s),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 11,
                                child: SizedBox(
                                  height: photoHeight,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        30 * s,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.ink.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 40 * s,
                                          offset: Offset(0, 18 * s),
                                        ),
                                      ],
                                    ),
                                    child: _photo(radius: 30 * s),
                                  ),
                                ),
                              ),
                              SizedBox(width: 40 * s),
                              Expanded(
                                flex: 10,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _details(s, titleSize: 40 * s),
                                    SizedBox(height: 22 * s),
                                    _mainAction(s),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  // ---------------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------------

  Widget _photo({required double radius}) {
    final t = _ambient.value * 2 * math.pi;
    final managed = _managed;
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
              child: ColorFiltered(
                colorFilter: managed.status == EventStatus.completed
                    ? const ColorFilter.matrix([
                        0.6, 0.3, 0.1, 0, 10, //
                        0.3, 0.6, 0.1, 0, 10, //
                        0.3, 0.3, 0.4, 0, 10, //
                        0, 0, 0, 1, 0,
                      ])
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: EventPhoto(event: managed.event),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.splashScrim.withValues(alpha: 0.6),
                    AppColors.splashScrim.withValues(alpha: 0),
                    AppColors.splashScrim.withValues(alpha: 0.35),
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerRow(double s, {required bool onDark, double titleOpacity = 0}) {
    final ink = onDark ? AppColors.white : AppColors.ink;
    return Row(
      children: [
        AuthIconButton(
          label: 'Back',
          scale: s,
          onDark: onDark,
          onTap: () => Navigator.of(context).maybePop(),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18 * s,
            color: ink,
          ),
        ),
        Expanded(
          child: Opacity(
            opacity: titleOpacity,
            child: Text(
              widget.title,
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
          label: 'Share event',
          scale: s,
          onDark: onDark,
          onTap: _share,
          child: Icon(Icons.ios_share_rounded, size: 19 * s, color: ink),
        ),
      ],
    );
  }

  /// The main button for where the event is in its life.
  Widget _mainAction(double s) {
    final managed = _managed;
    return switch (managed.status) {
      EventStatus.ongoing => PrimaryButton(
        label: 'Manage Check-ins',
        scale: s * 0.92,
        time: _ambient.value,
        onPressed: () => _manage(s),
      ),
      EventStatus.upcoming => PrimaryButton(
        label: 'Message Volunteers',
        scale: s * 0.92,
        time: _ambient.value,
        onPressed: () => _message(s),
      ),
      EventStatus.completed => PrimaryButton(
        label: 'Send Thank-You',
        scale: s * 0.92,
        time: _ambient.value,
        onPressed: () => _message(s),
      ),
    };
  }

  Widget _details(double s, {required double titleSize}) {
    final managed = _managed;
    final event = managed.event;
    final here = CoordinatorBoard.checkedInAt(managed.title).length;
    var n = 0;
    Widget rise(Widget child) =>
        RiseIn(progress: _rise(n++), distance: 18 * s, child: child);
    final (fill, ink) = switch (managed.status) {
      EventStatus.ongoing => (AppColors.roleChosenFill, AppColors.brand),
      EventStatus.upcoming => (AppColors.tagLearnFill, AppColors.tagLearnText),
      EventStatus.completed => (AppColors.socialFill, AppColors.fieldIcon),
    };
    final spotsLeft = math.max(0, event.capacity - managed.roster.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rise(
          Wrap(
            spacing: 8 * s,
            runSpacing: 8 * s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusPill(
                label: managed.status.label,
                fill: fill,
                ink: ink,
                scale: s * 1.15,
              ),
              EventCategoryTag(
                category: event.category,
                scale: s,
                fontSize: 13,
              ),
              if (managed.ongoing) LiveChip(time: _ambient.value, scale: s),
            ],
          ),
        ),
        SizedBox(height: 14 * s),
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
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        SizedBox(height: 18 * s),
        rise(
          CoordinatorCard(
            scale: s,
            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 4 * s),
            child: Column(
              children: [
                for (final (i, (icon, label, text)) in [
                  (Icons.event_available_rounded, 'Date', event.date),
                  (Icons.schedule_rounded, 'Time', event.hours),
                  (Icons.place_outlined, 'Location', event.address),
                ].indexed) ...[
                  if (i > 0) rowDivider(),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12 * s),
                    child: Row(
                      children: [
                        Container(
                          width: 40 * s,
                          height: 40 * s,
                          decoration: BoxDecoration(
                            color: event.category.fill,
                            borderRadius: BorderRadius.circular(12 * s),
                          ),
                          child: Icon(
                            icon,
                            size: 20 * s,
                            color: event.category.text,
                          ),
                        ),
                        SizedBox(width: 14 * s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12.5 * s,
                                  color: AppColors.fieldIcon,
                                ),
                              ),
                              Text(
                                text,
                                style: TextStyle(
                                  fontSize: 15.5 * s,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: 16 * s),
        rise(
          SizedBox(
            height: 104 * s,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, (value, label, icon)) in [
                  (
                    '${managed.roster.length}/${event.capacity}',
                    'Signed up',
                    Icons.how_to_reg_rounded,
                  ),
                  if (managed.ongoing)
                    ('$here', 'Checked in', Icons.login_rounded)
                  else if (managed.status == EventStatus.upcoming)
                    ('$spotsLeft', 'Spots left', Icons.event_seat_rounded)
                  else
                    (
                      event.duration,
                      'Duration',
                      Icons.hourglass_bottom_rounded,
                    ),
                  (
                    managed.status == EventStatus.upcoming
                        ? event.impact.$1
                        : '${managed.mealsSoFar}',
                    managed.status == EventStatus.upcoming
                        ? 'Expected ${event.impact.$2.toLowerCase()}'
                        : 'Meals served',
                    Icons.restaurant_rounded,
                  ),
                ].indexed) ...[
                  if (i > 0) SizedBox(width: 10 * s),
                  Expanded(
                    child: Semantics(
                      container: true,
                      label: '$value $label',
                      excludeSemantics: true,
                      child: CoordinatorCard(
                        scale: s,
                        padding: EdgeInsets.symmetric(horizontal: 6 * s),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 18 * s,
                                color: AppColors.leafLight,
                              ),
                              SizedBox(height: 6 * s),
                              Text(
                                value,
                                style: TextStyle(
                                  fontSize: 22 * s,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12.5 * s,
                                  color: AppColors.bodyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: 14 * s),
        rise(_fillBar(managed, s)),
        SizedBox(height: 24 * s),
        rise(_teamSection(managed, s)),
        SizedBox(height: 24 * s),
        rise(_rolesSection(managed, s)),
        SizedBox(height: 24 * s),
        rise(_checklist(managed, s)),
        SizedBox(height: 24 * s),
        rise(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Subheading(text: 'About this event', scale: s),
              SizedBox(height: 10 * s),
              Text(
                event.about,
                style: TextStyle(
                  fontSize: 15.5 * s,
                  height: 1.6,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
        ),
        if (managed.status != EventStatus.completed) ...[
          SizedBox(height: 24 * s),
          rise(
            Row(
              children: [
                Expanded(
                  child: _OutlineAction(
                    icon: Icons.task_alt_rounded,
                    label: 'Mark Complete',
                    color: AppColors.brand,
                    scale: s,
                    onTap: _complete,
                  ),
                ),
                if (managed.status == EventStatus.upcoming) ...[
                  SizedBox(width: 10 * s),
                  Expanded(
                    child: _OutlineAction(
                      icon: Icons.event_busy_rounded,
                      label: 'Cancel Event',
                      color: AppColors.error,
                      scale: s,
                      onTap: _cancel,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _fillBar(ManagedEvent managed, double s) {
    final left = managed.event.capacity - managed.roster.length;
    final few = left > 0 && managed.fill < 0.5;
    final note = left <= 0
        ? 'Full: ${managed.roster.length} volunteers'
        : few
        ? 'Needs $left more volunteers'
        : '$left spots left';
    return Semantics(
      label: '${(managed.fill * 100).round()} percent full. $note',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: managed.fill),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, fill, _) => ClipRRect(
              borderRadius: BorderRadius.circular(5 * s),
              child: SizedBox(
                height: 10 * s,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: AppColors.stepTodo),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fill,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: few
                                ? const [AppColors.badge, AppColors.badgeRing]
                                : AppColors.accentGradient,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 8 * s),
          Text(
            note,
            style: TextStyle(
              fontSize: 13.5 * s,
              fontWeight: FontWeight.w600,
              color: few ? AppColors.badge : AppColors.fieldIcon,
            ),
          ),
        ],
      ),
    );
  }

  /// Overlapping faces of the team, opening the roster.
  Widget _teamSection(ManagedEvent managed, double s) {
    final faces = managed.roster.take(6).toList();
    final others = managed.roster.length - faces.length;
    final d = 40 * s;
    final step = 30 * s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Subheading(text: 'The team', scale: s),
        SizedBox(height: 12 * s),
        TappableRow(
          label: 'See all ${managed.roster.length} volunteers',
          scale: s,
          onTap: () => _manage(s),
          child: managed.roster.isEmpty
              ? Text(
                  'No one has signed up yet. Share the event to get started.',
                  style: TextStyle(
                    fontSize: 14.5 * s,
                    color: AppColors.bodyText,
                  ),
                )
              : Row(
                  children: [
                    SizedBox(
                      width:
                          d + step * (faces.length - 1 + (others > 0 ? 1 : 0)),
                      height: d,
                      child: Stack(
                        children: [
                          for (final (i, entry) in faces.indexed)
                            Positioned(
                              left: i * step,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 2.5,
                                  ),
                                ),
                                child: InitialsAvatar(
                                  initials: entry.initials,
                                  colors: entry.colors,
                                  size: d - 5,
                                ),
                              ),
                            ),
                          if (others > 0)
                            Positioned(
                              left: faces.length * step,
                              child: Container(
                                width: d,
                                height: d,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.roleChosenFill,
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 2.5,
                                  ),
                                ),
                                child: Text(
                                  '+$others',
                                  style: TextStyle(
                                    fontSize: 12 * s,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: Text(
                        'See all ${managed.roster.length}',
                        style: TextStyle(
                          fontSize: 14.5 * s,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  /// How many volunteers cover each role, as bars.
  Widget _rolesSection(ManagedEvent managed, double s) {
    final counts = <String, (IconData, int)>{};
    for (final entry in managed.roster) {
      final (icon, count) = counts[entry.role.name] ?? (entry.role.icon, 0);
      counts[entry.role.name] = (icon, count + 1);
    }
    final most = counts.values.fold(1, (m, e) => math.max(m, e.$2));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Subheading(text: 'Roles covered', scale: s),
        SizedBox(height: 12 * s),
        CoordinatorCard(
          scale: s,
          child: counts.isEmpty
              ? Text(
                  'Roles fill up as volunteers join.',
                  style: TextStyle(
                    fontSize: 14.5 * s,
                    color: AppColors.bodyText,
                  ),
                )
              : Column(
                  children: [
                    for (final (i, MapEntry(key: role, value: (icon, count)))
                        in counts.entries.indexed)
                      Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 12 * s),
                        child: Semantics(
                          label: '$role: $count',
                          excludeSemantics: true,
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                size: 18 * s,
                                color: AppColors.leafLight,
                              ),
                              SizedBox(width: 10 * s),
                              SizedBox(
                                width: 112 * s,
                                child: Text(
                                  role,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5 * s,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: count / most),
                                  duration: Duration(
                                    milliseconds: 800 + i * 120,
                                  ),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, fill, _) => ClipRRect(
                                    borderRadius: BorderRadius.circular(4 * s),
                                    child: SizedBox(
                                      height: 8 * s,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          const ColoredBox(
                                            color: AppColors.stepTodo,
                                          ),
                                          FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: fill,
                                            child: const DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors:
                                                      AppColors.accentGradient,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10 * s),
                              Text(
                                '$count',
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
        ),
      ],
    );
  }

  /// The prep list, with a ring showing how much is done.
  Widget _checklist(ManagedEvent managed, double s) {
    final tasks = eventTasks(managed);
    final done = CoordinatorBoard.tasksDone(managed.title);
    final count = tasks.where(done.contains).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _Subheading(text: 'Prep checklist', scale: s),
            ),
            SizedBox.square(
              dimension: 36 * s,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: count / tasks.length),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 4 * s,
                      backgroundColor: AppColors.stepTodo,
                      color: AppColors.brand,
                    ),
                    Center(
                      child: Text(
                        '$count/${tasks.length}',
                        style: TextStyle(
                          fontSize: 10.5 * s,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10 * s),
        CoordinatorCard(
          scale: s,
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 4 * s),
          child: Column(
            children: [
              for (final (i, task) in tasks.indexed) ...[
                if (i > 0) rowDivider(),
                Semantics(
                  button: true,
                  toggled: done.contains(task),
                  label: task,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      CoordinatorBoard.toggleTask(managed.title, task);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12 * s),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 24 * s,
                            height: 24 * s,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done.contains(task)
                                  ? AppColors.brand
                                  : AppColors.white,
                              border: Border.all(
                                color: done.contains(task)
                                    ? AppColors.brand
                                    : AppColors.fieldBorder,
                                width: 1.5,
                              ),
                            ),
                            child: AnimatedScale(
                              scale: done.contains(task) ? 1 : 0,
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutBack,
                              child: Icon(
                                Icons.check_rounded,
                                size: 15 * s,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12 * s),
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 15 * s,
                                fontWeight: FontWeight.w500,
                                color: done.contains(task)
                                    ? AppColors.fieldIcon
                                    : AppColors.ink,
                                decoration: done.contains(task)
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: AppColors.fieldIcon,
                              ),
                              child: Text(task),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

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

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.scale,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 50 * s,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(25 * s),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18 * s, color: color),
                SizedBox(width: 7 * s),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5 * s,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
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

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.action,
    required this.danger,
  });

  final String title;
  final String message;
  final String action;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    Widget button(String label, Color fill, Color ink, bool value) => Expanded(
      child: Semantics(
        button: true,
        label: '$label button',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(value),
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
    return Center(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 340,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 14.5,
                  height: 1.5,
                  color: AppColors.bodyText,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  button('Not now', AppColors.socialFill, AppColors.ink, false),
                  const SizedBox(width: 12),
                  button(
                    action,
                    danger ? AppColors.error : AppColors.brand,
                    AppColors.white,
                    true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
