# Admin Panel

## Domain Scope

Internal web-based operations dashboard for the brokerage platform. Used by operations staff, compliance officers, and KYC reviewers to manage users, review applications, approve fund transfers, monitor orders, and generate regulatory reports.

Accessed via dedicated domain (e.g., `admin.brokerage.com`), fully isolated from user-facing app.

Responsibilities:
- KYC review workbench (approve / reject / request supplementary documents)
- Fund withdrawal approval queue (3-tier: auto / manual / compliance escalation)
- User management (search, view, status management)
- Order monitoring (cross-user real-time order view)
- Hot stock list management
- System dashboard (KPIs: registrations, trade volume, deposit volume)
- SAR management (create, track, archive suspicious activity reports)
- Admin user management with RBAC role assignment

## Tech Stack

- **Framework**: React 19+ with TypeScript 5.x (strict mode)
- **UI Library**: Ant Design Pro 6.x (enterprise admin components)
- **State**: Zustand (client state), TanStack Query (server state)
- **Charts**: @ant-design/charts or ECharts
- **Build**: Vite
- **API**: REST calls to backend services via API Gateway

## Doc Index

| Path | Content |
|------|---------|
| `docs/prd/09-admin-panel.md` | Surface PRD -- full admin panel feature spec (Phase 1) |
| `docs/specs/` | Tech specs (TBD) |
| `docs/specs/*.tracker.md` | 实现跟踪文件（动态进度 + 验收记录） |
| `docs/active-features.yaml` | 域级功能实现进度仪表盘 |
| `docs/patches.yaml` | Patch 注册表（活跃补丁 + 技术债） |
| `src/` | React application source |

## Dependencies

### Upstream (data sources via REST API)
- **AMS** -- user accounts, KYC applications, notifications
- **Trading Engine** -- orders, positions, risk alerts
- **Market Data** -- market status, stock metadata
- **Fund Transfer** -- withdrawal queue, deposit records, reconciliation reports

### Downstream
- **Operations team** -- daily operational workflows
- **Compliance officers** -- regulatory review and SAR management

## Domain Agent

**Agent**: `.claude/agents/admin-panel-engineer.md`
Specialist in React/TypeScript, Ant Design Pro, enterprise admin UI, and RBAC implementation.

## Key Compliance Rules

1. **RBAC role verification** -- every page/action gated by role (super_admin, compliance_officer, kyc_reviewer, ops_staff, viewer)
2. **Audit trail for all admin actions** -- every state change (KYC decision, fund approval, status change) logged with admin user ID, timestamp, and reason
3. **PII masking in UI** -- SSN last 4 only, bank account last 4 only, HKID masked as `A****(3)`
4. **Session security** -- 15-min idle timeout, re-auth for sensitive operations
5. **No direct DB access** -- all data fetched through backend APIs; admin panel never connects to databases directly
6. **Export controls** -- bulk data exports require compliance_officer role; exports are audit-logged
