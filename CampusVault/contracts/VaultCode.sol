// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Vault {
    IERC20 public immutable token;

    /*connect this vault to the CVM NFT contract */
    CampusVaultNFT public membershipNFT; 

    string public membershipURI;
    

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    address public admin; /*administrator*/
    uint256 public feePercent;

    /* Governance Membership data structures */

    uint256 private _membershipTokenId;
    mapping(uint256 => address) public _ownerOfmembershipToken;
    mapping(address => uint256) public _balanceOfmembershipToken;
    mapping(address => uint256) public _membershipTokenOf;


    function _mintMembership(address to) internal {
        /*mint membership token if not already owned */

        /*if the membership token is already given to user, do NOT MINT AGAIN */
        /*each user should only get one NFT membership, even if they deposit multiple times */
        if(_membershipTokenOf[to] != 0){
            return;
        }

        /*mint the actual CVM NFT to the user so it can show up in metamask */
        uint256 tok_ID = membershipNFT.mint(to, membershipURI);


        /*keep track of which membership belongs to which specific user */
        _ownerOfmembershipToken[tok_ID] = to;

        /*log this user owning a membership token  */
        _balanceOfmembershipToken[to] = 1;

        /*connect the user address to their actual membership */
        _membershipTokenOf[to] = tok_ID; 
    }


    constructor(address _token, address _membershipNFT, string memory _membershipURI) {
        token = IERC20(_token);

        /*connect the vault to the real CVM NFT contract  */
        membershipNFT = CampusVaultNFT(_membershipNFT);

        /*metadata URI used when minting the membershipNFT */
        membershipURI = _membershipURI; 

        admin = msg.sender; /*whoever deploys the vault becomes the administrator */

        feePercent = 2; /*fee will be charged in the depositing token; fee will also be transferred to admin */
        

    }

    function _mint(address _to, uint256 _shares) private {
        totalSupply += _shares;
        balanceOf[_to] += _shares;

        /*also minting a membership*/
        _mintMembership(_to);
    
    }

    function _burn(address _from, uint256 _shares) private {
        totalSupply -= _shares;
        balanceOf[_from] -= _shares;
    }

    function deposit(uint256 _amount) external {
        /*
        a = amount (collateral)
        B = balance of token before deposit (total assets)
        T = total supply (total supply of vault tokens)
        s = shares to mint (new token to mint)

        (T + s) / T = (a + B) / B 

        s = aT / B
        */

        /*if the user is trying to deposit 0 tokens, revert it */
        if(_amount == 0){
            revert("error: cannot deposit 0 tokens, must be valid num starting @ 1");

        }



        uint256 shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / token.balanceOf(address(this));
        }

        _mint(msg.sender, shares);
        token.transferFrom(msg.sender, address(this), _amount);
    }

/*function to appreciate vault value based on users investment */
    function appreciateVaultValue(uint256 _amount) external{

        if(msg.sender != admin){ /*only the admin should be able to apply appreciation to vault */
            revert("error: only the admin can appreciate vault value");
        }

            /*the appreciation value has to be greater than 0 to be applied by admin  */
        if(_amount == 0){
            revert("error: appreciation amount has to be > 0");
        }

        /* admin transers extra CVLT into the vault to appreciate vaults value  */
        bool successful_transfer = token.transferFrom(msg.sender, address(this), _amount);

        /*if the transfer doesn't go through as expected */
        if(!successful_transfer){
            revert("error: vault appreciation transfer failed");
        }

    }

    function withdraw(uint256 _shares) external {
        /*
        a = amount
        B = balance of token before withdraw
        T = total supply
        s = shares to burn

        (T - s) / T = (B - a) / B 

        a = sB / T
        */

        /* user should not be allowed to withdraw 0 shares */
        if(_shares == 0){
            revert("error: cannot withdraw 0 shares");
        }

        /*ensure the user isn't trying to withdraw more shares than they have  */
        if(_shares > balanceOf[msg.sender]){
            revert("error: insufficient funds for this withdrawal");

        }


        uint256 grossAmount =
            (_shares * token.balanceOf(address(this))) / totalSupply;
        _burn(msg.sender, _shares);

        /* Take a fee for using the vault */
        uint256 fee = (grossAmount * feePercent) / 100;

        uint256 amount = grossAmount - fee; /* If the user were to withdraw 100 CVLT and the fee is 2%, then 
        the user will receive 98 CVLT while the admin will receive 2 CVLT */
        
        token.transfer(msg.sender, amount);
        token.transfer(admin, fee);

        /* you can implement revoking of governance membership here */


        /*if the user has fully withdrawn their investment */
        if(balanceOf[msg.sender] == 0){

            /*get the token ID of the users membership */
            uint256 tok_ID = _membershipTokenOf[msg.sender];

            membershipNFT.revoke_NFT(tok_ID); /*revoke the actual CVM NFT since the user fully withdrrew */


            /*remove the record for this membership tok */
            delete _ownerOfmembershipToken[tok_ID];


            _balanceOfmembershipToken[msg.sender] = 0; /*the user's membership balance should be 0 */

            delete _membershipTokenOf[msg.sender]; /*remove the record connecting this user to a membership tok */

        }


    }
    
}



interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner, address indexed spender, uint256 amount
    );

}

/*interface used so vault can call the CVM NFT contract */
interface CampusVaultNFT{

    /*mint CVM NFT to user when they deposit into the vault */
    function mint(address recipient, string calldata metadataURI) external returns (uint256);

    
    function revoke_NFT(uint256 tokenId) external; /*revoke the NFT when the user fully withdraws all funds */
}