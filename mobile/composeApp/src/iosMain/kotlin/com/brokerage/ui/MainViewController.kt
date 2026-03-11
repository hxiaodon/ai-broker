package com.brokerage.ui

import androidx.compose.ui.window.ComposeUIViewController
import com.brokerage.core.di.TokenManager
import com.brokerage.core.di.TokenManagerImpl
import com.brokerage.core.di.marketModule
import com.brokerage.core.di.networkModule
import com.brokerage.core.di.viewModelModule
import org.koin.core.context.startKoin
import org.koin.dsl.module
import platform.UIKit.UIViewController

private val appModule = module {
    single<TokenManager> { TokenManagerImpl() }
}

fun MainViewController(): UIViewController {
    initKoinIfNeeded()
    return ComposeUIViewController(
        configure = {
            enforceStrictPlistSanityCheck = false
        }
    ) {
        App()
    }
}

private var koinStarted = false

private fun initKoinIfNeeded() {
    if (!koinStarted) {
        koinStarted = true
        startKoin {
            modules(
                networkModule,
                marketModule,
                viewModelModule,
                appModule
            )
        }
    }
}
