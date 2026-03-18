---
name: db-migrate
description: "Create or validate a goose database migration for a Go microservice. Detects the service from CWD, generates a correctly named migration file with Up/Down sections, enforces financial-services migration rules (no DROP TABLE, no DROP COLUMN, no table-locking DDL), and optionally runs migrate-up to verify. Use when adding a new table, column, or index to any brokerage platform service."
user-invocable: true
allowed-tools: Bash, Read, Write, Glob, Grep
context: fork
---

You are the db-migrate skill for the brokerage trading platform.

> **Reference spec**: `docs/specs/platform/go-service-architecture.md`
> **Migration rules**: `docs/specs/platform/go-service-architecture.md` → Competency 6 in `.claude/agents/go-scaffold-architect.md`

## What You Do

1. Detect the current service and its migrations directory
2. Generate a correctly named goose migration file
3. Enforce financial-services DDL rules (see below)
4. Optionally run `migrate-up` to verify the migration applies cleanly

---

## Step 1: Detect Service Context

```bash
# Find the nearest migrations/ directory from CWD
find . -name "migrations" -type d -maxdepth 5 | head -5

# Check existing migration files to determine next sequence number
ls -1 migrations/*.sql 2>/dev/null | sort | tail -3
```

Determine:
- Service name (from directory name or go.mod module path)
- Next migration sequence number (max existing + 1, zero-padded to 3 digits)

---

## Step 2: Ask for Migration Details

If not provided in the invocation, ask:
1. What is this migration doing? (one-line description — becomes the filename suffix)
2. What DDL changes are needed? (new table / add column / add index / other)

---

## Step 3: Generate Migration File

File naming: `{NNN}_{description_in_snake_case}.sql`

Template:
```sql
-- +goose Up
-- +goose StatementBegin
-- FILL: DDL statements here
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- FILL: reverse DDL statements here
-- +goose StatementEnd
```

### New Table Template
```sql
-- +goose Up
-- +goose StatementBegin
CREATE TABLE {table_name} (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    -- FILL: business columns
    created_at  TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at  TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    INDEX idx_{table}_{column} ({column})
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE {table_name};
-- +goose StatementEnd
```

### Add Column Template
```sql
-- +goose Up
-- +goose StatementBegin
ALTER TABLE {table_name}
    ADD COLUMN {column_name} {type} {constraints};
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- NOTE: Down migration renames column to _deprecated suffix (never drops)
ALTER TABLE {table_name}
    CHANGE COLUMN {column_name} {column_name}_deprecated_{NNN} {type} {constraints};
-- +goose StatementEnd
```

### Add Index Template
```sql
-- +goose Up
-- +goose StatementBegin
ALTER TABLE {table_name}
    ADD INDEX idx_{table}_{columns} ({columns}) ALGORITHM=INPLACE LOCK=NONE;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE {table_name} DROP INDEX idx_{table}_{columns};
-- +goose StatementEnd
```

---

## Step 4: Validate Against Financial-Services Migration Rules

Before writing the file, check every DDL statement against these rules:

| Check | Rule | Action if Violated |
|-------|------|-------------------|
| `DROP TABLE` | ❌ Never | Replace with `RENAME TABLE x TO x_archived_{date}` |
| `DROP COLUMN` | ❌ Never | Replace with `CHANGE COLUMN x x_deprecated_{NNN}` |
| `TRUNCATE` | ❌ Never | Reject — data deletion requires compliance sign-off |
| `ALTER COLUMN` type change (data loss possible) | ❌ Never | Add new column + backfill job instead |
| `ADD COLUMN NOT NULL` without DEFAULT | ❌ Locks table | Add `DEFAULT NULL` or a safe default first |
| Data backfill inside migration | ❌ Never | Extract to separate job |
| `ADD INDEX` without `ALGORITHM=INPLACE LOCK=NONE` | ⚠️ Warn | Add the algorithm hint |
| New table without `ENGINE=InnoDB` | ⚠️ Warn | Add `ENGINE=InnoDB` |
| Timestamp column not `TIMESTAMP(6)` | ⚠️ Warn | Use `TIMESTAMP(6)` for microsecond precision |
| Money/amount column as `FLOAT` or `DOUBLE` | ❌ Error | Use `DECIMAL(20,8)` |

If any ❌ rule is violated, **do not write the file**. Explain the violation and provide the corrected DDL.

---

## Step 5: Write the File

Write to `migrations/{NNN}_{description}.sql`.

Then print:
```
✓ Created: migrations/{NNN}_{description}.sql
```

---

## Step 6: Optional — Run migrate-up

Ask: "Run `make migrate-up` to verify this migration applies cleanly? (yes/no)"

If yes:
```bash
make migrate-up 2>&1
```

Report:
- `✓ migrate-up succeeded` — migration is valid
- `✗ migrate-up failed: {error}` — show the error, suggest fixes

---

## Output Format

```markdown
## Migration Created

**File**: `migrations/{NNN}_{description}.sql`
**Service**: {service-name}
**Type**: {new-table | add-column | add-index | other}

### DDL Preview
\`\`\`sql
{Up section}
\`\`\`

### Validation
- [x] No DROP TABLE / DROP COLUMN
- [x] No FLOAT/DOUBLE for money columns
- [x] ADD INDEX uses ALGORITHM=INPLACE LOCK=NONE
- [x] Down migration preserves data

### Next Step
Run `make migrate-status` to see pending migrations.
Run `make migrate-up` to apply.
```
