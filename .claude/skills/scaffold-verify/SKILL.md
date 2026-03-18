---
name: scaffold-verify
description: "Run the full scaffold verification checklist against a newly scaffolded Go microservice. Checks compilation, DDD layer dependencies, Wire wiring, Kafka Outbox setup, compliance rules (decimal, UTC, idempotency, PII, audit), and spec completeness. Use after go-scaffold-architect completes a scaffold, or before a domain engineer begins filling business logic."
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
context: fork
---

You are the scaffold-verify skill for the brokerage trading platform.

> **Reference spec**: `docs/specs/platform/go-service-architecture.md`
> **Full checklist source**: `.claude/agents/go-scaffold-architect.md` → Verification Checklist

## What You Do

Run every item in the scaffold verification checklist against a Go microservice directory.
Report pass/fail per item. Stop at the first critical failure and explain how to fix it.

---

## Step 1: Locate the Service

```bash
# Find the service src/ directory
find . -name "go.mod" -maxdepth 5 | head -10
```

Ask if ambiguous: "Which service should I verify? (provide path to src/ directory)"

Set `$SERVICE_ROOT` = path to the `src/` directory containing `go.mod`.

---

## Step 2: Run Compilation Checks

```bash
cd $SERVICE_ROOT
go build ./... 2>&1
```

```bash
cd $SERVICE_ROOT
go vet ./... 2>&1
```

```bash
# Verify wire_gen.go is up to date (re-run wire and check for diff)
cd $SERVICE_ROOT
which wire && wire ./cmd/server/ 2>&1 | tail -5
```

**Critical**: If `go build` fails, stop and report. Do not continue to other checks.

---

## Step 3: Check Endpoint Availability

```bash
# Start the service in background and probe endpoints
cd $SERVICE_ROOT
go run ./cmd/server/ &
SERVER_PID=$!
sleep 3

curl -sf http://localhost:8000/health && echo "✓ /health" || echo "✗ /health"
curl -sf http://localhost:8000/metrics | head -3 && echo "✓ /metrics" || echo "✗ /metrics"
curl -sf http://localhost:8000/ready && echo "✓ /ready" || echo "✗ /ready"

kill $SERVER_PID 2>/dev/null
```

---

## Step 4: DDD Layer Dependency Check

Verify the import graph obeys: `server → service → biz ← data` (Layout A) or `handler → app → domain ← infra` (Layout B).

```bash
# Detect layout
if [ -d "$SERVICE_ROOT/internal/biz" ]; then
    echo "Layout: single-domain-ddd"
    LAYOUT="A"
else
    echo "Layout: subdomain-first-ddd"
    LAYOUT="B"
fi
```

```bash
# Layout A: check data/ does NOT import service/ or server/
grep -r "\".*service\"" $SERVICE_ROOT/internal/data/ --include="*.go" | grep -v "_test.go" | grep -v "//.*import"
grep -r "\".*server\"" $SERVICE_ROOT/internal/data/ --include="*.go" | grep -v "_test.go"

# Layout A: check biz/ imports nothing from data/ or service/
grep -r "\".*data\"" $SERVICE_ROOT/internal/biz/ --include="*.go" | grep -v "_test.go"
grep -r "\".*service\"" $SERVICE_ROOT/internal/biz/ --include="*.go" | grep -v "_test.go"
```

```bash
# Layout B: check each subdomain's infra/ does not import app/ or other subdomains' app/
for subdir in $SERVICE_ROOT/internal/*/; do
    subdomain=$(basename $subdir)
    if [ -d "$subdir/infra" ]; then
        violations=$(grep -r "\".*/$subdomain/app\"" $subdir/infra/ --include="*.go" 2>/dev/null)
        [ -n "$violations" ] && echo "✗ $subdomain/infra imports $subdomain/app (forbidden): $violations"
    fi
    if [ -d "$subdir/app" ]; then
        violations=$(grep -r "\".*infra\"" $subdir/app/ --include="*.go" 2>/dev/null)
        [ -n "$violations" ] && echo "✗ $subdomain/app imports infra (forbidden): $violations"
    fi
done
```

```bash
# Cross-subdomain: check no subdomain imports a sibling's app/ or domain/ directly
# (should only import through interfaces defined in deps.go)
for subdir in $SERVICE_ROOT/internal/*/; do
    subdomain=$(basename $subdir)
    grep -r "internal/[^\"]*/$subdomain/app\|internal/[^\"]*/$subdomain/domain" \
        $SERVICE_ROOT/internal/ --include="*.go" \
        --exclude-dir="$subdomain" 2>/dev/null \
        | grep -v "_test.go" \
        | grep -v "deps.go" \
        && echo "✗ Cross-subdomain direct import detected (use deps.go interface instead)"
done
```

---

## Step 5: Financial Coding Rules

