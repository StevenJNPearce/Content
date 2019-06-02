const deployContract = require('../deployingAContract');
const assert = require('assert');
const { bytecode } = require('../setup')
describe('deployContract', function() {
    it('deploys the contract', async () => {
        const contract = await deployContract()
        
        assert(bytecode === (await contract.getCode())) // is provider connected ?
    });
});