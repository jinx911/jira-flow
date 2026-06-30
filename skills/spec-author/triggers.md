# Spec-Author Trigger Map

Core sections are always required. Engineering sections below are expanded ONLY when the matching trigger fires. The orchestrator passes the trigger set; if absent, the architect detects triggers from a codebase scan.

| Trigger | Section to expand | Required content |
|---|---|---|
| New table / field change / migration | Data Model | table schema, fields, indexes, migration steps |
| New or changed endpoint / request-response | API Contract | endpoint, request/response shape, error codes |
| Cross-module / cross-service change | Interface Boundaries | inter-module contracts, call direction |
| Status machine / multi-step workflow / async | State & Flow | state machine or sequence diagram |
| Significant error paths / permission / payment | Error Contract | exception classes, fallback, permission matrix |
| (always; depth scales) | Test Strategy | how to test each acceptance criterion |

## Trigger detection hints
- **Data Model**: migration files referenced, new columns in description, "新增表/字段".
- **API Contract**: "接口/endpoint/请求/响应", route changes.
- **Interface Boundaries**: more than one module/service in affected modules.
- **State & Flow**: status fields, workflow, "审批/流转", async jobs.
- **Error Contract**: permission rules, payment, file upload, external service calls.

## Extending
Add project-specific triggers via project-config `spec.triggers` — a map of trigger name → required section + content checklist.
