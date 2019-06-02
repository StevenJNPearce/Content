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

  // Deploy the contract. Pass "Hello world" to the contstructor

  // The contract is NOT deployed yet; we must wait until it is mined

};
