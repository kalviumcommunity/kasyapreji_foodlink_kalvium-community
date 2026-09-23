# **PRD — Food Distribution Campaign Coordination Mobile App**

 **Platform:** Mobile (Flutter \+ Dart)  
 **Backend:** Firebase Authentication \+ Cloud Firestore \+ Firebase Storage  
 **Development:** Firebase Emulator Suite \+ Android/iOS emulator or physical device

> This PRD is based on the supplied problem statement and the uploaded PRD playbook. The playbook defines a PRD as the shared agreement on the problem, users, constraints, measurement, dependencies and risks, and recommends writing it before implementation. fileciteturn0file0L48-L72

## **1\. Product Summary**

A non-profit needs a single mobile workspace for coordinating food distribution across multiple communities/sites. The app replaces fragmented group-chat coordination with structured volunteer assignments, beneficiary updates, live distribution counts and site-level supply visibility.

### **Problem statement**

A non-profit manages food distribution across several communities, but volunteer assignments and beneficiary updates are fragmented across group chats. During active campaigns, coordinators have no live count of what has been distributed and cannot reallocate supplies before shortages occur at individual sites.

### **Product hypothesis**

If volunteers and coordinators record operational activity in one real-time system, coordinators can see current distribution and site conditions and act on emerging shortages earlier than they can through fragmented group chats.

## **2\. Goals**

1. Establish one operational source of truth for an active campaign.  
2. Give coordinators a live view of distribution activity by site.  
3. Give volunteers clear assignments and a fast field-update workflow.  
4. Make beneficiary updates structured and traceable.  
5. Surface potential site shortages early enough for coordinator action.  
6. Keep the v1 architecture simple enough to build and test with Flutter \+ Firebase.

## **3\. Non-Goals / Out of Scope for v1**

* Predictive demand forecasting or ML-based shortage prediction.  
* Public beneficiary-facing account/app.  
* Payments, donations or fundraising.  
* Full accounting/inventory ERP.  
* Web application unless separately requested.  
* Automated WhatsApp/Telegram group management.  
* Complex GIS routing/navigation.  
* Multi-organization tenancy.  
* Advanced BI/reporting beyond operational campaign metrics.

## **4\. Users & Stakeholders**

| Role | Responsibility |
| ----- | ----- |
| Coordinator | Owns campaign operations, monitors sites, assigns volunteers and reallocates supplies. |
| Volunteer | Executes assigned field work and records distribution/beneficiary updates. |
| Program/Operations Lead | Reviews campaign outcomes and operational status. |
| Firebase/Engineering Owner | Owns authentication, database structure, security rules and deployment. |
| Beneficiary | Recipient represented by a structured record; no account required in v1 unless confirmed. |

The playbook recommends explicitly identifying primary users, secondary users, data owners and approvers. fileciteturn0file0L126-L172

## **5\. Business Impact**

### **Operational**

* Reduces dependence on scattered group-chat messages.  
* Creates one place to see assignments and field updates.  
* Gives coordinators a current site-by-site operating picture.

### **Supply / campaign continuity**

* Makes low-supply sites visible.  
* Gives coordinators a structured reallocation action.  
* Records reallocation decisions for later review.

### **User experience**

* Volunteers do not need to search old chat messages for their assignment.  
* Coordinators do not need to manually consolidate counts from multiple chats.

**Important:** financial impact and time-saved numbers are not supplied by the problem statement and must be measured before being claimed as baseline business impact.

## **6\. Success Metrics / KPIs**

The uploaded playbook requires each KPI to contain a metric, measurement method, numeric target and timeline. fileciteturn0file0L219-L251

| KPI | Measurement method | Target | Timeline |
| ----- | ----- | ----- | ----- |
| Assignment visibility | % of active volunteers who can see current assignment in app | **To be validated** | First campaign after launch |
| Distribution update latency | Median time between field event and Firestore submission | **To be validated** | First campaign |
| Live count freshness | Age of newest site update shown on coordinator dashboard | **To be validated** | Active campaigns |
| Shortage response time | Time from low-supply detection to coordinator reallocation action | **To be validated** | First campaign |
| Data completeness | % of distribution records with site, user, quantity and timestamp | **To be validated** | First campaign |
| App adoption | % of active volunteers/coordinators using the app during campaign | **To be validated** | 30 days after pilot |

Do not replace these placeholders with invented numbers. Validate baselines and targets with the non-profit.

## **7\. User Stories**

The playbook specifies: `As a [role], I want to [action], so that [business benefit].` fileciteturn0file0L257-L289

### **Coordinator stories**

* **US-C01:** As a coordinator, I want to see current distribution totals by site, so that I can identify sites that require intervention.  
* **US-C02:** As a coordinator, I want to see low-supply sites, so that I can reallocate available supplies before a site runs short.  
* **US-C03:** As a coordinator, I want to assign volunteers to sites and tasks, so that field work has clear ownership.  
* **US-C04:** As a coordinator, I want to reassign a volunteer, so that an uncovered or overloaded site can receive help.  
* **US-C05:** As a coordinator, I want to inspect a site's distribution history and current supply position, so that reallocation decisions are based on current information.  
* **US-C06:** As a coordinator, I want to review beneficiary updates, so that campaign participation and distribution records remain structured.

