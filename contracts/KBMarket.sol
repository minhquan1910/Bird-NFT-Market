//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
// security against transactions for multiple requests
import 'hardhat/console.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract KBMarket is Ownable{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _tokensSold;

    address payable _owner; 
    
    // Mint fee
    uint256 listingPrice = 0.045 ether;

    constructor() {
    //set the owner
    // convert address to payable address
    _owner = payable(msg.sender);
    }

     // Token Market

    struct MarketToken {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    // tokenId return which MarketToken -  fetch which one it is 

    mapping(uint256 => MarketToken) private idToMarketToken;

    // listen to events from front end applications
    event MarketTokenMinted(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    // get the listing price
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }
    // set the listing price
    function setListingPrice(uint256 price) public onlyOwner(){
        listingPrice = price;
    }

    // two functions to interact with contract
    // 1. create a market item to put it up for sale
    // 2. create a market sale for buying and selling between parties

    function makeMarketItem(
        address nftContract,
        uint tokenId,
        uint price
    )
    public payable  {
    // nonReentrant is a modifier to prevent reentry attack

    require(price > 0, 'Price must be at least one wei');
    require(msg.value == listingPrice, 'Price must be equal to listing price');

    _tokenIds.increment();
    uint itemId = _tokenIds.current();

    //putting it up for sale - bool - no owner
    idToMarketToken[itemId] = MarketToken(
        itemId,
        nftContract,
        tokenId,
        payable(msg.sender),
        payable(address(0)),
        price,
        false
    );

    // NFT transaction
    // Send token from token minted caller to contract 
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

    emit MarketTokenMinted(
        itemId,
        nftContract,
        tokenId,
        msg.sender,
        address(0),
        price,
        false
    );
    }
    // function to conduct transactions and market sales 

    function createMarketSale(
        address nftContract,
        uint itemId) 
        public payable {
            uint price = idToMarketToken[itemId].price;
            uint tokenId = idToMarketToken[itemId].tokenId;
            require(msg.value == price, 'Please submit the asking price in order to continue');

            // transfer the amount to the seller
            idToMarketToken[itemId].seller.transfer(msg.value);
            // transfer the token from contract address to the buyer
            IERC721(nftContract).transferFrom(address(this),msg.sender, tokenId);
            idToMarketToken[itemId].owner = payable(msg.sender);
            idToMarketToken[itemId].sold = true;
            _tokensSold.increment(); 

            payable(_owner).transfer(listingPrice);
        }

    // function to fetchMarketItems - minting, buying ans selling
    // return the number of unsold items

    function fetchMarketTokens() public view returns(MarketToken[] memory) {
        uint itemCount = _tokenIds.current();
        uint unsoldItemCount = _tokenIds.current() - _tokensSold.current();
        uint currentIndex = 0;

        // looping over the number of items created (if number has not been sold populate the array)
        MarketToken[] memory items = new MarketToken[](unsoldItemCount);
        for(uint i = 0; i < itemCount;) {
            if(idToMarketToken[i + 1].owner == address(0)) {
                uint currentId = i + 1;
                MarketToken memory currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem; 
                currentIndex += 1;
            }
            unchecked{
                ++i;
            }
        } 
        return items; 
    }

    // return nfts that the user has purchased

    function fetchMyNFTs() public view returns (MarketToken[] memory) {
        uint totalItemCount = _tokenIds.current();
        // a second counter for each individual user
        uint itemCount = 0;
        uint currentIndex = 0;

        for(uint i = 0; i < totalItemCount;) {
            if(idToMarketToken[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
            unchecked {
                ++i;
            }
        }

        // second loop to loop through the amount you have purchased with itemcount
        // check to see if the owner address is equal to msg.sender

        MarketToken[] memory items = new MarketToken[](itemCount);
        for(uint i = 0; i < totalItemCount;) {
            if(idToMarketToken[i +1].owner == msg.sender) {
                uint currentId = idToMarketToken[i + 1].itemId;
                // current array
                MarketToken memory currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
            unchecked {
                ++i;
            }
        }
        return items;
    }

    // function for returning an array of minted nfts
    function fetchItemsCreated() public view returns(MarketToken[] memory) {
        // instead of .owner it will be the .seller
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for(uint i = 0; i < totalItemCount;) {
            if(idToMarketToken[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
            unchecked {
                ++i;
            }
        }

        // second loop to loop through the amount you have purchased with itemcount
        // check to see if the owner address is equal to msg.sender

        MarketToken[] memory items = new MarketToken[](itemCount);
        for(uint i = 0; i < totalItemCount;) {
            if(idToMarketToken[i +1].seller == msg.sender) {
                uint currentId = idToMarketToken[i + 1].itemId;
                MarketToken memory currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
            unchecked {
                ++i;
            }
        }
        return items;
    }
}
