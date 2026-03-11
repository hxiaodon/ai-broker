package com.brokerage.ui.screens.auth
import com.brokerage.ui.icons.BrokerageIcons

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.brokerage.ui.theme.*
import kotlinx.coroutines.launch

/**
 * 登录页面
 */
@Composable
fun LoginScreen(
    onLoginSuccess: () -> Unit,
    onNavigateToRegister: () -> Unit,
    onNavigateToVerificationLogin: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    var loginMethod by remember { mutableStateOf(LoginMethod.PHONE) }
    var phoneNumber by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    var rememberMe by remember { mutableStateOf(true) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

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
                contentDescription = "Logo",
                modifier = Modifier.size(64.dp),
                tint = PrimaryBlue
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "欢迎回来",
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "登录您的账户",
                fontSize = 14.sp,
                color = TextSecondary
            )
        }

        Spacer(modifier = Modifier.height(40.dp))

        // 登录方式切换
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            LoginMethodTab(
                text = "手机号",
                selected = loginMethod == LoginMethod.PHONE,
                onClick = { loginMethod = LoginMethod.PHONE },
                modifier = Modifier.weight(1f)
            )
            LoginMethodTab(
                text = "邮箱",
                selected = loginMethod == LoginMethod.EMAIL,
                onClick = { loginMethod = LoginMethod.EMAIL },
                modifier = Modifier.weight(1f)
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // 输入框
        when (loginMethod) {
            LoginMethod.PHONE -> {
                OutlinedTextField(
                    value = phoneNumber,
                    onValueChange = { phoneNumber = it },
                    label = { Text("手机号") },
                    placeholder = { Text("请输入手机号") },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Phone,
                        imeAction = ImeAction.Next
                    ),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }
            LoginMethod.EMAIL -> {
                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    label = { Text("邮箱") },
                    placeholder = { Text("请输入邮箱地址") },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Email,
                        imeAction = ImeAction.Next
                    ),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // 密码输入框
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("密码") },
            placeholder = { Text("请输入密码") },
            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Done
            ),
            keyboardActions = KeyboardActions(
                onDone = { /* TODO: 登录 */ }
            ),
            trailingIcon = {
                IconButton(onClick = { passwordVisible = !passwordVisible }) {
                    Icon(
                        imageVector = if (passwordVisible) BrokerageIcons.Visibility else BrokerageIcons.VisibilityOff,
                        contentDescription = if (passwordVisible) "隐藏密码" else "显示密码"
                    )
                }
            },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(8.dp))

        // 记住我 & 忘记密码
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.clickable { rememberMe = !rememberMe }
            ) {
                Checkbox(
                    checked = rememberMe,
                    onCheckedChange = { rememberMe = it }
                )
                Text(
                    text = "记住我",
                    fontSize = 14.sp,
                    color = TextSecondary
                )
            }

            TextButton(onClick = { /* TODO: 忘记密码 */ }) {
                Text(
                    text = "忘记密码？",
                    fontSize = 14.sp
                )
            }
        }

        // 错误提示
        if (errorMessage != null) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = errorMessage!!,
                fontSize = 12.sp,
                color = DangerRed,
                modifier = Modifier.fillMaxWidth()
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // 登录按钮
        Button(
            onClick = {
                isLoading = true
                errorMessage = null
                // TODO: 实际登录逻辑
                // 模拟登录
                scope.launch {
                    kotlinx.coroutines.delay(1500)
                    isLoading = false
                    if ((loginMethod == LoginMethod.PHONE && phoneNumber.isNotEmpty()) ||
                        (loginMethod == LoginMethod.EMAIL && email.isNotEmpty()) &&
                        password.isNotEmpty()) {
                        onLoginSuccess()
                    } else {
                        errorMessage = "请填写完整信息"
                    }
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp),
            enabled = !isLoading
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

        // 验证码登录选项
        if (onNavigateToVerificationLogin != null) {
            OutlinedButton(
                onClick = onNavigateToVerificationLogin,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("使用验证码登录")
            }
            Spacer(modifier = Modifier.height(16.dp))
        }

        // 生物识别登录
        OutlinedButton(
            onClick = { /* TODO: 生物识别 */ },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("使用面容ID/指纹登录")
        }

        Spacer(modifier = Modifier.height(24.dp))

        // 分隔线
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            HorizontalDivider(modifier = Modifier.weight(1f), color = BorderLight)
            Text(
                text = "或",
                fontSize = 12.sp,
                color = TextSecondary,
                modifier = Modifier.padding(horizontal = 16.dp)
            )
            HorizontalDivider(modifier = Modifier.weight(1f), color = BorderLight)
        }

        Spacer(modifier = Modifier.height(24.dp))

        // 第三方登录
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            ThirdPartyLoginButton(
                text = "Apple 登录",
                onClick = { /* TODO: Apple 登录 */ },
                modifier = Modifier.weight(1f)
            )
            ThirdPartyLoginButton(
                text = "微信登录",
                onClick = { /* TODO: 微信登录 */ },
                modifier = Modifier.weight(1f)
            )
        }

        Spacer(modifier = Modifier.height(32.dp))

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

        Spacer(modifier = Modifier.height(16.dp))

        // 用户协议
        Text(
            text = "登录即表示同意《用户协议》和《隐私政策》",
            fontSize = 12.sp,
            color = TextSecondary,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

@Composable
private fun LoginMethodTab(
    text: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        onClick = onClick,
        modifier = modifier,
        color = if (selected) PrimaryBlue else Color.Transparent,
        shape = MaterialTheme.shapes.medium,
        border = if (!selected) ButtonDefaults.outlinedButtonBorder else null
    ) {
        Text(
            text = text,
            fontSize = 14.sp,
            fontWeight = if (selected) FontWeight.Medium else FontWeight.Normal,
            color = if (selected) Color.White else TextPrimary,
            modifier = Modifier.padding(vertical = 12.dp),
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun ThirdPartyLoginButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    OutlinedButton(
        onClick = onClick,
        modifier = modifier
    ) {
        Text(text = text, fontSize = 14.sp)
    }
}

enum class LoginMethod {
    PHONE,
    EMAIL
}
