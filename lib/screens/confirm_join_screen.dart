import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/event_plans.dart';
import '../data/join_options.dart';
import '../data/sample_events.dart';
import '../navigation/tab_navigation.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/app_nav.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/event_tile.dart';
import '../widgets/leaf.dart';
import '../widgets/light_particles.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/primary_button.dart';
import '../widgets/rise_in.dart';
import '../widgets/soft_backdrop.dart';

/// Confirm Your Details: the step between Join Event and being counted in.
///
/// The volunteer picks a role and a time slot for the event (each opens a
/// list of choices in place), can leave a note for the organiser, with
/// quick suggestions to tap, and chooses whether to be reminded the day
/// before. Confirm & Join adds them to the event and plays a celebration
/// with a summary of what they signed up for.
///
/// Behind it all the event's own photo glows through, blurred and drifting,
/// with soft light specks and two swaying leaves. The event's photo grows
/// out of the details page ([heroTag]) into the summary card.
///
/// Phones follow the Figma frame, with Confirm & Join pinned to the bottom
/// on frosted glass; laptops get the side navigation rail ([tab]
/// highlighted), the event and what happens next on the left, and the form
/// on the right.
class ConfirmJoinScreen extends StatefulWidget {
  const ConfirmJoinScreen({
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
  State<ConfirmJoinScreen> createState() => _ConfirmJoinScreenState();
}

/// Which list of choices is open, if any.
enum _Picker { role, slot }

class _ConfirmJoinScreenState extends State<ConfirmJoinScreen>
    with TickerProviderStateMixin {
  static const _maxNotes = 200;

  /// Notes the volunteer can add with a tap.
  static const _suggestions = [
    'First time volunteering',
    'Vegetarian meals please',
    'Happy to lift heavy boxes',
    'Coming with a friend',
  ];

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  /// The celebration once the volunteer has joined.
  late final AnimationController _success = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  final _notes = TextEditingController();

  late final List<EventRole> _roles = rolesFor(_event);
  late final List<TimeSlot> _slots = timeSlotsFor(_event);
  int _role = 0;
  int _slot = 0;
  _Picker? _open;
  bool _remind = true;
  bool _submitting = false;

  VolunteerEvent get _event => widget.event;
  Object get _heroTag => widget.heroTag ?? 'details/${_event.title}';
  bool get _done => _success.status != AnimationStatus.dismissed;

  /// Staggered entrance progress (0–1) for the n-th element.
  double _rise(int n) {
    final start = (0.08 + n * 0.06).clamp(0.0, 0.62);
    return Curves.easeOutCubic.transform(
      ((_intro.value - start) / 0.38).clamp(0.0, 1.0),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _success.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _toggle(_Picker picker) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() => _open = _open == picker ? null : picker);
  }

  void _pick(_Picker picker, int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (picker == _Picker.role) {
        _role = index;
      } else {
        _slot = index;
      }
      _open = null;
    });
  }

