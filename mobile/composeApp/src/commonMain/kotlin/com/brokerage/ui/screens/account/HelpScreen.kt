package com.brokerage.ui.screens.account
import com.brokerage.ui.icons.BrokerageIcons

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
 * 帮助中心页面
 */
@Composable
fun HelpScreen(
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedCategory by remember { mutableStateOf<HelpCategory?>(null) }
    var selectedQuestion by remember { mutableStateOf<HelpQuestion?>(null) }

    when {
        selectedQuestion != null -> {
            // 显示问题详情
            QuestionDetailView(
                question = selectedQuestion!!,
                onBackClick = { selectedQuestion = null }
            )
        }
        selectedCategory != null -> {
            // 显示分类下的问题列表
            CategoryQuestionsView(
                category = selectedCategory!!,
                onBackClick = { selectedCategory = null },
                onQuestionClick = { selectedQuestion = it }
            )
        }
        else -> {
            // 显示分类列表
            HelpCategoriesView(
                onBackClick = onBackClick,
                onCategoryClick = { selectedCategory = it }
            )
        }
    }
}

/**
 * 帮助分类列表
 */
@Composable
private fun HelpCategoriesView(
    onBackClick: () -> Unit,
    onCategoryClick: (HelpCategory) -> Unit
) {
    val categories = remember {
        listOf(
            HelpCategory("account", "账户相关", "🔐", 8),
            HelpCategory("trading", "交易相关", "📈", 12),
            HelpCategory("funding", "出入金", "💰", 6),
            HelpCategory("market", "行情数据", "📊", 5),
            HelpCategory("kyc", "身份认证", "🆔", 4),
            HelpCategory("security", "安全问题", "🔒", 7),
            HelpCategory("fees", "费用说明", "💵", 3),
            HelpCategory("other", "其他问题", "❓", 10)
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundLight)
    ) {
        // 顶部导航栏
        HelpTopBar(
            title = "帮助中心",
            onBackClick = onBackClick
        )

        // 搜索框
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium),
            color = Color.White,
            shape = MaterialTheme.shapes.medium
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { /* TODO: 搜索功能 */ }
                    .padding(Spacing.medium),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(BrokerageIcons.Search, contentDescription = "搜索", modifier = Modifier.size(20.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "搜索问题...",
                    fontSize = 14.sp,
                    color = TextSecondary
                )
            }
        }

        // 分类列表
        LazyColumn(
            modifier = Modifier.weight(1f),
            contentPadding = PaddingValues(Spacing.medium),
            verticalArrangement = Arrangement.spacedBy(Spacing.small)
        ) {
            items(categories) { category ->
                CategoryCard(
                    category = category,
                    onClick = { onCategoryClick(category) }
                )
            }
        }

        // 底部联系客服
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = Color.White,
            shadowElevation = 8.dp
        ) {
            Column(
                modifier = Modifier.padding(Spacing.medium)
            ) {
                Text(
                    text = "没有找到答案？",
                    fontSize = 14.sp,
                    color = TextSecondary
                )
                Spacer(modifier = Modifier.height(8.dp))
                Button(
                    onClick = { /* TODO: 联系客服 */ },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("联系客服")
                }
            }
        }
    }
}

/**
 * 分类下的问题列表
 */
@Composable
private fun CategoryQuestionsView(
    category: HelpCategory,
    onBackClick: () -> Unit,
    onQuestionClick: (HelpQuestion) -> Unit
) {
    val questions = remember(category.id) {
        getQuestionsForCategory(category.id)
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundLight)
    ) {
        HelpTopBar(
            title = category.name,
            onBackClick = onBackClick
        )

        LazyColumn(
            contentPadding = PaddingValues(Spacing.medium),
            verticalArrangement = Arrangement.spacedBy(Spacing.small)
        ) {
            items(questions) { question ->
                QuestionCard(
                    question = question,
                    onClick = { onQuestionClick(question) }
                )
            }
        }
    }
}

/**
 * 问题详情
 */
