package com.brokerage.core.di

import com.brokerage.data.api.MarketApiClient
import com.brokerage.data.repository.FakeMarketRepository
import com.brokerage.data.repository.MarketRepository
import com.brokerage.data.repository.MarketRepositoryImpl
import com.brokerage.data.websocket.MarketWebSocketClient
import org.koin.dsl.module

/**
 * 行情模块 DI 配置
 */
val marketModule = module {
    // API 客户端 (kept for future use with real backend)
    single {
        MarketApiClient(
            httpClient = get(),
            baseUrl = "https://api.example.com"
        )
    }

    // WebSocket 客户端 (kept for future use with real backend)
    single {
        MarketWebSocketClient(
            httpClient = get(),
            wsUrl = "wss://api.example.com/ws",
            json = get()
        )
    }

    // Repository — using fake implementation for end-to-end testing without a real backend.
    // To switch back to the real implementation, replace FakeMarketRepository() with:
    //   MarketRepositoryImpl(apiClient = get(), wsClient = get())
    single<MarketRepository> {
        FakeMarketRepository()
    }
}
