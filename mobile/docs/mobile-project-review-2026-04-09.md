# Mobile 项目整体 Review

- 日期: 2026-04-09
- 范围: `mobile/src` Flutter 客户端项目整体
- 审查方式:
  - 阅读项目结构、核心模块、关键 provider 和路由/网络/安全链路
  - 复核测试与静态检查结果
  - 不以增量 commit 为边界，而是按当前仓库整体状态评估

## 总体结论

项目的基础分层方向是对的，`core / shared / features` 的组织方式也基本清晰；但当前仓库更接近“可演示的阶段性实现”，还不是“可上线的完整基线”。

主要问题不在于目录结构混乱，而在于几个关键基础能力没有真正闭环:

1. 鉴权链路没有完成实际接线。
2. 网络错误处理在多个层级重复实现且互相打架。
3. 安全能力中有一部分仍是占位实现。
4. 测试集存在失真，既有真实失败，也有覆盖错对象的问题。
5. 若按产品完成度衡量，仍有多处 placeholder / stub 会给团队造成“已完成”的错觉。

## 发现

### 1. 高风险: AuthInterceptor 没有真正接上 token 读写来源

#### 现象

- `AuthInterceptor` 的 `getAccessToken` 和 `refreshAccessToken` 默认都返回 `null`
- `DioClient.create()` 只是直接实例化 `AuthInterceptor(dio)`，没有注入实际回调
- 各 repository provider 也都在使用裸 `DioClient.create(...)`

#### 证据

- `src/lib/core/network/auth_interceptor.dart:18`
- `src/lib/core/network/auth_interceptor.dart:19`
- `src/lib/core/network/dio_client.dart:77`
- `src/lib/features/auth/data/auth_repository_impl.dart:311`
- `src/lib/features/market/data/watchlist_repository_impl.dart:174`
- `src/lib/features/market/data/market_data_repository_impl.dart:148`

#### 影响

- 依赖统一 JWT 注入的接口不会自动带 `Authorization`
- 401 后刷新 token 再重试的逻辑基本不会生效
- 某些接口如果没有手动加 header，会在联调或线上直接表现为未认证请求

#### 建议

- 明确 `DioClient.create()` 的职责边界
- 如果使用统一拦截器注入 token，就在 provider 装配阶段把 token 读取与刷新回调真实注入
- 如果不走统一拦截器，就删除这条“看起来存在但实际不可用”的公共能力，避免误导调用方

### 2. 高风险: 网络错误处理在 interceptor 和 remote data source 两层重复实现且不兼容

#### 现象

- `ErrorInterceptor` 在拦截器层直接把 `DioException` 映射成 `AppException`
- 但 auth/market 的 remote data source 又都在 `catch (DioException)` 后做更细粒度的业务映射
- 这两套逻辑的假设互相冲突

#### 证据

- `src/lib/core/network/error_interceptor.dart:10`
- `src/lib/features/auth/data/remote/auth_remote_data_source.dart:46`
- `src/lib/features/auth/data/remote/auth_remote_data_source.dart:200`
- `src/lib/features/market/data/remote/market_remote_data_source.dart:230`
- `src/lib/features/market/data/remote/market_remote_data_source.dart:302`
- `src/lib/features/market/data/remote/market_remote_data_source.dart:344`

#### 影响

- OTP 错误里像 `remainingAttempts`、`lockoutUntil` 这类上下文信息可能丢失
- 市场数据侧的 `429 Retry-After` 重试能力可能被提前截断
- 不同调用路径上得到的异常类型可能不一致，增加排障成本

#### 建议

- 统一异常映射边界，只保留一层作为“最终异常转换层”
- 如果 remote data source 需要协议级细节，就不要在 interceptor 层提前吞掉 `DioException`
- 如果决定由 interceptor 统一转换，则 remote data source 需要改为面向 `AppException` 设计

### 3. 高风险: TLS pinning 目前不能当作真实可用的 pinning 能力

#### 现象

- pin 值仍是 placeholder
- 注释声称 `badCertificateCallback` 会在系统信任的情况下继续执行额外校验，但当前实现并不能保证这一点
- 代码名义上写的是 SPKI pinning，实际 hash 的却是整张证书 DER

#### 证据

- `src/lib/core/security/ssl_pinning_config.dart:41`
- `src/lib/core/security/ssl_pinning_config.dart:61`
- `src/lib/core/security/ssl_pinning_config.dart:103`

#### 影响

- 团队可能误以为“证书固定”已经完成
- 如果按当前实现对外宣称具备 pinning，会高估真实安全能力
- 真正上线前若不整改，这块会是安全基线缺口

#### 建议

- 在 README / 安全文档里明确标注当前状态为 placeholder
- 上线前补齐真实 pin 值与正确的 SPKI 提取实现
- 对安全能力采用“可用/不可用”二元判定，不要让半成品伪装成已交付能力

### 4. 中风险: SearchNotifier 初始化时序有 bug，且已被现有测试暴露

#### 现象

- `build()` 中先调用 `_init()`，再返回初始 state
- `_loadHotStocks()` 的异常分支里会立刻写 `state`
- 在 provider 尚未稳定初始化时，这种写法会触发未初始化状态读取

#### 证据

- `src/lib/features/market/application/search_notifier.dart:121`
- `src/lib/features/market/application/search_notifier.dart:129`
- `src/lib/features/market/application/search_notifier.dart:165`
- `src/test/features/market/application/search_notifier_test.dart:134`

#### 影响

