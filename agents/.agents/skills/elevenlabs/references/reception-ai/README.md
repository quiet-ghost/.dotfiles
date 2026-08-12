# Reception AI

Reception AI is an AI phone receptionist for small and medium businesses. It answers inbound calls, books appointments, takes messages, and manages operations from a dashboard.

## What It Does

| Feature | Use |
|---------|-----|
| 24/7 call answering | Avoid missed calls |
| 70+ languages | Multilingual caller handling |
| Appointment scheduling | Schedule, reschedule, cancel bookings |
| Booking page | Self-service online scheduling |
| Client management | CRM-like interaction history |
| Knowledge base | Business facts from website/files/gap answers |
| Analytics | Revenue, bookings, calls, growth |
| Integrations | Google Calendar, Zapier, webhooks, MCP server |

## Setup Flow

1. Sign up and scan the business website.
2. Customize receptionist voice, languages, rules, and call behavior.
3. Configure services, staff, business hours, availability, and booking rules.
4. Connect phone number and integrations.
5. Test calls and fill knowledge gaps.
6. Monitor inbox and analytics.

## Knowledge Base

Reception AI knowledge includes:

| Source | Notes |
|--------|-------|
| Website content | Scraped pages |
| Uploaded files | PDFs and documents |
| Knowledge gap answers | Manual answers for previously missed questions |
| Business config | Services, hours, settings added automatically |

When callers ask questions, Reception AI searches the knowledge base, answers naturally, and logs a knowledge gap when no relevant info is found.

Best practices:

| Practice | Reason |
|----------|--------|
| Keep sources current | Avoid outdated policies/pricing |
| Be specific | Better answers |
| Review gaps regularly | Improve coverage |
| Avoid duplicate business config | Services/hours/staff already exist structurally |

## Scheduling Model

Reception AI scheduling docs cover services, business hours, staff, booking page, inbox, business assistant, phone numbers, and analytics. Use those docs for operational setup, not the general ElevenAgents docs.

## Integrations

| Integration | Use |
|-------------|-----|
| Google Calendar | Staff availability sync |
| Zapier | Connect many apps via MCP |
| Webhooks | Custom HTTP endpoints |
| MCP server | Custom tools and data |

## Routing Note

If the user asks for a custom voice agent rather than the packaged SMB receptionist product, use `../eleven-agents/README.md`.
