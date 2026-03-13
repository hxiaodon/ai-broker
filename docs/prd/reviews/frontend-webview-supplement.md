# 前端评审补充：WebView/H5 页面技术问题

**补充评审角色**: Frontend Engineer（WebView/H5 专项）
**评审日期**: 2026-03-13
**评审背景**: 补充 frontend-engineer-review.md，新增 App 内 WebView/H5 场景评审。现有报告已覆盖 Admin Panel 19 项问题，本报告聚焦 App 内 WebView/H5 场景，不重复已有内容。

**H5 场景识别**:
- PRD-08 第 7.1 节：帮助中心 "静态 FAQ 页面（WebView 或原生）"
- PRD-08 第 3.2 节：W-8BEN 查看，描述为"内嵌 PDF 查看器展示"
- PRD-02 第 2 节 Step 6：5 份风险披露文件（"内容支持中英文双语"，高度暗示 WebView 承载）
- PRD-02 第 2 节 Step 7：5 份协议（客户协议、隐私政策等），同样适合 WebView 承载
- PRD-01 第 3.1 节：冷启动页底部"用户协议/隐私政策"链接
- PRD-08 第 2.1 节："联系客服"跳转外部链接（Email 客户端）
- 营销落地页、合规公告、费率说明等运营内容（PRD 未明确，但属于行业标准做法）

---

## 一、JSBridge 接口规范完全缺失，是最大设计空白

**严重程度**: P0
**场景**: 帮助中心、风险披露文件、协议页面、营销落地页、通用 H5

**问题描述**

整套 PRD（01-08 全部模块）中没有任何关于 JSBridge 的定义。然而以下场景明确需要 H5 与 Native 通信：

1. **PRD-08 第 7.1 节** 帮助中心 H5 页面需要调用 Native 联系客服入口（第 7.2 节定义了"提交工单"按钮跳转 Email 模板）——H5 内的"联系客服"按钮如何触发 Native Email 客户端？JSBridge 还是 `mailto:` 链接？PRD 未说明。
2. **PRD-02 Step 6** 风险披露文件要求"滚动至底部后才激活'我已阅读'复选框"——若文件以 WebView 承载，H5 需要向 Native 回调"已滚动到底"事件，整个滚动检测逻辑和 Native 通信接口 PRD 完全没有设计。
3. **PRD-02 Step 7** 协议签署中，用户在 WebView 内看完协议后要回到原生表单完成签署——WebView 关闭时机、携带数据的回调格式均未定义。
4. **PRD-08 第 3.2 节** W-8BEN PDF 查看器需要内嵌于 App，若使用 WebView 承载 PDF，下载/分享 PDF 的操作需要调用 Native 系统分享能力。

缺少 JSBridge 规范意味着 iOS（WKWebView + `WKScriptMessageHandler`）和 Android（`WebView.addJavascriptInterface`）的具体接口需要 H5 团队与 Native 团队自行协商，极易造成双端不一致、联调返工。

**建议解决方案**

补充独立的 JSBridge 接口规范文档，至少需要定义以下 API：

```
// H5 → Native（调用能力）
JSBridge.call("openEmailClient", { to: "support@xxx.com", subject: "...", body: "..." })
JSBridge.call("shareFile", { url: "...", mimeType: "application/pdf", filename: "W-8BEN.pdf" })
JSBridge.call("closeWebView", { result: { agreed: true } })
JSBridge.call("getAuthToken", {})  // 获取当前 JWT（用于 H5 发起鉴权请求）

// Native → H5（注入/回调）
window.NativeBridge.onThemeChange(colorScheme)  // 主题变更通知
window.NativeBridge.setAuthContext({ token, userId, locale })  // 页面初始化注入
```

每个接口需标注：调用方（H5 or Native）、参数类型、回调格式、iOS/Android 实现差异。

---

## 二、H5 页面鉴权方案未定义，JWT 注入方式存在安全隐患

**严重程度**: P0
**场景**: 帮助中心、W-8BEN PDF 查看、风险披露/协议页面

**问题描述**

PRD-01 第四节定义的认证体系基于 JWT（15 分钟有效期）+ HttpOnly Secure Cookie（Refresh Token）。然而：

