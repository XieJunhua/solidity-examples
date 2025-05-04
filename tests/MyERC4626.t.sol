// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";

import { MyERC4626 } from "../src/MyERC4626.sol";
import { MyERC20 } from "../src/MyERC20.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract MyERC4626Test is Test {
    MyERC4626 internal myERC4626;
    MyERC20 internal myERC20 = new MyERC20();

    address internal alice = makeAddr("Alice");
    address internal bob = makeAddr("Bob");

    function setUp() public {
        myERC4626 = new MyERC4626(myERC20, "MyERC4626", "MYERC4626");
    }

    function test_Example() public {
        myERC20.mint(alice, 1000);
        vm.startPrank(alice);
        myERC20.approve(address(myERC4626), 1000);
        myERC4626.deposit(1000, alice);
        assertEq(myERC4626.balanceOf(alice), 1000);
        vm.stopPrank();

        vm.startPrank(bob);
        myERC20.mint(bob, 500);
        myERC20.approve(address(myERC4626), 500);
        myERC4626.deposit(500, bob);
        assertEq(myERC4626.balanceOf(bob), 500);
        vm.stopPrank();

        // vm.warp(block.timestamp + 1 days);
        vm.roll(block.number + 1000);
        vm.startPrank(bob);
        console2.log("bob shares before", myERC4626.balanceOf(bob));
        // myERC4626.withdraw(500, bob, bob);
        myERC4626.redeem(500, bob, bob);
        console2.log("bob balance", myERC20.balanceOf(bob));
        console2.log("bob shares after", myERC4626.balanceOf(bob));
        // assertEq(myERC20.balanceOf(bob), 2000);
        vm.stopPrank();
    }
}
