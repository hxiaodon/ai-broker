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
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.brokerage.ui.theme.*

/**
 * 注册页面
 */
@Composable
fun RegisterScreen(
    onRegisterSuccess: () -> Unit,
    onNavigateToLogin: () -> Unit,
    modifier: Modifier = Modifier
) {
    var currentStep by remember { mutableStateOf(1) }
    var phoneNumber by remember { mutableStateOf("") }
    var verificationCode by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    var confirmPasswordVisible by remember { mutableStateOf(false) }
    var agreeToTerms by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var countdown by remember { mutableStateOf(0) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Color.White)
    ) {
        // 顶部导航栏
        RegisterTopBar(
            currentStep = currentStep,
            totalSteps = 3,
            onBackClick = {
                if (currentStep > 1) {
                    currentStep--
                } else {
                    onNavigateToLogin()
                }
            }
        )

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(Spacing.large)
        ) {
            when (currentStep) {
                1 -> {
                    // 步骤1：手机号验证
                    PhoneVerificationStep(
                        phoneNumber = phoneNumber,
                        onPhoneNumberChange = { phoneNumber = it },
                        verificationCode = verificationCode,
                        onVerificationCodeChange = { verificationCode = it },
                        countdown = countdown,
                        onSendCode = {
                            // TODO: 发送验证码
                            countdown = 60
                        },
                        errorMessage = errorMessage
                    )
                }
                2 -> {
                    // 步骤2：设置密码
                    PasswordSetupStep(
                        email = email,
                        onEmailChange = { email = it },
                        password = password,
                        onPasswordChange = { password = it },
                        confirmPassword = confirmPassword,
                        onConfirmPasswordChange = { confirmPassword = it },
                        passwordVisible = passwordVisible,
                        onPasswordVisibilityChange = { passwordVisible = it },
                        confirmPasswordVisible = confirmPasswordVisible,
                        onConfirmPasswordVisibilityChange = { confirmPasswordVisible = it },
                        errorMessage = errorMessage
                    )
                }
                3 -> {
                    // 步骤3：同意协议
                    AgreementStep(
                        agreeToTerms = agreeToTerms,
                        onAgreeToTermsChange = { agreeToTerms = it }
                    )
                }
            }
        }

        // 底部按钮
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = Color.White,
            shadowElevation = 8.dp
        ) {
            Column(
                modifier = Modifier.padding(Spacing.medium)
            ) {
                Button(
                    onClick = {
                        when (currentStep) {
                            1 -> {
                                if (phoneNumber.isNotEmpty() && verificationCode.length == 6) {
                                    currentStep = 2
                                } else {
                                    errorMessage = "请输入手机号和验证码"
                                }
                            }
                            2 -> {
                                if (password.length >= 8 && password == confirmPassword) {
                                    currentStep = 3
                                } else {
                                    errorMessage = "密码不符合要求或两次输入不一致"
                                }
                            }
                            3 -> {
                                if (agreeToTerms) {
                                    // TODO: 提交注册
                                    onRegisterSuccess()
                                } else {
                                    errorMessage = "请阅读并同意用户协议"
                                }
                            }
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !isLoading
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            color = Color.White
                        )
                    } else {
                        Text(if (currentStep == 3) "完成注册" else "下一步")
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = "已有账户？",
                        fontSize = 14.sp,
                        color = TextSecondary
                    )
                    Text(
                        text = "立即登录",
                        fontSize = 14.sp,
                        color = PrimaryBlue,
                        fontWeight = FontWeight.Medium,
                        modifier = Modifier.clickable { onNavigateToLogin() }
                    )
                }
            }
        }
    }
}

@Composable
private fun RegisterTopBar(
    currentStep: Int,
    totalSteps: Int,
    onBackClick: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color.White,
        shadowElevation = 1.dp
    ) {
        Column {
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
                    text = "注册账户",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimary,
                    modifier = Modifier.weight(1f)
                )

                Text(
                    text = "$currentStep/$totalSteps",
                    fontSize = 14.sp,
                    color = TextSecondary
                )
            }

            // 进度条
            LinearProgressIndicator(
                progress = currentStep.toFloat() / totalSteps,
                modifier = Modifier.fillMaxWidth(),
                color = PrimaryBlue
            )
        }
    }
}

@Composable
private fun PhoneVerificationStep(
    phoneNumber: String,
    onPhoneNumberChange: (String) -> Unit,
    verificationCode: String,
    onVerificationCodeChange: (String) -> Unit,
    countdown: Int,
    onSendCode: () -> Unit,
    errorMessage: String?
) {
    Column {
        Text(
            text = "验证手机号",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "我们将发送验证码到您的手机",
            fontSize = 14.sp,
            color = TextSecondary
        )

        Spacer(modifier = Modifier.height(32.dp))

        OutlinedTextField(
            value = phoneNumber,
            onValueChange = onPhoneNumberChange,
            label = { Text("手机号") },
            placeholder = { Text("请输入手机号") },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Phone,
                imeAction = ImeAction.Next
            ),
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedTextField(
                value = verificationCode,
                onValueChange = onVerificationCodeChange,
                label = { Text("验证码") },
                placeholder = { Text("请输入6位验证码") },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Number,
                    imeAction = ImeAction.Done
                ),
                singleLine = true,
                modifier = Modifier.weight(1f)
            )

            Button(
                onClick = onSendCode,
                enabled = phoneNumber.length == 11 && countdown == 0,
                modifier = Modifier.height(56.dp)
            ) {
                Text(if (countdown > 0) "${countdown}s" else "发送")
            }
        }

        if (errorMessage != null) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = errorMessage,
                fontSize = 12.sp,
                color = DangerRed
            )
        }
    }
}

