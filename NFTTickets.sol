pragma solidity ^0.8.0;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC721/IERC721Receiver.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC721/ERC721.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/math/SafeMath.sol";

contract NFTTickets is ERC721URIStorage {
    using SafeMath for uint256;
    
    uint256 internal tokenID = 0;
    
    bytes32 constant EmptyString = 0x569e75fc77c1a856f6daaf9e69d8a9566ca34aa47f9133711ce065a571af0cfd;
    bytes32 constant NullHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
    
    // Authorized Addresses
    mapping (address => bool) internal authorizedContract;
    mapping (address => bool) internal contractOwners;
    
    // NFT Registry
    mapping (bytes32 => bool) internal ticketHashExistsMap;
    mapping (bytes32 => NFTTicketStruct) public TicketHashRegistry;
    mapping (bytes32 => address) internal TicketHashRegistryOwner;
    
    // NFT Struct
    struct NFTTicketStruct {
        string _tokenURI;
        uint256 maxTicketNumber;
        uint256 ticketCount;
    }
    
    // Set up events here
    event successBoolMessage(bool, string);
    
    constructor() ERC721 ("Ticket", "TKT"){
        // For testing purposes use a static contract
        authorizedContract[0xaE036c65C649172b43ef7156b009c6221B596B8b] = true;
        
        contractOwners[msg.sender] = true;
    }
    
    // Owner house keeping
    modifier onlyOwner {
        require(contractOwners[msg.sender], "Error: Not a contract owner");
        _;
    }
    
    function addContractOwner(address _ownerAddress) public onlyOwner {
        contractOwners[_ownerAddress] = true;
    }
    
    function removeContractOwner(address _ownerAddress) public onlyOwner {
        delete contractOwners[_ownerAddress];
    }
    
    // Authorized Contract housekeeping
    function addAuthorizedContract (address _thisContract) public onlyOwner {
        // TODO: Prove it's a contract by verifying function selector?
        authorizedContract[_thisContract] = true;
        
        
        emit successBoolMessage(true, string(abi.encodePacked("Contract is authorized")));
    }
    
    function removeAuthorizedContract (address _thisContract) public onlyOwner {
        delete authorizedContract[_thisContract];
        
        emit successBoolMessage(true, string(abi.encodePacked("Contract has been removed")));
    }
    
    function isSelfAuthorizedContractOrOwner () internal view returns (bool) {
        return isAuthorizedContractOrOwner(msg.sender);
    }
    
    function isAuthorizedContractOrOwner (address _thisContract) internal view returns (bool) {
        return (contractOwners[_thisContract] || authorizedContract[_thisContract]);
    }
    
    // TicketHash housekeeping
    function ticketHashExists(bytes32 _thisTicketHash) internal view returns (bool) {
        return ticketHashExistsMap[_thisTicketHash];
    }
    
    function isTicketHashOwner(bytes32 _thisTicketHash) internal view returns (bool) {
        bool isHashOwner = false;
        
        if (ticketHashExists(_thisTicketHash)){
            if (TicketHashRegistryOwner[_thisTicketHash] == msg.sender) {
                isHashOwner = true;
            }
        }
        
        return isHashOwner;
    }
    
    // NFT Generation
    function registerNewEventTicket (bytes32 _ticketHash, string memory _tokenURI, uint256 _maxTickets) public returns (bytes32) {
        if (!ticketHashExists(_ticketHash)){
            if (isSelfAuthorizedContractOrOwner()){
                // Create our new ticket in the system
                ticketHashExistsMap[_ticketHash] = true;
                TicketHashRegistryOwner[_ticketHash] = msg.sender;
                TicketHashRegistry[_ticketHash] = NFTTicketStruct(_tokenURI, _maxTickets, 0);
                
                emit successBoolMessage(true, string(abi.encodePacked("Success: Webhash registered")));
                
                return _ticketHash;
            } else {
                emit successBoolMessage(false, string(abi.encodePacked("Error: Not authorized")));
                return NullHash; 
            }
        } else {
            emit successBoolMessage(false, string(abi.encodePacked("Error: Webhash exists returning null address")));
            return NullHash;
        }
    }
    
    // Minting Operations 
    function getNextTokenID() internal returns (uint256) {
        return ++tokenID;
    }
    
    function generateNewTicketNFT (bytes32 _ticketHash) public returns (uint256) {
        if (isSelfAuthorizedContractOrOwner()){
            if (isTicketHashOwner(_ticketHash)){
                NFTTicketStruct storage _thisNFT = TicketHashRegistry[_ticketHash];
                uint256 _thisTokenID = getNextTokenID();
                
                if (_thisNFT.maxTicketNumber == 0 || _thisNFT.ticketCount < _thisNFT.maxTicketNumber) {
                    _mint(msg.sender, _thisTokenID);
                    _setTokenURI(_thisTokenID, _thisNFT._tokenURI);
                    _thisNFT.ticketCount = _thisNFT.ticketCount + 1;
                    
                    emit successBoolMessage(false, string(abi.encodePacked("Success: Ticket created.")));
                    return _thisTokenID;
                } else {
                    // Ticket max hit
                    emit successBoolMessage(false, string(abi.encodePacked("Error: Max tickets reached")));
                    return 0;
                }

            } else {
                // Not the ticket hash owner
                emit successBoolMessage(false, string(abi.encodePacked("Error: Not ticket hash owner")));
                return 0;
            }
        } else {
            // Not authorized
            emit successBoolMessage(false, string(abi.encodePacked("Error: Not authorized")));
            return 0;
        }
    }
}