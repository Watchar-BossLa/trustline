-- Disclosure-control scenario tests for db/schema.sql (R21, R22; AC23, AC24 at database level).
-- Run against a fresh database loaded with db/schema.sql:
--   psql -v ON_ERROR_STOP=1 -d <db> -f db/tests/disclosure_test.sql
-- Every check raises an exception on failure; the last line prints ALL DISCLOSURE TESTS PASSED.
-- All data is synthetic.

\set ON_ERROR_STOP 1
CREATE SCHEMA test;

-- ---------------------------------------------------------------- fixtures
INSERT INTO core.agency VALUES ('RSLPF', 'Royal Saint Lucia Police Force (synthetic)'), ('OVERSIGHT', 'Oversight (synthetic)');
INSERT INTO core.officer (id, badge_no, display_name, agency_code, unit, roles) VALUES
  ('00000000-0000-0000-0000-000000000101', 'OFF-101', 'PC Joel Marchand',   'RSLPF', 'Gros Islet Traffic', '{traffic_officer}'),
  ('00000000-0000-0000-0000-000000000102', 'OFF-102', 'PC Ryan Lafitte',    'RSLPF', 'Castries Traffic',   '{traffic_officer}'),
  ('00000000-0000-0000-0000-000000000301', 'INV-301', 'DC Tessa Grandval',  'RSLPF', 'CID',                '{investigator}'),
  ('00000000-0000-0000-0000-000000000302', 'CID-302', 'PC Alan Dauphin',    'RSLPF', 'CID',                '{traffic_officer}'),
  ('00000000-0000-0000-0000-000000000311', 'UC-311',  'Protected officer',  'RSLPF', 'Covert Operations',  '{investigator}'),
  ('00000000-0000-0000-0000-000000000401', 'SUP-401', 'Insp Marcus Belair', 'RSLPF', 'CID',                '{supervisor}'),
  ('00000000-0000-0000-0000-000000000701', 'DPC-701', 'Ruth Calixte',       'OVERSIGHT', 'Data Protection oversight', '{oversight_analyst}');
INSERT INTO ledger.signing_key VALUES ('k1', 'ledger', 'ed25519', decode(repeat('00', 32), 'hex'), '2026-01-01', NULL, 'active');
INSERT INTO core.protected_identity_designation (id, officer_id, reason, designated_by, designated_at)
  VALUES ('00000000-0000-0000-0000-00000000aa11', '00000000-0000-0000-0000-000000000311',
          'Undercover deployment, synthetic test', '00000000-0000-0000-0000-000000000401', '2026-10-01');

-- Insert one ledger entry and attach subjects. Hashes are placeholders (ledger crypto is tested in Rust).
CREATE FUNCTION test.ev(p_seq bigint, p_at timestamptz, p_badge text, p_purpose text, p_case text,
                        p_kind text, p_subjects bytea[], p_relations text[]) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE o core.officer%ROWTYPE; i int; prot boolean;
BEGIN
  SELECT * INTO o FROM core.officer WHERE badge_no = p_badge;
  prot := EXISTS (SELECT 1 FROM core.protected_identity_designation d
                  WHERE d.officer_id = o.id AND d.designated_at <= p_at AND (d.ended_at IS NULL OR d.ended_at > p_at));
  INSERT INTO ledger.access_event (seq, event_id, occurred_at, actor_type, actor_id, actor_badge, actor_roles,
    actor_agency, actor_unit, actor_protected, purpose, case_ref, request_kind, decision, policy_version,
    rules_version, http_status, canonical_body, prev_hash, entry_hash, signature, key_id)
  VALUES (p_seq, gen_random_uuid(), p_at, CASE WHEN p_badge IS NULL THEN 'citizen' ELSE 'officer' END::core.actor_type,
    o.id, o.badge_no, coalesce(o.roles, '{}'), coalesce(o.agency_code, 'CITIZEN'), o.unit, prot, p_purpose, p_case, p_kind,
    'allow', 'p1', 'r1', 200, '\x00', decode(repeat('00', 32), 'hex'),
    sha256(int8send(p_seq)), decode(repeat('22', 64), 'hex'), 'k1');
  FOR i IN 1 .. array_length(p_subjects, 1) LOOP
    INSERT INTO ledger.access_event_subject VALUES (p_seq, p_subjects[i], p_relations[i]::ledger.subject_relation);
  END LOOP;
END $$;

