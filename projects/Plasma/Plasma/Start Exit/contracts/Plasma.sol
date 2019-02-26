pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./PriorityQueue.sol";
import "./PlasmaRLP.sol";
import "./Validate.sol";
import "./Merkle.sol";
import "./ByteUtils.sol";

contract Plasma {
  using SafeMath for uint256;
  using PlasmaRLP for bytes;
  using Merkle for bytes32;

  address public operator;
  uint public currentPlasmaBlock;
  uint public currentDepositBlock;

  uint public BLOCK_BUFFER = 1000;
  uint256 public EXIT_BOND = 1000000000000000000;

  mapping(uint => PlasmaBlock) public plasmaChain;
  mapping(uint256 => Exit) public exits;
  mapping(address => address) public exitQueues;

  event DepositCreated(
    address owner, 
    uint256 amount, 
    uint256 blockNumber
  );

  event ExitStarted(
    address exitor,
    uint256 utxoPos,
    address token,
    uint256 amount
  );

  struct PlasmaBlock {
      bytes32 root;
      uint256 timestamp;
  }

  struct Exit {
    address exitor;
    address token;
    uint256 amount;
  }
  
  constructor() public {
    operator = msg.sender;
    currentPlasmaBlock = BLOCK_BUFFER;
    currentDepositBlock = 1;
    exitQueues[address(0)] = address(new PriorityQueue());
  }

  function deposit() 
    public
    payable
  {
    bytes32 root = keccak256(abi.encodePacked(msg.sender, msg.value));
    uint256 blockNum = getDepositBlock();
    plasmaChain[blockNum] = PlasmaBlock(
      root,
      block.timestamp
    );
    emit DepositCreated(msg.sender, msg.value, blockNum);
    currentDepositBlock++;
  }

  function submitBlock(bytes32 _root) 
    public 
  {
    require(msg.sender == operator);
    plasmaChain[currentPlasmaBlock] = PlasmaBlock(_root, block.timestamp);
    currentPlasmaBlock += BLOCK_BUFFER;
    currentDepositBlock = 1; 
  }

  function addExitToQueue(uint256 _utxoPos, address _exitor, address _token, uint256 _amount, uint256 _createdAt)
    public
  {
    require(_amount > 0);
    require(exitQueues[_token] != address(0));
    require(exits[_utxoPos].amount == 0);
    PriorityQueue queue = PriorityQueue(exitQueues[_token]);

    uint256 exitableAt = _createdAt + 2 weeks;
    queue.insert(exitableAt, _utxoPos);

    exits[_utxoPos] = Exit(_exitor, _token, _amount);
    emit ExitStarted(_exitor, _utxoPos, _token, _amount);
  }

  function startExit(
        uint256 _utxoPos,
        bytes memory _txBytes,
        bytes memory _proof,
        bytes memory _sigs
    )
        public
        payable
    {
        require(msg.value == EXIT_BOND);
        uint256 blknum = _utxoPos / 1000000000;
        uint256 txindex = (_utxoPos % 1000000000) / 10000;
        uint256 oindex = _utxoPos - blknum * 1000000000 - txindex * 10000;

        // Check the sender owns this UTXO.
        PlasmaRLP.exitingTx memory exitingTx = _txBytes.createExitingTx(oindex);
        require(msg.sender == exitingTx.exitor, "Sender must be exitor.");
        // Check the transaction was included in the chain and is correctly signed.
        bytes32 root = plasmaChain[blknum].root;

        bytes32 merkleHash = keccak256(abi.encodePacked(keccak256(_txBytes), ByteUtils.slice(_sigs, 0, 130)));

        require(merkleHash.checkMembership(txindex, root, _proof), "Transaction Merkle proof is invalid.");
        require(Validate.checkSigs(keccak256(_txBytes), root, exitingTx.inputCount, _sigs), "Signatures must match.");
        address addr = exitingTx.exitor;
        address payable exitor = address(uint160(addr));

        addExitToQueue(_utxoPos, exitor, exitingTx.token, exitingTx.amount, plasmaChain[blknum].timestamp);
    }


  function getDepositBlock() 
    internal
    returns (uint256)
  {
      return currentPlasmaBlock.sub(BLOCK_BUFFER).add(currentDepositBlock);
  }
}