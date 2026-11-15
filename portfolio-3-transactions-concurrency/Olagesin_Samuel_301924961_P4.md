# Portfolio 3: Transactions and Concurrency

## 1. Objective

This portfolio demonstrates how SwiftWallet applies transfers
atomically and protects wallet balances during concurrent requests.

The PostgreSQL database from the previous portfolios is reused.

## 2. Transfer Rules

A successful transfer must:

- Use two different wallets.
- Have a positive amount with no more than two decimal places.
- Have sufficient funds in the source wallet.
- Debit the source and credit the destination by the same amount.
- Create two balanced ledger entries.
- Avoid moving money twice for an identical request key.

All changes must commit together or be rolled back together.

## 3. Planned Demonstrations

1. Commit a transfer and verify the resulting balances and records.
2. Roll back a transfer and verify that its changes are discarded.
3. Use two database sessions to demonstrate lock contention
   and prevent overspending.

SQL scripts and screenshots will accompany each demonstration.