-- +goose Up
-- Add pinyin and initials columns for Chinese name search support
-- Spec: P4-05 — enable pinyin search for Chinese stock names (e.g., "pingguo" matches "苹果")

ALTER TABLE stocks
    ADD COLUMN pinyin VARCHAR(255) NULL COMMENT 'Full pinyin of name_cn (e.g., "pingguo")' AFTER name_cn,
    ADD COLUMN initials VARCHAR(50) NULL COMMENT 'Pinyin initials of name_cn (e.g., "pg")' AFTER pinyin;

-- Update fulltext index to include pinyin column
DROP INDEX idx_stocks_search ON stocks;
CREATE FULLTEXT INDEX idx_stocks_search ON stocks(name, name_cn, pinyin);

-- +goose Down
-- Rollback: remove pinyin columns and restore original fulltext index
ALTER TABLE stocks
    DROP COLUMN pinyin,
    DROP COLUMN initials;

DROP INDEX idx_stocks_search ON stocks;
CREATE FULLTEXT INDEX idx_stocks_search ON stocks(name, name_cn);
