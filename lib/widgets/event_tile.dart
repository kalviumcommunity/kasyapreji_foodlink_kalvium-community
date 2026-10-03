import 'package:flutter/material.dart';

import '../data/sample_events.dart';
import '../theme/app_colors.dart';

/// An event: a row with a square photo (phones), or a [card] with
/// the photo on top (laptops). Lifts on hover and dips when pressed.
class EventTile extends StatefulWidget {
  const EventTile({
    super.key,
    required this.event,
    required this.scale,
    required this.card,
    required this.onTap,
  });

  final VolunteerEvent event;
  final double scale;
  final bool card;
  final VoidCallback onTap;

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
                        AspectRatio(
                          aspectRatio: 16 / 10,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              photo(16 * s),
                              Positioned(
                                left: 10 * s,
                                top: 10 * s,
                                child: _CategoryTag(
                                  label: event.category.label,
                                  scale: s,
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

/// Frosted label naming the event's category, over a card's photo.
class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20 * s),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.12),
            blurRadius: 8 * s,
            offset: Offset(0, 2 * s),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12 * s,
          fontWeight: FontWeight.w600,
          color: AppColors.brand,
        ),
      ),
    );
  }
}
