const { web3JS } = require('./web3Util.js');
const { Block, Transaction } = require('./plasmaObjects.js');
const { validateTransaction, NULL_ADDRESS, decodeUtxoId, encodeUtxoId } = require('./utils.js');

class PlasmaChain {
    constructor(operator, contractAddress, abi, web3=web3JS) {
        this.operator = operator;
        this.plasmaContract = new web3.eth.Contract(abi, contractAddress);
        this.blocks = {};
        this.blockBuffer = 1000;
        this.nextTxBlock = this.blockBuffer;
        this.currentBlock = new Block([], this.nextTxBlock);

        this.depositListener(this);
    }

    depositListener(self) {
        this.plasmaContract.events.DepositCreated({},
            function (err, event) {
                self.addDeposit(event);
            }
        );
    }

    addDeposit(event) {
        const args = event.returnValues;
        const { owner, amount, blockNumber } = args;
        const deposit = this.getDepositTx(owner, amount);
        this.blocks[blockNumber] = new Block([deposit], blockNumber);
    }

    addTransaction(tx) {
        validateTransaction(tx, this.blocks, this.currentBlock, this.currentBlock.spentUtxos);
        this.currentBlock.transactionSet.push(tx);
        return encodeUtxoId(this.currentBlock.blockNumber, this.currentBlock.transactionSet.length - 1, 0);
    }

    markUtxoSpent(utxoId) {
        const [blkNum, txIndex, oIndex] = decodeUtxoId(utxoId);
        const tx = this.getTransaction(utxoId);
        if(oIndex === 0) {
            tx.spent1 = true;
        } else {
            tx.spent2 = true;
        }
    }

    getTransaction(utxoId) {
        const [blkNum, txIndex, oIndex] = decodeUtxoId(utxoId);
        if(this.blocks[blkNum]) {
            return this.blocks[blkNum].transactionSet[txIndex];
        } else if(this.currentBlock.blockNumber === blkNum) {
            return this.currentBlock.transactionSet[txIndex];
        } else {
            return null;
        }
    }

    getDepositTx(owner, amount) {
        return new Transaction(0, 0, 0, 0, 0, 0, owner, amount, NULL_ADDRESS, 0);
    }
}

module.exports = PlasmaChain;