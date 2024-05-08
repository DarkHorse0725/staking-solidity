// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {VmSafe} from "forge-std/Vm.sol";

import "./mocks/PAIDToken.sol";
import "../src/contracts/SPAID.sol";

contract SPAIDTest is Test {
    PAIDToken public paidToken;
    SPAID public stakedPAID;

    address public owner;

    VmSafe.Wallet public treasury;
    VmSafe.Wallet public alice;
    VmSafe.Wallet public bob;

    function setUp() public {
        console.log("Setting up...");
        owner = address(this);

        paidToken = new PAIDToken();

        treasury = vm.createWallet("Treasury");
        alice = vm.createWallet("Alice");
        bob = vm.createWallet("Bob");

        console.log("Treasury Wallet address is ", treasury.addr);

        stakedPAID = new SPAID(address(paidToken), treasury.addr, 2);
    }

    function testConstructorBadPaidTokenAddress() public {
        bytes4 selector = bytes4(keccak256("ZeroAddressNotAllowed()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        new SPAID(address(0), treasury.addr, 2);
    }

    function testConstructorBadTreasuryAddress() public {
        bytes4 selector = bytes4(keccak256("ZeroAddressNotAllowed()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        new SPAID(address(paidToken), address(0), 2);
    }

    function testConstructorBadTaxLowerLimit() public {
        bytes4 selector = bytes4(keccak256("InvalidTaxAmount()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        new SPAID(address(paidToken), treasury.addr, 0);
    }

    function testConstructorBadTaxUpperLimit() public {
        bytes4 selector = bytes4(keccak256("InvalidTaxAmount()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        new SPAID(address(paidToken), treasury.addr, 11);
    }

    function testSetTaxAsOwner() public {
        stakedPAID.setTax(5);
        assertEq(stakedPAID.tax(), 5);
    }

    function testSetTaxNotOwner() public {
        vm.prank(alice.addr);
        bytes4 selector = bytes4(keccak256("Unauthorized()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        stakedPAID.setTax(5);
    }

     function testSetTaxLowerLimit() public {
        bytes4 selector = bytes4(keccak256("InvalidTaxAmount()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        stakedPAID.setTax(0);
    }

     function testSetTaxUpperLimit() public {
        bytes4 selector = bytes4(keccak256("InvalidTaxAmount()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        stakedPAID.setTax(11);
    }

    function testSetTreasuryAsOwner() public {
        stakedPAID.setTreasury(bob.addr);
        assertEq(stakedPAID.treasury(), bob.addr);
    }

    function testSetTreasuryNotOwner() public {
        vm.prank(alice.addr);
        bytes4 selector = bytes4(keccak256("Unauthorized()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        stakedPAID.setTreasury(alice.addr);
    }

     function testSetTreasuryZeroAddress() public {
        bytes4 selector = bytes4(keccak256("ZeroAddressNotAllowed()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        stakedPAID.setTreasury(address(0));
    }

    function testGetTokenName() public {
        assertEq(stakedPAID.name(), "Staked PAID");
    }

    function testGetTokenSymbol() public {
        assertEq(stakedPAID.symbol(), "sPAID");
    }

    function testDespositWithInvalidAmountRevert() public {
        bytes4 selector = bytes4(keccak256("InvalidAmount()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        stakedPAID.deposit(0);
    }

     function testDespositWithInsufficientPAIDBalanceRevert() public {
        vm.prank(bob.addr);
        bytes4 selector = bytes4(keccak256("InsufficientPAIDBalance()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        stakedPAID.deposit(75000);
    }

    function testDepositWithProperAllowance() public {
        //  Approve the total amount of 75000 plus the 2% tax
        paidToken.approve(address(stakedPAID), 76500000000000000000000);
        //  Stake 75000 PAID
        stakedPAID.deposit(75000000000000000000000);

        //  Treasury should have 1500 PAID
        assertEq(paidToken.balanceOf(treasury.addr), 1500000000000000000000);
        //  User should have 75000 sPAID
        assertEq(stakedPAID.balanceOf(owner), 75000000000000000000000);
    }

     function testWithdrawInvalidAmountRevert() public {
        bytes4 selector = bytes4(keccak256("InvalidAmount()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        stakedPAID.withdraw(0);
    }

     function testWithdrawInsufficientPAIDBalanceRevert() public {
        bytes4 selector = bytes4(keccak256("InsufficientPAIDBalance()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        stakedPAID.withdraw(75000);
    }

    function testWithdraw() public {
        paidToken.approve(address(stakedPAID), 76500000000000000000000);
        //  Stake 75000 PAID
        stakedPAID.deposit(75000000000000000000000);

        stakedPAID.withdraw(75000000000000000000000);

        assertEq(paidToken.balanceOf(owner), 499997000000000000000000000);
        assertEq(stakedPAID.balanceOf(owner), 0);
        assertEq(paidToken.balanceOf(treasury.addr), 3000000000000000000000);
    }

    function testWithdrawAllStakedNotOwner() public {
        vm.prank(alice.addr);
        bytes4 selector = bytes4(keccak256("Unauthorized()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        stakedPAID.withdrawAllStaked();
    }

    function testWithdrawAllStakedWithZeroBalance() public {
        bytes4 selector = bytes4(keccak256("InsufficientPAIDBalance()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        stakedPAID.withdrawAllStaked();
    }

    function testWithdrawAllStakedWithBalance() public {
        paidToken.approve(address(stakedPAID), 76500000000000000000000);
        //  Stake 75000 PAID
        stakedPAID.deposit(75000000000000000000000);

        stakedPAID.withdrawAllStaked();

        assertEq(paidToken.balanceOf(owner), 499998500000000000000000000);
    }
}
