# CampusVault

CampusVault is a student-focused decentralized finance (DeFi) savings vault. It uses a custom fungible token (FT) called 'CVLT' (CampusVault Token), a non-fungible token (NFT) called 'CVM' (CampusVault Membership), a vault smart contract, and a simple frontend decentralized application (DApp).

The main idea is that students can deposit CVLT into the vault as a basic savings system. In return, they receive vault shares that represent their stake in the vault. While a user is invested, they also hold a CVM governance membership.

To model growth, the admin can add additional CVLT into the vault. When the vault balance increases, each user's vault shares appreciate in more CVLT than they originally invested, simulating the savings vault appreciating over time. 

When a user withdraws all of their vault shares, their membership is removed. The vault also charges a small 2% withdrawal fee, which goes to the admin/treasury to help keep the vault sustainable.

## Local Deployment Addresses

For my local Hardhat demo, the contracts were deployed at:


CampusVaultNFT: 0x5FbDB2315678afecb367f032d93F642f64180aa3
MyToken:        0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
Vault:          0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0

```text
# Demo Prerequisites Setup

## Overview
For this demo, you will need:
- Node.js
- npm 
- git

---

## Check if Node and npm are already installed

Open your terminal and run:

```bash
node -v
npm -v
````

* If you see version numbers, you are good to go.
* If not, follow the setup instructions below.

---

## Windows Users (Required)

You must install WSL2 and a Linux distribution (Ubuntu recommended) before installing Node.

Setup guide:
[https://oneuptime.com/blog/post/2026-03-02-ubuntu-wsl2-windows11-development/view](https://oneuptime.com/blog/post/2026-03-02-ubuntu-wsl2-windows11-development/view)

After installing, open your Ubuntu terminal and continue below.

---

## macOS and Linux Users

You can continue directly with the steps below.

---

## Install Node.js and npm using nvm 
using nvm (node version manager) is the best way to do it
### 1) Install nvm

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
```

or

```bash
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
```

---

### 2) Restart your terminal

This step is required before using nvm.

---

### 3) Install Node.js (LTS version)

```bash
nvm install --lts
```

---

### 4) Verify installation

```bash
node -v
npm -v
```

You should see version numbers (e.g., v20.x.x).

---

## Notes

* if these instructions dont work for you please check online resources to install node and npm in you machine


---

## Ready

Once Node.js and npm are installed, you are ready for the demo.



## hardhat chain ID

```bash
31337
```
