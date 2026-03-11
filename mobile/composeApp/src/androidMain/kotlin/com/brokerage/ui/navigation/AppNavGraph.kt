package com.brokerage.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.brokerage.ui.screens.account.AccountScreen
import com.brokerage.ui.screens.account.FundingScreen
import com.brokerage.ui.screens.auth.LoginScreen
import com.brokerage.ui.screens.auth.PhoneVerificationLoginScreen
import com.brokerage.ui.screens.market.MarketScreen
import com.brokerage.ui.screens.market.SearchScreen
import com.brokerage.ui.screens.market.StockDetailScreen
import com.brokerage.ui.screens.orders.OrdersScreen
import com.brokerage.ui.screens.portfolio.PortfolioScreen
import com.brokerage.ui.screens.trade.TradeScreen

/**
 * Navigation graph for the app
 */
@Composable
fun AppNavGraph(
    navController: NavHostController,
    startDestination: String = Screen.Market.route
) {
    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        // Market screen (Tab 1)
        composable(Screen.Market.route) {
            MarketScreen(
                onStockClick = { symbol ->
                    navController.navigate(Screen.StockDetail.createRoute(symbol))
                },
                onSearchClick = {
                    navController.navigate(Screen.Search.route)
                }
            )
        }

        // Orders screen (Tab 2)
        composable(Screen.Orders.route) {
            OrdersScreen(
                onOrderClick = { orderId ->
                    // TODO: Navigate to order detail
                }
            )
        }

        // Portfolio screen (Tab 3)
        composable(Screen.Portfolio.route) {
            PortfolioScreen(
                onBuyClick = { symbol ->
                    navController.navigate(Screen.Trade.createRoute(symbol, true))
                },
                onSellClick = { symbol ->
                    navController.navigate(Screen.Trade.createRoute(symbol, false))
                }
            )
        }

        // Account screen (Tab 4)
        composable(Screen.Account.route) {
            AccountScreen(
                onFundingClick = {
                    navController.navigate(Screen.Funding.route)
                },
                onSettingsClick = {
                    navController.navigate(Screen.Settings.route)
                },
                onHelpClick = {
                    navController.navigate(Screen.Help.route)
                }
            )
        }

        // Stock detail screen
        composable(
            route = Screen.StockDetail.route,
            arguments = listOf(
                navArgument("symbol") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val symbol = backStackEntry.arguments?.getString("symbol") ?: ""
            StockDetailScreen(
                symbol = symbol,
                onBackClick = { navController.popBackStack() },
                onTradeClick = { sym ->
                    navController.navigate(Screen.Trade.createRoute(sym, true))
                }
            )
        }

        // Search screen
        composable(Screen.Search.route) {
            SearchScreen(
                onBackClick = { navController.popBackStack() },
                onStockClick = { symbol ->
                    navController.navigate(Screen.StockDetail.createRoute(symbol))
                }
            )
        }

        // Trade screen
        composable(
            route = Screen.Trade.route,
            arguments = listOf(
                navArgument("symbol") { type = NavType.StringType },
                navArgument("isBuy") { type = NavType.BoolType }
            )
        ) { backStackEntry ->
            val symbol = backStackEntry.arguments?.getString("symbol") ?: ""
            val isBuy = backStackEntry.arguments?.getBoolean("isBuy") ?: true

            TradeScreen(
                symbol = symbol,
                isBuy = isBuy,
                onBackClick = { navController.popBackStack() },
                onSubmitOrder = {
                    // TODO: Submit order and navigate back
                    navController.popBackStack()
                }
            )
        }

        // Funding screen
        composable(Screen.Funding.route) {
            FundingScreen(
                onBackClick = { navController.popBackStack() },
                onDepositClick = {
                    // TODO: Navigate to deposit screen
                },
                onWithdrawClick = {
                    // TODO: Navigate to withdraw screen
                },
                onAddBankCardClick = {
                    // TODO: Navigate to add bank card screen
                }
            )
        }

        // Settings screen
        composable(Screen.Settings.route) {
            // TODO: Implement SettingsScreen
        }

        // Help screen
        composable(Screen.Help.route) {
            // TODO: Implement HelpScreen
        }

        // Login screen (password)
        composable(Screen.Login.route) {
            LoginScreen(
                onLoginSuccess = {
                    navController.navigate(Screen.Market.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                },
                onNavigateToRegister = {
                    navController.navigate(Screen.Register.route)
                },
                onNavigateToVerificationLogin = {
                    navController.navigate(Screen.PhoneVerificationLogin.route)
                }
            )
        }

        // Phone verification login screen
        composable(Screen.PhoneVerificationLogin.route) {
            PhoneVerificationLoginScreen(
                onLoginSuccess = {
                    navController.navigate(Screen.Market.route) {
                        popUpTo(Screen.PhoneVerificationLogin.route) { inclusive = true }
                    }
                },
                onNavigateToPasswordLogin = {
                    navController.navigate(Screen.Login.route)
                },
                onNavigateToRegister = {
                    navController.navigate(Screen.Register.route)
                }
            )
        }

        // Register screen
        composable(Screen.Register.route) {
            // TODO: Implement RegisterScreen
        }
    }
}
