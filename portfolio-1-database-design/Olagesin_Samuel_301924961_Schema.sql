-- Run only against a dedicated portfolio database. Deletes the demo schema.
DROP SCHEMA IF EXISTS wallet_demo CASCADE;
CREATE SCHEMA wallet_demo;
SET search_path TO wallet_demo;
CREATE TABLE customers (
 customer_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 full_name text NOT NULL,
 email text NOT NULL UNIQUE
);
CREATE TABLE wallets (
 wallet_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 customer_id bigint NOT NULL REFERENCES customers,
 currency char(3) NOT NULL CHECK (currency = 'NGN'),
 opening_balance numeric(18,2) NOT NULL CHECK (opening_balance >= 0),
 balance numeric(18,2) NOT NULL CHECK (balance >= 0),
 UNIQUE(customer_id, currency)
);
CREATE TABLE transfers (
 transfer_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 request_key text NOT NULL UNIQUE,
 source_wallet_id bigint NOT NULL REFERENCES wallets,
 destination_wallet_id bigint NOT NULL REFERENCES wallets,
 amount numeric(18,2) NOT NULL CHECK (amount > 0),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK (source_wallet_id <> destination_wallet_id)
);
CREATE TABLE ledger_entries (
 entry_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 transfer_id bigint NOT NULL REFERENCES transfers,
 wallet_id bigint NOT NULL REFERENCES wallets,
 delta numeric(18,2) NOT NULL CHECK (delta <> 0),
 UNIQUE(transfer_id, wallet_id)
);
-- Controlled write path. Direct table writes remain possible for the demo owner;
-- a production application role must receive function execution only.
CREATE FUNCTION transfer_funds(p_key text, p_source bigint, p_destination bigint,
 p_amount numeric) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE v_id bigint; v_count integer; v_balance numeric; v_existing transfers%ROWTYPE;
BEGIN
 IF p_key IS NULL OR btrim(p_key) = '' OR p_amount IS NULL OR p_amount <= 0
 OR p_amount <> round(p_amount,2) OR p_source = p_destination
 OR p_source IS NULL OR p_destination IS NULL THEN
  RAISE EXCEPTION 'Invalid transfer input';
 END IF;
 -- Stable order prevents opposite-direction transfers locking wallets oppositely.
 PERFORM wallet_id FROM wallets WHERE wallet_id IN(p_source,p_destination)
 ORDER BY wallet_id FOR UPDATE;
 GET DIAGNOSTICS v_count = ROW_COUNT;
 IF v_count <> 2 THEN RAISE EXCEPTION 'Wallet not found'; END IF;
 SELECT * INTO v_existing FROM transfers WHERE request_key = p_key;
 IF FOUND THEN
  IF v_existing.source_wallet_id <> p_source OR v_existing.destination_wallet_id <> p_destination
   OR v_existing.amount <> p_amount THEN RAISE EXCEPTION 'Idempotency key payload conflict'; END IF;
  RETURN v_existing.transfer_id;
 END IF;
 SELECT balance INTO v_balance FROM wallets WHERE wallet_id=p_source;
 IF v_balance < p_amount THEN RAISE EXCEPTION 'Insufficient funds'; END IF;
 INSERT INTO transfers(request_key,source_wallet_id,destination_wallet_id,amount)
 VALUES(p_key,p_source,p_destination,p_amount) RETURNING transfer_id INTO v_id;
 UPDATE wallets SET balance=balance-p_amount WHERE wallet_id=p_source;
 UPDATE wallets SET balance=balance+p_amount WHERE wallet_id=p_destination;
 INSERT INTO ledger_entries(transfer_id,wallet_id,delta)
 VALUES(v_id,p_source,-p_amount),(v_id,p_destination,p_amount);
 RETURN v_id;
END $$;
