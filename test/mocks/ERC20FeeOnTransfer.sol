// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ERC20FeeOnTransfer
 * @dev 在转账时收取费用的ERC20代币模拟合约
 */
contract ERC20FeeOnTransfer {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    // 转账费率，以1000为基数，例如：30表示3%的费用
    uint256 public immutable feeRate;
    address public immutable feeRecipient;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _feeRate) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        feeRate = _feeRate;
        feeRecipient = msg.sender;
    }
    
    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "ERC20: insufficient balance");
        
        // 计算并扣除费用
        uint256 feeAmount = (amount * feeRate) / 1000;
        uint256 transferAmount = amount - feeAmount;
        
        // 更新余额
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += transferAmount;
        
        if (feeAmount > 0) {
            balanceOf[feeRecipient] += feeAmount;
            emit Transfer(msg.sender, feeRecipient, feeAmount);
        }
        
        emit Transfer(msg.sender, to, transferAmount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "ERC20: insufficient balance");
        
        if (allowance[from][msg.sender] != type(uint256).max) {
            require(allowance[from][msg.sender] >= amount, "ERC20: insufficient allowance");
            allowance[from][msg.sender] -= amount;
        }
        
        // 计算并扣除费用
        uint256 feeAmount = (amount * feeRate) / 1000;
        uint256 transferAmount = amount - feeAmount;
        
        // 更新余额
        balanceOf[from] -= amount;
        balanceOf[to] += transferAmount;
        
        if (feeAmount > 0) {
            balanceOf[feeRecipient] += feeAmount;
            emit Transfer(from, feeRecipient, feeAmount);
        }
        
        emit Transfer(from, to, transferAmount);
        return true;
    }
} 