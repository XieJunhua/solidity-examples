// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IERC4626.sol";

contract Vault is ERC20, IERC4626 {
    IERC20 public immutable asset; // 底层资产（如 DAI）
    uint256 public totalAssets; // 金库总资产
    uint256 public profitPerShare; // 每股累积收益（单位：资产/代币，放大精度）
    uint256 public constant PRECISION = 1e18; // 精度因子

    // 用户数据
    struct UserInfo {
        uint256 shares; // 用户持有的金库代币
        uint256 lastProfitPerShare; // 用户存入或最后结算时的 profitPerShare
        uint256 unclaimedProfit; // 未领取的收益
    }

    mapping(address => UserInfo) public userInfo;

    constructor(IERC20 _asset) ERC20("Vault Token", "vToken") {
        asset = _asset;
    }

    // 存入资产，铸造代币
    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        shares = convertToShares(assets);
        require(shares > 0, "Zero shares");

        // 更新用户未领取收益
        _updateUserProfit(receiver);

        // 转入资产
        asset.transferFrom(msg.sender, address(this), assets);
        totalAssets += assets;

        // 铸造代币
        _mint(receiver, shares);

        // 更新用户数据
        UserInfo storage user = userInfo[receiver];
        user.shares += shares;
        user.lastProfitPerShare = profitPerShare;

        emit Deposit(msg.sender, receiver, assets, shares);
        return shares;
    }

    // 指定代币数量，存入资产
    function mint(uint256 shares, address receiver) public override returns (uint256 assets) {
        assets = convertToAssets(shares);
        require(assets > 0, "Zero assets");

        // 更新用户未领取收益
        _updateUserProfit(receiver);

        // 转入资产
        asset.transferFrom(msg.sender, address(this), assets);
        totalAssets += assets;

        // 铸造代币
        _mint(receiver, shares);

        // 更新用户数据
        UserInfo storage user = userInfo[receiver];
        user.shares += shares;
        user.lastProfitPerShare = profitPerShare;

        emit Deposit(msg.sender, receiver, assets, shares);
        return assets;
    }

    // 模拟外部收益（如投资回报）
    function addProfit(uint256 profit) external {
        // 模拟外部协议将收益转入金库
        asset.transferFrom(msg.sender, address(this), profit);
        totalAssets += profit;

        // 更新每股累积收益
        uint256 totalShares = totalSupply();
        if (totalShares > 0) {
            profitPerShare += (profit * PRECISION) / totalShares;
        }
    }

    // 用户提取累积收益
    function claimProfit(address receiver) public returns (uint256 profit) {
        _updateUserProfit(msg.sender);
        UserInfo storage user = userInfo[msg.sender];
        profit = user.unclaimedProfit;
        require(profit > 0, "No profit to claim");

        user.unclaimedProfit = 0;
        totalAssets -= profit;
        asset.transfer(receiver, profit);
    }

    // 更新用户未领取收益
    function _updateUserProfit(address userAddress) internal {
        UserInfo storage user = userInfo[userAddress];
        if (user.shares > 0) {
            uint256 profitDelta = ((profitPerShare - user.lastProfitPerShare) * user.shares) / PRECISION;
            user.unclaimedProfit += profitDelta;
            user.lastProfitPerShare = profitPerShare;
        }
    }

    // 资产 → 代币 转换
    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply();
        return supply == 0 ? assets : (assets * supply) / totalAssets;
    }

    // 代币 → 资产 转换
    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply();
        return supply == 0 ? shares : (shares * totalAssets) / supply;
    }

    // 赎回代币（简化，未包含收益提取）
    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256 assets) {
        require(shares <= userInfo[owner].shares, "Insufficient shares");

        // 更新用户未领取收益
        _updateUserProfit(owner);

        // 计算资产
        assets = convertToAssets(shares);
        totalAssets -= assets;

        // 销毁代币
        _burn(owner, shares);

        // 更新用户数据
        UserInfo storage user = userInfo[owner];
        user.shares -= shares;

        // 转出资产
        asset.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        return assets;
    }

    // 查询用户未领取收益
    function getUnclaimedProfit(address userAddress) public view returns (uint256) {
        UserInfo memory user = userInfo[userAddress];
        uint256 profitDelta = ((profitPerShare - user.lastProfitPerShare) * user.shares) / PRECISION;
        return user.unclaimedProfit + profitDelta;
    }
}