  /// Adds [note] to the notes, or takes it out if it's already there.
  void _toggleSuggestion(String note) {
    HapticFeedback.selectionClick();
    final parts = _notes.text
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (!parts.remove(note)) parts.add(note);
    final text = parts.join(', ');
    if (text.length > _maxNotes) return;
    setState(() {
      _notes.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  Future<void> _confirm() async {
    if (_submitting || _done) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _open = null;
    });
    // A short beat, as a real sign-up would take.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    EventPlans.join(
      _event.title,
      JoinDetails(
        role: _roles[_role],
        slot: _slots[_slot],
        notes: _notes.text.trim(),
        remind: _remind,
      ),
    );
    setState(() => _submitting = false);
    _success.forward(from: 0);
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
            animation: Listenable.merge([_intro, _ambient, _success]),
            builder: (context, _) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarContrastEnforced: false,
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: _background(size, s, wide)),
                  Positioned.fill(
                    child: wide ? _buildWide(size, s) : _buildCompact(s),
                  ),
                  if (_done)
                    Positioned.fill(
                      child: _Celebration(
                        event: _event,
                        role: _roles[_role],
                        slot: _slots[_slot],
                        remind: _remind,
                        progress: _success.value,
                        time: _ambient.value,
                        scale: s,
                        onDone: () => Navigator.of(context).maybePop(),
                        onExplore: () => _openTab(AppTab.explore),
                        onMyEvents: () => _openTab(AppTab.events),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Background
  // ---------------------------------------------------------------------------

  /// Soft cream backdrop in the event's colours, with the event's photo
  /// blurred and slowly drifting across the top, fading into the page.
  Widget _background(Size size, double s, bool wide) {
    final t = _ambient.value * 2 * math.pi;
    final appear = Curves.easeOut.transform(_intro.value);
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: SoftBackdropPainter(
            time: _ambient.value,
            palette: SoftBackdropPalette(
              base: AppColors.backdrop,
              glows: [
                (_event.category.glow, 0.85, const Offset(0.9, 0.12), 0.5, 0),
                (AppColors.glowMint, 0.6, const Offset(0.05, 0.55), 0.45, 0.33),
                (AppColors.glowPeach, 0.5, const Offset(0.8, 0.85), 0.5, 0.66),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: size.height * (wide ? 0.62 : 0.5),
          child: Opacity(
            opacity: 0.42 * appear,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0x99FFFFFF),
                  Color(0x00FFFFFF),
                ],
                stops: [0, 0.45, 1],
              ).createShader(rect),
              child: ClipRect(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 26,
                    sigmaY: 26,
                    tileMode: TileMode.decal,
                  ),
                  child: Transform.scale(
                    scale: 1.25 + 0.05 * math.sin(t),
                    alignment: Alignment(math.cos(t) * 0.4, 0),
                    child: EventPhoto(event: _event),
                  ),
                ),
              ),
            ),
          ),
        ),
        // A cream wash keeps dark text crisp over the photo.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.surface.withValues(alpha: 0.35),
                AppColors.surface.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        const RepaintBoundary(child: CustomPaint(painter: DotTexturePainter())),
        IgnorePointer(
          child: CustomPaint(
            painter: _DecorPainter(
              time: _ambient.value,
              appear: appear,
              wide: wide,
              scale: s,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Phone layout
  // ---------------------------------------------------------------------------

  Widget _buildCompact(double s) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, 0),
            child: RiseIn(
              progress: _rise(0),
              distance: -10 * s,
              child: _headerRow(s),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      24 * s,
                      20 * s,
                      24 * s,
                      150 * s + bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 480 * s),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RiseIn(
                              progress: _rise(1),
                              distance: 18 * s,
                              child: _title(s, 32),
                            ),
                            SizedBox(height: 24 * s),
                            RiseIn(
                              progress: _rise(2),
                              distance: 18 * s,
                              child: _SummaryCard(
                                event: _event,
                                heroTag: _heroTag,
                                time: _ambient.value,
                                scale: s,
                              ),
                            ),
                            SizedBox(height: 28 * s),
                            ..._form(s, first: 3),
                            SizedBox(height: 26 * s),
                            RiseIn(
                              progress: _rise(9),
                              distance: 18 * s,
                              child: _NextSteps(event: _event, scale: s),
                            ),
                            SizedBox(height: 18 * s),
                            RiseIn(
                              progress: _rise(10),
                              distance: 18 * s,
                              child: _privacyNote(s),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Confirm & Join on frosted glass.
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
                          padding: EdgeInsets.fromLTRB(
                            24 * s,
                            12 * s,
                            24 * s,
                            0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.78),
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
                                child: _confirmArea(s),
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

    final eventSide = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RiseIn(
          progress: _rise(2),
          distance: 18 * s,
          child: _EventPanel(
            event: _event,
            heroTag: _heroTag,
            time: _ambient.value,
            scale: s,
          ),
        ),
        SizedBox(height: 22 * s),
        RiseIn(
          progress: _rise(4),
          distance: 18 * s,
          child: _NextSteps(event: _event, scale: s),
        ),
      ],
    );
    final form = RiseIn(
      progress: _rise(3),
      distance: 24 * s,
      child: _Card(
        scale: s,
        padding: EdgeInsets.all(30 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._form(s, first: 4),
            SizedBox(height: 26 * s),
            _confirmArea(s),
            SizedBox(height: 16 * s),
            _privacyNote(s),
          ],
        ),
      ),
    );

    return Row(
      children: [
        SizedBox(
          width: railWidth,
          child: AppSideRail(current: widget.tab, scale: s, onSelect: _openTab),
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
                        distance: 18 * s,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _title(s, 42),
                            SizedBox(height: 8 * s),
                            Text(
                              'Choose how you’d like to help at '
                              '${_event.title}.',
                              style: TextStyle(
                                fontSize: 17 * s,
                                color: AppColors.bodyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 28 * s),
                      if (sideBySide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 10, child: eventSide),
                            SizedBox(width: 36 * s),
                            Expanded(flex: 11, child: form),
                          ],
                        )
                      else ...[
                        eventSide,
                        SizedBox(height: 26 * s),
                        form,
                      ],
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
          onTap: () => openAppTab(context, null, AppTab.profile),
        ),
      ],
    );
  }

  Widget _title(double s, double size) {
    return Semantics(
      header: true,
      child: Text(
        'Confirm Your Details',
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: size * s,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -size * s * 0.01,
          color: AppColors.ink,
        ),
      ),
    );
  }

  /// Role, time slot, notes and the reminder switch, rising in from the
  /// [first] entrance step.
  List<Widget> _form(double s, {required int first}) {
    final category = _event.category;
    Widget rise(int n, Widget child) =>
        RiseIn(progress: _rise(first + n), distance: 18 * s, child: child);
    return [
      rise(
        0,
        _Field(
          label: 'Role',
          scale: s,
          child: _Dropdown(
            label: 'Role',
            options: [
              for (final role in _roles) (role.icon, role.name, role.blurb),
            ],
            selected: _role,
            open: _open == _Picker.role,
            category: category,
            scale: s,
            onToggle: () => _toggle(_Picker.role),
            onSelect: (i) => _pick(_Picker.role, i),
          ),
        ),
      ),
      SizedBox(height: 22 * s),
      rise(
        1,
        _Field(
          label: 'Time Slot',
          scale: s,
          child: _Dropdown(
            label: 'Time Slot',
            options: [
              for (final slot in _slots) (slot.icon, slot.label, slot.range),
            ],
            selected: _slot,
            open: _open == _Picker.slot,
            category: category,
            scale: s,
            onToggle: () => _toggle(_Picker.slot),
            onSelect: (i) => _pick(_Picker.slot, i),
          ),
        ),
      ),
      SizedBox(height: 22 * s),
      rise(
        2,
        _Field(
          label: 'Additional Notes (Optional)',
          scale: s,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NotesField(
                controller: _notes,
                maxLength: _maxNotes,
                scale: s,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 12 * s),
              Wrap(
                spacing: 8 * s,
                runSpacing: 8 * s,
                children: [
                  for (final note in _suggestions)
                    _SuggestionChip(
                      label: note,
                      chosen: _notes.text.contains(note),
                      scale: s,
                      onTap: () => _toggleSuggestion(note),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: 22 * s),
      rise(
        3,
        _ReminderRow(
          value: _remind,
          scale: s,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            setState(() => _remind = value);
          },
        ),
      ),
    ];
  }

  /// What's been picked, then Confirm & Join.
  Widget _confirmArea(double s) {
    final role = _roles[_role];
    final slot = _slots[_slot];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Row(
            key: ValueKey('$_role/$_slot'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(role.icon, size: 16 * s, color: AppColors.brand),
              SizedBox(width: 6 * s),
              Flexible(
                child: Text(
                  '${role.name}  ·  ${slot.name}, ${slot.range}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5 * s,
                    fontWeight: FontWeight.w600,
                    color: AppColors.bodyText,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10 * s),
        PrimaryButton(
          label: 'Confirm & Join',
          scale: s,
          time: _ambient.value,
          loading: _submitting,
          onPressed: _done ? null : _confirm,
        ),
      ],
    );
  }

  Widget _privacyNote(double s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 17 * s,
          color: AppColors.fieldIcon,
        ),
        SizedBox(width: 8 * s),
        Expanded(
          child: Text(
            'Only ${_event.organiser} will see your role, time slot and '
            'notes. You can leave the event at any time.',
            style: TextStyle(
              fontSize: 13 * s,
              height: 1.5,
              color: AppColors.fieldIcon,
            ),
          ),
        ),
      ],
    );
  }
}

