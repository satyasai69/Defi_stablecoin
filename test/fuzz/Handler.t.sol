//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

contract Handler is Test {
    DSCEngine dsce;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    MockV3Aggregator public ethusdPriceFeed;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;
    uint256 public timeMintIsCalled;
    address[] public usersWithCollatrialDeposited;

    constructor(DSCEngine _dsce, DecentralizedStableCoin _dsc, address _weth, address _wbtc) {
        dsce = _dsce;
        dsc = _dsc;
        weth = ERC20Mock(_weth);
        wbtc = ERC20Mock(_wbtc);

        ethusdPriceFeed = MockV3Aggregator(dsce.getCollateralTokenPriceFeed(address(weth)));
    }

    /*//////////////////////////////////////////////////////////////
                             PUBLIC FUNCTION
    //////////////////////////////////////////////////////////////*/

    function mint(uint256 amount, uint256 addressSeed) public {
        if (usersWithCollatrialDeposited.length == 0) {
            return;
        }
        address sender = usersWithCollatrialDeposited[addressSeed % usersWithCollatrialDeposited.length];
        (uint256 totalDscMinted, uint256 collaterialValueInUsd) = dsce.getAccountInformtion(sender);
        int256 maxMintAmount = (int256(collaterialValueInUsd / 2)) - int256(totalDscMinted);

        console.log("maxMintAmount:", maxMintAmount);

        if (maxMintAmount < 0) {
            return;
        }

        uint256 amounts = bound(amount, 0, uint256(maxMintAmount));
        if (amounts == 0) {
            return;
        }
        vm.startPrank(sender);

        dsce.mintDsc(amounts);

        vm.stopPrank();
        timeMintIsCalled++;
    }

    function depositCollateral(uint256 collaterialSeed, uint256 collaterialAmount) public {
        uint256 collaterialAmounts = bound(collaterialAmount, 1, MAX_DEPOSIT_SIZE);

        ERC20Mock collaterial = _getCollateralFromSeed(collaterialSeed);

        vm.startPrank(msg.sender);

        collaterial.mint(msg.sender, collaterialAmounts);

        collaterial.approve(address(dsce), collaterialAmounts);

        dsce.depositCollateral(address(collaterial), collaterialAmounts);

        vm.stopPrank();
        usersWithCollatrialDeposited.push(msg.sender);
    }

    function redeemCollaterial(uint256 collaterialSeed, uint256 collaterialAmount) public {
        ERC20Mock collaterial = _getCollateralFromSeed(collaterialSeed);

        uint256 maxCollaterialToRedeem = dsce.getCollateralBalanceOfUser(msg.sender, address(collaterial));

        uint256 collaterialAmounts = bound(collaterialAmount, 0, maxCollaterialToRedeem);

        if (collaterialAmounts == 0) {
            return;
        }

        dsce.redeemCollateral(address(collaterial), collaterialAmounts);
    }

    function updateCollateralPrice(uint96 newPrice) public {
        int256 newPriceInt = int256(uint256(newPrice));
        ethusdPriceFeed.updateAnswer(newPriceInt);
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    //Helper function

    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }
}
