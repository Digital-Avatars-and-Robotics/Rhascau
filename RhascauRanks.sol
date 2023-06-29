// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
 
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Counters.sol"; 

contract RhascauRanks is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint8;

    event RankAssigned(address _user, uint256 _tokenId);

    address public rhascauManagerContract;
    string public constant baseExtension = ".json";
    string public baseURI = "ipfs://QmSz1f4greFUkcZGj4UBd6dYW9SMaigyncL15VhC8HqdRJ/";

    mapping(address => uint256) public userToToken;

    Counters.Counter private _tokenIdCounter;
    
    modifier alreadyOwner(address _user) {
        require(balanceOf(_user) == 0, "Rhascau Ranking: You can have only one rank");
        _;
    }

    modifier onlyRhascauManager() {
        require(msg.sender == rhascauManagerContract, "Rhascau Ranking: This function can be called only by Rhascau Manager");
        _;
    }

    constructor() ERC721("Rhascau Season I", "RSI") {}

    function safeMint(address _to) external 
    onlyRhascauManager 
    alreadyOwner(_to)
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        userToToken[_to] = tokenId;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(baseURI,"0",baseExtension)));
        emit RankAssigned(_to, tokenId);
    }

    function _beforeTokenTransfer(address from, address, uint256, uint256) internal override pure {
        require(from == address(0), "Rhascau Ranking: You can't transfer your ranking token");   
    }

    function upgradeRanking(address _user, uint8 _newRank) external 
    onlyRhascauManager 
    {
        _setTokenURI(userToToken[_user], string(abi.encodePacked(baseURI,(uint8(_newRank)).toString(),baseExtension)));
    }

    function changeRhascauManagerContract(address _newContract) external onlyOwner {
        rhascauManagerContract = _newContract;
    }

    function getUsersTokenURI(address _user) external view returns(string memory) { 
                return tokenURI(userToToken[_user]);
            }

    function getBaseURI() external view returns(string memory) {
        return baseURI;
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function tokenExists(uint256 tokenId) public view returns (bool) {
        return super._exists(tokenId);
    }
}
 