/// Frosted white card.
class _Card extends StatelessWidget {
  const _Card({
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
        color: AppColors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24 * s),
        border: Border.all(color: AppColors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.08),
            blurRadius: 28 * s,
            offset: Offset(0, 10 * s),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A form label above its input.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.scale, required this.child});

  final String label;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 17 * s,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        SizedBox(height: 10 * s),
        child,
      ],
    );
  }
}

/// Figma's event card: the photo, then the title, date and time, with the
/// place and spots left added below.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.event,
    required this.heroTag,
    required this.time,
    required this.scale,
  });

  final VolunteerEvent event;
  final Object heroTag;
  final double time;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final spotsLeft = math.max(0, event.capacity - event.going);
    final grey = TextStyle(fontSize: 15.5 * s, color: AppColors.fieldIcon);
    return Row(
      children: [
        SizedBox.square(
          dimension: 132 * s,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20 * s),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.18),
                  blurRadius: 20 * s,
                  offset: Offset(0, 8 * s),
                ),
              ],
            ),
            child: Hero(
              tag: heroTag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20 * s),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Transform.scale(
                      scale: 1.06 + 0.03 * math.sin(time * 2 * math.pi),
                      child: EventPhoto(event: event),
                    ),
                    Positioned(
                      left: 8 * s,
                      top: 8 * s,
                      child: EventCategoryTag(
                        category: event.category,
                        scale: s * 0.85,
                        shadow: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 20 * s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: TextStyle(
                  fontSize: 19 * s,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 10 * s),
              Text(event.date, style: grey),
              SizedBox(height: 6 * s),
              Text(event.hours, style: grey),
              SizedBox(height: 10 * s),
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 15 * s,
                    color: AppColors.brand,
                  ),
                  SizedBox(width: 4 * s),
                  Flexible(
                    child: Text(
                      event.place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5 * s,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6 * s),
              _SpotsPill(left: spotsLeft, scale: s),
            ],
          ),
        ),
      ],
    );
  }
}

