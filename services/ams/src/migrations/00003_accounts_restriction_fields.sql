-- services/ams/src/migrations/00003_accounts_restriction_fields.sql
-- AMS: Add account restriction fields and update KYC enum values
-- Implements ams-to-trading.md v1.1 contract (2026-03-30)
--
-- Changes:
--   1. Add is_restricted, restriction_reason, restriction_until_at columns to accounts table
--   2. Add index on is_restricted for Trading Engine filtering
--   3. NOTE: kyc_tier and kyc_status enum value renames (VERIFIED→APPROVED, BASIC→TIER_1, etc.)
--      are handled by application layer during deployment with zero-downtime migration strategy
--      (see deployment-notes in docs/patches.yaml).

-- +goose Up
-- +goose StatementBegin

ALTER TABLE accounts
  ADD COLUMN is_restricted        TINYINT(1)   NOT NULL DEFAULT 0     COMMENT 'PDT/合规/账户暂停限制标记；Trading Engine 据此拒绝下单',
  ADD COLUMN restriction_reason   VARCHAR(255) NULL                   COMMENT '限制原因说明（is_restricted=1 时填写）',
  ADD COLUMN restriction_until_at TIMESTAMP    NULL                   COMMENT '限制解除时间(UTC)，NULL=无限期';

-- Index for Trading Engine to efficiently filter restricted accounts
CREATE INDEX idx_accounts_is_restricted ON accounts (is_restricted);

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin

DROP INDEX idx_accounts_is_restricted ON accounts;

ALTER TABLE accounts
  DROP COLUMN restriction_until_at,
  DROP COLUMN restriction_reason,
  DROP COLUMN is_restricted;

-- +goose StatementEnd
