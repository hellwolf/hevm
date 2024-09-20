// SPDX-License-Identifier: MIT
// contributed by @karmacoma on 5 Aug 2023

pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

// inspired by the classic reentrancy level in Ethernaut CTF
contract BadVault {
    mapping(address => uint256) public balance;

    function deposit() external payable {
        balance[msg.sender] += msg.value;

        // console2.log("deposit", msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        // checks
        uint256 _balance = balance[msg.sender];
        require(_balance >= amount, "insufficient balance");

        // console2.log("withdraw", msg.sender, amount);

        // interactions
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "transfer failed");

        // effects
        balance[msg.sender] = _balance - amount;
    }
}

// from https://github.com/mds1/multicall
struct Call3Value {
    address target;
    uint256 value;
    bytes4 sig;
    bytes32 data;
}

contract ExploitLaunchPad {
    address public owner;
    bool reentered;

    Call3Value public call;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        if (reentered) {
            return;
        }

        require(call.value <= address(this).balance, "insufficient balance");

        reentered = true;
        (bool success,) = call.target.call{value: call.value}(abi.encodePacked(call.sig, call.data));
        reentered = false;
    }

    function defer(Call3Value calldata _call) external payable {
        require(msg.sender == owner, "only owner");
        call = _call;
    }

    function go(Call3Value calldata _call)
        external
        payable
    {
        require(msg.sender == owner, "only owner");
        require(_call.value <= address(this).balance, "insufficient balance");

        (bool success,) = _call.target.call{value: _call.value}(abi.encodePacked(_call.sig, _call.data));
    }

    function deposit() external payable {}

    function withdraw() external {
        owner.call{value: address(this).balance}("");
    }
}

contract BadVaultTest is Test {
    BadVault vault;
    ExploitLaunchPad exploit;

    address user1;
    address user2;
    address attacker;

    function setUp() public {
        vault = new BadVault();

        user1 = address(1);
        user2 = address(2);

        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vault.deposit{value: 1 ether}();

        vm.deal(user2, 1 ether);
        vm.prank(user2);
        vault.deposit{value: 1 ether}();

        attacker = address(42);
        vm.prank(attacker);
        exploit = new ExploitLaunchPad();

        assert(exploit.owner() == attacker);
        console2.log("HI");
        console2.log(exploit.owner());
        console2.log(attacker);
    }

    /// @custom:halmos --array-lengths data1=36,data2=36,deferredData=36
    function test_prove_BadVault_usingExploitLaunchPad(
        address target1,
        uint256 amount1,
        bytes4 sig1,
        bytes32 data1,

        address target2,
        uint256 amount2,
        bytes4 sig2,
        bytes32 data2,

        address deferredTarget,
        uint256 deferredAmount,
        bytes4 deferredSig,
        bytes32 deferredData

    ) public {
        uint256 STARTING_BALANCE = 2 ether;
        vm.deal(attacker, STARTING_BALANCE);

        vm.assume(address(exploit).balance == 0);
        vm.assume((amount1 + amount2) <= STARTING_BALANCE);

        // console2.log("attacker starting balance", address(attacker).balance);
        vm.prank(attacker);
        exploit.deposit{value: STARTING_BALANCE}();

        vm.prank(attacker);
        exploit.go(Call3Value({
            target: target1,
            value: amount1,
            sig: sig1,
            data: data1
        }));

        vm.prank(attacker);
        exploit.defer(Call3Value({
            target: deferredTarget,
            value: deferredAmount,
            sig: deferredSig,
            data: deferredData
        }));

        vm.prank(attacker);
        exploit.go(Call3Value({
            target: target2,
            value: amount2,
            sig: sig2,
            data: data2
        }));

        vm.prank(attacker);
        exploit.withdraw();

        // they can not end up with more ether than they started with
        // console2.log("attacker final balance", address(attacker).balance);
        assert(attacker.balance <= STARTING_BALANCE);
    }
}
