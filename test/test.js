const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("KBMarket", function(){
    it("Should mint and trade TFTs", async function(){
        const Market = await ethers.getContractFactory("KBMarket");
        const market = await Market.deploy();
        await market.deployed();
        const marketAddress = market.address;

        const NFT = await ethers.getContractFactory("NFT");
        const nft = await NFT.deploy(marketAddress);
        await nft.deployed();
        const nftContractAddress = nft.address;

        //Test to receive listing price
        let listingPrice = await market.getListingPrice();
        listingPrice = listingPrice.toString();

        const auctionPrice = ethers.utils.parseUnits('100','ether');

        //Test for mint
        await nft.mintToken('https-t1');
        await nft.mintToken('https-t2');

        await market.makeMarketItem(nftContractAddress, 1, auctionPrice, {value:listingPrice});
        await market.makeMarketItem(nftContractAddress, 2, auctionPrice, {value:listingPrice});

        //Test for different address for different users - test accounts
        //Return an array of however many addresses
        const [_,buyerAddress] = await ethers.getSigners();

        //Create a market sale with address, id and sale
        await market.connect(buyerAddress).createMarketSale(nftContractAddress,1, {
            value: auctionPrice
        })

        let items = await market.fetchMarketTokens();
        
        items = await Promise.all(items.map(async i => {
            const tokenURI = await nft.tokenURI(i.tokenId);
            let item = {
                price: i.price.toString(),
                tokenId: i.tokenId.toString(),
                seller: i.seller,
                owner: i.owner,
                tokenURI
            }
            return item;
        }))

        console.log('items',items);
    })
})