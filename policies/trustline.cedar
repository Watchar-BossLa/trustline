// TRUSTLINE access policy. Default deny: anything not permitted below is denied.
// forbid always overrides permit. Field groups and domains: rules/field-groups.yaml.
// Expected results per role and purpose: docs/05-access-policy.md (the matrix test asserts it).

// ---------------------------------------------------------------------------
// Guardrails (forbid)
// ---------------------------------------------------------------------------

@id("G1-no-cross-domain-profile")
forbid (
  principal,
  action,
  resource == Trustline::FieldGroup::"cross_domain_profile"
);

@id("G2-no-health-record")
forbid (
  principal,
  action,
  resource == Trustline::FieldGroup::"health_record"
);

@id("G3-no-health-for-police-roles")
forbid (
  principal is Trustline::Officer,
  action == Trustline::Action::"ReadFieldGroup",
  resource is Trustline::FieldGroup
)
when
{
  resource.domain == "health" &&
  principal.roles.containsAny(["traffic_officer", "patrol_officer", "dispatcher", "investigator", "crash_investigator", "supervisor"])
};

@id("G4-health-only-emergency-card-for-ems")
forbid (
  principal,
  action == Trustline::Action::"ReadFieldGroup",
  resource is Trustline::FieldGroup
)
when { resource.domain == "health" }
unless
{
  principal is Trustline::Officer &&
  principal.roles.contains("ems_responder") &&
  resource == Trustline::FieldGroup::"emergency_card" &&
  context.purpose == "EMS" &&
  context.incident_active &&
  context.emergency_consent &&
  context.device_attested
};

@id("G5-officer-device-must-be-attested")
forbid (
  principal is Trustline::Officer,
  action == Trustline::Action::"ReadFieldGroup",
  resource
)
unless { context.device_attested };

@id("G6-officer-ops-need-attested-device")
forbid (
  principal is Trustline::Officer,
  action in [
    Trustline::Action::"IssueTicket",
    Trustline::Action::"ConfirmHit",
    Trustline::Action::"DecideLicenceAction",
    Trustline::Action::"RequestDeferral",
    Trustline::Action::"ApproveDeferral",
    Trustline::Action::"ReleaseDeferral",
    Trustline::Action::"AcknowledgeDeferral",
    Trustline::Action::"DesignateProtectedIdentity",
    Trustline::Action::"AcknowledgeDesignation",
    Trustline::Action::"ReviewAlert"
  ],
  resource
)
unless { context.device_attested };

@id("G7-citizen-only-self")
forbid (
  principal is Trustline::Citizen,
  action == Trustline::Action::"ReadFieldGroup",
  resource
)
unless { context.is_self && context.purpose == "CIT" };

// ---------------------------------------------------------------------------
// Field-group permits
// ---------------------------------------------------------------------------

@id("P1-roadside-stop")
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"ReadFieldGroup",
  resource is Trustline::FieldGroup
)
when
{
  principal.roles.containsAny(["traffic_officer", "patrol_officer", "supervisor"]) &&
  ["TS", "CP"].contains(context.purpose) &&
  [
    Trustline::FieldGroup::"identity_basic",
    Trustline::FieldGroup::"licence_status",
    Trustline::FieldGroup::"points_band",
    Trustline::FieldGroup::"vehicle_registration",
    Trustline::FieldGroup::"insurance_status",
    Trustline::FieldGroup::"inspection_status",
    Trustline::FieldGroup::"compliance_summary",
    Trustline::FieldGroup::"alerts_summary",
    Trustline::FieldGroup::"court_flag"
  ].contains(resource)
};

@id("P2-dispatch-hit")
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"ReadFieldGroup",
  resource is Trustline::FieldGroup
)
when
{
  principal.roles.contains("dispatcher") &&
  context.purpose == "DSP" &&
  [Trustline::FieldGroup::"identity_basic", Trustline::FieldGroup::"alerts_summary"].contains(resource)
};

@id("P3-investigation-with-case")
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"ReadFieldGroup",
  resource is Trustline::FieldGroup
)
when
{
  principal.roles.contains("investigator") &&
  context.purpose == "INV" &&
  context.case_ref_valid &&
  [
    Trustline::FieldGroup::"identity_basic",
    Trustline::FieldGroup::"licence_status",
    Trustline::FieldGroup::"alerts_summary",
    Trustline::FieldGroup::"criminal_record",
    Trustline::FieldGroup::"vehicle_history",
    Trustline::FieldGroup::"accident_history"
  ].contains(resource)
};

@id("P4-warrant-execution")
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"ReadFieldGroup",
  resource is Trustline::FieldGroup
)
when
{
  principal.roles.contains("investigator") &&
  context.purpose == "WAR" &&
  context.warrant_ref_valid &&
  [Trustline::FieldGroup::"identity_basic", Trustline::FieldGroup::"alerts_summary"].contains(resource)
};

@id("P5-crash-investigation")
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"ReadFieldGroup",
  resource is Trustline::FieldGroup
)
when
{
  principal.roles.contains("crash_investigator") &&
  context.purpose == "CRASH" &&
  context.incident_active &&
  [
    Trustline::FieldGroup::"identity_basic",
    Trustline::FieldGroup::"licence_status",
    Trustline::FieldGroup::"vehicle_registration",
    Trustline::FieldGroup::"accident_history",
    Trustline::FieldGroup::"insurance_detail",
    Trustline::FieldGroup::"inspection_history"
  ].contains(resource)
};