1. WebView 在 App 进程内运行，**无法直接共享 App 的 Keychain/Keystore 中的 JWT**，也无法访问主 App 进程的 Cookie（WKWebView 独立 Cookie 存储）。
2. PRD 中所有 H5 场景（帮助中心 FAQ 查询用户账户级内容、W-8BEN PDF 需要鉴权下载等）均需要登录态，但 PRD 完全没有描述 H5 如何获取 Token。
3. 常见的三种方案各有问题，PRD 未做选择：
   - **URL 参数传递 Token**：`https://h5.example.com/faq?token=xxx` — Token 会出现在服务器访问日志、浏览器历史，有泄露风险，违反安全规则。
   - **JSBridge 注入 Token**：Native 在 WebView 加载完成后调用 `evaluateJavaScript` 注入 Token — 安全，但需要 JSBridge 规范（见问题一）。
   - **Cookie 同步**：手动将 JWT 写入 WKWebView 的 `WKHTTPCookieStore` — 可行但实现复杂，且 15 分钟过期后 H5 无法自动刷新 Token（无法调用 HttpOnly Refresh Token Cookie）。

PRD-01 第 5.1 节明确要求 Refresh Token 必须存储在 HttpOnly Secure Cookie 中，这直接导致 H5 页面无法独立完成 Token 刷新，必须依赖 Native 代理。但这个代理机制 PRD 完全没有设计。

**建议解决方案**

推荐方案：Native 在 WebView 初始化时通过 JSBridge 注入短时效 Token（有效期与 WebView 会话对齐，例如 30 分钟），H5 页面使用该 Token 调用 API。Token 刷新由 Native 定期触发并通过 JSBridge 更新 H5 侧。需补充到 PRD JSBridge 规范中，并同步更新安全规格章节。

---

## 三、W-8BEN PDF 查看器实现方案不可行

**严重程度**: P1
**场景**: 个人资料 - W-8BEN 查看

**问题描述**

PRD-08 第 3.2 节写道：

> "W-8BEN 查看：以内嵌 PDF 查看器展示已签署的 W-8BEN 原件。"

此功能存在两个未解决的技术问题：

1. **PDF 文件访问链接**：W-8BEN PDF 存储于加密对象存储（PRD-02 第 5 节 `pdf_storage_key`），需要 Presigned URL 才能访问（该问题已在 frontend-engineer-review.md 问题 4.1 中针对证件图片提出，但 W-8BEN PDF 是另一个独立的 Presigned URL 接口，PRD 同样未定义）。当前 PRD-08 的 API 规格（第 8 节）只有 `GET /v1/users/settings` 和若干设置更新接口，完全没有 W-8BEN 文件访问 API。
2. **"内嵌 PDF 查看器"的实现路径未说明**：iOS 可以用 `PDFKit`（原生）或 WKWebView 加载 PDF URL，但 WKWebView 加载 PDF 不支持搜索、无法分享，且 PDF 链接若通过 URL Scheme 传递有 Token 泄露风险。Android 没有系统级 PDF 查看器，需要第三方库（如 AndroidPdfViewer）或 WebView 加载 Google Docs Viewer（但这会把含 PII 的 PDF 发送到 Google 服务器，严重违反安全规则）。

**建议解决方案**

1. 补充 `GET /v1/users/w8ben/view-url` 接口返回 15 分钟有效的 Presigned URL。
2. 明确实现方案：iOS 使用 `PDFKit` 原生渲染，Android 使用 `PdfRenderer` API（API 21+，符合 PRD-00 中 API 26 最低要求）直接渲染，两者均不经过 WebView，不暴露 Token，不依赖第三方 PDF 服务。

---

## 四、风险披露文件"滚动到底"检测方案与 WebView 实现冲突

**严重程度**: P1
**场景**: KYC Step 6 风险披露

**问题描述**

PRD-02 第 2 节 Step 6 要求：

> "5 份文件全部展开阅读（或滚动至底部）后，才激活'我已阅读全部文件'复选框"

这是一个关键合规性控制点（FINRA Rule 2010 风险披露要求）。然而：

