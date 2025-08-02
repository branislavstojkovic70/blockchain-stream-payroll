// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
using SafeERC20 for IERC20;

interface IStreamingContract {
    struct Stream {
        address recipient;
        address sender;
        uint256 startTime;
        uint256 endTime;
        uint256 totalAmount;
        uint256 withdrawnAmount;
        address tokenAddress;
        bool cancelled;
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

    event StreamCancelled(
        uint256 indexed streamId,
        uint256 recipientBalance,
        uint256 senderBalance
    );

    function createStream(
        address recipient,
        uint256 startTime,
        uint256 endTime
    ) external payable returns (uint256 streamId);

    function withdrawFromStream(uint256 streamId) external;

    function getStream(uint256 streamId) external view returns (Stream memory);

    function calculateWithdrawableAmount(
        uint256 streamId
    ) external view returns (uint256);

    function createTokenStream(
        address recipient,
        address tokenAddress,
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime
    ) external returns (uint256 streamId);

    function cancelStream(uint256 streamId) external;
}

contract StreamContract is
    IStreamingContract,
    ERC721Enumerable,
    ReentrancyGuard
{
    uint256 private nextStreamId;
    mapping(uint256 => Stream) private streams;

    constructor() ERC721("StreamOwnership", "STRM") {}

    modifier onlyRecipient(uint256 streamId) {
        require(
            ownerOf(streamId) == msg.sender,
            StreamContract__NotStreamRecipient()
        );
        _;
    }

    error StreamContract__InvalidRecipient();
    error StreamContract__InvalidToken();
    error StreamContract__InvalidTimeRange();
    error StreamContract__StartInPast();
    error StreamContract__ZeroAmount();
    error StreamContract__NotStreamRecipient();
    error StreamContract__StreamCancelled();
    error StreamContract__NothingToWithdraw();
    error StreamContract__AlreadyCancelled();
    error StreamContract__OnlySenderCanCancel();
    error StreamContract__ETHTransferFailed();

    function createStream(
        address recipient,
        uint256 startTime,
        uint256 endTime
    ) external payable override returns (uint256 streamId) {
        require(recipient != address(0), StreamContract__InvalidRecipient());
        require(endTime > startTime, StreamContract__InvalidTimeRange());
        require(startTime >= block.timestamp, StreamContract__StartInPast());
        require(msg.value > 0, StreamContract__ZeroAmount());

        streamId = nextStreamId++;
        streams[streamId] = Stream({
            recipient: recipient,
            sender: msg.sender,
            startTime: startTime,
            endTime: endTime,
            totalAmount: msg.value,
            withdrawnAmount: 0,
            tokenAddress: address(0),
            cancelled: false
        });

        _safeMint(recipient, streamId);

        emit StreamCreated(
            streamId,
            msg.sender,
            recipient,
            msg.value,
            startTime,
            endTime
        );
    }

    function createTokenStream(
        address recipient,
        address tokenAddress,
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime
    ) external override returns (uint256 streamId) {
        require(recipient != address(0), StreamContract__InvalidRecipient());
        require(tokenAddress != address(0), StreamContract__InvalidToken());
        require(endTime > startTime, StreamContract__InvalidTimeRange());
        require(startTime >= block.timestamp, StreamContract__StartInPast());
        require(totalAmount > 0, StreamContract__ZeroAmount());

        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            totalAmount
        );
        streamId = nextStreamId++;
        streams[streamId] = Stream({
            recipient: recipient,
            sender: msg.sender,
            startTime: startTime,
            endTime: endTime,
            totalAmount: totalAmount,
            withdrawnAmount: 0,
            tokenAddress: tokenAddress,
            cancelled: false
        });

        _mint(recipient, streamId);

        emit StreamCreated(
            streamId,
            msg.sender,
            recipient,
            totalAmount,
            startTime,
            endTime
        );
    }

    function withdrawFromStream(
        uint256 streamId
    ) external override nonReentrant onlyRecipient(streamId) {
        Stream storage s = streams[streamId];
        require(!s.cancelled, StreamContract__StreamCancelled());

        uint256 amount = calculateWithdrawableAmount(streamId);
        require(amount > 0, StreamContract__NothingToWithdraw());

        s.withdrawnAmount += amount;

        if (s.tokenAddress == address(0)) {
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, StreamContract__ETHTransferFailed());
        } else {
            IERC20(s.tokenAddress).safeTransfer(msg.sender, amount);
        }

        emit Withdrawal(streamId, msg.sender, amount);
    }

    function cancelStream(uint256 streamId) external override nonReentrant {
        Stream storage s = streams[streamId];
        require(!s.cancelled, StreamContract__AlreadyCancelled());
        require(msg.sender == s.sender, StreamContract__OnlySenderCanCancel());

        uint256 recipientAmount = calculateWithdrawableAmount(streamId);
        uint256 senderRefund = s.totalAmount - recipientAmount;

        s.cancelled = true;
        s.withdrawnAmount = s.totalAmount;

        address recipient = ownerOf(streamId);

        if (s.tokenAddress == address(0)) {
            if (recipientAmount > 0) {
                (bool ok, ) = payable(recipient).call{value: recipientAmount}(
                    ""
                );
                require(ok, StreamContract__ETHTransferFailed());
            }
            if (senderRefund > 0) {
                (bool ok, ) = payable(s.sender).call{value: senderRefund}("");
                require(ok, StreamContract__ETHTransferFailed());
            }
        } else {
            if (recipientAmount > 0) {
                IERC20(s.tokenAddress).safeTransfer(recipient, recipientAmount);
            }
            if (senderRefund > 0) {
                IERC20(s.tokenAddress).safeTransfer(s.sender, senderRefund);
            }
        }

        emit StreamCancelled(streamId, recipientAmount, senderRefund);
    }

    function getStream(
        uint256 streamId
    ) external view override returns (Stream memory) {
        return streams[streamId];
    }

    function calculateWithdrawableAmount(
        uint256 streamId
    ) public view override returns (uint256) {
        Stream storage s = streams[streamId];
        if (block.timestamp <= s.startTime || s.cancelled) return 0;

        uint256 end = block.timestamp > s.endTime ? s.endTime : block.timestamp;
        uint256 elapsed = end - s.startTime;
        uint256 unlocked = (s.totalAmount * elapsed) /
            (s.endTime - s.startTime); //amount * elapsed time / maxDuration
        if (unlocked <= s.withdrawnAmount) return 0;

        return unlocked - s.withdrawnAmount;
    }
}
