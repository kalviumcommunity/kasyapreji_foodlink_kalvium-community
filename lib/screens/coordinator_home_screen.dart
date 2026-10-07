import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/coordinator.dart';
import '../navigation/tab_navigation.dart';
import '../navigation/transitions.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/app_nav.dart';
import '../widgets/asset_photo.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/coordinator_widgets.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/page_scene.dart';
import '../widgets/primary_button.dart';
import '../widgets/rise_in.dart';
import '../widgets/soft_backdrop.dart';
import 'coordinator/beneficiaries_screen.dart';
import 'coordinator/create_event_screen.dart';
import 'coordinator/event_details_screen.dart';

/// Coordinator home: a greeting, the coordinator's numbers, and today's
/// event with Manage Event, as in the Figma.
///
/// Today's event shows who has checked in, live. Manage Event (and Check
/// In) opens a panel to check volunteers in and message them. Below are
/// alerts that need a decision (each handled with one tap), quick actions
/// (message volunteers, check in, new event), the rest of the week's events
/// with how full each is (each opening the same panel), and what volunteers
/// have been doing.
///
/// A photo of a coordinator with her clipboard fades into the backdrop
/// behind the greeting. Phones follow the Figma frame with the
/// coordinator's bottom bar; laptops get the side rail, today's event and
/// the week on the left, and alerts, actions and activity on the right.
class CoordinatorHomeScreen extends StatefulWidget {
  const CoordinatorHomeScreen({super.key, this.name = 'Agnibha'});

  final String name;

  static const String routeName = 'coordinator-home';

  static const String photo = 'assets/images/role_coordinator.jpg';

  @override
  State<CoordinatorHomeScreen> createState() => _CoordinatorHomeScreenState();
}

