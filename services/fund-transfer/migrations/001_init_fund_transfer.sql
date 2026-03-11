-- Fund Transfer System Database Schema

-- fund_transfers table (partitioned by month)
CREATE TABLE fund_transfers (
    transfer_id VARCHAR(64) PRIMARY KEY,
    account_id VARCHAR(64) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('DEPOSIT', 'WITHDRAWAL')),
    status VARCHAR(30) NOT NULL,
    amount DECIMAL(20, 8) NOT NULL,
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('USD', 'HKD')),
    channel VARCHAR(20) NOT NULL CHECK (channel IN ('ACH', 'WIRE', 'FPS', 'CHATS', 'SWIFT')),
    bank_account_id VARCHAR(64) NOT NULL,
    request_id VARCHAR(64) NOT NULL UNIQUE, -- idempotency key
    failure_reason TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP
) PARTITION BY RANGE (created_at);

-- Create partitions for 2026
CREATE TABLE fund_transfers_2026_01 PARTITION OF fund_transfers
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE fund_transfers_2026_02 PARTITION OF fund_transfers
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE fund_transfers_2026_03 PARTITION OF fund_transfers
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE fund_transfers_2026_04 PARTITION OF fund_transfers
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE fund_transfers_2026_05 PARTITION OF fund_transfers
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE fund_transfers_2026_06 PARTITION OF fund_transfers
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE fund_transfers_2026_07 PARTITION OF fund_transfers
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE fund_transfers_2026_08 PARTITION OF fund_transfers
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE fund_transfers_2026_09 PARTITION OF fund_transfers
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE fund_transfers_2026_10 PARTITION OF fund_transfers
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE TABLE fund_transfers_2026_11 PARTITION OF fund_transfers
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE fund_transfers_2026_12 PARTITION OF fund_transfers
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- Indexes
CREATE INDEX idx_fund_transfers_account_id ON fund_transfers(account_id, created_at DESC);
CREATE INDEX idx_fund_transfers_status ON fund_transfers(status) WHERE status IN ('PENDING', 'BANK_PROCESSING', 'APPROVAL');
CREATE INDEX idx_fund_transfers_request_id ON fund_transfers(request_id);

-- bank_accounts table
CREATE TABLE bank_accounts (
    bank_account_id VARCHAR(64) PRIMARY KEY,
    account_id VARCHAR(64) NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_number VARCHAR(100) NOT NULL,
    routing_number VARCHAR(50),
    swift_code VARCHAR(20),
    bank_name VARCHAR(255) NOT NULL,
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('USD', 'HKD')),
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_bank_accounts_account_id ON bank_accounts(account_id);
CREATE UNIQUE INDEX idx_bank_accounts_unique ON bank_accounts(account_id, account_number, routing_number);

-- account_balances table
CREATE TABLE account_balances (
    account_id VARCHAR(64) NOT NULL,
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('USD', 'HKD')),
    total_balance DECIMAL(20, 8) NOT NULL DEFAULT 0,
    available_balance DECIMAL(20, 8) NOT NULL DEFAULT 0,
    unsettled_amount DECIMAL(20, 8) NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (account_id, currency)
);

CREATE INDEX idx_account_balances_updated_at ON account_balances(updated_at);

-- ledger_entries table (immutable)
CREATE TABLE ledger_entries (
    entry_id VARCHAR(64) PRIMARY KEY,
    transfer_id VARCHAR(64) NOT NULL,
    account_type VARCHAR(20) NOT NULL CHECK (account_type IN ('ASSET', 'LIABILITY', 'BANK', 'FEE')),
    account_id VARCHAR(64) NOT NULL,
    debit DECIMAL(20, 8) NOT NULL DEFAULT 0,
    credit DECIMAL(20, 8) NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('USD', 'HKD')),
    exchange_rate DECIMAL(10, 6),
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ledger_entries_transfer_id ON ledger_entries(transfer_id);
CREATE INDEX idx_ledger_entries_account_id ON ledger_entries(account_id, created_at DESC);

