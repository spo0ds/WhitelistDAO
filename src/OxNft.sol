// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";

error NTNFT__CanOnlyMintOnce();
error NTNFT__NotNFTOwner();
error NTNFT__NftNotTransferrable();

contract OxNft is
    ERC721,
    ERC721Pausable,
    Ownable,
    ERC721Burnable,
    EIP712,
    ERC721Votes
{
    uint256 private _nextTokenId;
    mapping(address => bool) private _minter;

    constructor(
        address initialOwner
    ) ERC721("Oxy", "Ox") Ownable(initialOwner) EIP712("Oxy", "1") {}

    modifier onlyOnceMint() {
        if (_minter[msg.sender]) {
            revert NTNFT__CanOnlyMintOnce();
        }
        _;
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://ipfs.io/ipfs/Qmcx9T9WYxU2wLuk5bptJVwqjtxQPL8SxjgUkoEaDqWzti?filename=BasicNFT.png";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint() public onlyOnceMint {
        uint256 tokenId = _nextTokenId++;
        _minter[msg.sender] = true;
        _safeMint(msg.sender, tokenId);
    }

    function burn(uint tokenId) public override {
        if (ownerOf(tokenId) != msg.sender) {
            revert NTNFT__NotNFTOwner();
        }
        delete _minter[msg.sender];
        _burn(tokenId);
    }

    function hasMinted(address minter) external view returns (bool) {
        return _minter[minter];
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Pausable, ERC721Votes) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Votes) {
        super._increaseBalance(account, value);
    }

    /// @notice Function disabled as cannot transfer a soulbound nft
    function transferFrom(address, address, uint256) public pure override {
        revert NTNFT__NftNotTransferrable();
    }

    /// @notice Function disabled as cannot transfer a soulbound nft
    function approve(address, uint256) public pure override {
        revert NTNFT__NftNotTransferrable();
    }

    /// @notice Function disabled as cannot transfer a soulbound nft
    function setApprovalForAll(address, bool) public pure override {
        revert NTNFT__NftNotTransferrable();
    }

    /// @notice Function disabled as cannot transfer a soulbound nft
    function getApproved(uint256) public pure override returns (address) {
        revert NTNFT__NftNotTransferrable();
    }

    /// @notice Function disabled as cannot transfer a soulbound nft
    function isApprovedForAll(
        address,
        address
    ) public pure override returns (bool) {
        revert NTNFT__NftNotTransferrable();
    }

    function getTokenId() public view returns (uint256) {
        return _nextTokenId;
    }
}
