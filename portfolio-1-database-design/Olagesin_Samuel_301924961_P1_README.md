# Portfolio 1: Database Design and Modelling

## 1. Introduction

This portfolio documents the design and implementation of a PostgreSQL
database for SwiftWallet, a simulated digital wallet platform.

The design begins with business requirements, followed by entity
identification, relationship modelling, schema implementation,
normalisation and validation.

## 2. Selected Case Study

### Organisation
SwiftWallet is a simulated fintech platform that allows customers
to hold money in wallets and transfer funds to other customers.

### Database Users
- Customers: view balances, make transfers and view transaction history.
- Support staff: investigate enquiries and locate transfers.
- Finance staff: review ledger entries and reconcile balances.
- Administrators: manage authorised database access.

### Major Data
The database will store customer details, wallets, transfers
and ledger entries.

### Key Operations
1. Register a customer.
2. Create a wallet for a customer.
3. Retrieve a wallet balance.
4. Transfer money between wallets.
5. Retrieve transaction history.
6. Record the debit and credit associated with a transfer.
7. Reconcile wallet balances against ledger entries.

## 3. Business Rules

- Each customer must have a unique email address.
- Each customer may have at most one NGN wallet.
- Every wallet must belong to a customer.
- Transfers must involve two different wallets.
- Transfer amounts must be positive and expressed to at most
  two decimal places.
- A wallet must have sufficient funds before a transfer is completed.
- A successful transfer must debit and credit the same amount.
- A failed transfer must not leave partial changes.
- Repeating an identical transfer request must not move money twice.

## 4. Scope and Assumptions

The initial system supports NGN transfers within SwiftWallet.

External bank transfers, card payments, fees, foreign currencies
and identity verification are outside the scope.

All data will be synthetic. Wallets will receive opening balances
representing funds held at the start of the demonstration.
Deposit processing is outside the initial scope.

Customer-facing and staff-facing applications are not implemented
in this portfolio.