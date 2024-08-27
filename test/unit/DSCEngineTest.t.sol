//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {console} from "forge-std/console.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

import {StdCheats} from "forge-std/StdCheats.sol";

contract DSCEngineTest is StdCheats, Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;

    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public constant ERC20_MINT_AMOUNT = 100 ether;

    ///////////////////////
    // Constructor Tests //
    ///////////////////////
    //   address[] public tokenAddresses;
    address[] public feedAddresses;

    function setUp() public {
        deployer = new DeployDSC();

        (dsc, dsce, config) = deployer.run();
        (wethUsdPriceFeed, wbtcUsdPriceFeed, weth,,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTORTEST
    //////////////////////////////////////////////////////////////*/

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    uint256 amountCollateral = 10 ether;
    uint256 amountToMint = 100 ether;
    address public user = address(1);

    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;
    uint256 public constant LIQUIDATION_THRESHOLD = 50;

    // Liquidation
    address public liquidator = makeAddr("liquidator");
    uint256 public collateralToCover = 20 ether;

    function testrevertsIfTokenLengthDontMatchPriceFeed() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(wethUsdPriceFeed);
        priceFeedAddresses.push(wbtcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);

        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /*//////////////////////////////////////////////////////////////
                                 PRICE TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetUsdValue() public view {
        uint256 expertedUsdvalue = 2000e18;
        uint256 actualUsd = dsce.getUsdValue(weth, 1 ether);
        console.log(actualUsd);

        assertEq(expertedUsdvalue, actualUsd);
    }

    function testTokenAmountUsd() public view {
        uint256 expertedwethvalue = 1 ether;
        uint256 actualweth = dsce.getTokenAmountFromUsd(weth, 2000e18);

        assertEq(expertedwethvalue, actualweth);
    }

    /*//////////////////////////////////////////////////////////////
                         DEPOSIT COLLATERAL TESTS
    //////////////////////////////////////////////////////////////*/

    function testRevertsIfCollateralIszero() public {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine_NeedMoreThanZero.selector);

        dsce.depositCollateral(weth, 0);

        vm.stopPrank();
    }

    function testRevertsWithUnapprovesCollateral() public {
        ERC20Mock ranToken = new ERC20Mock();

        ranToken.mint(USER, STARTING_ERC20_BALANCE);

        vm.startPrank(USER);

        vm.expectRevert(DSCEngine.DSCEngine_NotAllowedToken.selector);

        dsce.depositCollateral(address(ranToken), STARTING_ERC20_BALANCE);

        vm.stopPrank();
    }

    modifier DepositCollateral() {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        dsce.depositCollateral(address(weth), AMOUNT_COLLATERAL);

        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccontInfo() public DepositCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformtion(USER);

        uint256 expectedTotalDscMinted = 0;

        uint256 expectedDepositAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);

        assertEq(totalDscMinted, expectedTotalDscMinted);

        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }

    function testdepositCollateralAndMintDsc() public {
        vm.startPrank(USER);

        uint256 beforeBalanceOfDsc = DecentralizedStableCoin(dsc).balanceOf(USER);

        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        dsce.depositCollateralAndMintDsc(address(weth), AMOUNT_COLLATERAL, ERC20_MINT_AMOUNT);

        uint256 afterBalanceOfDsc = DecentralizedStableCoin(dsc).balanceOf(USER);

        assertEq(0, beforeBalanceOfDsc);
        assertEq(ERC20_MINT_AMOUNT, afterBalanceOfDsc);

        vm.stopPrank();
    }

    modifier depositedCollateralAndMintedDsc() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        //  dsce.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, ERC20_MINT_AMOUNT);

        dsce.depositCollateralAndMintDsc(address(weth), AMOUNT_COLLATERAL, ERC20_MINT_AMOUNT);
        vm.stopPrank();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            REDEEMCOLLATERAL
    //////////////////////////////////////////////////////////////*/

    function testRedeemCollateral() public DepositCollateral {
        vm.startPrank(USER);

        dsce.redeemCollateral(address(weth), AMOUNT_COLLATERAL);

        uint256 expectValue = 0;

        uint256 activerValue = dsce.getAccountCollteralValue(USER);

        assertEq(expectValue, activerValue);

        vm.stopPrank();
    }

    function testMustRedeemMoreThanZero() public DepositCollateral {
        vm.startPrank(USER);

        vm.expectRevert(DSCEngine.DSCEngine_NeedMoreThanZero.selector);

        dsce.redeemCollateral(address(weth), 0);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                  MINT
    //////////////////////////////////////////////////////////////*/

    ///////////////////////////////////
    // burnDsc Tests //
    ///////////////////////////////////

    function testRevertsIfBurnAmountIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, ERC20_MINT_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine_NeedMoreThanZero.selector);
        dsce.brunDsc(0);
        vm.stopPrank();
    }

    function testCantBurnMoreThanUserHas() public {
        vm.prank(USER);
        vm.expectRevert();
        dsce.brunDsc(1);
    }

    function testCanBurnDsc() public depositedCollateralAndMintedDsc {
        vm.startPrank(USER);
        dsc.approve(address(dsce), ERC20_MINT_AMOUNT);
        dsce.brunDsc(ERC20_MINT_AMOUNT);
        vm.stopPrank();

        uint256 userBalance = dsc.balanceOf(USER);
        assertEq(userBalance, 0);
    }

    /*//////////////////////////////////////////////////////////////
                              MINTDSCTEST
    //////////////////////////////////////////////////////////////*/

    function testRevertsIfMintAmountIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, ERC20_MINT_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine_NeedMoreThanZero.selector);
        dsce.mintDsc(0);
        vm.stopPrank();
    }

    function testCanMintDsc() public DepositCollateral {
        vm.prank(USER);
        dsce.mintDsc(ERC20_MINT_AMOUNT);

        uint256 userBalance = dsc.balanceOf(USER);
        assertEq(userBalance, ERC20_MINT_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                             LIQUIDTION TEST
    //////////////////////////////////////////////////////////////*/

    function testProperlyReportsHealthFactor() public depositedCollateralAndMintedDsc {
        uint256 expectedHealthFactor = 100 ether;
        uint256 healthFactor = dsce.getHealthFactor(USER);
        // $100 minted with $20,000 collateral at 50% liquidation threshold
        // means that we must have $200 collatareral at all times.
        // 20,000 * 0.5 = 10,000
        // 10,000 / 100 = 100 health factor
        assertEq(healthFactor, expectedHealthFactor);
    }
}
