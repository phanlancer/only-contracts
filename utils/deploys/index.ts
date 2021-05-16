import { Signer } from "ethers";

import DeployCoreContracts from "./deployCoreContracts";
import DeployExternalContracts from "./deployExternal";

export default class DeployHelper {
  public core: DeployCoreContracts;
  public external: DeployExternalContracts;

  constructor(deployerSigner: Signer) {
    this.core = new DeployCoreContracts(deployerSigner);
    this.external = new DeployExternalContracts(deployerSigner);
  }
}
