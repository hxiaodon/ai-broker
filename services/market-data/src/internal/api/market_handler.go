package api

import (
	"net/http"
	"strconv"

	"github.com/brokerage/market-service/internal/service"
	"github.com/gin-gonic/gin"
)

// MarketHandler 行情 API 处理器
type MarketHandler struct {
	marketService *service.MarketService
}

// NewMarketHandler 创建行情 API 处理器
func NewMarketHandler(marketService *service.MarketService) *MarketHandler {
	return &MarketHandler{
		marketService: marketService,
	}
}

// Response 统一响应格式
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// Success 成功响应
func Success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code:    0,
		Message: "success",
		Data:    data,
	})
}

// Error 错误响应
func Error(c *gin.Context, code int, message string) {
	c.JSON(http.StatusOK, Response{
		Code:    code,
		Message: message,
	})
}

// GetStockList 获取股票列表
// @Summary 获取股票列表
// @Tags Market
// @Param category query string false "分类: watchlist/us/hk/hot"
// @Param page query int false "页码"
// @Param pageSize query int false "每页数量"
// @Success 200 {object} Response
// @Router /api/v1/market/stocks [get]
func (h *MarketHandler) GetStockList(c *gin.Context) {
	var req service.StockListRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		Error(c, 400, "invalid request parameters")
		return
	}

	userID, _ := c.Get("user_id")
	req.UserID = userID.(uint64)

	resp, err := h.marketService.GetStockList(c.Request.Context(), &req)
	if err != nil {
		Error(c, 500, err.Error())
		return
	}

	Success(c, resp)
}

// GetStockDetail 获取股票详情
// @Summary 获取股票详情
// @Tags Market
// @Param symbol path string true "股票代码"
// @Success 200 {object} Response
// @Router /api/v1/market/stocks/{symbol} [get]
func (h *MarketHandler) GetStockDetail(c *gin.Context) {
	symbol := c.Param("symbol")
	if symbol == "" {
		Error(c, 400, "symbol is required")
		return
	}

	resp, err := h.marketService.GetStockDetail(c.Request.Context(), symbol)
	if err != nil {
		Error(c, 500, err.Error())
		return
	}

	Success(c, resp)
}

// GetKlineData 获取K线数据
// @Summary 获取K线数据
// @Tags Market
// @Param symbol path string true "股票代码"
// @Param interval query string true "时间间隔: 1m/1d/1w/1M"
// @Param startTime query int false "开始时间戳(毫秒)"
// @Param endTime query int false "结束时间戳(毫秒)"
// @Param limit query int false "返回数量"
// @Success 200 {object} Response
// @Router /api/v1/market/kline/{symbol} [get]
func (h *MarketHandler) GetKlineData(c *gin.Context) {
	symbol := c.Param("symbol")
	if symbol == "" {
		Error(c, 400, "symbol is required")
		return
	}

	interval := c.Query("interval")
	if interval == "" {
		Error(c, 400, "interval is required")
		return
	}

	var startTime, endTime int64
	var limit int

	if startTimeStr := c.Query("startTime"); startTimeStr != "" {
		if val, err := strconv.ParseInt(startTimeStr, 10, 64); err == nil {
			startTime = val
		}
	}

	if endTimeStr := c.Query("endTime"); endTimeStr != "" {
		if val, err := strconv.ParseInt(endTimeStr, 10, 64); err == nil {
			endTime = val
		}
	}

	if limitStr := c.Query("limit"); limitStr != "" {
		if val, err := strconv.Atoi(limitStr); err == nil {
			limit = val
		}
	}

	resp, err := h.marketService.GetKlineData(c.Request.Context(), symbol, interval, startTime, endTime, limit)
	if err != nil {
		Error(c, 500, err.Error())
		return
	}

	Success(c, resp)
}

// SearchStocks 搜索股票
// @Summary 搜索股票
// @Tags Market
// @Param keyword query string true "搜索关键词"
// @Param limit query int false "返回数量"
// @Success 200 {object} Response
// @Router /api/v1/market/search [get]
func (h *MarketHandler) SearchStocks(c *gin.Context) {
	keyword := c.Query("keyword")
	if keyword == "" {
		Error(c, 400, "keyword is required")
		return
	}

	limit := 10
	if limitStr := c.Query("limit"); limitStr != "" {
		if val, err := strconv.Atoi(limitStr); err == nil && val > 0 {
			limit = val
		}
	}

	resp, err := h.marketService.SearchStocks(c.Request.Context(), keyword, limit)
	if err != nil {
		Error(c, 500, err.Error())
		return
	}

	Success(c, resp)
}

