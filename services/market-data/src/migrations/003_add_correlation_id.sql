-- +goose Up
-- Add correlation_id column for distributed tracing
ALTER TABLE outbox_events ADD COLUMN correlation_id VARCHAR(64) DEFAULT '' AFTER event_type;
CREATE INDEX idx_correlation_id ON outbox_events(correlation_id);

-- +goose Down
DROP INDEX idx_correlation_id ON outbox_events;
ALTER TABLE outbox_events DROP COLUMN correlation_id;
