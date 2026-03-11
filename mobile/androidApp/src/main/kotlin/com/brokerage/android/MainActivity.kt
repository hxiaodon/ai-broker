package com.brokerage.android

import android.app.Application
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.brokerage.core.di.TokenManager
import com.brokerage.core.di.TokenManagerImpl
import com.brokerage.core.di.marketModule
import com.brokerage.core.di.networkModule
import com.brokerage.core.di.viewModelModule
import com.brokerage.ui.MainScreen
import org.koin.android.ext.koin.androidContext
import org.koin.core.context.startKoin
import org.koin.dsl.module

class BrokerageApp : Application() {
    override fun onCreate() {
        super.onCreate()

        // Initialize Koin
        startKoin {
            androidContext(this@BrokerageApp)
            modules(
                networkModule,
                marketModule,
                viewModelModule,
                appModule
            )
        }
    }
}

val appModule = module {
    single<TokenManager> { TokenManagerImpl() }
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MainScreen()
        }
    }
}