### **Volunteer stories**

* **US-V01:** As a volunteer, I want to see my current assignment, so that I know where and what I need to work on.  
* **US-V02:** As a volunteer, I want to record a distribution update quickly, so that field activity is reflected in the live campaign count.  
* **US-V03:** As a volunteer, I want to update beneficiary information from my assigned site, so that coordinators have current records.  
* **US-V04:** As a volunteer, I want to see assignment changes, so that I do not act on outdated instructions.

## **8\. Functional Requirements**

### **Authentication**

* Email/password sign-up and sign-in using Firebase Authentication.  
* Persist authenticated session.  
* Sign-out.  
* User profile document in Firestore.  
* Role field: `coordinator` or `volunteer`.  
* UI and Firestore rules must enforce role boundaries; hiding a button is not a security mechanism.

### **Campaign**

* Active campaign visible on dashboard.  
* Campaign has sites and operational status.  
* Campaign data is scoped by `campaignId`.

### **Sites**

* List sites.  
* Show site status.  
* Show live distribution/supply indicators.  
* Open site detail.  
* Coordinator can initiate reallocation.

### **Distribution**

* Volunteer selects/uses assigned site.  
* Enters quantity distributed.  
* Optionally records unit/category.  
* Links update to campaign, site and authenticated user.  
* Server timestamp is used for authoritative event time.  
* Successful update refreshes live counts.

### **Assignments**

* Coordinator creates assignment.  
* Assignment has volunteer, site, campaign, task/status and timestamps.  
* Volunteer sees only relevant assignments.  
* Coordinator can reassign.

### **Beneficiaries**

* Create/update beneficiary records.  
* Link beneficiary to campaign/site.  
* Record distribution event/reference.  
* Avoid collecting unnecessary sensitive personal data.

### **Alerts**

* Show low-supply alerts and assignment changes.  
* Alert has status such as `open`, `acknowledged`, `resolved`.  
* v1 may use in-app alerts; push notifications can be added after the core workflow is stable.

### **Storage**

* Optional site/campaign media.  
* Optional proof-of-distribution files if the organization confirms the requirement.  
* Do not upload sensitive documents unless a documented need and retention policy exist.

## **9\. Information Architecture — 12 Screens**

1. Splash / App Bootstrap  
2. Sign In  
3. Sign Up  
4. Profile & Role Setup  
5. Live Campaign Dashboard  
6. Communities / Distribution Sites  
7. Site Detail & Reallocation  
8. Distribution Update  
9. Volunteer Assignments  
10. Beneficiaries  
11. Alerts & Notifications  
12. Profile & Settings

The detailed build guides are in the `pages/` folder.

## **10\. Navigation**

### **Volunteer**

`Splash → Sign In/Sign Up → Profile Setup → Dashboard → Assignments → Site Detail → Distribution Update`

Bottom navigation:

* Home  
* Assignments  
* Sites  
* Alerts  
* Profile

### **Coordinator**

`Splash → Sign In/Sign Up → Profile Setup → Dashboard → Sites → Site Detail → Reallocate / Assign → Beneficiaries`

Bottom navigation:

* Dashboard  
* Sites  
* Assignments  
* Alerts  
* Profile

**Design decision:** coordinator and volunteer do not need separate apps. Use one Flutter app with role-aware screens and Firestore security rules.

## **11\. Firestore Data Model**

text

```
users/{uid}
  displayName
  email
  role
  phone
  photoUrl
  active
  createdAt
  updatedAt

campaigns/{campaignId}
  name
  status
  startDate
  endDate
  createdBy
  createdAt
  updatedAt

campaigns/{campaignId}/sites/{siteId}
  name
  address
  status
  supplyStatus
  currentSupply
  capacity
  updatedAt

campaigns/{campaignId}/assignments/{assignmentId}
  volunteerId
  siteId
  task
  status
  assignedAt
  updatedAt

campaigns/{campaignId}/beneficiaries/{beneficiaryId}
  siteId
  name
  householdSize
  status
  notes
  createdAt
  updatedAt

campaigns/{campaignId}/distributionEvents/{eventId}
  siteId
  volunteerId
  category
  quantity
  unit
  beneficiaryCount
  recordedAt
  createdAt

campaigns/{campaignId}/reallocations/{reallocationId}
  fromSiteId
  toSiteId
  category
  quantity
  unit
  reason
  createdBy
  createdAt

campaigns/{campaignId}/alerts/{alertId}
  type
  siteId
  severity
  message
  status
  createdAt
  resolvedAt
```

### **Data design notes**

* Use `campaignId` to isolate campaign data.  
* Use document IDs rather than storing credentials.  
* Prefer server timestamps for audit fields.  
* Keep distribution events append-only where possible; corrections should be explicit rather than silently overwriting historical activity.  
* Derived counts can be computed from events or maintained as denormalized fields only when the consistency strategy is documented.