@id("P6-licensing-administration")
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"ReadFieldGroup",
  resource is Trustline::FieldGroup
)
when
{
  principal.roles.contains("licensing_officer") &&
  context.purpose == "LIC" &&
  [
    Trustline::FieldGroup::"identity_basic",
    Trustline::FieldGroup::"licence_status",
    Trustline::FieldGroup::"points_detail",
    Trustline::FieldGroup::"ticket_detail",
    Trustline::FieldGroup::"court_timeline"
  ].contains(resource)
};

@id("P7-court-system")
permit (
  principal is Trustline::Service,
  action == Trustline::Action::"ReadFieldGroup",
  resource is Trustline::FieldGroup
)
when
{
  principal.roles.contains("court_system") &&
  context.purpose == "CRT" &&
  [Trustline::FieldGroup::"ticket_detail", Trustline::FieldGroup::"court_timeline"].contains(resource)
};

@id("P8-ems-emergency-card")
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"ReadFieldGroup",
  resource is Trustline::FieldGroup
)
when
{
  principal.roles.contains("ems_responder") &&
  context.purpose == "EMS" &&
  context.incident_active &&
  context.emergency_consent &&
  [Trustline::FieldGroup::"identity_basic", Trustline::FieldGroup::"emergency_card"].contains(resource)
};

@id("P9-oversight-audit")
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"ReadFieldGroup",
  resource == Trustline::FieldGroup::"ledger_metadata"
)
when
{
  principal.roles.contains("oversight_analyst") &&
  context.purpose == "AUD"
};

@id("P10-citizen-own-record")
permit (
  principal is Trustline::Citizen,
  action == Trustline::Action::"ReadFieldGroup",
  resource is Trustline::FieldGroup
)
when
{
  context.is_self &&
  context.purpose == "CIT" &&
  [
    Trustline::FieldGroup::"identity_basic",
    Trustline::FieldGroup::"licence_status",
    Trustline::FieldGroup::"points_detail",
    Trustline::FieldGroup::"vehicle_registration",
    Trustline::FieldGroup::"insurance_status",
    Trustline::FieldGroup::"inspection_status",
    Trustline::FieldGroup::"compliance_summary",
    Trustline::FieldGroup::"ticket_detail",
    Trustline::FieldGroup::"court_timeline",
    Trustline::FieldGroup::"access_log_own"
  ].contains(resource)
};

// ---------------------------------------------------------------------------
// Operation permits
// ---------------------------------------------------------------------------

@id("O1-issue-ticket")
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"IssueTicket",
  resource == Trustline::Capability::"tickets"
)
when { principal.roles.containsAny(["traffic_officer", "patrol_officer", "supervisor"]) };

@id("O2-confirm-hit")
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"ConfirmHit",
  resource == Trustline::Capability::"hits"
)
when { principal.roles.contains("dispatcher") && context.purpose == "DSP" };

@id("O3-decide-licence-action")
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"DecideLicenceAction",
  resource == Trustline::Capability::"licence_actions"
)
when { principal.roles.contains("licensing_officer") && context.purpose == "LIC" };

@id("O4-request-deferral")
// Case- or entry-scoped deferral, or a renewal. The API also checks the case is open at source
// and that the requester belongs to the case team; the database enforces durations and continuity.
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"RequestDeferral",
  resource == Trustline::Capability::"deferrals"
)
when { principal.roles.contains("investigator") && context.purpose == "INV" };

@id("O5-approve-deferral")
// Approve or reject. Never the requester (database CHECK approved_by <> requested_by).
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"ApproveDeferral",
  resource == Trustline::Capability::"deferrals"
)
when { principal.roles.contains("supervisor") && context.purpose == "INV" };

@id("O5b-release-deferral-early")
// Early release only ever increases transparency, so the case team and oversight may do it.
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"ReleaseDeferral",
  resource == Trustline::Capability::"deferrals"
)
when
{
  (principal.roles.containsAny(["investigator", "supervisor"]) && context.purpose == "INV") ||
  (principal.roles.contains("oversight_analyst") && context.purpose == "AUD")
};

@id("O5c-designate-protected-identity")
// Undercover or protected officers: badge and unit never shown to citizens. Oversight must acknowledge.
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"DesignateProtectedIdentity",
  resource == Trustline::Capability::"designations"
)
when { principal.roles.contains("supervisor") && context.purpose == "INV" };

@id("O6-oversight-acknowledge-deferral")
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"AcknowledgeDeferral",
  resource == Trustline::Capability::"deferrals"
)
when { principal.roles.contains("oversight_analyst") && context.purpose == "AUD" };

@id("O6b-oversight-acknowledge-designation")
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"AcknowledgeDesignation",
  resource == Trustline::Capability::"designations"
)
when { principal.roles.contains("oversight_analyst") && context.purpose == "AUD" };

@id("O6c-oversight-review-alert")
permit (
  principal is Trustline::Officer,
  action == Trustline::Action::"ReviewAlert",
  resource == Trustline::Capability::"alerts"
)
when { principal.roles.contains("oversight_analyst") && context.purpose == "AUD" };

@id("O7-court-records")
permit (
  principal is Trustline::Service,
  action in [Trustline::Action::"RecordCourtOutcome", Trustline::Action::"RecordPayment"],
  resource == Trustline::Capability::"court_records"
)
when { principal.roles.contains("court_system") && context.purpose == "CRT" };
