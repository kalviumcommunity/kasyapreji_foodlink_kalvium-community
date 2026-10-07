import 'package:flutter/material.dart';

import 'community.dart';
import 'my_events.dart';

/// The volunteer's personal details.
class ProfileDetails {
  const ProfileDetails({
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.bio,
    required this.emergencyName,
    required this.emergencyPhone,
  });

  final String name;
  final String email;
  final String phone;
  final String city;
  final String bio;
  final String emergencyName;
  final String emergencyPhone;
}

/// What the volunteer wants to hear about and share.
class ProfileSettings {
  const ProfileSettings({
    this.eventReminders = true,
    this.newEventsNearby = true,
    this.communityActivity = true,
    this.weeklySummary = false,
    this.showOnLeaderboard = true,
    this.shareHoursWithOrganisers = true,
    this.distanceKm = 15,
    this.language = 'English',
  });

  final bool eventReminders;
  final bool newEventsNearby;
  final bool communityActivity;
  final bool weeklySummary;
  final bool showOnLeaderboard;
  final bool shareHoursWithOrganisers;

  /// How far away events can be, for suggestions.
  final double distanceKm;
  final String language;

  ProfileSettings copyWith({
    bool? eventReminders,
    bool? newEventsNearby,
    bool? communityActivity,
    bool? weeklySummary,
    bool? showOnLeaderboard,
    bool? shareHoursWithOrganisers,
    double? distanceKm,
    String? language,
  }) => ProfileSettings(
    eventReminders: eventReminders ?? this.eventReminders,
    newEventsNearby: newEventsNearby ?? this.newEventsNearby,
    communityActivity: communityActivity ?? this.communityActivity,
    weeklySummary: weeklySummary ?? this.weeklySummary,
    showOnLeaderboard: showOnLeaderboard ?? this.showOnLeaderboard,
    shareHoursWithOrganisers:
        shareHoursWithOrganisers ?? this.shareHoursWithOrganisers,
    distanceKm: distanceKm ?? this.distanceKm,
    language: language ?? this.language,
  );
}

const _initialDetails = ProfileDetails(
  name: 'Agnibha Bhattacharya',
  email: 'demo@foodlink.org',
  phone: '+91 98300 12345',
  city: 'Kolkata',
  bio: 'Weekend volunteer who loves food drives and garden mornings.',
  emergencyName: 'Riya Bhattacharya',
  emergencyPhone: '+91 98300 67890',
);

/// The volunteer's profile, kept in memory until accounts exist. Profile
/// pages listen, so a change shows everywhere at once.
class VolunteerProfile {
  VolunteerProfile._();

  static final ValueNotifier<ProfileDetails> details = ValueNotifier(
    _initialDetails,
  );
  static final ValueNotifier<Set<String>> interests = ValueNotifier({
    'Food Drives',
    'Community Kitchens',
    'Gardening',
  });
  static final ValueNotifier<Set<String>> skills = ValueNotifier({
    'Cooking',
    'Lifting',
  });
  static final ValueNotifier<Set<String>> days = ValueNotifier({'Sat', 'Sun'});
  static final ValueNotifier<String> timeOfDay = ValueNotifier('Mornings');
  static final ValueNotifier<ProfileSettings> settings = ValueNotifier(
    const ProfileSettings(),
  );

  /// Whether organisers can ask the volunteer to fill a last-minute gap.
  static final ValueNotifier<bool> availableForUrgent = ValueNotifier(true);

  @visibleForTesting
  static void reset() {
    details.value = _initialDetails;
    interests.value = {'Food Drives', 'Community Kitchens', 'Gardening'};
    skills.value = {'Cooking', 'Lifting'};
    days.value = {'Sat', 'Sun'};
    timeOfDay.value = 'Mornings';
    settings.value = const ProfileSettings();
    availableForUrgent.value = true;
  }
}

/// Causes a volunteer can follow.
const interestOptions = [
  ('Food Drives', Icons.volunteer_activism_rounded),
  ('Community Kitchens', Icons.soup_kitchen_outlined),
  ('Food Rescue', Icons.recycling_rounded),
  ('Gardening', Icons.yard_outlined),
  ('Education', Icons.menu_book_rounded),
  ('Children & Youth', Icons.child_care_rounded),
  ('Elderly Care', Icons.elderly_rounded),
  ('Clean-ups', Icons.cleaning_services_outlined),
];

/// Skills a volunteer can offer.
const skillOptions = [
  'Cooking',
  'Driving',
  'Teaching',
  'Lifting',
  'First Aid',
  'Photography',
  'Languages',
  'Organising',
];

const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const timesOfDay = ['Mornings', 'Afternoons', 'Evenings', 'Any time'];

/// Total hours the volunteer has given.
int get volunteerHours => pastVisits.fold(0, (sum, visit) => sum + visit.hours);