-- Visible log as JSON, without sequence numbers (the only field that legitimately differs between
-- two people's logs). Hold parameters as in rules/disclosure.yaml.
CREATE FUNCTION test.vis(p_subject bytea, p_now timestamptz, p_self boolean DEFAULT false) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT coalesce(jsonb_agg(to_jsonb(v) - 'seq' ORDER BY v.seq DESC), '[]'::jsonb)
  FROM citizen.visible_access_events(p_subject, p_now, interval '72 hours', ARRAY['INV', 'WAR'], p_self, NULL, 100) v
$$;
CREATE FUNCTION test.seqs(p_subject bytea, p_now timestamptz) RETURNS bigint[]
LANGUAGE sql AS $$
  SELECT coalesce(array_agg(v.seq ORDER BY v.seq DESC), '{}')
  FROM citizen.visible_access_events(p_subject, p_now, interval '72 hours', ARRAY['INV', 'WAR'], false, NULL, 100) v
$$;
CREATE FUNCTION test.check(p_ok boolean, p_name text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF NOT p_ok THEN RAISE EXCEPTION 'FAILED: %', p_name; END IF;
  RAISE NOTICE 'ok  %', p_name;
END $$;
CREATE FUNCTION test.must_fail(p_sql text, p_name text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ok  % (refused: %)', p_name, left(SQLERRM, 80);
    RETURN;
  END;
  RAISE EXCEPTION 'FAILED: % (was accepted)', p_name;
END $$;

-- Subjects (keyed hashes): X suspect, Y control person, Z co-owner of X's car, W lapse case.
-- T0 = 2026-11-01 12:00Z
-- X and Y receive identical non-investigative lookups; only X is also investigated.
SELECT test.ev(1, '2026-11-01 12:00Z', 'OFF-101', 'TS',  NULL,       'roadside_check',      '{\\x0a}', '{primary}');
SELECT test.ev(2, '2026-11-01 12:00Z', 'OFF-101', 'TS',  NULL,       'roadside_check',      '{\\x0b}', '{primary}');
SELECT test.ev(3, '2026-11-01 13:00Z', 'INV-301', 'INV', 'SYN-CASE-2026-0001', 'investigation_query', '{\\x0a}', '{primary}');
SELECT test.ev(4, '2026-11-01 14:00Z', 'UC-311',  'INV', 'SYN-CASE-2026-0001', 'investigation_query', '{\\x0a,\\x0c}', '{primary,vehicle_owner}');
SELECT test.ev(5, '2026-11-01 15:00Z', 'INV-301', 'INV', 'SYN-CASE-2026-0001', 'deferral_request',    '{\\x0a}', '{administrative}');
SELECT test.ev(6, '2026-11-02 18:00Z', 'CID-302', 'TS',  NULL,       'roadside_check',      '{\\x0a}', '{primary}');   -- pretext stop by case unit
SELECT test.ev(7, '2026-11-02 19:00Z', 'OFF-102', 'TS',  NULL,       'roadside_check',      '{\\x0a}', '{primary}');   -- uninvolved officer
SELECT test.ev(8, '2026-11-02 19:00Z', 'OFF-102', 'TS',  NULL,       'roadside_check',      '{\\x0b}', '{primary}');
SELECT test.ev(9, '2026-11-03 04:00Z', NULL,      'CIT', NULL,       'citizen_access_log',  '{\\x0a}', '{self}');
SELECT test.ev(10,'2026-11-03 04:00Z', NULL,      'CIT', NULL,       'citizen_access_log',  '{\\x0b}', '{self}');

-- ------------------------------------------------- R21: no trace while protected
SELECT test.check(test.seqs('\x0a', '2026-11-01 14:30Z') = '{1}', 'DF1 provisional hold: INV lookups withheld before any deferral');
SELECT test.check(test.vis('\x0a', '2026-11-01 14:30Z') = test.vis('\x0b', '2026-11-01 14:30Z'), 'DF2 suspect and control logs identical during hold');

-- Case deferral requested at T0+3h by INV-301 covering unit CID, approved by SUP-401 at T0+5h.
INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, case_ref, covered_units, coverage_from, chain_created_at,
  reason, requested_by, created_at, lapses_at, expires_at)
VALUES ('00000000-0000-0000-0000-0000000000d1', 'case', '\x0a', 'SYN-CASE-2026-0001', '{CID}', '2026-11-01 12:00Z',
  '2026-11-01 15:00Z', 'Covert phase of synthetic case 0001', '00000000-0000-0000-0000-000000000301',
  '2026-11-01 15:00Z', '2026-11-04 15:00Z', '2027-01-30 15:00Z');
SELECT test.must_fail($$UPDATE ledger.disclosure_deferral SET status = 'active', approved_by = requested_by, approved_at = '2026-11-01 17:00Z'
  WHERE id = '00000000-0000-0000-0000-0000000000d1'$$, 'DF3 self-approval refused');
UPDATE ledger.disclosure_deferral SET status = 'active', approved_by = '00000000-0000-0000-0000-000000000401',
  approved_at = '2026-11-01 17:00Z', decided_at = '2026-11-01 17:00Z' WHERE id = '00000000-0000-0000-0000-0000000000d1';

SELECT test.check(test.seqs('\x0a', '2026-11-05 12:00Z') = '{7,1}', 'DF4 after hold: case deferral withholds INV lookups and the case unit''s pretext stop; uninvolved stop visible');
SELECT test.check(test.vis('\x0a', '2026-11-05 12:00Z') = test.vis('\x0b', '2026-11-05 12:00Z'), 'DF5 indistinguishable: suspect log equals control log during deferral');
SELECT test.check(test.vis('\x0a', '2026-11-05 12:00Z', true) = test.vis('\x0b', '2026-11-05 12:00Z', true), 'DF6 indistinguishable with include_self');
SELECT test.check(test.seqs('\x0c', '2026-11-05 12:00Z') = '{}', 'DF7 co-owner of the vehicle does not see the protected lookup');
SELECT test.check(
  (SELECT array_agg(seq ORDER BY seq DESC) FROM citizen.visible_access_events('\x0a', '2026-11-05 12:00Z', '72 hours', '{INV,WAR}', false, NULL, 1)) = '{7}'
  AND (SELECT array_agg(seq ORDER BY seq DESC) FROM citizen.visible_access_events('\x0a', '2026-11-05 12:00Z', '72 hours', '{INV,WAR}', false, 7, 1)) = '{1}'
  AND NOT EXISTS (SELECT 1 FROM citizen.visible_access_events('\x0a', '2026-11-05 12:00Z', '72 hours', '{INV,WAR}', false, 1, 1)),
  'DF8 paging with limit 1 walks only visible entries (full pages, no gaps)');
SELECT test.check(NOT EXISTS (SELECT 1 FROM citizen.visible_access_events('\x0a', '2099-01-01', '72 hours', '{INV,WAR}', true, NULL, 100) v WHERE v.request_kind = 'deferral_request'),
  'DF9 administrative entries never appear, even after the deferral ends');

-- ------------------------------------------------- R22: accountable and time-limited
SELECT test.must_fail($$INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, case_ref, coverage_from, chain_created_at,
  reason, requested_by, created_at, lapses_at, expires_at) VALUES (gen_random_uuid(), 'case', '\x0b', 'SYN-CASE-2026-0002',
  '2026-10-01', '2026-11-05 12:00Z', 'Retroactive attempt synthetic', '00000000-0000-0000-0000-000000000301',
  '2026-11-05 12:00Z', '2026-11-06 12:00Z', '2026-12-01')$$, 'DF10 retroactive coverage beyond the hold refused (no visible entry can vanish)');
SELECT test.must_fail($$INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, event_seq, case_ref, coverage_from, chain_created_at,
  reason, requested_by, created_at, lapses_at, expires_at) VALUES (gen_random_uuid(), 'entry', '\x0a', 1, 'SYN-CASE-2026-0001',
  '2026-11-01 12:00Z', '2026-11-05 12:00Z', 'Hide an already visible stop', '00000000-0000-0000-0000-000000000301',
  '2026-11-05 12:00Z', '2026-11-06 12:00Z', '2026-12-01')$$, 'DF11 entry deferral for an already visible entry refused');
