# 编译问题修复总结

**日期**: 2026-03-08
**状态**: ✅ 全部修复完成

---

## 问题概述

在验证 P0 级别修复后，发现项目存在预存在的编译错误，主要分为两类：
1. **BigDecimal 序列化问题** - kotlinx.serialization 无法序列化自定义 BigDecimal 类型
2. **依赖注入配置问题** - Koin DI 模块配置错误
3. **Compose 代码问题** - 缺少 coroutine scope 和导入

---

## 修复详情

### 1. BigDecimal 序列化器 ✅

**问题**:
```
Serializer has not been found for type 'com.brokerage.common.decimal.BigDecimal'
```

**解决方案**:
创建了 `BigDecimalSerializer` 来支持 kotlinx.serialization：

```kotlin
// shared/src/commonMain/kotlin/com/brokerage/common/decimal/BigDecimalSerializer.kt
object BigDecimalSerializer : KSerializer<BigDecimal> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("BigDecimal", PrimitiveKind.STRING)

    override fun serialize(encoder: Encoder, value: BigDecimal) {
        encoder.encodeString(value.toPlainString())
    }

    override fun deserialize(decoder: Decoder): BigDecimal {
        return BigDecimal(decoder.decodeString())
    }
}
```

**应用到数据模型**:
- `Kline.kt`: 使用 `@Serializable(with = BigDecimalSerializer::class)` 注解非空字段
- `Stock.kt`: 非空字段使用显式序列化器，可空字段使用 `@Contextual`
- `StockDetail.kt`: 同上

**示例**:
```kotlin
@Serializable
data class Kline(
    val timestamp: Long,
    @Serializable(with = BigDecimalSerializer::class) val open: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val high: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val low: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val close: BigDecimal,
    val volume: Long
)

@Serializable
data class Stock(
    val symbol: String,
    @Serializable(with = BigDecimalSerializer::class) val price: BigDecimal,
    @Contextual val pe: BigDecimal?,  // 可空类型使用 @Contextual
    @Contextual val pb: BigDecimal?
)
```

---

### 2. 依赖注入配置修复 ✅

**问题**:
```
No parameter with name 'json' found
No value passed for parameter 'baseUrl'
```

**原因**: MarketModule.kt 中的构造函数参数与实际类定义不匹配

**修复前**:
```kotlin
single {
    MarketApiClient(
        httpClient = get(),
        json = get()  // ❌ 错误参数
    )
}
```

**修复后**:
```kotlin
single {
    MarketApiClient(
        httpClient = get(),
        baseUrl = "https://api.example.com"  // ✅ 正确参数
    )
}

single {
    MarketWebSocketClient(
        httpClient = get(),
        wsUrl = "wss://api.example.com/ws",
        json = get()
    )
}
```

**修复文件**: `shared/src/commonMain/kotlin/com/brokerage/core/di/MarketModule.kt`

---

### 3. Compose Coroutine 问题修复 ✅

**问题 1**: FundingScreen.kt
```
No parameter with name 'enabled' found
```

**修复**: 移除了 `ActionButton` 不支持的 `enabled` 参数

**问题 2**: LoginScreen.kt
```
Unresolved reference 'launch'
Suspend function should be called only from a coroutine
```

**修复**:
1. 添加 `rememberCoroutineScope()`
2. 添加缺失的导入：
   ```kotlin
   import kotlinx.coroutines.delay
   import kotlinx.coroutines.launch
   ```
3. 使用 `scope.launch` 替代 `GlobalScope.launch`

**修复后代码**:
```kotlin
val scope = rememberCoroutineScope()

Button(
    onClick = {
        isLoading = true
        scope.launch {
            delay(1500)
            isLoading = false
            onLoginSuccess()
        }
    }
)
```

---

## 修复文件清单

### 新建文件
- ✅ `shared/src/commonMain/kotlin/com/brokerage/common/decimal/BigDecimalSerializer.kt`

### 修改文件
- ✅ `shared/src/commonMain/kotlin/com/brokerage/domain/marketdata/Kline.kt`
- ✅ `shared/src/commonMain/kotlin/com/brokerage/domain/marketdata/Stock.kt`
- ✅ `shared/src/commonMain/kotlin/com/brokerage/domain/marketdata/StockDetail.kt`
- ✅ `shared/src/commonMain/kotlin/com/brokerage/core/di/MarketModule.kt`
- ✅ `composeApp/src/commonMain/kotlin/com/brokerage/ui/screens/account/FundingScreen.kt`
- ✅ `composeApp/src/commonMain/kotlin/com/brokerage/ui/screens/auth/LoginScreen.kt`

---

## 编译验证结果

### ✅ Shared 模块
```bash
./gradlew shared:compileDebugKotlinAndroid
BUILD SUCCESSFUL in 2s
```

### ✅ ComposeApp 模块
```bash
./gradlew composeApp:compileDebugKotlinAndroid
BUILD SUCCESSFUL in 3s
```

---

## 技术要点

### BigDecimal 序列化策略

1. **非空字段**: 使用 `@Serializable(with = BigDecimalSerializer::class)`
   - 优点: 类型安全，编译时检查
   - 适用: 必填的金额、价格字段

2. **可空字段**: 使用 `@Contextual`
   - 优点: 支持 null 值
   - 适用: 可选的财务指标（PE、PB 等）

3. **序列化格式**: 使用字符串而非数字
   - 原因: 保持精度，避免浮点数误差
   - 符合金融编码标准

### Coroutine 最佳实践

1. **避免使用 GlobalScope**: 使用 `rememberCoroutineScope()`
2. **Compose 中的异步操作**: 始终在 composition scope 中启动
3. **导入管理**: 确保导入 `kotlinx.coroutines.launch` 和 `delay`

---

## 后续建议

### 1. 添加序列化测试
```kotlin
@Test
fun testBigDecimalSerialization() {
    val kline = Kline(
        timestamp = 1234567890,
        open = BigDecimal("100.50"),
        high = BigDecimal("101.00"),
        low = BigDecimal("100.00"),
        close = BigDecimal("100.75"),
        volume = 1000000
    )

    val json = Json.encodeToString(kline)
    val decoded = Json.decodeFromString<Kline>(json)

    assertEquals(kline.open.toPlainString(), decoded.open.toPlainString())
}
```

### 2. 配置 Koin 模块的环境变量
```kotlin
single {
    MarketApiClient(
        httpClient = get(),
        baseUrl = getProperty("API_BASE_URL", "https://api.example.com")
    )
}
```

### 3. 添加 Coroutine 异常处理
```kotlin
scope.launch {
    try {
        delay(1500)
        onLoginSuccess()
    } catch (e: Exception) {
        errorMessage = "登录失败: ${e.message}"
    } finally {
        isLoading = false
    }
}
```

---

## 总结

✅ **所有预存在的编译问题已修复**
✅ **P0 级别修复保持完整**
✅ **代码符合金融编码标准**
✅ **项目可以成功编译**

现在可以安全地进行 P1 级别功能开发或进行实际测试。
