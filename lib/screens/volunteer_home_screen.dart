import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/asset_photo.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/foodlink_logo.dart';
import '../widgets/leaf.dart';
import '../widgets/light_particles.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/rise_in.dart';
import '../widgets/soft_backdrop.dart';

/// One upcoming event in the list.
class _Event {
  const _Event(this.title, this.when, this.place, this.photo, this.focus);

  final String title;
  final String when;
  final String place;
  final String photo;
  final Alignment focus;
}

/// Sample events, until events come from the database.
const _events = [
  _Event(
    'Community Food Drive',
    'Sat, 20 Sep · 10:00 AM',
    'Riverside Center',
    'assets/images/role_volunteer.jpg',
    Alignment(0.1, -0.3),
  ),
  _Event(
    'Weekend Meal Packing',
    'Sun, 21 Sep · 9:00 AM',
    'Hope Kitchen',
    'assets/images/impact_packing.jpg',
    Alignment.center,
  ),
  _Event(
    'Neighbourhood Share Day',
    'Sat, 27 Sep · 4:00 PM',
    'Green Park',
    'assets/images/change_volunteers.jpg',
    Alignment.center,
  ),
];

/// The volunteer's numbers: value, label, icon. Sample values for now.
const _stats = [
  (12, 'Events', Icons.event_available_rounded),
  (36, 'Hours', Icons.schedule_rounded),
  (5, 'Communities', Icons.groups_rounded),
];

/// The app's main sections. Only Home exists so far.
const _tabs = [
  ('Home', Icons.home_rounded),
  ('Explore', Icons.search_rounded),
  ('Events', Icons.calendar_today_rounded),
  ('Community', Icons.sentiment_satisfied_alt_rounded),
  ('Profile', Icons.person_outline_rounded),
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
/// The other sections and event details aren't designed yet, so they answer
/// with a notice for now. [name] and the numbers are sample values until
/// accounts exist.
class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({super.key, this.name = 'Agnibha'});

  final String name;

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
    for (final event in _events) {
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

  void _openTab(int index) {
    if (index == 0) return;
    HapticFeedback.selectionClick();
    showAuthNotice(context, '${_tabs[index].$1} is coming soon.');
  }

  void _soon(String what) => showAuthNotice(context, '$what coming soon.');

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
                        painter: _ScenePainter(
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
                        for (final (i, event) in _events.indexed)
                          Padding(
                            padding: EdgeInsets.only(top: 18 * s),
                            child: RiseIn(
                              progress: _rise(7 + i),
                              distance: 20 * s,
                              child: _EventTile(
                                event: event,
                                scale: s,
                                card: false,
                                onTap: () => _soon('Event details are'),
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
        _bottomBar(s),
      ],
    );
  }

  Widget _bottomBar(double s) {
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
              for (final (i, (label, icon)) in _tabs.indexed)
                Expanded(
                  child: _NavItem(
                    label: label,
                    icon: icon,
                    selected: i == 0,
                    scale: s,
                    rail: false,
                    onTap: () => _openTab(i),
                  ),
                ),
            ],
          ),
        ),
      ),
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
        SizedBox(width: railWidth, child: _rail(s)),
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
                          for (final (i, event) in _events.indexed)
                            SizedBox(
                              width: cardWidth,
                              child: RiseIn(
                                progress: _rise(7 + i),
                                distance: 24 * s,
                                child: _EventTile(
                                  event: event,
                                  scale: s,
                                  card: true,
                                  onTap: () => _soon('Event details are'),
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

  /// Laptops: brand mark and the sections down the left side.
  Widget _rail(double s) {
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
                  for (final (i, (label, icon)) in _tabs.indexed)
                    Padding(
                      padding: EdgeInsets.only(bottom: 6 * s),
                      child: _NavItem(
                        label: label,
                        icon: icon,
                        selected: i == 0,
                        scale: s,
                        rail: true,
                        onTap: () => _openTab(i),
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
          onTap: () => _soon('The full events list is'),
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

/// An upcoming event: a row with a square photo (phones), or a [card] with
/// the photo on top (laptops). Lifts on hover and dips when pressed.
class _EventTile extends StatefulWidget {
  const _EventTile({
    required this.event,
    required this.scale,
    required this.card,
    required this.onTap,
  });

  final _Event event;
  final double scale;
  final bool card;
  final VoidCallback onTap;

  @override
  State<_EventTile> createState() => _EventTileState();
}

class _EventTileState extends State<_EventTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final event = widget.event;
    final card = widget.card;

    Widget photo(double radius) => ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AnimatedScale(
        scale: _hovered ? 1.06 : 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: Image.asset(
          event.photo,
          fit: BoxFit.cover,
          alignment: event.focus,
          errorBuilder: (_, _, _) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppColors.earthLight, AppColors.brand],
              ),
            ),
          ),
        ),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17 * s,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        SizedBox(height: 9 * s),
        for (final (icon, text) in [
          (Icons.schedule_rounded, event.when),
          (Icons.place_outlined, event.place),
        ])
          Padding(
            padding: EdgeInsets.only(bottom: 6 * s),
            child: Row(
              children: [
                Icon(icon, size: 15 * s, color: AppColors.leafLight),
                SizedBox(width: 6 * s),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5 * s,
                      color: AppColors.bodyText,
                    ),
                  ),
                ),
              ],
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
              transform: Matrix4.translationValues(0, _hovered ? -4 * s : 0, 0),
              padding: card ? EdgeInsets.all(10 * s) : EdgeInsets.zero,
              decoration: card
                  ? BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.72),
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
              child: card
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(aspectRatio: 16 / 10, child: photo(16 * s)),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            8 * s,
                            14 * s,
                            8 * s,
                            4 * s,
                          ),
                          child: details,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        SizedBox.square(
                          dimension: 108 * s,
                          child: photo(20 * s),
                        ),
                        SizedBox(width: 20 * s),
                        Expanded(child: details),
                      ],
                    ),
            ),
          ),
        ),
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