@Composable
private fun PasswordSetupStep(
    email: String,
    onEmailChange: (String) -> Unit,
    password: String,
    onPasswordChange: (String) -> Unit,
    confirmPassword: String,
    onConfirmPasswordChange: (String) -> Unit,
    passwordVisible: Boolean,
    onPasswordVisibilityChange: (Boolean) -> Unit,
    confirmPasswordVisible: Boolean,
    onConfirmPasswordVisibilityChange: (Boolean) -> Unit,
    errorMessage: String?
) {
    Column {
        Text(
            text = "设置密码",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "请设置您的登录密码",
            fontSize = 14.sp,
            color = TextSecondary
        )

        Spacer(modifier = Modifier.height(32.dp))

        OutlinedTextField(
            value = email,
            onValueChange = onEmailChange,
            label = { Text("邮箱（选填）") },
            placeholder = { Text("用于找回密码") },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Email,
                imeAction = ImeAction.Next
            ),
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        OutlinedTextField(
            value = password,
            onValueChange = onPasswordChange,
            label = { Text("密码") },
            placeholder = { Text("至少8位，包含字母和数字") },
            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Next
            ),
            trailingIcon = {
                IconButton(onClick = { onPasswordVisibilityChange(!passwordVisible) }) {
                    Icon(
                        imageVector = if (passwordVisible) BrokerageIcons.Visibility else BrokerageIcons.VisibilityOff,
                        contentDescription = if (passwordVisible) "隐藏密码" else "显示密码",
                        modifier = Modifier.size(20.dp)
                    )
                }
            },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        OutlinedTextField(
            value = confirmPassword,
            onValueChange = onConfirmPasswordChange,
            label = { Text("确认密码") },
            placeholder = { Text("请再次输入密码") },
            visualTransformation = if (confirmPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Done
            ),
            trailingIcon = {
                IconButton(onClick = { onConfirmPasswordVisibilityChange(!confirmPasswordVisible) }) {
                    Icon(
                        imageVector = if (confirmPasswordVisible) BrokerageIcons.Visibility else BrokerageIcons.VisibilityOff,
                        contentDescription = if (confirmPasswordVisible) "隐藏密码" else "显示密码",
                        modifier = Modifier.size(20.dp)
                    )
                }
            },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "• 至少8个字符\n• 包含字母和数字\n• 建议包含特殊字符",
            fontSize = 12.sp,
            color = TextSecondary,
            lineHeight = 18.sp
        )

        if (errorMessage != null) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = errorMessage,
                fontSize = 12.sp,
                color = DangerRed
            )
        }
    }
}

@Composable
private fun AgreementStep(
    agreeToTerms: Boolean,
    onAgreeToTermsChange: (Boolean) -> Unit
) {
    Column {
        Text(
            text = "服务协议",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "请阅读并同意以下协议",
            fontSize = 14.sp,
            color = TextSecondary
        )

        Spacer(modifier = Modifier.height(32.dp))

        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .height(300.dp),
            color = BackgroundLight,
            shape = MaterialTheme.shapes.medium
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(Spacing.medium)
            ) {
                Text(
                    text = "用户服务协议",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = """
                        欢迎使用本券商交易平台。在使用本平台服务前，请您仔细阅读并充分理解本协议的全部内容。

                        1. 服务说明
                        本平台为用户提供证券交易服务，包括但不限于股票买卖、行情查询、资产管理等功能。

                        2. 用户责任
                        - 您应确保注册信息真实、准确、完整
                        - 您应妥善保管账户密码，对账户下的所有行为负责
                        - 您应遵守相关法律法规，不得从事违法违规交易

                        3. 风险提示
                        - 证券投资存在风险，您应充分了解并承担投资风险
                        - 市场价格波动可能导致本金损失
                        - 过往业绩不代表未来表现

                        4. 隐私保护
                        我们将严格保护您的个人信息，不会未经授权向第三方披露。

                        5. 免责声明
                        - 因不可抗力导致的服务中断，本平台不承担责任
                        - 因用户自身原因导致的损失，本平台不承担责任

                        6. 协议变更
                        本平台有权根据需要修改本协议，修改后的协议将在平台公布。

                        如您对本协议有任何疑问，请联系客服。
                    """.trimIndent(),
                    fontSize = 12.sp,
                    color = TextSecondary,
                    lineHeight = 18.sp
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { onAgreeToTermsChange(!agreeToTerms) }
                .padding(vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Checkbox(
                checked = agreeToTerms,
                onCheckedChange = onAgreeToTermsChange
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "我已阅读并同意",
                fontSize = 14.sp,
                color = TextSecondary
            )
            Text(
                text = "《用户服务协议》",
                fontSize = 14.sp,
                color = PrimaryBlue,
                fontWeight = FontWeight.Medium
            )
            Text(
                text = "和",
                fontSize = 14.sp,
                color = TextSecondary
            )
            Text(
                text = "《隐私政策》",
                fontSize = 14.sp,
                color = PrimaryBlue,
                fontWeight = FontWeight.Medium
            )
        }
    }
}
