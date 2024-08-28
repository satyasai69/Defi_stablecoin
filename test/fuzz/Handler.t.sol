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

    function depositCollateral(uint256 collaterialSeed, uint256 collaterialAmount) public {
        uint256 collaterialAmounts = bound(collaterialAmount, 1, MAX_DEPOSIT_SIZE);

        ERC20Mock collaterial = _getCollteralFromSeed(collaterialSeed);

        vm.startPrank(msg.sender);

        collaterial.mint(msg.sender, collaterialAmounts);

        collaterial.approve(address(dsce), collaterialAmounts);

        dsce.depositCollateral(address(collaterial), collaterialAmounts);

        vm.stopPrank();
    }

    //Helper function

    function _getCollteralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }
}
