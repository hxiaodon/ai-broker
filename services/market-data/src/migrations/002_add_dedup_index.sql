-- +goose Up
-- Add index for quote deduplication
ALTER TABLE quotes ADD INDEX idx_symbol_market_updated (symbol, market, last_updated_at);

-- +goose Down
ALTER TABLE quotes DROP INDEX idx_symbol_market_updated;
