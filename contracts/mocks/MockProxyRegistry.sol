pragma solidity ^0.6.10;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev A simple mock ProxyRegistry for use in local tests with minimal security
 */
contract MockProxyRegistry is Ownable {
  mapping(address => address) public proxies;


  /**
   * @notice Allow the owner to set a proxy for testing
   * @param _address           The address that the proxy will act on behalf of
   * @param _proxyForAddress  The proxy that will act on behalf of the address
   */
  function setProxy(address _address, address _proxyForAddress)
      external
      onlyOwner()
  {
      proxies[_address] = _proxyForAddress;
  }
}
