import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("CampusVaultModule", (m) => {
  const token = m.contract("MyToken", ["CampusVault Token","CVLT",1000000,]);

  const vault = m.contract("Vault", [token]);

  return { token, vault };

});
