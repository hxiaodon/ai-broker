# 环境配置指南 (Environment Configuration Guide)

## 概述 (Overview)

所有API域名和特性开关都集中在 `EnvironmentConfig` 中，避免 hardcode。支持开发、预发布、生产三个环境。

## 快速开始 (Quick Start)

### 本地开发（使用 Mock Server）

```bash
# 方式 1：使用 .env 文件
flutter run --dart-define-from-file=.env.development

# 方式 2：直接指定参数
flutter run --dart-define=ENVIRONMENT=development

# 方式 3：仅运行测试
flutter test --dart-define=ENVIRONMENT=development
```

### 预发布环境

```bash
flutter run --dart-define=ENVIRONMENT=staging
```

### 生产环境

```bash
flutter run --dart-define=ENVIRONMENT=production
```

## 默认配置 (Default Configuration)

### 开发环境 (Development)
```
ENVIRONMENT=development
Market API:    http://localhost:8080
AMS API:       http://localhost:8080
WebSocket:     ws://localhost:8080
```

### 预发布环境 (Staging)
```
ENVIRONMENT=staging
Market API:    https://api-staging.trading.example.com
AMS API:       https://ams-staging.trading.example.com
WebSocket:     wss://ws-staging.trading.example.com
```

### 生产环境 (Production)
```
ENVIRONMENT=production
Market API:    https://api.trading.example.com
AMS API:       https://ams.trading.example.com
WebSocket:     wss://ws.trading.example.com
```

## 覆盖默认值 (Overriding Defaults)

如果需要覆盖 ENVIRONMENT 的默认值，使用显式的 URL 参数：

```bash
# 使用 staging 环境但连接本地 Mock Server
flutter run \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=MARKET_BASE_URL=http://localhost:8080 \
  --dart-define=AMS_BASE_URL=http://localhost:8080 \
  --dart-define=WS_BASE_URL=ws://localhost:8080
```

## 在 CI/CD 中使用 (CI/CD Usage)

### GitHub Actions 示例

```yaml
# .github/workflows/build.yml
jobs:
  build-staging:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: |
          flutter build apk \
            --dart-define=ENVIRONMENT=staging \
            --dart-define=MARKET_BASE_URL=${{ secrets.STAGING_MARKET_API }} \
            --dart-define=AMS_BASE_URL=${{ secrets.STAGING_AMS_API }}
```

## 代码中访问配置 (Accessing Config in Code)

```dart
import 'package:trading_app/core/config/environment_config.dart';

// 在任何地方访问配置
final config = EnvironmentConfig.instance;

print('Environment: ${config.environmentName}');
print('Market API: ${config.marketBaseUrl}');
print('Is Production: ${config.isProduction}');

// 基于环境条件处理逻辑
if (config.isDevelopment) {
  // 开发模式：显示更详细的日志
  AppLogger.enableDetailedMode();
}
```

## 配置初始化流程 (Initialization Flow)

在 `main.dart` 中自动初始化（推荐）：

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 必须第一个初始化！
  EnvironmentConfig.initialize();
  
  // ... 其他初始化代码
  
  runApp(const ProviderScope(child: TradingApp()));
}
```

如果需要手动控制环境：

```dart
EnvironmentConfig.initialize(environment: Environment.staging);
```

## 最佳实践 (Best Practices)

### ✅ DO

1. **总是使用 EnvironmentConfig**
   ```dart
   final baseUrl = EnvironmentConfig.instance.marketBaseUrl;
   ```

2. **在 main() 中初始化**
   ```dart
   void main() {
     EnvironmentConfig.initialize();
     // ...
   }
   ```

3. **使用 .env 文件进行本地开发**
   ```bash
   flutter run --dart-define-from-file=.env.development
   ```

4. **在 CI/CD 中使用 secrets**
   ```yaml
   --dart-define=MARKET_BASE_URL=${{ secrets.API_URL }}
   ```

### ❌ DON'T

1. **不要 hardcode URL**
   ```dart
   // ❌ 不要这样做
   const baseUrl = 'http://localhost:8080';
   ```

2. **不要在多个地方定义相同的配置**
   ```dart
   // ❌ 不要这样做
   // file1.dart: const API_URL = '...';
   // file2.dart: const API_URL = '...';
   ```

3. **不要在运行时修改配置**
   ```dart
   // ❌ 不要这样做
   EnvironmentConfig.instance.marketBaseUrl = 'https://new-url.com';
   ```

## 环境变量参考 (Environment Variables Reference)

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `ENVIRONMENT` | `development` | 环境：development/staging/production |
| `MARKET_BASE_URL` | 由 ENVIRONMENT 决定 | Market Data API 基址 |
| `AMS_BASE_URL` | 由 ENVIRONMENT 决定 | AMS API 基址 |
| `WS_BASE_URL` | 由 ENVIRONMENT 决定 | WebSocket 基址 |

## 常见问题 (FAQ)

### Q: 如何在本地同时测试多个环境？

A: 使用不同的 `--dart-define` 创建多个 run 配置：

```bash
# Terminal 1：开发环境
flutter run --dart-define=ENVIRONMENT=development

# Terminal 2：预发布环境（需要不同的端口）
flutter run -d emulator-2 --dart-define=ENVIRONMENT=staging
```

### Q: Mock Server 在哪个端口？

A: 默认是 `localhost:8080`。可以通过 `--dart-define=MARKET_BASE_URL=...` 覆盖。

### Q: 生产环境如何保密 API URL？

A: 在 CI/CD 中使用 secrets：

```yaml
--dart-define=MARKET_BASE_URL=${{ secrets.PROD_MARKET_API }}
```

## 文件清单 (File Reference)

- `lib/core/config/environment_config.dart` — 配置类
- `.env.example` — 环境变量示例
- `lib/main.dart` — 初始化位置
- `lib/features/market/data/market_data_repository_impl.dart` — 使用示例
- `lib/features/market/data/watchlist_repository_impl.dart` — 使用示例
- `lib/features/market/application/quote_websocket_notifier.dart` — WebSocket 配置

