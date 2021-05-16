pragma solidity ^0.6.10;
// contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => address) public proxies; // mapping address to OwnableDelegateProxy
}
