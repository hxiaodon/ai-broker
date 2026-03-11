package polygon

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/brokerage/market-service/internal/config"
)

// Client Polygon.io 客户端
type Client struct {
	apiKey     string
	baseURL    string
	wsURL      string
	httpClient *http.Client
}

// NewClient 创建 Polygon.io 客户端
func NewClient(cfg *config.PolygonConfig) *Client {
	return &Client{
		apiKey:  cfg.APIKey,
		baseURL: cfg.BaseURL,
		wsURL:   cfg.WsURL,
		httpClient: &http.Client{
			Timeout: time.Duration(cfg.Timeout) * time.Second,
		},
	}
}

// QuoteResponse 实时行情响应
type QuoteResponse struct {
	Status string `json:"status"`
	Ticker string `json:"ticker"`
	Results struct {
		Price  float64 `json:"p"`
		Size   int64   `json:"s"`
		Time   int64   `json:"t"`
	} `json:"results"`
}

// AggregateResponse K线数据响应
type AggregateResponse struct {
	Status       string `json:"status"`
	Ticker       string `json:"ticker"`
	QueryCount   int    `json:"queryCount"`
	ResultsCount int    `json:"resultsCount"`
	Results      []struct {
		Open      float64 `json:"o"`
		High      float64 `json:"h"`
		Low       float64 `json:"l"`
		Close     float64 `json:"c"`
		Volume    int64   `json:"v"`
		Timestamp int64   `json:"t"`
	} `json:"results"`
}

// TickerDetailsResponse 股票详情响应
type TickerDetailsResponse struct {
	Status  string `json:"status"`
	Results struct {
		Ticker      string  `json:"ticker"`
		Name        string  `json:"name"`
		Market      string  `json:"market"`
		MarketCap   float64 `json:"market_cap"`
		SharesOutstanding float64 `json:"share_class_shares_outstanding"`
	} `json:"results"`
}

// GetQuote 获取实时行情
func (c *Client) GetQuote(ctx context.Context, symbol string) (*QuoteResponse, error) {
	path := fmt.Sprintf("/v2/last/trade/%s", symbol)
	body, err := c.doRequest(ctx, http.MethodGet, path)
	if err != nil {
		return nil, err
	}

	var resp QuoteResponse
	if err := parseResponse(body, &resp); err != nil {
		return nil, err
	}

	return &resp, nil
}

// GetAggregates 获取 K 线数据
func (c *Client) GetAggregates(ctx context.Context, symbol, interval string, from, to int64) (*AggregateResponse, error) {
	multiplier, timespan := parseInterval(interval)
	path := fmt.Sprintf("/v2/aggs/ticker/%s/range/%d/%s/%d/%d", symbol, multiplier, timespan, from, to)

	body, err := c.doRequest(ctx, http.MethodGet, path)
	if err != nil {
		return nil, err
	}

	var resp AggregateResponse
	if err := parseResponse(body, &resp); err != nil {
		return nil, err
	}

	return &resp, nil
}

// GetTickerDetails 获取股票详情
func (c *Client) GetTickerDetails(ctx context.Context, symbol string) (*TickerDetailsResponse, error) {
	path := fmt.Sprintf("/v3/reference/tickers/%s", symbol)

	body, err := c.doRequest(ctx, http.MethodGet, path)
	if err != nil {
		return nil, err
	}

	var resp TickerDetailsResponse
	if err := parseResponse(body, &resp); err != nil {
		return nil, err
	}

	return &resp, nil
}

// doRequest 执行 HTTP 请求
func (c *Client) doRequest(ctx context.Context, method, path string) ([]byte, error) {
	url := fmt.Sprintf("%s%s?apiKey=%s", c.baseURL, path, c.apiKey)

	req, err := http.NewRequestWithContext(ctx, method, url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to do request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	return body, nil
}

// parseResponse 解析响应
func parseResponse(data []byte, v interface{}) error {
	if err := json.Unmarshal(data, v); err != nil {
		return fmt.Errorf("failed to unmarshal response: %w", err)
	}
	return nil
}

// parseInterval 解析时间间隔
func parseInterval(interval string) (int, string) {
	switch interval {
	case "1m":
		return 1, "minute"
	case "5m":
		return 5, "minute"
	case "15m":
		return 15, "minute"
	case "30m":
		return 30, "minute"
	case "1h":
		return 1, "hour"
	case "1d":
		return 1, "day"
	case "1w":
		return 1, "week"
	case "1M":
		return 1, "month"
	default:
		return 1, "minute"
	}
}