/// The past events that gave a certificate.
List<PastVisit> get certificates => [
  for (final visit in pastVisits)
    if (visit.certificate) visit,
];

/// Volunteer levels, by hours given.
const _levels = [
  (0, 'Seedling'),
  (10, 'Helping Hand'),
  (25, 'Community Champion'),
  (50, 'Food Hero'),
  (100, 'FoodLink Legend'),
];

/// The volunteer's level (1-based), its name, the next level's name and
/// hours, and how far they are towards it (0–1).
({int level, String name, String? next, int nextHours, double progress})
volunteerLevel() {
  final hours = volunteerHours;
  var index = 0;
  for (var i = 0; i < _levels.length; i++) {
    if (hours >= _levels[i].$1) index = i;
  }
  final last = index == _levels.length - 1;
  final from = _levels[index].$1;
  final to = last ? from : _levels[index + 1].$1;
  return (
    level: index + 1,
    name: _levels[index].$2,
    next: last ? null : _levels[index + 1].$2,
    nextHours: to,
    progress: last ? 1 : (hours - from) / (to - from),
  );
}

/// An achievement the volunteer has earned or is working towards.
class VolunteerBadge {
  const VolunteerBadge({
    required this.name,
    required this.icon,
    required this.color,
    required this.how,
    required this.earned,
  });

  final String name;
  final IconData icon;
  final Color color;

  /// How to earn it.
  final String how;
  final bool earned;
}

/// The volunteer's badges, earned ones first.
List<VolunteerBadge> volunteerBadges() {
  bool attended(bool Function(PastVisit) test) => pastVisits.any(test);
  final shared = CommunityFeed.posts.value.any((post) => post.author.you);
  final badges = [
    VolunteerBadge(
      name: 'First Steps',
      icon: Icons.directions_walk_rounded,
      color: const Color(0xFF6A9A51),
      how: 'Go to your first event',
      earned: pastVisits.isNotEmpty,
    ),
    VolunteerBadge(
      name: 'Ten Strong',
      icon: Icons.looks_one_rounded,
      color: const Color(0xFF2D6A45),
      how: 'Go to 10 events',
      earned: pastVisits.length >= 10,
    ),
    VolunteerBadge(
      name: 'Early Bird',
      icon: Icons.wb_twilight_rounded,
      color: const Color(0xFFE0A63A),
      how: 'Join an event that starts before 8 AM',
      earned: attended(
        (visit) => RegExp(r'^[67]:\d\d AM').hasMatch(visit.event.hours),
      ),
    ),
    VolunteerBadge(
      name: 'Food Rescuer',
      icon: Icons.recycling_rounded,
      color: const Color(0xFF3D6683),
      how: 'Help rescue food that would go to waste',
      earned: attended(
        (visit) =>
            visit.event.title.contains('Gleaning') ||
            visit.event.title.contains('Sort'),
      ),
    ),
    VolunteerBadge(
      name: 'Green Thumb',
      icon: Icons.yard_rounded,
      color: const Color(0xFF4F7539),
      how: 'Plant or grow food with the community',
      earned: attended(
        (visit) =>
            visit.event.title.contains('Planting') ||
            visit.event.title.contains('Seed'),
      ),
    ),
    VolunteerBadge(
      name: 'Community Voice',
      icon: Icons.campaign_rounded,
      color: const Color(0xFFDC6558),
      how: 'Share your first post in Community',
      earned: shared,
    ),
    VolunteerBadge(
      name: 'Half Century',
      icon: Icons.hourglass_bottom_rounded,
      color: const Color(0xFF8A5A1E),
      how: 'Give 50 hours',
      earned: volunteerHours >= 50,
    ),
  ];
  return [
    ...badges.where((badge) => badge.earned),
    ...badges.where((badge) => !badge.earned),
  ];
}

/// Questions volunteers often ask.
const helpTopics = [
  (
    'How do I join an event?',
    'Open any event from Home or Explore and tap Join Event. Pick a role '
        'and time slot, add a note if you like, then tap Confirm & Join.',
  ),
  (
    'Can I leave an event I joined?',
    'Yes. Open the event from My Events and tap Leave event at the bottom. '
        'Please leave early if you can, so someone else can take your spot.',
  ),
  (
    'How are my hours counted?',
    'Organisers confirm your attendance after each event. The hours of your '
        'time slot are then added to your profile and certificates.',
  ),
  (
    'How do I get a certificate?',
    'Workshops and some larger drives give a certificate of participation. '
        'You’ll find them under Profile, then Certificates.',
  ),
  (
    'Is my personal information shared?',
    'Only the organisers of events you join can see your name, phone and '
        'emergency contact. You can change what you share in Settings.',
  ),
];
