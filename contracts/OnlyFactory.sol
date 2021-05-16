pragma solidity ^0.6.10;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { IFactory } from "./interfaces/IFactory.sol";
import { ProxyRegistry } from "./ERC1155/ProxyRegistry.sol";
import { OnlyCollectible } from "./OnlyCollectible.sol";
import { Strings } from "./lib/Strings.sol";

// TODO: WIP
contract MyFactory is IFactory, Ownable, ReentrancyGuard {
  using Strings for string;
  using SafeMath for uint256;

  address public proxyRegistryAddress;
  address public nftAddress;
  string constant internal baseMetadataURI = "https://api.only.com/should/be/changed";
  uint256 constant UINT256_MAX = ~uint256(0);

  /**
   * Optionally set this to a small integer to enforce limited existence per option/token ID
   * (Otherwise rely on sell orders on Only, which can only be made by the factory owner.)
   */
  uint256 constant SUPPLY_PER_TOKEN_ID = UINT256_MAX;

  /**
   * Three different options for minting MyCollectibles (basic, premium, and gold).
   */
  enum Option {
    Basic,
    Premium,
    Gold
  }
  uint256 constant NUM_OPTIONS = 3;
  mapping (uint256 => uint256) public optionToTokenID;

  constructor(address _proxyRegistryAddress, address _nftAddress) public {
    proxyRegistryAddress = _proxyRegistryAddress;
    nftAddress = _nftAddress;
  }

  /////
  // IFACTORY METHODS
  /////

  function name() external view override returns (string memory) {
    return "My Collectible Pre-Sale";
  }

  function symbol() external view override returns (string memory) {
    return "MCP";
  }

  function supportsFactoryInterface() external view override returns (bool) {
    return true;
  }

  function factorySchemaName() external view override returns (string memory) {
    return "ERC1155";
  }

  function numOptions() external view override returns (uint256) {
    return NUM_OPTIONS;
  }

  function canMint(uint256 _optionId, uint256 _amount) external view override returns (bool) {
    return _canMint(msg.sender, Option(_optionId), _amount);
  }

  function mint(uint256 _optionId, address _toAddress, uint256 _amount, bytes calldata _data) external override nonReentrant() {
    return _mint(Option(_optionId), _toAddress, _amount, _data);
  }

  function uri(uint256 _optionId) external view override returns (string memory) {
    return Strings.strConcat(
      baseMetadataURI,
      "factory/",
      Strings.uint2str(_optionId)
    );
  }

  /**
   * @dev Main minting logic implemented here!
   */
  function _mint(
    Option _option,
    address _toAddress,
    uint256 _amount,
    bytes memory _data
  ) internal {
    require(_canMint(msg.sender, _option, _amount), "MyFactory#_mint: CANNOT_MINT_MORE");
    uint256 optionId = uint256(_option);
    OnlyCollectible nftContract = OnlyCollectible(nftAddress);
    uint256 id = optionToTokenID[optionId];
    if (id == 0) {
      id = nftContract.create(_toAddress, _amount, "", _data);
      optionToTokenID[optionId] = id;
    } else {
      nftContract.mint(_toAddress, id, _amount, _data);
    }
  }

  /**
   * Get the factory's ownership of Option.
   * Should be the amount it can still mint.
   * NOTE: Called by `canMint`
   */
  function balanceOf(
    address _owner,
    uint256 _optionId
  ) public view override returns (uint256) {
    if (!_isOwnerOrProxy(_owner)) {
      // Only the factory owner or owner's proxy can have supply
      return 0;
    }
    uint256 id = optionToTokenID[_optionId];
    if (id == 0) {
      // Haven't minted yet
      return SUPPLY_PER_TOKEN_ID;
    }

    OnlyCollectible nftContract = OnlyCollectible(nftAddress);
    uint256 currentSupply = nftContract.totalSupply(id);
    return SUPPLY_PER_TOKEN_ID.sub(currentSupply);
  }

  /**
   * Hack to get things to work automatically on Only.
   * Use safeTransferFrom so the frontend doesn't have to worry about different method names.
   */
  function safeTransferFrom(
    address /* _from */,
    address _to,
    uint256 _optionId,
    uint256 _amount,
    bytes calldata _data
  ) external override {
    _mint(Option(_optionId), _to, _amount, _data);
  }

  //////
  // Below methods shouldn't need to be overridden or modified
  //////

  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view override returns (bool) {
    return owner() == _owner && _isOwnerOrProxy(_operator);
  }

  function _canMint(
    address _fromAddress,
    Option _option,
    uint256 _amount
  ) internal view returns (bool) {
    uint256 optionId = uint256(_option);
    return _amount > 0 && balanceOf(_fromAddress, optionId) >= _amount;
  }

  function _isOwnerOrProxy(
    address _address
  ) internal view returns (bool) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    return owner() == _address || address(proxyRegistry.proxies(owner())) == _address;
  }
}
