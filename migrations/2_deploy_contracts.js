const Dice = artifacts.require('Dice');
const DiceBattle = artifacts.require('DiceBattle');
const DiceMarket = artifacts.require('DiceMarket');

module.exports = function (deployer) {
    deployer.deploy(Dice)
    .then(() => {
        return deployer.deploy(DiceBattle, Dice.address);
    }).then(() => {
        return deployer.deploy(DiceMarket, 1, Dice.address);
    });
};