1. PRD 未说明 5 份文件以何种方式展示：原生组件（`UIScrollView` / Compose `LazyColumn`）还是 WebView 嵌入的 HTML 文件？
2. 若使用 WebView 承载文件内容（运营侧更新文件无需发版，是常见做法），"滚动到底部"的判断必须在 WebView 内部的 JavaScript 中实现，然后通过 JSBridge 回调给 Native，Native 再更新复选框状态。这整个通信链路 PRD 完全没有设计。
3. 若 5 份文件都在各自的 WebView 中，用户关闭其中某份后重新打开是否需要重新滚动？"已读状态"在 Session 内如何持久化？PRD 没有说明。

更严重的问题是：PRD-02 第 5.3 节 `POST /v1/kyc/submit` 的请求体中没有任何"用户已阅读全部文件"的服务端验证字段，意味着目前纯依赖前端控制，绕过此检测只需修改一个 DOM 属性，这无法通过合规审计。

**建议解决方案**

1. 明确文件展示方案：推荐原生 `ScrollView` + 富文本渲染（文件内容由 CMS 管理，通过 API 下发 Markdown 或 HTML 字符串，原生渲染）。这样避免 JSBridge 复杂性，也消除 WebView 安全风险。
2. `POST /v1/kyc/submit` 请求体增加 `read_documents: ["RISK_DISCLOSURE_1", ..., "RISK_DISCLOSURE_5"]` 字段，服务端验证所有必读文件均已标记已读，防止前端绕过。

---

## 五、帮助中心 WebView URL 硬编码风险及域名白名单缺失

**严重程度**: P1
**场景**: 帮助中心 FAQ

**问题描述**

PRD-08 第 7.1 节："Phase 1：静态 FAQ 页面（WebView 或原生）"。这是整个 PRD 中唯一明确提及 WebView 的场景，但没有任何配套的技术规格：

1. **URL 硬编码风险**：若帮助中心 URL 硬编码在客户端（如 `https://help.example.com/faq`），一旦域名更换或内容结构调整，必须发版才能修复。SEC/FINRA 合规内容（费用说明、风险披露）若因 URL 硬编码导致用户看到过时版本，存在监管风险。PRD 没有要求服务端配置 WebView URL。
2. **域名白名单未定义**：WebView 如果允许加载任意 URL，攻击者可通过深链（Deep Link）或 URL Redirect 让 App 的 WebView 加载恶意页面，然后通过 JSBridge 调用 Native 能力。PRD 没有要求对 WebView 加载的 URL 做白名单限制。
3. **WebView 内跳转控制**：FAQ 页面通常会有"了解更多"链接指向外部内容，如果 WebView 不限制外部跳转，用户可能在 App 内被导航到第三方页面，产生 UX 问题并带来 XSS 风险。

**建议解决方案**

1. 增加 App 配置接口或 Remote Config（Firebase / 自建）下发 WebView URL，App 不硬编码任何 H5 地址。
2. 在 Native 的 `WKNavigationDelegate`（iOS）/ `WebViewClient.shouldOverrideUrlLoading`（Android）中实现域名白名单校验，只允许加载 `*.example.com` 域名，外部链接拦截后改为系统浏览器打开。
3. PRD 安全规格章节补充 WebView 安全策略：禁止 JavaScript 访问本地文件（`allowFileAccessFromFileURLs: false`），禁用 `allowUniversalAccessFromFileURLs`。

---

## 六、App 主题色（涨跌颜色）与 H5 页面无同步机制

**严重程度**: P1
**场景**: 帮助中心、营销落地页、任何包含行情数据展示的 H5 页面

**问题描述**

PRD-08 第 5.1 节定义了涨跌颜色方案（红涨绿跌 / 绿涨红跌），并要求：

> "设置更改后立即生效，无需重启，全局 App 状态更新，所有行情页同步变更。"

然而 WebView 页面是独立的渲染环境：

