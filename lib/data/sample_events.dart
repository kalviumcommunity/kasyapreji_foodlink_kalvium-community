import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The kinds of event volunteers can filter by on Explore, each with its own
/// tag colours and icon.
enum EventCategory {
  foodDrive(
    'Food Drive',
    Icons.volunteer_activism_rounded,
    AppColors.tagFoodFill,
    AppColors.tagFoodText,
    AppColors.glowPeach,
  ),
  community(
    'Community',
    Icons.diversity_3_rounded,
    AppColors.roleChosenFill,
    AppColors.brand,
    AppColors.glowMint,
  ),
  education(
    'Education',
    Icons.menu_book_rounded,
    AppColors.tagLearnFill,
    AppColors.tagLearnText,
    AppColors.glowSky,
  );

  const EventCategory(this.label, this.icon, this.fill, this.text, this.glow);

  final String label;
  final IconData icon;

  /// Tag background and text colours.
  final Color fill;
  final Color text;

  /// Soft colour glowing behind the event's details.
  final Color glow;
}

/// One volunteering event.
class VolunteerEvent {
  const VolunteerEvent({
    required this.title,
    required this.when,
    required this.place,
    required this.category,
    required this.photo,
    this.focus = Alignment.center,
    required this.date,
    required this.hours,
    required this.address,
    required this.about,
    required this.going,
    required this.capacity,
    required this.impact,
    required this.duration,
    required this.bring,
    required this.organiser,
  });

  final String title;

  /// Short date and start time for lists, e.g. "Sat, 20 Sep · 10:00 AM".
  final String when;
  final String place;
  final EventCategory category;
  final String photo;

  /// Which part of [photo] to keep when it is cropped.
  final Alignment focus;

  /// Full date and time range for the details page.
  final String date;
  final String hours;
  final String address;
  final String about;

  /// Volunteers signed up so far, out of [capacity] spots.
  final int going;
  final int capacity;

  /// What the event achieves, e.g. ('500+', 'Meals').
  final (String, String) impact;
  final String duration;

  /// What volunteers should bring.
  final List<String> bring;
  final String organiser;

  /// Whether [query] appears in the title, place, date or category.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      title,
      place,
      address,
      when,
      category.label,
    ].any((field) => field.toLowerCase().contains(q));
  }
}

const _communityFoodDrive = VolunteerEvent(
  title: 'Community Food Drive',
  when: 'Sat, 20 Sep · 10:00 AM',
  place: 'Riverside Center',
  category: EventCategory.foodDrive,
  photo: 'assets/images/role_volunteer.jpg',
  focus: Alignment(0.1, -0.3),
  date: 'Sat, 20 Sep 2026',
  hours: '10:00 AM – 2:00 PM',
  address: 'Riverside Center, Kolkata',
  about:
      'Join us in distributing fresh meals to families in need. Help us '
      'spread kindness and reduce food waste.',
  going: 50,
  capacity: 60,
  impact: ('500+', 'Meals'),
  duration: '4 hrs',
  bring: ['Water bottle', 'Comfortable shoes', 'Cap or hat'],
  organiser: 'Riverside Food Bank',
);

const _weekendMealPacking = VolunteerEvent(
  title: 'Weekend Meal Packing',
  when: 'Sun, 21 Sep · 9:00 AM',
  place: 'Hope Kitchen',
  category: EventCategory.foodDrive,
  photo: 'assets/images/impact_packing.jpg',
  date: 'Sun, 21 Sep 2026',
  hours: '9:00 AM – 12:00 PM',
  address: 'Hope Kitchen, Kolkata',
  about:
      'Pack dry rations and ready meals into family kits that go out to '
      'shelters across the city.',
  going: 28,
  capacity: 30,
  impact: ('400', 'Kits'),
  duration: '3 hrs',
  bring: ['Apron', 'Hair tie or cap', 'Water bottle'],
  organiser: 'Hope Kitchen Trust',
);

