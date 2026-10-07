import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/my_events.dart';
import '../data/volunteer_profile.dart';
import '../navigation/tab_navigation.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/app_nav.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/primary_button.dart';
import '../widgets/rise_in.dart';
import '../widgets/soft_backdrop.dart';

/// The pages behind the Profile menu: Personal Information, Interests,
/// Certificates, Settings and Help & Support.

/// Shared frame for a profile page: the soft backdrop, Back, a title and
/// subtitle, then [children] rising in one after another, with an optional
/// [action] pinned at the bottom on phones (and at the end on laptops).
///
/// Laptops keep the side navigation rail with Profile highlighted.
class ProfilePageScaffold extends StatefulWidget {
  const ProfilePageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.action,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> Function(double scale, bool wide) children;
  final Widget Function(double scale)? action;

  @override
  State<ProfilePageScaffold> createState() => _ProfilePageScaffoldState();
}

class _ProfilePageScaffoldState extends State<ProfilePageScaffold>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  double _rise(int n) {
    final start = (n * 0.06).clamp(0.0, 0.6);
    return Curves.easeOutCubic.transform(
      ((_intro.value - start) / 0.4).clamp(0.0, 1.0),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backdrop.first,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        excludeFromSemantics: true,
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
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
            return AnimatedBuilder(
              animation: _intro,
              builder: (context, _) => Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _ambient,
                      builder: (context, _) => CustomPaint(
                        painter: SoftBackdropPainter(time: _ambient.value),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(painter: DotTexturePainter()),
                    ),
                  ),
                  Positioned.fill(
                    child: wide ? _wide(size, s) : _compact(size, s),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _body(double s, bool wide) {
    var n = 1;
    return [
      RiseIn(progress: _rise(0), distance: -10 * s, child: _header(s, wide)),
      SizedBox(height: 22 * s),
      for (final child in widget.children(s, wide))
        RiseIn(progress: _rise(n++), distance: 18 * s, child: child),
    ];
  }

  Widget _header(double s, bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
            Container(
              width: 44 * s,
              height: 44 * s,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.roleChosenFill,
                    AppColors.roleChosenCircle,
                  ],
                ),
              ),
              child: Icon(widget.icon, size: 22 * s, color: AppColors.brand),
            ),
          ],
        ),
        SizedBox(height: 18 * s),
        Semantics(
          header: true,
          child: Text(
            widget.title,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: (wide ? 44 : 34) * s,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        SizedBox(height: 6 * s),
        Text(
          widget.subtitle,
          style: TextStyle(fontSize: 15.5 * s, color: AppColors.bodyText),
        ),
      ],
    );
  }

  Widget _compact(Size size, double s) {
    final width = math.min(size.width, 560 * s) - 48 * s;
    final action = widget.action;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24 * s, 14 * s, 24 * s, 28 * s),
              child: Center(
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _body(s, false),
                  ),
                ),
              ),
            ),
          ),
          if (action != null)
            Container(
              padding: EdgeInsets.fromLTRB(24 * s, 12 * s, 24 * s, 0),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.92),
                border: const Border(
                  top: BorderSide(color: AppColors.fieldBorder),
                ),
              ),
              child: SafeArea(
                top: false,
                minimum: EdgeInsets.only(bottom: 14 * s),
                child: Center(
                  child: SizedBox(
                    width: width,
                    child: RiseIn(
                      progress: _rise(3),
                      distance: 30 * s,
                      child: action(s),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _wide(Size size, double s) {
    final railWidth = 224 * s;
    final action = widget.action;
    return Row(
      children: [
        SizedBox(
          width: railWidth,
          child: AppSideRail(
            current: AppTab.profile,
            scale: s,
            onSelect: (tab) => openAppTab(context, null, tab),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 30 * s, horizontal: 48 * s),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 760 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._body(s, true),
                    if (action != null) ...[
                      SizedBox(height: 24 * s),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(width: 360 * s, child: action(s)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Frosted white card for a group on a profile page.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.scale,
    required this.child,
    this.title,
    this.icon,
  });

  final double scale;
  final String? title;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.all(18 * s),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title case final title?) ...[
            Row(
              children: [
                Icon(
                  icon ?? Icons.eco_rounded,
                  size: 18 * s,
                  color: AppColors.leafLight,
                ),
                SizedBox(width: 8 * s),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 18 * s,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14 * s),
          ],
          child,
        ],
      ),
    );
  }
}

Widget _fieldLabel(String text, double s) => Padding(
  padding: EdgeInsets.only(bottom: 8 * s, left: 4 * s),
  child: Text(
    text,
    style: TextStyle(
      fontSize: 14.5 * s,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
  ),
);

// -----------------------------------------------------------------------------
// Personal Information
// -----------------------------------------------------------------------------

/// Edit name, contact details, a short bio and an emergency contact. Save
/// checks the name, email and phone first.
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _start = VolunteerProfile.details.value;
  late final _name = TextEditingController(text: _start.name);
  late final _email = TextEditingController(text: _start.email);
  late final _phone = TextEditingController(text: _start.phone);
  late final _city = TextEditingController(text: _start.city);
  late final _bio = TextEditingController(text: _start.bio);
  late final _emergencyName = TextEditingController(text: _start.emergencyName);
  late final _emergencyPhone = TextEditingController(
    text: _start.emergencyPhone,
  );
  bool _tried = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _city,
      _bio,
      _emergencyName,
      _emergencyPhone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? get _nameError =>
      _name.text.trim().length < 2 ? 'Please enter your name' : null;

  String? get _emailError =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())
      ? null
      : 'Please enter a valid email';

  String? get _phoneError =>
      _phone.text.replaceAll(RegExp(r'\D'), '').length < 10
      ? 'Please enter a valid phone number'
      : null;

  void _save() {
    setState(() => _tried = true);
    if (_nameError != null || _emailError != null || _phoneError != null) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    VolunteerProfile.details.value = ProfileDetails(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      city: _city.text.trim().isEmpty ? _start.city : _city.text.trim(),
      bio: _bio.text.trim(),
      emergencyName: _emergencyName.text.trim(),
      emergencyPhone: _emergencyPhone.text.trim(),
    );
    showAuthNotice(context, 'Your details are saved.');
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return ProfilePageScaffold(
      title: 'Personal Information',
      subtitle: 'Organisers of events you join will see these details.',
      icon: Icons.person_outline_rounded,
      action: (s) => PrimaryButton(
        label: 'Save Changes',
        scale: s * 0.9,
        onPressed: _save,
      ),
      children: (s, wide) {
        Widget field(
          String label,
          TextEditingController controller,
          IconData icon, {
          String? error,
          TextInputType? keyboard,
          TextCapitalization caps = TextCapitalization.none,
        }) => Padding(
          padding: EdgeInsets.only(bottom: 14 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fieldLabel(label, s),
              AuthField(
                controller: controller,
                hint: label,
                icon: icon,
                scale: s,
                keyboardType: keyboard,
                textCapitalization: caps,
                errorText: _tried ? error : null,
                onChanged: (_) {
                  if (_tried) setState(() {});
                },
              ),
            ],
          ),
        );
        return [
          ProfileCard(
            scale: s,
            title: 'About you',
            icon: Icons.badge_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                field(
                  'Full name',
                  _name,
                  Icons.person_outline_rounded,
                  error: _nameError,
                  caps: TextCapitalization.words,
                ),
                field(
                  'Email',
                  _email,
                  Icons.mail_outline_rounded,
                  error: _emailError,
                  keyboard: TextInputType.emailAddress,
                ),
                field(
                  'Phone',
                  _phone,
                  Icons.phone_outlined,
                  error: _phoneError,
                  keyboard: TextInputType.phone,
                ),
                field(
                  'City',
                  _city,
                  Icons.location_city_outlined,
                  caps: TextCapitalization.words,
                ),
                _fieldLabel('A little about you', s),
                Container(
                  padding: EdgeInsets.all(16 * s),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16 * s),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: TextField(
                    controller: _bio,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [LengthLimitingTextInputFormatter(160)],
                    cursorColor: AppColors.brand,
                    style: TextStyle(
                      fontSize: 15.5 * s,
                      height: 1.45,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration.collapsed(
                      hintText: 'What brings you to volunteering?',
                      hintStyle: TextStyle(
                        fontSize: 15.5 * s,
                        color: AppColors.fieldHint,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18 * s),
          ProfileCard(
            scale: s,
            title: 'Emergency contact',
            icon: Icons.health_and_safety_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                field(
                  'Contact name',
                  _emergencyName,
                  Icons.person_outline_rounded,
                  caps: TextCapitalization.words,
                ),
                field(
                  'Contact phone',
                  _emergencyPhone,
                  Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 15 * s,
                      color: AppColors.fieldIcon,
                    ),
                    SizedBox(width: 6 * s),
                    Expanded(
                      child: Text(
                        'Only used if something happens during an event.',
                        style: TextStyle(
                          fontSize: 12.5 * s,
                          color: AppColors.fieldIcon,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ];
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Interests
// -----------------------------------------------------------------------------

/// Causes the volunteer cares about, skills they can offer, and when they're
/// usually free. Suggestions on Home and Explore will follow these.
class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  late final Set<String> _interests = {...VolunteerProfile.interests.value};
  late final Set<String> _skills = {...VolunteerProfile.skills.value};
  late final Set<String> _days = {...VolunteerProfile.days.value};
  late String _time = VolunteerProfile.timeOfDay.value;

  void _toggle(Set<String> set, String value) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!set.remove(value)) set.add(value);
    });
  }

  void _save() {
    if (_interests.isEmpty) {
      showAuthNotice(context, 'Pick at least one cause you care about.');
      return;
    }
    HapticFeedback.mediumImpact();
    VolunteerProfile.interests.value = {..._interests};
    VolunteerProfile.skills.value = {..._skills};
    VolunteerProfile.days.value = {..._days};
    VolunteerProfile.timeOfDay.value = _time;
    showAuthNotice(context, 'Your interests are saved.');
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return ProfilePageScaffold(
      title: 'Interests',
      subtitle:
          'We’ll suggest events that match what you love and when '
          'you’re free.',
      icon: Icons.interests_outlined,
      action: (s) => PrimaryButton(
        label: 'Save Interests',
        scale: s * 0.9,
        onPressed: _save,
      ),
      children: (s, wide) => [
        ProfileCard(
          scale: s,
          title: 'Causes you care about',
          icon: Icons.favorite_border_rounded,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = wide ? 4 : 2;
              final gap = 10 * s;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final (name, icon) in interestOptions)
                    SizedBox(
                      width: width,
                      child: _InterestTile(
                        label: name,
                        icon: icon,
                        selected: _interests.contains(name),
                        scale: s,
                        onTap: () => _toggle(_interests, name),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: 18 * s),
        ProfileCard(
          scale: s,
          title: 'Skills you can offer',
          icon: Icons.handyman_outlined,
          child: Wrap(
            spacing: 8 * s,
            runSpacing: 8 * s,
            children: [
              for (final skill in skillOptions)
                _Pill(
                  label: skill,
                  selected: _skills.contains(skill),
                  scale: s,
                  onTap: () => _toggle(_skills, skill),
                ),
            ],
          ),
        ),
        SizedBox(height: 18 * s),
        ProfileCard(
          scale: s,
          title: 'When you’re free',
          icon: Icons.calendar_month_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (final (i, day) in weekDays.indexed) ...[
                    if (i > 0) SizedBox(width: 6 * s),
                    Expanded(
                      child: _DayDot(
                        label: day,
                        selected: _days.contains(day),
                        scale: s,
                        onTap: () => _toggle(_days, day),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 16 * s),
              Wrap(
                spacing: 8 * s,
                runSpacing: 8 * s,
                children: [
                  for (final time in timesOfDay)
                    _Pill(
                      label: time,
                      selected: time == _time,
                      scale: s,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _time = time);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InterestTile extends StatelessWidget {
  const _InterestTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 92 * s,
            padding: EdgeInsets.all(12 * s),
            decoration: BoxDecoration(
              color: selected ? AppColors.roleChosenFill : AppColors.white,
              borderRadius: BorderRadius.circular(18 * s),
              border: Border.all(
                color: selected ? AppColors.brand : AppColors.fieldBorder,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      icon,
                      size: 26 * s,
                      color: selected ? AppColors.brand : AppColors.fieldIcon,
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14 * s,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 22 * s,
                      height: 22 * s,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brand,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 14 * s,
                        color: AppColors.white,
                      ),
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 9 * s),
            decoration: BoxDecoration(
              color: selected ? AppColors.brand : AppColors.white,
              borderRadius: BorderRadius.circular(20 * s),
              border: Border.all(
                color: selected ? AppColors.brand : AppColors.fieldBorder,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14 * s,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.label,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.brand : AppColors.white,
              border: Border.all(
                color: selected ? AppColors.brand : AppColors.fieldBorder,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.all(4 * s),
                child: Text(
                  label.substring(0, 2),
                  style: TextStyle(
                    fontSize: 13 * s,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.white : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Certificates
// -----------------------------------------------------------------------------

/// Every certificate the volunteer has earned, styled like the paper ones,
/// with Share and Download.
class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = certificates;
    final hours = list.fold(0, (sum, visit) => sum + visit.hours);
    return ProfilePageScaffold(
      title: 'Certificates',
      subtitle:
          '${list.length} certificates for $hours hours of learning and '
          'giving.',
      icon: Icons.card_membership_rounded,
      children: (s, wide) => [
        if (list.isEmpty)
          ProfileCard(
            scale: s,
            child: Text(
              'Workshops and larger drives give certificates. Yours will '
              'appear here.',
              style: TextStyle(fontSize: 15 * s, color: AppColors.bodyText),
            ),
          ),
        for (final visit in list)
          Padding(
            padding: EdgeInsets.only(bottom: 16 * s),
            child: _CertificateCard(visit: visit, scale: s),
          ),
      ],
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.visit, required this.scale});

  final PastVisit visit;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final event = visit.event;
    final name = VolunteerProfile.details.value.name;
    return Container(
      padding: EdgeInsets.all(7 * s),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: AppColors.earthLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.earthDark.withValues(alpha: 0.1),
            blurRadius: 20 * s,
            offset: Offset(0, 8 * s),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(18 * s, 18 * s, 18 * s, 12 * s),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF5),
          borderRadius: BorderRadius.circular(16 * s),
          border: Border.all(
            color: AppColors.earthLight.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42 * s,
                  height: 42 * s,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFF2CF7C), AppColors.sun],
                    ),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 23 * s,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Text(
                    'CERTIFICATE OF PARTICIPATION',
                    style: TextStyle(
                      fontSize: 11.5 * s,
                      letterSpacing: 1.4 * s,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tagFoodText,
                    ),
                  ),
                ),
                Icon(
                  Icons.eco_rounded,
                  size: 20 * s,
                  color: AppColors.leafLight,
                ),
              ],
            ),
            SizedBox(height: 14 * s),
            Text(
              'Presented to $name for taking part in',
              style: TextStyle(fontSize: 13 * s, color: AppColors.fieldIcon),
            ),
            SizedBox(height: 4 * s),
            Text(
              event.title,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 21 * s,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 6 * s),
            Text(
              '${event.date} · ${visit.hours} hours · ${visit.role}',
              style: TextStyle(fontSize: 13 * s, color: AppColors.bodyText),
            ),
            SizedBox(height: 4 * s),
            Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 15 * s,
                  color: AppColors.brand,
                ),
                SizedBox(width: 5 * s),
                Expanded(
                  child: Text(
                    'Issued by ${event.organiser}',
                    style: TextStyle(
                      fontSize: 13 * s,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10 * s),
            Container(
              height: 1,
              color: AppColors.earthLight.withValues(alpha: 0.4),
            ),
            SizedBox(height: 4 * s),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _TextAction(
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  scale: s,
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            'https://foodlink.app/certificates/'
                            '${event.title.toLowerCase().replaceAll(' ', '-')}',
                      ),
                    );
                    showAuthNotice(context, 'Certificate link copied.');
                  },
                ),
                SizedBox(width: 8 * s),
                _TextAction(
                  icon: Icons.download_rounded,
                  label: 'Download',
                  scale: s,
                  onTap: () =>
                      showAuthNotice(context, 'PDF downloads are coming soon.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.icon,
    required this.label,
    required this.scale,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 8 * s),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17 * s, color: AppColors.brand),
                SizedBox(width: 5 * s),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
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

// -----------------------------------------------------------------------------
// Settings
// -----------------------------------------------------------------------------

/// Notifications, privacy, how far to look for events, and language.
/// Changes save straight away.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _languages = ['English', 'Bengali', 'Hindi'];

  void _update(ProfileSettings settings) {
    HapticFeedback.selectionClick();
    VolunteerProfile.settings.value = settings;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: VolunteerProfile.settings,
      builder: (context, settings, _) => ProfilePageScaffold(
        title: 'Settings',
        subtitle: 'Changes are saved as you make them.',
        icon: Icons.settings_outlined,
        children: (s, wide) => [
          ProfileCard(
            scale: s,
            title: 'Notifications',
            icon: Icons.notifications_none_rounded,
            child: Column(
              children: [
                _SwitchRow(
                  label: 'Event reminders',
                  hint: 'The day before each event you’ve joined',
                  value: settings.eventReminders,
                  scale: s,
                  onChanged: (v) =>
                      _update(settings.copyWith(eventReminders: v)),
                ),
                _SwitchRow(
                  label: 'New events near you',
                  hint: 'When an event matching your interests opens',
                  value: settings.newEventsNearby,
                  scale: s,
                  onChanged: (v) =>
                      _update(settings.copyWith(newEventsNearby: v)),
                ),
                _SwitchRow(
                  label: 'Community activity',
                  hint: 'Likes and comments on your posts',
                  value: settings.communityActivity,
                  scale: s,
                  onChanged: (v) =>
                      _update(settings.copyWith(communityActivity: v)),
                ),
                _SwitchRow(
                  label: 'Weekly summary',
                  hint: 'Your hours and impact every Sunday',
                  value: settings.weeklySummary,
                  scale: s,
                  last: true,
                  onChanged: (v) =>
                      _update(settings.copyWith(weeklySummary: v)),
                ),
              ],
            ),
          ),
          SizedBox(height: 18 * s),
          ProfileCard(
            scale: s,
            title: 'Privacy',
            icon: Icons.shield_outlined,
            child: Column(
              children: [
                _SwitchRow(
                  label: 'Show me on leaderboards',
                  hint: 'Appear in Community’s top volunteers',
                  value: settings.showOnLeaderboard,
                  scale: s,
                  onChanged: (v) =>
                      _update(settings.copyWith(showOnLeaderboard: v)),
                ),
                _SwitchRow(
                  label: 'Share my hours with organisers',
                  hint: 'Helps them invite experienced volunteers',
                  value: settings.shareHoursWithOrganisers,
                  scale: s,
                  last: true,
                  onChanged: (v) =>
                      _update(settings.copyWith(shareHoursWithOrganisers: v)),
                ),
              ],
            ),
          ),
          SizedBox(height: 18 * s),
          ProfileCard(
            scale: s,
            title: 'Event distance',
            icon: Icons.near_me_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Suggest events within',
                        style: TextStyle(
                          fontSize: 15 * s,
                          color: AppColors.bodyText,
                        ),
                      ),
                    ),
                    Text(
                      '${settings.distanceKm.round()} km',
                      style: TextStyle(
                        fontSize: 16 * s,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.brand,
                    inactiveTrackColor: AppColors.stepTodo,
                    thumbColor: AppColors.brand,
                    overlayColor: AppColors.brand.withValues(alpha: 0.12),
                    trackHeight: 5,
                  ),
                  child: Slider(
                    value: settings.distanceKm,
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: '${settings.distanceKm.round()} km',
                    semanticFormatterCallback: (v) => '${v.round()} km',
                    onChanged: (v) => VolunteerProfile.settings.value = settings
                        .copyWith(distanceKm: v),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18 * s),
          ProfileCard(
            scale: s,
            title: 'Language',
            icon: Icons.translate_rounded,
            child: Wrap(
              spacing: 8 * s,
              runSpacing: 8 * s,
              children: [
                for (final language in _languages)
                  _Pill(
                    label: language,
                    selected: language == settings.language,
                    scale: s,
                    onTap: () => _update(settings.copyWith(language: language)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.scale,
    required this.onChanged,
    this.last = false,
  });

  final String label;
  final String hint;
  final bool value;
  final double scale;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      toggled: value,
      label: label,
      excludeSemantics: true,
      onTap: () => onChanged(!value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8 * s),
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(
                    bottom: BorderSide(color: AppColors.fieldBorder),
                  ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15.5 * s,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 2 * s),
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: 12.5 * s,
                        color: AppColors.fieldIcon,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: s.clamp(0.8, 1.1),
                child: Switch(
                  value: value,
                  onChanged: onChanged,
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

// -----------------------------------------------------------------------------
// Help & Support
// -----------------------------------------------------------------------------

/// Common questions that open in place, and ways to reach the FoodLink team.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _open;

  void _copy(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    showAuthNotice(context, '$what copied.');
  }

  @override
  Widget build(BuildContext context) {
    return ProfilePageScaffold(
      title: 'Help & Support',
      subtitle: 'Answers to common questions, and a team happy to help.',
      icon: Icons.support_agent_rounded,
      children: (s, wide) => [
        ProfileCard(
          scale: s,
          title: 'Common questions',
          icon: Icons.help_outline_rounded,
          child: Column(
            children: [
              for (final (i, (question, answer)) in helpTopics.indexed)
                _Question(
                  question: question,
                  answer: answer,
                  open: _open == i,
                  last: i == helpTopics.length - 1,
                  scale: s,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _open = _open == i ? null : i);
                  },
                ),
            ],
          ),
        ),
        SizedBox(height: 18 * s),
        ProfileCard(
          scale: s,
          title: 'Contact us',
          icon: Icons.forum_outlined,
          child: Column(
            children: [
              _ContactRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: 'help@foodlink.org',
                scale: s,
                onTap: () => _copy('help@foodlink.org', 'Email address'),
              ),
              SizedBox(height: 10 * s),
              _ContactRow(
                icon: Icons.phone_outlined,
                label: 'Call us (10 AM – 6 PM)',
                value: '+91 33 4000 1234',
                scale: s,
                onTap: () => _copy('+91 33 4000 1234', 'Phone number'),
              ),
              SizedBox(height: 10 * s),
              _ContactRow(
                icon: Icons.bug_report_outlined,
                label: 'Something not working?',
                value: 'Report a problem',
                scale: s,
                onTap: () => showAuthNotice(
                  context,
                  'Thanks! Problem reports are coming soon. Email us for now.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.question,
    required this.answer,
    required this.open,
    required this.last,
    required this.scale,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool open;
  final bool last;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.fieldBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            label: question,
            excludeSemantics: true,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14 * s),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          question,
                          style: TextStyle(
                            fontSize: 15.5 * s,
                            fontWeight: FontWeight.w600,
                            color: open ? AppColors.brand : AppColors.ink,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 24 * s,
                          color: open ? AppColors.brand : AppColors.fieldIcon,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: EdgeInsets.only(bottom: 14 * s),
                    child: Text(
                      answer,
                      style: TextStyle(
                        fontSize: 14.5 * s,
                        height: 1.55,
                        color: AppColors.bodyText,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.scale,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      button: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(12 * s),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16 * s),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 40 * s,
                  height: 40 * s,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.roleChosenFill,
                  ),
                  child: Icon(icon, size: 20 * s, color: AppColors.brand),
                ),
                SizedBox(width: 12 * s),
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
                      SizedBox(height: 2 * s),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15.5 * s,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22 * s,
                  color: AppColors.fieldIcon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
