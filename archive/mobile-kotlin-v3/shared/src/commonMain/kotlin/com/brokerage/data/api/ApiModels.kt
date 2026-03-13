package com.brokerage.data.api

import kotlinx.serialization.Serializable

/**
 * API 统一响应格式
 */
@Serializable
data class ApiResponse<T>(
    val code: Int,
    val message: String,
    val data: T? = null
)

/**
 * 分页响应
 */
@Serializable
data class PagedResponse<T>(
    val total: Int,
    val page: Int,
    val pageSize: Int,
    val items: List<T>
)

/**
 * API 异常
 */
sealed class ApiException(message: String) : Exception(message) {
    class NetworkError(message: String) : ApiException(message)
    class ServerError(val code: Int, message: String) : ApiException(message)
    class Unauthorized(message: String = "Unauthorized") : ApiException(message)
    class BadRequest(message: String) : ApiException(message)
    class NotFound(message: String) : ApiException(message)
    class Unknown(message: String) : ApiException(message)
}

/**
 * API 结果封装
 */
sealed class ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>()
    data class Error(val exception: ApiException) : ApiResult<Nothing>()

    fun isSuccess(): Boolean = this is Success
    fun isError(): Boolean = this is Error

    fun getOrNull(): T? = when (this) {
        is Success -> data
        is Error -> null
    }

    fun exceptionOrNull(): ApiException? = when (this) {
        is Success -> null
        is Error -> exception
    }
}
