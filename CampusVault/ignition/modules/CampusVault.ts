import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("CampusVaultModule", (m) => {

  /*deploy the CVLT FT */
  const token = m.contract("MyToken", ["CampusVault Token","CVLT",1000000,]); 

  
  const NFT = m.contract("contracts/CVM_NFT.sol:CampusVaultNFT");

  const membershipURI = "https://harlequin-tiny-pike-353.mypinata.cloud/ipfs/QmYrLKAdkb2TC2NJpNA5jP9BAzfp2HQ6mZNnw7kEb3mFVV";   /*metadata URI for CVM NFT */

  /*deploy vault and give it FT, NFT, and metadata URI */
  const vault = m.contract("Vault", [token, NFT, membershipURI]);

  m.call(NFT, "transferOwnership", [vault]); /*make the vault the owner of the NFT contract; since NFT functions are onlyOwner */

  return { token, NFT, vault };

});