const _leaf = LeafShape(
  tipA: Offset(52, 6),
  tipB: Offset(14, 70),
  bulgeLeft: 14,
  bulgeRight: 12,
  color: AppColors.onboardingLeaf,
  veinColor: AppColors.leafVein,
);

/// The photo washed into the top of the page (right of the side rail on
/// laptops), with green specks drifting up and a leaf swaying in the corner.
class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.photo,
    required this.time,
    required this.reveal,
    required this.appear,
    required this.left,
    required this.scale,
  });

  final ui.Image? photo;
  final double time;
  final double reveal;
  final double appear;

  /// Where the photo starts from the left (the side rail's width).
  final double left;
  final double scale;

  static final _specks = LightParticles(
    top: 60,
    bottom: 900,
    count: 14,
    seed: 31,
    color: AppColors.leafLight,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final s = scale;
    final image = photo;
    if (image != null && reveal > 0) {
      final rect = Rect.fromLTRB(left, 0, size.width, 330 * s);
      canvas.saveLayer(rect, Paint());
      // Pale, so the dark greeting stays easy to read on top.
      paintPhotoCover(
        canvas,
        image,
        rect,
        alignment: const Alignment(0, -0.2),
        zoom: 1.05 + 0.04 * math.sin(time * 2 * math.pi),
        opacity: 0.32 * reveal,
      );
      canvas.drawRect(
        rect.inflate(2),
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.linear(
            Offset(rect.center.dx, rect.top + rect.height * 0.2),
            rect.bottomCenter,
            const [Color(0xFF000000), Color(0x00000000)],
          ),
      );
      canvas.restore();
    }

    _specks.paint(
      canvas,
      sx: size.width / OnboardingLayout.designWidth,
      sy: size.height / OnboardingLayout.designHeight,
      time: time,
      opacity: 0.5 * appear,
    );

    paintSwayingLeaf(
      canvas,
      _leaf,
      target: Offset(size.width - 34 * s, 124 * s),
      scale: s * 0.75,
      time: time,
      appear: appear,
    );
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) => true;
}
