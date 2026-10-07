import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/community.dart';
import '../data/event_plans.dart';
import '../data/sample_events.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'event_tile.dart';
import 'foodlink_logo.dart';

/// Pieces of the Community screen: avatars, posts, comments and stories.

/// A tab along the top of Community: white with a green underline when
/// chosen, soft grey otherwise.
class CommunityTabButton extends StatefulWidget {
  const CommunityTabButton({
    super.key,
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
  State<CommunityTabButton> createState() => _CommunityTabButtonState();
}

class _CommunityTabButtonState extends State<CommunityTabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final selected = widget.selected;
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
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            height: 52 * s,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.white
                  : _hovered
                  ? AppColors.roleChosenFill
                  : AppColors.socialFill.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16 * s),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: selected ? 0.08 : 0),
                  blurRadius: 14 * s,
                  offset: Offset(0, 4 * s),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 260),
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 16.5 * s,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.brand : AppColors.fieldIcon,
                  ),
                  child: Text(widget.label),
                ),
                // The green underline from the Figma.
                Positioned(
                  bottom: 5 * s,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    width: selected ? 64 * s : 0,
                    height: 3 * s,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.accentGradient,
                      ),
                      borderRadius: BorderRadius.circular(2 * s),
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

/// A member's round avatar: the FoodLink logo for FoodLink, a person for
/// the volunteer and members without a photo colour, otherwise their
/// initials. Organisations get a small leaf badge.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.member, required this.size});

  final CommunityMember member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final d = size;
    final Widget inner;
    if (member.name == foodLink.name) {
      inner = FoodLinkLogo(width: d * 0.5, color: AppColors.logoOnDark);
    } else if (member.you || identical(member.colors, AppColors.avatar)) {
      inner = Icon(
        Icons.person_rounded,
        size: d * 0.58,
        color: const Color(0xFFF3E4D6),
      );
    } else {
      inner = Text(
        member.initials,
        style: TextStyle(
          fontSize: d * 0.34,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      );
    }
    return SizedBox.square(
      dimension: d,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: d,
            height: d,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: member.colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: member.colors.last.withValues(alpha: 0.25),
                  blurRadius: d * 0.2,
                  offset: Offset(0, d * 0.06),
                ),
              ],
            ),
            child: inner,
          ),
          if (member.organisation && member.name != foodLink.name)
            Positioned(
              right: -d * 0.04,
              bottom: -d * 0.04,
              child: Container(
                width: d * 0.38,
                height: d * 0.38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brand,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: Icon(
                  Icons.eco_rounded,
                  size: d * 0.22,
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Share a moment from your volunteering..." at the top of the feed.
class ComposerPrompt extends StatefulWidget {
  const ComposerPrompt({super.key, required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  State<ComposerPrompt> createState() => _ComposerPromptState();
}

class _ComposerPromptState extends State<ComposerPrompt> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Semantics(
      button: true,
      label: 'Share a moment',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.fromLTRB(12 * s, 12 * s, 12 * s, 12 * s),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(22 * s),
              border: Border.all(
                color: _hovered
                    ? AppColors.roleChosenBorder
                    : AppColors.fieldBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(
                    alpha: _hovered ? 0.12 : 0.06,
                  ),
                  blurRadius: 20 * s,
                  offset: Offset(0, 6 * s),
                ),
              ],
            ),
            child: Row(
              children: [
                MemberAvatar(member: you, size: 42 * s),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Text(
                    'Share a moment from your volunteering...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15 * s,
                      color: AppColors.fieldHint,
                    ),
                  ),
                ),
                SizedBox(width: 8 * s),
                Container(
                  width: 40 * s,
                  height: 40 * s,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.roleChosenFill,
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 20 * s,
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

/// One post: the author and time with a menu, the text, a photo you can
/// double-tap to like, the event it's about, and like, comment and save.
class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.scale,
    required this.onComments,
    required this.onMenu,
    required this.onOpenEvent,
  });

  final CommunityPost post;
  final double scale;
  final VoidCallback onComments;

  /// 'save', 'link', 'report' or 'delete'.
  final ValueChanged<String> onMenu;
  final void Function(VolunteerEvent event, Object heroTag) onOpenEvent;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  /// The big heart that pops over the photo on a double tap.
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _doubleTapLike() {
    HapticFeedback.mediumImpact();
    CommunityFeed.like(widget.post.id);
    _pop.forward(from: 0);
  }

  VolunteerEvent? get _event {
    final title = widget.post.event;
    if (title == null) return null;
    for (final event in sampleEvents) {
      if (event.title == title) return event;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final post = widget.post;
    final author = post.author;
    final liked = CommunityFeed.hasLiked(post.id);
    final saved = CommunityFeed.hasSaved(post.id);
    final event = _event;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            MemberAvatar(member: author, size: 54 * s),
            SizedBox(width: 14 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          author.you ? '${author.name} (you)' : author.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17 * s,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (author.organisation) ...[
                        SizedBox(width: 5 * s),
                        Icon(
                          Icons.verified_rounded,
                          size: 16 * s,
                          color: AppColors.leafLight,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 3 * s),
                  Text(
                    post.time,
                    style: TextStyle(
                      fontSize: 14 * s,
                      color: AppColors.fieldIcon,
                    ),
                  ),
                ],
              ),
            ),
            _PostMenu(
              post: post,
              saved: saved,
              scale: s,
              onSelected: widget.onMenu,
            ),
          ],
        ),
        SizedBox(height: 14 * s),
        Text.rich(
          TextSpan(
            text: post.text,
            children: [
              if (post.heart)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsets.only(left: 6 * s),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 18 * s,
                      color: AppColors.leafLight,
                    ),
                  ),
                ),
            ],
          ),
          style: TextStyle(
            fontSize: 16.5 * s,
            height: 1.5,
            color: AppColors.ink.withValues(alpha: 0.88),
          ),
        ),
        if (post.photo case final photo?) ...[
          SizedBox(height: 14 * s),
          Semantics(
            image: true,
            label: 'Photo. Double tap to like',
            child: GestureDetector(
              onDoubleTap: _doubleTapLike,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20 * s),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(photo, fit: BoxFit.cover),
                      AnimatedBuilder(
                        animation: _pop,
                        builder: (context, _) {
                          if (!_pop.isAnimating) return const SizedBox();
                          final t = _pop.value;
                          final grow = Curves.elasticOut.transform(
                            (t / 0.6).clamp(0.0, 1.0),
                          );
                          final fade = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
                          return Center(
                            child: Opacity(
                              opacity: fade.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: 0.3 + 0.9 * grow,
                                child: Icon(
                                  Icons.favorite_rounded,
                                  size: 90 * s,
                                  color: AppColors.white,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.ink.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        if (event != null) ...[
          SizedBox(height: 12 * s),
          _EventLink(
            event: event,
            heroTag: 'community/${post.id}',
            scale: s,
            onTap: () => widget.onOpenEvent(event, 'community/${post.id}'),
          ),
        ],
        SizedBox(height: 10 * s),
        Row(
          children: [
            _ActionButton(
              label: liked ? 'Unlike' : 'Like',
              icon: liked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: liked ? AppColors.badge : AppColors.bodyText,
              count: CommunityFeed.likesOf(post),
              scale: s,
              bounce: true,
              active: liked,
              onTap: () {
                HapticFeedback.selectionClick();
                CommunityFeed.toggleLike(post.id);
              },
            ),
            SizedBox(width: 18 * s),
            _ActionButton(
              label: 'Comments',
              icon: Icons.chat_bubble_outline_rounded,
              color: AppColors.bodyText,
              count: post.commentCount,
              scale: s,
              onTap: widget.onComments,
            ),
            const Spacer(),
            _ActionButton(
              label: saved ? 'Remove from saved' : 'Save post',
              icon: saved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: saved ? AppColors.brand : AppColors.bodyText,
              scale: s,
              bounce: true,
              active: saved,
              onTap: () {
                HapticFeedback.selectionClick();
                CommunityFeed.toggleSave(post.id);
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// The "..." menu on a post.
class _PostMenu extends StatelessWidget {
  const _PostMenu({
    required this.post,
    required this.saved,
    required this.scale,
    required this.onSelected,
  });

  final CommunityPost post;
  final bool saved;
  final double scale;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    PopupMenuItem<String> item(
      String value,
      IconData icon,
      String label, {
      Color color = AppColors.ink,
    }) => PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
    return PopupMenuButton<String>(
      tooltip: 'More options',
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 26 * s,
        color: AppColors.fieldIcon,
      ),
      color: AppColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) => [
        item(
          'save',
          saved ? Icons.bookmark_remove_outlined : Icons.bookmark_add_outlined,
          saved ? 'Remove from saved' : 'Save post',
        ),
        item('link', Icons.link_rounded, 'Copy link'),
        if (post.author.you)
          item(
            'delete',
            Icons.delete_outline_rounded,
            'Delete post',
            color: AppColors.error,
          )
        else
          item('report', Icons.flag_outlined, 'Report post'),
      ],
    );
  }
}

/// A heart, comment or bookmark with an optional count. [bounce] makes the
/// icon spring when it turns [active].
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.scale,
    required this.onTap,
    this.count,
    this.bounce = false,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int? count;
  final double scale;
  final bool bounce;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final iconWidget = Icon(
      icon,
      key: ValueKey(icon),
      size: 24 * s,
      color: color,
    );
    return Semantics(
      button: true,
      label: count == null ? label : '$label, $count',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8 * s, horizontal: 4 * s),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                bounce
                    ? AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                              scale: CurvedAnimation(
                                parent: animation,
                                curve: active
                                    ? Curves.elasticOut
                                    : Curves.easeOut,
                              ),
                              child: child,
                            ),
                        child: iconWidget,
                      )
                    : iconWidget,
                if (count != null) ...[
                  SizedBox(width: 8 * s),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.4),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Text(
                      '$count',
                      key: ValueKey(count),
                      style: TextStyle(
                        fontSize: 16 * s,
                        fontWeight: FontWeight.w500,
                        color: AppColors.bodyText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The event a post is about, as a small card that opens its details.
class _EventLink extends StatefulWidget {
  const _EventLink({
    required this.event,
    required this.heroTag,
    required this.scale,
    required this.onTap,
  });

  final VolunteerEvent event;
  final Object heroTag;
  final double scale;
  final VoidCallback onTap;

  @override
  State<_EventLink> createState() => _EventLinkState();
}

class _EventLinkState extends State<_EventLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final event = widget.event;
    return ValueListenableBuilder(
      valueListenable: EventPlans.joined,
      builder: (context, joined, _) {
        final going = joined.contains(event.title);
        return Semantics(
          button: true,
          label: 'Event: ${event.title}',
          excludeSemantics: true,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.all(8 * s),
                decoration: BoxDecoration(
                  color: _hovered
                      ? AppColors.roleChosenFill
                      : AppColors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16 * s),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 48 * s,
                      child: Hero(
                        tag: widget.heroTag,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12 * s),
                          child: EventPhoto(event: event),
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5 * s,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 2 * s),
                          Text(
                            '${event.when} · ${event.place}',
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
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10 * s,
                        vertical: 6 * s,
                      ),
                      decoration: BoxDecoration(
                        color: going
                            ? AppColors.roleChosenFill
                            : AppColors.brand,
                        borderRadius: BorderRadius.circular(12 * s),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (going) ...[
                            Icon(
                              Icons.check_rounded,
                              size: 14 * s,
                              color: AppColors.brand,
                            ),
                            SizedBox(width: 3 * s),
                          ],
                          Text(
                            going ? 'Going' : 'View',
                            style: TextStyle(
                              fontSize: 12.5 * s,
                              fontWeight: FontWeight.w700,
                              color: going ? AppColors.brand : AppColors.white,
                            ),
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
      },
    );
  }
}

/// The grey grab handle at the top of a sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.fieldBorder,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// A small green count, e.g. beside "Comments".
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.scale});

  final int count;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 2 * s),
      decoration: BoxDecoration(
        color: AppColors.roleChosenFill,
        borderRadius: BorderRadius.circular(10 * s),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 13 * s,
          fontWeight: FontWeight.w700,
          color: AppColors.brand,
        ),
      ),
    );
  }
}

/// A pill to pick, e.g. an event to tag.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
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
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand : AppColors.white,
            borderRadius: BorderRadius.circular(18 * s),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.fieldBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_rounded : icon,
                size: 15 * s,
                color: selected ? AppColors.white : AppColors.brand,
              ),
              SizedBox(width: 6 * s),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5 * s,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.white : AppColors.ink,
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

