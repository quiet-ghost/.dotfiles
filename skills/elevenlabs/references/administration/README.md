# Administration

Use this for billing, workspaces, service accounts, SSO, SCIM, data residency, and enterprise governance.

## Billing

| Topic | Detail |
|-------|--------|
| Plans | Free, Starter, Creator, Pro, Scale, Business, Enterprise |
| Payment | Subscription plans and Pay As You Go prepay |
| Rollover | Unused credits can roll over up to two months if not cancelled/downgraded |
| Rights | Paid plans grant commercial rights subject to input rights and terms |
| Custom voice slots | Used by Voice Design and Voice Cloning, not saved Voice Library voices |
| Cloning | Starter tier and above; free plan has Voice Design slots |

## Workspaces

Workspaces provide shared billing, shared resources, access management, API key management, and multiple workspace membership.

Shared resources can include voices, Agents, Studio projects, dubs, and pronunciation dictionaries. Enterprise copying can be limited to workspaces in the same consolidated billing group.

## Seats And Roles

| Role/Seat | Use |
|-----------|-----|
| Admin | Manage members, permissions, billing, workspace settings |
| Full Seat | Unrestricted product access |
| Basic Seat | Primarily ElevenAgents/ElevenAPI, limited ElevenCreative access |

Only admins can add/remove team members, manage billing, and manage service accounts.

## Service Accounts And API Keys

Service accounts are available for multi-seat customers. They act like workspace members and initially have no resources. Grant access through groups or direct sharing.

Key rotation pattern:

1. Create replacement API key on the same service account.
2. Copy old key permissions.
3. Deploy new key.
4. Confirm traffic works.
5. Delete or disable old key.

IP whitelisting is Enterprise preview. It supports public IPv4/IPv6 addresses and CIDR ranges, 1 to 100 entries per key. Private IP ranges are not accepted.

## SSO

SSO is Enterprise-only and admin-configured. ElevenLabs supports OIDC and SAML. Microsoft Entra/Azure should use SAML, not OIDC.

SAML supports SP-initiated SSO only. Bookmark app URL:

```text
https://elevenlabs.io/app/sign-in?use_sso=true
```

For data residency environments, ACS/Reply URLs use `https://<region>.residency.elevenlabs.io/__/auth/handler`.

## SCIM

SCIM is Enterprise-only and supports SCIM 2.0 users and groups.

| Capability | Support |
|------------|---------|
| Users | GET, POST, PUT, PATCH, DELETE |
| Groups | GET, POST, PUT, PATCH, DELETE |
| Discovery endpoints | Yes |
| Search | GET filters and `/.search` |
| Pagination | `startIndex`, `count` |
| Bulk | Max 100 ops, 1 MB payload |
| Attribute filtering | Yes |
| Sorting | Ignored |
| Primary email update | Not supported |

SCIM token is shown once. Regenerating invalidates the previous token.

## Data Residency

Data residency is Enterprise-only and creates separate isolated environments with separate accounts, API URLs, WebSocket URLs, API keys, and blank workspaces.

| Region | Web | API | WebSocket |
|--------|-----|-----|-----------|
| EU | `https://eu.residency.elevenlabs.io` | `https://api.eu.residency.elevenlabs.io` | `wss://api.eu.residency.elevenlabs.io` |
| India | `https://in.residency.elevenlabs.io` | `https://api.in.residency.elevenlabs.io` | `wss://api.in.residency.elevenlabs.io` |
| Singapore | `https://sg.residency.elevenlabs.io` | `https://api.sg.residency.elevenlabs.io` | `wss://api.sg.residency.elevenlabs.io` |

SDKs support environment configuration. For React agents in EU residency, use `serverLocation: "eu-residency"`. For JS client WebRTC, also set regional LiveKit URL when required.

## Limitations

| Topic | Limitation |
|-------|------------|
| Residency migration | Limited support; recreate resources via API where possible |
| Dubbing in residency | Not currently available per docs |
| LLM availability | Varies by region and ZRM requirements |
| HIPAA | Requires BAA before eligible services |