1. **H5 页面无法感知 Native 的颜色偏好设置**：`GET /v1/users/settings` 的 `color_scheme` 字段由 Native 读取，WebView 内的 H5 页面无法直接获取。如果帮助中心或营销页展示行情示例（例如"当 AAPL 涨 5% 时..."），颜色展示与 App 其余页面不一致，体验割裂。
2. **用户在 WebView 内切换颜色方案后**（如通过 Settings 页再返回 WebView），WebView 页面不会自动更新，需要刷新才能生效，而 PRD 要求的是"立即生效"。
3. **深色模式（Dark Mode）**：PRD 未明确是否支持深色模式，但 PRD-08 没有任何深色模式说明。如果 App 支持系统深色模式，WebView 的 `prefers-color-scheme` CSS 媒体查询与 App 的 Dark Mode 状态需要同步，否则 WebView 页面在深色模式下显示白底，与 App 其余页面不协调。

**建议解决方案**

1. 在 Native 加载 WebView 时，通过 URL 参数或 JSBridge 注入当前颜色方案：`?colorScheme=RED_UP&theme=light`，H5 页面根据参数设置 CSS 变量。
2. 用户更改颜色设置后，若 WebView 仍在显示，Native 通过 JSBridge 推送 `onThemeChange` 事件，H5 实时更新 CSS 变量，无需刷新。
3. PRD-08 第 5.1 节补充"颜色方案同步至 H5 页面"的技术要求。

---

## 七、WebView 内 Deep Link 与 Custom URL Scheme 的双向跳转未定义

**严重程度**: P1
**场景**: 帮助中心、营销落地页、合规公告

**问题描述**

PRD-01 第 3.1 节冷启动页提到"用户协议/隐私政策"链接，这类页面通常在 WebView 内展示。PRD-03 新闻 Tab 的"点击行为：跳转外部浏览器打开原文链接"表明 PRD 区分了 WebView 内打开和外部浏览器打开，但整个 PRD 没有统一的跳转规则定义。具体缺陷：

1. **从 H5 页面跳转回 Native 页面的机制未定义**：营销落地页通常包含"立即开户"CTA 按钮，点击后应跳转到 App 的 KYC 流程（Native 页面）。H5 如何触发这个跳转？PRD-00 提到 `app://` Custom URL Scheme，但没有任何文档定义具体的 scheme 格式（如 `app://kyc/start`、`app://trading/buy?symbol=AAPL`），也没有 Native 侧对 scheme 的处理规范。
2. **WebView 多级页内跳转后的返回处理**：帮助中心 FAQ 可能包含分类 → 文章 → 相关文章的多级跳转。Android 返回键默认触发 `Activity.onBackPressed`，如果 Native 没有拦截 WebView 的 history，会直接关闭 WebView 而非返回上一级 H5 页面。iOS 左滑手势同理（WebView 的 `canGoBack` 需要被 Native 检测并覆盖左滑手势）。PRD 完全没有这个处理逻辑的规格。
3. **外部链接处理不一致**：PRD-03 第 3.5 节"新闻 Tab"点击跳转"外部浏览器"，PRD-01 第 3.1 节"用户协议"暗示 WebView 内打开，PRD-08 第 7.2 节"联系客服"跳转"Email 客户端"。不同场景的处理方式分散在各个 PRD 章节，没有统一的外部链接处理规则文档，前端实现时极易出现不一致。

**建议解决方案**

1. 补充 App URL Scheme 规范文档，定义所有可从 H5 触发的 Native 页面跳转（开户、入金、股票详情等）及参数格式。
2. 在 WebView 组件封装层统一处理返回逻辑：优先检测 `webView.canGoBack`，可回退则调用 `webView.goBack()`，否则关闭 WebView。
3. 统一定义三种链接处理策略：（A）WebView 内打开、（B）系统浏览器打开、（C）Native 页面跳转，并在各 PRD 中统一使用这三种标记。

---

## 八、WebView 加载失败的降级与错误处理方案缺失

**严重程度**: P1
**场景**: 帮助中心、W-8BEN PDF 查看、风险披露文件、营销落地页

**问题描述**

整个 PRD 的"错误处理"章节仅覆盖了 Native 场景（PRD-01 第 7 节、PRD-07 等），没有任何针对 WebView 加载失败的处理规格：

