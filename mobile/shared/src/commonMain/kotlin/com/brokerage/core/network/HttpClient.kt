package com.brokerage.core.network

import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

/**
 * API response wrapper
 */
sealed class ApiResponse<out T> {
    data class Success<T>(val data: T) : ApiResponse<T>()
    data class Error(val code: Int, val message: String) : ApiResponse<Nothing>()
    data class Exception(val throwable: Throwable) : ApiResponse<Nothing>()
}

/**
 * HTTP client for REST API calls
 */
class KtorHttpClient(
    private val baseUrl: String,
    private val enableLogging: Boolean = true
) {
    @PublishedApi
    internal val client = HttpClient {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                isLenient = true
                encodeDefaults = true
                prettyPrint = true
            })
        }

        install(HttpTimeout) {
            requestTimeoutMillis = 30_000
            connectTimeoutMillis = 10_000
            socketTimeoutMillis = 30_000
        }

        if (enableLogging) {
            install(Logging) {
                logger = Logger.DEFAULT
                level = LogLevel.INFO
            }
        }

        defaultRequest {
            url(baseUrl)
            contentType(ContentType.Application.Json)
        }
    }

    /**
     * GET request
     */
    suspend inline fun <reified T> get(
        path: String,
        headers: Map<String, String> = emptyMap(),
        params: Map<String, String> = emptyMap()
    ): ApiResponse<T> {
        return try {
            val response: HttpResponse = client.get(path) {
                headers.forEach { (key, value) ->
                    header(key, value)
                }
                params.forEach { (key, value) ->
                    parameter(key, value)
                }
            }

            if (response.status.isSuccess()) {
                ApiResponse.Success(response.body<T>())
            } else {
                ApiResponse.Error(
                    response.status.value,
                    response.bodyAsText()
                )
            }
        } catch (e: Exception) {
            ApiResponse.Exception(e)
        }
    }

    /**
     * POST request
     */
    suspend inline fun <reified T, reified R> post(
        path: String,
        body: T,
        headers: Map<String, String> = emptyMap()
    ): ApiResponse<R> {
        return try {
            val response: HttpResponse = client.post(path) {
                headers.forEach { (key, value) ->
                    header(key, value)
                }
                setBody(body)
            }

            if (response.status.isSuccess()) {
                ApiResponse.Success(response.body<R>())
            } else {
                ApiResponse.Error(
                    response.status.value,
                    response.bodyAsText()
                )
            }
        } catch (e: Exception) {
            ApiResponse.Exception(e)
        }
    }

    /**
     * PUT request
     */
    suspend inline fun <reified T, reified R> put(
        path: String,
        body: T,
        headers: Map<String, String> = emptyMap()
    ): ApiResponse<R> {
        return try {
            val response: HttpResponse = client.put(path) {
                headers.forEach { (key, value) ->
                    header(key, value)
                }
                setBody(body)
            }

            if (response.status.isSuccess()) {
                ApiResponse.Success(response.body<R>())
            } else {
                ApiResponse.Error(
                    response.status.value,
                    response.bodyAsText()
                )
            }
        } catch (e: Exception) {
            ApiResponse.Exception(e)
        }
    }

    /**
     * DELETE request
     */
    suspend inline fun <reified T> delete(
        path: String,
        headers: Map<String, String> = emptyMap()
    ): ApiResponse<T> {
        return try {
            val response: HttpResponse = client.delete(path) {
                headers.forEach { (key, value) ->
                    header(key, value)
                }
            }

            if (response.status.isSuccess()) {
                ApiResponse.Success(response.body<T>())
            } else {
                ApiResponse.Error(
                    response.status.value,
                    response.bodyAsText()
                )
            }
        } catch (e: Exception) {
            ApiResponse.Exception(e)
        }
    }

    /**
     * Close client
     */
    fun close() {
        client.close()
    }
}

/**
 * HTTP client factory
 */
object HttpClientFactory {
    fun create(
        baseUrl: String,
        enableLogging: Boolean = true
    ): KtorHttpClient {
        return KtorHttpClient(baseUrl, enableLogging)
    }
}

/**
 * Extension functions for ApiResponse
 */
fun <T> ApiResponse<T>.isSuccess(): Boolean = this is ApiResponse.Success

fun <T> ApiResponse<T>.isError(): Boolean = this is ApiResponse.Error || this is ApiResponse.Exception

fun <T> ApiResponse<T>.getOrNull(): T? = when (this) {
    is ApiResponse.Success -> data
    else -> null
}

fun <T> ApiResponse<T>.getOrThrow(): T = when (this) {
    is ApiResponse.Success -> data
    is ApiResponse.Error -> throw RuntimeException("API Error: $code - $message")
    is ApiResponse.Exception -> throw throwable
}

fun <T, R> ApiResponse<T>.map(transform: (T) -> R): ApiResponse<R> = when (this) {
    is ApiResponse.Success -> ApiResponse.Success(transform(data))
    is ApiResponse.Error -> this
    is ApiResponse.Exception -> this
}