/// "10 spots left", amber when only a few remain.
class _SpotsPill extends StatelessWidget {
  const _SpotsPill({
    required this.left,
    required this.scale,
    this.onDark = false,
  });

  final int left;
  final double scale;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final few = left <= 5;
    final fill = onDark
        ? AppColors.white.withValues(alpha: 0.2)
        : few
        ? AppColors.tagFoodFill
        : AppColors.roleChosenFill;
    final ink = onDark
        ? AppColors.white
        : few
        ? AppColors.tagFoodText
        : AppColors.brand;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12 * s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            few
                ? Icons.local_fire_department_rounded
                : Icons.event_seat_rounded,
            size: 13 * s,
            color: ink,
          ),
          SizedBox(width: 4 * s),
          Text(
            few
                ? 'Only $left ${left == 1 ? 'spot' : 'spots'} left'
                : '$left spots left',
            style: TextStyle(
              fontSize: 12 * s,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Laptops: the event's photo, large, with its details on frosted glass.
class _EventPanel extends StatelessWidget {
  const _EventPanel({
    required this.event,
    required this.heroTag,
    required this.time,
    required this.scale,
  });

  final VolunteerEvent event;
  final Object heroTag;
  final double time;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final white = TextStyle(
      fontSize: 15 * s,
      fontWeight: FontWeight.w500,
      color: AppColors.white,
    );
    final t = time * 2 * math.pi;
    return Container(
      height: 340 * s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28 * s),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(
              AppColors.ink,
              event.category.text,
              0.4,
            )!.withValues(alpha: 0.22),
            blurRadius: 40 * s,
            offset: Offset(0, 18 * s),
          ),
        ],
      ),
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28 * s),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: 1.08 + 0.04 * math.sin(t),
                alignment: Alignment(math.cos(t) * 0.3, 0),
                child: EventPhoto(event: event),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.splashScrim.withValues(alpha: 0.25),
                      AppColors.splashScrim.withValues(alpha: 0),
                      AppColors.splashScrim.withValues(alpha: 0.55),
                    ],
                    stops: const [0, 0.4, 1],
                  ),
                ),
              ),
              Positioned(
                left: 20 * s,
                top: 20 * s,
                child: EventCategoryTag(
                  category: event.category,
                  scale: s,
                  fontSize: 14,
                  shadow: true,
                ),
              ),
              Positioned(
                left: 16 * s,
                right: 16 * s,
                bottom: 16 * s,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20 * s),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: EdgeInsets.all(18 * s),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20 * s),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.title,
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 24 * s,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(height: 10 * s),
                          Wrap(
                            spacing: 18 * s,
                            runSpacing: 6 * s,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              for (final (icon, text) in [
                                (Icons.event_available_rounded, event.date),
                                (Icons.schedule_rounded, event.hours),
                                (Icons.place_outlined, event.place),
                              ])
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 17 * s,
                                      color: AppColors.white,
                                    ),
                                    SizedBox(width: 6 * s),
                                    Text(text, style: white),
                                  ],
                                ),
                              _SpotsPill(
                                left: math.max(0, event.capacity - event.going),
                                scale: s,
                                onDark: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

/// A white field showing the current choice; tapping it opens the list of
/// [options] (icon, title, subtitle) just below, to pick from.
class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.options,
    required this.selected,
    required this.open,
    required this.category,
    required this.scale,
    required this.onToggle,
    required this.onSelect,
  });

  final String label;
  final List<(IconData, String, String)> options;
  final int selected;
  final bool open;
  final EventCategory category;
  final double scale;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final (icon, title, _) = options[selected];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          label: '$label: $title',
          excludeSemantics: true,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: 62 * s,
                padding: EdgeInsets.only(left: 12 * s, right: 16 * s),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16 * s),
                  border: Border.all(
                    color: open
                        ? AppColors.brand.withValues(alpha: 0.7)
                        : AppColors.fieldBorder,
                    width: open ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(
                        alpha: open ? 0.14 : 0.05,
                      ),
                      blurRadius: (open ? 18 : 10) * s,
                      offset: Offset(0, 4 * s),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                        child: child,
                      ),
                      child: Container(
                        key: ValueKey(selected),
                        width: 38 * s,
                        height: 38 * s,
                        decoration: BoxDecoration(
                          color: category.fill,
                          borderRadius: BorderRadius.circular(12 * s),
                        ),
                        child: Icon(icon, size: 20 * s, color: category.text),
                      ),
                    ),
                    SizedBox(width: 14 * s),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previous, ?current],
                        ),
                        child: Text(
                          title,
                          key: ValueKey(title),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17 * s,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 26 * s,
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
          child: !open
              ? const SizedBox(width: double.infinity)
              : Container(
                  margin: EdgeInsets.only(top: 8 * s),
                  padding: EdgeInsets.all(6 * s),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18 * s),
                    border: Border.all(color: AppColors.fieldBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.08),
                        blurRadius: 24 * s,
                        offset: Offset(0, 10 * s),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (final (i, option) in options.indexed)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 260 + i * 60),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => RiseIn(
                            progress: value,
                            distance: 10 * s,
                            child: child!,
                          ),
                          child: _Option(
                            option: option,
                            chosen: i == selected,
                            category: category,
                            scale: s,
                            onTap: () => onSelect(i),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// One choice in an open [_Dropdown].
class _Option extends StatefulWidget {
  const _Option({
    required this.option,
    required this.chosen,
    required this.category,
    required this.scale,
    required this.onTap,
  });

  final (IconData, String, String) option;
  final bool chosen;
  final EventCategory category;
  final double scale;
  final VoidCallback onTap;

  @override
  State<_Option> createState() => _OptionState();
}

class _OptionState extends State<_Option> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final (icon, title, subtitle) = widget.option;
    final chosen = widget.chosen;
    return Semantics(
      button: true,
      selected: chosen,
      label: title,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 10 * s),
            decoration: BoxDecoration(
              color: chosen
                  ? AppColors.roleChosenFill
                  : _hovered
                  ? AppColors.background
                  : AppColors.white.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(14 * s),
            ),
            child: Row(
              children: [
                Container(
                  width: 36 * s,
                  height: 36 * s,
                  decoration: BoxDecoration(
                    color: chosen ? AppColors.white : widget.category.fill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18 * s, color: widget.category.text),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5 * s,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 2 * s),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13 * s,
                          color: AppColors.fieldIcon,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8 * s),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22 * s,
                  height: 22 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: chosen ? AppColors.brand : AppColors.white,
                    border: Border.all(
                      color: chosen ? AppColors.brand : AppColors.fieldBorder,
                      width: 1.5,
                    ),
                  ),
                  child: chosen
                      ? Icon(
                          Icons.check_rounded,
                          size: 14 * s,
                          color: AppColors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The grey notes box from the Figma, with a character count.
class _NotesField extends StatefulWidget {
  const _NotesField({
    required this.controller,
    required this.maxLength,
    required this.scale,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int maxLength;
  final double scale;
  final ValueChanged<String> onChanged;

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final focused = _focus.hasFocus;
    final length = widget.controller.text.length;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.fromLTRB(18 * s, 16 * s, 14 * s, 10 * s),
      decoration: BoxDecoration(
        color: focused ? AppColors.white : AppColors.socialFill,
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(
          color: focused
              ? AppColors.brand.withValues(alpha: 0.7)
              : AppColors.fieldBorder,
          width: focused ? 1.5 : 1,
        ),
        boxShadow: [
          if (focused)
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.14),
              blurRadius: 18 * s,
              offset: Offset(0, 4 * s),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: widget.controller,
            focusNode: _focus,
            minLines: 2,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              LengthLimitingTextInputFormatter(widget.maxLength),
            ],
            onChanged: widget.onChanged,
            cursorColor: AppColors.brand,
            style: TextStyle(
              fontSize: 16 * s,
              height: 1.45,
              color: AppColors.ink,
            ),
            decoration: InputDecoration.collapsed(
              hintText: 'e.g. dietary preference, experience...',
              hintStyle: TextStyle(
                fontSize: 16 * s,
                color: AppColors.fieldHint,
              ),
            ),
          ),
          SizedBox(height: 6 * s),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$length/${widget.maxLength}',
              style: TextStyle(
                fontSize: 12 * s,
                fontWeight: FontWeight.w500,
                color: length >= widget.maxLength
                    ? AppColors.tagFoodText
                    : AppColors.fieldHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A note to add with one tap; shows a tick once it's in the notes.
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.chosen,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final bool chosen;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      button: true,
      selected: chosen,
      label: label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
            decoration: BoxDecoration(
              color: chosen
                  ? AppColors.roleChosenFill
                  : AppColors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20 * s),
              border: Border.all(
                color: chosen
                    ? AppColors.roleChosenBorder
                    : AppColors.fieldBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    chosen ? Icons.check_rounded : Icons.add_rounded,
                    key: ValueKey(chosen),
                    size: 15 * s,
                    color: AppColors.brand,
                  ),
                ),
                SizedBox(width: 5 * s),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13 * s,
                      fontWeight: FontWeight.w600,
                      color: chosen ? AppColors.brand : AppColors.bodyText,
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

/// "Remind me the day before", with a switch.
class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.value,
    required this.scale,
    required this.onChanged,
  });

  final bool value;
  final double scale;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      toggled: value,
      label: 'Remind me the day before',
      excludeSemantics: true,
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 8 * s, 12 * s),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16 * s),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 38 * s,
                  height: 38 * s,
                  decoration: BoxDecoration(
                    color: value
                        ? AppColors.roleChosenFill
                        : AppColors.socialFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    value
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_outlined,
                    size: 19 * s,
                    color: value ? AppColors.brand : AppColors.fieldIcon,
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remind me the day before',
                        style: TextStyle(
                          fontSize: 15.5 * s,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 2 * s),
                      Text(
                        'A friendly nudge at 6 PM',
                        style: TextStyle(
                          fontSize: 13 * s,
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
      ),
    );
  }
}

