package com.brokerage.data.websocket

import com.brokerage.domain.marketdata.DepthData
import com.brokerage.domain.marketdata.QuoteData
import com.brokerage.domain.marketdata.TradeRecord
import com.brokerage.domain.marketdata.WsMessage
import io.ktor.client.*
import io.ktor.client.plugins.websocket.*
import io.ktor.websocket.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString

/**
 * WebSocket 客户端状态
 */
enum class WsState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    RECONNECTING,
    ERROR
}

/**
 * 行情 WebSocket 客户端
 */
class MarketWebSocketClient(
    private val httpClient: HttpClient,
    private val wsUrl: String,
    private val json: Json
) {
    private var session: DefaultClientWebSocketSession? = null
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    private val _state = MutableStateFlow(WsState.DISCONNECTED)
    val state: StateFlow<WsState> = _state.asStateFlow()

    private val _quotes = MutableSharedFlow<QuoteData>(replay = 0, extraBufferCapacity = 100)
    val quotes: SharedFlow<QuoteData> = _quotes.asSharedFlow()

    private val _depth = MutableSharedFlow<DepthData>(replay = 1, extraBufferCapacity = 50)
    val depth: SharedFlow<DepthData> = _depth.asSharedFlow()

    private val _trades = MutableSharedFlow<TradeRecord>(replay = 0, extraBufferCapacity = 100)
    val trades: SharedFlow<TradeRecord> = _trades.asSharedFlow()

    private val _errors = MutableSharedFlow<String>(replay = 0, extraBufferCapacity = 10)
    val errors: SharedFlow<String> = _errors.asSharedFlow()

    private var heartbeatJob: Job? = null
    private var reconnectJob: Job? = null
    private var reconnectAttempts = 0
    private val maxReconnectAttempts = 5
    private val subscribedSymbols = mutableSetOf<String>()
    private val subscribedDepthSymbols = mutableSetOf<String>()

    /**
     * 连接 WebSocket（token 从 HttpClient 的 Authorization header 自动获取）
     */
    suspend fun connect(token: String = "") {
        if (_state.value == WsState.CONNECTED || _state.value == WsState.CONNECTING) {
            return
        }

        _state.value = WsState.CONNECTING

        try {
            // Token 已在 HttpClient 的 defaultRequest 中配置，无需手动传递
            session = httpClient.webSocketSession(urlString = wsUrl)
            _state.value = WsState.CONNECTED
            reconnectAttempts = 0

            startHeartbeat()
            startReceiving()

            // 重新订阅之前的股票
            if (subscribedSymbols.isNotEmpty()) {
                subscribe(subscribedSymbols.toList())
            }

            // 重新订阅深度数据
            for (symbol in subscribedDepthSymbols.toList()) {
                val message = WsMessage.SubscribeDepth(symbol = symbol)
                sendMessage(message)
            }
        } catch (e: Exception) {
            _state.value = WsState.ERROR
            _errors.emit("Connection failed: ${e.message}")
            scheduleReconnect()
        }
    }

    /**
     * 断开连接
     */
    suspend fun disconnect() {
        heartbeatJob?.cancel()
        reconnectJob?.cancel()
        session?.close()
        session = null
        _state.value = WsState.DISCONNECTED
        subscribedSymbols.clear()
        subscribedDepthSymbols.clear()
    }

    /**
     * 订阅股票
     */
    suspend fun subscribe(symbols: List<String>) {
        if (symbols.isEmpty()) return

        subscribedSymbols.addAll(symbols)

        if (_state.value == WsState.CONNECTED) {
            val message = WsMessage.Subscribe(symbols = symbols)
            sendMessage(message)
        }
    }

    /**
     * 取消订阅
     */
    suspend fun unsubscribe(symbols: List<String>) {
        if (symbols.isEmpty()) return

        subscribedSymbols.removeAll(symbols.toSet())

        if (_state.value == WsState.CONNECTED) {
            val message = WsMessage.Unsubscribe(symbols = symbols)
            sendMessage(message)
        }
    }

    /**
     * 订阅深度行情
     */
    suspend fun subscribeDepth(symbol: String) {
        subscribedDepthSymbols.add(symbol)

        if (_state.value == WsState.CONNECTED) {
            val message = WsMessage.SubscribeDepth(symbol = symbol)
            sendMessage(message)
        }
    }

    /**
     * 取消订阅深度行情
     */
    suspend fun unsubscribeDepth(symbol: String) {
        subscribedDepthSymbols.remove(symbol)

        if (_state.value == WsState.CONNECTED) {
            val message = WsMessage.UnsubscribeDepth(symbol = symbol)
            sendMessage(message)
        }
    }

    /**
     * 发送消息
     */
    private suspend fun sendMessage(message: WsMessage) {
        try {
            val jsonString = when (message) {
                is WsMessage.Subscribe -> json.encodeToString(message)
                is WsMessage.Unsubscribe -> json.encodeToString(message)
                is WsMessage.Ping -> json.encodeToString(message)
                is WsMessage.SubscribeDepth -> json.encodeToString(message)
                is WsMessage.UnsubscribeDepth -> json.encodeToString(message)
                else -> return
            }
            session?.send(Frame.Text(jsonString))
        } catch (e: Exception) {
            _errors.emit("Failed to send message: ${e.message}")
        }
    }

    /**
     * 启动心跳
     */
    private fun startHeartbeat() {
        heartbeatJob?.cancel()
        heartbeatJob = scope.launch {
            while (isActive && _state.value == WsState.CONNECTED) {
                delay(30_000) // 30 秒心跳
                try {
                    sendMessage(WsMessage.Ping())
                } catch (e: Exception) {
                    _errors.emit("Heartbeat failed: ${e.message}")
                    scheduleReconnect()
                    break
                }
            }
        }
    }

    /**
     * 接收消息
     */
    private fun startReceiving() {
        scope.launch {
            try {
                session?.incoming?.consumeAsFlow()?.collect { frame ->
                    if (frame is Frame.Text) {
                        val text = frame.readText()
                        handleMessage(text)
                    }
                }
            } catch (e: Exception) {
                if (_state.value == WsState.CONNECTED) {
                    _errors.emit("Connection lost: ${e.message}")
                    scheduleReconnect()
                }
            }
        }
    }

    /**
     * 处理消息
     */
    private suspend fun handleMessage(text: String) {
        try {
            // 简单解析 action 字段
            val actionRegex = """"action"\s*:\s*"(\w+)"""".toRegex()
            val action = actionRegex.find(text)?.groupValues?.get(1)

            when (action) {
                "quote" -> {
                    val message = json.decodeFromString<WsMessage.Quote>(text)
                    _quotes.emit(message.data)
                }
                "depth" -> {
                    val message = json.decodeFromString<WsMessage.Depth>(text)
                    _depth.emit(message.data)
                }
                "trade" -> {
                    val message = json.decodeFromString<WsMessage.Trade>(text)
                    _trades.emit(message.data)
                }
                "pong" -> {
                    // 心跳响应，忽略
                }
                "error" -> {
                    val message = json.decodeFromString<WsMessage.Error>(text)
                    _errors.emit("Server error: ${message.message}")
                }
            }
        } catch (e: Exception) {
            _errors.emit("Failed to parse message: ${e.message}")
        }
    }

    /**
     * 调度重连
     */
    private fun scheduleReconnect() {
        if (reconnectAttempts >= maxReconnectAttempts) {
            _state.value = WsState.ERROR
            scope.launch {
                _errors.emit("Max reconnect attempts reached")
            }
            return
        }

        reconnectJob?.cancel()
        reconnectJob = scope.launch {
            _state.value = WsState.RECONNECTING
            reconnectAttempts++

            val delay = minOf(1000L * (1 shl reconnectAttempts), 30_000L) // 指数退避，最大 30 秒
            delay(delay)

            // 需要从外部传入 token，这里简化处理
            // 实际应该通过回调或其他方式获取最新 token
            _errors.emit("Reconnecting... (attempt $reconnectAttempts)")
        }
    }

    /**
     * 清理资源
     */
    fun dispose() {
        scope.cancel()
        subscribedSymbols.clear()
        subscribedDepthSymbols.clear()
    }
}
