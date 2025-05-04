# UniswapV2 部署指南

此目录包含了用于部署 UniswapV2 协议核心合约的脚本。

## 部署脚本

- `DeployUniswapV2.s.sol`: 主要部署脚本，用于部署 UniswapV2Factory、WETH 和 UniswapV2Router02 合约。

## 如何使用

1. 首先确保你有一个私钥存储在环境变量中：

```bash
export PRIVATE_KEY=0cfa3dff5e87974bff21af63c801c883686dc0b00036ab52267f66cc0b79b180
```

2. 部署到指定的网络：

```bash
# 部署到本地网络
forge script script/DeployUniswapV2.s.sol:DeployUniswapV2 --rpc-url http://localhost:8545 --broadcast -vvv

# 部署到测试网（例如 Sepolia）
forge script script/DeployUniswapV2.s.sol:DeployUniswapV2 --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvv
```

3. 验证合约（可选）：

```bash
forge verify-contract $FACTORY_ADDRESS src/UniswapV2Factory.sol:UniswapV2Factory --etherscan-api-key $ETHERSCAN_API_KEY --constructor-args $(cast abi-encode "constructor(address)" $OWNER_ADDRESS)

forge verify-contract $WETH_ADDRESS src/WETH.sol:WETH --etherscan-api-key $ETHERSCAN_API_KEY

forge verify-contract $ROUTER_ADDRESS src/UniswapV2Router02.sol:UniswapV2Router02 --etherscan-api-key $ETHERSCAN_API_KEY --constructor-args $(cast abi-encode "constructor(address,address)" $FACTORY_ADDRESS $WETH_ADDRESS)
```

## 部署后操作

1. 确保记录所有部署的合约地址，尤其是：
   - UniswapV2Factory
   - WETH
   - UniswapV2Router02

2. 可以通过 UniswapV2Factory 创建代币对：
   ```solidity
   factory.createPair(tokenA, tokenB);
   ```

3. 通过 Router 添加流动性：
   ```solidity
   router.addLiquidity(tokenA, tokenB, amountA, amountB, minA, minB, to, deadline);
   ``` 