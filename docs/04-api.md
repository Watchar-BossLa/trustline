# 04 — API guide

`api/openapi.yaml` (OpenAPI 3.1, validated with openapi-spec-validator on 2 Nov 2026) is the
contract: 37 operations, 32 ledger-scoped (`x-ledger: true`), 1 per-item (`x-ledger: per_item`,
offline sync) and 4 without personal data (`x-ledger: false`). This guide explains the
conventions the server must follow.

## Conventions

| Topic | Rule |
| --- | --- |
| Identifiers | NIC, licence and plate travel only in JSON bodies (`Identifier`), never in URLs or query strings. Lookups are therefore `POST`. |
| Purpose | Every officer request states a purpose (`purpose` field, or implied by the endpoint's single `x-purposes` value). References (`case_ref`, `warrant_ref`, `incident_ref`) are validated at source before policy. |
| Device | Officer calls send `X-Device-Id`. Unknown, revoked or unattested devices → 403 and a deny entry. |
| Ledger | Ledger middleware wraps every `x-ledger: true` route and writes exactly one entry, whatever the outcome. The response carries `ledger_seq` (body or Problem). |
| Errors | `application/problem+json`. Messages never reveal which agency holds a record or why a group was denied beyond its name. |
| Unknown vs stale | A failed source sets the section's `availability` to `unknown` and the source status to `timeout` or `error`. Never serve cached personal data. |
| Synthetic | Every personal-data response includes `synthetic: true`; responses that apply rules include `legal_rules_verified`. |
| Rate limits | 429 with `Retry-After`; the denial is a `rate_limited` ledger entry. Limits in docs/02 §11. |
| Disclosure | Citizen access entries come only from `citizen.visible_access_events`; a withheld entry must be indistinguishable from one that never existed (identical 404s, no counts, full pages). See ADR 0011. |
| Versioning | Path prefix `/v1`. Breaking changes need a new version and a spec change through Prompt D. |
| Time | RFC 3339 UTC in the API; the web app shows Saint Lucia time (UTC−04:00). |
| Money | `*_ecd` fields are Eastern Caribbean dollars, two decimals. Demo penalties are flagged `penalty_is_illustrative`. |

## Who calls what

| Caller | Endpoints |
| --- | --- |
| Officer app (TS, CP) | `POST /v1/roadside/checks`, `POST /v1/tickets`, `GET /v1/tickets/{ticketNo}`, `GET /v1/offline/bundle`, `POST /v1/offline/sync`, `GET /v1/hits/{hitId}/events` |
| Dispatch (DSP) | `GET /v1/hits`, `POST /v1/hits/{hitId}/decision` |
| Investigators (INV, WAR, CRASH) | `POST /v1/investigations/queries`, `POST /v1/deferrals` (request or renew), `POST /v1/deferrals/{deferralId}/release` |
| Supervisors | `POST /v1/deferrals/{deferralId}/approval`, `POST /v1/deferrals/{deferralId}/release`, `POST /v1/protected-identities` (plus roadside endpoints) |
| Licensing Authority (LIC) | `GET /v1/licensing/proposed-actions`, `POST /v1/licensing/proposed-actions/{actionId}/decision`, `POST /v1/licensing/driver-record` |
| Court system (CRT) | `POST /v1/court/payments`, `POST /v1/court/outcomes`, `POST /v1/court/fines`, `GET /v1/tickets/{ticketNo}` |
| EMS (EMS) | `POST /v1/ems/emergency-cards` |
| Citizen (CIT) | `GET /v1/me/record`, `GET /v1/me/access-log`, `POST /v1/me/disputes`, `PUT /v1/me/emergency-card-consent`, `POST /v1/tickets/{ticketNo}/payments/simulated` |
| Oversight (AUD) | `/v1/oversight/*` |
| Anyone | `GET /healthz`, `GET /v1/meta/rules`; `POST /v1/dev/token` only when DEV_AUTH is on |

## Example — roadside check (persona S2, synthetic)

Request:
```http
POST /v1/roadside/checks
Authorization: Bearer <OFF-101 dev token>
X-Device-Id: 0194a3c2-0000-7000-8000-000000000101
Content-Type: application/json

{"identifier": {"type": "PLATE", "value": "SYN-PB 4521"}, "purpose": "TS",
 "location": {"lat": 14.0723, "lon": -60.9497, "text": "Gros Islet Highway"}}
```

Response (abridged):
```json
{
  "request_id": "rq_01JCX...", "ledger_seq": 1842, "purpose": "TS",
  "synthetic": true, "legal_rules_verified": false,
  "person": {"availability": "available", "full_name": "Darnell Vieux-Fort (SYNTHETIC)",
             "licence_no_masked": "SYN-DL-****17"},
  "licence": {"availability": "available", "status": "SUSPENDED", "classes": ["B"],
              "override_reason": "suspend_6m"},
  "points": {"availability": "available", "band": "14+"},
  "vehicle": {"availability": "available", "plate": "SYN-PB 4521", "registration_status": "REGISTERED",
              "insurance": {"availability": "available", "status": "VALID"},
              "inspection": {"availability": "unknown"}},
  "compliance": {"availability": "available", "unpaid_tickets_count": 2, "unpaid_total_ecd": 400.0},
  "alerts": {"availability": "available", "warrant": "NONE", "stolen_vehicle": "NONE"},
  "court": {"availability": "available", "court_date_pending": false},
  "sources": [{"agency": "TRANSPORT", "status": "ok", "latency_ms": 84},
              {"agency": "INSPECTION", "status": "timeout", "latency_ms": 1200}]
}
```

## Contract tests (built in M3 and M7)
- Every response in the integration suite validates against its schema.
- No response schema outside `StatusCard` and `InvestigationResult` mixes field groups from more
  than one domain (AC13); `cross_domain_profile` has no schema at all.
- No path or query parameter accepts an identifier.
- Every `x-ledger: true` route is wrapped by the ledger middleware (route-table test).
