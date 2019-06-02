const { ethers } = require('ethers');

const getProvider = () => ethers.getDefaultProvider()

module.exports = getProvider;