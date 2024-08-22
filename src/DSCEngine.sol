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
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    error DSCEngine_BreakHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private constant ADDITTIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIATION_THRESHOLD = 50;
    uint256 private constant LIQUIATION_PREISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_priceFeed;
    mapping(address user => mapping(address token => uint256 balance)) private s_collateralDeposit;
    mapping(address user => uint256 amountDSCMinted) private s_DSCMinted;

    address[] private s_collateralToken;

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
            s_collateralToken.push(tokenAddresses[i]);
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

    function mintDsc(uint256 amountDscToMint) external moreThanaZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] = amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function brunDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    /*//////////////////////////////////////////////////////////////
                                PRIVATE & INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _revertIfHealthFactorIsBroken(address user) internal view {
        // check health factor(do they have enough collateral?)
        // Revert if they don't

        uint256 userHealthFactor = _healthFactor(user);

        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine_BreakHealthFactor(userHealthFactor);
        }
    }

    function _healthFactor(address user) internal view returns (uint256) {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformtion(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIATION_THRESHOLD) / LIQUIATION_PREISION;

        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    function _getAccountInformtion(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        uint256 totalDscMinted = s_DSCMinted[user];
        uint256 collateralValueInUsd = getAccountCollteralValue(user);

        return (totalDscMinted, collateralValueInUsd);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC  & EXTERNAL VIEW FUNCTION 
    //////////////////////////////////////////////////////////////*/

    function getAccountCollteralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 i = 0; i < s_collateralToken.length; i++) {
            address token = s_collateralToken[i];
            uint256 amount = s_collateralDeposit[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }

        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeed[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();

        return ((uint256(price) * ADDITTIONAL_FEED_PRECISION) * amount) / PRECISION;
    }
}
