SET search_path TO wallet_demo;
CREATE INDEX IF NOT EXISTS ix_transfers_source_recent
ON transfers(source_wallet_id,created_at DESC,transfer_id DESC);
ANALYZE transfers;
