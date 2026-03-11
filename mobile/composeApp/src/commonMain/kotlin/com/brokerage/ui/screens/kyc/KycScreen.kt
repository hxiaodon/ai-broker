package com.brokerage.ui.screens.kyc
import com.brokerage.ui.icons.BrokerageIcons

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.brokerage.ui.theme.*

/**
 * KYC 身份认证流程 (完整 7 步)
 * Based on mobile-app-design-v2.md requirements
 *
 * Steps:
 * 1. 个人信息 (Personal Information)
 * 2. 身份证件上传 (ID Document Upload)
 * 3. 人脸识别 (Face Verification)
 * 4. 地址证明上传 (Address Proof Upload) - NEW
 * 5. 投资者评估 (Investor Assessment)
 * 6. 风险披露 (Risk Disclosure)
 * 7. 协议签署 (Agreement Signing) - NEW
 */
@Composable
fun KycScreen(
    onKycComplete: () -> Unit,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    var currentStep by remember { mutableStateOf(1) }
    var isLoading by remember { mutableStateOf(false) }

    // 步骤1：个人信息
    var fullName by remember { mutableStateOf("") }
    var idNumber by remember { mutableStateOf("") }
    var dateOfBirth by remember { mutableStateOf("") }
    var nationality by remember { mutableStateOf("中国") }
    var address by remember { mutableStateOf("") }

    // 步骤2：身份证件
    var idCardFrontUploaded by remember { mutableStateOf(false) }
    var idCardBackUploaded by remember { mutableStateOf(false) }

    // 步骤3：人脸识别
    var faceVerified by remember { mutableStateOf(false) }

    // 步骤4：地址证明 (NEW)
    var addressProofUploaded by remember { mutableStateOf(false) }
    var addressProofType by remember { mutableStateOf("") }

    // 步骤5：投资者评估
    var investmentExperience by remember { mutableStateOf("") }
    var riskTolerance by remember { mutableStateOf("") }
    var annualIncome by remember { mutableStateOf("") }
    var investmentGoal by remember { mutableStateOf("") }

    // 步骤6：风险披露
    var riskDisclosureAgreed by remember { mutableStateOf(false) }

    // 步骤7：协议签署 (NEW)
    var customerAgreementSigned by remember { mutableStateOf(false) }
    var marginAgreementSigned by remember { mutableStateOf(false) }
    var privacyPolicySigned by remember { mutableStateOf(false) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BackgroundLight)
    ) {
        // 顶部进度条
        KycTopBar(
            currentStep = currentStep,
            totalSteps = 7,
            onBackClick = {
                if (currentStep > 1) {
                    currentStep--
                } else {
                    onBackClick()
                }
            }
        )

        // 内容区域
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(Spacing.medium)
        ) {
            when (currentStep) {
                1 -> PersonalInfoStep(
                    fullName = fullName,
                    onFullNameChange = { fullName = it },
                    idNumber = idNumber,
                    onIdNumberChange = { idNumber = it },
                    dateOfBirth = dateOfBirth,
                    onDateOfBirthChange = { dateOfBirth = it },
                    nationality = nationality,
                    onNationalityChange = { nationality = it },
                    address = address,
                    onAddressChange = { address = it }
                )
                2 -> IdCardUploadStep(
                    frontUploaded = idCardFrontUploaded,
                    backUploaded = idCardBackUploaded,
                    onUploadFront = { idCardFrontUploaded = true },
                    onUploadBack = { idCardBackUploaded = true }
                )
                3 -> FaceVerificationStep(
                    verified = faceVerified,
                    onStartVerification = { faceVerified = true }
                )
                4 -> AddressProofUploadStep(
                    uploaded = addressProofUploaded,
                    proofType = addressProofType,
                    onProofTypeChange = { addressProofType = it },
                    onUpload = { addressProofUploaded = true }
                )
                5 -> InvestorAssessmentStep(
                    investmentExperience = investmentExperience,
                    onInvestmentExperienceChange = { investmentExperience = it },
                    riskTolerance = riskTolerance,
                    onRiskToleranceChange = { riskTolerance = it },
                    annualIncome = annualIncome,
                    onAnnualIncomeChange = { annualIncome = it },
                    investmentGoal = investmentGoal,
                    onInvestmentGoalChange = { investmentGoal = it }
                )
                6 -> RiskDisclosureStep(
                    agreed = riskDisclosureAgreed,
                    onAgreeChange = { riskDisclosureAgreed = it }
                )
                7 -> AgreementSigningStep(
                    customerAgreementSigned = customerAgreementSigned,
                    onCustomerAgreementChange = { customerAgreementSigned = it },
                    marginAgreementSigned = marginAgreementSigned,
                    onMarginAgreementChange = { marginAgreementSigned = it },
                    privacyPolicySigned = privacyPolicySigned,
                    onPrivacyPolicyChange = { privacyPolicySigned = it }
                )
            }
        }

        // 底部按钮
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = Color.White,
            shadowElevation = 8.dp
        ) {
            Button(
                onClick = {
                    when (currentStep) {
                        1 -> {
                            if (fullName.isNotEmpty() && idNumber.isNotEmpty()) {
                                currentStep = 2
                            }
                        }
                        2 -> {
                            if (idCardFrontUploaded && idCardBackUploaded) {
                                currentStep = 3
                            }
                        }
                        3 -> {
                            if (faceVerified) {
                                currentStep = 4
                            }
                        }
                        4 -> {
                            if (addressProofUploaded && addressProofType.isNotEmpty()) {
                                currentStep = 5
                            }
                        }
                        5 -> {
                            if (investmentExperience.isNotEmpty() && riskTolerance.isNotEmpty()) {
                                currentStep = 6
                            }
                        }
                        6 -> {
                            if (riskDisclosureAgreed) {
                                currentStep = 7
                            }
                        }
                        7 -> {
                            if (customerAgreementSigned && marginAgreementSigned && privacyPolicySigned) {
                                onKycComplete()
                            }
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(Spacing.medium),
                enabled = !isLoading
            ) {
                Text(
                    text = if (currentStep == 7) "完成认证" else "下一步",
                    fontSize = 16.sp
                )
            }
        }
    }
}

@Composable
private fun KycTopBar(
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
                        contentDescription = "返回"
                    )
                }

                Text(
                    text = "身份认证",
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

/**
 * 步骤1：个人信息
 */
@Composable
private fun PersonalInfoStep(
    fullName: String,
    onFullNameChange: (String) -> Unit,
    idNumber: String,
    onIdNumberChange: (String) -> Unit,
    dateOfBirth: String,
    onDateOfBirthChange: (String) -> Unit,
    nationality: String,
    onNationalityChange: (String) -> Unit,
    address: String,
    onAddressChange: (String) -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(
            text = "个人信息",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "请如实填写您的个人信息",
            fontSize = 14.sp,
            color = TextSecondary
        )

        Spacer(modifier = Modifier.height(24.dp))

        OutlinedTextField(
            value = fullName,
            onValueChange = onFullNameChange,
            label = { Text("姓名") },
            placeholder = { Text("请输入真实姓名") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        OutlinedTextField(
            value = idNumber,
            onValueChange = onIdNumberChange,
            label = { Text("身份证号") },
            placeholder = { Text("请输入身份证号码") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        OutlinedTextField(
            value = dateOfBirth,
            onValueChange = onDateOfBirthChange,
            label = { Text("出生日期") },
            placeholder = { Text("YYYY-MM-DD") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        OutlinedTextField(
            value = nationality,
            onValueChange = onNationalityChange,
            label = { Text("国籍") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        OutlinedTextField(
            value = address,
            onValueChange = onAddressChange,
            label = { Text("居住地址") },
            placeholder = { Text("请输入详细地址") },
            minLines = 2,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

/**
 * 步骤2：身份证件上传
 */
@Composable
private fun IdCardUploadStep(
    frontUploaded: Boolean,
    backUploaded: Boolean,
    onUploadFront: () -> Unit,
    onUploadBack: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(
            text = "上传身份证件",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "请上传清晰的身份证正反面照片",
            fontSize = 14.sp,
            color = TextSecondary
        )

        Spacer(modifier = Modifier.height(24.dp))

        // 身份证正面
        UploadCard(
            title = "身份证正面",
            uploaded = frontUploaded,
            onUpload = onUploadFront
        )

        Spacer(modifier = Modifier.height(16.dp))

        // 身份证反面
        UploadCard(
            title = "身份证反面",
            uploaded = backUploaded,
            onUpload = onUploadBack
        )

        Spacer(modifier = Modifier.height(24.dp))

        // 提示信息
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = InfoBlue.copy(alpha = 0.1f),
            shape = MaterialTheme.shapes.small
        ) {
            Column(
                modifier = Modifier.padding(Spacing.medium)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = BrokerageIcons.PhotoCamera,
                        contentDescription = null,
                        tint = InfoBlue,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "拍摄提示",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = InfoBlue
                    )
                }
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "• 确保证件边框完整\n• 照片清晰，无反光\n• 信息完整可见",
                    fontSize = 12.sp,
                    color = TextSecondary,
                    lineHeight = 20.sp
                )
            }
        }
    }
}

@Composable
private fun UploadCard(
    title: String,
    uploaded: Boolean,
    onUpload: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color.White,
        shape = MaterialTheme.shapes.medium,
        tonalElevation = 1.dp
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = title,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary
            )

            Spacer(modifier = Modifier.height(16.dp))

            if (uploaded) {
                Icon(
                    imageVector = BrokerageIcons.CheckCircle,
                    contentDescription = "已上传",
                    tint = SuccessGreen,
                    modifier = Modifier.size(48.dp)
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "已上传",
                    fontSize = 14.sp,
                    color = SuccessGreen
                )
            } else {
                Icon(
                    imageVector = BrokerageIcons.PhotoCamera,
                    contentDescription = "上传照片",
                    tint = TextSecondary,
                    modifier = Modifier.size(48.dp)
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(
                    onClick = onUpload,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("上传照片")
                }
            }
        }
    }
}

/**
 * 步骤3：人脸识别
 */
@Composable
private fun FaceVerificationStep(
    verified: Boolean,
    onStartVerification: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "人脸识别",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "请进行人脸识别验证",
            fontSize = 14.sp,
            color = TextSecondary
        )

        Spacer(modifier = Modifier.height(40.dp))

        if (verified) {
            Icon(
                imageVector = BrokerageIcons.CheckCircle,
                contentDescription = "验证成功",
                tint = SuccessGreen,
                modifier = Modifier.size(80.dp)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "验证成功",
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                color = SuccessGreen
            )
        } else {
            Icon(
                imageVector = BrokerageIcons.Person,
                contentDescription = "人脸识别",
                tint = TextSecondary,
                modifier = Modifier.size(80.dp)
            )
            Spacer(modifier = Modifier.height(24.dp))
            Button(
                onClick = onStartVerification,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("开始人脸识别")
            }

            Spacer(modifier = Modifier.height(24.dp))

            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = InfoBlue.copy(alpha = 0.1f),
                shape = MaterialTheme.shapes.small
            ) {
                Column(
                    modifier = Modifier.padding(Spacing.medium)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = BrokerageIcons.Info,
                            contentDescription = null,
                            tint = InfoBlue,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "识别提示",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = InfoBlue
                        )
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "• 保持光线充足\n• 正对摄像头\n• 按照提示完成动作",
                        fontSize = 12.sp,
                        color = TextSecondary,
                        lineHeight = 20.sp
                    )
                }
            }
        }
    }
}