1. **帮助中心 WebView 加载失败（网络异常或服务器 5xx）**：用户处于弱网/无网环境时，WebView 会显示浏览器默认错误页（白屏或"网页无法打开"），与 App 整体风格完全不符，且用户无法理解这是 App 内的页面。PRD 没有要求 Native 拦截 WebView 加载错误并展示品牌化的错误页。
2. **KYC Step 6 风险披露文件加载失败**：若风险披露文件通过 WebView 加载（H5 页面），在用户网络不佳时文件加载失败，"我已阅读"复选框应如何处理？是禁止提交（合规要求，但体验差）还是降级为显示本地缓存版本（需要 PRD 定义缓存策略）？PRD 完全没有这个场景的处理逻辑，而这直接影响 KYC 完成率这一核心指标。
3. **WebView 白屏超时**：WebView 冷启动有首屏白屏问题（通常 500ms-2s），PRD 没有要求任何 Loading 状态（Skeleton 或 Loading Spinner），与 PRD-07（跨模块交互规格）中定义的"Loading 状态"规范不一致。

**建议解决方案**

1. 所有 WebView 容器必须实现：（A）加载中 Loading 状态（进度条或 Spinner）；（B）加载失败降级页（品牌化错误页 + 重试按钮）；（C）超时时间（建议 10 秒）。
2. 对于合规关键页面（风险披露、协议条款），必须提供离线 fallback：App 内预置最新版本的文件，WebView 失败时展示预置版本，并标注版本日期。
3. 将 WebView 错误处理规范纳入 PRD-07 跨模块交互的错误处理章节。

---

## 九、营销/运营 H5 页面的 CMS 机制与版本管理完全缺失

**严重程度**: P2
**场景**: 帮助中心、营销落地页、合规公告、费率说明

**问题描述**

PRD-08 第 7.1 节定义帮助中心为"静态 FAQ 页面"，PRD-00 将"Phase 1 仅中文"作为范围约束。然而对于一家金融机构：

1. **费率说明、手续费公告频繁变更**：SEC/FINRA 要求费率变更必须提前通知用户，且通知记录需要保留。如果费率说明 H5 页面没有版本管理机制，无法证明用户在某个时间点看到的是哪个版本的费率，无法满足监管审计要求。PRD 完全没有设计 H5 内容的版本管理或版本记录机制。
2. **协议条款更新的重签流程**：PRD-02 第 2 节 Step 7 定义了"协议版本升级需重新签署"，但当运营侧更新了"客户协议"H5 页面内容后，系统如何感知到版本变更？如何触发用户重签？H5 URL 不变但内容变更时，后端如何判断用户签署的是哪个版本？`agreement_signatures` 表中的 `agreement_version` 字段由谁来维护？PRD 没有定义 H5 内容版本与数据库版本字段的同步机制。
3. **没有 H5 URL 的服务端配置能力**：若 H5 页面 URL 硬编码在客户端，发现安全漏洞时无法服务端下发新 URL 关闭旧页面。对于金融 App，能够随时关闭特定 H5 入口（例如某营销活动因合规问题需要下线）是必要的运营能力，PRD 没有此设计。

**建议解决方案**

1. 补充"内容配置接口"（Content Config API）：`GET /v1/app/content-config` 返回各 H5 入口的 URL、版本号、是否启用。客户端每次启动时更新本地配置，从而支持服务端动态开关。
2. `agreement_signatures` 表的 `agreement_version` 字段需要对应一个服务端维护的协议版本注册表，版本号变更时通过 Push Notification 提醒用户重新签署。
3. 合规相关 H5 内容（费率说明、风险声明）的每次更新需要在 Admin Panel 进行版本记录，并保留旧版本快照，供监管审计查询。

---

## 十、H5 页面访客态与登录态功能边界未定义，与 Native 规则不一致

**严重程度**: P2
**场景**: 帮助中心、营销落地页

**问题描述**

PRD-01 第 6 节详细定义了 Native 页面的访客模式规则（哪些页面可访问、哪些需要登录）。但对 H5/WebView 页面：

