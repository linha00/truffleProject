const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require('truffle-assertions');
var assert = require('assert');

var Dice = artifacts.require('../contracts/Dice.sol');
var DiceBattle = artifacts.require('../contracts/DiceBattle.sol');
var DiceMarket = artifacts.require('../contracts/DiceMarket.sol');

contract('DiceBattle', function(accounts) {
    
    before(async () => {
        diceInstance = await Dice.deployed();
        diceBattleInstance = await DiceBattle.deployed();
        diceMarketInstance = await DiceMarket.deployed();
    });
    console.log('testing trade contract');

    it('Get Dice', async () => {
        let makeD1 = await diceInstance.add(1, 1, {from: accounts[1], value: 1000000000000000000});
        let makeD2 = await diceInstance.add(30, 1, {from: accounts[2], value: 1000000000000000000});
    
        assert.notStrictEqual(
            makeD1,
            undefined,
            "Failed to make dice"
        );
    
        assert.notStrictEqual(
            makeD2,
            undefined,
            "Failed to make dice"
        );
    });

    it('transfer ownership of dice', async () => {
        let t1 = await diceInstance.transfer(0, diceBattleInstance.address, {from: accounts[1]});
        let t2 = await diceInstance.transfer(1, diceBattleInstance.address, {from: accounts[2]});
    
        let enemy_adj1 = await diceBattleInstance.setBattlePair(accounts[2], {from: accounts[1]});
        let enemy_adj2 = await diceBattleInstance.setBattlePair(accounts[1], {from: accounts[2]});
    
        truffleAssert.eventEmitted(enemy_adj1, 'add_enemy');
        truffleAssert.eventEmitted(enemy_adj2, 'add_enemy');
    });
    
    it('DiceBattle working properly', async () => {
        let doBattle = await diceBattleInstance.battle(0, 1, {from: accounts[1]});

        try {
            truffleAssert.eventEmitted(doBattle, 'battlewin');
        } catch (e) {
            truffleAssert.eventEmitted(doBattle, 'BattleDraw');
        }
    });

    it('DiceMarket: creation of dice', async () => {
        let makeD = await diceInstance.add(6, 1, {from: accounts[3], value: 1000000000000000000});
        assert.notStrictEqual(
            makeD,
            undefined,
            "Failed to make dice"
        );
    });

    it('DiceMarket: creation of dice without vlaue', async () => {
        await truffleAssert.fails(
            diceInstance.add(1, 1, {from: accounts[3], value: 0}),
            truffleAssert.ErrorType.REVERT,
            "at least 0.01 ETH is needed to spawn a new dice"
        );
    });

    it('DiceMarket: transfer of dice to diceMarket', async () => {
        let diceId = await diceInstance.add(6, 1, {from: accounts[3], value: 1000000000000000000});
        let transferTx = await diceInstance.transfer(2, diceMarketInstance.address, {from: accounts[3]});
        
        // check if the dice is transferred
        truffleAssert.eventEmitted(transferTx, 'DiceTransferred');

        // check if the dice owner is the DiceMarket contract
        let newOwner = await diceInstance.getOwner(2);
        assert.strictEqual(newOwner, diceMarketInstance.address, "Dice ownership wasn't transferred to the DiceMarket contract.");
    });

    it('DiceMarket: cannot list dice if price is less than creation value + commission', async () => {
        // Attempt to list at a price less than the minimum price
        await truffleAssert.fails(
            diceMarketInstance.list(2, 1000, {from: accounts[3]}), // price in finney
            truffleAssert.ErrorType.REVERT,
            "Selling price needs to be >= value + commission fee"
        );
    });
    
    it('DiceMarket: list dice if price is more than creation value + commission', async () => {
        // Attempt to list at a price more than the minimum price
        let list = await diceMarketInstance.list(2, 1001, {from: accounts[3]});
        truffleAssert.eventEmitted(list, 'diceListed');
    });

    it('DiceMarket: owner unlist dice', async () => {
        // Attempt to unlist with another account
        await truffleAssert.fails(
            diceMarketInstance.unlist(2, {from: accounts[1]}),
            truffleAssert.ErrorType.REVERT,
            "You are not the seller"
        );

        // Attempt to unlist with the correct account
        let unlist = await diceMarketInstance.unlist(2, {from: accounts[3]});
        truffleAssert.eventEmitted(unlist, 'diceUnlisted');
    });

    it('DiceMarket: buy dice', async () => {
        let list = await diceMarketInstance.list(2, 1001, {from: accounts[3]});
        truffleAssert.eventEmitted(list, 'diceListed');

        // Attempt to buy with the wrong amount
        await truffleAssert.fails(
            diceMarketInstance.buy(2, {from: accounts[1], value: 0}),
            truffleAssert.ErrorType.REVERT,
            "Price needs to be >= listing price (in Finney)"
        );

        // Attempt to buy with the correct account
        let buy = await diceMarketInstance.buy(2, {from: accounts[1], value: 1100000000000000000});
        truffleAssert.eventEmitted(buy, 'diceBought');
    });
})