import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/sample_events.dart';

/// The PRD's data model (section 11), under `campaigns/{campaignId}`.
///
/// v1 has no campaign-switcher UI yet, so the app always uses one
/// well-known campaign document — see [kDefaultCampaignId] in
/// `campaign_service.dart`. That's a deliberate simplification, not a
/// security boundary: the Firestore rules support any number of
/// campaigns, each fully isolated from the others by its own
/// `campaignId` path segment.
class Campaign {
  const Campaign({
    required this.id,
    required this.name,
    required this.status,
    required this.createdBy,
  });

  final String id;
  final String name;

  /// `'planned'`, `'active'`, or `'completed'`.
  final String status;
  final String createdBy;

  factory Campaign.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Campaign(
      id: doc.id,
      name: data['name'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      createdBy: data['createdBy'] as String? ?? '',
    );
  }
}

/// `campaigns/{campaignId}/sites/{siteId}`.
class SiteRecord {
  const SiteRecord({
    required this.id,
    required this.name,
    required this.address,
    required this.status,
    required this.currentSupply,
    required this.capacity,
  });

  final String id;
  final String name;
  final String address;

  /// `'active'`, `'paused'`, or `'closed'`.
  final String status;
  final num currentSupply;
  final num capacity;

  /// `'ok'`, `'low'`, or `'critical'` — a placeholder threshold (20% /
  /// 5% of capacity) until the organization validates a real one; see
  /// the PRD's own KPI table, which leaves this "to be validated".
  String get supplyStatus {
    if (capacity <= 0) return 'ok';
    final ratio = currentSupply / capacity;
    if (ratio < 0.05) return 'critical';
    if (ratio < 0.2) return 'low';
    return 'ok';
  }

  factory SiteRecord.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return SiteRecord(
      id: doc.id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      currentSupply: data['currentSupply'] as num? ?? 0,
      capacity: data['capacity'] as num? ?? 0,
    );
  }
}

/// `campaigns/{campaignId}/assignments/{siteId}_{volunteerId}`.
///
/// The document ID is deliberately deterministic (`siteId_volunteerId`),
/// not auto-generated — it's what lets the Firestore rules cheaply check
/// "does this volunteer have an assignment at this site?" with a single
/// `exists()` call, which is what actually enforces (not just the UI)
/// that a volunteer can only record distribution at a site they're
/// assigned to.
class Assignment {
  const Assignment({
    required this.id,
    required this.siteId,
    required this.volunteerId,
    required this.task,
    required this.status,
  });

  final String id;
  final String siteId;
  final String volunteerId;
  final String task;

  /// `'active'`, `'completed'`, or `'cancelled'`.
  final String status;

  static String idFor({required String siteId, required String volunteerId}) =>
      '${siteId}_$volunteerId';

  factory Assignment.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Assignment(
      id: doc.id,
      siteId: data['siteId'] as String? ?? '',
      volunteerId: data['volunteerId'] as String? ?? '',
      task: data['task'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
    );
  }
}

/// `campaigns/{campaignId}/beneficiaries/{beneficiaryId}` — an individual
/// household record, exactly as the PRD specifies. This is a different,
/// finer-grained concept from the existing Beneficiaries *screens*, which
/// manage partner organizations (shelters, community centres) — see
/// [PartnerOrganization] for that.
class HouseholdBeneficiary {
  const HouseholdBeneficiary({
    required this.id,
    required this.siteId,
    required this.name,
    required this.householdSize,
    required this.status,
    required this.notes,
  });

  final String id;
  final String siteId;
  final String name;
  final int householdSize;

  /// `'pending'`, `'served'`, or `'inactive'`.
  final String status;
  final String notes;

  factory HouseholdBeneficiary.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return HouseholdBeneficiary(
      id: doc.id,
      siteId: data['siteId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      householdSize: data['householdSize'] as int? ?? 1,
      status: data['status'] as String? ?? 'pending',
      notes: data['notes'] as String? ?? '',
    );
  }
}

