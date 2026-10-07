import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Someone who posts in the community: a volunteer or an organisation.
class CommunityMember {
  const CommunityMember({
    required this.name,
    required this.about,
    this.colors = AppColors.avatar,
    this.organisation = false,
    this.you = false,
  });

  final String name;

  /// A short line under their name in comments, e.g. "Volunteer · 24 events".
  final String about;

  /// Avatar gradient, top to bottom.
  final List<Color> colors;

  /// Organisations get a leaf badge; FoodLink itself shows its logo.
  final bool organisation;

  /// The volunteer using the app.
  final bool you;

  String get initials => name
      .split(' ')
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0])
      .join();
}

/// The volunteer using the app, until accounts exist.
const you = CommunityMember(
  name: 'Agnibha',
  about: 'Volunteer · 12 events',
  you: true,
);

const foodLink = CommunityMember(
  name: 'FoodLink',
  about: 'Official',
  organisation: true,
  colors: [AppColors.brand, AppColors.brandDark],
);

const _riya = CommunityMember(
  name: 'Riya Sharma',
  about: 'Volunteer · 24 events',
);
const _arjun = CommunityMember(
  name: 'Arjun Mehta',
  about: 'Volunteer · 9 events',
  colors: [Color(0xFF7FA6C4), Color(0xFF3D6683)],
);
const _priya = CommunityMember(
  name: 'Priya Nair',
  about: 'Garden lead · 31 events',
  colors: [Color(0xFF9DBB80), Color(0xFF4F7539)],
);
const _kabir = CommunityMember(
  name: 'Kabir Das',
  about: 'Volunteer · 15 events',
  colors: [Color(0xFFE0A63A), Color(0xFFB0702A)],
);
const _ananya = CommunityMember(
  name: 'Ananya Roy',
  about: 'Volunteer · 18 events',
  colors: [Color(0xFFD99A8E), Color(0xFF9A5448)],
);
const _hopeKitchen = CommunityMember(
  name: 'Hope Kitchen Trust',
  about: 'Organiser',
  organisation: true,
  colors: [AppColors.earthLight, AppColors.earthDark],
);
const _riverside = CommunityMember(
  name: 'Riverside Food Bank',
  about: 'Organiser',
  organisation: true,
  colors: [Color(0xFF7FA6C4), Color(0xFF3D6683)],
);
const _greenRoots = CommunityMember(
  name: 'Green Roots Collective',
  about: 'Organiser',
  organisation: true,
  colors: [AppColors.leafLight, AppColors.leafDark],
);

class CommunityComment {
  const CommunityComment({
    required this.author,
    required this.text,
    required this.time,
  });

  final CommunityMember author;
  final String text;
  final String time;
}

/// A post in the feed.
class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.author,
    required this.time,
    required this.text,
    this.heart = false,
    this.photo,
    this.event,
    required this.likes,
    this.comments = const [],
    this.earlierComments = 0,
  });

  final String id;
  final CommunityMember author;
  final String time;
  final String text;

  /// Ends the text with a small green heart, as in the Figma.
  final bool heart;
  final String? photo;

  /// Title of an event the post links to.
  final String? event;

  /// Likes from other people (the volunteer's own like is added on top).
  final int likes;

  /// The latest comments, oldest first.
  final List<CommunityComment> comments;

  /// Older comments not loaded, counted in the total.
  final int earlierComments;

  int get commentCount => earlierComments + comments.length;

  CommunityPost withComment(CommunityComment comment) => CommunityPost(
    id: id,
    author: author,
    time: time,
    text: text,
    heart: heart,
    photo: photo,
    event: event,
    likes: likes,
    comments: [...comments, comment],
    earlierComments: earlierComments,
  );
}

/// The community feed and what the volunteer has liked or saved, kept in
/// memory until it comes from the database. The feed and comment sheets
/// listen, so changes show everywhere at once.
class CommunityFeed {
  CommunityFeed._();

  static final ValueNotifier<List<CommunityPost>> posts = ValueNotifier([
    ..._samplePosts,
  ]);
  static final ValueNotifier<Set<String>> liked = ValueNotifier({});
  static final ValueNotifier<Set<String>> saved = ValueNotifier({});

  static int _next = 0;

  static CommunityPost? byId(String id) {
    for (final post in posts.value) {
      if (post.id == id) return post;
    }
    return null;
  }

  static bool hasLiked(String id) => liked.value.contains(id);
  static bool hasSaved(String id) => saved.value.contains(id);

  static int likesOf(CommunityPost post) =>
      post.likes + (hasLiked(post.id) ? 1 : 0);

  static void toggleLike(String id) => _toggle(liked, id);
  static void toggleSave(String id) => _toggle(saved, id);

  /// Likes [id] without un-liking it (a double tap on the photo).
  static void like(String id) {
    if (!hasLiked(id)) liked.value = {...liked.value, id};
  }

  static void comment(String id, String text) {
    posts.value = [
      for (final post in posts.value)
        post.id == id
            ? post.withComment(
                CommunityComment(author: you, text: text, time: 'Just now'),
              )
            : post,
    ];
  }

