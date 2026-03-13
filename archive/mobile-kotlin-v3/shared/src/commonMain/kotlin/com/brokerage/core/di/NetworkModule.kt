package com.brokerage.core.di

import com.brokerage.core.network.createHttpClient
import com.brokerage.core.network.createJson
import org.koin.dsl.module

/**
 * 网络模块 DI 配置
 */
val networkModule = module {
    // JSON
    single { createJson() }

    // HttpClient
    single {
        createHttpClient(
            json = get(),
            tokenProvider = { get<TokenManager>().getToken() }
        )
    }
}

/**
 * Token 管理器接口
 */
interface TokenManager {
    fun getToken(): String?
    fun setToken(token: String)
    fun clearToken()
}

/**
 * Token 管理器实现（使用内存存储，实际应使用 SecureStorage）
 */
class TokenManagerImpl : TokenManager {
    private var token: String? = null

    override fun getToken(): String? = token

    override fun setToken(token: String) {
        this.token = token
    }

    override fun clearToken() {
        token = null
    }
}