/// `campaigns/{campaignId}/distributionEvents/{eventId}` — append-only;
/// corrections are an explicit coordinator edit, never a delete (the
/// PRD's own data design notes ask for this).
class DistributionEvent {
  const DistributionEvent({
    required this.id,
    required this.siteId,
    required this.volunteerId,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.beneficiaryCount,
    required this.recordedAt,
  });

  final String id;
  final String siteId;
  final String volunteerId;
  final String category;
  final num quantity;
  final String unit;
  final int beneficiaryCount;
  final DateTime recordedAt;

  factory DistributionEvent.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final recordedAt = data['recordedAt'];
    return DistributionEvent(
      id: doc.id,
      siteId: data['siteId'] as String? ?? '',
      volunteerId: data['volunteerId'] as String? ?? '',
      category: data['category'] as String? ?? '',
      quantity: data['quantity'] as num? ?? 0,
      unit: data['unit'] as String? ?? '',
      beneficiaryCount: data['beneficiaryCount'] as int? ?? 0,
      recordedAt: recordedAt is Timestamp
          ? recordedAt.toDate()
          : DateTime.now(),
    );
  }
}

/// `campaigns/{campaignId}/reallocations/{reallocationId}` — an
/// immutable record (never updated or deleted) of moving supply from one
/// site to another.
class Reallocation {
  const Reallocation({
    required this.id,
    required this.fromSiteId,
    required this.toSiteId,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.reason,
    required this.createdBy,
  });

  final String id;
  final String fromSiteId;
  final String toSiteId;
  final String category;
  final num quantity;
  final String unit;
  final String reason;
  final String createdBy;

  factory Reallocation.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return Reallocation(
      id: doc.id,
      fromSiteId: data['fromSiteId'] as String? ?? '',
      toSiteId: data['toSiteId'] as String? ?? '',
      category: data['category'] as String? ?? '',
      quantity: data['quantity'] as num? ?? 0,
      unit: data['unit'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
    );
  }
}

/// `campaigns/{campaignId}/alerts/{alertId}`.
class CampaignAlert {
  const CampaignAlert({
    required this.id,
    required this.type,
    required this.siteId,
    required this.severity,
    required this.message,
    required this.status,
  });

  final String id;
  final String type;
  final String siteId;

  /// `'info'`, `'warning'`, or `'critical'`.
  final String severity;
  final String message;

  /// `'open'`, `'acknowledged'`, or `'resolved'`.
  final String status;

  factory CampaignAlert.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return CampaignAlert(
      id: doc.id,
      type: data['type'] as String? ?? 'other',
      siteId: data['siteId'] as String? ?? '',
      severity: data['severity'] as String? ?? 'info',
      message: data['message'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
    );
  }
}

/// `campaigns/{campaignId}/events/{eventId}` — the existing coordinator
/// Events screens' `ManagedEvent`, backed by Firestore. A separate
/// concept from the PRD's `sites`/`distributionEvents` — see the note
/// at the top of `campaign_service.dart` on why these aren't merged.
class CampaignEventRecord {
  const CampaignEventRecord({
    required this.id,
    required this.title,
    required this.status,
    required this.mealsSoFar,
    required this.createdBy,
  });

  final String id;
  final String title;

  /// `'ongoing'`, `'upcoming'`, or `'completed'`.
  final String status;
  final int mealsSoFar;
  final String createdBy;

  factory CampaignEventRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return CampaignEventRecord(
      id: doc.id,
      title: data['title'] as String? ?? '',
      status: data['status'] as String? ?? 'upcoming',
      mealsSoFar: data['mealsSoFar'] as int? ?? 0,
      createdBy: data['createdBy'] as String? ?? '',
    );
  }
}

/// `campaigns/{campaignId}/events/{eventId}/roster/{volunteerId}` — a
/// volunteer's own join record for one event. The document ID is the
/// volunteer's uid, which is what lets the security rules enforce "you
/// can only create/read/leave your OWN roster entry" with a plain
/// `request.auth.uid == volunteerId` check, no query needed.
class EventRosterEntry {
  const EventRosterEntry({
    required this.volunteerId,
    required this.name,
    required this.role,
    required this.status,
  });

  final String volunteerId;
  final String name;
  final String role;

  /// `'pending'` until a coordinator confirms it, then `'confirmed'`.
  final String status;