/**
 * 步骤4：投资者评估
 */
@Composable
private fun InvestorAssessmentStep(
    investmentExperience: String,
    onInvestmentExperienceChange: (String) -> Unit,
    riskTolerance: String,
    onRiskToleranceChange: (String) -> Unit,
    annualIncome: String,
    onAnnualIncomeChange: (String) -> Unit,
    investmentGoal: String,
    onInvestmentGoalChange: (String) -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(
            text = "投资者评估",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "请如实填写以下信息",
            fontSize = 14.sp,
            color = TextSecondary
        )

        Spacer(modifier = Modifier.height(24.dp))

        // 投资经验
        Text(
            text = "投资经验",
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
            color = TextPrimary
        )
        Spacer(modifier = Modifier.height(8.dp))
        listOf("无经验", "1年以下", "1-3年", "3-5年", "5年以上").forEach { option ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                RadioButton(
                    selected = investmentExperience == option,
                    onClick = { onInvestmentExperienceChange(option) }
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(text = option, fontSize = 14.sp)
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // 风险承受能力
        Text(
            text = "风险承受能力",
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
            color = TextPrimary
        )
        Spacer(modifier = Modifier.height(8.dp))
        listOf("保守型", "稳健型", "平衡型", "成长型", "进取型").forEach { option ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                RadioButton(
                    selected = riskTolerance == option,
                    onClick = { onRiskToleranceChange(option) }
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(text = option, fontSize = 14.sp)
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // 年收入
        Text(
            text = "年收入",
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
            color = TextPrimary
        )
        Spacer(modifier = Modifier.height(8.dp))
        listOf("10万以下", "10-30万", "30-50万", "50-100万", "100万以上").forEach { option ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                RadioButton(
                    selected = annualIncome == option,
                    onClick = { onAnnualIncomeChange(option) }
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(text = option, fontSize = 14.sp)
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // 投资目标
        Text(
            text = "投资目标",
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
            color = TextPrimary
        )
        Spacer(modifier = Modifier.height(8.dp))
        listOf("资产保值", "稳健增值", "长期增长", "短期收益", "投机交易").forEach { option ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                RadioButton(
                    selected = investmentGoal == option,
                    onClick = { onInvestmentGoalChange(option) }
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(text = option, fontSize = 14.sp)
            }
        }
    }
}

/**
 * 步骤5：风险披露
 */
@Composable
private fun RiskDisclosureStep(
    agreed: Boolean,
    onAgreeChange: (Boolean) -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(
            text = "风险披露",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "请仔细阅读以下风险披露声明",
            fontSize = 14.sp,
            color = TextSecondary
        )

        Spacer(modifier = Modifier.height(24.dp))

        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .height(300.dp),
            color = Color.White,
            shape = MaterialTheme.shapes.medium,
            tonalElevation = 1.dp
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(Spacing.medium)
            ) {
                Text(
                    text = "证券投资风险披露声明",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = """
                        尊敬的投资者：

                        证券投资具有一定的风险，为了使您更好地了解其中的风险，根据有关法律、法规和规章的规定，特向您提供本风险披露声明书，请您认真详细阅读。

                        一、市场风险
                        证券市场受政治、经济、投资心理和交易制度等各种因素的影响，导致证券价格波动，使您存在亏损的可能，您将不得不承担由此造成的损失。

                        二、政策风险
                        因国家法律、法规、政策、证券交易规则等的变化，可能引起证券市场价格波动，使您存在亏损的可能，您将不得不承担由此造成的损失。

                        三、上市公司经营风险
                        由于上市公司所处行业整体经营形势的变化；上市公司经营管理等方面的因素，如经营决策重大失误、高级管理人员变更、重大诉讼等都可能引起该公司证券价格的波动；由于上市公司经营不善甚至会导致该公司被停牌、摘牌，使您所持有的证券贬值或变为废纸，您将不得不承担由此造成的损失。

                        四、技术风险
                        由于交易撮合、清算交收、行情揭示及银证转账是通过电子通讯技术和电脑技术来实现的，这些技术存在着被网络黑客和计算机病毒攻击的可能，或者通讯技术、电脑技术和相关软件存在缺陷，这些风险可能给您带来损失或者使您的正常交易无法进行。

                        五、不可抗力风险
                        诸如地震、火灾、水灾等自然灾害或战争、瘟疫、社会动乱等不可抗力因素可能导致证券交易系统的瘫痪；证券营业部无法控制和不可预测的系统故障、设备故障、通讯故障、电力故障等也可能导致证券交易系统非正常运行甚至瘫痪；这些都会使您的正常交易无法进行，您将不得不承担由此造成的损失。

                        本风险披露声明书的披露事项仅为列举性质，未能详尽列明证券投资的所有风险。您在参与证券交易前，应认真阅读相关业务规则及协议条款，对其他可能存在的风险因素也应有所了解和掌握，并确信自己已做好足够的风险评估与财务安排，避免因参与证券交易而遭受难以承受的损失。
                    """.trimIndent(),
                    fontSize = 12.sp,
                    color = TextSecondary,
                    lineHeight = 20.sp
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Checkbox(
                checked = agreed,
                onCheckedChange = onAgreeChange
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "我已阅读并理解上述风险披露声明",
                fontSize = 14.sp,
                color = TextPrimary
            )
        }
    }
}

/**
 * Step 4: Address Proof Upload (NEW)
 */
@Composable
private fun AddressProofUploadStep(
    uploaded: Boolean,
    proofType: String,
    onProofTypeChange: (String) -> Unit,
    onUpload: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(Spacing.medium)
    ) {
        Text(
            text = "地址证明上传",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )
        
        Text(
            text = "请上传近3个月内的地址证明文件",
            fontSize = 14.sp,
            color = TextSecondary
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Proof type selection
        Text(
            text = "证明类型",
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            color = TextPrimary
        )
        
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf("水电费账单", "银行对账单", "信用卡账单", "政府信函").forEach { type ->
                OutlinedButton(
                    onClick = { onProofTypeChange(type) },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.outlinedButtonColors(
                        containerColor = if (proofType == type) Primary.copy(alpha = 0.1f) else Color.Transparent
                    )
                ) {
                    Text(type)
                }
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Upload button
        if (!uploaded) {
            Button(
                onClick = onUpload,
                modifier = Modifier.fillMaxWidth(),
                enabled = proofType.isNotEmpty()
            ) {
                Text("上传文件")
            }
        } else {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Success.copy(alpha = 0.1f))
            ) {
                Row(
                    modifier = Modifier.padding(Spacing.medium),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("✓", fontSize = 24.sp, color = Success)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("地址证明已上传", color = Success)
                }
            }
        }
    }
}

/**
 * Step 7: Agreement Signing (NEW)
 */
@Composable
private fun AgreementSigningStep(
    customerAgreementSigned: Boolean,
    onCustomerAgreementChange: (Boolean) -> Unit,
    marginAgreementSigned: Boolean,
    onMarginAgreementChange: (Boolean) -> Unit,
    privacyPolicySigned: Boolean,
    onPrivacyPolicyChange: (Boolean) -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(Spacing.medium)
    ) {
        Text(
            text = "协议签署",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )
        
        Text(
            text = "请仔细阅读并签署以下协议",
            fontSize = 14.sp,
            color = TextSecondary
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Customer Agreement
        AgreementCard(
            title = "客户协议",
            description = "规定您与本公司之间的权利义务关系",
            signed = customerAgreementSigned,
            onSignedChange = onCustomerAgreementChange
        )

        // Margin Agreement
        AgreementCard(
            title = "融资融券协议",
            description = "如需使用保证金交易，必须签署此协议",
            signed = marginAgreementSigned,
            onSignedChange = onMarginAgreementChange
        )

        // Privacy Policy
        AgreementCard(
            title = "隐私政策",
            description = "说明我们如何收集、使用和保护您的个人信息",
            signed = privacyPolicySigned,
            onSignedChange = onPrivacyPolicyChange
        )

        Spacer(modifier = Modifier.height(8.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = Info.copy(alpha = 0.1f))
        ) {
            Row(
                modifier = Modifier.padding(Spacing.medium),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = BrokerageIcons.Info,
                    contentDescription = null,
                    tint = Info,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = "提示：所有协议均需签署才能完成开户",
                    fontSize = 12.sp,
                    color = Info
                )
            }
        }
    }
}

@Composable
private fun AgreementCard(
    title: String,
    description: String,
    signed: Boolean,
    onSignedChange: (Boolean) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (signed) Success.copy(alpha = 0.05f) else Color.White
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = title,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = TextPrimary
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = description,
                        fontSize = 12.sp,
                        color = TextSecondary
                    )
                }
                TextButton(onClick = { /* TODO: Show agreement */ }) {
                    Text("查看 >")
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Checkbox(
                    checked = signed,
                    onCheckedChange = onSignedChange
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "我已阅读并同意《$title》",
                    fontSize = 14.sp,
                    color = TextPrimary
                )
            }
        }
    }
}
