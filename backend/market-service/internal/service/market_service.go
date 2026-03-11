package service

import (
	"context"
	"fmt"
	"time"

	"github.com/brokerage/market-service/internal/model"
	"github.com/brokerage/market-service/internal/repository"
	"github.com/brokerage/market-service/pkg/cache"
	"github.com/brokerage/market-service/pkg/polygon"
	"github.com/shopspring/decimal"
)

// MarketService 行情服务
type MarketService struct {
	stockRepo     *repository.StockRepository
	quoteRepo     *repository.QuoteRepository
	klineRepo     *repository.KlineRepository
	watchlistRepo *repository.WatchlistRepository
	newsRepo      *repository.NewsRepository
	financialRepo *repository.FinancialRepository
	hotSearchRepo *repository.HotSearchRepository
	polygonClient *polygon.Client
}

// NewMarketService 创建行情服务
func NewMarketService(
	stockRepo *repository.StockRepository,
	quoteRepo *repository.QuoteRepository,
	klineRepo *repository.KlineRepository,
	watchlistRepo *repository.WatchlistRepository,
	newsRepo *repository.NewsRepository,
	financialRepo *repository.FinancialRepository,
	hotSearchRepo *repository.HotSearchRepository,
	polygonClient *polygon.Client,
) *MarketService {
	return &MarketService{
		stockRepo:     stockRepo,
		quoteRepo:     quoteRepo,
		klineRepo:     klineRepo,
		watchlistRepo: watchlistRepo,
		newsRepo:      newsRepo,
		financialRepo: financialRepo,
		hotSearchRepo: hotSearchRepo,
		polygonClient: polygonClient,
	}
}

// StockListRequest 股票列表请求
type StockListRequest struct {
	Category string `form:"category"` // watchlist/us/hk/hot
	Page     int    `form:"page"`
	PageSize int    `form:"pageSize"`
	UserID   uint64 // 从认证中间件获取
}

// StockListResponse 股票列表响应
type StockListResponse struct {
	Total  int64               `json:"total"`
	Page   int                 `json:"page"`
	PageSize int               `json:"pageSize"`
	Stocks []*StockWithQuote   `json:"stocks"`
}

// StockWithQuote 股票信息（含行情）
type StockWithQuote struct {
	Symbol        string          `json:"symbol"`
	Name          string          `json:"name"`
	NameCN        string          `json:"nameCN"`
	Market        string          `json:"market"`
	Price         decimal.Decimal `json:"price"`
	Change        decimal.Decimal `json:"change"`
	ChangePercent decimal.Decimal `json:"changePercent"`
	MarketCap     string          `json:"marketCap"`
	PE            decimal.Decimal `json:"pe"`
	Volume        string          `json:"volume"`
	Timestamp     int64           `json:"timestamp"`
}

// GetStockList 获取股票列表
func (s *MarketService) GetStockList(ctx context.Context, req *StockListRequest) (*StockListResponse, error) {
	// 设置默认值
	if req.Page <= 0 {
		req.Page = 1
	}
	if req.PageSize <= 0 {
		req.PageSize = 20
	}
	if req.PageSize > 100 {
		req.PageSize = 100
	}

	var symbols []string
	var total int64

	// 根据分类获取股票列表
	switch req.Category {
	case "watchlist":
		// 获取自选股
		watchlists, err := s.watchlistRepo.FindByUserID(ctx, req.UserID)
		if err != nil {
			return nil, fmt.Errorf("failed to get watchlist: %w", err)
		}
		for _, w := range watchlists {
			symbols = append(symbols, w.Symbol)
		}
		total = int64(len(symbols))

	case "us", "hk":
		// 获取美股/港股列表
		offset := (req.Page - 1) * req.PageSize
		stocks, err := s.stockRepo.List(ctx, req.Category, offset, req.PageSize)
		if err != nil {
			return nil, fmt.Errorf("failed to get stock list: %w", err)
		}
		for _, stock := range stocks {
			symbols = append(symbols, stock.Symbol)
		}
		count, err := s.stockRepo.Count(ctx, req.Category)
		if err != nil {
			return nil, fmt.Errorf("failed to count stocks: %w", err)
		}
		total = count

	default:
		// 默认返回自选股
		watchlists, err := s.watchlistRepo.FindByUserID(ctx, req.UserID)
		if err != nil {
			return nil, fmt.Errorf("failed to get watchlist: %w", err)
		}
		for _, w := range watchlists {
			symbols = append(symbols, w.Symbol)
		}
		total = int64(len(symbols))
	}

	// 获取股票信息和行情
	stocksWithQuote, err := s.getStocksWithQuote(ctx, symbols)
	if err != nil {
		return nil, err
	}

	return &StockListResponse{
		Total:    total,
		Page:     req.Page,
		PageSize: req.PageSize,
		Stocks:   stocksWithQuote,
	}, nil
}

