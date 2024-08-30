# DAI Stablecoin Contract with Foundry

This repository contains the code for a DAI stablecoin implementation built using Solidity and tested with Foundry. The primary contract, DSCEngine, manages the minting and redeeming of decentralized stablecoins (DSC), as well as collateral deposits and withdrawals.

# Table of Contents

Introduction
Features
Contracts Overview
Installation
Usage
Testing
License
Introduction
The DSCEngine contract is the core of the DSC system. It handles the logic for minting and redeeming DSC, managing collateral, and ensuring the stability and health of the system. This project demonstrates the application of advanced Solidity concepts, including reentrancy protection, price feeds via Chainlink oracles, and custom error handling.

# Features

Collateral Management: Deposit and withdraw supported collateral tokens.
Minting & Burning: Mint DSC against deposited collateral and burn DSC to redeem collateral.
Health Factor: Ensures the health factor of accounts to prevent under-collateralization.
Liquidation Mechanism: Liquidate under-collateralized positions with bonuses for liquidators.
Oracle Integration: Uses Chainlink oracles for secure and decentralized price feeds.

# Contracts Overview

DSCEngine
This contract manages the core functionality of the DSC system:

# Collateral Management:

Allows users to deposit and redeem collateral tokens.
DSC Minting: Users can mint DSC tokens by depositing collateral.
Health Factor Monitoring: Ensures that users maintain sufficient collateral to support their minted DSC.

# Liquidation:

Facilitates the liquidation of under-collateralized positions.

# DecentralizedStableCoin

A simplified stablecoin contract that represents the DSC token. This contract is integrated with the DSCEngine for minting and burning operations.

# OracleLib

A custom library for interacting with Chainlink price feeds. It includes functions to verify the freshness of price data and to prevent stale prices from being used.

# Installation

To get started with the project, clone the repository and install the required dependencies.

```
git clone https://github.com/yourusername/dai-stablecoin-foundry.git
cd dai-stablecoin-foundry
forge install
```

# Usage

The DSCEngine contract can be used for various operations:

# Deposit Collateral:

```solidity
function depositCollateral(address tokenCollateralAddress, uint256 amountToCollateral) external;
```

# Mint DSC:

```solidity
function mintDsc(uint256 amountDscToMint) external;
```

Redeem Collateral:

```solidity
function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral) external;
```

#Liquidate Under-Collateralized Positions:

```solidity
function liquidate(address collateral, address user, uint256 debtToCover) external;
```

# Testing

The project includes a suite of tests written in Solidity using Foundry. To run the tests, use the following command:

```
forge test
```

# License

This project is licensed under the MIT License. See the LICENSE file for more details.
