// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CampusVaultNFT is ERC721, Ownable { //NFT contract for CampusVault Membership
    uint256 private _tokenCounter; //tokencountre tracks the next token ID

mapping(uint256 => string) private _tokenURI; //stores the metadata URI for each token
 

    event NFTMinted(address indexed owner, uint256 indexed tokenId, string initialDataURI); //emitted whenever a new NFT is minted


    constructor()
        ERC721("CampusVault Membership", "CVM")
        Ownable(msg.sender){

        }
    

     function tokenURI(uint256 tokenId) public view override returns (string memory) { //this function returns the metadata URI for given token
        //make sure the token has been minted 
        require(_ownerOf(tokenId) != address(0), "Nonexistent token");
        return _tokenURI[tokenId]; //return the metadata URI for this token
    }
   
    //ONLY OWNER can mint a membership NFT to a recipient 
    function mint(address recipient, string calldata metadataURI) external onlyOwner returns (uint256) {
        uint256 tokenId = _tokenCounter; //take the current token num and store in tokenID for the NFT to use

        _tokenCounter++; //increment the counter by 1 so the next NFT minted gets a different ID 

        //mint the NFT to a given recipient
        _mint(recipient, tokenId);

       
        _tokenURI[tokenId] = metadataURI;  //store the metadata URI string
        
        //emit the event for a new NFT to be minted
        emit NFTMinted(recipient, tokenId, metadataURI); 
        return tokenId;
    }


   

  


}