// GetStockDetail 获取股票详情
func (s *MarketService) GetStockDetail(ctx context.Context, symbol string) (*StockDetailResponse, error) {
	// 尝试从缓存获取
	cacheKey := fmt.Sprintf("stock:detail:%s", symbol)
	var detail StockDetailResponse
	if err := cache.Get(ctx, cacheKey, &detail); err == nil {
		return &detail, nil
	}

	// 从数据库获取股票信息
	stock, err := s.stockRepo.FindBySymbol(ctx, symbol)
	if err != nil {
		return nil, fmt.Errorf("failed to get stock: %w", err)
	}

	// 获取最新行情
	quote, err := s.quoteRepo.FindBySymbol(ctx, symbol)
	if err != nil {
		return nil, fmt.Errorf("failed to get quote: %w", err)
	}

	detail = StockDetailResponse{
		Symbol:        stock.Symbol,
		Name:          stock.Name,
		NameCN:        stock.NameCN,
		Market:        stock.Market,
		Price:         quote.Price,
		Change:        quote.ChangeAmount,
		ChangePercent: quote.ChangePercent,
		Open:          quote.Open,
		High:          quote.High,
		Low:           quote.Low,
		Volume:        fmt.Sprintf("%d", quote.Volume),
		MarketCap:     stock.MarketCap,
		PE:            stock.PE,
		PB:            stock.PB,
		DividendYield: stock.DividendYield,
		Week52High:    stock.Week52High,
		Week52Low:     stock.Week52Low,
		AvgVolume:     stock.AvgVolume,
		Timestamp:     quote.Timestamp,
	}

	// 缓存结果
	_ = cache.Set(ctx, cacheKey, detail, 5*time.Second)

	return &detail, nil
}

// StockDetailResponse 股票详情响应
type StockDetailResponse struct {
	Symbol        string          `json:"symbol"`
	Name          string          `json:"name"`
	NameCN        string          `json:"nameCN"`
	Market        string          `json:"market"`
	Price         decimal.Decimal `json:"price"`
	Change        decimal.Decimal `json:"change"`
	ChangePercent decimal.Decimal `json:"changePercent"`
	Open          decimal.Decimal `json:"open"`
	High          decimal.Decimal `json:"high"`
	Low           decimal.Decimal `json:"low"`
	Volume        string          `json:"volume"`
	MarketCap     string          `json:"marketCap"`
	PE            decimal.Decimal `json:"pe"`
	PB            decimal.Decimal `json:"pb"`
	DividendYield decimal.Decimal `json:"dividendYield"`
	Week52High    decimal.Decimal `json:"week52High"`
	Week52Low     decimal.Decimal `json:"week52Low"`
	AvgVolume     string          `json:"avgVolume"`
	Timestamp     int64           `json:"timestamp"`
}

// GetKlineData 获取K线数据
func (s *MarketService) GetKlineData(ctx context.Context, symbol, interval string, startTime, endTime int64, limit int) ([]*model.Kline, error) {
	// 设置默认值
	if limit <= 0 {
		limit = 100
	}
	if limit > 500 {
		limit = 500
	}
	if endTime <= 0 {
		endTime = time.Now().UnixMilli()
	}
	if startTime <= 0 {
		// 默认返回最近100条
		startTime = endTime - int64(limit)*getIntervalMillis(interval)
	}

	// 从数据库获取K线数据
	klines, err := s.klineRepo.FindBySymbolAndInterval(ctx, symbol, interval, startTime, endTime, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get kline data: %w", err)
	}

	return klines, nil
}

// SearchStocks 搜索股票
func (s *MarketService) SearchStocks(ctx context.Context, keyword string, limit int) ([]*StockWithQuote, error) {
	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	// 搜索股票
	stocks, err := s.stockRepo.Search(ctx, keyword, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to search stocks: %w", err)
	}

	// 获取股票代码列表
	symbols := make([]string, 0, len(stocks))
	for _, stock := range stocks {
		symbols = append(symbols, stock.Symbol)
	}

	// 获取行情信息
	return s.getStocksWithQuote(ctx, symbols)
}

