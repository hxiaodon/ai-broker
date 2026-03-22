-- migrations/002_add_outbox_metadata.sql
-- Add event_id, event_type, correlation_id to outbox_events for Kafka compliance

-- +goose Up
ALTER TABLE outbox_events
    ADD COLUMN event_id VARCHAR(36) NOT NULL COMMENT 'UUID v4 for idempotency' AFTER id,
    ADD COLUMN event_type VARCHAR(100) NOT NULL COMMENT 'Event type with version, e.g. QuoteUpdated.v1' AFTER event_id,
    ADD COLUMN correlation_id VARCHAR(36) NULL COMMENT 'OTel trace ID or request correlation ID' AFTER event_type,
    ADD INDEX idx_outbox_event_id (event_id);

-- +goose Down
ALTER TABLE outbox_events
    DROP INDEX idx_outbox_event_id,
    DROP COLUMN correlation_id,
    DROP COLUMN event_type,
    DROP COLUMN event_id;
