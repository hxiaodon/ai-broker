package com.brokerage.core.network

import io.ktor.client.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.client.plugins.websocket.*
import io.ktor.client.request.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

/**
 * 创建配置好的 HttpClient
 */
fun createHttpClient(
    json: Json,
    tokenProvider: () -> String?
): HttpClient {
    return HttpClient {
        // JSON 序列化
        install(ContentNegotiation) {
            json(json)
        }

        // WebSocket 支持
        install(WebSockets)

        // 日志
        install(Logging) {
            logger = Logger.DEFAULT
            level = LogLevel.INFO
        }

        // 超时配置
        install(HttpTimeout) {
            requestTimeoutMillis = 30_000
            connectTimeoutMillis = 10_000
            socketTimeoutMillis = 30_000
        }

        // 默认请求配置
        defaultRequest {
            // JWT 认证
            tokenProvider()?.let { token ->
                header(HttpHeaders.Authorization, "Bearer $token")
            }

            // 通用 headers
            header(HttpHeaders.ContentType, ContentType.Application.Json)
            header(HttpHeaders.Accept, ContentType.Application.Json)
        }
    }
}

/**
 * 创建 JSON 配置
 */
fun createJson(): Json {
    return Json {
        ignoreUnknownKeys = true
        isLenient = true
        encodeDefaults = true
        prettyPrint = false
    }
}