```bash
# Rule 1: No float64/float32 for money/price/amount/quantity
grep -rn "float64\|float32" $SERVICE_ROOT/internal/ --include="*.go" \
    | grep -v "_test.go" \
    | grep -iE "price|amount|quantity|money|balance|fee|commission|rate" \
    && echo "✗ float used for financial field" || echo "✓ No float for financial fields"
```

```bash
# Rule 2: All time.Now() must call .UTC()
grep -rn "time\.Now()" $SERVICE_ROOT/internal/ --include="*.go" \
    | grep -v "_test.go" \
    | grep -v "\.UTC()" \
    && echo "✗ time.Now() without .UTC()" || echo "✓ All time.Now() use .UTC()"
```

```bash
# Rule 3: DSN must include UTC timezone
grep -rn "parseTime\|time_zone" $SERVICE_ROOT/ --include="*.go" --include="*.yaml" | head -5
grep -rn "loc=UTC\|time_zone.*00:00" $SERVICE_ROOT/ --include="*.go" --include="*.yaml" \
    && echo "✓ DSN has UTC timezone" || echo "⚠ DSN UTC timezone not detected — verify manually"
```

```bash
# Rule 4: No bare return err (should be wrapped with context)
grep -rn "return err$" $SERVICE_ROOT/internal/ --include="*.go" \
    | grep -v "_test.go" \
    | head -10 \
    && echo "✗ Bare 'return err' found — wrap with fmt.Errorf" || echo "✓ No bare return err"
```

```bash
# Rule 5: No swallowed errors
grep -rn ",\s*_\s*=" $SERVICE_ROOT/internal/ --include="*.go" \
    | grep -v "_test.go" \
    | grep -v "//.*ignore" \
    | head -5 \
    && echo "⚠ Possible swallowed errors — review manually" || echo "✓ No obvious swallowed errors"
```

---

## Step 6: Compliance Scaffolding Checks

```bash
# Idempotency middleware registered
grep -rn "idempotency\|Idempotency" $SERVICE_ROOT/internal/server/ --include="*.go" \
    && echo "✓ Idempotency middleware found" || echo "✗ Idempotency middleware not found in server/"
```

```bash
# Outbox table in migrations
grep -rn "outbox_events" $SERVICE_ROOT/../migrations/ --include="*.sql" \
    && echo "✓ outbox_events table in migrations" || echo "⚠ No outbox_events table — needed if service publishes Kafka events"
```

```bash
# kafka.Writer.WriteMessages not called directly from business logic
grep -rn "WriteMessages" $SERVICE_ROOT/internal/ --include="*.go" \
    | grep -v "outbox\|worker" \
    | grep -v "_test.go" \
    && echo "✗ Direct kafka.WriteMessages outside outbox worker" || echo "✓ Kafka publish only via outbox worker"
```

```bash
# PII fields: VARBINARY in SQL if service handles PII
grep -rn "SSN\|HKID\|passport\|bank_account\|date_of_birth" \
    $SERVICE_ROOT/../migrations/ --include="*.sql" | head -5
grep -rn "VARBINARY\|varbinary" \
    $SERVICE_ROOT/../migrations/ --include="*.sql" | head -5
```

```bash
# Secrets not in code
grep -rn "password\s*=\s*\"[^\"]\+\"\|secret\s*=\s*\"[^\"]\+\"\|api_key\s*=\s*\"[^\"]\+" \
    $SERVICE_ROOT/ --include="*.go" --include="*.yaml" \
    | grep -v "example\|placeholder\|your-.*-here\|test\|mock" \
    && echo "✗ Possible hardcoded secret" || echo "✓ No obvious hardcoded secrets"
```

```bash
# configs/local.yaml in .gitignore
grep -n "local.yaml\|*.env" $SERVICE_ROOT/../.gitignore 2>/dev/null \
    && echo "✓ local.yaml in .gitignore" || echo "✗ Add configs/local.yaml to .gitignore"
```

---

## Step 7: Wire and Dependency Injection

```bash
# ProviderSet exists in each subdomain
if [ "$LAYOUT" = "B" ]; then
    for subdir in $SERVICE_ROOT/internal/*/; do
        subdomain=$(basename $subdir)
        [ "$subdomain" = "data" ] || [ "$subdomain" = "kafka" ] || [ "$subdomain" = "server" ] && continue
        grep -l "ProviderSet\|wire.NewSet" $subdir/*.go 2>/dev/null \
            && echo "✓ $subdomain has ProviderSet" \
            || echo "✗ $subdomain missing ProviderSet (wire.go)"
    done
fi
```

```bash
# wire_gen.go exists and is non-empty
[ -s "$SERVICE_ROOT/cmd/server/wire_gen.go" ] \
    && echo "✓ wire_gen.go exists" \
    || echo "✗ wire_gen.go missing — run: wire ./cmd/server/"
```

