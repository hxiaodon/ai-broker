package com.brokerage.core.network

import io.ktor.client.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.client.plugins.websocket.*
import io.ktor.serialization.kotlinx.json.*
import io.ktor.websocket.*
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.*
import kotlinx.serialization.json.Json
import kotlin.time.Duration.Companion.milliseconds

/**
 * WebSocket connection state
 */
sealed class WebSocketState {
    object Disconnected : WebSocketState()
    object Connecting : WebSocketState()
    object Connected : WebSocketState()
    data class Error(val message: String) : WebSocketState()
}

/**
 * WebSocket client for real-time market data streaming
 */
class KtorWebSocketClient(
    private val baseUrl: String,
    private val enableLogging: Boolean = true
) {
    private val client = HttpClient {
        install(WebSockets) {
            pingInterval = 20_000.milliseconds
            maxFrameSize = Long.MAX_VALUE
        }

        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                isLenient = true
                encodeDefaults = true
            })
        }

        if (enableLogging) {
            install(Logging) {
                logger = Logger.DEFAULT
                level = LogLevel.INFO
            }
        }
    }

    private var session: DefaultClientWebSocketSession? = null
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    private val _state = MutableStateFlow<WebSocketState>(WebSocketState.Disconnected)
    val state: StateFlow<WebSocketState> = _state.asStateFlow()

    private val _incoming = MutableSharedFlow<ByteArray>(
        replay = 0,
        extraBufferCapacity = 100,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )
    val incoming: SharedFlow<ByteArray> = _incoming.asSharedFlow()

    /**
     * Connect to WebSocket server
     */
    suspend fun connect(path: String = "/ws") {
        if (_state.value is WebSocketState.Connected) {
            return
        }

        _state.value = WebSocketState.Connecting

        try {
            client.webSocket(
                urlString = "$baseUrl$path"
            ) {
                session = this
                _state.value = WebSocketState.Connected

                // Start receiving messages
                scope.launch {
                    receiveMessages()
                }

                // Keep connection alive
                try {
                    for (frame in incoming) {
                        // Connection is alive
                    }
                } catch (e: Exception) {
                    handleError(e)
                }
            }
        } catch (e: Exception) {
            handleError(e)
        } finally {
            _state.value = WebSocketState.Disconnected
            session = null
        }
    }

    /**
     * Disconnect from WebSocket server
     */
    suspend fun disconnect() {
        try {
            session?.close(CloseReason(CloseReason.Codes.NORMAL, "Client disconnect"))
        } catch (e: Exception) {
            // Ignore
        } finally {
            session = null
            _state.value = WebSocketState.Disconnected
        }
    }

    /**
     * Send binary message (Protobuf)
     */
    suspend fun send(data: ByteArray) {
        try {
            session?.send(Frame.Binary(true, data))
        } catch (e: Exception) {
            handleError(e)
        }
    }

    /**
     * Send text message (JSON)
     */
    suspend fun sendText(message: String) {
        try {
            session?.send(Frame.Text(message))
        } catch (e: Exception) {
            handleError(e)
        }
    }

    /**
     * Receive messages from server
     */
    private suspend fun receiveMessages() {
        try {
            session?.incoming?.consumeAsFlow()?.collect { frame ->
                when (frame) {
                    is Frame.Binary -> {
                        val data = frame.readBytes()
                        _incoming.emit(data)
                    }
                    is Frame.Text -> {
                        val text = frame.readText()
                        _incoming.emit(text.encodeToByteArray())
                    }
                    is Frame.Close -> {
                        _state.value = WebSocketState.Disconnected
                    }
                    else -> {
                        // Ignore other frame types
                    }
                }
            }
        } catch (e: Exception) {
            handleError(e)
        }
    }

    /**
     * Handle connection errors
     */
    private fun handleError(e: Exception) {
        _state.value = WebSocketState.Error(e.message ?: "Unknown error")
    }

    /**
     * Auto-reconnect with exponential backoff
     */
    suspend fun connectWithRetry(
        path: String = "/ws",
        maxRetries: Int = 5,
        initialDelayMs: Long = 1000
    ) {
        var retries = 0
        var delay = initialDelayMs

        while (retries < maxRetries) {
            try {
                connect(path)
                break
            } catch (e: Exception) {
                retries++
                if (retries >= maxRetries) {
                    _state.value = WebSocketState.Error("Max retries exceeded")
                    break
                }

                delay(delay)
                delay = (delay * 2).coerceAtMost(30_000) // Max 30 seconds
            }
        }
    }

    /**
     * Close client and cleanup resources
     */
    fun close() {
        scope.cancel()
        client.close()
    }
}

/**
 * WebSocket client factory
 */
object WebSocketClientFactory {
    fun create(
        baseUrl: String,
        enableLogging: Boolean = true
    ): KtorWebSocketClient {
        return KtorWebSocketClient(baseUrl, enableLogging)
    }
}