// AddToWatchlist 添加自选股
func (s *MarketService) AddToWatchlist(ctx context.Context, userID uint64, symbol string) error {
	// 检查是否已存在
	exists, err := s.watchlistRepo.Exists(ctx, userID, symbol)
	if err != nil {
		return fmt.Errorf("failed to check watchlist: %w", err)
	}
	if exists {
		return fmt.Errorf("stock already in watchlist")
	}

	// 添加自选股
	watchlist := &model.Watchlist{
		UserID: userID,
		Symbol: symbol,
	}
	if err := s.watchlistRepo.Create(ctx, watchlist); err != nil {
		return fmt.Errorf("failed to add to watchlist: %w", err)
	}

	return nil
}

// RemoveFromWatchlist 删除自选股
func (s *MarketService) RemoveFromWatchlist(ctx context.Context, userID uint64, symbol string) error {
	return s.watchlistRepo.Delete(ctx, userID, symbol)
}

// getStocksWithQuote 获取股票信息（含行情）
func (s *MarketService) getStocksWithQuote(ctx context.Context, symbols []string) ([]*StockWithQuote, error) {
	if len(symbols) == 0 {
		return []*StockWithQuote{}, nil
	}

	// 批量获取股票信息
	stocks, err := s.stockRepo.FindBySymbols(ctx, symbols)
	if err != nil {
		return nil, fmt.Errorf("failed to get stocks: %w", err)
	}

	stockMap := make(map[string]*model.Stock)
	for _, stock := range stocks {
		stockMap[stock.Symbol] = stock
	}

	// 批量获取行情
	quotes, err := s.quoteRepo.FindBySymbols(ctx, symbols)
	if err != nil {
		return nil, fmt.Errorf("failed to get quotes: %w", err)
	}

	// 组装结果
	result := make([]*StockWithQuote, 0, len(quotes))
	for _, quote := range quotes {
		stock, ok := stockMap[quote.Symbol]
		if !ok {
			continue
		}

		result = append(result, &StockWithQuote{
			Symbol:        stock.Symbol,
			Name:          stock.Name,
			NameCN:        stock.NameCN,
			Market:        stock.Market,
			Price:         quote.Price,
			Change:        quote.ChangeAmount,
			ChangePercent: quote.ChangePercent,
			MarketCap:     stock.MarketCap,
			PE:            stock.PE,
			Volume:        fmt.Sprintf("%d", quote.Volume),
			Timestamp:     quote.Timestamp,
		})
	}

	return result, nil
}

// getIntervalMillis 获取时间间隔的毫秒数
func getIntervalMillis(interval string) int64 {
	switch interval {
	case "1m":
		return 60 * 1000
	case "1d":
		return 24 * 60 * 60 * 1000
	case "1w":
		return 7 * 24 * 60 * 60 * 1000
	case "1M":
		return 30 * 24 * 60 * 60 * 1000
	default:
		return 60 * 1000
	}
}

// GetHotSearches 获取热门搜索
func (s *MarketService) GetHotSearches(ctx context.Context, limit int) ([]*model.HotSearch, error) {
	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	hotSearches, err := s.hotSearchRepo.GetTopSearches(ctx, time.Now(), limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get hot searches: %w", err)
	}

	return hotSearches, nil
}

// GetStockNews 获取股票新闻
func (s *MarketService) GetStockNews(ctx context.Context, symbol string, page, pageSize int) ([]*model.News, int64, error) {
	if page <= 0 {
		page = 1
	}
	if pageSize <= 0 {
		pageSize = 20
	}
	if pageSize > 100 {
		pageSize = 100
	}

	offset := (page - 1) * pageSize
	newsList, err := s.newsRepo.FindBySymbol(ctx, symbol, offset, pageSize)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get news: %w", err)
	}

	total, err := s.newsRepo.Count(ctx, symbol)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count news: %w", err)
	}

	return newsList, total, nil
}

// GetFinancials 获取财报数据
func (s *MarketService) GetFinancials(ctx context.Context, symbol string, limit int) ([]*model.Financial, error) {
	if limit <= 0 {
		limit = 4
	}
	if limit > 20 {
		limit = 20
	}

	financials, err := s.financialRepo.FindBySymbol(ctx, symbol, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get financials: %w", err)
	}

	return financials, nil
}