-- reconciliation_records table
CREATE TABLE reconciliation_records (
    record_id VARCHAR(64) PRIMARY KEY,
    transfer_id VARCHAR(64) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('REALTIME', 'EOD', 'MONTHLY')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('MATCHED', 'MISMATCHED', 'PENDING', 'RESOLVED')),
    internal_amount DECIMAL(20, 8) NOT NULL,
    bank_amount DECIMAL(20, 8) NOT NULL,
    difference DECIMAL(20, 8) NOT NULL,
    internal_timestamp TIMESTAMP NOT NULL,
    bank_timestamp TIMESTAMP,
    bank_reference_id VARCHAR(100),
    mismatch_reason TEXT,
    resolved_by VARCHAR(64),
    resolved_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reconciliation_records_transfer_id ON reconciliation_records(transfer_id);
CREATE INDEX idx_reconciliation_records_status ON reconciliation_records(status) WHERE status IN ('MISMATCHED', 'PENDING');
CREATE INDEX idx_reconciliation_records_type_date ON reconciliation_records(type, created_at DESC);

-- reconciliation_reports table
CREATE TABLE reconciliation_reports (
    report_id VARCHAR(64) PRIMARY KEY,
    type VARCHAR(20) NOT NULL CHECK (type IN ('REALTIME', 'EOD', 'MONTHLY')),
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    total_transfers INT NOT NULL,
    matched_count INT NOT NULL,
    mismatched_count INT NOT NULL,
    pending_count INT NOT NULL,
    total_amount DECIMAL(20, 8) NOT NULL,
    mismatched_amount DECIMAL(20, 8) NOT NULL,
    generated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reconciliation_reports_type_date ON reconciliation_reports(type, start_date DESC);

-- compliance_checks table
CREATE TABLE compliance_checks (
    check_id VARCHAR(64) PRIMARY KEY,
    transfer_id VARCHAR(64) NOT NULL,
    check_type VARCHAR(20) NOT NULL CHECK (check_type IN ('SAME_NAME', 'AML', 'TRAVEL_RULE', 'KYC_LIMIT')),
    passed BOOLEAN NOT NULL,
    reason TEXT,
    details JSONB,
    checked_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_compliance_checks_transfer_id ON compliance_checks(transfer_id);
CREATE INDEX idx_compliance_checks_type_passed ON compliance_checks(check_type, passed);

-- sanctions_lists table (for AML screening)
CREATE TABLE sanctions_lists (
    list_id VARCHAR(64) PRIMARY KEY,
    list_name VARCHAR(50) NOT NULL CHECK (list_name IN ('OFAC', 'UN', 'EU')),
    entity_name VARCHAR(255) NOT NULL,
    entity_type VARCHAR(20) NOT NULL CHECK (entity_type IN ('INDIVIDUAL', 'ENTITY')),
    country VARCHAR(3),
    added_date DATE NOT NULL,
    description TEXT,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sanctions_lists_entity_name ON sanctions_lists USING gin(to_tsvector('english', entity_name));
CREATE INDEX idx_sanctions_lists_list_name ON sanctions_lists(list_name);

-- transfer_events table (event sourcing)
CREATE TABLE transfer_events (
    event_id VARCHAR(64) PRIMARY KEY,
    transfer_id VARCHAR(64) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    from_status VARCHAR(30),
    to_status VARCHAR(30),
    metadata JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_transfer_events_transfer_id ON transfer_events(transfer_id, created_at);
CREATE INDEX idx_transfer_events_type ON transfer_events(event_type, created_at DESC);

-- Functions and triggers

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_fund_transfers_updated_at
    BEFORE UPDATE ON fund_transfers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_account_balances_updated_at
    BEFORE UPDATE ON account_balances
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Ensure ledger entries are balanced
CREATE OR REPLACE FUNCTION check_ledger_balance()
RETURNS TRIGGER AS $$
DECLARE
    total_debit DECIMAL(20, 8);
    total_credit DECIMAL(20, 8);
BEGIN
    SELECT COALESCE(SUM(debit), 0), COALESCE(SUM(credit), 0)
    INTO total_debit, total_credit
    FROM ledger_entries
    WHERE transfer_id = NEW.transfer_id;

    IF total_debit != total_credit THEN
        RAISE EXCEPTION 'Ledger entries must be balanced: debit=%, credit=%', total_debit, total_credit;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER check_ledger_balance_trigger
    AFTER INSERT ON ledger_entries
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE FUNCTION check_ledger_balance();