- 同步失败或早期失败路径会直接崩掉 provider 初始化
- 当前测试已经复现该问题
- 这类时序 bug 在真实环境下通常会表现为偶发初始化失败，定位成本高

#### 建议

- 不要在 `build()` 尚未返回初始 state 前启动会回写 `state` 的异步初始化
- 可改为先返回初值，再通过微任务、effect 或显式初始化入口触发异步加载

### 5. 中风险: 默认测试集中混入依赖 localhost 和平台 binding 的手工测试

#### 现象

- `watchlist_repository_test.dart` 直接请求 `http://localhost:8080`
- 同时使用 `Connectivity()`，但没有初始化 test binding
- 当前在 `flutter test` 下直接失败

#### 证据

- `src/test/features/market/data/watchlist_repository_test.dart:8`
- `src/test/features/market/data/watchlist_repository_test.dart:15`
- `src/test/features/market/data/watchlist_repository_test.dart:18`

#### 影响

- 默认测试集不稳定，CI 不能作为健康信号
- 本该是手工联调验证的内容，被放进了单元测试入口
- 新成员会误以为仓库本身存在功能性回归，实际上是测试分类错误

#### 建议

- 将这类测试迁移到 integration / manual / smoke 分类
- 若保留在自动化测试中，需补齐 binding 初始化、mock 依赖与启动前置条件

### 6. 中风险: 路由测试覆盖了未接线代码，对真实路由保护不足

#### 现象

- 真实 app 使用的是 `app_router.dart` 里的 `_redirect`
- `RouteGuards` 类并未被生产路由引用
- 但当前路由测试主要覆盖的是 `RouteGuards`

#### 证据

- `src/lib/core/routing/app_router.dart:31`
- `src/lib/core/routing/app_router.dart:167`
- `src/lib/core/routing/route_guards.dart:10`
- `src/test/core/routing/route_guards_test.dart:47`

#### 影响

- 测试通过不代表真实路由逻辑安全
- 会形成“测试很多，但没测到线上路径”的假象

#### 建议

- 删除死代码，或者把真实路由逻辑抽为可测试纯函数并由生产代码复用
- 测试对象必须与生产接线保持一致

### 7. 中风险: 生物识别签名链路仍是 stub，实现与安全诉求不匹配

#### 现象

- 设备注销时拼接的是 `stub_signature`
- 底层 `BiometricKeyManager` 当前也是明确的 stub 实现

#### 证据

- `src/lib/features/auth/presentation/screens/device_management_screen.dart:82`
- `src/lib/core/auth/biometric_key_manager.dart:30`

#### 影响

- UI 看起来像“已经过生物识别签名保护”
- 实际上只是完成了交互流程，没有完成真正的密码学证明

#### 建议

- 若这条链路暂时只是 demo，应在文档和代码中明确标注不可用于生产
- 若要上线，需补齐平台 KeyStore / Secure Enclave 集成与验签协议

### 8. 低风险: 多个核心页面和图表仍处于 placeholder 阶段

#### 现象

- KYC、Trading、Portfolio、Settings 多个路由仍返回 `_Placeholder`
- K 线图组件明确标注为 placeholder，仅使用简化的 `CustomPaint`

#### 证据

- `src/lib/core/routing/app_router.dart:76`
- `src/lib/features/market/presentation/widgets/kline_chart_widget.dart:221`

#### 影响

- 如果用于阶段性演示没有问题
- 但如果团队按“功能完成”理解当前仓库，会高估交付状态

#### 建议

- 统一标注哪些模块是“已交付”、哪些只是“脚手架 / 原型 / 占位”
- 产品、测试、研发应共享同一份完成度定义

## 结构层面的补充判断

### 正向点

- `core / shared / features` 的组织是合理的
- 数据层、应用层、展示层已经初步分离
- Riverpod、go_router、Dio、测试目录等基础设施选择本身没有明显方向性错误

### 主要结构性问题

- “公共基础能力已存在”的表象强于“公共基础能力已真正闭环”的现实
- 文档、注释、命名与真实交付状态之间存在偏差
- 测试覆盖率和测试有效性不是一回事，当前仓库后者更需要优先修复

## 建议的整改优先级

### P0

1. 修复认证拦截器接线问题
2. 统一网络异常处理边界
3. 修复 `SearchNotifier` 初始化时序 bug
4. 把默认测试集恢复到全绿，移走错误分类的 localhost 手工测试

### P1

1. 重构真实路由测试，覆盖生产接线路径
2. 明确安全能力哪些是真实现，哪些仍是 stub
3. 清理注释中会误导“已完成度”的描述

### P2

1. 系统化替换 Placeholder 页面
2. 完成真实 K 线图集成
3. 进一步收敛原型代码、测试代码、生产代码之间的边界

## 验证记录

### 静态检查

- 执行: `flutter analyze`
- 结果: 26 个问题
- 主要类型:
  - `avoid_print`
  - `unused_import`
  - `unused_field`

### 测试

- 执行: `flutter test`
- 结果: 306 通过，2 失败

失败文件:

1. `src/test/features/market/application/search_notifier_test.dart`
2. `src/test/features/market/data/watchlist_repository_test.dart`

其中第二个失败不是业务逻辑回归，而是测试本身分类与初始化方式有问题。

## 结语

如果把当前项目视为阶段性原型，这份仓库已经具备继续迭代的基础；但如果把它视为可直接进入稳定联调或上线准备的主干，那么至少鉴权、异常处理、安全能力声明、测试可信度这四个方面还需要先补齐。