/// What happens after joining, as three linked steps.
class _NextSteps extends StatelessWidget {
  const _NextSteps({required this.event, required this.scale});

  final VolunteerEvent event;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final steps = [
      (
        Icons.mark_email_read_outlined,
        'Instant confirmation',
        'Your spot is saved straight away.',
      ),
      (
        Icons.notifications_none_rounded,
        'A reminder before the day',
        'With the time, place and what to bring.',
      ),
      (
        Icons.how_to_reg_outlined,
        'Check in on arrival',
        'Give your name at the ${event.place} welcome desk.',
      ),
    ];
    return _Card(
      scale: s,
      padding: EdgeInsets.all(18 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.eco_rounded, size: 18 * s, color: AppColors.leafLight),
              SizedBox(width: 8 * s),
              Text(
                'What happens next',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 18 * s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * s),
          for (final (i, (icon, title, text)) in steps.indexed)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 34 * s,
                        height: 34 * s,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.accentGradient,
                          ),
                        ),
                        child: Icon(icon, size: 17 * s, color: AppColors.white),
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: EdgeInsets.symmetric(vertical: 4 * s),
                            color: AppColors.stepDone,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 12 * s),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 6 * s,
                        bottom: i < steps.length - 1 ? 14 * s : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15 * s,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 2 * s),
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 13.5 * s,
                              height: 1.4,
                              color: AppColors.bodyText,
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
      ),
    );
  }
}

