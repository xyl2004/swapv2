# UniswapV2 智能合约

这是基于Uniswap V2协议的智能合约集合，包含了去中心化交易所（DEX）的核心功能实现。

## 项目结构

- **src/**: 核心合约代码
  - `UniswapV2Factory.sol`: 负责创建交易对
  - `UniswapV2Pair.sol`: 交易对合约，管理流动性和交易
  - `UniswapV2Router.sol`: 路由合约，用于添加/移除流动性和交易
  - `UniswapV2ERC20.sol`: LP代币实现
  - `Multicall.sol`: 多调用合约，用于批量查询
  - **interfaces/**: 所有合约接口
  - **libraries/**: 工具库
    - `Math.sol`: 数学计算库
    - `SafeMath.sol`: 安全数学运算
    - `UQ112x112.sol`: 定点数学库
    - `UniswapV2Library.sol`: Uniswap业务逻辑库
    - `TransferHelper.sol`: 安全转账辅助函数

- **test/**: 测试文件
  - `RouterTest.t.sol`: 路由合约测试
  - `FeeOnTransferTest.t.sol`: 收费代币测试
  - **mocks/**: 测试用的模拟合约
    - `ERC20Mock.sol`: ERC20代币模拟合约
    - `ERC20FeeOnTransfer.sol`: 带转账费用的ERC20代币

- **script/**: 部署脚本
  - `DeployRouter.s.sol`: 部署脚本

## 已部署合约地址（Sepolia测试网）

- Factory: `0xa2361D0e6e8807A25e24203555770c8e7C7a285D`
- Router: `0xA9b544D27B0A389C6eD60950AD6eEF894063EEb4`

## 功能特性

- **自动做市商(AMM)算法**: 使用常量乘积公式 x * y = k
- **最低流动性锁定**: 防止价格操纵
- **闪电贷**: 支持无抵押借贷（同一交易内还清）
- **支持原生ETH交易**: 通过Router可直接使用ETH
- **支持带转账费用的代币**: 特殊处理收费代币的交易和添加流动性

## 部署指南

1. 配置环境变量：

```bash
export PRIVATE_KEY=你的私钥
export RPC_URL=你的RPC节点URL
```

2. 部署合约：

```bash
# 部署到测试网（例如 Sepolia）
forge script script/DeployRouter.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast -vvv
```

## 使用示例

### 创建交易对
```solidity
// 通过工厂合约创建新的交易对
IUniswapV2Factory factory = IUniswapV2Factory(FACTORY_ADDRESS);
address pairAddress = factory.createPair(tokenA, tokenB);
```

### 添加流动性
```solidity
// 先授权Router合约
IERC20(tokenA).approve(ROUTER_ADDRESS, amountA);
IERC20(tokenB).approve(ROUTER_ADDRESS, amountB);

// 添加流动性
IUniswapV2Router router = IUniswapV2Router(ROUTER_ADDRESS);
router.addLiquidity(
    tokenA,
    tokenB,
    amountA,
    amountB,
    amountAMin,
    amountBMin,
    recipient,
    deadline
);
```

### 交易代币
```solidity
// 先授权Router合约
IERC20(tokenA).approve(ROUTER_ADDRESS, amountIn);

// 兑换代币
address[] memory path = new address[](2);
path[0] = tokenA;
path[1] = tokenB;

router.swapExactTokensForTokens(
    amountIn,
    amountOutMin,
    path,
    recipient,
    deadline
);
```

## 许可证
MIT 