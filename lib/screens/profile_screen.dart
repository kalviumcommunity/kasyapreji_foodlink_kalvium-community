import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/community.dart';
import '../data/my_events.dart';
import '../data/volunteer_profile.dart';
import '../navigation/tab_navigation.dart';
import '../navigation/transitions.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/app_nav.dart';
import '../widgets/asset_photo.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/page_scene.dart';
import '../widgets/rise_in.dart';
import '../widgets/soft_backdrop.dart';
import 'my_events_screen.dart';
import 'profile_pages.dart';
import 'sign_in_screen.dart';

/// Profile: who the volunteer is and what they've done.
///
/// Their photo, name and level sit at the top, then their events, hours and
/// certificates (each opening the matching page), progress towards the next
/// level, the badges they've earned and those still to earn, and a switch
/// to say they're free for last-minute calls. Below that are Personal
/// Information, Interests, Certificates, Settings and Help & Support, each
/// on its own page, and Log Out, which asks first and then returns to Sign
/// In.
///
/// A photo of hands sharing fruit fades into the backdrop behind the
/// avatar. Phones follow the Figma frame with the bottom navigation bar;
/// laptops get the side navigation rail, the volunteer's card on the left
/// and the menu on the right.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const String routeName = 'profile';

  static const String photo = 'assets/images/splash_giving.jpg';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final _photo = AssetPhoto(ProfileScreen.photo);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  double _rise(int n) {
    final start = (n * 0.065).clamp(0.0, 0.6);
    return Curves.easeOutCubic.transform(
      ((_intro.value - start) / 0.4).clamp(0.0, 1.0),
    );
  }

  /// How far the numbers have counted up (0–1).
  double get _count => Curves.easeOutCubic.transform(
    ((_intro.value - 0.25) / 0.75).clamp(0.0, 1.0),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _photo.resolve(context, () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _photo.dispose();
    super.dispose();
  }

  void _openTab(AppTab tab) => openAppTab(context, AppTab.profile, tab);

  void _open(Widget page) => Navigator.of(context).push(softRoute(page));

  void _openPastEvents() => Navigator.of(context).push(
    softRoute(
      const MyEventsScreen(showPast: true),
      name: MyEventsScreen.routeName,
    ),
  );

  Future<void> _logOut() async {
    HapticFeedback.selectionClick();
    final sure = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cancel',
      barrierColor: AppColors.ink.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, _, _) => const _LogOutDialog(),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (sure != true || !mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context)
        .pushAndRemoveUntil(softRoute(const SignInScreen()), (_) => false);
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
                VolunteerProfile.details,
                VolunteerProfile.interests,
                VolunteerProfile.availableForUrgent,
                CommunityFeed.posts,
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
                          focus: const Alignment(0, 0.2),
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
                      ..._identity(s, first: 1),
                      SizedBox(height: 24 * s),
                      RiseIn(
                        progress: _rise(4),
                        distance: 18 * s,
                        child: _stats(s),
                      ),
                      SizedBox(height: 18 * s),
                      RiseIn(
                        progress: _rise(5),
                        distance: 18 * s,
                        child: _LevelCard(time: _ambient.value, scale: s),
                      ),
                      SizedBox(height: 18 * s),
                      RiseIn(
                        progress: _rise(6),
                        distance: 18 * s,
                        child: _BadgesStrip(scale: s),
                      ),
                      SizedBox(height: 18 * s),
                      RiseIn(
                        progress: _rise(7),
                        distance: 18 * s,
                        child: _AvailabilityCard(
                          scale: s,
                          time: _ambient.value,
                        ),
                      ),
                      SizedBox(height: 14 * s),
                      RiseIn(
                        progress: _rise(8),
                        distance: 18 * s,
                        child: _menu(s, card: false),
                      ),
                      SizedBox(height: 18 * s),
                      RiseIn(
                        progress: _rise(9),
                        distance: 18 * s,
                        child: _LogOutButton(scale: s, onTap: _logOut),
                      ),
                      SizedBox(height: 14 * s),
                      _version(s),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        AppBottomBar(current: AppTab.profile, scale: s, onSelect: _openTab),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Laptop layout
  // ---------------------------------------------------------------------------

  Widget _buildWide(Size size, double s, double railWidth) {
    final mainWidth = math.min(size.width - railWidth, 1120 * s);
    return Row(
      children: [
        SizedBox(
          width: railWidth,
          child: AppSideRail(
            current: AppTab.profile,
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
                      SizedBox(height: 10 * s),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 11,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ..._identity(s, first: 1),
                                SizedBox(height: 24 * s),
                                RiseIn(
                                  progress: _rise(4),
                                  distance: 18 * s,
                                  child: _stats(s),
                                ),
                                SizedBox(height: 18 * s),
                                RiseIn(
                                  progress: _rise(5),
                                  distance: 18 * s,
                                  child: _LevelCard(
                                    time: _ambient.value,
                                    scale: s,
                                  ),
                                ),
                                SizedBox(height: 18 * s),
                                RiseIn(
                                  progress: _rise(6),
                                  distance: 18 * s,
                                  child: _BadgesStrip(scale: s),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 32 * s),
                          Expanded(
                            flex: 10,
                            child: Padding(
                              padding: EdgeInsets.only(top: 40 * s),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  RiseIn(
                                    progress: _rise(5),
                                    distance: 20 * s,
                                    child: _AvailabilityCard(
                                      scale: s,
                                      time: _ambient.value,
                                    ),
                                  ),
                                  SizedBox(height: 18 * s),
                                  RiseIn(
                                    progress: _rise(6),
                                    distance: 20 * s,
                                    child: _menu(s, card: true),
                                  ),
                                  SizedBox(height: 18 * s),
                                  RiseIn(
                                    progress: _rise(7),
                                    distance: 20 * s,
                                    child: _LogOutButton(
                                      scale: s,
                                      onTap: _logOut,
                                    ),
                                  ),
                                  SizedBox(height: 14 * s),
                                  _version(s),
                                ],
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

  /// Back, and a pencil to edit the profile.
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
        AuthIconButton(
          label: 'Edit profile',
          scale: s,
          onTap: () => _open(const PersonalInfoScreen()),
          child: Icon(Icons.edit_outlined, size: 19 * s, color: AppColors.ink),
        ),
      ],
    );
  }

  /// The avatar, name, role and level, and where they're based.
  List<Widget> _identity(double s, {required int first}) {
    final details = VolunteerProfile.details.value;
    final level = volunteerLevel();
    return [
      RiseIn(
        progress: _rise(first),
        distance: 16 * s,
        child: Center(
          child: _BigAvatar(
            time: _ambient.value,
            scale: s,
            onEdit: () =>
                showAuthNotice(context, 'Photo upload is coming soon.'),
          ),
        ),
      ),
      SizedBox(height: 16 * s),
      RiseIn(
        progress: _rise(first + 1),
        distance: 16 * s,
        child: Column(
          children: [
            Semantics(
              header: true,
              child: Text(
                details.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 27 * s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            SizedBox(height: 6 * s),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8 * s,
              runSpacing: 6 * s,
              children: [
                Text(
                  'Volunteer',
                  style: TextStyle(
                    fontSize: 16 * s,
                    color: AppColors.fieldIcon,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * s,
                    vertical: 4 * s,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.roleChosenFill,
                    borderRadius: BorderRadius.circular(12 * s),
                    border: Border.all(color: AppColors.roleChosenBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 14 * s,
                        color: AppColors.brand,
                      ),
                      SizedBox(width: 4 * s),
                      Flexible(
                        child: Text(
                          'Level ${level.level} · ${level.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5 * s,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      SizedBox(height: 10 * s),
      RiseIn(
        progress: _rise(first + 2),
        distance: 16 * s,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.place_outlined,
              size: 15 * s,
              color: AppColors.leafLight,
            ),
            SizedBox(width: 4 * s),
            Flexible(
              child: Text(
                '${details.city} · Volunteering since Mar 2025',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5 * s, color: AppColors.bodyText),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// Events, Hours and Certificates, as in the Figma, counting up.
  Widget _stats(double s) {
    final stats = [
      (
        pastVisits.length,
        'Events',
        Icons.event_available_rounded,
        _openPastEvents,
      ),
      (volunteerHours, 'Hours', Icons.schedule_rounded, _openPastEvents),
      (
        certificates.length,
        'Certificates',
        Icons.workspace_premium_rounded,
        () => _open(const CertificatesScreen()),
      ),
    ];
    return Row(
      children: [
        for (final (i, (value, label, icon, onTap)) in stats.indexed) ...[
          if (i > 0) SizedBox(width: 12 * s),
          Expanded(
            child: _StatTile(
              value: value,
              shown: (value * _count).round(),
              label: label,
              icon: icon,
              scale: s,
              onTap: onTap,
            ),
          ),
        ],
      ],
    );
  }

  /// The Figma's menu: Personal Information through Help & Support.
  Widget _menu(double s, {required bool card}) {
    final interests = VolunteerProfile.interests.value.length;
    final items = [
      (
        Icons.person_outline_rounded,
        'Personal Information',
        'Name, contact and emergency contact',
        () => _open(const PersonalInfoScreen()),
      ),
      (
        Icons.interests_outlined,
        'Interests',
        '$interests causes · days you’re free',
        () => _open(const InterestsScreen()),
      ),
      (
        Icons.card_membership_rounded,
        'Certificates',
        '${certificates.length} earned',
        () => _open(const CertificatesScreen()),
      ),
      (
        Icons.settings_outlined,
        'Settings',
        'Notifications, privacy and language',
        () => _open(const SettingsScreen()),
      ),
      (
        Icons.support_agent_rounded,
        'Help & Support',
        'Questions and ways to reach us',
        () => _open(const HelpScreen()),
      ),
    ];
    final list = Column(
      children: [
        for (final (i, (icon, label, hint, onTap)) in items.indexed) ...[
          Container(height: 1, color: AppColors.fieldBorder),
          _MenuRow(
            icon: icon,
            label: label,
            hint: hint,
            scale: s,
            onTap: onTap,
          ),
          if (i == items.length - 1 && !card)
            Container(height: 1, color: AppColors.fieldBorder),
        ],
      ],
    );
    if (!card) return list;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 4 * s),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.82),
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
      // The first line would sit on the card's edge.
      child: ClipRect(
        child: Transform.translate(offset: const Offset(0, -1), child: list),
      ),
    );
  }

  Widget _version(double s) => Text(
    'FoodLink 1.0 · Made with care in Kolkata',
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 12.5 * s, color: AppColors.fieldHint),
  );
}

/// The large avatar with a slowly turning ring and a camera badge.
class _BigAvatar extends StatelessWidget {
  const _BigAvatar({
    required this.time,
    required this.scale,
    required this.onEdit,
  });

  final double time;
  final double scale;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final d = 128 * s;
    return SizedBox.square(
      dimension: d + 16 * s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: time * 2 * math.pi,
            child: Container(
              width: d + 14 * s,
              height: d + 14 * s,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppColors.leafLight,
                    AppColors.sun,
                    AppColors.earthLight,
                    AppColors.brand,
                    AppColors.leafLight,
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: d + 6 * s,
            height: d + 6 * s,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
            ),
          ),
          Semantics(
            label: 'Profile photo',
            image: true,
            child: Container(
              width: d,
              height: d,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppColors.avatar,
                ),
              ),
              child: Icon(
                Icons.person_rounded,
                size: d * 0.62,
                color: const Color(0xFFF3E4D6),
              ),
            ),
          ),
          Positioned(
            right: 6 * s,
            bottom: 8 * s,
            child: Semantics(
              button: true,
              label: 'Change photo',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 36 * s,
                  height: 36 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brand,
                    border: Border.all(color: AppColors.white, width: 3),
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    size: 17 * s,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the Figma's three numbers, counting up; opens its page.
class _StatTile extends StatefulWidget {
  const _StatTile({
    required this.value,
    required this.shown,
    required this.label,
    required this.icon,
    required this.scale,
    required this.onTap,
  });

  final int value;
  final int shown;
  final String label;
  final IconData icon;
  final double scale;
  final VoidCallback onTap;

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Semantics(
      button: true,
      label: '${widget.value} ${widget.label}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 96 * s,
            transform: Matrix4.translationValues(0, _hovered ? -3 * s : 0, 0),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.white
                  : AppColors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(20 * s),
              border: Border.all(color: AppColors.white),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(
                    alpha: _hovered ? 0.14 : 0.06,
                  ),
                  blurRadius: 20 * s,
                  offset: Offset(0, 8 * s),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 17 * s, color: AppColors.leafLight),
                  SizedBox(height: 4 * s),
                  Text(
                    '${widget.shown}',
                    style: TextStyle(
                      fontSize: 26 * s,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 2 * s),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13.5 * s,
                      color: AppColors.bodyText,
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

/// The volunteer's level on deep green, with a bar filling towards the
/// next one.
class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.time, required this.scale});

  final double time;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final level = volunteerLevel();
    final hours = volunteerHours;
    final next = level.next;
    return Container(
      padding: EdgeInsets.all(18 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24 * s),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brand, AppColors.leafMid],
          stops: [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.28),
            blurRadius: 26 * s,
            spreadRadius: -6 * s,
            offset: Offset(0, 14 * s),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46 * s,
                height: 46 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.16),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '${level.level}',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 22 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 19 * s,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      next == null
                          ? 'The highest level. Thank you!'
                          : '${level.nextHours - hours} more hours to $next',
                      style: TextStyle(
                        fontSize: 13 * s,
                        color: AppColors.logoOnDark,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$hours/${level.nextHours} hrs',
                style: TextStyle(
                  fontSize: 13.5 * s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * s),
          Semantics(
            label: '${(level.progress * 100).round()} percent to $next',
            excludeSemantics: true,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: level.progress),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (context, fill, _) => Container(
                height: 10 * s,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(5 * s),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fill.clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5 * s),
                      gradient: const LinearGradient(
                        colors: [AppColors.sun, Color(0xFFF2CF7C)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sun.withValues(
                            alpha: 0.4 + 0.3 * math.sin(time * 2 * math.pi * 2),
                          ),
                          blurRadius: 10 * s,
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
    );
  }
}

/// Earned badges in colour and those still to earn in grey; tapping one
/// says how it's earned.
class _BadgesStrip extends StatelessWidget {
  const _BadgesStrip({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final badges = volunteerBadges();
    final earned = badges.where((badge) => badge.earned).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.eco_rounded, size: 18 * s, color: AppColors.leafLight),
            SizedBox(width: 8 * s),
            Expanded(
              child: Text(
                'Badges',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 19 * s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              '$earned of ${badges.length} earned',
              style: TextStyle(
                fontSize: 13 * s,
                fontWeight: FontWeight.w600,
                color: AppColors.fieldIcon,
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * s),
        SizedBox(
          height: 104 * s,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: badges.length,
            separatorBuilder: (_, _) => SizedBox(width: 12 * s),
            itemBuilder: (context, i) =>
                _BadgeMedal(badge: badges[i], index: i, scale: s),
          ),
        ),
      ],
    );
  }
}

class _BadgeMedal extends StatelessWidget {
  const _BadgeMedal({
    required this.badge,
    required this.index,
    required this.scale,
  });

  final VolunteerBadge badge;
  final int index;
  final double scale;

  void _explain(BuildContext context) {
    HapticFeedback.selectionClick();
    showAuthNotice(
      context,
      badge.earned
          ? '${badge.name}: earned! ${badge.how}.'
          : '${badge.name}: ${badge.how} to earn this badge.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final earned = badge.earned;
    return Semantics(
      button: true,
      label: '${badge.name}${earned ? ', earned' : ', not earned yet'}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _explain(context),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 600 + index * 90),
          curve: Curves.easeOutBack,
          builder: (context, pop, child) =>
              Transform.scale(scale: pop.clamp(0.0, 1.2), child: child),
          child: SizedBox(
            width: 76 * s,
            child: Column(
              children: [
                Container(
                  width: 62 * s,
                  height: 62 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: earned
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(badge.color, AppColors.white, 0.35)!,
                              badge.color,
                            ],
                          )
                        : null,
                    color: earned ? null : AppColors.socialFill,
                    border: Border.all(
                      color: earned ? AppColors.white : AppColors.fieldBorder,
                      width: 3,
                    ),
                    boxShadow: [
                      if (earned)
                        BoxShadow(
                          color: badge.color.withValues(alpha: 0.35),
                          blurRadius: 12 * s,
                          offset: Offset(0, 5 * s),
                        ),
                    ],
                  ),
                  child: Icon(
                    earned ? badge.icon : Icons.lock_outline_rounded,
                    size: 26 * s,
                    color: earned ? AppColors.white : AppColors.fieldHint,
                  ),
                ),
                SizedBox(height: 8 * s),
                Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 11.5 * s,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: earned ? AppColors.ink : AppColors.fieldHint,
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

/// "Available for urgent calls", with a switch and a pulsing dot when on.
class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.scale, required this.time});

  final double scale;
  final double time;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final on = VolunteerProfile.availableForUrgent.value;
    final pulse = (time * 4) % 1.0;
    void toggle(bool value) {
      HapticFeedback.selectionClick();
      VolunteerProfile.availableForUrgent.value = value;
    }

    return Semantics(
      toggled: on,
      label: 'Available for urgent calls',
      excludeSemantics: true,
      onTap: () => toggle(!on),
      child: GestureDetector(
        onTap: () => toggle(!on),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 8 * s, 12 * s),
          decoration: BoxDecoration(
            color: on
                ? AppColors.roleChosenFill
                : AppColors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20 * s),
            border: Border.all(
              color: on ? AppColors.roleChosenBorder : AppColors.fieldBorder,
            ),
          ),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 40 * s,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (on)
                      Container(
                        width: 40 * s * (0.6 + 0.4 * pulse),
                        height: 40 * s * (0.6 + 0.4 * pulse),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.leafLight.withValues(
                            alpha: 0.35 * (1 - pulse),
                          ),
                        ),
                      ),
                    Container(
                      width: 30 * s,
                      height: 30 * s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on ? AppColors.brand : AppColors.socialFill,
                      ),
                      child: Icon(
                        Icons.bolt_rounded,
                        size: 18 * s,
                        color: on ? AppColors.white : AppColors.fieldIcon,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available for urgent calls',
                      style: TextStyle(
                        fontSize: 15.5 * s,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 2 * s),
                    Text(
                      on
                          ? 'Organisers can ask you to fill a last-minute gap'
                          : 'You won’t get last-minute requests',
                      style: TextStyle(
                        fontSize: 12.5 * s,
                        color: AppColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: s.clamp(0.8, 1.1),
                child: Switch(
                  value: on,
                  onChanged: toggle,
                  activeThumbColor: AppColors.white,
                  activeTrackColor: AppColors.brand,
                  inactiveThumbColor: AppColors.white,
                  inactiveTrackColor: AppColors.stepTodo,
                  trackOutlineColor: const WidgetStatePropertyAll(
                    Colors.transparent,
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

/// One row of the Figma's menu: icon, label (with a hint below) and a
/// chevron that nudges on hover.
class _MenuRow extends StatefulWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.hint,
    required this.scale,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final double scale;
  final VoidCallback onTap;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Semantics(
      button: true,
      label: widget.label,
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
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(vertical: 14 * s, horizontal: 4 * s),
            color: _pressed
                ? AppColors.roleChosenFill.withValues(alpha: 0.6)
                : AppColors.white.withValues(alpha: 0),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42 * s,
                  height: 42 * s,
                  decoration: BoxDecoration(
                    color: _hovered
                        ? AppColors.roleChosenFill
                        : AppColors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(13 * s),
                  ),
                  child: Icon(widget.icon, size: 22 * s, color: AppColors.ink),
                ),
                SizedBox(width: 16 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 16.5 * s,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 2 * s),
                      Text(
                        widget.hint,
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
                AnimatedSlide(
                  offset: Offset(_hovered ? 0.3 : 0, 0),
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 26 * s,
                    color: _hovered ? AppColors.brand : AppColors.fieldIcon,
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

/// The Figma's pale red Log Out pill.
class _LogOutButton extends StatefulWidget {
  const _LogOutButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  State<_LogOutButton> createState() => _LogOutButtonState();
}

class _LogOutButtonState extends State<_LogOutButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Semantics(
      button: true,
      label: 'Log Out',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 60 * s,
              decoration: BoxDecoration(
                color: _hovered
                    ? const Color(0xFFF8DEDA)
                    : const Color(0xFFFBEAE7),
                borderRadius: BorderRadius.circular(20 * s),
                border: Border.all(
                  color: _hovered
                      ? AppColors.badgeRing
                      : const Color(0xFFF8DEDA),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 21 * s,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 10 * s),
                  Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 17 * s,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
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

/// "Log out of FoodLink?" with Cancel and Log Out.
class _LogOutDialog extends StatelessWidget {
  const _LogOutDialog();

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFBEAE7),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 30,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Log out of FoodLink?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your events and hours are saved. Sign in again any time to '
                'pick up where you left off.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 14.5,
                  height: 1.5,
                  color: AppColors.bodyText,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: 'Cancel',
                      fill: AppColors.socialFill,
                      ink: AppColors.ink,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogButton(
                      label: 'Log Out',
                      fill: AppColors.error,
                      ink: AppColors.white,
                      onTap: () => Navigator.of(context).pop(true),
                    ),
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

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.fill,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final Color fill;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label button',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
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
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
