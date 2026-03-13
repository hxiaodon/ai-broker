package com.brokerage.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.brokerage.ui.components.BottomNavBar
import com.brokerage.ui.navigation.AppNavGraph
import com.brokerage.ui.navigation.Screen
import com.brokerage.ui.theme.BrokerageTheme

/**
 * Main container with bottom navigation
 * Android-specific implementation
 */
@Composable
fun MainScreen() {
    BrokerageTheme {
        val navController = rememberNavController()
        val navBackStackEntry by navController.currentBackStackEntryAsState()
        val currentRoute = navBackStackEntry?.destination?.route

        // Determine if we should show bottom nav
        val showBottomNav = when (currentRoute) {
            Screen.Market.route,
            Screen.Orders.route,
            Screen.Portfolio.route,
            Screen.Account.route -> true
            else -> false
        }

        // Determine selected tab index
        val selectedTab = when (currentRoute) {
            Screen.Market.route -> 0
            Screen.Orders.route -> 1
            Screen.Portfolio.route -> 2
            Screen.Account.route -> 3
            else -> 0
        }

        Scaffold(
            bottomBar = {
                if (showBottomNav) {
                    BottomNavBar(
                        selectedTab = selectedTab,
                        onTabSelected = { index ->
                            val route = when (index) {
                                0 -> Screen.Market.route
                                1 -> Screen.Orders.route
                                2 -> Screen.Portfolio.route
                                3 -> Screen.Account.route
                                else -> Screen.Market.route
                            }
                            navController.navigate(route) {
                                // Pop up to the start destination
                                popUpTo(Screen.Market.route) {
                                    saveState = true
                                }
                                // Avoid multiple copies of the same destination
                                launchSingleTop = true
                                // Restore state when reselecting a previously selected item
                                restoreState = true
                            }
                        }
                    )
                }
            }
        ) { paddingValues ->
            Box(modifier = Modifier.padding(paddingValues)) {
                AppNavGraph(navController = navController)
            }
        }
    }
}
