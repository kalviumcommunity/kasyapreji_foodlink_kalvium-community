import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import '../widgets/rise_in.dart';
import '../widgets/soft_backdrop.dart';
import 'event_details_screen.dart';
import 'explore_screen.dart';

/// The volunteer's numbers, from the events they've been to.
final _stats = [
  (pastVisits.length, 'Events', Icons.event_available_rounded),
  (
    pastVisits.fold(0, (sum, visit) => sum + visit.hours),
    'Hours',
    Icons.schedule_rounded,
  ),
  (
    {for (final visit in pastVisits) visit.event.organiser}.length,
    'Communities',
    Icons.groups_rounded,
  ),
];

/// Volunteer home: greeting, a quote, the volunteer's numbers and upcoming
/// events.
///
/// A community-meal photo fades into the soft page backdrop behind the
/// greeting; the numbers count up as the page arrives and the hand waves.
///
/// Phones follow the Figma frame with a bottom navigation bar; laptops get a
/// side navigation rail and the events as a grid of photo cards.
///
/// The Explore tab and "View All" open [ExploreScreen], each event opens its
/// [EventDetailsScreen], and the other tabs open their sections. [name] is a
/// sample value until accounts exist.
class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({super.key, this.name = 'Agnibha'});

  final String name;

  static const String routeName = 'volunteer-home';

  static const String photo = 'assets/images/onboarding_community_meal.jpg';
  static const String quotePhoto = 'assets/images/splash_giving.jpg';

  @override
  State<VolunteerHomeScreen> createState() => _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends State<VolunteerHomeScreen>
    with TickerProviderStateMixin {
  final _photo = AssetPhoto(VolunteerHomeScreen.photo);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
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
    for (final event in upcomingEvents) {
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

  void _openTab(AppTab tab) => openAppTab(context, AppTab.home, tab);

  void _openEvent(VolunteerEvent event) => openEventDetails(
    context,
    event,
    from: AppTab.home,
    heroTag: _heroTag(event),
  );

  static Object _heroTag(VolunteerEvent event) => 'home/${event.title}';

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
              animation: Listenable.merge([_intro, _ambient]),
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
              padding: EdgeInsets.only(top: 14 * s, bottom: 28 * s),
              child: Center(
                child: SizedBox(
                  width: width,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RiseIn(
                          progress: _rise(0),
                          distance: -10 * s,
                          child: _headerRow(s),
                        ),
                        SizedBox(height: 26 * s),
                        RiseIn(
                          progress: _rise(1),
                          distance: 18 * s,
                          child: _greetingBlock(s, 21 * s, 36 * s),
                        ),
                        SizedBox(height: 26 * s),
                        RiseIn(
                          progress: _rise(2),
                          distance: 20 * s,
                          child: SizedBox(
                            height: 116 * s,
                            child: _QuoteCard(scale: s, time: _ambient.value),
                          ),
                        ),
                        SizedBox(height: 16 * s),
                        SizedBox(height: 104 * s, child: _statsRow(s, 12 * s)),
                        SizedBox(height: 30 * s),
                        RiseIn(
                          progress: _rise(6),
                          distance: 16 * s,
                          child: _sectionHeader(s, 23 * s),
                        ),
                        SizedBox(height: 14 * s),
                        Container(height: 1, color: AppColors.fieldBorder),
                        for (final (i, event) in upcomingEvents.indexed)
                          Padding(
                            padding: EdgeInsets.only(top: 18 * s),
                            child: RiseIn(
                              progress: _rise(7 + i),
                              distance: 20 * s,
                              child: EventTile(
                                event: event,
                                scale: s,
                                card: false,
                                onTap: () => _openEvent(event),
                                heroTag: _heroTag(event),
                              ),
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
        AppBottomBar(current: AppTab.home, scale: s, onSelect: _openTab),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Laptop layout
  // ---------------------------------------------------------------------------

  Widget _buildWide(Size size, double s, double railWidth) {
    final mainWidth = math.min(size.width - railWidth, 1080 * s);
    final content = mainWidth - 96 * s;
    final stacked = content < 620;
    final columns = content >= 700 ? 3 : (content >= 440 ? 2 : 1);
    final gap = 20 * s;
    final cardWidth = (content - gap * (columns - 1)) / columns;

    return Row(
      children: [
        SizedBox(
          width: railWidth,
          child: AppSideRail(
            current: AppTab.home,
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
                        child: _greetingBlock(s, 22 * s, 48 * s),
                      ),
                      SizedBox(height: 28 * s),
                      if (stacked) ...[
                        RiseIn(
                          progress: _rise(2),
                          distance: 20 * s,
                          child: SizedBox(
                            height: 130 * s,
                            child: _QuoteCard(scale: s, time: _ambient.value),
                          ),
                        ),
                        SizedBox(height: 16 * s),
                        SizedBox(height: 116 * s, child: _statsRow(s, 14 * s)),
                      ] else
                        SizedBox(
                          height: 148 * s,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 10,
                                child: RiseIn(
                                  progress: _rise(2),
                                  distance: 20 * s,
                                  child: _QuoteCard(
                                    scale: s * 1.15,
                                    time: _ambient.value,
                                  ),
                                ),
                              ),
                              SizedBox(width: gap),
                              Expanded(flex: 11, child: _statsRow(s, 16 * s)),
                            ],
                          ),
                        ),
                      SizedBox(height: 36 * s),
                      RiseIn(
                        progress: _rise(6),
                        distance: 16 * s,
                        child: _sectionHeader(s, 28 * s),
                      ),
                      SizedBox(height: 14 * s),
                      Container(height: 1, color: AppColors.fieldBorder),
                      SizedBox(height: 22 * s),
                      Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final (i, event) in upcomingEvents.indexed)
                            SizedBox(
                              width: cardWidth,
                              child: RiseIn(
                                progress: _rise(7 + i),
                                distance: 24 * s,
                                child: EventTile(
                                  event: event,
                                  scale: s,
                                  card: true,
                                  onTap: () => _openEvent(event),
                                  heroTag: _heroTag(event),
                                ),
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
        AuthAvatar(
          scale: s * 1.1,
          onTap: () => openAppTab(context, AppTab.home, AppTab.profile),
        ),
      ],
    );
  }

  /// "Good Morning," over the volunteer's name and a waving hand.
  Widget _greetingBlock(double s, double small, double large) {
    final cycle = _ambient.value * 2 % 1.0;
    final wave = _intro.isCompleted && cycle < 0.4
        ? math.sin(cycle / 0.4 * math.pi * 4) * 0.3
        : 0.0;
    return Semantics(
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
    );
  }

  Widget _statsRow(double s, double gap) {
    // The numbers count up while the page arrives.
    final count = Curves.easeOutCubic.transform(
      ((_intro.value - 0.25) / 0.75).clamp(0.0, 1.0),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (value, label, icon)) in _stats.indexed) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: RiseIn(
              progress: _rise(3 + i),
              distance: 20 * s,
              child: _StatTile(
                value: value,
                shown: (value * count).round(),
                label: label,
                icon: icon,
                scale: s,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(double s, double fontSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Upcoming Events',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        AuthTextLink(
          label: 'View All',
          scale: s,
          fontSize: 17,
          onTap: () => openAppTab(context, AppTab.home, AppTab.explore),
        ),
      ],
    );
  }
}

/// The quote on pale green, with a photo of shared food melting in from the
/// right.
class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.scale, required this.time});

  final double scale;
  final double time;

  /// The card's green where the photo begins.
  static final Color _wash = Color.lerp(
    AppColors.roleChosenCircle,
    AppColors.roleChosenFill,
    0.56,
  )!;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final radius = BorderRadius.circular(24 * s);
    return Semantics(
      label: 'Small actions make a big difference.',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.12),
              blurRadius: 24 * s,
              offset: Offset(0, 10 * s),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.roleChosenCircle,
                      AppColors.roleChosenFill,
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.44,
                  heightFactor: 1,
                  // The photo, under a wash of the card's green that thins
                  // out to the right.
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Inset a touch so the wash fully covers its edge.
                      Padding(
                        padding: const EdgeInsets.only(left: 1.5),
                        child: ClipRect(
                          child: Transform.scale(
                            scale: 1.06 + 0.04 * math.sin(time * 2 * math.pi),
                            child: Image.asset(
                              VolunteerHomeScreen.quotePhoto,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_wash, _wash.withValues(alpha: 0.25)],
                            stops: const [0, 0.75],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18 * s),
                child: Row(
                  children: [
                    Align(
                      alignment: const Alignment(0, -0.45),
                      child: Text(
                        '“',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 58 * s,
                          height: 0.9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Container(
                      width: 2.5 * s,
                      margin: EdgeInsets.symmetric(vertical: 20 * s),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(2 * s),
                      ),
                    ),
                    SizedBox(width: 18 * s),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Small actions\nmake a big difference.',
                          style: TextStyle(
                            fontSize: 18 * s,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 40 * s),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the volunteer's numbers, with its icon and label.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.shown,
    required this.label,
    required this.icon,
    required this.scale,
  });

  /// The real number, and the one on screen while it counts up.
  final int value;
  final int shown;
  final String label;
  final IconData icon;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6 * s),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.66),
          borderRadius: BorderRadius.circular(20 * s),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.9)),
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
              Icon(icon, size: 17 * s, color: AppColors.leafLight),
              SizedBox(height: 3 * s),
              Text(
                '$shown',
                style: TextStyle(
                  fontSize: 27 * s,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 2 * s),
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
