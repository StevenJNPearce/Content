pragma solidity ^0.5.0;

import "./SafeMath.sol";

contract Plasma {
  using SafeMath for uint256;
  address public operator;
  uint public currentPlasmaBlock;
  uint public currentDepositBlock;

  uint public BLOCK_BUFFER = 1000;

  mapping(uint => PlasmaBlock) public plasmaChain;

  struct PlasmaBlock {
      bytes32 root;
      uint256 timestamp;
  }
  
  constructor() public {
    operator = msg.sender;
    currentPlasmaBlock = BLOCK_BUFFER;
    currentDepositBlock = 1;
  }
}