SELECT test.must_fail($$INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, case_ref, coverage_from, chain_created_at,
  reason, requested_by, created_at, lapses_at, expires_at) VALUES (gen_random_uuid(), 'case', '\x0b', 'SYN-CASE-2026-0003',
  '2026-11-05 12:00Z', '2026-11-05 12:00Z', 'Too long synthetic request', '00000000-0000-0000-0000-000000000301',
  '2026-11-05 12:00Z', '2026-11-06 12:00Z', '2027-03-01')$$, 'DF12 approval period over 90 days refused');

-- Renewal continues coverage with no gap at the boundary.
INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, case_ref, covered_units, coverage_from, chain_created_at,
  reason, requested_by, created_at, lapses_at, expires_at, renews, status, approved_by, approved_at, decided_at)
VALUES ('00000000-0000-0000-0000-0000000000d2', 'case', '\x0a', 'SYN-CASE-2026-0001', '{CID}', '2026-11-01 12:00Z',
  '2026-11-01 15:00Z', 'Renewal: covert phase continues', '00000000-0000-0000-0000-000000000301',
  '2027-01-25 12:00Z', '2027-01-28 12:00Z', '2027-04-24 12:00Z', '00000000-0000-0000-0000-0000000000d1',
  'active', '00000000-0000-0000-0000-000000000401', '2027-01-26 12:00Z', '2027-01-26 12:00Z');