  /// Puts the volunteer's post at the top of the feed.
  static CommunityPost share(String text, {String? photo, String? event}) {
    final post = CommunityPost(
      id: 'you-${_next++}',
      author: you,
      time: 'Just now',
      text: text,
      photo: photo,
      event: event,
      likes: 0,
    );
    posts.value = [post, ...posts.value];
    return post;
  }

  static void delete(String id) {
    posts.value = [
      for (final post in posts.value)
        if (post.id != id) post,
    ];
  }

  static void _toggle(ValueNotifier<Set<String>> set, String id) {
    final next = {...set.value};
    if (!next.remove(id)) next.add(id);
    set.value = next;
  }

  @visibleForTesting
  static void reset() {
    posts.value = [..._samplePosts];
    liked.value = {};
    saved.value = {};
    _next = 0;
  }
}

const _samplePosts = [
  CommunityPost(
    id: 'riya-1',
    author: _riya,
    time: '2h ago',
    text: 'A little help goes a long way',
    heart: true,
    photo: 'assets/images/impact_packing.jpg',
    event: 'Weekend Meal Packing',
    likes: 124,
    earlierComments: 9,
    comments: [
      CommunityComment(
        author: _kabir,
        text: 'Such a great team today. Same time next week?',
        time: '1h ago',
      ),
      CommunityComment(
        author: _hopeKitchen,
        text: 'Thank you Riya! 400 kits went out this morning.',
        time: '1h ago',
      ),
      CommunityComment(
        author: _ananya,
        text: 'Love this. Count me in for the next one!',
        time: '45m ago',
      ),
    ],
  ),
  CommunityPost(
    id: 'foodlink-1',
    author: foodLink,
    time: '1d ago',
    text:
        'Grateful to all our volunteers! In September you shared 7,950 meals '
        'across 14 events. Thank you for every hour you gave.',
    photo: 'assets/images/onboarding_community_meal.jpg',
    likes: 342,
    earlierComments: 26,
    comments: [
      CommunityComment(
        author: _priya,
        text: 'Proud to be part of this community.',
        time: '20h ago',
      ),
      CommunityComment(
        author: _arjun,
        text: 'Here’s to an even bigger next month!',
        time: '18h ago',
      ),
    ],
  ),
  CommunityPost(
    id: 'arjun-1',
    author: _arjun,
    time: '1d ago',
    text:
        'My first gleaning trip! We saved 300 kg of greens from the fields '
        'before noon. Muddy shoes, full heart.',
    photo: 'assets/images/event_harvest_greens.jpg',
    event: 'Harvest Gleaning Day',
    likes: 87,
    earlierComments: 4,
    comments: [
      CommunityComment(
        author: _greenRoots,
        text: 'Welcome to the gleaning crew, Arjun!',
        time: '22h ago',
      ),
    ],
  ),
  CommunityPost(
    id: 'hope-1',
    author: _hopeKitchen,
    time: '2d ago',
    text:
        'We still need a few more hands for Shelter Dinner Service. If you '
        'can spare an evening, tap below to join.',
    event: 'Shelter Dinner Service',
    likes: 56,
    earlierComments: 6,
    comments: [
      CommunityComment(
        author: _kabir,
        text: 'Signed up for the second half!',
        time: '1d ago',
      ),
    ],
  ),
  CommunityPost(
    id: 'priya-1',
    author: _priya,
    time: '3d ago',
    text:
        'The raised beds we built are already sprouting. Spinach, okra and '
        'tomatoes for the community kitchen by next month.',
    photo: 'assets/images/notifications_community_farm.jpg',
    event: 'Urban Garden Setup',
    likes: 156,
    earlierComments: 11,
    comments: [
      CommunityComment(
        author: _riya,
        text: 'This is beautiful, Priya!',
        time: '2d ago',
      ),
    ],
  ),
  CommunityPost(
    id: 'kabir-1',
    author: _kabir,
    time: '4d ago',
    text:
        'Tip for first-timers: bring a water bottle and wear shoes you '
        'don’t mind getting dusty. And ask questions, everyone is friendly!',
    likes: 64,
    earlierComments: 3,
    comments: [
      CommunityComment(
        author: _ananya,
        text: 'And a cap for the outdoor ones!',
        time: '3d ago',
      ),
    ],
  ),
  CommunityPost(
    id: 'ananya-1',
    author: _ananya,
    time: '5d ago',
    text:
        '80 saplings in the ground before breakfast at Eco Park. Can’t '
        'wait to see this orchard in a few years.',
    photo: 'assets/images/event_tree_planting.jpg',
    event: 'Tree Planting Morning',
    likes: 112,
    earlierComments: 7,
  ),
  CommunityPost(
    id: 'riverside-1',
    author: _riverside,
    time: '1w ago',
    text:
        'Last Saturday’s food drive reached 500 families. A huge thank you '
        'to the 50 volunteers who made it happen.',
    photo: 'assets/images/role_volunteer.jpg',
    event: 'Community Food Drive',
    likes: 208,
    earlierComments: 15,
  ),
];

