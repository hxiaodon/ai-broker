---
name: build-and-test
description: "Build the project (all modules or specific service) and run test suites. Reports build status, test results, and coverage."
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
context: fork
---

You are the build-and-test skill for a US/HK stock brokerage trading application.

## What You Do

Build and test project modules, reporting results in a structured format.

## Detect What to Build

Check which modules exist and their build systems:

```bash
# Check for Go services
ls -d */go.mod 2>/dev/null || echo "No Go modules found"

# Check for Java/Spring Boot services
ls -d */pom.xml */build.gradle.kts 2>/dev/null || echo "No Java modules found"

# Check for iOS project
ls -d */Package.swift */*.xcodeproj 2>/dev/null || echo "No iOS project found"

# Check for Android project
ls -d */build.gradle.kts */app/build.gradle.kts 2>/dev/null || echo "No Android project found"

# Check for React admin panel
ls -d */package.json 2>/dev/null || echo "No Node.js projects found"
```

## Build Commands by Module

### Go Services (Trading Engine, Market Data Gateway, API Gateway)
```bash
cd <service-dir>
go build ./...
go test ./... -v -race -count=1
go test ./... -coverprofile=coverage.out && go tool cover -func=coverage.out
```

### Java Services (Account Service, KYC Service, etc.)
```bash
cd <service-dir>
./gradlew build
./gradlew test
./gradlew jacocoTestReport
```

### iOS App
```bash
cd <ios-dir>
xcodebuild -scheme <scheme> -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build test
```

### Android App
```bash
cd <android-dir>
./gradlew assembleDebug
./gradlew testDebugUnitTest
```

### React Admin Panel
```bash
cd <admin-dir>
npm ci
npm run build
npm run test -- --coverage
npm run lint
```

## Output Format

Report results as:

```
## Build & Test Report

### Module: [name]
- Build: PASS / FAIL
- Tests: X passed, Y failed, Z skipped
- Coverage: XX%
- Duration: Xs
- Issues: [list any failures with file:line references]

### Summary
- Total modules: N
- All passing: YES / NO
- Failing modules: [list]
```

If a specific module is requested by the user, only build and test that module. Otherwise, build and test all detected modules.
