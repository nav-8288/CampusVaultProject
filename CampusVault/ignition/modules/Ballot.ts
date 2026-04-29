import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("BallotModule", (m) => {
  const numProposals = 4;
  const ballot = m.contract("Ballot", [numProposals]);

  return { ballot };
});