/// A longer story from the community.
class CommunityStory {
  const CommunityStory({
    required this.title,
    required this.author,
    required this.photo,
    required this.minutes,
    required this.tag,
    required this.summary,
    required this.paragraphs,
    this.focus = Alignment.center,
  });

  final String title;
  final CommunityMember author;
  final String photo;
  final Alignment focus;

  /// Reading time.
  final int minutes;
  final String tag;
  final String summary;
  final List<String> paragraphs;
}

const communityStories = [
  CommunityStory(
    title: 'How one food drive fed 500 families',
    author: _riya,
    photo: 'assets/images/role_volunteer.jpg',
    focus: Alignment(0.1, -0.3),
    minutes: 4,
    tag: 'Food Drive',
    summary:
        'Fifty volunteers, six hours and a lot of cardboard boxes. Riya '
        'shares what it took.',
    paragraphs: [
      'When Riverside Food Bank asked for help with their autumn drive, we '
          'expected a busy morning. We didn’t expect 500 families.',
      'By nine o’clock the hall was full of donated rice, lentils and '
          'vegetables. We set up three lines: sorting, packing and handing out. '
          'Everyone found a place, even people who’d never volunteered before.',
      'The best moment came at noon, when a grandmother hugged one of our '
          'youngest volunteers and told him he’d made her week. That’s why we '
          'keep coming back.',
      'If you’ve been thinking about joining a drive, this is your sign. '
          'Bring a water bottle and an open heart. We’ll show you the rest.',
    ],
  ),
  CommunityStory(
    title: 'From kitchen leftovers to a community lunch',
    author: _hopeKitchen,
    photo: 'assets/images/event_community_meal.jpg',
    minutes: 3,
    tag: 'Food Rescue',
    summary:
        'How rescued vegetables became 600 plates of festive lunch at the '
        'Town Hall.',
    paragraphs: [
      'Every week, restaurants and markets around us throw away food that '
          'is perfectly good to eat. This year we decided to cook it instead.',
      'Volunteers collected surplus vegetables, bread and rice from twelve '
          'partners. Our cooks planned a menu around what arrived, not the '
          'other way round.',
      'The result was a lunch for 600 guests, with almost nothing wasted. '
          'We’re doing it again this month, and we’d love your help in the '
          'kitchen.',
    ],
  ),
  CommunityStory(
    title: 'What I learned in my first 10 events',
    author: _arjun,
    photo: 'assets/images/change_volunteers.jpg',
    minutes: 5,
    tag: 'Volunteer Life',
    summary: 'Arjun on nerves, new friends and why the small jobs matter most.',
    paragraphs: [
      'My first event, I was so nervous I nearly didn’t go. Ten events '
          'later, it’s the best part of my week.',
      'Lesson one: nobody expects you to know everything. Lesson two: the '
          'small jobs, like stacking chairs or refilling water, keep everything '
          'running.',
      'Lesson three: you meet the kindest people. Some of my closest '
          'friends now are people I met sorting potatoes.',
      'If you’re on the fence, pick one short event and just try it. '
          'You’ll be surprised how quickly it feels like home.',
    ],
  ),
  CommunityStory(
    title: 'Growing food on city rooftops',
    author: _greenRoots,
    photo: 'assets/images/notifications_community_farm.jpg',
    minutes: 4,
    tag: 'Gardening',
    summary:
        'Raised beds, rain barrels and a lot of spinach: how our gardens '
        'feed local kitchens.',
    paragraphs: [
      'You don’t need a farm to grow food. Our rooftop and park gardens '
          'grow over 200 kg of vegetables every season.',
      'Volunteers build the beds, plant seasonal crops and harvest every '
          'week. Everything goes straight to community kitchens nearby.',
      'Join a garden morning to learn the basics. You might go home with '
          'a seed pack for your own balcony.',
    ],
  ),
  CommunityStory(
    title: 'A morning in the fields: gleaning explained',
    author: _priya,
    photo: 'assets/images/event_harvest_greens.jpg',
    minutes: 3,
    tag: 'Food Rescue',
    summary:
        'What gleaning is, why farmers love it and how 300 kg of greens '
        'were saved in one morning.',
    paragraphs: [
      'Gleaning means picking the crops left in the field after harvest. '
          'They’re perfectly good, just too many or too small to sell.',
      'Farmers invite us in, we pick, and the food goes to community '
          'kitchens the same day. Nothing is wasted.',
      'Wear sturdy shoes, bring gloves and come early. The sunrise over '
          'the fields is worth it on its own.',
    ],
  ),
];

/// Meals shared through FoodLink each month this year (January to
/// September).
const monthlyMeals = [
  ('Jan', 3100),
  ('Feb', 3600),
  ('Mar', 4200),
  ('Apr', 4800),
  ('May', 5200),
  ('Jun', 5900),
  ('Jul', 6400),
  ('Aug', 7100),
  ('Sep', 7950),
];

/// This year's meal goal.
const mealGoal = 60000;

/// Volunteers with the most hours this month; the volunteer using the app
/// is the one marked [CommunityMember.you].
const topVolunteers = [
  (_priya, 28),
  (_riya, 24),
  (_ananya, 19),
  (_kabir, 16),
  (you, 14),
  (_arjun, 11),
];
