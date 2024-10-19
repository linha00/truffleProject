// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.0;

import "./Dice.sol"; 

contract DiceMarket {
    Dice diceContract;

    //variables
    uint256 public commissionFee; // in finney
    address public owner;

    //structs
    struct Listing {
        uint256 price; // Listing price of the dice //setting the price in finney
        address seller; // Address of the seller
    }

    //events
    event diceListed(uint256 diceId, uint256 price, address seller);
    event diceUnlisted(uint256 diceId);
    event diceBought(uint256 diceId, address buyer, uint256 price);

    //mappings
    mapping(uint256 => Listing) public listings;

    //modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier validBuyingPrice(uint256 diceId, uint256 price) {
        require(price >= listings[diceId].price, "Price needs to be >= listing price (in Finney)");
        _;
    }

    modifier isListed(uint256 diceId) {
        require(listings[diceId].price > 0, "Dice is not listed");
        _;
    }

    modifier notListed(uint256 diceId) {
        require(listings[diceId].price == 0, "Dice is already listed");
        _;
    }

    modifier isSeller(uint256 diceId) {
        require(listings[diceId].seller == msg.sender, "You are not the seller");
        _;
    }

    //Constructor
    constructor(uint256 _commissionFee, address diceAddress) public {
        owner = msg.sender;
        commissionFee = _commissionFee;
        diceContract = Dice(diceAddress);
    }

    //functions
    function list(uint256 diceId, uint256 price) 
        public
        notListed(diceId)
    {   

        uint256[] memory diceOwned = diceContract.getDices(address(this));
        bool check = false;
        for (uint256 i = 0; i < diceOwned.length; i++) {
            if (diceContract.getPrevOwner(diceOwned[i]) == msg.sender) {
                check = true;
                break;
            }
        }
        require(check, "You need to transfer a dice first");

        require(diceContract.getOwner(diceId) == address(this), "you need to transfer the dice to this contract first");

        require(price * 1 finney >= diceContract.getDiceValue(diceId) + commissionFee * 1 finney, 
            "Selling price needs to be >= value + commission fee");

         require(diceContract.getPrevOwner(diceId) == msg.sender, "You are not the owner of this dice");

        // List the dice on the market
        listings[diceId] = Listing({
            price: price,
            seller: msg.sender
        });

        emit diceListed(diceId, price, msg.sender);
    }

    function unlist(uint256 diceId)
        public
        isListed(diceId)
        isSeller(diceId)
    {
        delete listings[diceId];
        emit diceUnlisted(diceId);
    }

    function buy(uint256 diceId)
    public
    payable
    isListed(diceId)
    validBuyingPrice(diceId, msg.value)
    {
        Listing memory listing = listings[diceId];

        require(listing.seller != msg.sender, "You are the seller of the dice");

        // Transfer excess funds back to the buyer if overpaid
        if (msg.value > listing.price) {
            uint256 excessAmount = msg.value - listing.price;
            msg.sender.transfer(excessAmount);
        }

        // Transfer the funds to the seller minus the commission
        uint256 sellerProceeds = listing.price - commissionFee;
        address seller = listing.seller;
        address(uint160(seller)).transfer(sellerProceeds);

        // Transfer the commission to the marketplace owner
        address(uint160(owner)).transfer(commissionFee);

        // Transfer dice ownership to the buyer
        diceContract.transfer(diceId, msg.sender);

        // Remove the listing
        delete listings[diceId];

        emit diceBought(diceId, msg.sender, listing.price);
    }


    //setters
    function setCommission(uint256 _commissionFee) public onlyOwner {
        commissionFee = _commissionFee;
    }

    //getters
    function checkPrice(uint256 diceId) public view returns(uint256) {
        return listings[diceId].price;
    }
}