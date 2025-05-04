// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyERC20 is ERC20 {
    constructor() ERC20("MyERC20", "MYERC20") { }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
