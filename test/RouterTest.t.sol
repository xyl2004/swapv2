// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Router.sol";
import "../src/UniswapV2Pair.sol";
import "./mocks/ERC20Mock.sol";

contract RouterTest is Test {
    UniswapV2Factory factory;
    UniswapV2Router router;
    ERC20Mock tokenA;
    ERC20Mock tokenB;
    address owner;
    address user;

    function setUp() public {
        // 设置账户
        owner = address(this);
        user = makeAddr("user");
        
        // 部署工厂合约
        factory = new UniswapV2Factory(owner);
        
        // 部署路由合约
        router = new UniswapV2Router(address(factory));
        
        // 部署测试代币
        tokenA = new ERC20Mock("Token A", "TKA", 18);
        tokenB = new ERC20Mock("Token B", "TKB", 18);
        
        // 确保token排序 (tokenA < tokenB)
        if (address(tokenA) > address(tokenB)) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }
        
        // 为测试用户铸造代币
        tokenA.mint(owner, 100 ether);
        tokenB.mint(owner, 100 ether);
        tokenA.mint(user, 100 ether);
        tokenB.mint(user, 100 ether);
        
        // 授权路由合约可以使用代币
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        
        vm.startPrank(user);
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

    // 测试添加流动性功能
    function testAddLiquidity() public {
        uint amountADesired = 10 ether;
        uint amountBDesired = 20 ether;
        
        // 添加流动性
        (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountADesired,
            amountBDesired,
            0, // 最小A数量
            0, // 最小B数量
            owner,
            block.timestamp + 1 hours
        );
        
        // 验证返回值
        assertEq(amountA, amountADesired, "Incorrect amount A");
        assertEq(amountB, amountBDesired, "Incorrect amount B");
        assertGt(liquidity, 0, "No liquidity minted");
        
        // 获取Pair地址
        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        assertNotEq(pairAddress, address(0), "Pair not created");
        
        // 验证LP代币余额
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        assertEq(pair.balanceOf(owner), liquidity, "LP token balance mismatch");
    }
    
    // 测试移除流动性功能
    function testRemoveLiquidity() public {
        // 先添加流动性
        (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            10 ether,
            20 ether,
            0,
            0,
            owner,
            block.timestamp + 1 hours
        );
        
        // 获取Pair地址
        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        
        // 授权路由合约使用LP代币
        pair.approve(address(router), liquidity);
        
        // 添加流动性前记录代币余额
        uint tokenABalanceBefore = tokenA.balanceOf(owner);
        uint tokenBBalanceBefore = tokenB.balanceOf(owner);
        
        // 移除流动性
        (uint removedA, uint removedB) = router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liquidity,
            0, // 最小A数量
            0, // 最小B数量
            owner,
            block.timestamp + 1 hours
        );
        
        // 验证返回值（注意：实际返回值可能会有所不同，这里需要根据具体实现调整测试）
        assertTrue(removedA > 0, "Should have removed some token A");
        assertTrue(removedB > 0, "Should have removed some token B");
        
        // 验证代币余额增加
        assertEq(tokenA.balanceOf(owner) - tokenABalanceBefore, removedA, "Token A balance mismatch");
        assertEq(tokenB.balanceOf(owner) - tokenBBalanceBefore, removedB, "Token B balance mismatch");
        
        // 验证LP代币余额为0
        assertEq(pair.balanceOf(owner), 0, "LP token not fully burned");
    }
    
    // 测试交换代币功能
    function testSwapExactTokensForTokens() public {
        // 先添加流动性
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            50 ether,
            100 ether,
            0,
            0,
            owner,
            block.timestamp + 1 hours
        );
        
        uint amountIn = 1 ether;
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        // 预估可得到的代币数量
        uint[] memory amountsOut = router.getAmountsOut(amountIn, path);
        
        // 用户余额初始状态
        uint userTokenABefore = tokenA.balanceOf(user);
        uint userTokenBBefore = tokenB.balanceOf(user);
        
        // 用户进行代币交换
        vm.startPrank(user);
        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            0, // 最小输出数量
            path,
            user,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // 验证交换结果
        assertEq(amounts[0], amountIn, "Input amount mismatch");
        assertEq(amounts[1], amountsOut[1], "Output amount mismatch");
        
        // 验证用户余额变化
        assertEq(userTokenABefore - tokenA.balanceOf(user), amountIn, "Token A balance change incorrect");
        assertEq(tokenB.balanceOf(user) - userTokenBBefore, amounts[1], "Token B balance change incorrect");
    }
    
    // 测试预期代币输出功能
    function testSwapTokensForExactTokens() public {
        // 先添加流动性
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            50 ether,
            100 ether,
            0,
            0,
            owner,
            block.timestamp + 1 hours
        );
        
        uint amountOut = 1 ether;
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        // 预估需要的代币数量
        uint[] memory amountsIn = router.getAmountsIn(amountOut, path);
        
        // 用户余额初始状态
        uint userTokenABefore = tokenA.balanceOf(user);
        uint userTokenBBefore = tokenB.balanceOf(user);
        
        // 用户进行代币交换
        vm.startPrank(user);
        uint[] memory amounts = router.swapTokensForExactTokens(
            amountOut,
            amountsIn[0] * 2, // 最大输入数量
            path,
            user,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // 验证交换结果
        assertEq(amounts[0], amountsIn[0], "Input amount mismatch");
        assertEq(amounts[1], amountOut, "Output amount mismatch");
        
        // 验证用户余额变化
        assertEq(userTokenABefore - tokenA.balanceOf(user), amounts[0], "Token A balance change incorrect");
        assertEq(tokenB.balanceOf(user) - userTokenBBefore, amountOut, "Token B balance change incorrect");
    }
    
    // 测试报价功能
    function testQuote() public {
        uint amountA = 1 ether;
        uint reserveA = 10 ether;
        uint reserveB = 5 ether;
        
        uint amountB = router.quote(amountA, reserveA, reserveB);
        
        // 验证报价计算是否正确
        // amountB = (amountA * reserveB) / reserveA
        assertEq(amountB, (amountA * reserveB) / reserveA, "Quote calculation incorrect");
    }
    
    // 测试获取输出金额功能
    function testGetAmountOut() public {
        uint amountIn = 1 ether;
        uint reserveIn = 10 ether;
        uint reserveOut = 5 ether;
        
        uint amountOut = router.getAmountOut(amountIn, reserveIn, reserveOut);
        
        // 模拟计算公式
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        uint expectedAmountOut = numerator / denominator;
        
        assertEq(amountOut, expectedAmountOut, "GetAmountOut calculation incorrect");
    }
    
    // 测试获取输入金额功能
    function testGetAmountIn() public {
        uint amountOut = 1 ether;
        uint reserveIn = 10 ether;
        uint reserveOut = 5 ether;
        
        uint amountIn = router.getAmountIn(amountOut, reserveIn, reserveOut);
        
        // 确保计算结果正确
        assertTrue(amountIn > 0, "Amount in should be greater than 0");
        
        // 使用计算得到的输入金额，再计算输出金额，应该接近原始输出金额
        uint calculatedOut = router.getAmountOut(amountIn, reserveIn, reserveOut);
        
        // 由于整数除法可能有1的误差
        assertApproxEqAbs(calculatedOut, amountOut, 1, "Input/Output calculations inconsistent");
    }
}

// 创建ERC20代币模拟合约
