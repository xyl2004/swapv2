// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Router.sol";
import "../src/UniswapV2Pair.sol";
import "./mocks/ERC20Mock.sol";
import "./mocks/ERC20FeeOnTransfer.sol";

contract FeeOnTransferTest is Test {
    UniswapV2Factory factory;
    UniswapV2Router router;
    ERC20Mock tokenA;
    ERC20FeeOnTransfer tokenB; // 带有交易费用的代币
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
        
        // 部署测试代币 - tokenA是普通ERC20，tokenB是有交易费用的ERC20
        tokenA = new ERC20Mock("Token A", "TKA", 18);
        // 设置3%的转账费用
        tokenB = new ERC20FeeOnTransfer("Token B Fee", "TKB", 18, 30);
        
        // 确保token排序 (这里不排序，我们确保后面代码中正确使用)
        
        // 为测试用户铸造代币
        tokenA.mint(owner, 1000 ether);
        tokenB.mint(owner, 1000 ether);
        tokenA.mint(user, 1000 ether);
        tokenB.mint(user, 1000 ether);
        
        // 授权路由合约可以使用代币
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        
        vm.startPrank(user);
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

    // 测试添加流动性功能
//     function testAddLiquidity() public {
//     uint amountADesired = 100 ether;
//     uint amountBDesired = 100 ether;

//     // 初始化余额
//     uint balanceABefore = tokenA.balanceOf(owner);
//     uint balanceBBefore = tokenB.balanceOf(owner);

//     // 添加流动性
//     (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
//         address(tokenA),
//         address(tokenB),
//         amountADesired,
//         amountBDesired,
//         0,
//         0,
//         owner,
//         block.timestamp + 60
//     );

//     // 获取 Pair 地址和储备金
//     address pairAddress = factory.getPair(address(tokenA), address(tokenB));
//     assertNotEq(pairAddress, address(0), "Pair not created");
//     (uint reserveA, uint reserveB,) = UniswapV2Pair(pairAddress).getReserves();

//     // 根据储备金状态断言
//     if (reserveA == 0 && reserveB == 0) {
//         // 首次添加流动性
//         assertEq(amountA, amountADesired, "Initial amount A mismatch");
//         assertEq(amountB, amountBDesired, "Initial amount B mismatch");
//     } else {
//         // 后续添加流动性（必须调整）
//         assertLt(amountA, amountADesired, "Amount A should be adjusted");
//         assertLt(amountB, amountBDesired, "Amount B should be adjusted");
//     }

//     // 验证实际转账量
//     uint actualSpentA = balanceABefore - tokenA.balanceOf(owner);
//     uint actualSpentB = balanceBBefore - tokenB.balanceOf(owner);
//     assertEq(actualSpentA, amountA, "Token A spent mismatch");
//     assertEq(actualSpentB, amountB, "Token B spent mismatch");
// }
    
    // 测试支持费用转移的代币交换
    function testSwapExactTokensForTokensSupportingFeeOnTransferTokens() public {
        // 先添加流动性 - 注意这里添加大量代币以减小滑点
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            500 ether,
            500 ether,
            0,
            0,
            owner,
            block.timestamp + 1 hours
        );
        
        uint amountIn = 10 ether;
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        // 用户余额初始状态
        uint userTokenABefore = tokenA.balanceOf(user);
        uint userTokenBBefore = tokenB.balanceOf(user);
        
        // 使用费用转移支持的交换函数
        vm.startPrank(user);
        
        // 交换前记录余额
        uint balanceBefore = tokenB.balanceOf(user);
        
        // 执行代币交换
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0, // 最小输出数量
            path,
            user,
            block.timestamp + 1 hours
        );
        
        // 交换后记录余额
        uint balanceAfter = tokenB.balanceOf(user);
        
        vm.stopPrank();
        
        // 验证用户的代币A减少了正确数量
        assertEq(userTokenABefore - tokenA.balanceOf(user), amountIn, "Token A balance change incorrect");
        
        // 验证用户收到了代币B
        assertGt(balanceAfter, balanceBefore, "Should have received token B");
        
        // 输出实际收到的代币B数量
        console.log("Received token B amount:", balanceAfter - balanceBefore);
    }
    
    // 测试从带费用代币交换到普通代币
    function testSwapFromFeeToken() public {
        // 先添加流动性
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            500 ether,
            500 ether,
            0,
            0,
            owner,
            block.timestamp + 1 hours
        );
        
        uint amountIn = 10 ether;
        address[] memory path = new address[](2);
        path[0] = address(tokenB); // 从带费用的代币
        path[1] = address(tokenA); // 到普通代币
        
        // 用户余额初始状态
        uint userTokenABefore = tokenA.balanceOf(user);
        uint userTokenBBefore = tokenB.balanceOf(user);
        
        // 使用费用转移支持的交换函数
        vm.startPrank(user);
        
        // 交换前记录余额
        uint balanceBefore = tokenA.balanceOf(user);
        
        // 执行代币交换
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0, // 最小输出数量
            path,
            user,
            block.timestamp + 1 hours
        );
        
        // 交换后记录余额
        uint balanceAfter = tokenA.balanceOf(user);
        
        vm.stopPrank();
        
        // 验证用户的代币B减少了正确数量
        assertEq(userTokenBBefore - tokenB.balanceOf(user), amountIn, "Token B balance change incorrect");
        
        // 验证用户收到了代币A
        assertGt(balanceAfter, balanceBefore, "Should have received token A");
        
        // 输出实际收到的代币A数量
        console.log("Received token A amount:", balanceAfter - balanceBefore);
    }
} 