SELECT test.check(test.seqs('\x0a', '2027-02-15') = '{7,1}', 'DF13 renewal: entries stay withheld after the first approval expires');
SELECT test.must_fail($$INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, case_ref, coverage_from, chain_created_at,
  reason, requested_by, created_at, lapses_at, expires_at, renews) VALUES (gen_random_uuid(), 'case', '\x0a', 'SYN-CASE-2026-0001',
  '2026-11-01 12:00Z', '2026-11-01 15:00Z', 'Late renewal synthetic', '00000000-0000-0000-0000-000000000301',
  '2027-04-25 12:00Z', '2027-04-26 12:00Z', '2027-06-01', '00000000-0000-0000-0000-0000000000d2')$$, 'DF14 renewal after expiry refused (no gap, no reappear-then-vanish)');
-- One-year cap: a renewal chain on a separate subject (V) runs past 365 days only with a magistrate's order.
CREATE FUNCTION test.renew(p_id uuid, p_prev uuid, p_created timestamptz, p_expires timestamptz, p_order text) RETURNS void
LANGUAGE sql AS $f$
  INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, case_ref, coverage_from, chain_created_at, reason, requested_by,
    created_at, lapses_at, expires_at, renews, magistrate_order_ref, status, approved_by, approved_at, decided_at)
  VALUES (p_id, 'case', '\x0f', 'SYN-CASE-2027-0009', '2027-01-01', '2027-01-01', 'Long-running synthetic case',
    '00000000-0000-0000-0000-000000000301', p_created, p_created + interval '1 day', p_expires, p_prev, p_order, 'active',
    '00000000-0000-0000-0000-000000000401', p_created + interval '2 hours', p_created + interval '2 hours')
$f$;
SELECT test.renew('00000000-0000-0000-0000-0000000000f1', NULL, '2027-01-01', '2027-03-31', NULL);
SELECT test.renew('00000000-0000-0000-0000-0000000000f2', '00000000-0000-0000-0000-0000000000f1', '2027-03-25', '2027-06-20', NULL);
SELECT test.renew('00000000-0000-0000-0000-0000000000f3', '00000000-0000-0000-0000-0000000000f2', '2027-06-15', '2027-09-10', NULL);
SELECT test.renew('00000000-0000-0000-0000-0000000000f4', '00000000-0000-0000-0000-0000000000f3', '2027-09-05', '2027-12-01', NULL);
SELECT test.must_fail($$SELECT test.renew('00000000-0000-0000-0000-0000000000f5', '00000000-0000-0000-0000-0000000000f4', '2027-11-25', '2028-02-20', NULL)$$,
  'DF15 chain beyond 365 days refused without a magistrate order');
SELECT test.renew('00000000-0000-0000-0000-0000000000f5', '00000000-0000-0000-0000-0000000000f4', '2027-11-25', '2028-02-20', 'SYN-MAG-ORDER-2027-17');
SELECT test.check(true, 'DF15b chain beyond 365 days accepted with a recorded magistrate order');

-- Early release by oversight: everything covered appears, marked with the delay; protected officer masked; INV reference withheld.
UPDATE ledger.disclosure_deferral SET status = 'released', released_at = '2027-03-01 12:00Z',
  released_by = '00000000-0000-0000-0000-000000000701', release_reason = 'Case closed (synthetic)'
  WHERE id = '00000000-0000-0000-0000-0000000000d2';
SELECT test.check(test.seqs('\x0a', '2027-03-02') = '{7,6,4,3,1}', 'DF16 release: withheld entries appear with their original times');
SELECT test.check((SELECT bool_and(v.deferred_until = '2027-03-01 12:00Z') FROM citizen.visible_access_events('\x0a', '2027-03-02', '72 hours', '{INV,WAR}', false, NULL, 100) v WHERE v.seq IN (3, 4, 6)),
  'DF17 released entries show the date disclosure was delayed until');
