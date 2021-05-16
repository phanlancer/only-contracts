pragma solidity ^0.6.10;

import { ERC1155Tradable } from "./ERC1155/ERC1155Tradable.sol";

/**
 * @title OnlyCollectible
 * OnlyCollectible - a contract for Only semi-fungible tokens.
 */
contract OnlyCollectible is ERC1155Tradable {
  /**
   * TODO: set the base metadata URI
   */
  constructor(address _proxyRegistryAddress)
    public
    ERC1155Tradable(
      "OnlyCollectible",
      "OCB",
      _proxyRegistryAddress
    ) {
    _setBaseMetadataURI("should be replaced with the ONLY uri");
  }

  /**
   * TODO: Get the contract URI
   */
  function contractURI() public view returns (string memory) {
    return "should be replaced with the ONLY uri";
  }
}
