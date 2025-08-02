# Workshop Task: Smart Contract Development for Robinhood's Streaming Payroll

## Background

Robinhood, the financial services company that recently expanded into blockchain with their own Layer-2 network, wants to implement a streaming payment solution for their employees. As part of their commitment to blockchain innovation, they've decided to pilot a new payroll system that distributes salaries continuously over time rather than in traditional monthly cycles.

This system will enable real-time salary payments and transparent vesting schedules for employee compensation packages.

## Your Mission

You'll build a streaming smart contract system in **three progressive phases**:
- **Phase 1**: Basic ETH streaming (start here!)
- **Phase 2**: Add ERC-20 token support and cancellation
- **Phase 3**: Make streams tradeable with NFTs

**Important**: Start with Phase 1 and only move to the next phase after completing the previous one!

---

## Phase 1: Basic ETH Streaming 🌊

### What You'll Build
A simple contract that streams ETH payments over time. Think of it like a digital hourglass where ETH flows from sender to recipient continuously.

### Requirements
1. **Create a stream** with:
   - Who gets paid (recipient)
   - When payment starts
   - When payment ends
   - How much ETH (sent with the transaction)

2. **Recipients can**:
   - Check how much they can withdraw
   - Withdraw their accumulated ETH

3. **Important**: No cancellation in Phase 1! Once created, streams run to completion.

### Interface for Phase 1

```solidity
pragma solidity 0.8.26;

interface IStreamingContractV1 {
    struct Stream {
        address recipient;
        address sender;
        uint256 startTime;
        uint256 endTime;
        uint256 totalAmount;
        uint256 withdrawnAmount;
    }

    event StreamCreated(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime
    );
    
    event Withdrawal(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount
    );

    // Create a new ETH stream (totalAmount comes from msg.value)
    function createStream(
        address recipient,
        uint256 startTime,
        uint256 endTime
    ) external payable returns (uint256 streamId);

    // Withdraw available funds from a stream
    function withdrawFromStream(uint256 streamId) external;

    // View stream details
    function getStream(uint256 streamId) external view returns (Stream memory);

    // Check withdrawable amount
    function calculateWithdrawableAmount(uint256 streamId) external view returns (uint256);
}
```

### Implementation Tips for Phase 1
1. **Stream Creation**:
   - Check that `endTime > startTime`
   - Check that `startTime >= block.timestamp` (no past streams)
   - Use `msg.value` as the total amount
   - Store the stream and emit event

2. **Withdrawal Logic**:
   - Check if we're past `startTime`
   - Calculate how much time has passed
   - Calculate unlocked amount
   - Subtract already withdrawn amount
   - Transfer ETH and update withdrawn amount

### Example Scenario
Bob invoices Robinhood for 10 ETH. Instead of paying immediately, they create a 3-month stream. Bob can withdraw his accumulated ETH anytime during those 3 months.

---

## Phase 2: Token Support & Cancellation 💰

**Only start this after completing Phase 1!**

### What's New?
- Support for ERC-20 tokens (USDC, USDT, etc.)
- Ability to cancel streams

### Additional Requirements
1. **Token streams**: Accept any ERC-20 token, not just ETH
2. **Cancellation**: 
   - Only sender can cancel
   - Recipient gets what they've earned so far
   - Sender gets back the rest

### Extended Interface for Phase 2

```solidity
// Add these to your existing interface:

struct Stream {
    // ... previous fields ...
    address tokenAddress; // address(0) for ETH
    bool cancelled;
}

event StreamCancelled(
    uint256 indexed streamId,
    uint256 recipientBalance,
    uint256 senderBalance
);

// Create a stream with ERC-20 tokens
function createTokenStream(
    address recipient,
    address tokenAddress,
    uint256 totalAmount,
    uint256 startTime,
    uint256 endTime
) external returns (uint256 streamId);

// Cancel a stream (only sender can call)
function cancelStream(uint256 streamId) external;
```

### Implementation Tips for Phase 2
1. **Token Handling**:
   - Use `IERC20(token).transferFrom()` to receive tokens
   - Sender must approve contract first!
   - Handle both ETH and token withdrawals

2. **Cancellation**:
   - Calculate streamed vs unstreamed amounts
   - Send streamed portion to recipient
   - Return unstreamed portion to sender

### Example Scenario
Alice has a $120,000 annual salary paid in USDC. A 1-year stream is created. If she leaves after 6 months, the stream is cancelled - she gets $60,000 and the company gets back $60,000.

---

## Phase 3: NFT Trading (Advanced) 🎨

**Only start this after completing Phase 2!**

### What's New?
Streams become NFTs that can be bought and sold!

### Additional Requirements
1. Each stream is an ERC-721 NFT
2. Whoever owns the NFT receives the stream payments
3. Streams can be traded on NFT marketplaces

### Extended Interface for Phase 3

```solidity
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IStreamingContractV3 is IERC721 {
    // All previous functions remain
    // ERC-721 functions are inherited
    // Override transferFrom to update stream recipient
}
```

### Implementation Tips for Phase 3
1. **NFT Integration**:
   - Mint an NFT when creating a stream
   - Use streamId as tokenId
   - Update recipient when NFT is transferred

2. **Transfer Logic**:
   - Override `_transfer` to update stream recipient
   - Ensure withdrawals go to current NFT owner

### Example Scenario
Charlie has a 4-year HOOD token vesting stream. After 2 years, he needs cash and sells his stream NFT. The buyer gets the remaining 2 years of vesting.

---

## Testing Your Contract

### Phase 1 Tests
```solidity
// Test stream creation
// Test withdrawal calculations
// Test multiple withdrawals
// Test can't withdraw before start time
```

### Phase 2 Tests
```solidity
// Test token streams
// Test cancellation by sender
// Test cancellation calculations
// Test non-sender can't cancel
```

### Phase 3 Tests
```solidity
// Test NFT minting
// Test stream transfer updates recipient
// Test new owner can withdraw
```

## Security Checklist

- [ ] Reentrancy protection on withdrawals
- [ ] Integer overflow/underflow checks
- [ ] Access control (who can cancel?)
- [ ] Proper token handling
- [ ] Time validation

## Good luck!
Start with Phase 1 and build up! Good luck building the future of continuous payments!