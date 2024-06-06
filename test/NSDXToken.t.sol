// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NSDXToken} from "../src/NSDXToken.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

contract NSDXTokenTest is Test {
    NSDXToken public token;
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;


    function setUp() public {
        token = new NSDXToken();
        acc0 = address(this);
        acc1 = vm.addr(1);
        acc2 = vm.addr(2);
        acc3 = vm.addr(3);
        acc4 = vm.addr(4);

    }

    function testTokenInitialValues() public {
        assertEq(token.name(), "NASDEX Token", "token name did not match");
        assertEq(token.symbol(), "NSDX", "token symbol did not match");
        assertEq(token.decimals(), 18, "token decimals did not match");
        assertEq(token.totalSupply(), 0, "token supply should be zero");
    }

    function test_TokenMinting() public {
        assertEq(token.balanceOf(acc0), 0, "token balance should be zero initially");
        token.mint(acc0, 10000);
        assertEq(token.balanceOf(acc0), 10000, "token balance did not match");
    }

    function test_TotalSupply() public {
        assertEq(token.balanceOf(acc0), 0, "token balance should be zero initially");
        token.mint(acc0, 10000);
        assertEq(token.totalSupply(), 10000, "total supply did not match");
    }

    function test_TokenMintingWithWrongRole() public {
        vm.prank(acc1);
        bytes32 requiredRole = keccak256("MINTER_ROLE");
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)",
                acc1,
                requiredRole
            )
        );
        token.mint(acc0, 10000);
    }

    function test_TokenMintingForZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InvalidReceiver(address)",
                address(0)
            )
        );
        token.mint(address(0), 10000);
    }

    function test_TokenTransfer() public {
        token.mint(acc0, 10000);
        assertEq(token.balanceOf(acc1), 0, "token balance should be zero initially");
        token.transfer(acc1, 500);
        assertEq(token.balanceOf(acc0), 9500, "token balance did not match");
        assertEq(token.balanceOf(acc1), 500, "token balance did not match");
    }

    function test_TokenTransferToOtherAddress() public {
        token.mint(acc1, 500);
        assertEq(token.balanceOf(acc1), 500, "acc1 token balance did not match");
        vm.prank(acc1);
        token.transfer(acc2, 100);
        assertEq(token.balanceOf(acc1), 400, "acc1 token balance did not match");
        assertEq(token.balanceOf(acc2), 100, "acc2 token balance did not match");
    }

    function test_TokenTransferToZeroAddress() public {
        token.mint(acc1, 500);
        assertEq(token.balanceOf(acc1), 500, "acc1 token balance did not match");
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InvalidReceiver(address)",
                address(0)
            )
        );
        vm.prank(acc1);
        token.transfer(address(0), 100);
    }

    function test_TokenTransferMoreThanBalance() public {
        uint256 balance = 500;
        uint256 needed = 600;

        token.mint(acc2, balance);
        assertEq(token.balanceOf(acc2), balance, "acc1 token balance did not match");
        vm.prank(acc2);
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InsufficientBalance(address,uint256,uint256)",
                acc2,
                balance,
                needed
            )
        );
        token.transfer(acc3, needed);
    }

    function test_TokenApprove() public {
        assertEq(token.allowance(acc0, acc3), 0, "token allowance should be zero initially");
        token.approve(acc3, 500);
        assertEq(token.allowance(acc0, acc3), 500, "token allowance did not match");
    }

    function test_TokenApproveForZeroSpenderAddress() public {
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InvalidSpender(address)",
                address(0)
            )
        );
        token.approve(address(0), 500);
    }

    function test_TokenTransferFrom() public {
        assertEq(token.balanceOf(acc0), 0, "acc0 token balance did not match");
        token.mint(acc0, 1000);
        token.approve(acc3, 500);
        assertEq(token.allowance(acc0, acc3), 500, "token allowance did not match");
        vm.prank(acc3);
        token.transferFrom(acc0, acc4, 400);
        assertEq(token.balanceOf(acc4), 400, "acc4 token balance did not match");
        assertEq(token.allowance(acc0, acc3), 100, "token allowance did not match");
    }

    function test_TokenTransferFromForMoreThanAllowance() public {
        assertEq(token.balanceOf(acc0), 0, "acc0 token balance did not match");
        token.mint(acc0, 1000);
        token.approve(acc3, 100);
        assertEq(token.allowance(acc0, acc3), 100, "token allowance did not match");
        vm.prank(acc3);
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InsufficientAllowance(address,uint256,uint256)",
                acc3,
                100,
                110
            )
        );
        token.transferFrom(acc0, acc4, 110);
    }

    function test_GrantRole() public {
        bytes32 requiredRole = keccak256("MINTER_ROLE");
        assertFalse(token.hasRole(requiredRole, acc1));
        token.grantRole(requiredRole, acc1);
        assertTrue(token.hasRole(requiredRole, acc1));

        assertEq(token.balanceOf(acc1), 0, "token allowance did not match");
        vm.prank(acc1);
        token.mint(acc1, 200);
        assertEq(token.balanceOf(acc1), 200, "token allowance did not match");   
    }

    function test_onlyAdminCanGrantRole() public {
        bytes32 requiredRole = keccak256("MINTER_ROLE");
        assertFalse(token.hasRole(requiredRole, acc1));
        token.grantRole(requiredRole, acc1);
        assertTrue(token.hasRole(requiredRole, acc1));

        vm.prank(acc1);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)",
                acc1,
                address(0)
            )
        );
        token.grantRole(requiredRole, acc2);

    }

    function test_RevokeRole() public {
        bytes32 requiredRole = keccak256("MINTER_ROLE");
        assertFalse(token.hasRole(requiredRole, acc1));
        token.grantRole(requiredRole, acc1);
        assertTrue(token.hasRole(requiredRole, acc1));

        vm.prank(acc1);
        token.mint(acc1, 200);

        token.revokeRole(requiredRole, acc1);

        vm.prank(acc1);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)",
                acc1,
                requiredRole
            )
        );
        token.mint(acc1, 200);
    }    
}
