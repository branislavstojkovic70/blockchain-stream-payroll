// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../contracts/StreamPay.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("TestToken", "TTK") {
        _mint(msg.sender, 1_000_000 ether);
    }
}

contract StreamContractTest is Test {
    StreamContract public streamContract;
    TestToken public token;

    address sender = address(0xA1);
    address recipient = address(0xB2);

    function setUp() public {
        vm.deal(sender, 100 ether);
        streamContract = new StreamContract();
        token = new TestToken();

        token.transfer(sender, 100_000 ether);
    }

    function testCreateETHStream() public {
        vm.prank(sender);
        uint256 start = block.timestamp + 1 hours;
        uint256 end = start + 1 days;

        uint256 streamId = streamContract.createStream{value: 10 ether}(
            recipient,
            start,
            end
        );

        IStreamingContract.Stream memory s = streamContract.getStream(streamId);
        assertEq(s.recipient, recipient);
        assertEq(s.startTime, start);
        assertEq(s.totalAmount, 10 ether);
        assertEq(s.tokenAddress, address(0));
    }

    function test_RevertWhen_RecipientIsZeroAddress() public {
        vm.expectRevert();
        vm.prank(sender);
        streamContract.createStream{value: 1 ether}(
            address(0),
            block.timestamp + 1,
            block.timestamp + 2
        );
    }

    function test_RevertWhen_EndTimeBeforeStartTime() public {
        vm.expectRevert();
        vm.prank(sender);
        streamContract.createStream{value: 1 ether}(
            recipient,
            block.timestamp + 2,
            block.timestamp + 1
        );
    }

    function testCreateTokenStream() public {
        vm.startPrank(sender);
        token.approve(address(streamContract), 100 ether);
        uint256 start = block.timestamp + 1 hours;
        uint256 end = start + 1 days;

        uint256 streamId = streamContract.createTokenStream(
            recipient,
            address(token),
            100 ether,
            start,
            end
        );
        vm.stopPrank();

        IStreamingContract.Stream memory s = streamContract.getStream(streamId);
        assertEq(s.recipient, recipient);
        assertEq(s.startTime, start);
        assertEq(s.totalAmount, 100 ether);
        assertEq(s.tokenAddress, address(token));
    }

    function testWithdrawETHStream() public {
        vm.startPrank(sender);
        uint256 start = block.timestamp;
        uint256 end = start + 1 days;

        uint256 streamId = streamContract.createStream{value: 12 ether}(
            recipient,
            start,
            end
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 12 hours);
        uint256 balanceBefore = recipient.balance;

        vm.prank(recipient);
        streamContract.withdrawFromStream(streamId);

        uint256 balanceAfter = recipient.balance;
        assertApproxEqAbs(balanceAfter - balanceBefore, 6 ether, 1e14);
    }

    function testWithdrawTokenStream() public {
        vm.startPrank(sender);
        token.approve(address(streamContract), 100 ether);
        uint256 start = block.timestamp;
        uint256 end = start + 2 days;

        uint256 streamId = streamContract.createTokenStream(
            recipient,
            address(token),
            100 ether,
            start,
            end
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);
        vm.prank(recipient);
        streamContract.withdrawFromStream(streamId);

        assertApproxEqAbs(token.balanceOf(recipient), 50 ether, 1e14);
    }

    function testCancelETHStream() public {
        vm.prank(sender);
        uint256 start = block.timestamp;
        uint256 end = start + 1 days;

        uint256 streamId = streamContract.createStream{value: 20 ether}(
            recipient,
            start,
            end
        );

        vm.warp(block.timestamp + 6 hours);

        vm.prank(sender);
        streamContract.cancelStream(streamId);

        uint256 recipientBalance = recipient.balance;
        uint256 senderBalance = sender.balance;

        assertGt(recipientBalance, 0);
        assertGt(senderBalance, 0);
    }

    function test_RevertWhen_NonSenderCancelsStream() public {
        vm.prank(sender);
        uint256 streamId = streamContract.createStream{value: 5 ether}(
            recipient,
            block.timestamp,
            block.timestamp + 1 days
        );

        vm.expectRevert();
        vm.prank(recipient);
        streamContract.cancelStream(streamId);
    }

    function test_RevertWhen_WithdrawBeforeStartTime() public {
        vm.startPrank(sender);
        uint256 start = block.timestamp + 1 days;
        uint256 end = start + 1 days;
        uint256 streamId = streamContract.createStream{value: 5 ether}(
            recipient,
            start,
            end
        );
        vm.stopPrank();

        vm.expectRevert();
        vm.prank(recipient);
        streamContract.withdrawFromStream(streamId);
    }

function testCancelTokenStream() public {
    vm.startPrank(sender);
    token.approve(address(streamContract), 200 ether);
    
    uint256 start = block.timestamp + 1;
    uint256 end = start + 2 days;
    uint256 streamId = streamContract.createTokenStream(
        recipient,
        address(token),
        200 ether,
        start,
        end
    );

    vm.warp(start + 1 days);
    vm.stopPrank();

    uint256 recipientBefore = token.balanceOf(recipient);
    uint256 senderBefore = token.balanceOf(sender);

    vm.prank(sender);
    streamContract.cancelStream(streamId);

    uint256 recipientAfter = token.balanceOf(recipient);
    uint256 senderAfter = token.balanceOf(sender);

    uint256 recipientDelta = recipientAfter - recipientBefore;
    uint256 senderDelta = senderAfter - senderBefore;

    assertEq(recipientDelta + senderDelta, 200 ether);
}

}
