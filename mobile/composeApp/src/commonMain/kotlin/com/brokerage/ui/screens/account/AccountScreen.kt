package com.brokerage.ui.screens.account
import com.brokerage.ui.icons.BrokerageIcons

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.brokerage.ui.components.*
import com.brokerage.ui.theme.*

/**
 * Account screen - user profile and settings
 * Based on design document "我的" Tab
 */
@Composable
fun AccountScreen(
    onFundingClick: () -> Unit,
    onSettingsClick: () -> Unit,
    onHelpClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BackgroundLight)
    ) {
        // Top bar
        AccountTopBar()

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
        ) {
            // User profile card
            UserProfileCard()

            Spacer(modifier = Modifier.height(Spacing.small))

            // Menu sections
            MenuSection(
                title = "资金管理",
                items = listOf(
                    MenuItem("出入金", "💰", onClick = onFundingClick),
                    MenuItem("银行卡管理", "💳", onClick = { /* TODO */ }),
                    MenuItem("资金明细", "📊", onClick = { /* TODO */ })
                )
            )

            Spacer(modifier = Modifier.height(Spacing.small))

            MenuSection(
                title = "账户设置",
                items = listOf(
                    MenuItem("个人信息", "👤", onClick = { /* TODO */ }),
                    MenuItem("安全设置", "🔒", onClick = { /* TODO */ }),
                    MenuItem("通知设置", "🔔", onClick = { /* TODO */ }),
                    MenuItem("偏好设置", "⚙️", onClick = onSettingsClick)
                )
            )

            Spacer(modifier = Modifier.height(Spacing.small))

            MenuSection(
                title = "帮助与支持",
                items = listOf(
                    MenuItem("帮助中心", "❓", onClick = onHelpClick),
                    MenuItem("联系客服", "💬", onClick = { /* TODO */ }),
                    MenuItem("关于我们", "ℹ️", onClick = { /* TODO */ })
                )
            )

            Spacer(modifier = Modifier.height(Spacing.large))

            // Logout button
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.medium)
            ) {
                SecondaryButton(
                    text = "退出登录",
                    onClick = { /* TODO */ }
                )
            }

            Spacer(modifier = Modifier.height(Spacing.large))
        }
    }
}

/**
 * Top bar
 */
@Composable
private fun AccountTopBar() {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color.White,
        shadowElevation = 1.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp)
                .padding(horizontal = Spacing.medium),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "我的",
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimaryLight
            )
        }
    }
}

/**
 * User profile card
 */
@Composable
private fun UserProfileCard() {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color.White
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { /* TODO: Navigate to profile */ }
                .padding(Spacing.medium),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Avatar placeholder
            Box(
                modifier = Modifier
                    .size(64.dp)
                    .background(
                        color = Primary.copy(alpha = 0.1f),
                        shape = androidx.compose.foundation.shape.CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = BrokerageIcons.Person,
                    contentDescription = null,
                    modifier = Modifier.size(32.dp),
                    tint = Primary
                )
            }

            Spacer(modifier = Modifier.width(Spacing.medium))

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = "用户名",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimaryLight
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "账户 ID: 123456789",
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
            }

            Icon(
                imageVector = BrokerageIcons.ChevronRight,
                contentDescription = null,
                tint = TextSecondaryLight,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

/**
 * Menu section with title and items
 */
@Composable
private fun MenuSection(
    title: String,
    items: List<MenuItem>
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color.White
    ) {
        Column(
            modifier = Modifier.fillMaxWidth()
        ) {
            // Section title
            Text(
                text = title,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
                color = TextSecondaryLight,
                modifier = Modifier.padding(
                    horizontal = Spacing.medium,
                    vertical = Spacing.small
                )
            )

            // Menu items
            items.forEachIndexed { index, item ->
                MenuItemRow(item = item)
                if (index < items.size - 1) {
                    HorizontalDivider(
                        color = DividerLight,
                        thickness = 1.dp,
                        modifier = Modifier.padding(start = 56.dp)
                    )
                }
            }
        }
    }
}

/**
 * Single menu item row
 */
@Composable
private fun MenuItemRow(item: MenuItem) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = item.onClick)
            .background(Color.White)
            .padding(horizontal = Spacing.medium, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = item.title,
            fontSize = 16.sp,
            color = TextPrimaryLight,
            modifier = Modifier.weight(1f)
        )
        Icon(
            imageVector = BrokerageIcons.ChevronRight,
            contentDescription = null,
            tint = TextSecondaryLight,
            modifier = Modifier.size(20.dp)
        )
    }
}

/**
 * Menu item data class
 */
data class MenuItem(
    val title: String,
    val icon: String,
    val onClick: () -> Unit
)
