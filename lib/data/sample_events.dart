import 'package:flutter/widgets.dart';

/// The kinds of event volunteers can filter by on Explore.
enum EventCategory {
  foodDrive('Food Drive'),
  community('Community'),
  education('Education');

  const EventCategory(this.label);

  final String label;
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
  });

  final String title;
  final String when;
  final String place;
  final EventCategory category;
  final String photo;

  /// Which part of [photo] to keep when it is cropped.
  final Alignment focus;

  /// Whether [query] appears in the title, place, date or category.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      title,
      place,
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
);

const _weekendMealPacking = VolunteerEvent(
  title: 'Weekend Meal Packing',
  when: 'Sun, 21 Sep · 9:00 AM',
  place: 'Hope Kitchen',
  category: EventCategory.foodDrive,
  photo: 'assets/images/impact_packing.jpg',
);

const _neighbourhoodShareDay = VolunteerEvent(
  title: 'Neighbourhood Share Day',
  when: 'Sat, 27 Sep · 4:00 PM',
  place: 'Green Park',
  category: EventCategory.community,
  photo: 'assets/images/change_volunteers.jpg',
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
  ),
  VolunteerEvent(
    title: 'Weekend Meal Distribution',
    when: 'Sat, 5 Oct · 11:00 AM',
    place: 'Hope Shelter',
    category: EventCategory.foodDrive,
    photo: 'assets/images/onboarding_community_meal.jpg',
  ),
  _weekendMealPacking,
  _neighbourhoodShareDay,
  VolunteerEvent(
    title: 'Healthy Eating Workshop',
    when: 'Wed, 8 Oct · 6:00 PM',
    place: 'Community Library',
    category: EventCategory.education,
    photo: 'assets/images/splash_giving.jpg',
  ),
  VolunteerEvent(
    title: 'Food Safety Basics',
    when: 'Sat, 11 Oct · 2:00 PM',
    place: 'Riverside Center',
    category: EventCategory.education,
    photo: 'assets/images/role_coordinator.jpg',
    focus: Alignment(0, -0.2),
  ),
];

/// The few events the volunteer home shows under "Upcoming Events".
const upcomingEvents = [
  _communityFoodDrive,
  _weekendMealPacking,
  _neighbourhoodShareDay,
];