  factory EventRosterEntry.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return EventRosterEntry(
      volunteerId: doc.id,
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
    );
  }
}

/// `campaigns/{campaignId}/team/{id}` — the existing Team Management
/// screen's invited staff (`TeamMember` in `lib/data/coordinator.dart`).
/// The signed-in coordinator's own "you" entry is handled separately,
/// in-memory, by `applySignedInIdentity` — this is only for the other
/// people a coordinator invites.
class TeamRecord {
  const TeamRecord({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.colorSeed,
    required this.invited,
  });

  final String id;
  final String name;
  final String role;
  final String email;
  final int colorSeed;
  final bool invited;

  factory TeamRecord.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return TeamRecord(
      id: doc.id,
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? '',
      email: data['email'] as String? ?? '',
      colorSeed: data['colorSeed'] as int? ?? 0,
      invited: data['invited'] as bool? ?? true,
    );
  }
}

/// Real numbers for one reporting window, computed from actual
/// `events` and `roster` records — see
/// `CampaignService.computeReportComparison` for exactly what each
/// field measures and the approximations involved.
class ReportStats {
  const ReportStats({
    required this.meals,
    required this.volunteers,
    required this.communities,
  });

  final int meals;
  final int volunteers;
  final int communities;

  static const zero = ReportStats(meals: 0, volunteers: 0, communities: 0);
}

/// A reporting window's real numbers alongside the equivalent-length
/// window immediately before it, for the existing Reports screen's
/// period-over-period comparison.
class ReportComparison {
  const ReportComparison({required this.current, required this.previous});

  final ReportStats current;
  final ReportStats previous;
}

/// One real volunteer's participation record, from `watchAllRosterEntries`
/// — the reusable, tested backend service for a real volunteer
/// directory. See that method's doc comment for why the existing
/// Volunteers (approval) *screen* isn't wired to this yet.
class VolunteerParticipation {
  const VolunteerParticipation({
    required this.volunteerId,
    required this.name,
    required this.eventId,
    required this.role,
    required this.status,
    this.joinedAt,
  });

  final String volunteerId;
  final String name;
  final String eventId;
  final String role;
  final String status;
  final DateTime? joinedAt;
}

/// A real event read back from Firestore in full — see
/// `CampaignService.fetchEvents`.
class RealEvent {
  const RealEvent({
    required this.id,
    required this.event,
    required this.status,
    required this.mealsSoFar,
    this.createdAt,
  });

  final String id;
  final VolunteerEvent event;

  /// `'ongoing'`, `'upcoming'`, or `'completed'`.
  final String status;
  final int mealsSoFar;
  final DateTime? createdAt;
}

/// `campaigns/{campaignId}/partnerOrganizations/{orgId}` — the shelters
/// and community centres the existing Beneficiaries screens manage
/// (`lib/data/coordinator.dart`'s `Beneficiary`, now backed by Firestore
/// instead of a fixed sample list). `colorSeed` replaces the sample
/// data's hand-picked `Color` list — Firestore can't store a `Color`, so
/// the UI derives a consistent avatar gradient from this index instead.
class PartnerOrganization {
  const PartnerOrganization({
    required this.id,
    required this.name,
    required this.type,
    required this.people,
    required this.address,
    required this.contact,
    required this.phone,
    required this.mealsThisMonth,
    required this.nextDelivery,
    required this.colorSeed,
    required this.isNew,
  });

  final String id;
  final String name;
  final String type;
  final int people;
  final String address;
  final String contact;
  final String phone;
  final int mealsThisMonth;
  final String nextDelivery;
  final int colorSeed;
  final bool isNew;

  factory PartnerOrganization.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return PartnerOrganization(
      id: doc.id,
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? '',
      people: data['people'] as int? ?? 0,
      address: data['address'] as String? ?? '',
      contact: data['contact'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      mealsThisMonth: data['mealsThisMonth'] as int? ?? 0,
      nextDelivery: data['nextDelivery'] as String? ?? '',
      colorSeed: data['colorSeed'] as int? ?? 0,
      isNew: data['isNew'] as bool? ?? false,
    );
  }
}
