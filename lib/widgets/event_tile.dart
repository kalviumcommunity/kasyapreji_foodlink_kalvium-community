import 'package:flutter/material.dart';

import '../data/event_plans.dart';
import '../data/sample_events.dart';
import '../theme/app_colors.dart';

/// An event: a row with a square photo (phones), or a [card] with
/// the photo on top (laptops). Lifts on hover and dips when pressed, and
/// shows a green check on the photo once the volunteer has joined.
///
/// The photo is a [Hero] tagged [heroTag], so it grows into the details
/// page when the tile is opened.
class EventTile extends StatefulWidget {
  const EventTile({
    super.key,
    required this.event,
    required this.scale,
    required this.card,
    required this.onTap,
    required this.heroTag,
  });

  final VolunteerEvent event;
  final double scale;
  final bool card;
  final VoidCallback onTap;
  final Object heroTag;

  @override
  State<EventTile> createState() => _EventTileState();
}

class _EventTileState extends State<EventTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final event = widget.event;
    final card = widget.card;

    Widget photo(double radius) => Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: widget.heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: AnimatedScale(
              scale: _hovered ? 1.06 : 1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              child: EventPhoto(event: event),
            ),
          ),
        ),
        Positioned(
          right: 8 * s,
          top: 8 * s,
          child: _JoinedCheck(title: event.title, scale: s),
        ),
      ],
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
                        AspectRatio(
                          aspectRatio: 16 / 10,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              photo(16 * s),
                              Positioned(
                                left: 10 * s,
                                top: 10 * s,
                                child: EventCategoryTag(
                                  category: event.category,
                                  scale: s,
                                  shadow: true,
                                ),
                              ),
                            ],
                          ),
                        ),
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

/// The event's photo, cropped to fill, with a gradient while it loads.
class EventPhoto extends StatelessWidget {
  const EventPhoto({super.key, required this.event});

  final VolunteerEvent event;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
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
    );
  }
}

/// Pill naming the event's category, in that category's colours.
class EventCategoryTag extends StatelessWidget {
  const EventCategoryTag({
    super.key,
    required this.category,
    required this.scale,
    this.fontSize = 12,
    this.shadow = false,
  });

  final EventCategory category;
  final double scale;
  final double fontSize;

  /// Lifts the tag off a photo.
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final size = fontSize * s;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.95,
        vertical: size * 0.45,
      ),
      decoration: BoxDecoration(
        color: category.fill,
        borderRadius: BorderRadius.circular(size * 2),
        boxShadow: [
          if (shadow)
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.14),
              blurRadius: 8 * s,
              offset: Offset(0, 2 * s),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: size * 1.1, color: category.text),
          SizedBox(width: size * 0.4),
          Text(
            category.label,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w600,
              color: category.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small green check that pops onto the photo of an event the volunteer
/// has joined.
class _JoinedCheck extends StatelessWidget {
  const _JoinedCheck({required this.title, required this.scale});

  final String title;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return ValueListenableBuilder(
      valueListenable: EventPlans.joined,
      builder: (context, joined, _) => AnimatedScale(
        scale: joined.contains(title) ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: Container(
          width: 24 * s,
          height: 24 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.brand,
            border: Border.all(color: AppColors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.25),
                blurRadius: 6 * s,
              ),
            ],
          ),
          child: Icon(
            Icons.check_rounded,
            size: 14 * s,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
