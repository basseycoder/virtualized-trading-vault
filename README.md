# Virtualized Trading Vault Contract

## Overview

This project implements a secure, blockchain-based vault contract designed for managing transactions of virtual collectibles on the Stacks blockchain. It provides a mechanism for vault initialization, transaction completion, and payment refunds, ensuring transparent and reliable transactions between requesters and providers.

### Key Features:
- **Vault Initialization:** A vault is created with a specific provider, item, and payment amount, where the requester deposits the payment.
- **Vault Completion:** A vault can be finalized after verification, releasing payment to the provider upon successful transaction completion.
- **Vault Cancellation:** In case of failed transactions, payment can be returned to the requester.
- **Transaction Tracking:** Each vault is tracked with a unique sequence number to ensure transparency.

---

## Contract Functions

### 1. `initialize-vault`
Initializes a new vault for a trading transaction.

#### Parameters:
- `provider`: The principal address of the provider.
- `item-identifier`: A unique identifier for the item being traded.
- `payment-amount`: The amount of payment for the transaction.

#### Returns:
- A sequence number for the initialized vault.

---

### 2. `complete-vault-transaction`
Completes a vault transaction and releases the payment to the provider.

#### Parameters:
- `sequence`: The vault sequence number.

#### Returns:
- `true` if the transaction is successfully completed.

---

### 3. `return-payment`
Returns the payment to the requester in the case of a canceled or failed transaction.

#### Parameters:
- `sequence`: The vault sequence number.

#### Returns:
- `true` if the payment is successfully returned to the requester.

---

### 4. `get-vault-details`
Retrieves the details of a specific vault transaction.

#### Parameters:
- `sequence`: The vault sequence number.

#### Returns:
- Details of the vault, including its state, requester, provider, item, and payment amount.

---

### 5. `get-latest-sequence`
Retrieves the most recent vault sequence number.

#### Returns:
- The latest sequence number used in the vault system.

---

## System Constants & Error Handling

- **Vault Duration:** Vaults have a default duration of approximately one week (1008 blocks).
- **Error Codes:**
  - `ERR_PERMISSION_DENIED`: Insufficient permissions.
  - `ERR_VAULT_NONEXISTENT`: Vault does not exist.
  - `ERR_ALREADY_FINALIZED`: Vault has already been finalized.
  - `ERR_OPERATION_FAILED`: The operation failed.
  - `ERR_SEQUENCE_INVALID`: Invalid vault sequence.
  - `ERR_PAYMENT_INVALID`: Invalid payment amount.
  - `ERR_PROVIDER_INVALID`: Invalid provider.
  - `ERR_VAULT_EXPIRED`: Vault has expired.

---

## Usage

To deploy and interact with the vault contract, use the Stacks wallet and Stacks.js library.

### Example Steps:
1. Initialize a vault:
   ```javascript
   await contract.call('initialize-vault', [providerPrincipal, itemIdentifier, paymentAmount]);
   ```
2. Complete a vault transaction:
   ```javascript
   await contract.call('complete-vault-transaction', [vaultSequence]);
   ```
3. Return payment for a canceled vault:
   ```javascript
   await contract.call('return-payment', [vaultSequence]);
   ```

---

## Development

- This contract is written in Clarity, the smart contract language for the Stacks blockchain.
- Ensure you have the latest version of the Stacks CLI installed to deploy and interact with the contract.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
```