The playbook stresses verifying data fields, types, quality and ownership before planning features. fileciteturn0file0L176-L213

## **12\. Real-Time Data Workflow**

text

```
Volunteer / Coordinator
        ↓
Flutter UI
        ↓
Firebase Auth ─────→ authenticated UID / role
        ↓
Cloud Firestore
        ├── campaigns
        ├── sites
        ├── assignments
        ├── beneficiaries
        ├── distributionEvents
        ├── reallocations
        └── alerts
        ↓
Firestore realtime listeners
        ↓
Coordinator dashboard / site screens
```

Operational loop:

`Observe → Investigate → Act → Record → Observe again`

## **13\. UI Design Direction**

* Mobile-first, touch-friendly interface.  
* Primary dashboard uses large KPI cards.  
* Shortage status must be visually obvious without relying only on color.  
* Every quantity has a unit.  
* Every live number has a “last updated” timestamp.  
* Primary actions are placed near the relevant data.  
* Use confirmation dialogs for irreversible or high-impact actions such as reallocation.  
* Provide loading, empty, error and offline states for every Firestore-backed screen.  
* Use accessible text sizes and semantic labels.

## **14\. Technical Requirements**

* Flutter stable channel.  
* Dart.  
* Firebase project.  
* Firebase Authentication.  
* Cloud Firestore.  
* Firebase Storage.  
* Firebase Emulator Suite for local development.  
* Android/iOS emulator and at least one physical-device test pass.  
* Use `flutterfire configure` to connect Flutter to Firebase.  
* Keep Firebase configuration out of manually hard-coded business logic.  
* Use Firestore security rules and Firebase Storage rules.  
* Do not trust client-side role checks for authorization.

## **15\. Risks & Assumptions**

The PRD playbook distinguishes unconfirmed assumptions from risks and recommends likelihood, impact and mitigation. fileciteturn0file0L349-L376

| Risk / assumption | Likelihood | Impact | Mitigation |
| ----- | ----- | ----- | ----- |
| Real-time counts are expected but exact freshness requirement is undefined | Medium | High | Validate freshness SLA before implementation. |
| Supply units differ across food categories | High | High | Define canonical unit model before data entry UI. |
| Volunteers have poor connectivity at sites | Medium | High | Add offline-aware UI and define offline-sync strategy before claiming full offline support. |
| Multiple volunteers update the same site simultaneously | High | High | Use atomic transactions/batched writes where required; test concurrency. |
| Beneficiary data may be sensitive | Medium | High | Collect minimum necessary fields and restrict access by role. |
| Role can be manipulated from client | Low if rules are correct | Critical | Enforce role authorization in Firestore Security Rules. |
| Firestore costs grow with excessive listeners | Medium | Medium | Scope listeners to active campaign/site and unsubscribe on dispose. |
| Reallocation creates inconsistent supply totals | Medium | High | Use transactions and record immutable reallocation events. |

## **16\. MVP Acceptance Criteria**

* A user can authenticate.  
* User role is available to the application.  
* A coordinator can see an active campaign and its sites.  
* A volunteer can see assigned work.  
* A volunteer can submit a distribution event.  
* The coordinator dashboard reflects the submitted event without manual refresh.  
* A site can become visibly low-supply based on defined business rules.  
* A coordinator can create a reallocation record.  
* Important records include user and timestamp metadata.  
* Unauthorized users cannot read/write protected Firestore data.  
* Loading, empty, error and permission-denied states are implemented.

## **17\. Delivery Phases**

### **Phase 0 — Product and Firebase foundation**

PRD → data model → Firebase project → Auth → Firestore → Storage → Emulator → security rules.

### **Phase 1 — App shell and authentication**

Flutter project → theme → navigation → splash → sign-in → sign-up → role/profile setup.

### **Phase 2 — Core operational data**

Campaigns → sites → assignments → beneficiaries → distribution events.

### **Phase 3 — Live operations**

Dashboard listeners → site detail → shortage rules → alerts → reallocation.

### **Phase 4 — Hardening**

Security rules → validation → offline/error states → concurrency testing → performance → device testing.

### **Phase 5 — Pilot**

Seed realistic data → run one campaign → measure KPI baselines → collect coordinator/volunteer feedback → revise v1.

## **18\. PRD Validation Checklist**

The uploaded playbook provides a 15-question quality gate covering problem specificity, KPI completeness, stakeholders, data validation, user stories, scope, workflow, risks, wireframes, language and stakeholder review. fileciteturn0file0L418-L482

Before submission:

* Problem is specific and evidence-backed.  
* KPI targets are validated, not invented.  
* Stakeholders are named.  
* Primary user and use case are clear.  
* Firebase data model is reviewed.  
* User stories use Role \+ Action \+ Benefit.  
* v1 scope is bounded.  
* End-to-end data flow is documented.  
* Risks and assumptions are explicit.  
* Screen/wireframe plan exists.  
* No vague claims such as “very fast” or “user-friendly”.  
* Security rules are reviewed.  
* Naming conventions are consistent.  
* Stakeholder review is completed.  
* A non-technical reader can understand the product.

