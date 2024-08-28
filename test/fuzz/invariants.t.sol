//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {StdInvariant} from "forge-std/StdInvariant.sol";

import {Handler} from "./Handler.t.sol";

contract invariants is StdInvariant, Test {
    DeployDSC depolyer;
    HelperConfig config;
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    Handler handler;

    address weth;
    address wbtc;

    function setUp() public {
        depolyer = new DeployDSC();
        config = new HelperConfig();

        (dsc, dsce, config) = depolyer.run();

        (,, weth, wbtc,) = config.activeNetworkConfig();

        handler = new Handler(dsce, dsc, address(weth), address(wbtc));

        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMorevalueThanTotalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();

        uint256 totalwethdeposit = IERC20(weth).balanceOf(address(dsce));
        uint256 totalwbtcdeposit = IERC20(wbtc).balanceOf(address(dsce));

        uint256 wethValue = dsce.getUsdValue(address(weth), totalwethdeposit);

        uint256 wbtcValue = dsce.getUsdValue(address(wbtc), totalwbtcdeposit);

        assert(wethValue + wbtcValue >= totalSupply);
    }
}