```bash
# deps.go exists for subdomains with cross-subdomain calls
grep -rn "wire.Bind" $SERVICE_ROOT/cmd/server/wire.go 2>/dev/null | head -10
```

---

## Step 8: SDD Spec Completeness

```bash
# Required spec files exist
SERVICE_DIR=$(dirname $SERVICE_ROOT)
for f in "docs/specs/service-overview.md" "docs/specs/business-rules.md"; do
    [ -f "$SERVICE_DIR/$f" ] \
        && echo "✓ $f exists" \
        || echo "✗ $f missing"
done
```

```bash
# FILL markers still present (expected — domain engineer fills these)
grep -rn "FILL:" $SERVICE_DIR/docs/specs/ --include="*.md" --include="*.yaml" --include="*.proto" \
    | wc -l \
    | xargs -I{} echo "ℹ {} FILL markers remaining for domain engineer"
```

```bash
# errors.proto exists
[ -f "$(dirname $SERVICE_ROOT)/api/"*"/v1/errors.proto" ] \
    && echo "✓ errors.proto exists" \
    || echo "✗ errors.proto missing"
```

---

## Step 9: Local Dev Infrastructure

```bash
SERVICE_DIR=$(dirname $SERVICE_ROOT)
[ -f "$SERVICE_DIR/docker-compose.yaml" ] && echo "✓ docker-compose.yaml" || echo "✗ docker-compose.yaml missing"
[ -f "$SERVICE_DIR/Makefile" ] && echo "✓ Makefile" || echo "✗ Makefile missing"

# Makefile has required targets
for target in "proto" "wire" "migrate-up" "dev" "test" "lint"; do
    grep -q "^$target:" $SERVICE_DIR/Makefile 2>/dev/null \
        && echo "  ✓ make $target" \
        || echo "  ✗ make $target missing"
done
```

```bash
# docker-compose has MySQL with UTC
grep -q "time-zone.*00:00\|default-time-zone" $SERVICE_DIR/docker-compose.yaml 2>/dev/null \
    && echo "✓ MySQL UTC enforced in docker-compose" \
    || echo "⚠ MySQL UTC timezone not set in docker-compose"
```

---

## Step 10: Migration Safety

```bash
# No destructive DDL in any migration
grep -rn "DROP TABLE\|DROP COLUMN\|TRUNCATE" \
    $(dirname $SERVICE_ROOT)/migrations/ --include="*.sql" \
    | grep -v "^.*--.*DROP\|Down\|archived\|deprecated" \
    && echo "✗ Destructive DDL found in migrations" || echo "✓ No destructive DDL in migrations"
```

```bash
# Money columns use DECIMAL not FLOAT/DOUBLE
grep -rn "FLOAT\|DOUBLE" \
    $(dirname $SERVICE_ROOT)/migrations/ --include="*.sql" \
    | grep -iE "price|amount|quantity|money|balance|fee" \
    && echo "✗ FLOAT/DOUBLE used for financial column" || echo "✓ No FLOAT/DOUBLE for financial columns"
```

---

## Output Format

```markdown
## Scaffold Verification Report
**Service**: {service-name}
**Layout**: {single-domain-ddd | subdomain-first-ddd}
**Verified**: {ISO8601 timestamp}

### Results

| Category | Status | Details |
|----------|--------|---------|
| Compilation | ✓ PASS / ✗ FAIL | |
| go vet | ✓ PASS / ✗ FAIL | |
| /health /metrics /ready | ✓ PASS / ✗ FAIL | |
| DDD layer dependencies | ✓ PASS / ✗ FAIL / ⚠ WARN | |
| Financial coding rules | ✓ PASS / ✗ FAIL | |
| Compliance scaffolding | ✓ PASS / ✗ FAIL | |
| Wire / DI | ✓ PASS / ✗ FAIL | |
| SDD specs | ✓ PASS / ⚠ WARN | {N} FILL markers remaining |
| Local dev infra | ✓ PASS / ✗ FAIL | |
| Migration safety | ✓ PASS / ✗ FAIL | |

### Failures (fix before handing off to domain engineer)
{list of ✗ items with file:line and fix instructions}

### Warnings (review before production)
{list of ⚠ items}

### Ready for Domain Engineer
{YES — scaffold is clean / NO — fix failures above first}
```

---

## Handoff

If all critical checks pass:
```
Scaffold is verified. Hand off to domain engineer:
- Fill FILL markers in docs/specs/
- Implement domain logic in internal/{biz or subdomain/domain}/
- Run `make dev` to start the local stack
- Run `make test` after each layer is implemented
```

If failures exist:
```
Fix the listed failures, then re-run /scaffold-verify.
Do not hand off a broken scaffold — domain engineers build on this foundation.
```
