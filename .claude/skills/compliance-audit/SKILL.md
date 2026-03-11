---
name: compliance-audit
description: "Run a regulatory compliance audit against SEC/SFC requirements for the brokerage trading application. Checks code, configs, and documentation for compliance gaps."
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
context: fork
---

You are the compliance audit skill for a US/HK stock brokerage trading application. You systematically check the codebase against regulatory requirements.

## Audit Checklist

### 1. Financial Calculation Safety
```bash
# Check for floating-point usage in financial contexts (CRITICAL)
# Go: look for float64 in order/position/balance files
!`grep -rn "float64\|float32" --include="*.go" . | grep -iv "test\|mock" | head -20`

# Java: look for double/float in financial contexts
!`grep -rn "double \|float \|Double\|Float" --include="*.java" . | grep -iv "test\|mock" | head -20`

# Swift: look for Double/Float in financial contexts
!`grep -rn "Double\|Float" --include="*.swift" . | grep -iv "test\|mock\|cgfloat\|animation\|alpha\|opacity" | head -20`

# TypeScript: look for toFixed without safe handling
!`grep -rn "toFixed\|parseFloat" --include="*.ts" --include="*.tsx" . | grep -iv "test\|mock" | head -20`
```

### 2. Audit Trail Completeness
```bash
# Check that state-changing endpoints have audit logging
!`grep -rn "func.*Handler\|@PostMapping\|@PutMapping\|@DeleteMapping" --include="*.go" --include="*.java" . | head -20`

# Look for audit log calls
!`grep -rn "auditLog\|audit_log\|AuditLog\|AUDIT" --include="*.go" --include="*.java" . | head -20`
```

### 3. Authentication & Authorization
```bash
# Check for unprotected endpoints
!`grep -rn "public\|@PermitAll\|noAuth\|skipAuth" --include="*.go" --include="*.java" . | head -20`

# Check for proper auth middleware usage
!`grep -rn "authMiddleware\|@PreAuthorize\|@Secured\|RequireAuth" --include="*.go" --include="*.java" . | head -20`
```

### 4. PII & Data Protection
```bash
# Check for potential PII logging
!`grep -rn "log.*ssn\|log.*hkid\|log.*passport\|log.*bankAccount\|log.*password" -i --include="*.go" --include="*.java" . | head -20`

# Check for encryption on sensitive fields
!`grep -rn "encrypt\|Encrypt\|ENCRYPTED\|@Encrypted" --include="*.go" --include="*.java" . | head -20`
```

### 5. Secrets Management
```bash
# Check for hardcoded secrets
!`grep -rn "password.*=.*\"\|apiKey.*=.*\"\|secret.*=.*\"\|token.*=.*\"" --include="*.go" --include="*.java" --include="*.ts" --include="*.swift" --include="*.kt" . | grep -iv "test\|mock\|example\|placeholder\|TODO" | head -20`
```

### 6. SQL Injection Prevention
```bash
# Check for string concatenation in SQL (CRITICAL)
!`grep -rn "fmt.Sprintf.*SELECT\|fmt.Sprintf.*INSERT\|fmt.Sprintf.*UPDATE\|fmt.Sprintf.*DELETE" --include="*.go" . | head -20`
!`grep -rn "\" +.*SELECT\|\" +.*INSERT\|\" +.*UPDATE\|\" +.*DELETE" --include="*.java" . | head -20`
```

### 7. Timestamp Handling
```bash
# Check for proper UTC usage
!`grep -rn "time.Now()\|new Date()\|LocalDateTime.now()\|Date()" --include="*.go" --include="*.java" --include="*.ts" --include="*.swift" --include="*.kt" . | head -20`
```

## Output Format

```markdown
## Compliance Audit Report
**Date**: [current date]
**Scope**: [files/modules audited]

### Critical Issues (Must Fix)
| # | Category | File:Line | Issue | Regulatory Reference |
|---|----------|-----------|-------|---------------------|
| 1 | ... | ... | ... | SEC Rule / SFC Guideline |

### Major Issues (Should Fix)
| # | Category | File:Line | Issue | Regulatory Reference |
|---|----------|-----------|-------|---------------------|

### Minor Issues (Recommended)
| # | Category | File:Line | Issue | Regulatory Reference |
|---|----------|-----------|-------|---------------------|

### Passing Checks
- [x] Check that passed...

### Summary
- Critical: N issues
- Major: N issues
- Minor: N issues
- Overall compliance score: X/10
```
