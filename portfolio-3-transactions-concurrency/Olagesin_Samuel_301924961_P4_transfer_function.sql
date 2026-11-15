CREATE OR REPLACE FUNCTION wallet_demo.transfer_funds(
    p_key TEXT,
    p_source BIGINT,
    p_destination BIGINT,
    p_amount NUMERIC
)
RETURNS BIGINT
LANGUAGE plpgsql
SET search_path = wallet_demo, pg_temp
AS $$
DECLARE
    v_transfer_id BIGINT;
    v_wallet_count INTEGER;
    v_balance NUMERIC;
    v_existing transfers%ROWTYPE;
BEGIN
    -- Validate the request.
    IF p_key IS NULL
       OR btrim(p_key) = ''
       OR p_source IS NULL
       OR p_destination IS NULL
       OR p_source = p_destination
       OR p_amount IS NULL
       OR p_amount <= 0
       OR p_amount::TEXT IN ('NaN', 'Infinity', '-Infinity')
       OR p_amount <> round(p_amount, 2)
    THEN
        RAISE EXCEPTION 'Invalid transfer input';
    END IF;

    -- Lock both wallets in a consistent order.
    -- Locks remain held until the surrounding transaction ends.
    PERFORM wallet_id
    FROM wallets
    WHERE wallet_id IN (p_source, p_destination)
    ORDER BY wallet_id
    FOR UPDATE;

    GET DIAGNOSTICS v_wallet_count = ROW_COUNT;

    IF v_wallet_count <> 2 THEN
        RAISE EXCEPTION 'Wallet not found';
    END IF;

    -- An identical retry returns the existing transfer.
    SELECT *
    INTO v_existing
    FROM transfers
    WHERE request_key = p_key;

    IF FOUND THEN
        IF v_existing.source_wallet_id <> p_source
           OR v_existing.destination_wallet_id <> p_destination
           OR v_existing.amount <> p_amount
        THEN
            RAISE EXCEPTION 'Request key reused with different details';
        END IF;

        RETURN v_existing.transfer_id;
    END IF;

    -- Check funds after acquiring the locks.
    SELECT balance
    INTO v_balance
    FROM wallets
    WHERE wallet_id = p_source;

    IF v_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;

    INSERT INTO transfers (
        request_key,
        source_wallet_id,
        destination_wallet_id,
        amount
    )
    VALUES (
        p_key,
        p_source,
        p_destination,
        p_amount
    )
    RETURNING transfer_id INTO v_transfer_id;

    UPDATE wallets
    SET balance = balance - p_amount
    WHERE wallet_id = p_source;

    UPDATE wallets
    SET balance = balance + p_amount
    WHERE wallet_id = p_destination;

    INSERT INTO ledger_entries (
        transfer_id,
        wallet_id,
        delta
    )
    VALUES
        (v_transfer_id, p_source, -p_amount),
        (v_transfer_id, p_destination, p_amount);

    RETURN v_transfer_id;
END;
$$;