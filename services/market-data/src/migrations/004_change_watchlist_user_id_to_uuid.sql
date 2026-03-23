-- +goose Up
-- Change watchlist_items.user_id from BIGINT to CHAR(36) for UUID support
-- Security: UUID prevents user enumeration attacks vs auto-increment int64

ALTER TABLE watchlist_items
    MODIFY COLUMN user_id CHAR(36) NOT NULL COMMENT 'User UUID from AMS service';

-- +goose Down
-- Rollback: restore to BIGINT (data loss if UUIDs were inserted)
ALTER TABLE watchlist_items
    MODIFY COLUMN user_id BIGINT NOT NULL COMMENT 'User ID';
