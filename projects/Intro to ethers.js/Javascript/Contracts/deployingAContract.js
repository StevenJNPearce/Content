const ethers = require("ethers");

const { bytecode, provider } = require("./setup");

const abi = [
  "event ValueChanged(address indexed author, string oldValue, string newValue)",
  "constructor(string value)",
  "function getValue() view returns (string value)",
  "function setValue(string value)"
];

module.exports = async () => {
  // Create an instance of a Contract Factory
  let factory = new ethers.ContractFactory(abi, bytecode, provider.getSigner());

  // Deploy the contract. Pass "Hello world" to the constructor
  let contract = await factory.deploy("Hello World");

  console.log(contract.address);

  console.log(contract.deployTransaction.hash);

  // Return a promise that will resolve when the deployment transaction has been mined.
  return contract.deployed();
};
