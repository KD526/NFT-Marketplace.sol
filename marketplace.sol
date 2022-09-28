// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract NFT is ERC721URIStorage {
    // used when incrementing or decrementing
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  address contractAddress;

  constructor(address marketplaceAddress) ERC721 ("Ticket minter", "STMM") {
      contractAddress = marketplaceAddress;
  }

    //
  function createToken(string memory tokenURI) public returns (uint) {
      _tokenIds.increment();
      uint256 newItemId = _tokenIds.current();
      _mint(msg.sender, newItemId);
      _setTokenURI(newItemId, tokenURI);
      setApprovalForAll(contractAddress, true);
      return newItemId;
  }
}

contract NFTTickectMarket is ReentrancyGuard {

    using Counters for Counters.Counter;
    Counters.Counter private itemsIds;
    Counters.Counter private _itemsSold;
    //to keep track of the owner of this address
    address payable owner;
    uint256 listingPrice = 10 ether;

    constructor () {
        //whoever deploys this contract is the owner
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
    }
    mapping(uint256 => MarketItem) private idToMarketItem;
    event MarketItemCreated(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );
//function to allow user to put a ticket/item for sell
//payable because the function can receive payment

function createMarketItem (
    address nftContract,
     uint256 tokenId,
     uint256 price

    ) public payable nonReentrant {
        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == listingPrice, "Price must be equal to listing price");
        itemsIds.increment();
        uint256 itemId = itemsIds.current();
        idToMarketItem[itemId] = MarketItem (
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price
        );
        //transfer ownership of this nft from the person sending the tx to the address of this contract
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price
        );
    }
//function to do the actual sell of the nFT ticket
function createMarketSale (
        address nftContract,
        uint256 itemId
    ) public payable nonReentrant {
        //using the mapping to access the price and token id of nft ticket
        uint price = idToMarketItem[itemId].price;

        uint tokenId = idToMarketItem[itemId].tokenId;

        require(msg.value == price, "Please submit the asking price in order to complete the purchase");
        //transfer the eth value that is sent in this tx to the address of the seller
        idToMarketItem[itemId].seller.transfer(msg.value);
        //do the actual transfer of the nft to the new owner from the nftContract
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        //set the new owner of the nft
        idToMarketItem[itemId].owner = payable(msg.sender);
        //increment items being sold by 1 to keep track of items sold
        _itemsSold.increment();
      //transfer the amout of the listing price to the owner of this contract
        payable(owner).transfer(listingPrice);
 }
//function to fetch current market items/ticket for sale
function fetchMarketItems() public view returns (MarketItem[] memory){
    //total number of items created so far
    uint itemCount = itemsIds.current();
    //number of items not yet sold
    uint unsoldItemCount = itemCount - _itemsSold.current();
    uint currentIndex = 0;
    //variable for holding an array of all market items/tickets seting it to a new array with the length on unsoldItems
    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
     for(uint i =0; i< itemCount; i++) {
         if(idToMarketItem[i + 1].owner == address(0)) {
             uint currentId =idToMarketItem[i + 1].itemId;
             MarketItem storage currentItem = idToMarketItem[currentId];
             items[currentIndex] = currentItem;
             currentIndex += 1;
         }
     }
     return items;
}
  //function to return items purchased
function fetchMyNFTs()public view returns(MarketItem[] memory) {
      uint totalItemCount = itemsIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;
      for(uint i=0; i < totalItemCount; i++){
          if(idToMarketItem[i + 1].owner == msg.sender) {
              itemCount += 1;
          }
      }
   MarketItem[] memory items = new MarketItem[](itemCount);
    for(uint i =0; i< itemCount; i++) {
         if(idToMarketItem[i + 1].owner == msg.sender){
             uint currentId =idToMarketItem[i + 1].itemId;
             MarketItem storage currentItem = idToMarketItem[currentId];
             items[currentIndex] = currentItem;
             currentIndex += 1;
         }
     }
   return items;
  }
  //functionality to allow owner of market place to get some fee every time a new item is purchased
}










