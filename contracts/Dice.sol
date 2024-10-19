// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.0;

contract Dice {
    //enum
    enum diceState {
        stationary,
        rolling
    }

    //variables
    uint256 luckyTimes = 0;
    uint256 public numDices = 0;

    //structs
    struct dice {
        uint8 numberOfSides;
        uint8 color;
        uint8 currentNumber;
        diceState state;
        uint256 creationValue;
        address owner;
        address prevOwner;
    }
    
    //events
    event rolling(uint256 diceId);
    event rolled(uint256 diceId, uint8 newNumber);
    event DiceTransferred(uint256 diceId, address from, address to);

    //mapping, basically an array
    mapping(uint256 => dice) public dices;

    //modifiers
    modifier ownerOnly(uint256 diceId) {
        //ensures a function is callable only by its owner
        require(dices[diceId].owner == msg.sender, "only the owner can transfer the dice");
        _;
    }

    modifier validDiceId(uint256 diceId) {
        //check valid of diceId
        require(diceId < numDices);
        _;
    }

    //functions
    function destroyDice(uint256 diceId)
        public
        ownerOnly(diceId) 
        validDiceId(diceId) 
        returns (uint256)
    {
        uint256 eth = dices[diceId].creationValue;
        //delete from state variable
        delete dices[diceId];
        return eth;
    }

    function add(uint8 numberOfSides, uint8 color)
        public
        payable
        returns (uint256)
    {
        //to create a new dice, and add to 'dices' map. requires at least 0.01ETH to create
        require(numberOfSides > 0);
        require(
            msg.value >= 0.01 ether,
            "at least 0.01 ETH is needed to spawn a new dice"
        );

        //new dice object using the structs
        dice memory newDice = dice(
            numberOfSides,
            color,
            (uint8)(block.timestamp % numberOfSides) + 1, //currentNumber
            diceState.stationary, //state
            msg.value, //creationValue
            msg.sender, //owner
            address(0) //prevOwner
        );

        uint256 newDiceId = numDices++;
        dices[newDiceId] = newDice; //commit to state variable
        return newDiceId; //return new diceId
    }

    function roll(uint256 diceId) 
        public 
        ownerOnly(diceId) 
        validDiceId(diceId) 
    {
        //roll a dice
        dices[diceId].state = diceState.rolling; //set state to rolling
        dices[diceId].currentNumber = 0; //number will become 0 while rolling
        emit rolling(diceId); //emit rolling event
    }

    function stopRoll(uint256 diceId)
        public
        ownerOnly(diceId)
        validDiceId(diceId)
    {
        //stop a rolling dice
        dices[diceId].state = diceState.stationary; //set state to stationary
        uint8 newNumber = (uint8)((block.timestamp * (diceId + 1)) % dices[diceId].numberOfSides) + 1; 
            //this is not a secure randomization
        dices[diceId].currentNumber = newNumber;
        emit rolled(diceId, newNumber); //emit rolled

        //check if the roll is max
        if (newNumber == dices[diceId].numberOfSides) luckyTimes++;
    }

    function transfer(uint256 diceId, address newOwner)
        public
        ownerOnly(diceId)
        validDiceId(diceId)
    {
        address prevOwner = dices[diceId].owner;
        //transfer ownership to new owner
        dices[diceId].prevOwner = dices[diceId].owner;
        dices[diceId].owner = newOwner;
        emit DiceTransferred(diceId, prevOwner, newOwner);
    }
    
    function amOwner(uint256 diceId)
        public
        view
        validDiceId(diceId)
        returns(bool)
    {
        return dices[diceId].owner == msg.sender;
    }

    //getters
    function getLuckyTimes()
        public
        view
        returns (uint256)
    {
        //get lucky times
        return luckyTimes;
    }

    function getDiceSides(uint256 diceId)
        public
        view
        validDiceId(diceId)
        returns (uint8)
    {
        //get number of sides of dice
        return dices[diceId].numberOfSides;
    }

    function getDiceNumber(uint256 diceId)
        public
        view
        validDiceId(diceId)
        returns (uint8)
    {
        //get current dice number
        return dices[diceId].currentNumber;
    }

    function getOwner(uint256 diceId)
        public
        view
        validDiceId(diceId)
        returns (address)
    {
        //get current dice number
        return dices[diceId].owner;
    }

    function getPrevOwner(uint256 diceId)
        public
        view
        validDiceId(diceId)
        returns (address)
    {
        //get current dice number
        return dices[diceId].prevOwner;
    }

    function getDiceValue(uint256 diceId)
        public
        view
        validDiceId(diceId)
        returns (uint256)
    {
        //get ether put in during creation
        return dices[diceId].creationValue;
    }

    function getDices(address ownerAddress)
        public
        view
        returns (uint256[] memory)
    {
         // Calculate how many dice are owned by the address
        uint256 count = 0;
        for (uint256 i = 0; i < numDices; i++) {
            if (dices[i].owner == ownerAddress) {
                count++;
            }
        }

        // Create a new array to hold the result
        uint256[] memory ownedDices = new uint256[](count);

        // Populate the array with dice IDs
        uint256 index = 0;
        for (uint256 i = 0; i < numDices; i++) {
            if (dices[i].owner == ownerAddress) {
                ownedDices[index] = i;
                index++;
            }
        }

        return ownedDices;
    }
}
