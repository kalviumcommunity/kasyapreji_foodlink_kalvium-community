import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/coordinator.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'event_tile.dart';

/// Pieces of the coordinator's home: today's event, alerts, actions, the
/// week's events, activity, and the Manage Event and message panels.

/// "1,240".
String formatCount(int value) {
  final digits = '$value';
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// A soft dot that breathes, for things happening now.
class PulseDot extends StatelessWidget {
  const PulseDot({
    super.key,
    required this.time,
    required this.size,
    this.color = AppColors.leafLight,
  });

  final double time;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pulse = (time * 4) % 1.0;
    return SizedBox.square(
      dimension: size * 1.8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * (1 + 0.8 * pulse),
            height: size * (1 + 0.8 * pulse),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.4 * (1 - pulse)),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ],
      ),
    );
  }
}

/// "● Live" beside Today's Events.
class LiveChip extends StatelessWidget {
  const LiveChip({super.key, required this.time, required this.scale});

  final double time;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.fromLTRB(6 * s, 3 * s, 10 * s, 3 * s),
      decoration: BoxDecoration(
        color: AppColors.roleChosenFill,
        borderRadius: BorderRadius.circular(12 * s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseDot(time: time, size: 7 * s, color: AppColors.brand),
          SizedBox(width: 2 * s),
          Text(
            'Live',
            style: TextStyle(
              fontSize: 13 * s,
              fontWeight: FontWeight.w700,
              color: AppColors.brand,
            ),
          ),
        ],
      ),
    );
  }
}

/// The Figma's today card: the photo, the title and "Ongoing · 20/30
/// volunteers", with the time and place and a check-in bar added.
class TodayEventCard extends StatefulWidget {
  const TodayEventCard({
    super.key,
    required this.managed,
    required this.checkedIn,
    required this.time,
    required this.scale,
    required this.onTap,
    this.large = false,
  });

  final ManagedEvent managed;
  final int checkedIn;
  final double time;
  final double scale;
  final bool large;
  final VoidCallback onTap;

  @override
  State<TodayEventCard> createState() => _TodayEventCardState();
}

