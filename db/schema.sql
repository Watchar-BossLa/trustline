-- TRUSTLINE canonical schema — PostgreSQL 16
-- Source of truth for M1 (node m1_schema). Migrations in db/migrations/ are generated from
-- this file; a CI check fails if they drift.
--
-- Principles enforced here:
--   * TRUSTLINE stores no agency master records (HL3). Personal identifiers appear only as
--     keyed hashes (bytea, HMAC-SHA-256) or envelope-encrypted values (*_enc bytea) (HL4).
--   * The access ledger is append-only (HL8): app role has INSERT/SELECT only and a trigger
--     rejects UPDATE/DELETE for everyone.
--   * Licence actions require a recorded human decision (HL5).

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------------
-- Roles (created only if absent; passwords are set outside this file)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'trustline_app') THEN
    CREATE ROLE trustline_app NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'trustline_oversight') THEN
    CREATE ROLE trustline_oversight NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'trustline_migrator') THEN
    CREATE ROLE trustline_migrator NOLOGIN;
  END IF;
END
$$;

CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS ledger;
CREATE SCHEMA IF NOT EXISTS tickets;
CREATE SCHEMA IF NOT EXISTS demerit;
CREATE SCHEMA IF NOT EXISTS citizen;
CREATE SCHEMA IF NOT EXISTS oversight;
CREATE SCHEMA IF NOT EXISTS ems;

-- ---------------------------------------------------------------------------
-- Enumerations
-- ---------------------------------------------------------------------------
CREATE TYPE core.identifier_type   AS ENUM ('NIC', 'DL', 'PLATE');
CREATE TYPE core.actor_type        AS ENUM ('officer', 'citizen', 'service', 'system');
CREATE TYPE core.record_status     AS ENUM ('active', 'suspended', 'revoked');
CREATE TYPE core.hit_kind          AS ENUM ('warrant', 'stolen_vehicle');
CREATE TYPE core.hit_status        AS ENUM ('unconfirmed', 'confirmed', 'cleared');
CREATE TYPE ledger.decision        AS ENUM ('allow', 'partial', 'deny', 'error', 'rate_limited');
CREATE TYPE ledger.subject_relation AS ENUM ('primary', 'resolved_holder', 'vehicle_owner', 'self');
CREATE TYPE ledger.deferral_status AS ENUM ('pending_approval', 'active', 'released', 'rejected');
CREATE TYPE tickets.ticket_status  AS ENUM ('issued', 'paid', 'referred_to_court', 'convicted', 'dismissed', 'withdrawn');
CREATE TYPE tickets.payment_channel AS ENUM ('online_simulated', 'court_counter', 'government_platform');
CREATE TYPE tickets.court_outcome  AS ENUM ('pending', 'convicted', 'dismissed', 'withdrawn');
CREATE TYPE tickets.appeal_status  AS ENUM ('none', 'pending', 'upheld', 'overturned');
CREATE TYPE demerit.conviction_source AS ENUM ('ticket_payment', 'court');
CREATE TYPE demerit.action_kind    AS ENUM ('notice_11_13', 'interview_14_17', 'suspend_6m', 'suspend_1y',
                                            'suspend_until_compliance', 'disqualify_unpaid_fine');
CREATE TYPE demerit.proposal_status AS ENUM ('pending', 'confirmed', 'rejected', 'superseded');
CREATE TYPE demerit.licence_action_status AS ENUM ('active', 'ended', 'overturned');
CREATE TYPE citizen.dispute_status AS ENUM ('open', 'under_review', 'upheld', 'not_upheld');
CREATE TYPE oversight.alert_status AS ENUM ('open', 'reviewing', 'closed_no_issue', 'referred');
CREATE TYPE oversight.severity     AS ENUM ('info', 'low', 'medium', 'high');

