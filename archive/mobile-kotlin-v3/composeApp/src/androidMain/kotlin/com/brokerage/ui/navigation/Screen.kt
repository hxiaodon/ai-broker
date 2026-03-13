package com.brokerage.ui.navigation

/**
 * Navigation routes for the app
 */
sealed class Screen(val route: String) {
    // Main tabs (bottom navigation)
    data object Market : Screen("market")
    data object Orders : Screen("orders")
    data object Portfolio : Screen("portfolio")
    data object Account : Screen("account")

    // Detail screens
    data object StockDetail : Screen("stock_detail/{symbol}") {
        fun createRoute(symbol: String) = "stock_detail/$symbol"
    }

    data object Search : Screen("search")

    data object Trade : Screen("trade/{symbol}/{isBuy}") {
        fun createRoute(symbol: String, isBuy: Boolean) = "trade/$symbol/$isBuy"
    }

    data object Funding : Screen("funding")
    data object Settings : Screen("settings")
    data object Help : Screen("help")

    // Auth screens
    data object Login : Screen("login")
    data object PhoneVerificationLogin : Screen("phone_verification_login")
    data object Register : Screen("register")

    companion object {
        // Main tab routes for bottom navigation
        val mainTabs = listOf(Market, Orders, Portfolio, Account)
    }
}
