package com.brokerage.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import com.brokerage.ui.components.BottomNavBar
import com.brokerage.ui.screens.account.AccountScreen
import com.brokerage.ui.screens.account.FundingScreen
import com.brokerage.ui.screens.account.HelpScreen
import com.brokerage.ui.screens.account.SettingsScreen
import com.brokerage.ui.screens.market.MarketScreen
import com.brokerage.ui.screens.market.SearchScreen
import com.brokerage.ui.screens.market.StockDetailScreen
import com.brokerage.ui.screens.orders.OrdersScreen
import com.brokerage.ui.screens.portfolio.PortfolioScreen
import com.brokerage.ui.screens.trade.TradeScreen
import com.brokerage.ui.theme.BrokerageTheme

private sealed interface IosRoute {
    data object Market : IosRoute
    data object Orders : IosRoute
    data object Portfolio : IosRoute
    data object Account : IosRoute
    data object Search : IosRoute
    data object Funding : IosRoute
    data object Settings : IosRoute
    data object Help : IosRoute
    data class StockDetail(val symbol: String) : IosRoute
    data class Trade(val symbol: String, val isBuy: Boolean) : IosRoute
}

private val tabRoots = setOf(
    IosRoute.Market, IosRoute.Orders, IosRoute.Portfolio, IosRoute.Account
)

@Composable
actual fun App() {
    BrokerageTheme {
        val backStack = remember { mutableStateListOf<IosRoute>(IosRoute.Market) }
        val current = backStack.last()

        fun push(route: IosRoute) { backStack.add(route) }
        fun pop() { if (backStack.size > 1) backStack.removeAt(backStack.lastIndex) }
        fun switchTab(route: IosRoute) {
            while (backStack.size > 1) backStack.removeAt(backStack.lastIndex)
            backStack[0] = route
        }

        val isTabRoot = current in tabRoots

        val selectedTab = when (backStack.firstOrNull()) {
            is IosRoute.Orders -> 1
            is IosRoute.Portfolio -> 2
            is IosRoute.Account -> 3
            else -> 0
        }

        Scaffold(
            bottomBar = {
                if (isTabRoot) {
                    BottomNavBar(
                        selectedTab = selectedTab,
                        onTabSelected = { index ->
                            switchTab(when (index) {
                                0 -> IosRoute.Market
                                1 -> IosRoute.Orders
                                2 -> IosRoute.Portfolio
                                3 -> IosRoute.Account
                                else -> IosRoute.Market
                            })
                        }
                    )
                }
            }
        ) { padding ->
            Box(modifier = Modifier.padding(padding)) {
                when (current) {
                    is IosRoute.Market -> MarketScreen(
                        onStockClick = { symbol -> push(IosRoute.StockDetail(symbol)) },
                        onSearchClick = { push(IosRoute.Search) }
                    )
                    is IosRoute.Orders -> OrdersScreen(
                        onOrderClick = {}
                    )
                    is IosRoute.Portfolio -> PortfolioScreen(
                        onBuyClick = { symbol -> push(IosRoute.Trade(symbol, true)) },
                        onSellClick = { symbol -> push(IosRoute.Trade(symbol, false)) }
                    )
                    is IosRoute.Account -> AccountScreen(
                        onFundingClick = { push(IosRoute.Funding) },
                        onSettingsClick = { push(IosRoute.Settings) },
                        onHelpClick = { push(IosRoute.Help) }
                    )
                    is IosRoute.Funding -> FundingScreen(
                        onBackClick = { pop() },
                        onDepositClick = {},
                        onWithdrawClick = {},
                        onAddBankCardClick = {}
                    )
                    is IosRoute.Settings -> SettingsScreen(
                        onBackClick = { pop() },
                        onLogout = { switchTab(IosRoute.Market) }
                    )
                    is IosRoute.Help -> HelpScreen(
                        onBackClick = { pop() }
                    )
                    is IosRoute.Search -> SearchScreen(
                        onBackClick = { pop() },
                        onStockClick = { symbol -> push(IosRoute.StockDetail(symbol)) }
                    )
                    is IosRoute.StockDetail -> StockDetailScreen(
                        symbol = current.symbol,
                        onBackClick = { pop() },
                        onTradeClick = { symbol -> push(IosRoute.Trade(symbol, true)) }
                    )
                    is IosRoute.Trade -> TradeScreen(
                        symbol = current.symbol,
                        isBuy = current.isBuy,
                        onBackClick = { pop() },
                        onSubmitOrder = { pop() }
                    )
                }
            }
        }
    }
}
