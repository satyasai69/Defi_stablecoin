//SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

pragma solidity ^0.8.19;

import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DSCEngine
 * @author satya
 * @notice This contract is the core of the  DSC system. It handle all the logic for mining and redeeming DSC, as well as depositing & withdrawing collateral.
 */
contract DSCEngine is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error DSCEngine_NeedMoreThanZero();
    error DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine_NotAllowedToken();
    error DSCEngine_TransferFailed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(address token => address priceFeed) private s_priceFeed;
    mapping(address user => mapping(address token => uint256 balance)) private s_collateralDeposit;

    DecentralizedStableCoin private immutable i_dsc;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event collateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier moreThanaZero(uint256 _amount) {
        if (_amount == 0) {
            revert DSCEngine_NeedMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeed[token] == address(0)) {
            revert DSCEngine_NotAllowedToken();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length == priceFeedAddresses.length) {
            revert DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeed[tokenAddresses[i]] = priceFeedAddresses[i];
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function depositCollateralAndMintDsc() external {}

    /**
     * @notice "follows CEI"
     * @param tokenCollateralAddress "The address of the token to deposit as collateral"
     * @param amountToCollarteral "The amount of collateral to deposit"
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountToCollarteral)
        external
        moreThanaZero(amountToCollarteral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposit[msg.sender][tokenCollateralAddress] += amountToCollarteral;
        emit collateralDeposited(msg.sender, tokenCollateralAddress, amountToCollarteral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountToCollarteral);
        if (!success) {
            revert DSCEngine_TransferFailed();
        }
    }

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    function brunDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}