class _TodayEventCardState extends State<TodayEventCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final managed = widget.managed;
    final event = managed.event;
    final total = managed.roster.length;
    final share = total == 0 ? 0.0 : widget.checkedIn / total;
    final photo = (widget.large ? 150 : 118) * s;

    return Semantics(
      button: true,
      label:
          '${event.title}. Ongoing. ${widget.checkedIn} of $total '
          'volunteers checked in',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.all(12 * s),
            transform: Matrix4.translationValues(0, _hovered ? -3 * s : 0, 0),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(26 * s),
              border: Border.all(color: AppColors.white),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(
                    alpha: _hovered ? 0.14 : 0.07,
                  ),
                  blurRadius: 26 * s,
                  offset: Offset(0, 10 * s),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: photo,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20 * s),
                        child: Transform.scale(
                          scale:
                              1.06 + 0.04 * math.sin(widget.time * 2 * math.pi),
                          child: EventPhoto(event: event),
                        ),
                      ),
                      Positioned(
                        left: 8 * s,
                        top: 8 * s,
                        child: Container(
                          padding: EdgeInsets.fromLTRB(
                            4 * s,
                            2 * s,
                            8 * s,
                            2 * s,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(10 * s),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PulseDot(
                                time: widget.time,
                                size: 6 * s,
                                color: AppColors.badge,
                              ),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 10 * s,
                                  letterSpacing: 0.8 * s,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.badge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 18 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: (widget.large ? 21 : 18) * s,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 8 * s),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          'Ongoing · ${widget.checkedIn}/$total volunteers',
                          key: ValueKey(widget.checkedIn),
                          style: TextStyle(
                            fontSize: 15.5 * s,
                            fontWeight: FontWeight.w600,
                            color: AppColors.leafMid,
                          ),
                        ),
                      ),
                      SizedBox(height: 6 * s),
                      Text(
                        '${event.hours} · ${event.place}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13 * s,
                          color: AppColors.fieldIcon,
                        ),
                      ),
                      SizedBox(height: 10 * s),
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: share),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, fill, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(4 * s),
                          child: SizedBox(
                            height: 7 * s,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                const ColoredBox(color: AppColors.stepTodo),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: fill.clamp(0.0, 1.0),
                                  child: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: AppColors.accentGradient,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (managed.mealsSoFar > 0) ...[
                        SizedBox(height: 8 * s),
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant_rounded,
                              size: 14 * s,
                              color: AppColors.tagFoodText,
                            ),
                            SizedBox(width: 5 * s),
                            Flexible(
                              child: Text(
                                '${managed.mealsSoFar} meals handed out so far',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5 * s,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.tagFoodText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

/// Something that needs a decision, with a one-tap action. Once handled it
/// turns green and says what happened.
class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    required this.handled,
    required this.scale,
    required this.onAction,
  });

  final CoordinatorAlert alert;
  final bool handled;
  final double scale;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(14 * s),
      decoration: BoxDecoration(
        color: handled
            ? AppColors.roleChosenFill
            : AppColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(
          color: handled ? AppColors.roleChosenBorder : AppColors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: handled ? 0 : 0.06),
            blurRadius: 20 * s,
            offset: Offset(0, 8 * s),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 42 * s,
            height: 42 * s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: handled
                  ? AppColors.brand
                  : alert.color.withValues(alpha: 0.14),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: child,
              ),
              child: Icon(
                handled ? Icons.check_rounded : alert.icon,
                key: ValueKey(handled),
                size: 21 * s,
                color: handled ? AppColors.white : alert.color,
              ),
            ),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 15 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 2 * s),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: Text(
                    handled ? alert.done : alert.detail,
                    key: ValueKey(handled),
                    style: TextStyle(
                      fontSize: 13 * s,
                      height: 1.35,
                      color: handled ? AppColors.brand : AppColors.bodyText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!handled) ...[
            SizedBox(width: 10 * s),
            Semantics(
              button: true,
              label: alert.action,
              excludeSemantics: true,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * s,
                      vertical: 8 * s,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(14 * s),
                    ),
                    child: Text(
                      alert.action,
                      style: TextStyle(
                        fontSize: 12.5 * s,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A square shortcut: an icon in a green circle over a two-line label.
class QuickActionTile extends StatefulWidget {
  const QuickActionTile({
    super.key,
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
  State<QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<QuickActionTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Semantics(
      button: true,
      label: widget.label.replaceAll('-\n', '').replaceAll('\n', ' '),
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
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 112 * s,
              decoration: BoxDecoration(
                color: _hovered
                    ? AppColors.white
                    : AppColors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(20 * s),
                border: Border.all(
                  color: _hovered
                      ? AppColors.roleChosenBorder
                      : AppColors.white,
                ),
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
                child: Padding(
                  padding: EdgeInsets.all(8 * s),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44 * s,
                        height: 44 * s,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.accentGradient,
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 22 * s,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: 8 * s),
                      Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13 * s,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
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
    );
  }
}

/// One of the week's events: photo, title, when, and how full it is.
class WeekEventRow extends StatefulWidget {
  const WeekEventRow({
    super.key,
    required this.managed,
    required this.scale,
    required this.onTap,
  });

  final ManagedEvent managed;
  final double scale;
  final VoidCallback onTap;

  @override
  State<WeekEventRow> createState() => _WeekEventRowState();
}

class _WeekEventRowState extends State<WeekEventRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final event = widget.managed.event;
    final signed = widget.managed.roster.length;
    final capacity = event.capacity;
    final share = (signed / capacity).clamp(0.0, 1.0);
    final left = capacity - signed;
    final short = left > 0 && share < 0.5;
    final full = left <= 0;
    final (note, color) = full
        ? ('Full', AppColors.brand)
        : short
        ? ('Needs $left more', AppColors.badge)
        : ('$left spots left', AppColors.fieldIcon);

    return Semantics(
      button: true,
      label: '${event.title}. ${event.when}. $signed of $capacity signed up',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14 * s),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 64 * s,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16 * s),
                    child: AnimatedScale(
                      scale: _hovered ? 1.08 : 1,
                      duration: const Duration(milliseconds: 300),
                      child: EventPhoto(event: event),
                    ),
                  ),
                ),
                SizedBox(width: 14 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5 * s,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 3 * s),
                      Text(
                        event.when,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13 * s,
                          color: AppColors.fieldIcon,
                        ),
                      ),
                      SizedBox(height: 8 * s),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3 * s),
                              child: SizedBox(
                                height: 6 * s,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    const ColoredBox(color: AppColors.stepTodo),
                                    FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: share,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: short
                                                ? const [
                                                    AppColors.badge,
                                                    AppColors.badgeRing,
                                                  ]
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
                          SizedBox(width: 10 * s),
                          Text(
                            '$signed/$capacity',
                            style: TextStyle(
                              fontSize: 12.5 * s,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        note,
                        style: TextStyle(
                          fontSize: 12 * s,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6 * s),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24 * s,
                  color: _hovered ? AppColors.brand : AppColors.fieldHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What volunteers have been doing on the coordinator's events, and the
/// latest message the coordinator sent. Tapping a row opens its event
/// ([onOpen] gets the title, or null for the coordinator's own message).
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.scale, required this.onOpen});

  final double scale;
  final ValueChanged<String?> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return ValueListenableBuilder(
      valueListenable: CoordinatorBoard.broadcasts,
      builder: (context, sent, _) {
        final items = [
          if (sent.isNotEmpty)
            (
              'You',
              'sent “${sent.last}”',
              'Just now',
              Icons.campaign_rounded,
              null,
            ),
          ...coordinatorActivity,
        ];
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 6 * s),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22 * s),
            border: Border.all(color: AppColors.white),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.06),
                blurRadius: 22 * s,
                offset: Offset(0, 8 * s),
              ),
            ],
          ),
          child: Column(
            children: [
              for (final (i, (who, what, ago, icon, event)) in items.indexed)
                Semantics(
                  button: true,
                  label: '$who $what, $ago',
                  excludeSemantics: true,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onOpen(event);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12 * s),
                        decoration: BoxDecoration(
                          border: i == items.length - 1
                              ? null
                              : const Border(
                                  bottom: BorderSide(
                                    color: AppColors.fieldBorder,
                                  ),
                                ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34 * s,
                              height: 34 * s,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: who == 'You'
                                    ? AppColors.brand
                                    : AppColors.roleChosenFill,
                              ),
                              child: Icon(
                                icon,
                                size: 17 * s,
                                color: who == 'You'
                                    ? AppColors.white
                                    : AppColors.brand,
                              ),
                            ),
                            SizedBox(width: 12 * s),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: who,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        TextSpan(text: ' $what'),
                                      ],
                                    ),
                                    style: TextStyle(
                                      fontSize: 14 * s,
                                      height: 1.4,
                                      color: AppColors.bodyText,
                                    ),
                                  ),
                                  SizedBox(height: 2 * s),
                                  Text(
                                    ago,
                                    style: TextStyle(
                                      fontSize: 12 * s,
                                      color: AppColors.fieldHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 6 * s),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20 * s,
                              color: AppColors.fieldHint,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Manage Event panel
// -----------------------------------------------------------------------------

/// Opens the panel for running [managed]: check volunteers in (for an event
/// happening now) or see who's signed up, and message them.
Future<void> showManageSheet(
  BuildContext context, {
  required ManagedEvent managed,
  required double scale,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.4),
    constraints: BoxConstraints(maxWidth: 640 * scale),
    builder: (context) => _ManageSheet(managed: managed, scale: scale),
  );
}