1. **帮助中心是否需要登录**：PRD-08 第 7.1 节没有说明帮助中心是否需要用户登录才能访问。从用户体验角度，帮助中心在账户被锁定、KYC 审核失败时应该可以访问（用户最需要帮助的时候）；但帮助中心若包含账户相关的个性化内容（"我的工单"），则需要登录。这个边界 PRD 未定义。
2. **访客态 WebView 的 Token 注入**：PRD-01 明确定义了访客模式下哪些 Native 页面可访问，但没有说明访客进入 WebView 时是否注入 Token（访客没有 Token），H5 页面如何判断访客态和登录态并展示不同内容？
3. **H5 内的登录引导与 Native 登录入口的冲突**：营销落地页如果包含"立即开户"按钮，访客点击后应跳转 Native 的登录/注册流程，还是 H5 内展示一个登录表单？如果展示 H5 登录表单，这与 PRD-01 定义的唯一登录方式（Native OTP 流程）产生冲突——H5 内没有 OTP 登录能力，整个认证链不完整。PRD 没有解决这个矛盾。

**建议解决方案**

1. 在 PRD-01 访客模式章节补充"H5 页面访客规则"：明确哪些 H5 页面允许无 Token 访问（公开页），哪些需要登录态（个性化内容）。
2. 对于访客点击"立即开户"等需要登录的 H5 CTA，统一通过 `JSBridge.call("openNativeLogin")` 触发 Native 登录流程，H5 内不实现任何登录逻辑，登录完成后 Native 回调 H5 并注入 Token。
3. 帮助中心 H5 页面设计为公开可访问（无需 Token），个性化内容（工单记录等）Phase 2 再实现。

---

## 总结

| # | 场景 | 问题 | 严重程度 |
|---|------|------|---------|
| 1 | 帮助中心 / 风险披露 / 协议 / 通用 H5 | JSBridge 接口规范完全缺失，双端实现无依据 | **P0** |
| 2 | 帮助中心 / W-8BEN / 风险披露 | H5 页面鉴权方案未定义，JWT 注入机制缺失，Refresh 链路不完整 | **P0** |
| 3 | 个人资料 - W-8BEN PDF 查看 | PDF 查看器实现方案不可行，访问 API 缺失，Android 方案可能将 PII 发送到 Google | **P1** |
| 4 | KYC Step 6 风险披露 | "滚动到底"检测依赖前端，服务端无验证，可被绕过，不符合合规要求 | **P1** |
| 5 | 帮助中心 / 营销落地页 | WebView URL 硬编码风险，域名白名单完全缺失，存在任意域名加载风险 | **P1** |
| 6 | 帮助中心 / 含行情的 H5 页面 | App 涨跌颜色方案与 H5 无同步机制，深色模式状态不同步 | **P1** |
| 7 | 帮助中心 / 营销落地页 / 协议页面 | Deep Link / Custom URL Scheme 未定义，WebView 内返回键逻辑缺失 | **P1** |
| 8 | 帮助中心 / W-8BEN / 风险披露 | WebView 加载失败无降级方案，合规关键页面无离线 fallback | **P1** |
| 9 | 帮助中心 / 营销页 / 费率说明 / 协议 | H5 内容无版本管理，协议版本与数据库 `agreement_version` 同步机制缺失 | **P2** |
| 10 | 帮助中心 / 营销落地页 | 访客态 H5 功能边界未定义，H5 登录引导与 Native OTP 流程存在冲突 | **P2** |

**对 PM 的行动建议（Sprint 0 前完成）**

1. **新增 JSBridge 规范文档**：定义所有 H5 ↔ Native 通信接口（调用方、参数、回调、iOS/Android 差异），这是所有 WebView/H5 功能开发的前置依赖。
2. **明确 H5 鉴权方案**：选定 JSBridge Token 注入方案，并更新 PRD-01 安全规格章节。
3. **W-8BEN PDF 查看**：确认使用原生 PDFKit/PdfRenderer 方案，并补充文件访问 API。
4. **KYC Step 6 服务端验证**：在 `POST /v1/kyc/submit` 增加已读文件列表字段，消除合规风险。
5. **补充 App URL Scheme 规范**：覆盖所有从 H5 触发 Native 跳转的场景。
6. **内容配置接口**：实现服务端下发 H5 URL 配置，取消客户端硬编码。
