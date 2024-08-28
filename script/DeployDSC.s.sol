//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDSC is Script {
    address[] public tokenAddress;
    address[] public priceFeedAddress;

    function run() public returns (DecentralizedStableCoin, DSCEngine, HelperConfig) {
        HelperConfig config = new HelperConfig();

        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            config.activeNetworkConfig();

        tokenAddress = [weth, wbtc];
        priceFeedAddress = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        console.log("Token Addresses:");
        for (uint256 i = 0; i < tokenAddress.length; i++) {
            console.log("Token", i, ":", tokenAddress[i]);
        }

        console.log("Price Feed Addresses:");
        for (uint256 i = 0; i < priceFeedAddress.length; i++) {
            console.log("Price Feeds", i, ":", priceFeedAddress[i]);
        }

        vm.startBroadcast();
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();

        DSCEngine engine = new DSCEngine(tokenAddress, priceFeedAddress, address(dsc));

        dsc.transferOwnership(address(engine));

        vm.stopBroadcast();

        return (dsc, engine, config);
    }
}