@Composable
private fun QuestionDetailView(
    question: HelpQuestion,
    onBackClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundLight)
    ) {
        HelpTopBar(
            title = "问题详情",
            onBackClick = onBackClick
        )

        LazyColumn(
            contentPadding = PaddingValues(Spacing.medium)
        ) {
            item {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = Color.White,
                    shape = MaterialTheme.shapes.medium
                ) {
                    Column(
                        modifier = Modifier.padding(Spacing.medium)
                    ) {
                        // 问题标题
                        Text(
                            text = question.title,
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )

                        Spacer(modifier = Modifier.height(Spacing.medium))

                        HorizontalDivider(color = BorderLight)

                        Spacer(modifier = Modifier.height(Spacing.medium))

                        // 问题答案
                        Text(
                            text = question.answer,
                            fontSize = 14.sp,
                            color = TextPrimary,
                            lineHeight = 22.sp
                        )
                    }
                }
            }

            item {
                Spacer(modifier = Modifier.height(Spacing.medium))
            }

            // 相关问题
            item {
                Text(
                    text = "相关问题",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimary
                )
                Spacer(modifier = Modifier.height(8.dp))
            }

            items(question.relatedQuestions) { related ->
                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { /* TODO: 跳转到相关问题 */ },
                    color = Color.White,
                    shape = MaterialTheme.shapes.small
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(Spacing.medium),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = related,
                            fontSize = 14.sp,
                            color = InfoBlue,
                            modifier = Modifier.weight(1f)
                        )
                        Icon(
                            imageVector = BrokerageIcons.ChevronRight,
                            contentDescription = null,
                            tint = TextSecondary,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
            }

            item {
                Spacer(modifier = Modifier.height(Spacing.medium))
            }

            // 反馈
            item {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = Color.White,
                    shape = MaterialTheme.shapes.medium
                ) {
                    Column(
                        modifier = Modifier.padding(Spacing.medium),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "这个答案有帮助吗？",
                            fontSize = 14.sp,
                            color = TextSecondary
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(Spacing.medium)
                        ) {
                            OutlinedButton(
                                onClick = { /* TODO: 有帮助 */ }
                            ) {
                                Text("👍 有帮助")
                            }
                            OutlinedButton(
                                onClick = { /* TODO: 没帮助 */ }
                            ) {
                                Text("👎 没帮助")
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun HelpTopBar(
    title: String,
    onBackClick: () -> Unit
) {
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
                Icon(BrokerageIcons.ArrowBack, contentDescription = "返回", modifier = Modifier.size(24.dp))
            }

            Text(
                text = title,
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary
            )
        }
    }
}

@Composable
private fun CategoryCard(
    category: HelpCategory,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        color = Color.White,
        shape = MaterialTheme.shapes.medium
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(text = category.icon, fontSize = 32.sp)

            Spacer(modifier = Modifier.width(Spacing.medium))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = category.name,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimary
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "${category.questionCount} 个问题",
                    fontSize = 12.sp,
                    color = TextSecondary
                )
            }

            Icon(
                imageVector = BrokerageIcons.ChevronRight,
                contentDescription = null,
                tint = TextSecondary,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
private fun QuestionCard(
    question: HelpQuestion,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        color = Color.White,
        shape = MaterialTheme.shapes.medium
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = question.title,
                fontSize = 14.sp,
                color = TextPrimary,
                modifier = Modifier.weight(1f)
            )
            Icon(
                imageVector = BrokerageIcons.ChevronRight,
                contentDescription = null,
                tint = TextSecondary,
                modifier = Modifier.size(16.dp)
            )
        }
    }
}

// 数据模型
data class HelpCategory(
    val id: String,
    val name: String,
    val icon: String,
    val questionCount: Int
)

data class HelpQuestion(
    val id: String,
    val title: String,
    val answer: String,
    val relatedQuestions: List<String>
)

// Mock 数据
private fun getQuestionsForCategory(categoryId: String): List<HelpQuestion> {
    return when (categoryId) {
        "account" -> listOf(
            HelpQuestion(
                id = "1",
                title = "如何注册账户？",
                answer = "1. 下载并打开APP\n2. 点击\"注册\"按钮\n3. 输入手机号并获取验证码\n4. 设置登录密码\n5. 完成身份认证（KYC）\n6. 等待审核通过\n\n注册过程通常需要1-2个工作日完成审核。",
                relatedQuestions = listOf("身份认证需要哪些材料？", "如何修改登录密码？")
            ),
            HelpQuestion(
                id = "2",
                title = "忘记密码怎么办？",
                answer = "1. 在登录页面点击\"忘记密码\"\n2. 输入注册手机号\n3. 获取验证码\n4. 设置新密码\n5. 完成密码重置\n\n如果手机号已更换，请联系客服处理。",
                relatedQuestions = listOf("如何修改手机号？", "如何设置交易密码？")
            ),
            HelpQuestion(
                id = "3",
                title = "如何注销账户？",
                answer = "账户注销需要满足以下条件：\n1. 账户余额为0\n2. 无持仓\n3. 无未完成订单\n4. 无未结算资金\n\n满足条件后，请联系客服申请注销。注销后数据将无法恢复。",
                relatedQuestions = listOf("如何清空持仓？", "如何提取全部资金？")
            )
        )
        "trading" -> listOf(
            HelpQuestion(
                id = "4",
                title = "如何买入股票？",
                answer = "1. 在行情页面搜索股票\n2. 点击进入股票详情页\n3. 点击\"买入\"按钮\n4. 选择订单类型（市价单/限价单）\n5. 输入买入数量\n6. 确认订单信息\n7. 输入交易密码\n8. 提交订单\n\n市价单会立即以市场价格成交，限价单会在价格达到设定值时成交。",
                relatedQuestions = listOf("什么是市价单？", "什么是限价单？", "如何撤销订单？")
            ),
            HelpQuestion(
                id = "5",
                title = "交易时间是什么时候？",
                answer = "美股交易时间（北京时间）：\n夏令时：21:30 - 04:00\n冬令时：22:30 - 05:00\n\n港股交易时间：\n上午：09:30 - 12:00\n下午：13:00 - 16:00\n\n盘前盘后交易时间请参考具体市场规则。",
                relatedQuestions = listOf("什么是盘前盘后交易？", "节假日是否可以交易？")
            )
        )
        "funding" -> listOf(
            HelpQuestion(
                id = "6",
                title = "如何入金？",
                answer = "1. 进入\"我的\" - \"出入金\"\n2. 选择\"入金\"\n3. 选择入金方式（银行转账/第三方支付）\n4. 输入入金金额\n5. 按照提示完成转账\n6. 等待到账（通常1-2个工作日）\n\n注意：入金账户必须是本人同名账户。",
                relatedQuestions = listOf("入金需要多久到账？", "入金有手续费吗？")
            ),
            HelpQuestion(
                id = "7",
                title = "如何出金？",
                answer = "1. 进入\"我的\" - \"出入金\"\n2. 选择\"出金\"\n3. 选择出金银行卡\n4. 输入出金金额\n5. 输入交易密码\n6. 提交申请\n7. 等待到账（通常1-2个工作日）\n\n出金金额不能超过可用余额。",
                relatedQuestions = listOf("出金需要多久到账？", "出金有手续费吗？")
            )
        )
        else -> emptyList()
    }
}
