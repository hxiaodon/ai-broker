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
import com.brokerage.ui.theme.*

/**
 * 设置页面
 */
@Composable
fun SettingsScreen(
    onBackClick: () -> Unit,
    onLogout: () -> Unit,
    modifier: Modifier = Modifier
) {
    var darkModeEnabled by remember { mutableStateOf(false) }
    var biometricEnabled by remember { mutableStateOf(true) }
    var notificationsEnabled by remember { mutableStateOf(true) }
    var priceAlertEnabled by remember { mutableStateOf(true) }
    var orderNotificationEnabled by remember { mutableStateOf(true) }
    var marketColorScheme by remember { mutableStateOf("绿涨红跌") }
    var language by remember { mutableStateOf("简体中文") }
    var fontSize by remember { mutableStateOf("标准") }

    var showLogoutDialog by remember { mutableStateOf(false) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BackgroundLight)
    ) {
        // 顶部导航栏
        SettingsTopBar(onBackClick = onBackClick)

        // 设置内容
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
        ) {
            // 外观设置
            SettingsSection(title = "外观") {
                SwitchSettingItem(
                    title = "深色模式",
                    subtitle = "使用深色主题",
                    checked = darkModeEnabled,
                    onCheckedChange = { darkModeEnabled = it }
                )

                HorizontalDivider(color = BorderLight)

                ClickableSettingItem(
                    title = "涨跌色",
                    value = marketColorScheme,
                    onClick = {
                        marketColorScheme = if (marketColorScheme == "绿涨红跌") "红涨绿跌" else "绿涨红跌"
                    }
                )

                HorizontalDivider(color = BorderLight)

                ClickableSettingItem(
                    title = "字体大小",
                    value = fontSize,
                    onClick = {
                        fontSize = when (fontSize) {
                            "小" -> "标准"
                            "标准" -> "大"
                            "大" -> "特大"
                            else -> "小"
                        }
                    }
                )

                HorizontalDivider(color = BorderLight)

                ClickableSettingItem(
                    title = "语言",
                    value = language,
                    onClick = { /* TODO: 语言选择 */ }
                )
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // 安全设置
            SettingsSection(title = "安全") {
                SwitchSettingItem(
                    title = "生物识别",
                    subtitle = "使用面容ID/指纹登录",
                    checked = biometricEnabled,
                    onCheckedChange = { biometricEnabled = it }
                )

                HorizontalDivider(color = BorderLight)

                ClickableSettingItem(
                    title = "修改密码",
                    onClick = { /* TODO: 修改密码 */ }
                )

                HorizontalDivider(color = BorderLight)

                ClickableSettingItem(
                    title = "交易密码",
                    onClick = { /* TODO: 交易密码 */ }
                )
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // 通知设置
            SettingsSection(title = "通知") {
                SwitchSettingItem(
                    title = "推送通知",
                    subtitle = "接收应用通知",
                    checked = notificationsEnabled,
                    onCheckedChange = { notificationsEnabled = it }
                )

                HorizontalDivider(color = BorderLight)

                SwitchSettingItem(
                    title = "价格提醒",
                    subtitle = "股票价格到达提醒",
                    checked = priceAlertEnabled,
                    onCheckedChange = { priceAlertEnabled = it },
                    enabled = notificationsEnabled
                )

                HorizontalDivider(color = BorderLight)

                SwitchSettingItem(
                    title = "订单通知",
                    subtitle = "订单状态变化通知",
                    checked = orderNotificationEnabled,
                    onCheckedChange = { orderNotificationEnabled = it },
                    enabled = notificationsEnabled
                )
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // 交易设置
            SettingsSection(title = "交易") {
                ClickableSettingItem(
                    title = "默认订单类型",
                    value = "限价单",
                    onClick = { /* TODO: 订单类型选择 */ }
                )

                HorizontalDivider(color = BorderLight)

                ClickableSettingItem(
                    title = "交易确认",
                    value = "开启",
                    onClick = { /* TODO: 交易确认设置 */ }
                )

                HorizontalDivider(color = BorderLight)

                ClickableSettingItem(
                    title = "快捷交易",
                    value = "关闭",
                    onClick = { /* TODO: 快捷交易设置 */ }
                )
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // 关于
            SettingsSection(title = "关于") {
                ClickableSettingItem(
                    title = "版本号",
                    value = "1.0.0",
                    onClick = { /* TODO: 版本信息 */ }
                )

                HorizontalDivider(color = BorderLight)

                ClickableSettingItem(
                    title = "用户协议",
                    onClick = { /* TODO: 用户协议 */ }
                )

                HorizontalDivider(color = BorderLight)

                ClickableSettingItem(
                    title = "隐私政策",
                    onClick = { /* TODO: 隐私政策 */ }
                )

                HorizontalDivider(color = BorderLight)

                ClickableSettingItem(
                    title = "检查更新",
                    onClick = { /* TODO: 检查更新 */ }
                )
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // 退出登录按钮
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.medium),
                color = Color.White,
                shape = MaterialTheme.shapes.medium
            ) {
                TextButton(
                    onClick = { showLogoutDialog = true },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp)
                ) {
                    Text(
                        text = "退出登录",
                        fontSize = 16.sp,
                        color = DangerRed,
                        fontWeight = FontWeight.Medium
                    )
                }
            }

            Spacer(modifier = Modifier.height(Spacing.large))
        }
    }

    // 退出登录确认对话框
    if (showLogoutDialog) {
        AlertDialog(
            onDismissRequest = { showLogoutDialog = false },
            title = { Text("退出登录") },
            text = { Text("确定要退出登录吗？") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showLogoutDialog = false
                        onLogout()
                    }
                ) {
                    Text("确定", color = DangerRed)
                }
            },
            dismissButton = {
                TextButton(onClick = { showLogoutDialog = false }) {
                    Text("取消")
                }
            }
        )
    }
}

@Composable
private fun SettingsTopBar(onBackClick: () -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color.White,
        shadowElevation = 1.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp)
                .padding(horizontal = Spacing.small),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBackClick) {
                Icon(
                    imageVector = BrokerageIcons.ArrowBack,
                    contentDescription = "返回",
                    modifier = Modifier.size(24.dp)
                )
            }

            Text(
                text = "设置",
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary
            )
        }
    }
}

@Composable
private fun SettingsSection(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Column {
        Text(
            text = title,
            fontSize = 14.sp,
            color = TextSecondary,
            modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small)
        )

        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = Color.White
        ) {
            Column {
                content()
            }
        }
    }
}

@Composable
private fun SwitchSettingItem(
    title: String,
    subtitle: String? = null,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    enabled: Boolean = true
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                fontSize = 16.sp,
                color = if (enabled) TextPrimary else TextSecondary
            )
            if (subtitle != null) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = subtitle,
                    fontSize = 12.sp,
                    color = TextSecondary
                )
            }
        }

        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            enabled = enabled
        )
    }
}

@Composable
private fun ClickableSettingItem(
    title: String,
    value: String? = null,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.medium),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            fontSize = 16.sp,
            color = TextPrimary,
            modifier = Modifier.weight(1f)
        )

        if (value != null) {
            Text(
                text = value,
                fontSize = 14.sp,
                color = TextSecondary
            )
            Spacer(modifier = Modifier.width(8.dp))
        }

        Text(
            text = "›",
            fontSize = 20.sp,
            color = TextSecondary
        )
    }
}
