// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PredumSale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // PRD parameters
    uint256 public prdPrice;
    uint256 public minBuy; 
    uint256 public cap;
    uint256 public prdSold;
    IERC20 public prd;

    // Round parameters
    uint256 public whitelistStartTime;
    uint256 public whitelistEndTime;
    uint256 public publicStartTime;
    uint256 public publicEndTime;
    bool public isStopped = false;

    // Whitelist parameters
    mapping(address => bool) public whitelist;

    // Blacklist parameters
    mapping(address => bool) public blacklist;

    constructor(
        uint256 _cap,
        address _prdToken,
        uint256 _prdPrice,
        uint256 _minBuy
    ) {
        cap = _cap;
        prd = IERC20(_prdToken);
        prdPrice = _prdPrice;
        minBuy = _minBuy;
    }

    receive() external payable {}

    // Modifiers
     modifier onlyWhenNotStopped {
        require(!isStopped);
        _;
    }

    modifier onlyWhenStopped {
        require(isStopped);
        _;
    }

    // Functions
    function _precheckBuy(address sender) internal view {
        require(block.timestamp > whitelistStartTime, "Whitelist's round does not start now.");
        if (block.timestamp > whitelistEndTime) {
            require(block.timestamp > publicStartTime, "Public's round does not start now.");
        }
        require(block.timestamp <= publicEndTime, "IDO is expired.");

        checkBlackList(sender);

        if (whitelistStartTime < block.timestamp && whitelistEndTime > block.timestamp) {
            require(whitelist[msg.sender], "You are not on the whitelist.");
        }
    }

    function checkBlackList(address _address) internal view {
        require(_address != address(0), "Zero address.");
        require(!blacklist[_address], "Blacklist user.");
    }

     function addToBlacklist(address _address) external onlyOwner {
        require(_address != address(0), "Zero address.");
        blacklist[_address] = true;
    }

    function removeFromBlacklist(address _address)
        external
        onlyOwner
    {
        require(_address != address(0), "Zero address.");
        delete blacklist[_address];
    }

    function addToWhitelist(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
    }

    function setRoundTime (
        uint256 _whitelistStartTime,
        uint256 _whitelistEndTime,
        uint256 _publicStartTime,
        uint256 _publicEndTime
    ) external onlyOwner {
        require(_whitelistStartTime >= block.timestamp, "Whitelist start time must be in the future.");
        require(_publicStartTime >= _whitelistEndTime, "Public start time must be after whitelist end time.");

        whitelistStartTime = _whitelistStartTime;
        whitelistEndTime = _whitelistEndTime;
        publicStartTime = _publicStartTime;
        publicEndTime = _publicEndTime;
    }

    // Buy function
    function buy() external payable onlyWhenNotStopped {
        _precheckBuy(msg.sender);

        require(msg.value >= minBuy, "You must buy at least the minimum amount.");

        uint256 prdAmount = msg.value.mul(prdPrice);

        require(prdSold.add(prdAmount) <= cap, "Not enough PRD prds available.");
    
        uint256 contractBalance = prd.balanceOf(address(this));
        require(prdAmount <= contractBalance, "Not enough PRD prds available in the contract");

        prd.transfer(msg.sender, prdAmount);

        prdSold = prdSold.add(prdAmount);
    }

    // Withdraw functions
    function withdrawETH (uint256 _ethAmount) external onlyOwner onlyWhenStopped {
        uint256 remainAmountToken = address(this).balance;
        require(remainAmountToken > 0 && remainAmountToken >= _ethAmount, "Not enough Ether in the contract.");
        require(_ethAmount > 0, "The amount want to withdraw must be greater than 0.");

        (bool success, ) = payable(owner()).call{value: _ethAmount}("");
        require(success, "Transfer failed.");
    }

    function withdrawPRD (address _prdToken) external onlyOwner onlyWhenStopped {
        uint256 remainAmountToken = prd.balanceOf(address(this));
        require(remainAmountToken > 0, "Not enough PRD in the contract.");
        IERC20(payable(_prdToken)).safeTransfer(owner(), remainAmountToken);
    }

    function changeCap(uint256 _cap) external onlyOwner {
        cap = _cap;
    }

    function changePrdToken(address _prdToken) external onlyOwner {
        prd = IERC20(_prdToken);
    }

    function changePrdPrice(uint256 _prdPrice) external onlyOwner {
        prdPrice = _prdPrice;
    }

    function changeMinBuy(uint256 _minBuy) external onlyOwner {
        minBuy = _minBuy;
    }

    function stopIDO() external onlyOwner {
        isStopped = true;
    }

    function resumeIDO() external onlyOwner {
        isStopped = false;
    }

    function checkBalanceOfAddresses(address _address) external view returns (uint256) {
        return prd.balanceOf(_address);
    }

    function checkBalance() external view returns (uint256, uint256) {
        return (prd.balanceOf(address(this)), address(this).balance);
    }
}