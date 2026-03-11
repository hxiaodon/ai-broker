package com.brokerage.ui.screens.market
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
import com.brokerage.domain.marketdata.SearchResult
import com.brokerage.presentation.market.SearchViewModel
import com.brokerage.ui.theme.*
import org.koin.compose.koinInject

/**
 * 搜索页面
 */
@Composable
fun SearchScreen(
    onBackClick: () -> Unit,
    onStockClick: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: SearchViewModel = koinInject()
) {
    val uiState by viewModel.uiState.collectAsState()
    var searchQuery by remember { mutableStateOf("") }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BackgroundLight)
    ) {
        // 搜索栏
        SearchBar(
            query = searchQuery,
            onQueryChange = {
                searchQuery = it
                viewModel.search(it)
            },
            onBackClick = onBackClick
        )

        // 内容区域
        when {
            searchQuery.isEmpty() -> {
                // 显示搜索历史和热门搜索
                SearchSuggestions(
                    history = uiState.searchHistory,
                    hotSearches = uiState.hotSearches,
                    onItemClick = { query ->
                        searchQuery = query
                        viewModel.search(query)
                    },
                    onClearHistory = { viewModel.clearHistory() }
                )
            }
            uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
            uiState.results.isEmpty() -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "未找到相关股票",
                        fontSize = 14.sp,
                        color = TextSecondary
                    )
                }
            }
            else -> {
                SearchResults(
                    results = uiState.results,
                    onStockClick = onStockClick
                )
            }
        }
    }
}

@Composable
private fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    onBackClick: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color.White,
        shadowElevation = 2.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBackClick) {
                Icon(BrokerageIcons.ArrowBack, contentDescription = "返回", modifier = Modifier.size(24.dp))
            }

            TextField(
                value = query,
                onValueChange = onQueryChange,
                modifier = Modifier.weight(1f),
                placeholder = { Text("搜索股票代码或名称") },
                singleLine = true,
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = BackgroundLight,
                    unfocusedContainerColor = BackgroundLight,
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent
                )
            )
        }
    }
}

@Composable
private fun SearchSuggestions(
    history: List<String>,
    hotSearches: List<String>,
    onItemClick: (String) -> Unit,
    onClearHistory: () -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(Spacing.medium)
    ) {
        // 搜索历史
        if (history.isNotEmpty()) {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "搜索历史",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = TextPrimary
                    )
                    TextButton(onClick = onClearHistory) {
                        Text("清空", fontSize = 12.sp)
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
            }

            items(history) { item ->
                SearchHistoryItem(
                    text = item,
                    onClick = { onItemClick(item) }
                )
            }

            item {
                Spacer(modifier = Modifier.height(24.dp))
            }
        }

        // 热门搜索
        if (hotSearches.isNotEmpty()) {
            item {
                Text(
                    text = "热门搜索",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimary
                )
                Spacer(modifier = Modifier.height(8.dp))
            }

            items(hotSearches) { item ->
                SearchHistoryItem(
                    text = item,
                    onClick = { onItemClick(item) }
                )
            }
        }
    }
}

@Composable
private fun SearchHistoryItem(
    text: String,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        color = Color.White
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "🕐",
                fontSize = 16.sp,
                modifier = Modifier.padding(end = 12.dp)
            )
            Text(
                text = text,
                fontSize = 14.sp,
                color = TextPrimary
            )
        }
    }
}

@Composable
private fun SearchResults(
    results: List<SearchResult>,
    onStockClick: (String) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize()
    ) {
        items(results) { result ->
            SearchResultItem(
                result = result,
                onClick = { onStockClick(result.symbol) }
            )
            HorizontalDivider(color = BorderLight, thickness = 1.dp)
        }
    }
}

@Composable
private fun SearchResultItem(
    result: SearchResult,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        color = Color.White,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = result.symbol,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = result.nameCN,
                    fontSize = 12.sp,
                    color = TextSecondary
                )
            }

            Text(
                text = result.market.name,
                fontSize = 12.sp,
                color = TextSecondary
            )
        }
    }
}
