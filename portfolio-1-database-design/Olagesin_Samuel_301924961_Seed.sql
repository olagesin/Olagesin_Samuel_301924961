SET search_path TO wallet_demo;
INSERT INTO customers(full_name,email)
SELECT 'Demo Customer '||g, 'customer'||g||'@example.test' FROM generate_series(1,1000) g;
INSERT INTO wallets(customer_id,currency,opening_balance,balance)
SELECT customer_id,'NGN',1000000,1000000 FROM customers;
-- Synthetic transfer history with matching ledger entries and reconciled balances.
INSERT INTO transfers(request_key,source_wallet_id,destination_wallet_id,amount,created_at)
SELECT 'seed-'||g, (g%1000)+1, ((g+1)%1000)+1, ((g%100)+1)::numeric,
 timestamptz '2026-01-01 00:00:00+00' + g*interval '1 second'
FROM generate_series(1,200000) g;
INSERT INTO ledger_entries(transfer_id,wallet_id,delta)
SELECT transfer_id,source_wallet_id,-amount FROM transfers
UNION ALL SELECT transfer_id,destination_wallet_id,amount FROM transfers;
UPDATE wallets w SET balance=w.opening_balance+a.total
FROM (SELECT wallet_id,sum(delta) total FROM ledger_entries GROUP BY wallet_id) a
WHERE w.wallet_id=a.wallet_id;
ANALYZE;
