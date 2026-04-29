// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Vault {
    IERC20 public immutable token;
    

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    address public admin; //administrator
    uint256 public feePercent;

    // Governance Membership data structures

    uint256 private _membershipTokenId;
    mapping(uint256 => address) public _ownerOfmembershipToken;
    mapping(address => uint256) public _balanceOfmembershipToken;
    mapping(address => uint256) public _membershipTokenOf;


    function _mintMembership(address to) internal {
        //mint membership token if not already owned 

        /*if the membership token is already given to user, do NOT MINT AGAIN */
        /*each user should only get one NFT membership, even if they deposit multiple times */
        if(_membershipTokenOf[to] != 0){
            return;
        }

        _membershipTokenId++;   /*increment the membership token ID so each membership has unique ID */

        /*keep track of which membership belongs to which specific user */
        _ownerOfmembershipToken[_membershipTokenId] = to;

        /*log this user owning a membership token  */
        _balanceOfmembershipToken[to] = 1;

        /*connect the user address to their actual membership */
        _membershipTokenOf[to] = _membershipTokenId; 
    }


    constructor(address _token) {
        token = IERC20(_token);

        admin = msg.sender; /*whoever deploys the vault becomes the administrator */

        feePercent = 2; /*fee will be charged in the depositing token; fee will also be transferred to admin */
        

    }

    function _mint(address _to, uint256 _shares) private {
        totalSupply += _shares;
        balanceOf[_to] += _shares;

        //also minting a membership
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

        // Take a fee for using the vault
        uint256 fee = (grossAmount * feePercent) / 100;

        uint256 amount = grossAmount - fee; /* If the user were to withdraw 100 CVLT and the fee is 2%, then 
        the user will receive 98 CVLT while the admin will receive 2 CVLT */
        
        token.transfer(msg.sender, amount);
        token.transfer(admin, fee);

        // you can implement revoking of governance membership here

        /*if the user has fully withdrawn their investment */
        if(balanceOf[msg.sender] == 0){

            /*get the token ID of the users membership */
            uint256 tok_ID = _membershipTokenOf[msg.sender];

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