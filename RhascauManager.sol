// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./PaymentChannel.sol";

interface IRhascauRanks {
    function safeMint(address _to) external;
    function upgradeRanking(address _user, uint8 _newRank) external;
    function getUsersTokenURI(address _user) external view returns(string memory);
}

contract RhascauManager is EIP712, Ownable {

    string private constant SIGNING_DOMAIN = "Rhascau";
    string private constant SIGNATURE_VERSION = "1";
    
    uint8 private rankIndex = 102;
    uint8 public currentSezon;
    address public rhascauContract;
    address public rhascauRanks;
    IRhascauRanks rhascauRanksContract;

    //events
    event RankUpdated(address _user, uint8 _newRank);
    event RankingIncreased(address _user, uint256 _amount);

    //debug events
    event DebugMessage(Message msg);
    event DebugString(string msg);
    event DebugUint(uint256 msg);

    constructor(address _rhascauContract, address _rhascauRanksContract) EIP712(SIGNING_DOMAIN,SIGNATURE_VERSION) {
        rhascauContract = _rhascauContract;
        rhascauRanks = _rhascauRanksContract;
        rhascauRanksContract = IRhascauRanks(_rhascauRanksContract);
    }

    struct Message {
        address owner;
        address pilot;
        string content;
    }

    struct UserStats {
        uint256 gamesPlayed;
        uint256 gamesWon;
    }

    mapping (address => address) public burnerToUser;
    mapping (address => mapping(uint8 => uint256)) public userToRankingPerSezon;
    mapping (address => address) public userToChannel;
    mapping (address => UserStats) userStats;
    
    function initiateChannel(Message calldata _message, bytes calldata _signature) external payable
    {
        require(msg.sender == recover(_message,_signature), "Rhascau Manager: Invalid signature, you can't create the channel");
        PaymentChannel c = (new PaymentChannel){value: msg.value}(msg.sender, _message.pilot, address(this));
        burnerToUser[_message.pilot] = msg.sender;
        userToChannel[msg.sender] = address(c);
    }

    function getPlayerAddress(address _burner) external view returns (address) {
        return burnerToUser[_burner];
    }

    function changeSezon(uint8 _newSezon) external onlyOwner {
        currentSezon = _newSezon;
    }

    function changeRankIndex(uint8 _newIndex) external onlyOwner {
        rankIndex = _newIndex;
    }

    //signature verifier
    function recover(Message calldata _message, bytes calldata _signature) 
    public view 
    returns (address) 
    {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Message(address owner,address pilot,string content)"),
            _message.owner,
            _message.pilot,
            keccak256(bytes(_message.content))
        )));
        address signer = ECDSA.recover(digest,_signature);
        return signer;
    }

    //ranks
    function assignRank(address _user) external {
        rhascauRanksContract.safeMint(_user);
    }

    function getUserRank(address _user) public view returns(string memory) {
        string memory userURI = rhascauRanksContract.getUsersTokenURI(_user);
            string memory userRank = sliceString(userURI, rankIndex, rankIndex + 1);
            return userRank;
    }

    function updateRanking() public {
        uint256 currentRanking = userToRankingPerSezon[msg.sender][currentSezon];
        string memory currentRank = getUserRank(msg.sender);
        if(currentRanking > 1000 && currentRanking <= 5000) {
            if(compareStrings(currentRank, "1")) revert("Rhascau Manager: You alredy have this rank, this would be a waste of gas");
            else 
            {
                rhascauRanksContract.upgradeRanking(msg.sender, 1);
                emit RankUpdated(msg.sender, 1);
            }
        }
        else if (currentRanking > 5000 && currentRanking <= 10000) {
            if(compareStrings(currentRank, "2")) revert("Rhascau Manager: You alredy have this rank, this would be a waste of gas");
            else 
            {
                rhascauRanksContract.upgradeRanking(msg.sender, 2);
                emit RankUpdated(msg.sender, 2);
            }
        }
        else if (currentRanking > 10000 && currentRanking <= 20000) {
            if(compareStrings(currentRank, "3")) revert("Rhascau Manager: You alredy have this rank, this would be a waste of gas");
            else 
            {
                rhascauRanksContract.upgradeRanking(msg.sender, 3);
                emit RankUpdated(msg.sender, 3);
            }
        }
        else if (currentRanking > 20000 && currentRanking <= 50000) {
            if(compareStrings(currentRank, "4")) revert("Rhascau Manager: You alredy have this rank, this would be a waste of gas");
            else 
            {
                rhascauRanksContract.upgradeRanking(msg.sender, 4);
                emit RankUpdated(msg.sender, 4);
            }
        }
        else if (currentRanking > 50000 && currentRanking <= 150000) {
            if(compareStrings(currentRank, "5")) revert("Rhascau Manager: You alredy have this rank, this would be a waste of gas");
            else 
            {
                rhascauRanksContract.upgradeRanking(msg.sender, 5);
                emit RankUpdated(msg.sender, 5);
            }
        }
        else if (currentRanking > 150000) {
            if(compareStrings(currentRank, "6")) revert("Rhascau Manager: You alredy have this rank, this would be a waste of gas");
            else 
            {
                rhascauRanksContract.upgradeRanking(msg.sender, 6);
                emit RankUpdated(msg.sender, 6);
            }
        }
        else if (currentRanking <= 1000) {
            revert("Rhascau Manager: You alredy have this rank, this would be a waste of gas");
        }
        else revert("Rhascau Manager: Unspecified error occured");
    }

    //update user stats
    function updateUserStats(address _user, bool _won) external {
        require(msg.sender == rhascauContract, "Rhascau manager: This method can be called only by Rhascau contract");
        if(_won) userStats[_user].gamesWon += 1;
        userStats[_user].gamesPlayed += 1;
    }

    function increaseUserRanking(uint256 _amount, address _user) external {
        require(msg.sender == rhascauContract, "Rhascau manager: This method can be called only by Rhascau contract");
        userToRankingPerSezon[_user][currentSezon] += _amount;
        emit RankingIncreased(_user, _amount);
    } 

    //getters
    function getUserStats(address _user) external view returns(uint256, uint256) {
        return (userStats[_user].gamesPlayed, userStats[_user].gamesWon);
    }

    function getUserRanking(address _user) external view returns(uint256) {
        return userToRankingPerSezon[_user][currentSezon];
    }

    //linked contracts
    function changeRhascauContract(address _newContract) external onlyOwner {
        rhascauContract = _newContract;
    }

    function changeRhascauRanksContract(address _newContract) external onlyOwner {
        rhascauRanks = _newContract;
        rhascauRanksContract = IRhascauRanks(_newContract);
    }

    //helpers
    function sliceString(string memory _string, uint _start, uint _end) internal pure returns (string memory) {
        bytes memory inputBytes = bytes(_string);
        uint len = _end - _start;
        bytes memory outputBytes = new bytes(len);
        for (uint8 i = 0; i < len; i++) {
            outputBytes[i] = inputBytes[i+_start];
        }
        return string(outputBytes);
    }

    function compareStrings(string memory _str1, string memory _str2) internal pure returns (bool) 
    {
        return keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2));
    }
}