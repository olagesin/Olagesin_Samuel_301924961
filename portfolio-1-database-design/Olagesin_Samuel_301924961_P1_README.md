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

## 5. Identified Entities and Attributes

### Customer
Represents a person registered on the platform.

| Attribute | Purpose |
|---|---|
| customer_id | Unique customer identifier |
| full_name | Customer's name |
| email | Unique customer email address |

### Wallet
Represents a customer's NGN wallet.

| Attribute | Purpose |
|---|---|
| wallet_id | Unique wallet identifier |
| customer_id | Identifies the wallet owner |
| currency | Currency supported by the wallet |
| opening_balance | Funds held at the start of the demonstration |
| balance | Current available balance |

### Transfer
Represents a completed movement of money between two wallets.

| Attribute | Purpose |
|---|---|
| transfer_id | Unique transfer identifier |
| request_key | Identifies a transfer request and its retries |
| source_wallet_id | Wallet sending the money |
| destination_wallet_id | Wallet receiving the money |
| amount | Amount transferred |
| created_at | Date and time of the transfer |

Only completed transfers are retained in this initial model.
Failed attempts and pending transfer workflows are outside its scope.

### Ledger Entry
Represents the signed movement of money in one wallet.

| Attribute | Purpose |
|---|---|
| entry_id | Unique ledger entry identifier |
| transfer_id | Transfer that produced the entry |
| wallet_id | Wallet affected by the entry |
| delta | Negative for a debit; positive for a credit |

A transfer of NGN 500 produces:
- A ledger entry of -500 for the source wallet.
- A ledger entry of +500 for the destination wallet.

## 6. Relationships and Cardinalities

| Relationship | Cardinality |
|---|---|
| Customer to Wallet | One customer has zero or one wallet in the NGN-only scope |
| Wallet to outgoing Transfer | One wallet has zero or many outgoing transfers |
| Wallet to incoming Transfer | One wallet has zero or many incoming transfers |
| Transfer to Ledger Entry | One completed transfer produces exactly two entries |
| Wallet to Ledger Entry | One wallet has zero or many ledger entries |

Each wallet belongs to exactly one customer.
Each transfer has exactly one source and one destination wallet.
Each ledger entry belongs to exactly one transfer and one wallet.

The "exactly two ledger entries" rule is a business invariant.
A foreign key alone cannot enforce it.

## 7. Entity Relationship Diagram

![SwiftWallet entity relationship diagram](Olagesin_Samuel_301924961_ER_Diagram.png)

The diagram shows the four entities, their key attributes
and their relationships.

The source and destination relationships between Wallet and
Transfer represent different roles played by the same entity.

The transfer-to-ledger relationship represents the business
requirement for exactly two entries per completed transfer.
Its implementation requires controlled transactional writes;
foreign keys only establish valid references.