const _neighbourhoodShareDay = VolunteerEvent(
  title: 'Neighbourhood Share Day',
  when: 'Sat, 27 Sep · 4:00 PM',
  place: 'Green Park',
  category: EventCategory.community,
  photo: 'assets/images/change_volunteers.jpg',
  date: 'Sat, 27 Sep 2026',
  hours: '4:00 PM – 7:00 PM',
  address: 'Green Park, Kolkata',
  about:
      'Neighbours bring extra produce and home-cooked food to share. Help '
      'set up the stalls, welcome visitors and keep things moving.',
  going: 18,
  capacity: 25,
  impact: ('200+', 'Guests'),
  duration: '3 hrs',
  bring: ['Reusable bags', 'Water bottle', 'A friendly smile'],
  organiser: 'Green Park Residents',
);

/// Sample events, until events come from the database. Explore lists them
/// all, in this order.
const sampleEvents = [
  _communityFoodDrive,
  VolunteerEvent(
    title: 'Urban Garden Setup',
    when: 'Sun, 28 Sep · 9:00 AM',
    place: 'Greenfield Park',
    category: EventCategory.community,
    photo: 'assets/images/notifications_community_farm.jpg',
    date: 'Sun, 28 Sep 2026',
    hours: '9:00 AM – 1:00 PM',
    address: 'Greenfield Park, Salt Lake',
    about:
        'Help build raised beds and plant seasonal vegetables for a '
        'community garden that will feed local families for months.',
    going: 24,
    capacity: 30,
    impact: ('30', 'Beds'),
    duration: '4 hrs',
    bring: ['Gardening gloves', 'Hat', 'Water bottle'],
    organiser: 'Green Roots Collective',
  ),
  VolunteerEvent(
    title: 'Weekend Meal Distribution',
    when: 'Sat, 5 Oct · 11:00 AM',
    place: 'Hope Shelter',
    category: EventCategory.foodDrive,
    photo: 'assets/images/onboarding_community_meal.jpg',
    date: 'Sat, 5 Oct 2026',
    hours: '11:00 AM – 3:00 PM',
    address: 'Hope Shelter, Howrah',
    about:
        'Serve warm lunches and pack take-home parcels for the families '
        'staying at Hope Shelter this weekend.',
    going: 35,
    capacity: 40,
    impact: ('300+', 'Meals'),
    duration: '4 hrs',
    bring: ['Apron', 'Hair tie or cap', 'Water bottle'],
    organiser: 'Hope Shelter Trust',
  ),
  _weekendMealPacking,
  _neighbourhoodShareDay,
  VolunteerEvent(
    title: 'Healthy Eating Workshop',
    when: 'Wed, 8 Oct · 6:00 PM',
    place: 'Community Library',
    category: EventCategory.education,
    photo: 'assets/images/splash_giving.jpg',
    date: 'Wed, 8 Oct 2026',
    hours: '6:00 PM – 8:00 PM',
    address: 'Community Library, Kolkata',
    about:
        'Learn simple, low-cost recipes and nutrition tips you can share '
        'with the families you support.',
    going: 22,
    capacity: 40,
    impact: ('12', 'Recipes'),
    duration: '2 hrs',
    bring: ['Notebook', 'Pen', 'Curiosity'],
    organiser: 'FoodLink Learning',
  ),
  VolunteerEvent(
    title: 'Food Safety Basics',
    when: 'Sat, 11 Oct · 2:00 PM',
    place: 'Riverside Center',
    category: EventCategory.education,
    photo: 'assets/images/role_coordinator.jpg',
    focus: Alignment(0, -0.2),
    date: 'Sat, 11 Oct 2026',
    hours: '2:00 PM – 4:30 PM',
    address: 'Riverside Center, Kolkata',
    about:
        'A hands-on session on storing, handling and transporting donated '
        'food safely. Everyone who attends gets a certificate.',
    going: 15,
    capacity: 30,
    impact: ('1', 'Certificate'),
    duration: '2.5 hrs',
    bring: ['Notebook', 'Pen', 'Photo ID'],
    organiser: 'Riverside Food Bank',
  ),
];

/// The few events the volunteer home shows under "Upcoming Events".
const upcomingEvents = [
  _communityFoodDrive,
  _weekendMealPacking,
  _neighbourhoodShareDay,
];