/// "You're in!": a frosted veil over the page, a card with a tick that draws
/// itself, confetti, and what the volunteer signed up for.
class _Celebration extends StatelessWidget {
  const _Celebration({
    required this.event,
    required this.role,
    required this.slot,
    required this.remind,
    required this.progress,
    required this.time,
    required this.scale,
    required this.onDone,
    required this.onExplore,
    required this.onMyEvents,
  });

  final VolunteerEvent event;
  final EventRole role;
  final TimeSlot slot;
  final bool remind;
  final double progress;
  final double time;
  final double scale;
  final VoidCallback onDone;
  final VoidCallback onExplore;
  final VoidCallback onMyEvents;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    double part(double from, double to) => Curves.easeOutCubic.transform(
      ((progress - from) / (to - from)).clamp(0.0, 1.0),
    );
    final veil = part(0, 0.25);
    final card = Curves.easeOutBack.transform(
      ((progress - 0.05) / 0.35).clamp(0.0, 1.0),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blocks taps on the form underneath.
        ModalBarrier(color: AppColors.ink.withValues(alpha: 0.28 * veil)),
        IgnorePointer(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10 * veil, sigmaY: 10 * veil),
            child: const SizedBox.expand(),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(painter: _ConfettiPainter(progress: progress)),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24 * s),
              child: Opacity(
                opacity: card.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.85 + 0.15 * card,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 420 * s),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        24 * s,
                        30 * s,
                        24 * s,
                        20 * s,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(30 * s),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.25),
                            blurRadius: 50 * s,
                            offset: Offset(0, 20 * s),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: SizedBox.square(
                              dimension: 96 * s,
                              child: CustomPaint(
                                painter: _TickPainter(
                                  ring: part(0.15, 0.5),
                                  tick: part(0.4, 0.65),
                                  time: time,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 18 * s),
                          RiseIn(
                            progress: part(0.4, 0.7),
                            distance: 12 * s,
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                'You’re in!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontSize: 30 * s,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 6 * s),
                          RiseIn(
                            progress: part(0.45, 0.75),
                            distance: 12 * s,
                            child: Text(
                              'Thanks for joining ${event.title}. '
                              'See you at ${event.place}!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15 * s,
                                height: 1.5,
                                color: AppColors.bodyText,
                              ),
                            ),
                          ),
                          SizedBox(height: 18 * s),
                          RiseIn(
                            progress: part(0.5, 0.8),
                            distance: 12 * s,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14 * s,
                                vertical: 4 * s,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(18 * s),
                                border: Border.all(
                                  color: AppColors.fieldBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  for (final (i, (icon, text)) in [
                                    (role.icon, role.name),
                                    (Icons.schedule_rounded, slot.label),
                                    (Icons.event_available_rounded, event.date),
                                    if (remind)
                                      (
                                        Icons.notifications_active_outlined,
                                        'Reminder set for the day before',
                                      ),
                                  ].indexed) ...[
                                    if (i > 0)
                                      Container(
                                        height: 1,
                                        color: AppColors.fieldBorder,
                                      ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10 * s,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            icon,
                                            size: 18 * s,
                                            color: AppColors.brand,
                                          ),
                                          SizedBox(width: 10 * s),
                                          Expanded(
                                            child: Text(
                                              text,
                                              style: TextStyle(
                                                fontSize: 14.5 * s,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.ink,
                                              ),
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
                          SizedBox(height: 20 * s),
                          RiseIn(
                            progress: part(0.6, 0.9),
                            distance: 12 * s,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PrimaryButton(
                                  label: 'Back to Event',
                                  scale: s * 0.9,
                                  time: time,
                                  onPressed: onDone,
                                ),
                                SizedBox(height: 12 * s),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 10 * s,
                                  runSpacing: 6 * s,
                                  children: [
                                    AuthTextLink(
                                      label: 'View My Events',
                                      scale: s,
                                      fontSize: 15,
                                      onTap: onMyEvents,
                                    ),
                                    Text(
                                      '·',
                                      style: TextStyle(
                                        fontSize: 15 * s,
                                        color: AppColors.fieldHint,
                                      ),
                                    ),
                                    AuthTextLink(
                                      label: 'Explore more',
                                      scale: s,
                                      fontSize: 15,
                                      onTap: onExplore,
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A green ring that draws itself, a tick inside it, and a soft halo
/// pulsing around it.
class _TickPainter extends CustomPainter {
  _TickPainter({required this.ring, required this.tick, required this.time});

  final double ring;
  final double tick;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final pulse = (time * 4) % 1.0;
    canvas.drawCircle(
      centre,
      r * (0.9 + 0.25 * pulse),
      Paint()
        ..color = AppColors.leafLight.withValues(
          alpha: 0.25 * (1 - pulse) * ring,
        ),
    );
    canvas.drawCircle(
      centre,
      r * 0.86 * ring,
      Paint()
        ..shader = ui.Gradient.linear(
          centre - Offset(r, r),
          centre + Offset(r, r),
          AppColors.accentGradient,
        ),
    );
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: r * 0.92),
      -math.pi / 2,
      2 * math.pi * ring,
      false,
      Paint()
        ..color = AppColors.roleChosenBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..strokeCap = StrokeCap.round,
    );
    if (tick <= 0) return;
    final path = Path()
      ..moveTo(centre.dx - r * 0.34, centre.dy + r * 0.02)
      ..lineTo(centre.dx - r * 0.08, centre.dy + r * 0.28)
      ..lineTo(centre.dx + r * 0.38, centre.dy - r * 0.26);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * tick),
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.13
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter oldDelegate) => true;
}

/// Confetti and little leaves bursting up from the middle of the screen,
/// then fluttering down.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});

  final double progress;

  static const _colors = [
    AppColors.leafLight,
    AppColors.sun,
    AppColors.brand,
    AppColors.onboardingLeaf,
    AppColors.earthLight,
    AppColors.badge,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = ((progress - 0.12) / 0.88).clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) return;
    final rnd = math.Random(11);
    final origin = Offset(size.width / 2, size.height * 0.42);
    final spread = math.min(size.width, 700.0);
    final fade = 1 - Curves.easeIn.transform(t);
    for (var i = 0; i < 46; i++) {
      final angle = -math.pi * (0.05 + 0.9 * rnd.nextDouble());
      final speed = (0.35 + rnd.nextDouble() * 0.5) * spread;
      final launch = Curves.easeOutCubic.transform(t);
      final point =
          origin +
          Offset(math.cos(angle), math.sin(angle)) * speed * launch +
          Offset(math.sin(t * 10 + i) * 12, size.height * 0.45 * t * t);
      final spin = rnd.nextDouble() * math.pi + t * 8 * (i.isEven ? 1 : -1);
      final w = 5 + rnd.nextDouble() * 6;
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(spin);
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: fade);
      if (i % 3 == 0) {
        // A little leaf.
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: w * 1.8, height: w * 0.9),
          paint,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.55),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

const _leafA = LeafShape(
  tipA: Offset(52, 6),
  tipB: Offset(14, 70),
  bulgeLeft: 14,
  bulgeRight: 12,
  color: AppColors.onboardingLeaf,
  veinColor: AppColors.leafVein,
);

const _leafB = LeafShape(
  tipA: Offset(8, 10),
  tipB: Offset(44, 58),
  bulgeLeft: 10,
  bulgeRight: 11,
  color: AppColors.leafLight,
  veinColor: AppColors.leafVein,
);

/// Light specks drifting up the page and two leaves swaying at its edges.
class _DecorPainter extends CustomPainter {
  _DecorPainter({
    required this.time,
    required this.appear,
    required this.wide,
    required this.scale,
  });

  final double time;
  final double appear;
  final bool wide;
  final double scale;

  static final _specks = LightParticles(
    top: 60,
    bottom: 880,
    count: 16,
    seed: 23,
    color: AppColors.leafLight,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final s = scale;
    _specks.paint(
      canvas,
      sx: size.width / OnboardingLayout.designWidth,
      sy: size.height / OnboardingLayout.designHeight,
      time: time,
      opacity: 0.5 * appear,
    );
    final (a, b) = wide
        ? (
            Offset(size.width - 60 * s, 170 * s),
            Offset(size.width - 40 * s, size.height - 50 * s),
          )
        // Peeking in from the edges, clear of the form.
        : (
            Offset(size.width - 4 * s, size.height * 0.46),
            Offset(0, size.height * 0.68),
          );
    paintSwayingLeaf(
      canvas,
      _leafA,
      target: a,
      scale: s * 0.65,
      time: time,
      appear: appear,
    );
    paintSwayingLeaf(
      canvas,
      _leafB,
      target: b,
      scale: s * 0.55,
      time: time,
      appear: appear,
      phase: 0.6,
      entry: const Offset(-50, 40),
    );
  }

  @override
  bool shouldRepaint(_DecorPainter oldDelegate) => true;
}