class _CoordinatorHomeScreenState extends State<CoordinatorHomeScreen>
    with TickerProviderStateMixin {
  final _photo = AssetPhoto(CoordinatorHomeScreen.photo);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  ManagedEvent get _today => CoordinatorBoard.active.first;
  List<ManagedEvent> get _week => CoordinatorBoard.active.skip(1).toList();

  double _rise(int n) {
    final start = (n * 0.065).clamp(0.0, 0.6);
    return Curves.easeOutCubic.transform(
      ((_intro.value - start) / 0.4).clamp(0.0, 1.0),
    );
  }

  /// How far the numbers have counted up (0–1).
  double get _count => Curves.easeOutCubic.transform(
    ((_intro.value - 0.2) / 0.8).clamp(0.0, 1.0),
  );

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _photo.resolve(context, () {
      if (mounted) setState(() {});
    });
    for (final managed in CoordinatorBoard.events.value) {
      precacheImage(AssetImage(managed.event.photo), context);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _photo.dispose();
    super.dispose();
  }

  void _openTab(CoordinatorTab tab) =>
      openCoordinatorTab(context, CoordinatorTab.home, tab);

  Future<void> _createEvent() async {
    final created = await Navigator.of(context)
        .push<String>(softRoute(const CreateEventScreen()));
    if (created != null && mounted) {
      showAuthNotice(context, '$created is live. Volunteers can sign up now.');
    }
  }

  void _details(ManagedEvent managed) =>
      Navigator.of(context)
          .push(softRoute(CoordinatorEventDetailsScreen(title: managed.title)));

  void _openBeneficiaries() => Navigator.of(context).push(
    softRoute(const BeneficiariesScreen(), name: BeneficiariesScreen.routeName),
  );

  /// A row of Recent Activity: its event's panel, or for the coordinator's
  /// own message, the message panel.
  void _openActivity(String? title, double s) {
    final managed = title == null ? null : CoordinatorBoard.eventNamed(title);
    if (managed != null) {
      _manage(managed, s);
    } else {
      _broadcast(s);
    }
  }

  void _manage(ManagedEvent managed, double s) {
    HapticFeedback.selectionClick();
    showManageSheet(context, managed: managed, scale: s);
  }

  Future<void> _broadcast(double s) async {
    final sent = await showBroadcastSheet(context, scale: s);
    if (sent != null && mounted) {
      showAuthNotice(context, 'Message sent to $sent volunteers.');
    }
  }

  void _handle(CoordinatorAlert alert) {
    HapticFeedback.mediumImpact();
    CoordinatorBoard.handle(alert.id);
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
                CoordinatorBoard.events,
                CoordinatorBoard.checkedIn,
                CoordinatorBoard.handledAlerts,
              ]),
              builder: (context, _) => Stack(
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
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: PageScenePainter(
                          photo: _photo.image,
                          time: _ambient.value,
                          reveal: _rise(0),
                          appear: _rise(5),
                          left: railWidth,
                          scale: s,
                          height: 300,
                          focus: const Alignment(0, -0.4),
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
    final width = math.min(size.width, 520 * s) - 48 * s;
    return Column(
      children: [
        Expanded(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24 * s, 14 * s, 24 * s, 28 * s),
              child: Center(
                child: SizedBox(
                  width: width,
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
                        child: _greetingRow(s, 21 * s, 36 * s),
                      ),
                      SizedBox(height: 26 * s),
                      SizedBox(height: 132 * s, child: _statsRow(s)),
                      SizedBox(height: 30 * s),
                      ..._todaySection(s, first: 5, wide: false),
                      SizedBox(height: 30 * s),
                      ..._alertsSection(s, first: 8),
                      SizedBox(height: 26 * s),
                      RiseIn(
                        progress: _rise(10),
                        distance: 18 * s,
                        child: _quickActions(s),
                      ),
                      SizedBox(height: 30 * s),
                      ..._weekSection(s, first: 11),
                      SizedBox(height: 30 * s),
                      ..._activitySection(s, first: 13),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        CoordinatorBottomBar(
          current: CoordinatorTab.home,
          scale: s,
          onSelect: _openTab,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Laptop layout
  // ---------------------------------------------------------------------------

  Widget _buildWide(Size size, double s, double railWidth) {
    final mainWidth = math.min(size.width - railWidth, 1140 * s);
    return Row(
      children: [
        SizedBox(
          width: railWidth,
          child: CoordinatorSideRail(
            current: CoordinatorTab.home,
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
                      SizedBox(height: 18 * s),
                      RiseIn(
                        progress: _rise(1),
                        distance: 20 * s,
                        child: _greetingRow(s, 22 * s, 48 * s),
                      ),
                      SizedBox(height: 26 * s),
                      SizedBox(height: 132 * s, child: _statsRow(s)),
                      SizedBox(height: 34 * s),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ..._todaySection(s, first: 5, wide: true),
                                SizedBox(height: 30 * s),
                                ..._weekSection(s, first: 8),
                              ],
                            ),
                          ),
                          SizedBox(width: 32 * s),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ..._alertsSection(s, first: 6),
                                SizedBox(height: 26 * s),
                                RiseIn(
                                  progress: _rise(8),
                                  distance: 18 * s,
                                  child: _quickActions(s),
                                ),
                                SizedBox(height: 26 * s),
                                ..._activitySection(s, first: 9),
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
    );
  }

  // ---------------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------------

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
        AuthAvatar(
          scale: s * 1.1,
          onTap: () => _openTab(CoordinatorTab.profile),
        ),
      ],
    );
  }

  /// "Good Morning," over the name and a waving hand, with the Figma's
  /// Coordinator pill on the right.
  Widget _greetingRow(double s, double small, double large) {
    final cycle = _ambient.value * 2 % 1.0;
    final wave = _intro.isCompleted && cycle < 0.4
        ? math.sin(cycle / 0.4 * math.pi * 4) * 0.3
        : 0.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            label: '$_greeting ${widget.name}!',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: TextStyle(
                    fontSize: small,
                    fontWeight: FontWeight.w500,
                    color: AppColors.bodyText,
                  ),
                ),
                SizedBox(height: 2 * s),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        '${widget.name}!',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: large,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -large * 0.01,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(width: large * 0.25),
                      Transform.rotate(
                        angle: wave,
                        alignment: Alignment.bottomCenter,
                        child: Icon(
                          Icons.waving_hand_rounded,
                          size: large * 0.82,
                          color: AppColors.sun,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12 * s),
        Semantics(
          button: true,
          label: 'Coordinator profile',
          excludeSemantics: true,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _openTab(CoordinatorTab.profile),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * s,
                  vertical: 11 * s,
                ),
                decoration: BoxDecoration(
                  color: AppColors.roleChosenFill,
                  borderRadius: BorderRadius.circular(24 * s),
                  border: Border.all(color: AppColors.roleChosenBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.assignment_ind_outlined,
                      size: 17 * s,
                      color: AppColors.brand,
                    ),
                    SizedBox(width: 6 * s),
                    Text(
                      'Coordinator',
                      style: TextStyle(
                        fontSize: 15 * s,
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
      ],
    );
  }

  /// The Figma's three pale green tiles, counting up.
  Widget _statsRow(double s) {
    final stats = [
      (
        CoordinatorBoard.active.length,
        'Active\nEvents',
        'Active Events',
        CoordinatorTab.events,
      ),
      (
        coordinatorVolunteers,
        'Volunteers',
        'Volunteers',
        CoordinatorTab.volunteers,
      ),
      (
        coordinatorMealsDistributed,
        'Meals\nDistributed',
        'Meals Distributed',
        CoordinatorTab.reports,
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (value, label, spoken, tab)) in stats.indexed) ...[
          if (i > 0) SizedBox(width: 12 * s),
          Expanded(
            child: RiseIn(
              progress: _rise(2 + i),
              distance: 20 * s,
              child: Semantics(
                container: true,
                button: true,
                label: '${formatCount(value)} $spoken',
                excludeSemantics: true,
                child: _Pressable(
                  onTap: () => _openTab(tab),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * s),
                    decoration: BoxDecoration(
                      color: AppColors.roleChosenFill.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(22 * s),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.06),
                          blurRadius: 18 * s,
                          offset: Offset(0, 6 * s),
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatCount((value * _count).round()),
                            style: TextStyle(
                              fontSize: 28 * s,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 6 * s),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15 * s,
                              height: 1.35,
                              color: AppColors.bodyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, double s, {Widget? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 23 * s,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }

  /// Today's Events: the ongoing event and Manage Event.
  List<Widget> _todaySection(
    double s, {
    required int first,
    required bool wide,
  }) {
    final today = _today;
    return [
      RiseIn(
        progress: _rise(first),
        distance: 16 * s,
        child: _sectionTitle(
          'Today\'s Events',
          s,
          trailing: LiveChip(time: _ambient.value, scale: s),
        ),
      ),
      SizedBox(height: 16 * s),
      RiseIn(
        progress: _rise(first + 1),
        distance: 18 * s,
        child: TodayEventCard(
          managed: today,
          checkedIn: CoordinatorBoard.checkedInAt(today.title).length,
          time: _ambient.value,
          scale: s,
          large: wide,
          onTap: () => _details(today),
        ),
      ),
      SizedBox(height: 18 * s),
      RiseIn(
        progress: _rise(first + 2),
        distance: 18 * s,
        child: PrimaryButton(
          label: 'Manage Event',
          scale: s,
          time: _ambient.value,
          onPressed: () => _manage(today, s),
        ),
      ),
    ];
  }

  List<Widget> _alertsSection(double s, {required int first}) {
    final handled = CoordinatorBoard.handledAlerts.value;
    final open = coordinatorAlerts.where((a) => !handled.contains(a.id));
    return [
      RiseIn(
        progress: _rise(first),
        distance: 16 * s,
        child: _sectionTitle(
          'Needs Your Attention',
          s,
          trailing: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey(open.length),
              padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 3 * s),
              decoration: BoxDecoration(
                color: open.isEmpty
                    ? AppColors.roleChosenFill
                    : AppColors.badge,
                borderRadius: BorderRadius.circular(12 * s),
              ),
              child: Text(
                open.isEmpty ? 'All clear' : '${open.length}',
                style: TextStyle(
                  fontSize: 13 * s,
                  fontWeight: FontWeight.w700,
                  color: open.isEmpty ? AppColors.brand : AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      SizedBox(height: 14 * s),
      for (final (i, alert) in coordinatorAlerts.indexed)
        RiseIn(
          progress: _rise(first + 1 + i ~/ 2),
          distance: 18 * s,
          child: Padding(
            padding: EdgeInsets.only(bottom: 12 * s),
            child: AlertCard(
              alert: alert,
              handled: handled.contains(alert.id),
              scale: s,
              onAction: () => _handle(alert),
            ),
          ),
        ),
    ];
  }

  Widget _quickActions(double s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('Quick Actions', s),
        SizedBox(height: 14 * s),
        Row(
          children: [
            for (final (i, (icon, label, onTap)) in [
              (
                Icons.campaign_outlined,
                'Message\nVolunteers',
                () => _broadcast(s),
              ),
              (
                Icons.how_to_reg_outlined,
                'Check In\nVolunteers',
                () => _manage(_today, s),
              ),
              (Icons.add_circle_outline_rounded, 'Create\nEvent', _createEvent),
              (
                Icons.diversity_1_outlined,
                'Benefi-\nciaries',
                _openBeneficiaries,
              ),
            ].indexed) ...[
              if (i > 0) SizedBox(width: 10 * s),
              Expanded(
                child: QuickActionTile(
                  icon: icon,
                  label: label,
                  scale: s,
                  onTap: onTap,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  List<Widget> _weekSection(double s, {required int first}) {
    return [
      RiseIn(
        progress: _rise(first),
        distance: 16 * s,
        child: _sectionTitle('Coming Up This Week', s),
      ),
      SizedBox(height: 6 * s),
      for (final (i, managed) in _week.indexed)
        RiseIn(
          progress: _rise(first + 1 + i ~/ 2),
          distance: 18 * s,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (i > 0) Container(height: 1, color: AppColors.fieldBorder),
              WeekEventRow(
                managed: managed,
                scale: s,
                onTap: () => _details(managed),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _activitySection(double s, {required int first}) {
    return [
      RiseIn(
        progress: _rise(first),
        distance: 16 * s,
        child: _sectionTitle('Recent Activity', s),
      ),
      SizedBox(height: 12 * s),
      RiseIn(
        progress: _rise(first + 1),
        distance: 18 * s,
        child: ActivityCard(
          scale: s,
          onOpen: (title) => _openActivity(title, s),
        ),
      ),
    ];
  }
}

/// Lifts on hover and dips when pressed, then calls [onTap].
class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.96 : (_hovered ? 1.02 : 1),
          duration: const Duration(milliseconds: 160),
          child: widget.child,
        ),
      ),
    );
  }
}