SELECT test.check((SELECT v.badge IS NULL AND v.unit IS NULL AND v.agency = 'RSLPF' FROM citizen.visible_access_events('\x0a', '2027-03-02', '72 hours', '{INV,WAR}', false, NULL, 100) v WHERE v.seq = 4),
  'DF18 protected officer shown as agency only, after release');
SELECT test.check((SELECT v.badge = 'INV-301' AND v.reference IS NULL FROM citizen.visible_access_events('\x0a', '2027-03-02', '72 hours', '{INV,WAR}', false, NULL, 100) v WHERE v.seq = 3),
  'DF19 case number never shown to the subject; ordinary badge shown');
SELECT test.check(test.seqs('\x0c', '2027-03-02') = '{4}', 'DF20 co-owner sees the lookup only after release');

-- Lapse: an unapproved request stops withholding after 72 hours.
SELECT test.ev(20, '2026-11-10 12:00Z', 'INV-301', 'INV', 'SYN-CASE-2026-0004', 'investigation_query', '{\\x0d}', '{primary}');
INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, case_ref, coverage_from, chain_created_at, reason, requested_by,
  created_at, lapses_at, expires_at)
VALUES ('00000000-0000-0000-0000-0000000000d3', 'case', '\x0d', 'SYN-CASE-2026-0004', '2026-11-10 12:00Z', '2026-11-12 12:00Z',
  'Never approved synthetic request', '00000000-0000-0000-0000-000000000301', '2026-11-12 12:00Z', '2026-11-15 12:00Z', '2027-01-01');
SELECT test.check(test.seqs('\x0d', '2026-11-14 12:00Z') = '{}', 'DF21 pending request withholds after the hold ends');
SELECT test.check(test.seqs('\x0d', '2026-11-15 13:00Z') = '{20}', 'DF22 unapproved request lapses and the entry appears');
SELECT test.check((SELECT v.deferred_until IS NULL FROM citizen.visible_access_events('\x0d', '2026-11-15 13:00Z', '72 hours', '{INV,WAR}', false, NULL, 100) v),
  'DF23 a lapsed request is not shown as an approved deferral');

-- Rejection releases at once (after the hold).
SELECT test.ev(21, '2026-11-20 12:00Z', 'INV-301', 'INV', 'SYN-CASE-2026-0005', 'investigation_query', '{\\x0e}', '{primary}');
INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, case_ref, coverage_from, chain_created_at, reason, requested_by,
  created_at, lapses_at, expires_at)
VALUES ('00000000-0000-0000-0000-0000000000d4', 'case', '\x0e', 'SYN-CASE-2026-0005', '2026-11-20 12:00Z', '2026-11-20 13:00Z',
  'Rejected synthetic request', '00000000-0000-0000-0000-000000000301', '2026-11-20 13:00Z', '2026-11-23 13:00Z', '2027-01-01');
UPDATE ledger.disclosure_deferral SET status = 'rejected', decided_at = '2026-11-21 09:00Z' WHERE id = '00000000-0000-0000-0000-0000000000d4';
SELECT test.check(test.seqs('\x0e', '2026-11-23 12:30Z') = '{21}', 'DF24 rejected request stops withholding once the hold ends');

-- Release ends the whole chain: an overlapping earlier approval and a pending renewal stop withholding too.
SELECT test.ev(30, '2026-12-01 12:00Z', 'INV-301', 'INV', 'SYN-CASE-2026-0006', 'investigation_query', '{\\x10}', '{primary}');
INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, case_ref, coverage_from, chain_created_at, reason, requested_by,
  created_at, lapses_at, expires_at, renews, status, approved_by, approved_at, decided_at) VALUES
  ('00000000-0000-0000-0000-0000000000a1', 'case', '\x10', 'SYN-CASE-2026-0006', '2026-12-01 12:00Z', '2026-12-01 13:00Z',
   'Overlap synthetic case first approval', '00000000-0000-0000-0000-000000000301', '2026-12-01 13:00Z', '2026-12-04 13:00Z',
   '2027-03-01 13:00Z', NULL, 'active', '00000000-0000-0000-0000-000000000401', '2026-12-01 14:00Z', '2026-12-01 14:00Z');
INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, case_ref, coverage_from, chain_created_at, reason, requested_by,
  created_at, lapses_at, expires_at, renews, status, approved_by, approved_at, decided_at) VALUES
  ('00000000-0000-0000-0000-0000000000a2', 'case', '\x10', 'SYN-CASE-2026-0006', '2026-12-01 12:00Z', '2026-12-01 13:00Z',
   'Overlap synthetic case early renewal', '00000000-0000-0000-0000-000000000301', '2026-12-02 13:00Z', '2026-12-05 13:00Z',
   '2027-03-02 13:00Z', '00000000-0000-0000-0000-0000000000a1', 'active', '00000000-0000-0000-0000-000000000401',
   '2026-12-02 14:00Z', '2026-12-02 14:00Z');
INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, case_ref, coverage_from, chain_created_at, reason, requested_by,
  created_at, lapses_at, expires_at, renews) VALUES
  ('00000000-0000-0000-0000-0000000000a3', 'case', '\x10', 'SYN-CASE-2026-0006', '2026-12-01 12:00Z', '2026-12-01 13:00Z',
   'Overlap synthetic case pending renewal', '00000000-0000-0000-0000-000000000301', '2026-12-03 13:00Z', '2026-12-06 13:00Z',
   '2027-03-03 13:00Z', '00000000-0000-0000-0000-0000000000a2');
SELECT test.check(test.seqs('\x10', '2026-12-04 13:00Z') = '{}', 'DF26a overlapping chain withholds after the hold ends');
UPDATE ledger.disclosure_deferral SET status = 'released', released_at = '2026-12-04 12:00Z',
  released_by = '00000000-0000-0000-0000-000000000701', release_reason = 'Oversight release (synthetic)'
  WHERE id = '00000000-0000-0000-0000-0000000000a2';
SELECT test.check(test.seqs('\x10', '2026-12-04 13:00Z') = '{30}'
  AND (SELECT v.deferred_until = '2026-12-04 12:00Z' FROM citizen.visible_access_events('\x10', '2026-12-04 13:00Z', '72 hours', '{INV,WAR}', false, NULL, 100) v)
  AND (SELECT array_agg(status::text ORDER BY id) FROM ledger.disclosure_deferral WHERE subject_key = '\x10') = '{released,released,rejected}',
  'DF26 release ends the whole chain: overlapping approval released, pending renewal rejected, entry visible at once');
SELECT test.must_fail($$INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, case_ref, coverage_from, chain_created_at,
  reason, requested_by, created_at, lapses_at, expires_at, renews) VALUES (gen_random_uuid(), 'case', '\x10', 'SYN-CASE-2026-0006',
  '2026-12-01 12:00Z', '2026-12-01 13:00Z', 'Revive a released chain', '00000000-0000-0000-0000-000000000301',
  '2026-12-04 14:00Z', '2026-12-05 14:00Z', '2027-02-01', '00000000-0000-0000-0000-0000000000a1')$$, 'DF27 a released chain cannot be renewed');
-- Exact 72-hour boundary: the entry has just become visible, so it can no longer be deferred.
SELECT test.ev(31, '2026-12-10 12:00Z', 'INV-301', 'INV', 'SYN-CASE-2026-0007', 'investigation_query', '{\\x0b}', '{primary}');
SELECT test.must_fail($$INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, event_seq, case_ref, coverage_from, chain_created_at,
  reason, requested_by, created_at, lapses_at, expires_at) VALUES (gen_random_uuid(), 'entry', '\x0b', 31, 'SYN-CASE-2026-0007',
  '2026-12-10 12:00Z', '2026-12-13 12:00Z', 'Boundary entry deferral', '00000000-0000-0000-0000-000000000301',
  '2026-12-13 12:00Z', '2026-12-14 12:00Z', '2027-01-01')$$, 'DF28 entry deferral at exactly 72 hours refused');
SELECT test.must_fail($$INSERT INTO ledger.disclosure_deferral (id, scope, subject_key, case_ref, coverage_from, chain_created_at,
  reason, requested_by, created_at, lapses_at, expires_at) VALUES (gen_random_uuid(), 'case', '\x0b', 'SYN-CASE-2026-0007',
  '2026-12-10 12:00Z', '2026-12-13 12:00Z', 'Boundary case deferral', '00000000-0000-0000-0000-000000000301',
  '2026-12-13 12:00Z', '2026-12-14 12:00Z', '2027-01-01')$$, 'DF28b case coverage reaching back exactly 72 hours refused');

-- Ledger stays immutable throughout.
SELECT test.must_fail($$DELETE FROM ledger.access_event WHERE seq = 4$$, 'DF25 withheld entries are never deleted from the ledger');

DROP SCHEMA test CASCADE;
\echo ALL DISCLOSURE TESTS PASSED
