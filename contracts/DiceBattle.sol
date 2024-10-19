pragma solidity ^0.5.0;
import "./Dice.sol";

contract DiceBattle {
    Dice diceContract;

    //mappings
    mapping(address => address) battle_pair;

    // Events
    event add_enemy(address player1, address player2);
    event BattleStarted(address player1, address player2, uint256 player1Dice, uint256 player2Dice);
    event battlewin(address winner, uint256 winningDiceId);
    event BattleDraw(address player1, uint256 player1Dice, address player2, uint256 player2Dice);

    //constructors
    constructor(Dice diceAddress) public {
        diceContract = diceAddress;
    }

    //functions 
    function setBattlePair(address enemy) public {
        // Require that only prev owner can allow an enemy
        uint256[] memory diceOwned = diceContract.getDices(address(this));
        bool check = false;
        for (uint256 i = 0; i < diceOwned.length; i++) {
            if (diceContract.getPrevOwner(diceOwned[i]) == msg.sender) {
                check = true;
                break;
            }
        }
        require(check, "You need to transfer a dice first");


        // Each player can only select one enemy
        require(msg.sender != enemy, "You cannot battle yourself.");
        require(battle_pair[msg.sender] == address(0) || battle_pair[enemy] == msg.sender, "You have already chosen an enemy or the enemy did not choose you as enemey.");
        require(battle_pair[enemy] == address(0) || battle_pair[enemy] == msg.sender, "Enemy must agree to battle.");

        // Set the battle pair
        battle_pair[msg.sender] = enemy;

        //emit event
        emit add_enemy(msg.sender, enemy);
    }

    function battle(uint256 myDiceId, uint256 enemyDiceId) public {
        // Require that battle_pairs align, ie each player has accepted a battle with the other
        address enemy = battle_pair[msg.sender];

        require(diceContract.getOwner(myDiceId) == address(this), "the dice was not transfered to this contract"); //check if dice is transfered to this contract
        require(diceContract.getOwner(enemyDiceId) == address(this), "enemy dice was not transfered to this contract"); //check if enemy dice is transfered to this contract
        require(diceContract.getPrevOwner(myDiceId) == msg.sender, "You must own the dice entered."); // check if the dice is owned by the user
        require(enemy != address(0), "You do not have a battle pair."); //check if there is a pair
        require(battle_pair[diceContract.getPrevOwner(enemyDiceId)] == msg.sender, "enemy did not set you as battlepair"); //check if enemy have set you as enemy
        require(diceContract.getPrevOwner(enemyDiceId) == enemy, "Enemy must own the dice entered."); // check if the dice is owned by enemy

        // Run battle
        emit BattleStarted(msg.sender, enemy, myDiceId, enemyDiceId);

        // Start the battle by rolling both dice
        diceContract.roll(myDiceId);
        diceContract.roll(enemyDiceId);

        // Stop the rolls and get the results
        diceContract.stopRoll(myDiceId);
        diceContract.stopRoll(enemyDiceId);

        uint8 myRoll = diceContract.getDiceNumber(myDiceId);
        uint8 enemyRoll = diceContract.getDiceNumber(enemyDiceId);

        address userAdd = msg.sender;
        address enemyAdd = battle_pair[userAdd];

        // Determine the winner
        if (myRoll > enemyRoll) {
            // Transfer both dice to user
            emit battlewin(msg.sender, myDiceId);
            diceContract.transfer(myDiceId, userAdd);
            diceContract.transfer(enemyDiceId, userAdd);
        } else if (enemyRoll > myRoll) {
            // Transfer both dice to enemy
            emit battlewin(enemy, enemyDiceId);
            diceContract.transfer(myDiceId, enemyAdd);
            diceContract.transfer(enemyDiceId, enemyAdd);
        } else {
            // It's a draw, send dice back to their owner
            emit BattleDraw(msg.sender, myDiceId, enemy, enemyDiceId);
            diceContract.transfer(myDiceId, diceContract.getPrevOwner(myDiceId));
            diceContract.transfer(enemyDiceId, diceContract.getPrevOwner(enemyDiceId));
        }

        // Clear battle pair once the battle is over
        battle_pair[msg.sender] = address(0);
        battle_pair[enemy] = address(0);
    }

    //getters
    function getBattlePair(address player) public view returns (address) {
        return battle_pair[player];
    }
    
    //setters
}