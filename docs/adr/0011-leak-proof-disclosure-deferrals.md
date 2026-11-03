# ADR 0011 — Leak-proof, accountable disclosure deferrals

- Status: Accepted
- Date: 2026-11-02
- Deciders: Kelvin Wilson Antoine (owner; approved the deferral design and asked that it be made
  leak-proof); drafted with Claude. Legal values remain subject to Saint Lucian counsel (HL11).

## Context
The citizen access log ("who viewed my data") is TRUSTLINE's signature feature. Without control it
would tell a suspect, within a minute, that an investigator had looked them up, and would show an
undercover officer's badge. A deferral that leaks in any other way (a page that comes back one row
short, a dispute that answers "withheld" instead of "not found", a co-owner of the suspect's car who
sees the lookup, a deferral request that itself appears in the log, a renewal that lets entries
flicker into view) is as bad as no deferral. At the same time, deferrals are the easiest way to hide
misuse from citizens (threat T16), so they must stay accountable.

## Decision
1. **One read path.** Citizen-facing access entries are read only through the SQL function
   `citizen.visible_access_events` in `db/schema.sql`. It withholds entries before ordering and paging.
2. **Provisional hold.** INV and WAR lookups are withheld for 72 hours automatically, so an
   investigator has time to request a deferral before anything reaches the subject.
3. **Case-scoped deferrals.** A deferral covers the subject's lookups that cite the case, or that were
   made by the case team's units (so a pretext traffic stop is covered); uninvolved officers' lookups
   stay visible. Entry-scoped deferrals exist for single entries still under hold.
4. **Withhold from everyone attached.** A covered entry is hidden from every person on it, not only
   the named subject (for example a vehicle's co-owner).
5. **Never make a visible entry vanish.** Coverage can reach back at most 72 hours (only entries still
   on hold); entry deferrals only while the entry is withheld; renewals only while the previous
   deferral is active, inheriting its coverage start. Enforced by CHECK constraints and a trigger.
6. **Administrative entries are invisible.** Deferral and designation handling is written to the
   ledger with subject relation `administrative`, which no citizen log shows.
7. **Protected identities.** A supervisor can designate an officer (for example undercover) whose
   badge and unit are never shown to citizens, before or after release. The ledger keeps the full
   identity; oversight sees and acknowledges every designation.
8. **References withheld.** Case and warrant numbers are never shown to the subject.
9. **Accountability.** Approval by a different supervisor; pending requests lapse after 72 hours;
   at most 90 days per approval; a chain beyond 365 days needs a recorded magistrate's order;
   early release by the case team or oversight; oversight sees every deferral in real time; released
   entries carry `deferred_until`; published reports show deferral counts nationally only, with cells
   under 5 suppressed.

## Consequences
- Verified on 2 Nov 2026: `db/tests/disclosure_test.sql` (25 scenarios, DF1–DF25) passes against
  PostgreSQL 16, including the indistinguishability checks (the suspect's log equals a control
  person's log during the hold and the deferral, with and without self views, page by page).
- The API must add the same guarantee at the HTTP layer (AC23 leak suite, persona S8 vs control S11).
- Pilot dependency: source agencies' own audit or self-service portals must honour deferral status
  (passed with X-Road requests), and formal subject-access requests to RSLPF rely on the Data
  Protection Act's Part 6 exemptions. Both need counsel.
- Disclosure is delayed, never cancelled: when a deferral ends, the subject sees the lookups. A
  government that wants permanent secrecy for some lookups needs a legal basis and a decision by
  the Data Protection Commissioner; this design does not provide it.

## Alternatives rejected
- No deferrals (rejected: tips off suspects; RSLPF would not adopt the system).
- Excluding all police investigative lookups from the citizen log (rejected: destroys the
  accountability that is the system's selling point, and the main control against misuse).
- Filtering in application code after the query (rejected: page sizes, cursors and counts leak).
- Deferrals visible only to the requesting unit (rejected: no independent oversight).
