import { ethers, run } from "hardhat";
import { ContractTransaction } from "ethers";

import { ether } from "../utils/common";

async function main() {
  console.log('-------------- Deployment Start --------------');

  const { chainId } = await ethers.provider.getNetwork();
  const accounts = await ethers.getSigners();
  
  console.log('------------- Deployment Completed ------------');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
