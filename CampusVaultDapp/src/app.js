class App {
    constructor() {
        // deployed contract addresses from hardhat
        this.TokenAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
        this.VaultAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

        // abi files copied from hardhat artifacts
        this.TokenAbiLocation = "./CampusVaultToken.json";
        this.VaultAbiLocation = "./Vault.json";

        this.TokenABI = null;
        this.VaultABI = null;

        // these get filled in once metamask connects
        this.signer = null;
        this.tokenContract = null;
        this.vaultContract = null;

        this.walletConnected = false;
        this.userAddress = null;
    }

    async loadABI() {
        try {
            // load token ABI first
            const tokenResponse = await fetch(this.TokenAbiLocation);
            const tokenData = await tokenResponse.json();
            this.TokenABI = tokenData.abi;

            // load vault ABI second
            const vaultResponse = await fetch(this.VaultAbiLocation);
            const vaultData = await vaultResponse.json();
            this.VaultABI = vaultData.abi;

            console.log("Token ABI loaded successfully.", this.TokenABI);
            console.log("Vault ABI loaded successfully.", this.VaultABI);
        } catch (error) {
            console.error("Failed to load ABI:", error);
        }
    }

    async connectMetaMaskAndContract() {
        try {
            if (!window.ethereum) {
                alert("MetaMask not detected. Please install it.");
                return;
            }

            // make sure both ABI files are loaded before creating contract objects
            if (!this.TokenABI || !this.VaultABI) {
                await this.loadABI();
            }

            const provider = new ethers.providers.Web3Provider(window.ethereum);
            await provider.send("eth_requestAccounts", []);
            this.signer = provider.getSigner();

            // connect frontend to the token contract
            this.tokenContract = new ethers.Contract(
                this.TokenAddress,
                this.TokenABI,
                this.signer
            );

            // connect frontend to the vault contract
            this.vaultContract = new ethers.Contract(
                this.VaultAddress,
                this.VaultABI,
                this.signer
            );

            this.walletConnected = true;
            this.userAddress = await this.signer.getAddress();

            const overlay = document.getElementById("overlay");
            if (overlay) {
                overlay.style.display = "none";
            }

            const accountDisplay = document.getElementById("account");
            if (accountDisplay) {
                accountDisplay.textContent = this.userAddress;
            }

            console.log("Connected to MetaMask and contracts successfully.");
            console.log("User Address:", this.userAddress);

            await this.refreshBalances();

        } catch (error) {
            console.error("MetaMask connection failed:", error);
        }
    }

    async approveVault() {
        try {
            if (!this.walletConnected || !this.tokenContract) {
                toastr.error("Please connect your wallet first");
                return;
            }

            const amountInput = document.getElementById("approve-amount");
            const amountValue = amountInput.value.trim();

            if (!amountValue) {
                toastr.error("Please enter an amount to approve");
                return;
            }

            // convert the input amount into token units with 18 decimals
            const amount = ethers.utils.parseUnits(amountValue, 18);

            // user approves the vault to spend this amount of CVLT
            const tx = await this.tokenContract.approve(this.VaultAddress, amount);
            await tx.wait();

            console.log("Vault approval successful:", tx);
            toastr.success("Vault approved successfully!");

            amountInput.value = "";

        } catch (error) {
            console.error("Error approving vault:", error);
            toastr.error("Error approving vault: " + error.message);
        }
    }

    async depositTokens() {
        try {
            if (!this.walletConnected || !this.vaultContract) {
                toastr.error("Please connect your wallet first");
                return;
            }

            const amountInput = document.getElementById("deposit-amount");
            const amountValue = amountInput.value.trim();

            if (!amountValue) {
                toastr.error("Please enter an amount to deposit");
                return;
            }

            const amount = ethers.utils.parseUnits(amountValue, 18);

            // deposit CVLT into the vault, this gives the user vault shares
            const tx = await this.vaultContract.deposit(amount);
            await tx.wait();

            console.log("Deposit successful:", tx);
            toastr.success("Deposit successful!");

            amountInput.value = "";
            await this.refreshBalances();

        } catch (error) {
            console.error("Error depositing tokens:", error);
            toastr.error("Error depositing tokens: " + error.message);
        }
    }

    async appreciateVaultValue() {
        try {
            if (!this.walletConnected || !this.tokenContract || !this.vaultContract) {
                toastr.error("Please connect your wallet first");
                return;
            }

            const amountInput = document.getElementById("growth-amount");
            const amountValue = amountInput.value.trim();

            if (!amountValue) {
                toastr.error("Please enter an amount to add");
                return;
            }

            const amount = ethers.utils.parseUnits(amountValue, 18);

            /*
            The admin approves the vault first because appreciateVaultValue()
            uses transferFrom to move CVLT into the vault.
            */
            const approveTx = await this.tokenContract.approve(this.VaultAddress, amount);
            await approveTx.wait();

            /*
            This adds extra CVLT into the vault.
            Since shares stay the same but vault balance goes up,
            the user's shares become worth more CVLT.
            */
            const tx = await this.vaultContract.appreciateVaultValue(amount);
            await tx.wait();

            console.log("Vault value appreciated successfully:", tx);
            toastr.success("Vault value appreciated successfully!");

            amountInput.value = "";
            await this.refreshBalances();

        } catch (error) {
            console.error("Error appreciating vault value:", error);
            toastr.error("Error appreciating vault value: " + error.message);
        }
    }

    async withdrawTokens() {
        try {
            if (!this.walletConnected || !this.vaultContract) {
                toastr.error("Please connect your wallet first");
                return;
            }

            const shareInput = document.getElementById("withdraw-shares");
            const shareValue = shareInput.value.trim();

            if (!shareValue) {
                toastr.error("Please enter the amount of shares to withdraw");
                return;
            }

            const shares = ethers.utils.parseUnits(shareValue, 18);

            // withdraw burns vault shares and sends CVLT back minus the fee
            const tx = await this.vaultContract.withdraw(shares);
            await tx.wait();

            console.log("Withdrawal successful:", tx);
            toastr.success("Withdrawal successful!");

            shareInput.value = "";
            await this.refreshBalances();

        } catch (error) {
            console.error("Error withdrawing tokens:", error);
            toastr.error("Error withdrawing tokens: " + error.message);
        }
    }

    async refreshBalances() {
        try {
            if (!this.walletConnected || !this.tokenContract || !this.vaultContract) {
                toastr.error("Please connect your wallet first");
                return;
            }

            const userAddress = await this.signer.getAddress();

            // read user balances and membership info from contracts
            const userTokenBalance = await this.tokenContract.balanceOf(userAddress);
            const userVaultBalance = await this.vaultContract.balanceOf(userAddress);
            const membershipId = await this.vaultContract._membershipTokenOf(userAddress);

            // admin balance is useful because this shows the withdraw fee
            const adminAddress = await this.vaultContract.admin();
            const adminTokenBalance = await this.tokenContract.balanceOf(adminAddress);

            const accountDisplay = document.getElementById("account");
            const tokenBalanceDisplay = document.getElementById("token-balance");
            const vaultBalanceDisplay = document.getElementById("vault-balance");
            const membershipDisplay = document.getElementById("membership-id");
            const adminBalanceDisplay = document.getElementById("admin-balance");

            if (accountDisplay) {
                accountDisplay.textContent = userAddress;
            }

            if (tokenBalanceDisplay) {
                tokenBalanceDisplay.textContent = ethers.utils.formatUnits(userTokenBalance, 18);
            }

            if (vaultBalanceDisplay) {
                vaultBalanceDisplay.textContent = ethers.utils.formatUnits(userVaultBalance, 18);
            }

            if (membershipDisplay) {
                membershipDisplay.textContent = membershipId.toString();
            }

            if (adminBalanceDisplay) {
                adminBalanceDisplay.textContent = ethers.utils.formatUnits(adminTokenBalance, 18);
            }

            console.log("Balances refreshed successfully.");
            console.log("User CVLT Balance:", ethers.utils.formatUnits(userTokenBalance, 18));
            console.log("User Vault Shares:", ethers.utils.formatUnits(userVaultBalance, 18));
            console.log("Membership Token ID:", membershipId.toString());
            console.log("Admin CVLT Balance:", ethers.utils.formatUnits(adminTokenBalance, 18));

        } catch (error) {
            console.error("Error refreshing balances:", error);
            toastr.error("Error refreshing balances: " + error.message);
        }
    }

    async transferTokensToUser() {
        try {
            if (!this.walletConnected || !this.tokenContract) {
                toastr.error("Please connect your wallet first");
                return;
            }

            const addressInput = document.getElementById("transfer-address");
            const amountInput = document.getElementById("transfer-amount");

            const receiverAddress = addressInput.value.trim();
            const amountValue = amountInput.value.trim();

            if (!receiverAddress) {
                toastr.error("Please enter the user address");
                return;
            }

            if (!ethers.utils.isAddress(receiverAddress)) {
                toastr.error("Please enter a valid Ethereum address");
                return;
            }

            if (!amountValue) {
                toastr.error("Please enter an amount to transfer");
                return;
            }

            const amount = ethers.utils.parseUnits(amountValue, 18);

            // this is mainly used so the user account has CVLT for the demo
            const tx = await this.tokenContract.transfer(receiverAddress, amount);
            await tx.wait();

            console.log("Token transfer successful:", tx);
            toastr.success("CVLT transferred successfully!");

            addressInput.value = "";
            amountInput.value = "";

            await this.refreshBalances();

        } catch (error) {
            console.error("Error transferring tokens:", error);
            toastr.error("Error transferring tokens: " + error.message);
        }
    }
}


document.addEventListener("DOMContentLoaded", async () => {
    const myApp = new App();
    await myApp.connectMetaMaskAndContract();

    const approveButton = document.getElementById("approve-btn");
    if (approveButton) {
        approveButton.addEventListener("click", () => {
            myApp.approveVault();
        });
    }

    const depositButton = document.getElementById("deposit-btn");
    if (depositButton) {
        depositButton.addEventListener("click", () => {
            myApp.depositTokens();
        });
    }

    const growthButton = document.getElementById("growth-btn");
    if (growthButton) {
        growthButton.addEventListener("click", () => {
            myApp.appreciateVaultValue();
        });
    }

    const withdrawButton = document.getElementById("withdraw-btn");
    if (withdrawButton) {
        withdrawButton.addEventListener("click", () => {
            myApp.withdrawTokens();
        });
    }

    const refreshButton = document.getElementById("refresh-balances");
    if (refreshButton) {
        refreshButton.addEventListener("click", () => {
            myApp.refreshBalances();
        });
    }

    const transferButton = document.getElementById("transfer-btn");
    if (transferButton) {
        transferButton.addEventListener("click", () => {
            myApp.transferTokensToUser();
        });
    }

});