/// One comment: the avatar, then a bubble with the name and text.
class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment, required this.scale});

  final CommunityComment comment;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final author = comment.author;
    return Padding(
      padding: EdgeInsets.only(bottom: 14 * s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MemberAvatar(member: author, size: 36 * s),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, 11 * s),
                  decoration: BoxDecoration(
                    color: author.you
                        ? AppColors.roleChosenFill
                        : AppColors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(18 * s),
                      bottomLeft: Radius.circular(18 * s),
                      bottomRight: Radius.circular(18 * s),
                      topLeft: Radius.circular(4 * s),
                    ),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.you ? '${author.name} (you)' : author.name,
                        style: TextStyle(
                          fontSize: 14 * s,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 3 * s),
                      Text(
                        comment.text,
                        style: TextStyle(
                          fontSize: 14.5 * s,
                          height: 1.4,
                          color: AppColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 6 * s, top: 4 * s),
                  child: Text(
                    '${comment.time} · ${author.about}',
                    style: TextStyle(
                      fontSize: 12 * s,
                      color: AppColors.fieldHint,
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

/// A story's photo, large, with its tag, title, author and reading time
/// over a dark fade. Zooms gently on hover.
class FeaturedStoryCard extends StatefulWidget {
  const FeaturedStoryCard({
    super.key,
    required this.story,
    required this.scale,
    required this.height,
    required this.onTap,
  });

  final CommunityStory story;
  final double scale;
  final double height;
  final VoidCallback onTap;

  @override
  State<FeaturedStoryCard> createState() => _FeaturedStoryCardState();
}

class _FeaturedStoryCardState extends State<FeaturedStoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final story = widget.story;
    return Semantics(
      button: true,
      label: 'Story: ${story.title}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: widget.height,
            transform: Matrix4.translationValues(0, _hovered ? -3 * s : 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26 * s),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(
                    alpha: _hovered ? 0.28 : 0.18,
                  ),
                  blurRadius: 30 * s,
                  offset: Offset(0, 14 * s),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'story/${story.title}',
                  child: AnimatedScale(
                    scale: _hovered ? 1.05 : 1,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    child: Image.asset(
                      story.photo,
                      fit: BoxFit.cover,
                      alignment: story.focus,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.splashScrim.withValues(alpha: 0.1),
                        AppColors.splashScrim.withValues(alpha: 0.15),
                        AppColors.splashScrim.withValues(alpha: 0.85),
                      ],
                      stops: const [0, 0.4, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 18 * s,
                  top: 16 * s,
                  child: Row(
                    children: [
                      StoryTag(label: 'Featured', scale: s, solid: true),
                      SizedBox(width: 6 * s),
                      StoryTag(label: story.tag, scale: s),
                    ],
                  ),
                ),
                Positioned(
                  left: 20 * s,
                  right: 20 * s,
                  bottom: 18 * s,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 24 * s,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: 6 * s),
                      Text(
                        story.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14 * s,
                          height: 1.4,
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      SizedBox(height: 12 * s),
                      Row(
                        children: [
                          MemberAvatar(member: story.author, size: 28 * s),
                          SizedBox(width: 8 * s),
                          Flexible(
                            child: Text(
                              '${story.author.name} · ${story.minutes} min read',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13 * s,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
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
    );
  }
}

/// A small tag on a story: frosted, or [solid] amber for "Featured".
class StoryTag extends StatelessWidget {
  const StoryTag({
    super.key,
    required this.label,
    required this.scale,
    this.solid = false,
  });

  final String label;
  final double scale;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        color: solid ? AppColors.sun : AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12 * s),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12 * s,
          fontWeight: FontWeight.w700,
          color: solid ? AppColors.white : AppColors.brand,
        ),
      ),
    );
  }
}

/// A story as a row: the photo, then its tag, title, summary and author.
class StoryRow extends StatefulWidget {
  const StoryRow({
    super.key,
    required this.story,
    required this.scale,
    required this.onTap,
    this.card = false,
  });

  final CommunityStory story;
  final double scale;
  final VoidCallback onTap;
  final bool card;

  @override
  State<StoryRow> createState() => _StoryRowState();
}

class _StoryRowState extends State<StoryRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final story = widget.story;
    return Semantics(
      button: true,
      label: 'Story: ${story.title}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            transform: Matrix4.translationValues(
              0,
              widget.card && _hovered ? -3 * s : 0,
              0,
            ),
            padding: widget.card ? EdgeInsets.all(12 * s) : EdgeInsets.zero,
            decoration: widget.card
                ? BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(22 * s),
                    border: Border.all(color: AppColors.white),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand.withValues(
                          alpha: _hovered ? 0.14 : 0.06,
                        ),
                        blurRadius: 24 * s,
                        offset: Offset(0, 10 * s),
                      ),
                    ],
                  )
                : null,
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 100 * s,
                  child: Hero(
                    tag: 'story/${story.title}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18 * s),
                      child: AnimatedScale(
                        scale: _hovered ? 1.07 : 1,
                        duration: const Duration(milliseconds: 400),
                        child: Image.asset(
                          story.photo,
                          fit: BoxFit.cover,
                          alignment: story.focus,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.tag.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.5 * s,
                          letterSpacing: 1.2 * s,
                          fontWeight: FontWeight.w700,
                          color: AppColors.leafLight,
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        story.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.5 * s,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 6 * s),
                      Row(
                        children: [
                          MemberAvatar(member: story.author, size: 20 * s),
                          SizedBox(width: 6 * s),
                          Flexible(
                            child: Text(
                              '${story.author.name} · ${story.minutes} min',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13 * s,
                                color: AppColors.fieldIcon,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6 * s),
                Transform.rotate(
                  angle: _hovered ? -math.pi / 12 : 0,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 20 * s,
                    color: _hovered ? AppColors.brand : AppColors.fieldHint,
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
