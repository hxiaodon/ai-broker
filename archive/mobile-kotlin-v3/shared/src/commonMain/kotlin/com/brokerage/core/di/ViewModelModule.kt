package com.brokerage.core.di

import com.brokerage.presentation.market.MarketViewModel
import com.brokerage.presentation.market.SearchViewModel
import com.brokerage.presentation.market.StockDetailViewModel
import org.koin.dsl.module

/**
 * ViewModel DI 配置
 */
val viewModelModule = module {
    // Market ViewModels
    factory { MarketViewModel(repository = get()) }
    factory { SearchViewModel(repository = get()) }
    factory { (symbol: String) -> StockDetailViewModel(repository = get(), symbol = symbol) }
}
