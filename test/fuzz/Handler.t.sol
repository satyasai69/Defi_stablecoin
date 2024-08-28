//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract Handler is Test {
    DSCEngine dsce;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(DSCEngine _dsce, DecentralizedStableCoin _dsc, address _weth, address _wbtc) {
        dsce = _dsce;
        dsc = _dsc;
        weth = ERC20Mock(_weth);
        wbtc = ERC20Mock(_wbtc);
    }

    /*//////////////////////////////////////////////////////////////
                             PUBLIC FUNCTION
    //////////////////////////////////////////////////////////////*/

    function depositCollateral(uint256 collaterialSeed, uint256 collaterialAmount) public {
        uint256 collaterialAmounts = bound(collaterialAmount, 1, MAX_DEPOSIT_SIZE);

        ERC20Mock collaterial = _getCollateralFromSeed(collaterialSeed);

        vm.startPrank(msg.sender);

        collaterial.mint(msg.sender, collaterialAmounts);

        collaterial.approve(address(dsce), collaterialAmounts);

        dsce.depositCollateral(address(collaterial), collaterialAmounts);

        vm.stopPrank();
    }

    function mintDsc() public {
        (uint256 totalDscMinted, uint256 collaterialValueInUsd) = dsce.getAccountInformtion(msg.sender);
        int256 maxMintAmount = (int256(collaterialValueInUsd / 2)) - int256(totalDscMinted);

        if (maxMintAmount < 0) {
            return;
        }

        uint256 amount = bound(uint256(maxMintAmount), 1, MAX_DEPOSIT_SIZE);
        if (amount == 0) {
            return;
        }

        vm.startPrank(msg.sender);
        dsce.mintDsc(amount);
        vm.stopPrank();
    }

    function redeemCollaterial(uint256 collaterialSeed, uint256 collaterialAmount) public {
        ERC20Mock collaterial = _getCollateralFromSeed(collaterialSeed);

        uint256 maxCollaterialToRedeem = dsce.getCollateralBalanceOfUser(msg.sender, address(collaterial));
        uint256 collaterialAmounts = bound(collaterialAmount, 1, maxCollaterialToRedeem);

        if (collaterialAmounts == 0) {
            return;
        }

        dsce.redeemCollateral(address(collaterial), collaterialAmounts);
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