enum _Filter { all, here, waiting }

class _ManageSheet extends StatefulWidget {
  const _ManageSheet({required this.managed, required this.scale});

  final ManagedEvent managed;
  final double scale;

  @override
  State<_ManageSheet> createState() => _ManageSheetState();
}

class _ManageSheetState extends State<_ManageSheet> {
  _Filter _filter = _Filter.all;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _message() async {
    final sent = await showBroadcastSheet(
      context,
      scale: widget.scale,
      event: widget.managed,
    );
    if (sent != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.brandDark,
            content: Text('Message sent to $sent volunteers.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final managed = widget.managed;
    final event = managed.event;
    final height = MediaQuery.sizeOf(context).height;

    return Container(
      constraints: BoxConstraints(maxHeight: height * 0.9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30 * s)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ValueListenableBuilder(
        valueListenable: CoordinatorBoard.checkedIn,
        builder: (context, _, _) {
          final here = CoordinatorBoard.checkedInAt(managed.title);
          final query = _search.text.trim().toLowerCase();
          final roster = [
            for (final entry in managed.roster)
              if ((query.isEmpty || entry.name.toLowerCase().contains(query)) &&
                  switch (_filter) {
                    _Filter.all => true,
                    _Filter.here => here.contains(entry.name),
                    _Filter.waiting => !here.contains(entry.name),
                  })
                entry,
          ];
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner: the event's photo with its title.
              SizedBox(
                height: 132 * s,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    EventPhoto(event: event),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.splashScrim.withValues(alpha: 0.2),
                            AppColors.splashScrim.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10 * s,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20 * s,
                      right: 20 * s,
                      bottom: 14 * s,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            managed.ongoing ? 'ONGOING NOW' : event.when,
                            style: TextStyle(
                              fontSize: 11.5 * s,
                              letterSpacing: 1.1 * s,
                              fontWeight: FontWeight.w700,
                              color: AppColors.logoOnDark,
                            ),
                          ),
                          SizedBox(height: 4 * s),
                          Semantics(
                            header: true,
                            child: Text(
                              event.title,
                              style: TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 23 * s,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          Text(
                            '${event.hours} · ${event.address}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13 * s,
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20 * s, 16 * s, 20 * s, 8 * s),
                child: Row(
                  children: [
                    for (final (i, (value, label)) in [
                      if (managed.ongoing)
                        (
                          '${here.length}/${managed.roster.length}',
                          'Checked in',
                        )
                      else
                        (
                          '${managed.roster.length}/${event.capacity}',
                          'Signed up',
                        ),
                      (
                        '${{for (final e in managed.roster) e.role.name}.length}',
                        'Roles covered',
                      ),
                      if (managed.ongoing)
                        ('${managed.mealsSoFar}', 'Meals so far')
                      else
                        (event.duration, 'Duration'),
                    ].indexed) ...[
                      if (i > 0) SizedBox(width: 10 * s),
                      Expanded(
                        child: Semantics(
                          container: true,
                          label: '$value $label',
                          excludeSemantics: true,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10 * s),
                            decoration: BoxDecoration(
                              color: AppColors.roleChosenFill,
                              borderRadius: BorderRadius.circular(16 * s),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: 19 * s,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12 * s,
                                    color: AppColors.bodyText,
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
              Padding(
                padding: EdgeInsets.fromLTRB(20 * s, 6 * s, 20 * s, 4 * s),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44 * s,
                        padding: EdgeInsets.symmetric(horizontal: 14 * s),
                        decoration: BoxDecoration(
                          color: AppColors.socialFill,
                          borderRadius: BorderRadius.circular(22 * s),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 20 * s,
                              color: AppColors.fieldIcon,
                            ),
                            SizedBox(width: 8 * s),
                            Expanded(
                              child: TextField(
                                controller: _search,
                                onChanged: (_) => setState(() {}),
                                cursorColor: AppColors.brand,
                                style: TextStyle(
                                  fontSize: 14.5 * s,
                                  color: AppColors.ink,
                                ),
                                decoration: InputDecoration.collapsed(
                                  hintText: 'Find a volunteer',
                                  hintStyle: TextStyle(
                                    fontSize: 14.5 * s,
                                    color: AppColors.fieldHint,
                                  ),
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
              if (managed.ongoing)
                Padding(
                  padding: EdgeInsets.fromLTRB(20 * s, 8 * s, 20 * s, 0),
                  child: Wrap(
                    spacing: 8 * s,
                    runSpacing: 8 * s,
                    children: [
                      for (final (filter, label) in [
                        (_Filter.all, 'All ${managed.roster.length}'),
                        (_Filter.here, 'Here ${here.length}'),
                        (
                          _Filter.waiting,
                          'Not yet ${managed.roster.length - here.length}',
                        ),
                      ]) ...[
                        _FilterChip(
                          label: label,
                          selected: filter == _filter,
                          scale: s,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _filter = filter);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              Flexible(
                child: roster.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(28 * s),
                        child: Text(
                          'No volunteers here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15 * s,
                            color: AppColors.bodyText,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.fromLTRB(
                          20 * s,
                          8 * s,
                          20 * s,
                          8 * s,
                        ),
                        itemCount: roster.length,
                        itemBuilder: (context, i) => _RosterRow(
                          entry: roster[i],
                          eventTitle: managed.title,
                          canCheckIn: managed.ongoing,
                          here: here.contains(roster[i].name),
                          scale: s,
                        ),
                      ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, 0),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.fieldBorder)),
                ),
                child: SafeArea(
                  top: false,
                  minimum: EdgeInsets.only(bottom: 14 * s),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SheetButton(
                          icon: Icons.campaign_outlined,
                          label: switch (managed.status) {
                            EventStatus.ongoing => 'Message Team',
                            EventStatus.upcoming => 'Send Reminder',
                            EventStatus.completed => 'Send Thanks',
                          },
                          filled: true,
                          scale: s,
                          onTap: _message,
                        ),
                      ),
                      SizedBox(width: 10 * s),
                      Expanded(
                        child: _SheetButton(
                          icon: Icons.close_rounded,
                          label: 'Done',
                          filled: false,
                          scale: s,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 7 * s),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand : AppColors.white,
            borderRadius: BorderRadius.circular(16 * s),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.fieldBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13 * s,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// A volunteer on the roster: avatar, name and role, and Check In / Here.
class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.entry,
    required this.eventTitle,
    required this.canCheckIn,
    required this.here,
    required this.scale,
  });

  final RosterEntry entry;
  final String eventTitle;
  final bool canCheckIn;
  final bool here;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7 * s),
      child: Row(
        children: [
          Container(
            width: 40 * s,
            height: 40 * s,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: entry.colors,
              ),
            ),
            child: Text(
              entry.initials,
              style: TextStyle(
                fontSize: 13.5 * s,
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
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 2 * s),
                Row(
                  children: [
                    Icon(
                      entry.role.icon,
                      size: 13 * s,
                      color: AppColors.leafLight,
                    ),
                    SizedBox(width: 4 * s),
                    Flexible(
                      child: Text(
                        entry.role.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          if (canCheckIn)
            Semantics(
              container: true,
              button: true,
              toggled: here,
              label: here
                  ? '${entry.name} is checked in'
                  : 'Check in ${entry.name}',
              excludeSemantics: true,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    CoordinatorBoard.toggleCheckIn(eventTitle, entry.name);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * s,
                      vertical: 8 * s,
                    ),
                    decoration: BoxDecoration(
                      color: here ? AppColors.roleChosenFill : AppColors.brand,
                      borderRadius: BorderRadius.circular(14 * s),
                      border: Border.all(
                        color: here
                            ? AppColors.roleChosenBorder
                            : AppColors.brand,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          here
                              ? Icons.check_circle_rounded
                              : Icons.login_rounded,
                          size: 15 * s,
                          color: here ? AppColors.brand : AppColors.white,
                        ),
                        SizedBox(width: 5 * s),
                        Text(
                          here ? 'Here' : 'Check In',
                          style: TextStyle(
                            fontSize: 12.5 * s,
                            fontWeight: FontWeight.w700,
                            color: here ? AppColors.brand : AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * s,
                vertical: 5 * s,
              ),
              decoration: BoxDecoration(
                color: AppColors.roleChosenFill,
                borderRadius: BorderRadius.circular(12 * s),
              ),
              child: Text(
                'Signed up',
                style: TextStyle(
                  fontSize: 12 * s,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.scale,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
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
            height: 52 * s,
            decoration: BoxDecoration(
              color: filled ? AppColors.brand : AppColors.socialFill,
              borderRadius: BorderRadius.circular(26 * s),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 19 * s,
                  color: filled ? AppColors.white : AppColors.ink,
                ),
                SizedBox(width: 8 * s),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5 * s,
                      fontWeight: FontWeight.w700,
                      color: filled ? AppColors.white : AppColors.ink,
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

// -----------------------------------------------------------------------------
// Message volunteers
// -----------------------------------------------------------------------------

/// Opens the sheet for messaging volunteers, about [event] or about all of
/// the coordinator's events. Returns how many volunteers it went to.
Future<int?> showBroadcastSheet(
  BuildContext context, {
  required double scale,
  ManagedEvent? event,
  String? recipient,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.4),
    constraints: BoxConstraints(maxWidth: 600 * scale),
    builder: (context) =>
        _BroadcastSheet(scale: scale, event: event, recipient: recipient),
  );
}

class _BroadcastSheet extends StatefulWidget {
  const _BroadcastSheet({required this.scale, this.event, this.recipient});

  final double scale;
  final ManagedEvent? event;

  /// One volunteer to message, instead of a group.
  final String? recipient;

  @override
  State<_BroadcastSheet> createState() => _BroadcastSheetState();
}

class _BroadcastSheetState extends State<_BroadcastSheet> {
  final _text = TextEditingController();

  /// null: everyone across the coordinator's events.
  late ManagedEvent? _audience = widget.event;

  static const _templates = [
    'Thank you for today!',
    'Please bring a water bottle.',
    'We start in one hour.',
    'Change of venue, details soon.',
  ];

  int get _count => widget.recipient != null
      ? 1
      : _audience?.roster.length ?? coordinatorVolunteers;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    CoordinatorBoard.broadcast(text);
    Navigator.of(context).pop(_count);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final canSend = _text.text.trim().isNotEmpty;
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
                  widget.recipient == null
                      ? 'Message Volunteers'
                      : 'Message ${widget.recipient}',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 22 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 4 * s),
                Text(
                  'They’ll get it as a notification and in their inbox.',
                  style: TextStyle(
                    fontSize: 13.5 * s,
                    color: AppColors.fieldIcon,
                  ),
                ),
                if (widget.recipient == null) ...[
                  SizedBox(height: 16 * s),
                  Text(
                    'Send to',
                    style: TextStyle(
                      fontSize: 14.5 * s,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 8 * s),
                  Wrap(
                    spacing: 8 * s,
                    runSpacing: 8 * s,
                    children: [
                      _FilterChip(
                        label: 'Everyone ($coordinatorVolunteers)',
                        selected: _audience == null,
                        scale: s,
                        onTap: () => setState(() => _audience = null),
                      ),
                      for (final managed in CoordinatorBoard.active)
                        _FilterChip(
                          label: '${managed.title} (${managed.roster.length})',
                          selected: _audience == managed,
                          scale: s,
                          onTap: () => setState(() => _audience = managed),
                        ),
                    ],
                  ),
                ],
                SizedBox(height: 16 * s),
                Container(
                  padding: EdgeInsets.all(16 * s),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18 * s),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: TextField(
                    controller: _text,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [LengthLimitingTextInputFormatter(240)],
                    onChanged: (_) => setState(() {}),
                    cursorColor: AppColors.brand,
                    style: TextStyle(
                      fontSize: 15.5 * s,
                      height: 1.45,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Write a short message...',
                      hintStyle: TextStyle(
                        fontSize: 15.5 * s,
                        color: AppColors.fieldHint,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10 * s),
                Wrap(
                  spacing: 8 * s,
                  runSpacing: 8 * s,
                  children: [
                    for (final template in _templates)
                      Semantics(
                        button: true,
                        label: template,
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _text.value = TextEditingValue(
                                text: template,
                                selection: TextSelection.collapsed(
                                  offset: template.length,
                                ),
                              );
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 11 * s,
                              vertical: 7 * s,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.roleChosenFill,
                              borderRadius: BorderRadius.circular(14 * s),
                            ),
                            child: Text(
                              template,
                              style: TextStyle(
                                fontSize: 12.5 * s,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 20 * s),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: canSend ? 1 : 0.5,
                  child: _SheetButton(
                    icon: Icons.send_rounded,
                    label: widget.recipient == null
                        ? 'Send to $_count volunteers'
                        : 'Send to ${widget.recipient}',
                    filled: true,
                    scale: s,
                    onTap: canSend ? _send : () {},
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
