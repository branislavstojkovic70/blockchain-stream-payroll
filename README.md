# Robinhood Streaming Payroll – Smart Contract System
<img src="./web3-kamp.png" style="width:100%; height:auto;">

## Overview

This project implements a streaming payroll system for Robinhood's Layer-2 blockchain network. The system enables continuous, real-time salary payments to employees, replacing traditional fixed-cycle payments with a more transparent and flexible solution.

The implementation is divided into three progressive phases:

- **Phase 1**: ETH-based salary streams  
- **Phase 2**: ERC-20 token support and stream cancellation  
- **Phase 3**: Tokenized streams as tradable ERC-721 NFTs

Each phase builds upon the previous, introducing enhanced functionality and extensibility.



## Technology Stack

| Tool/Language      | Purpose                              |
|--------------------|--------------------------------------|
| **Solidity**       | Smart contract development           |
| **Hardhat**        | Ethereum development framework       |
| **Foundry**        | High-performance testing & CLI tools |
| **TypeScript**     | Hardhat scripting and configuration  |
| **Node.js**        | JavaScript runtime for Hardhat       |
| **Rust**           | Required for installing Foundry      |

> Make sure both `Node.js` and `Rust` toolchains are installed before proceeding.

---

## Setup Instructions

### 1. Clone and Install Dependencies

```bash
git clone <repository-url>
cd robinhood-streaming-payroll/contracts
npm install
````

### 2. Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

---

## Usage

### Local Development (Requires Two Terminals)

**Terminal 1 – Start Local Ethereum Node:**

```bash
make localnet
```

**Terminal 2 – Compile & Deploy Contracts:**

```bash
make deploy
```

**Run Tests (Foundry):**

```bash
forge test -vvvv
```

---

## Makefile Commands

| Command         | Description                            |
| --------------- | -------------------------------------- |
| `make compile`  | Compiles contracts using Hardhat       |
| `make localnet` | Starts a local Hardhat node            |
| `make deploy`   | Deploys contracts to the local network |

---

## Project Structure

```
contracts/
├── contracts/             # Solidity smart contracts
├── test/                  # Hardhat and Foundry tests
├── tasks/                 # Custom Hardhat tasks
├── artifacts/, cache/     # Build artifacts (excluded from version control)
├── hardhat.config.ts      # Hardhat configuration
├── foundry.toml           # Foundry configuration
└── Makefile               # Build and deploy automation
```

---

## Phase Descriptions

### Phase 1 – ETH Streaming

* Create ETH-based streams with start and end times.
* Recipients can withdraw funds linearly over time.
* Streams are immutable once created.

### Phase 2 – Token Streaming & Cancellation

* Adds support for ERC-20 token streams.
* Allows stream cancellation by the sender.
* Ensures fair allocation of remaining balances.

### Phase 3 – NFT-Based Streams

* Streams are minted as ERC-721 NFTs.
* The stream recipient is dynamically bound to the current NFT owner.
* Enables secondary trading of active streams.

---

## Security Considerations

* ✅ Reentrancy protection on withdrawals
* ✅ Access control on stream creation and cancellation
* ✅ Safe handling of ETH and ERC-20 transfers
* ✅ Overflow/underflow checks
* ✅ Time validation on stream parameters