// GetHotSearches 获取热门搜索
// @Summary 获取热门搜索
// @Tags Market
// @Param limit query int false "返回数量"
// @Success 200 {object} Response
// @Router /api/v1/market/hot-searches [get]
func (h *MarketHandler) GetHotSearches(c *gin.Context) {
	limit := 10
	if limitStr := c.Query("limit"); limitStr != "" {
		if val, err := strconv.Atoi(limitStr); err == nil && val > 0 {
			limit = val
		}
	}

	resp, err := h.marketService.GetHotSearches(c.Request.Context(), limit)
	if err != nil {
		Error(c, 500, err.Error())
		return
	}

	Success(c, resp)
}

// GetStockNews 获取股票新闻
// @Summary 获取股票新闻
// @Tags Market
// @Param symbol path string true "股票代码"
// @Param page query int false "页码"
// @Param pageSize query int false "每页数量"
// @Success 200 {object} Response
// @Router /api/v1/market/news/{symbol} [get]
func (h *MarketHandler) GetStockNews(c *gin.Context) {
	symbol := c.Param("symbol")
	if symbol == "" {
		Error(c, 400, "symbol is required")
		return
	}

	page := 1
	if pageStr := c.Query("page"); pageStr != "" {
		if val, err := strconv.Atoi(pageStr); err == nil && val > 0 {
			page = val
		}
	}

	pageSize := 10
	if pageSizeStr := c.Query("pageSize"); pageSizeStr != "" {
		if val, err := strconv.Atoi(pageSizeStr); err == nil && val > 0 {
			pageSize = val
		}
	}

	newsList, total, err := h.marketService.GetStockNews(c.Request.Context(), symbol, page, pageSize)
	if err != nil {
		Error(c, 500, err.Error())
		return
	}

	Success(c, gin.H{
		"total":    total,
		"page":     page,
		"pageSize": pageSize,
		"news":     newsList,
	})
}

// GetFinancials 获取财报数据
// @Summary 获取财报数据
// @Tags Market
// @Param symbol path string true "股票代码"
// @Success 200 {object} Response
// @Router /api/v1/market/financials/{symbol} [get]
func (h *MarketHandler) GetFinancials(c *gin.Context) {
	symbol := c.Param("symbol")
	if symbol == "" {
		Error(c, 400, "symbol is required")
		return
	}

	limit := 4
	if limitStr := c.Query("limit"); limitStr != "" {
		if val, err := strconv.Atoi(limitStr); err == nil && val > 0 {
			limit = val
		}
	}

	resp, err := h.marketService.GetFinancials(c.Request.Context(), symbol, limit)
	if err != nil {
		Error(c, 500, err.Error())
		return
	}

	Success(c, resp)
}

// AddToWatchlist 添加自选股
// @Summary 添加自选股
// @Tags Market
// @Param body body AddWatchlistRequest true "请求体"
// @Success 200 {object} Response
// @Router /api/v1/market/watchlist [post]
func (h *MarketHandler) AddToWatchlist(c *gin.Context) {
	var req struct {
		Symbol string `json:"symbol" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		Error(c, 400, "invalid request body")
		return
	}

	// TODO: 从认证中间件获取用户ID
	userID := uint64(1)

	if err := h.marketService.AddToWatchlist(c.Request.Context(), userID, req.Symbol); err != nil {
		Error(c, 500, err.Error())
		return
	}

	Success(c, gin.H{"message": "添加成功"})
}

// RemoveFromWatchlist 删除自选股
// @Summary 删除自选股
// @Tags Market
// @Param symbol path string true "股票代码"
// @Success 200 {object} Response
// @Router /api/v1/market/watchlist/{symbol} [delete]
func (h *MarketHandler) RemoveFromWatchlist(c *gin.Context) {
	symbol := c.Param("symbol")
	if symbol == "" {
		Error(c, 400, "symbol is required")
		return
	}

	userID, _ := c.Get("user_id")

	if err := h.marketService.RemoveFromWatchlist(c.Request.Context(), userID.(uint64), symbol); err != nil {
		Error(c, 500, err.Error())
		return
	}

	Success(c, gin.H{"message": "删除成功"})
}
