package com.brokerage.ui.screens.auth
import com.brokerage.ui.icons.BrokerageIcons

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.brokerage.ui.theme.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * 手机验证码登录页面
 */
@Composable
fun PhoneVerificationLoginScreen(
    onLoginSuccess: () -> Unit,
    onNavigateToPasswordLogin: () -> Unit,
    onNavigateToRegister: () -> Unit,
    modifier: Modifier = Modifier
) {
    var phoneNumber by remember { mutableStateOf("") }
    var verificationCode by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var countdown by remember { mutableStateOf(0) }
    var codeSent by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    // 倒计时逻辑
    LaunchedEffect(countdown) {
        if (countdown > 0) {
            delay(1000)
            countdown--
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Color.White)
            .verticalScroll(rememberScrollState())
            .padding(Spacing.large)
    ) {
        Spacer(modifier = Modifier.height(40.dp))

        // Logo 和标题
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = BrokerageIcons.TrendingUp,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = PrimaryBlue
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "验证码登录",
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "输入手机号获取验证码",
                fontSize = 14.sp,
                color = TextSecondary
            )
        }

        Spacer(modifier = Modifier.height(40.dp))

        // 手机号输入
        OutlinedTextField(
            value = phoneNumber,
            onValueChange = {
                if (it.length <= 11) {
                    phoneNumber = it.filter { char -> char.isDigit() }
                    errorMessage = null
                }
            },
            label = { Text("手机号") },
            placeholder = { Text("请输入11位手机号") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            isError = errorMessage != null
        )

        Spacer(modifier = Modifier.height(16.dp))

        // 验证码输入和发送按钮
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedTextField(
                value = verificationCode,
                onValueChange = {
                    if (it.length <= 6) {
                        verificationCode = it.filter { char -> char.isDigit() }
                        errorMessage = null
                    }
                },
                label = { Text("验证码") },
                placeholder = { Text("请输入6位验证码") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true,
                modifier = Modifier.weight(1f),
                isError = errorMessage != null
            )

            Button(
                onClick = {
                    if (phoneNumber.length == 11) {
                        scope.launch {
                            // 模拟发送验证码
                            countdown = 60
                            codeSent = true
                            // TODO: 调用实际的发送验证码 API
                        }
                    } else {
                        errorMessage = "请输入正确的手机号"
                    }
                },
                enabled = phoneNumber.length == 11 && countdown == 0,
                modifier = Modifier
                    .height(56.dp)
                    .widthIn(min = 100.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (countdown > 0) Color.Gray else PrimaryBlue
                )
            ) {
                Text(
                    text = if (countdown > 0) "${countdown}s" else if (codeSent) "重新发送" else "获取验证码",
                    fontSize = 14.sp
                )
            }
        }

        // 错误提示
        if (errorMessage != null) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = errorMessage!!,
                color = DangerRed,
                fontSize = 12.sp
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // 登录按钮
        Button(
            onClick = {
                when {
                    phoneNumber.length != 11 -> {
                        errorMessage = "请输入正确的手机号"
                    }
                    verificationCode.length != 6 -> {
                        errorMessage = "请输入6位验证码"
                    }
                    else -> {
                        scope.launch {
                            isLoading = true
                            errorMessage = null

                            // 模拟验证码验证
                            delay(1000)

                            // TODO: 调用实际的验证码登录 API
                            // 这里简单模拟：验证码为 123456 时登录成功
                            if (verificationCode == "123456") {
                                onLoginSuccess()
                            } else {
                                errorMessage = "验证码错误，请重新输入"
                            }

                            isLoading = false
                        }
                    }
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp),
            enabled = !isLoading && phoneNumber.length == 11 && verificationCode.length == 6,
            colors = ButtonDefaults.buttonColors(containerColor = PrimaryBlue)
        ) {
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(24.dp),
                    color = Color.White
                )
            } else {
                Text("登录", fontSize = 16.sp)
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // 切换到密码登录
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center
        ) {
            Text(
                text = "使用密码登录",
                fontSize = 14.sp,
                color = PrimaryBlue,
                modifier = Modifier.clickable { onNavigateToPasswordLogin() }
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // 注册提示
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center
        ) {
            Text(
                text = "还没有账户？",
                fontSize = 14.sp,
                color = TextSecondary
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = "立即注册",
                fontSize = 14.sp,
                color = PrimaryBlue,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.clickable { onNavigateToRegister() }
            )
        }

        Spacer(modifier = Modifier.height(32.dp))

        // 用户协议
        Text(
            text = "登录即表示您同意我们的服务条款和隐私政策",
            fontSize = 12.sp,
            color = TextSecondary,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
    }
}
