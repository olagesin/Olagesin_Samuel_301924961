-- 2. Create the schema and tables in one transaction.
BEGIN;

CREATE SCHEMA wallet_demo;

CREATE TABLE wallet_demo.customers (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,

    CONSTRAINT pk_customers
        PRIMARY KEY (customer_id),

    CONSTRAINT uq_customers_email
        UNIQUE (email)
);

CREATE TABLE wallet_demo.wallets (
    wallet_id BIGINT GENERATED ALWAYS AS IDENTITY,
    customer_id BIGINT NOT NULL,
    currency CHAR(3) NOT NULL,
    opening_balance NUMERIC(18,2) NOT NULL,
    balance NUMERIC(18,2) NOT NULL,

    CONSTRAINT pk_wallets
        PRIMARY KEY (wallet_id),

    CONSTRAINT fk_wallets_customer
        FOREIGN KEY (customer_id)
        REFERENCES wallet_demo.customers (customer_id),

    CONSTRAINT uq_wallets_customer_currency
        UNIQUE (customer_id, currency),

    CONSTRAINT chk_wallets_currency
        CHECK (currency = 'NGN'),

    CONSTRAINT chk_wallets_opening_balance
        CHECK (opening_balance >= 0),

    CONSTRAINT chk_wallets_balance
        CHECK (balance >= 0)
);

CREATE TABLE wallet_demo.transfers (
    transfer_id BIGINT GENERATED ALWAYS AS IDENTITY,
    request_key TEXT NOT NULL,
    source_wallet_id BIGINT NOT NULL,
    destination_wallet_id BIGINT NOT NULL,
    amount NUMERIC(18,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT pk_transfers
        PRIMARY KEY (transfer_id),

    CONSTRAINT uq_transfers_request_key
        UNIQUE (request_key),

    CONSTRAINT fk_transfers_source_wallet
        FOREIGN KEY (source_wallet_id)
        REFERENCES wallet_demo.wallets (wallet_id),

    CONSTRAINT fk_transfers_destination_wallet
        FOREIGN KEY (destination_wallet_id)
        REFERENCES wallet_demo.wallets (wallet_id),

    CONSTRAINT chk_transfers_positive_amount
        CHECK (amount > 0),

    CONSTRAINT chk_transfers_different_wallets
        CHECK (source_wallet_id <> destination_wallet_id)
);

CREATE TABLE wallet_demo.ledger_entries (
    entry_id BIGINT GENERATED ALWAYS AS IDENTITY,
    transfer_id BIGINT NOT NULL,
    wallet_id BIGINT NOT NULL,
    delta NUMERIC(18,2) NOT NULL,

    CONSTRAINT pk_ledger_entries
        PRIMARY KEY (entry_id),

    CONSTRAINT fk_ledger_entries_transfer
        FOREIGN KEY (transfer_id)
        REFERENCES wallet_demo.transfers (transfer_id),

    CONSTRAINT fk_ledger_entries_wallet
        FOREIGN KEY (wallet_id)
        REFERENCES wallet_demo.wallets (wallet_id),

    CONSTRAINT uq_ledger_entries_transfer_wallet
        UNIQUE (transfer_id, wallet_id),

    CONSTRAINT chk_ledger_entries_nonzero_delta
        CHECK (delta <> 0)
);

COMMIT;