import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/coordinator.dart';
import '../../navigation/transitions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/app_nav.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/coordinator_page.dart';
import '../../widgets/primary_button.dart';
import '../sign_in_screen.dart';
import '../volunteer_home_screen.dart';

/// The coordinator's profile, as in the Figma: their photo, name and role,
/// then Organization Details, Team Management, Settings and Help & Support,
/// and Log Out (which asks first, then returns to Sign In).
///
/// A photo of a community farm fades into the backdrop behind the avatar.
class CoordinatorProfileScreen extends StatelessWidget {
  const CoordinatorProfileScreen({
    super.key,
    this.name = 'Agnibha Bhattacharya',
  });

  static const String routeName = 'coordinator-profile';

  final String name;

  Future<void> _logOut(BuildContext context) async {
    HapticFeedback.selectionClick();
    final sure = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.42),
      builder: (_) => const _LogOutDialog(),
    );
    if (sure != true || !context.mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context)
        .pushAndRemoveUntil(softRoute(const SignInScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    void open(Widget page) => Navigator.of(context).push(softRoute(page));
    return CoordinatorPage(
      tab: CoordinatorTab.profile,
      title: 'Profile',
      centerTitle: true,
      photo: 'assets/images/notifications_community_farm.jpg',
      maxWidth: 640,
      listenTo: Listenable.merge([
        CoordinatorBoard.organisation,
        CoordinatorBoard.team,
      ]),
      body: (context, c) {
        final s = c.scale;
        final org = CoordinatorBoard.organisation.value;
        return [
          Center(
            child: _BigAvatar(scale: s, time: c.time),
          ),
          SizedBox(height: 14 * s),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 25 * s,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 4 * s),
          Text(
            'Coordinator · ${org.name}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15 * s, color: AppColors.fieldIcon),
          ),
          SizedBox(height: 18 * s),
          Row(
            children: [
              for (final (i, (value, label)) in [
                ('${CoordinatorBoard.active.length}', 'Active events'),
                ('${volunteerContacts.length}', 'Volunteers'),
                ('${CoordinatorBoard.team.value.length}', 'Team'),
              ].indexed) ...[
                if (i > 0) SizedBox(width: 10 * s),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12 * s),
                    decoration: BoxDecoration(
                      color: AppColors.roleChosenFill.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(18 * s),
                    ),
                    child: Column(
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 21 * s,
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
              ],
            ],
          ),
          SizedBox(height: 16 * s),
          _OrgBanner(
            organisation: org,
            scale: s,
            onTap: () => open(const OrganizationDetailsScreen()),
          ),
          SizedBox(height: 18 * s),
          _Achievements(scale: s),
          SizedBox(height: 10 * s),
          for (final (icon, label, hint, page) in [
            (
              Icons.badge_outlined,
              'Organization Details',
              org.name,
              const OrganizationDetailsScreen() as Widget,
            ),
            (
              Icons.groups_outlined,
              'Team Management',
              '${CoordinatorBoard.team.value.length} members',
              const TeamManagementScreen(),
            ),
            (
              Icons.settings_outlined,
              'Settings',
              'Approvals, alerts and reports',
              const CoordinatorSettingsScreen(),
            ),
            (
              Icons.support_agent_rounded,
              'Help & Support',
              'Guides for coordinators',
              const CoordinatorHelpScreen(),
            ),
          ]) ...[
            rowDivider(),
            TappableRow(
              label: label,
              scale: s,
              onTap: () => open(page),
              child: Row(
                children: [
                  Container(
                    width: 42 * s,
                    height: 42 * s,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(13 * s),
                    ),
                    child: Icon(icon, size: 22 * s, color: AppColors.ink),
                  ),
                  SizedBox(width: 16 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 16.5 * s,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          hint,
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
                ],
              ),
            ),
          ],
          rowDivider(),
          TappableRow(
            label: 'Switch to Volunteer View',
            scale: s,
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              softRoute(
                VolunteerHomeScreen(name: name.split(' ').first),
                name: VolunteerHomeScreen.routeName,
              ),
              (_) => false,
            ),
            child: Row(
              children: [
                Container(
                  width: 42 * s,
                  height: 42 * s,
                  decoration: BoxDecoration(
                    color: AppColors.roleChosenFill,
                    borderRadius: BorderRadius.circular(13 * s),
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 22 * s,
                    color: AppColors.brand,
                  ),
                ),
                SizedBox(width: 16 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Switch to Volunteer View',
                        style: TextStyle(
                          fontSize: 16.5 * s,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brand,
                        ),
                      ),
                      Text(
                        'Join events yourself as a volunteer',
                        style: TextStyle(
                          fontSize: 12.5 * s,
                          color: AppColors.fieldIcon,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          rowDivider(),
          SizedBox(height: 26 * s),
          _LogOutButton(scale: s, onTap: () => _logOut(context)),
        ];
      },
    );
  }
}

/// The large avatar with a slowly turning green ring.
class _BigAvatar extends StatelessWidget {
  const _BigAvatar({required this.scale, required this.time});

  final double scale;
  final double time;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final d = 116 * s;
    return SizedBox.square(
      dimension: d + 14 * s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: time * 2 * math.pi,
            child: Container(
              width: d + 12 * s,
              height: d + 12 * s,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppColors.leafLight,
                    AppColors.brand,
                    AppColors.roleChosenBorder,
                    AppColors.leafLight,
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: d + 5 * s,
            height: d + 5 * s,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
            ),
          ),
          InitialsAvatar(
            initials: '',
            colors: AppColors.avatar,
            size: d,
            person: true,
          ),
          Positioned(
            right: 4 * s,
            bottom: 6 * s,
            child: Container(
              width: 32 * s,
              height: 32 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brand,
                border: Border.all(color: AppColors.white, width: 3),
              ),
              child: Icon(
                Icons.assignment_ind_rounded,
                size: 15 * s,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Figma's pale red Log Out pill.
class _LogOutButton extends StatelessWidget {
  const _LogOutButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      button: true,
      label: 'Log Out',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 58 * s,
            decoration: BoxDecoration(
              color: const Color(0xFFFBEAE7),
              borderRadius: BorderRadius.circular(18 * s),
              border: Border.all(color: const Color(0xFFF8DEDA)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 20 * s,
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
    );
  }
}

class _LogOutDialog extends StatelessWidget {
  const _LogOutDialog();

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
                fontSize: 16,
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
                'Your events, volunteers and reports are saved. Sign in '
                'again any time to pick up where you left off.',
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
                  button('Cancel', AppColors.socialFill, AppColors.ink, false),
                  const SizedBox(width: 12),
                  button('Log Out', AppColors.error, AppColors.white, true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Organization Details
// -----------------------------------------------------------------------------

/// The organisation's name, type, registration, address, contact and about,
/// editable with Edit and saved with Save Changes.
class OrganizationDetailsScreen extends StatefulWidget {
  const OrganizationDetailsScreen({super.key});

  @override
  State<OrganizationDetailsScreen> createState() =>
      _OrganizationDetailsScreenState();
}

class _OrganizationDetailsScreenState extends State<OrganizationDetailsScreen> {
  final _start = CoordinatorBoard.organisation.value;
  late final _fields = {
    'Name': TextEditingController(text: _start.name),
    'Type': TextEditingController(text: _start.type),
    'Registration no.': TextEditingController(text: _start.registration),
    'Address': TextEditingController(text: _start.address),
    'Email': TextEditingController(text: _start.email),
    'Phone': TextEditingController(text: _start.phone),
    'About': TextEditingController(text: _start.about),
  };
  bool _editing = false;

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    String value(String key) => _fields[key]!.text.trim();
    if (value('Name').length < 2) {
      showAuthNotice(context, 'The organisation needs a name.');
      return;
    }
    HapticFeedback.mediumImpact();
    CoordinatorBoard.organisation.value = Organisation(
      name: value('Name'),
      type: value('Type'),
      registration: value('Registration no.'),
      address: value('Address'),
      email: value('Email'),
      phone: value('Phone'),
      about: value('About'),
    );
    setState(() => _editing = false);
    showAuthNotice(context, 'Organization details saved.');
  }

  @override
  Widget build(BuildContext context) {
    const icons = {
      'Name': Icons.apartment_rounded,
      'Type': Icons.category_outlined,
      'Registration no.': Icons.verified_outlined,
      'Address': Icons.place_outlined,
      'Email': Icons.mail_outline_rounded,
      'Phone': Icons.phone_outlined,
      'About': Icons.info_outline_rounded,
    };
    return CoordinatorPage(
      tab: CoordinatorTab.profile,
      title: 'Organization Details',
      subtitle: 'How your organisation appears to volunteers.',
      showBar: false,
      maxWidth: 720,
      photo: 'assets/images/event_food_warehouse.jpg',
      action: (c) => _editing
          ? PrimaryButton(
              label: 'Save Changes',
              scale: c.scale * 0.92,
              time: c.time,
              onPressed: _save,
            )
          : _OutlineButton(
              icon: Icons.edit_outlined,
              label: 'Edit Details',
              scale: c.scale,
              onTap: () => setState(() => _editing = true),
            ),
      body: (context, c) {
        final s = c.scale;
        return [
          CoordinatorCard(
            scale: s,
            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 6 * s),
            child: Column(
              children: [
                for (final (i, MapEntry(key: label, value: controller))
                    in _fields.entries.indexed) ...[
                  if (i > 0) rowDivider(),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12 * s),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 2 * s),
                          child: Icon(
                            icons[label],
                            size: 20 * s,
                            color: AppColors.leafLight,
                          ),
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
                              SizedBox(height: 3 * s),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: _editing
                                    ? TextField(
                                        key: const ValueKey('edit'),
                                        controller: controller,
                                        minLines: 1,
                                        maxLines: label == 'About' ? 4 : 1,
                                        cursorColor: AppColors.brand,
                                        style: TextStyle(
                                          fontSize: 15.5 * s,
                                          color: AppColors.ink,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.only(
                                            bottom: 6 * s,
                                          ),
                                          enabledBorder:
                                              const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: AppColors.fieldBorder,
                                                ),
                                              ),
                                          focusedBorder:
                                              const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: AppColors.brand,
                                                  width: 2,
                                                ),
                                              ),
                                        ),
                                      )
                                    : Text(
                                        controller.text,
                                        key: const ValueKey('view'),
                                        style: TextStyle(
                                          fontSize: 15.5 * s,
                                          height: 1.4,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.ink,
                                        ),
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
        ];
      },
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
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
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            height: 58 * s,
            decoration: BoxDecoration(
              color: AppColors.roleChosenFill,
              borderRadius: BorderRadius.circular(29 * s),
              border: Border.all(color: AppColors.roleChosenBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20 * s, color: AppColors.brand),
                SizedBox(width: 8 * s),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.5 * s,
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
// Team Management
// -----------------------------------------------------------------------------

/// The organisation's team with their roles, and Invite Member.
class TeamManagementScreen extends StatelessWidget {
  const TeamManagementScreen({super.key});

  Future<void> _invite(BuildContext context, double s) async {
    final invited = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.4),
      constraints: BoxConstraints(maxWidth: 600 * s),
      builder: (_) => _InviteSheet(scale: s),
    );
    if (invited != null && context.mounted) {
      showAuthNotice(context, 'Invite sent to $invited.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CoordinatorPage(
      tab: CoordinatorTab.profile,
      title: 'Team Management',
      subtitle: 'The people who run your events with you.',
      showBar: false,
      maxWidth: 720,
      photo: 'assets/images/role_volunteer.jpg',
      listenTo: CoordinatorBoard.team,
      action: (c) => PrimaryButton(
        label: '+  Invite Member',
        scale: c.scale * 0.92,
        time: c.time,
        onPressed: () => _invite(context, c.scale),
      ),
      body: (context, c) {
        final s = c.scale;
        final team = CoordinatorBoard.team.value;
        return [
          for (final (i, member) in team.indexed) ...[
            if (i > 0) rowDivider(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12 * s),
              child: Row(
                children: [
                  InitialsAvatar(
                    initials: member.initials,
                    colors: member.colors,
                    size: 50 * s,
                    person: member.you,
                  ),
                  SizedBox(width: 14 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.you ? '${member.name} (you)' : member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5 * s,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 2 * s),
                        Text(
                          member.email,
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
                  SizedBox(width: 8 * s),
                  StatusPill(
                    label: member.invited ? 'Invited' : member.role,
                    fill: member.invited
                        ? AppColors.tagFoodFill
                        : member.role == 'Admin'
                        ? AppColors.brand
                        : AppColors.roleChosenFill,
                    ink: member.invited
                        ? AppColors.tagFoodText
                        : member.role == 'Admin'
                        ? AppColors.white
                        : AppColors.brand,
                    scale: s,
                  ),
                ],
              ),
            ),
          ],
        ];
      },
    );
  }
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.scale});

  final double scale;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  String _role = teamRoles[1];
  bool _tried = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _emailValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  void _send() {
    setState(() => _tried = true);
    if (_name.text.trim().length < 2 || !_emailValid) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    final name = _name.text.trim();
    CoordinatorBoard.invite(
      TeamMember(
        name: name,
        role: _role,
        email: _email.text.trim(),
        colors:
            avatarColors[CoordinatorBoard.team.value.length %
                avatarColors.length],
        invited: true,
      ),
    );
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    Widget field(
      TextEditingController controller,
      String hint,
      IconData icon,
      String? error,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 54 * s,
          padding: EdgeInsets.symmetric(horizontal: 16 * s),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16 * s),
            border: Border.all(
              color: error != null ? AppColors.error : AppColors.fieldBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20 * s, color: AppColors.leafLight),
              SizedBox(width: 12 * s),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) {
                    if (_tried) setState(() {});
                  },
                  cursorColor: AppColors.brand,
                  style: TextStyle(fontSize: 15.5 * s, color: AppColors.ink),
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
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
        if (error != null)
          Padding(
            padding: EdgeInsets.only(top: 6 * s, left: 4 * s),
            child: Text(
              error,
              style: TextStyle(fontSize: 13 * s, color: AppColors.error),
            ),
          ),
      ],
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30 * s)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22 * s, 12 * s, 22 * s, 18 * s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.fieldBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                SizedBox(height: 16 * s),
                Text(
                  'Invite a team member',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 21 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 16 * s),
                field(
                  _name,
                  'Full name',
                  Icons.person_outline_rounded,
                  _tried && _name.text.trim().length < 2
                      ? 'Enter their name'
                      : null,
                ),
                SizedBox(height: 12 * s),
                field(
                  _email,
                  'Email',
                  Icons.mail_outline_rounded,
                  _tried && !_emailValid ? 'Enter a valid email' : null,
                ),
                SizedBox(height: 16 * s),
                Text(
                  'Role',
                  style: TextStyle(
                    fontSize: 15 * s,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 8 * s),
                Wrap(
                  spacing: 8 * s,
                  runSpacing: 8 * s,
                  children: [
                    for (final role in teamRoles)
                      Semantics(
                        button: true,
                        selected: role == _role,
                        label: role,
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _role = role);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              horizontal: 13 * s,
                              vertical: 8 * s,
                            ),
                            decoration: BoxDecoration(
                              color: role == _role
                                  ? AppColors.brand
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(16 * s),
                              border: Border.all(
                                color: role == _role
                                    ? AppColors.brand
                                    : AppColors.fieldBorder,
                              ),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(
                                fontSize: 13.5 * s,
                                fontWeight: FontWeight.w600,
                                color: role == _role
                                    ? AppColors.white
                                    : AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 22 * s),
                PrimaryButton(
                  label: 'Send Invite',
                  scale: s * 0.9,
                  onPressed: _send,
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

/// Settings for running events: volunteer approvals and waitlists,
/// reminders, alerts, reports and privacy. Changes save as they're made.
class CoordinatorSettingsScreen extends StatelessWidget {
  const CoordinatorSettingsScreen({super.key});

  void _update(CoordinatorSettings settings) {
    HapticFeedback.selectionClick();
    CoordinatorBoard.settings.value = settings;
  }

  @override
  Widget build(BuildContext context) {
    return CoordinatorPage(
      tab: CoordinatorTab.profile,
      title: 'Settings',
      subtitle: 'How your events run. Changes are saved as you make them.',
      showBar: false,
      maxWidth: 720,
      photo: 'assets/images/event_potato_sorting.jpg',
      listenTo: CoordinatorBoard.settings,
      body: (context, c) {
        final s = c.scale;
        final settings = CoordinatorBoard.settings.value;
        Widget group(String title, IconData icon, List<Widget> rows) => Padding(
          padding: EdgeInsets.only(bottom: 16 * s),
          child: CoordinatorCard(
            scale: s,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18 * s, color: AppColors.leafLight),
                    SizedBox(width: 8 * s),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 18 * s,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8 * s),
                for (final (i, row) in rows.indexed) ...[
                  if (i > 0) rowDivider(),
                  row,
                ],
              ],
            ),
          ),
        );
        Widget toggle(
          String label,
          String hint,
          bool value,
          CoordinatorSettings Function(bool) change,
        ) => _SwitchRow(
          label: label,
          hint: hint,
          value: value,
          scale: s,
          onChanged: (v) => _update(change(v)),
        );
        return [
          group('Volunteers', Icons.how_to_reg_outlined, [
            toggle(
              'Auto-approve new volunteers',
              'Skip the review for people who sign up',
              settings.autoApprove,
              (v) => settings.copyWith(autoApprove: v),
            ),
            toggle(
              'Waitlist when full',
              'Let volunteers queue for a spot that opens up',
              settings.waitlist,
              (v) => settings.copyWith(waitlist: v),
            ),
            toggle(
              'Share contacts with my team',
              'Team members can see volunteers’ phone numbers',
              settings.shareContacts,
              (v) => settings.copyWith(shareContacts: v),
            ),
          ]),
          group('Reminders', Icons.alarm_rounded, [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remind volunteers before an event',
                    style: TextStyle(
                      fontSize: 15.5 * s,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 10 * s),
                  Wrap(
                    spacing: 8 * s,
                    runSpacing: 8 * s,
                    children: [
                      for (final hours in const [2, 12, 24, 48])
                        Semantics(
                          button: true,
                          selected: hours == settings.reminderHours,
                          label: '$hours hours before',
                          excludeSemantics: true,
                          child: GestureDetector(
                            onTap: () => _update(
                              settings.copyWith(reminderHours: hours),
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                horizontal: 14 * s,
                                vertical: 8 * s,
                              ),
                              decoration: BoxDecoration(
                                color: hours == settings.reminderHours
                                    ? AppColors.brand
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(16 * s),
                                border: Border.all(
                                  color: hours == settings.reminderHours
                                      ? AppColors.brand
                                      : AppColors.fieldBorder,
                                ),
                              ),
                              child: Text(
                                hours == 48 ? '2 days' : '$hours hrs',
                                style: TextStyle(
                                  fontSize: 13.5 * s,
                                  fontWeight: FontWeight.w600,
                                  color: hours == settings.reminderHours
                                      ? AppColors.white
                                      : AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            toggle(
              'Check-in reminders',
              'Nudge volunteers to check in when an event starts',
              settings.checkInReminders,
              (v) => settings.copyWith(checkInReminders: v),
            ),
          ]),
          group('Alerts for you', Icons.notifications_none_rounded, [
            toggle(
              'New sign-ups',
              'When someone asks to join one of your events',
              settings.newSignUps,
              (v) => settings.copyWith(newSignUps: v),
            ),
            toggle(
              'Low supplies',
              'When packing bags or food stock run low',
              settings.lowSupplies,
              (v) => settings.copyWith(lowSupplies: v),
            ),
            toggle(
              'Weekly impact report',
              'Emailed to you every Monday morning',
              settings.weeklyReport,
              (v) => settings.copyWith(weeklyReport: v),
            ),
          ]),
          group('Organisation', Icons.apartment_rounded, [
            toggle(
              'Show on Explore',
              'Volunteers can find your events and organisation',
              settings.publicProfile,
              (v) => settings.copyWith(publicProfile: v),
            ),
          ]),
        ];
      },
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
  });

  final String label;
  final String hint;
  final bool value;
  final double scale;
  final ValueChanged<bool> onChanged;

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
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8 * s),
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

/// Guides for coordinators that open in place, and the coordinator support
/// line.
class CoordinatorHelpScreen extends StatefulWidget {
  const CoordinatorHelpScreen({super.key});

  @override
  State<CoordinatorHelpScreen> createState() => _CoordinatorHelpScreenState();
}

class _CoordinatorHelpScreenState extends State<CoordinatorHelpScreen> {
  int? _open;

  void _copy(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    showAuthNotice(context, '$what copied.');
  }

  @override
  Widget build(BuildContext context) {
    return CoordinatorPage(
      tab: CoordinatorTab.profile,
      title: 'Help & Support',
      subtitle: 'Guides for running great events, and a team on call.',
      showBar: false,
      maxWidth: 720,
      photo: 'assets/images/role_coordinator.jpg',
      body: (context, c) {
        final s = c.scale;
        return [
          CoordinatorCard(
            scale: s,
            child: Column(
              children: [
                for (final (i, (question, answer))
                    in coordinatorHelpTopics.indexed) ...[
                  if (i > 0) rowDivider(),
                  Semantics(
                    button: true,
                    expanded: _open == i,
                    label: question,
                    excludeSemantics: true,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _open = _open == i ? null : i);
                        },
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
                                    color: _open == i
                                        ? AppColors.brand
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: _open == i ? 0.5 : 0,
                                duration: const Duration(milliseconds: 250),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 24 * s,
                                  color: AppColors.fieldIcon,
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
                    child: _open == i
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
              ],
            ),
          ),
          SizedBox(height: 16 * s),
          for (final (icon, label, value, what) in [
            (
              Icons.support_agent_rounded,
              'Coordinator support (8 AM – 10 PM)',
              '+91 33 4000 5678',
              'Phone number',
            ),
            (
              Icons.mail_outline_rounded,
              'Email',
              'coordinators@foodlink.org',
              'Email address',
            ),
          ])
            Padding(
              padding: EdgeInsets.only(bottom: 10 * s),
              child: Semantics(
                button: true,
                label: '$label: $value',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => _copy(value, what),
                  child: CoordinatorCard(
                    scale: s,
                    padding: EdgeInsets.all(12 * s),
                    child: Row(
                      children: [
                        Container(
                          width: 42 * s,
                          height: 42 * s,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.roleChosenFill,
                          ),
                          child: Icon(
                            icon,
                            size: 20 * s,
                            color: AppColors.brand,
                          ),
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
                          Icons.copy_rounded,
                          size: 18 * s,
                          color: AppColors.fieldIcon,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ];
      },
    );
  }
}

/// The organisation on a photo banner, with a Verified badge.
class _OrgBanner extends StatelessWidget {
  const _OrgBanner({
    required this.organisation,
    required this.scale,
    required this.onTap,
  });

  final Organisation organisation;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      button: true,
      label: '${organisation.name}, ${organisation.type}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 118 * s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22 * s),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.16),
                  blurRadius: 22 * s,
                  offset: Offset(0, 10 * s),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/event_food_warehouse.jpg',
                  fit: BoxFit.cover,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.brandDark.withValues(alpha: 0.92),
                        AppColors.brandDark.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16 * s),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8 * s,
                                vertical: 3 * s,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10 * s),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 13 * s,
                                    color: AppColors.logoOnDark,
                                  ),
                                  SizedBox(width: 4 * s),
                                  Text(
                                    'Verified organisation',
                                    style: TextStyle(
                                      fontSize: 11.5 * s,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8 * s),
                            Text(
                              organisation.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 21 * s,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              organisation.type,
                              style: TextStyle(
                                fontSize: 13 * s,
                                color: AppColors.logoOnDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 26 * s,
                        color: AppColors.white,
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

/// The coordinator's milestones as medals: earned in colour, the rest
/// locked; tapping one says how it's earned.
class _Achievements extends StatelessWidget {
  const _Achievements({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final all = coordinatorAchievements();
    final earned = all.where((a) => a.$5).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.eco_rounded, size: 18 * s, color: AppColors.leafLight),
            SizedBox(width: 8 * s),
            Expanded(
              child: Text(
                'Milestones',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 19 * s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              '$earned of ${all.length}',
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
          height: 100 * s,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: all.length,
            separatorBuilder: (_, _) => SizedBox(width: 12 * s),
            itemBuilder: (context, i) {
              final (name, icon, color, how, done) = all[i];
              return Semantics(
                button: true,
                label: '$name${done ? ', earned' : ', not earned yet'}',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showAuthNotice(
                      context,
                      done ? '$name: earned! $how.' : '$name: $how to earn it.',
                    );
                  },
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 600 + i * 90),
                    curve: Curves.easeOutBack,
                    builder: (context, pop, child) => Transform.scale(
                      scale: pop.clamp(0.0, 1.2),
                      child: child,
                    ),
                    child: SizedBox(
                      width: 76 * s,
                      child: Column(
                        children: [
                          Container(
                            width: 58 * s,
                            height: 58 * s,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: done
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color.lerp(
                                          color,
                                          AppColors.white,
                                          0.35,
                                        )!,
                                        color,
                                      ],
                                    )
                                  : null,
                              color: done ? null : AppColors.socialFill,
                              border: Border.all(
                                color: done
                                    ? AppColors.white
                                    : AppColors.fieldBorder,
                                width: 3,
                              ),
                              boxShadow: [
                                if (done)
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.35),
                                    blurRadius: 12 * s,
                                    offset: Offset(0, 5 * s),
                                  ),
                              ],
                            ),
                            child: Icon(
                              done ? icon : Icons.lock_outline_rounded,
                              size: 25 * s,
                              color: done
                                  ? AppColors.white
                                  : AppColors.fieldHint,
                            ),
                          ),
                          SizedBox(height: 7 * s),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 11.5 * s,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                              color: done ? AppColors.ink : AppColors.fieldHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