-- ---------------------------------------------------------------------------
-- core: actors, devices, reference data, subject references, hits, bundles
-- ---------------------------------------------------------------------------
CREATE TABLE core.agency (
  code            text PRIMARY KEY,                 -- e.g. RSLPF, TRANSPORT, COURTS, MOH
  name            text NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE core.officer (
  id              uuid PRIMARY KEY,
  badge_no        text NOT NULL UNIQUE,             -- e.g. OFF-101 (synthetic in this build)
  display_name    text NOT NULL,
  agency_code     text NOT NULL REFERENCES core.agency(code),
  unit            text NOT NULL,
  roles           text[] NOT NULL CHECK (cardinality(roles) > 0),
  status          core.record_status NOT NULL DEFAULT 'active',
  subject_key     bytea,                            -- officer's own NIC key, for self/colleague-lookup rules
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE core.device (
  id              uuid PRIMARY KEY,
  officer_id      uuid NOT NULL REFERENCES core.officer(id),
  label           text NOT NULL,
  public_key      bytea NOT NULL,                   -- X25519 for bundle encryption
  attestation     jsonb,                            -- pilot: WebAuthn/Android attestation evidence
  attested        boolean NOT NULL DEFAULT false,
  status          core.record_status NOT NULL DEFAULT 'active',
  registered_at   timestamptz NOT NULL DEFAULT now(),
  revoked_at      timestamptz
);
CREATE INDEX device_officer_idx ON core.device(officer_id);

CREATE TABLE core.service_principal (
  id              uuid PRIMARY KEY,
  name            text NOT NULL UNIQUE,             -- e.g. court-traffic-part
  roles           text[] NOT NULL,
  status          core.record_status NOT NULL DEFAULT 'active',
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE core.reason_code (                     -- loaded from rules/reason-codes.yaml
  code            text PRIMARY KEY,
  description     text NOT NULL,
  requires        text NOT NULL CHECK (requires IN ('none', 'case_ref', 'incident_ref', 'warrant_ref')),
  rules_version   text NOT NULL
);

CREATE TABLE core.hit (
  id              uuid PRIMARY KEY,
  kind            core.hit_kind NOT NULL,
  subject_key     bytea NOT NULL,
  source_agency   text NOT NULL REFERENCES core.agency(code),
  source_ref      text NOT NULL,                    -- warrant or stolen-report reference at source
  raised_event_seq bigint NOT NULL,                 -- ledger entry that produced the match
  status          core.hit_status NOT NULL DEFAULT 'unconfirmed',
  decided_by      uuid REFERENCES core.officer(id),
  decided_at      timestamptz,
  decision_note   text,
  decision_event_seq bigint,
  created_at      timestamptz NOT NULL DEFAULT now(),
  CHECK ((status = 'unconfirmed') = (decided_by IS NULL))
);
CREATE INDEX hit_open_idx ON core.hit(status) WHERE status = 'unconfirmed';

CREATE TABLE core.offline_bundle (
  id              uuid PRIMARY KEY,
  device_id       uuid NOT NULL REFERENCES core.device(id),
  issued_at       timestamptz NOT NULL,
  expires_at      timestamptz NOT NULL,
  key_id          text NOT NULL,
  sha256          bytea NOT NULL,
  entry_count     integer NOT NULL CHECK (entry_count >= 0),
  CHECK (expires_at > issued_at)
);

-- ---------------------------------------------------------------------------
-- ledger: append-only access log, subjects, checkpoints, keys, deferrals
-- ---------------------------------------------------------------------------
CREATE TABLE ledger.signing_key (
  key_id          text PRIMARY KEY,
  purpose         text NOT NULL CHECK (purpose IN ('ledger', 'checkpoint', 'bundle')),
  algorithm       text NOT NULL DEFAULT 'ed25519' CHECK (algorithm = 'ed25519'),
  public_key      bytea NOT NULL,
  valid_from      timestamptz NOT NULL,
  valid_to        timestamptz,
  status          text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'retired', 'compromised'))
);

CREATE TABLE ledger.access_event (
  seq             bigint PRIMARY KEY,               -- assigned by the writer under an advisory lock; gap-free
  event_id        uuid NOT NULL UNIQUE,
  occurred_at     timestamptz NOT NULL,
  actor_type      core.actor_type NOT NULL,
  actor_id        uuid,                             -- officer, service principal or NULL for citizen (see subject)
  actor_badge     text,
  actor_roles     text[] NOT NULL DEFAULT '{}',
  actor_agency    text,
  actor_unit      text,
  device_id       uuid,
  purpose         text NOT NULL,
  case_ref        text,
  incident_ref    text,
  warrant_ref     text,
  request_kind    text NOT NULL,                    -- e.g. roadside_check, investigation_query, ticket_issue
  identifier_type core.identifier_type,
  decision        ledger.decision NOT NULL,
  permitted_groups text[] NOT NULL DEFAULT '{}',
  denied_groups   text[] NOT NULL DEFAULT '{}',
  policy_version  text NOT NULL,
  rules_version   text NOT NULL,
  sources         jsonb NOT NULL DEFAULT '[]',      -- [{agency, xroad_id, status, ms}]
  response_digest bytea,                            -- SHA-256 of the response body, never the body
  http_status     smallint NOT NULL,
  offline         boolean NOT NULL DEFAULT false,
  offline_recorded_at timestamptz,                  -- device time for synced offline checks
  location_lat    numeric(8,5),
  location_lon    numeric(8,5),
  canonical_body  bytea NOT NULL,                   -- RFC 8785 bytes that were hashed
  prev_hash       bytea NOT NULL CHECK (octet_length(prev_hash) = 32),
  entry_hash      bytea NOT NULL UNIQUE CHECK (octet_length(entry_hash) = 32),
  signature       bytea NOT NULL CHECK (octet_length(signature) = 64),
  key_id          text NOT NULL REFERENCES ledger.signing_key(key_id),
  recorded_at     timestamptz NOT NULL DEFAULT now(),
  CHECK (seq >= 1),
  CHECK (offline = (offline_recorded_at IS NOT NULL))
);
CREATE INDEX access_event_actor_idx ON ledger.access_event(actor_id, occurred_at);
CREATE INDEX access_event_time_idx  ON ledger.access_event(occurred_at);

CREATE TABLE ledger.access_event_subject (
  event_seq       bigint NOT NULL REFERENCES ledger.access_event(seq),
  subject_key     bytea NOT NULL,                   -- HMAC-SHA-256 keyed hash, never a raw identifier
  relation        ledger.subject_relation NOT NULL,
  PRIMARY KEY (event_seq, subject_key, relation)
);
CREATE INDEX access_event_subject_key_idx ON ledger.access_event_subject(subject_key, event_seq);

CREATE TABLE ledger.checkpoint (
  id              bigserial PRIMARY KEY,
  from_seq        bigint NOT NULL,
  to_seq          bigint NOT NULL,
  merkle_root     bytea NOT NULL CHECK (octet_length(merkle_root) = 32),
  signed_at       timestamptz NOT NULL,
  signature       bytea NOT NULL CHECK (octet_length(signature) = 64),
  key_id          text NOT NULL REFERENCES ledger.signing_key(key_id),
  CHECK (to_seq >= from_seq),
  UNIQUE (from_seq, to_seq)
);

CREATE TABLE ledger.disclosure_deferral (
  id              uuid PRIMARY KEY,
  event_seq       bigint NOT NULL REFERENCES ledger.access_event(seq),
  subject_key     bytea NOT NULL,
  case_ref        text NOT NULL,
  reason          text NOT NULL,
  requested_by    uuid NOT NULL REFERENCES core.officer(id),
  approved_by     uuid REFERENCES core.officer(id),
  approved_at     timestamptz,
  expires_at      timestamptz NOT NULL,
  status          ledger.deferral_status NOT NULL DEFAULT 'pending_approval',
  oversight_acknowledged_at timestamptz,
  released_at     timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CHECK (status <> 'active' OR approved_by IS NOT NULL)
);
CREATE INDEX deferral_subject_idx ON ledger.disclosure_deferral(subject_key, status);

-- Append-only guard: rejects UPDATE/DELETE on ledger tables for every role, owner included.
CREATE FUNCTION ledger.reject_mutation() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'ledger tables are append-only (% on %)', TG_OP, TG_TABLE_NAME
    USING ERRCODE = 'insufficient_privilege';
END
$$;

CREATE TRIGGER access_event_append_only
  BEFORE UPDATE OR DELETE ON ledger.access_event
  FOR EACH ROW EXECUTE FUNCTION ledger.reject_mutation();
CREATE TRIGGER access_event_subject_append_only
  BEFORE UPDATE OR DELETE ON ledger.access_event_subject
  FOR EACH ROW EXECUTE FUNCTION ledger.reject_mutation();
CREATE TRIGGER checkpoint_append_only
  BEFORE UPDATE OR DELETE ON ledger.checkpoint
  FOR EACH ROW EXECUTE FUNCTION ledger.reject_mutation();
CREATE TRIGGER access_event_no_truncate
  BEFORE TRUNCATE ON ledger.access_event
  FOR EACH STATEMENT EXECUTE FUNCTION ledger.reject_mutation();

-- ---------------------------------------------------------------------------
-- tickets: offences, tickets, payments, court referrals, fines
-- ---------------------------------------------------------------------------
CREATE TABLE tickets.offence (                      -- loaded from rules/offences.yaml
  code            text PRIMARY KEY,                 -- e.g. MVRTA-DANGEROUS-DRIVING
  description     text NOT NULL,
  act_section     text,
  fixed_penalty_ecd numeric(10,2),                  -- NULL until verified from the Regulations
  ticketable      boolean NOT NULL,
  demerit_paragraph text,                           -- Schedule 2 paragraph, e.g. 2(d)
  verified        boolean NOT NULL DEFAULT false,
  rules_version   text NOT NULL
);

CREATE TABLE tickets.ticket (
  id              uuid PRIMARY KEY,
  ticket_no       text NOT NULL UNIQUE,             -- e.g. SYN-T-2026-000123
  issued_at       timestamptz NOT NULL,
  officer_id      uuid NOT NULL REFERENCES core.officer(id),
  device_id       uuid REFERENCES core.device(id),
  subject_key     bytea NOT NULL,                   -- driver's NIC key
  driver_identifier_enc bytea NOT NULL,             -- envelope-encrypted licence/NIC for the court
  vehicle_plate_enc bytea,
  offence_code    text NOT NULL REFERENCES tickets.offence(code),
  incident_id     uuid,                             -- groups offences from one occurrence (s.179(3))
  location_text   text,
  location_lat    numeric(8,5),
  location_lon    numeric(8,5),
  fixed_penalty_ecd numeric(10,2),
  payment_due_at  timestamptz,
  status          tickets.ticket_status NOT NULL DEFAULT 'issued',
  issue_event_seq bigint NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ticket_subject_idx ON tickets.ticket(subject_key, issued_at);

CREATE TABLE tickets.payment (
  id              uuid PRIMARY KEY,
  ticket_id       uuid NOT NULL REFERENCES tickets.ticket(id),
  amount_ecd      numeric(10,2) NOT NULL CHECK (amount_ecd >= 0),
  paid_at         timestamptz NOT NULL,
  channel         tickets.payment_channel NOT NULL,
  reference       text NOT NULL,
  confirmed_by_court boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tickets.court_referral (
  id              uuid PRIMARY KEY,
  ticket_id       uuid NOT NULL UNIQUE REFERENCES tickets.ticket(id),
  referred_at     timestamptz NOT NULL,
  court_case_ref  text NOT NULL UNIQUE,
  next_hearing_at timestamptz,
  outcome         tickets.court_outcome NOT NULL DEFAULT 'pending',
  outcome_at      timestamptz,
  appeal_status   tickets.appeal_status NOT NULL DEFAULT 'none',
  appeal_decided_at timestamptz
);

CREATE TABLE tickets.court_fine (                   -- section 107: fines imposed on conviction
  id              uuid PRIMARY KEY,
  court_case_ref  text NOT NULL UNIQUE,
  subject_key     bytea NOT NULL,
  amount_ecd      numeric(10,2) NOT NULL CHECK (amount_ecd > 0),
  proceedings_concluded_at timestamptz NOT NULL,    -- including any appeal
  paid_at         timestamptz,
  payment_confirmed_by_clerk boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX court_fine_unpaid_idx ON tickets.court_fine(proceedings_concluded_at) WHERE paid_at IS NULL;

-- ---------------------------------------------------------------------------
-- demerit: incidents, convictions, proposed and effective licence actions
-- ---------------------------------------------------------------------------
CREATE TABLE demerit.incident (
  id              uuid PRIMARY KEY,
  subject_key     bytea NOT NULL,
  occurred_at     timestamptz NOT NULL
);

CREATE TABLE demerit.conviction (
  id              uuid PRIMARY KEY,
  subject_key     bytea NOT NULL,
  incident_id     uuid NOT NULL REFERENCES demerit.incident(id),
  schedule_paragraph text NOT NULL,                 -- Schedule 2 paragraph, e.g. 2(d)
  points          smallint NOT NULL CHECK (points BETWEEN 0 AND 20),
  convicted_at    timestamptz NOT NULL,
  source          demerit.conviction_source NOT NULL,
  ticket_id       uuid REFERENCES tickets.ticket(id),
  court_case_ref  text,
  appeal_status   tickets.appeal_status NOT NULL DEFAULT 'none',
  counted         boolean NOT NULL,                 -- false when excluded by the same-incident rule or appeal
  rules_version   text NOT NULL,
  recorded_at     timestamptz NOT NULL DEFAULT now(),
  CHECK (source <> 'ticket_payment' OR ticket_id IS NOT NULL),
  CHECK (source <> 'court' OR court_case_ref IS NOT NULL)
);
CREATE INDEX conviction_subject_idx ON demerit.conviction(subject_key, convicted_at);

CREATE TABLE demerit.proposed_action (
  id              uuid PRIMARY KEY,
  subject_key     bytea NOT NULL,
  kind            demerit.action_kind NOT NULL,
  basis           jsonb NOT NULL,                   -- points snapshot, conviction ids, rule applied
  rules_version   text NOT NULL,
  engine_version  text NOT NULL,
  status          demerit.proposal_status NOT NULL DEFAULT 'pending',
  decided_by      uuid REFERENCES core.officer(id),
  decided_at      timestamptz,
  decision_note   text,
  decision_event_seq bigint,
  created_at      timestamptz NOT NULL DEFAULT now(),
  CHECK ((status IN ('confirmed', 'rejected')) = (decided_by IS NOT NULL AND decided_at IS NOT NULL))
);
CREATE INDEX proposed_action_pending_idx ON demerit.proposed_action(status, created_at) WHERE status = 'pending';

CREATE TABLE demerit.licence_action (
  id              uuid PRIMARY KEY,
  subject_key     bytea NOT NULL,
  kind            demerit.action_kind NOT NULL,
  proposed_action_id uuid NOT NULL UNIQUE REFERENCES demerit.proposed_action(id),
  authorised_by   uuid NOT NULL REFERENCES core.officer(id),   -- HL5: a human decision is mandatory
  starts_at       timestamptz NOT NULL,
  ends_at         timestamptz,                      -- NULL = until compliance or payment
  appeal_deadline timestamptz,
  status          demerit.licence_action_status NOT NULL DEFAULT 'active',
  ended_at        timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  CHECK (kind IN ('suspend_6m', 'suspend_1y', 'suspend_until_compliance', 'disqualify_unpaid_fine'))
);
CREATE INDEX licence_action_active_idx ON demerit.licence_action(subject_key) WHERE status = 'active';

-- A licence action can only exist for a proposal that a person confirmed.
CREATE FUNCTION demerit.require_confirmed_proposal() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE p demerit.proposed_action%ROWTYPE;
BEGIN
  SELECT * INTO p FROM demerit.proposed_action WHERE id = NEW.proposed_action_id;
  IF p.status IS DISTINCT FROM 'confirmed' OR p.decided_by IS DISTINCT FROM NEW.authorised_by THEN
    RAISE EXCEPTION 'licence action requires a proposal confirmed by the authorising officer';
  END IF;
  RETURN NEW;
END
$$;
CREATE TRIGGER licence_action_requires_confirmation
  BEFORE INSERT ON demerit.licence_action
  FOR EACH ROW EXECUTE FUNCTION demerit.require_confirmed_proposal();

-- ---------------------------------------------------------------------------
-- citizen: disputes
-- ---------------------------------------------------------------------------
CREATE TABLE citizen.dispute (
  id              uuid PRIMARY KEY,
  subject_key     bytea NOT NULL,
  event_seq       bigint REFERENCES ledger.access_event(seq),
  ticket_id       uuid REFERENCES tickets.ticket(id),
  body            text NOT NULL CHECK (length(body) BETWEEN 1 AND 4000),
  status          citizen.dispute_status NOT NULL DEFAULT 'open',
  resolution_note text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  resolved_at     timestamptz,
  CHECK (event_seq IS NOT NULL OR ticket_id IS NOT NULL)
);

-- ---------------------------------------------------------------------------
-- oversight: alerts and monthly reports (aggregates only)
-- ---------------------------------------------------------------------------
CREATE TABLE oversight.alert (
  id              uuid PRIMARY KEY,
  rule_code       text NOT NULL,                    -- from rules/anomaly-rules.yaml
  severity        oversight.severity NOT NULL,
  officer_id      uuid REFERENCES core.officer(id),
  subject_key     bytea,
  event_seqs      bigint[] NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  status          oversight.alert_status NOT NULL DEFAULT 'open',
  reviewer        text,
  review_note     text,
  reviewed_at     timestamptz,
  rules_version   text NOT NULL
);
CREATE INDEX alert_open_idx ON oversight.alert(status, created_at);

CREATE TABLE oversight.monthly_report (
  id              uuid PRIMARY KEY,
  period_start    date NOT NULL,
  period_end      date NOT NULL,
  generated_at    timestamptz NOT NULL,
  aggregates      jsonb NOT NULL,                   -- counts only; no identifiers or keys
  checkpoint_roots jsonb NOT NULL,                  -- [{from_seq, to_seq, merkle_root_hex}]
  published       boolean NOT NULL DEFAULT false,
  UNIQUE (period_start, period_end),
  CHECK (period_end >= period_start)
);

-- ---------------------------------------------------------------------------
-- ems: emergency-card consent (content stays with the Ministry of Health)
-- ---------------------------------------------------------------------------
CREATE TABLE ems.emergency_card_consent (
  subject_key     bytea PRIMARY KEY,
  opted_in_at     timestamptz NOT NULL,
  withdrawn_at    timestamptz,
  consent_text_version text NOT NULL,
  CHECK (withdrawn_at IS NULL OR withdrawn_at >= opted_in_at)
);

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------
GRANT USAGE ON SCHEMA core, ledger, tickets, demerit, citizen, oversight, ems TO trustline_app;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA core, tickets, demerit, citizen, oversight, ems TO trustline_app;
GRANT SELECT, INSERT ON ledger.access_event, ledger.access_event_subject, ledger.checkpoint TO trustline_app;
GRANT SELECT ON ledger.signing_key TO trustline_app;
GRANT SELECT, INSERT, UPDATE ON ledger.disclosure_deferral TO trustline_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ledger TO trustline_app;
REVOKE DELETE, TRUNCATE ON ALL TABLES IN SCHEMA core, ledger, tickets, demerit, citizen, oversight, ems FROM trustline_app;

GRANT USAGE ON SCHEMA ledger, oversight TO trustline_oversight;
GRANT SELECT ON ledger.access_event, ledger.checkpoint, ledger.disclosure_deferral, ledger.signing_key TO trustline_oversight;
GRANT SELECT, UPDATE ON oversight.alert TO trustline_oversight;
GRANT SELECT ON oversight.monthly_report TO trustline_oversight;

COMMIT;
