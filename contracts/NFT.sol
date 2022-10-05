// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    error ERC721_NonSelfApprove();
    error ERC721_Unauthorize();
    error ERC721_NotExist();
    error ERC721_NotOwner();

    address private marketplaceAddress;  
    mapping(uint256 => string) private _tokenURIs;

    constructor(address mrkplaceAddr) ERC721("",""){
        marketplaceAddress = mrkplaceAddr;
    }
    
    //Mint token
    function mintToken(string calldata _tokenURI) external returns(uint256){
        _tokenIds.increment();
        address sender = _msgSender();
        uint256 newTokenId = _tokenIds.current();
        //Mint token with Safe Mint
        _safeMint(sender, newTokenId);
        //Set Token URI with mapping 
        _setTokenURI(newTokenId, _tokenURI);
        //Approve transfer For marketplace
        setApprovalForAll(marketplaceAddress, true);
        return newTokenId;
    }

    //Set token URI function
    function _setTokenURI(uint256 _tokenId, string calldata _tokenURI) internal{
        if(!_exists(_tokenId)) revert ERC721_NotExist();
        _tokenURIs[_tokenId] = _tokenURI;
    }

    //Get token URI
    function tokenURI(uint256 tokenId) public view override returns(string memory){
        _requireMinted(tokenId);

        string memory base = _baseURI();
        string memory _tokenURI = _tokenURIs[tokenId];
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    //Set approve
    function _approveTransfer(address _to, uint256 tokenId) public {
        //Check if tokenId exists or not
        if(!_exists(tokenId)) revert ERC721_NotExist(); 
        //Not so approve owner self
        address owner;
        owner = ownerOf(tokenId);
        _nonSelfApprove(owner, _to);
        //Check msg.sender is owner or not 
        if(!(_msgSender() == owner)) revert ERC721_Unauthorize();
        _approve(_to, tokenId);
    }
    
    //Check non self approve
    function _nonSelfApprove(address _from, address _to) internal pure{
        if(_from == _to) revert ERC721_NonSelfApprove();
    }

    //Burn
    function burn(uint256 _tokenId) public{
        if(!(_msgSender() == ownerOf(_tokenId))) revert ERC721_NotOwner();
        _burn(_tokenId);
    }

}