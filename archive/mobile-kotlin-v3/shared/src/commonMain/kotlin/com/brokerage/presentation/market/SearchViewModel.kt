package com.brokerage.presentation.market

import com.brokerage.data.api.ApiResult
import com.brokerage.data.repository.MarketRepository
import com.brokerage.domain.marketdata.SearchResult
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

/**
 * 搜索页面状态
 */
data class SearchUiState(
    val isLoading: Boolean = false,
    val results: List<SearchResult> = emptyList(),
    val searchHistory: List<String> = emptyList(),
    val hotSearches: List<String> = emptyList(),
    val error: String? = null
)

/**
 * 搜索 ViewModel
 */
class SearchViewModel(
    private val repository: MarketRepository
) {
    private val viewModelScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    private val _uiState = MutableStateFlow(SearchUiState())
    val uiState: StateFlow<SearchUiState> = _uiState.asStateFlow()

    private val searchHistoryList = mutableListOf<String>()

    init {
        loadHotSearches()
    }

    /**
     * 搜索股票
     */
    fun search(query: String) {
        if (query.isBlank()) {
            _uiState.update { it.copy(results = emptyList(), isLoading = false) }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            when (val result = repository.searchStocks(query, limit = 20)) {
                is ApiResult.Success -> {
                    // 添加到搜索历史
                    if (!searchHistoryList.contains(query)) {
                        searchHistoryList.add(0, query)
                        if (searchHistoryList.size > 10) {
                            searchHistoryList.removeAt(searchHistoryList.size - 1)
                        }
                    }

                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            results = result.data,
                            searchHistory = searchHistoryList.toList(),
                            error = null
                        )
                    }
                }
                is ApiResult.Error -> {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = result.exception.message
                        )
                    }
                }
            }
        }
    }

    /**
     * 加载热门搜索
     */
    private fun loadHotSearches() {
        viewModelScope.launch {
            when (val result = repository.getHotSearches(limit = 10)) {
                is ApiResult.Success -> {
                    _uiState.update { it.copy(hotSearches = result.data) }
                }
                is ApiResult.Error -> {
                    // 热门搜索加载失败不影响主流程
                }
            }
        }
    }

    /**
     * 清空搜索历史
     */
    fun clearHistory() {
        searchHistoryList.clear()
        _uiState.update { it.copy(searchHistory = emptyList()) }
    }
}
