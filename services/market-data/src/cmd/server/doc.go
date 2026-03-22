// Package main provides the entry point for the market-data service.
//
//	@title          Market Data Service API
//	@version        1.0
//	@description    Real-time and historical market data for US (NYSE/NASDAQ) and HK (HKEX) equities. Provides quote snapshots, K-line charts, watchlists, and stock search.
//	@termsOfService https://example.com/terms
//
//	@contact.name   Market Data Team
//	@contact.email  market-data@example.com
//
//	@license.name   Proprietary
//
//	@host     localhost:8080
//	@BasePath /api/v1
//
//	@securityDefinitions.apikey BearerAuth
//	@in header
//	@name Authorization
//	@description JWT Bearer token. Format: "Bearer {token}"
//
//	@tag.name       quote
//	@tag.description Real-time quote snapshots and market status
//
//	@tag.name       kline
//	@tag.description Historical K-line (OHLCV) candlestick data
//
//	@tag.name       watchlist
//	@tag.description User watchlist management
//
//	@tag.name       search
//	@tag.description Stock symbol search and hot rankings
package main
