// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract MyERC4626 is ERC4626 {
    constructor(IERC20 asset, string memory name, string memory symbol) ERC4626(asset) ERC20(name, symbol) {
        // Initialize the vault with the underlying asset
    }

    // Override the _decimals function to match the underlying asset's decimals
    function decimals() public view override returns (uint8) {
        return super.decimals();
    }

    // Optional: Override deposit/withdraw functions if you need custom logic
    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    // Optional: Add custom fee mechanism
    // uint256 private constant FEE_BPS = 10; // 0.1% fee
    //
    // function _convertToShares(uint256 assets, Math.Rounding rounding) internal view override returns (uint256) {
    //     uint256 shares = super._convertToShares(assets, rounding);
    //     return shares - (shares * FEE_BPS / 10000);
    // }
}
