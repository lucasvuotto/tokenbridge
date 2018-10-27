pragma solidity ^0.4.24;

import "./Transferable.sol";

contract FederatedManager {
    address owner;
    address[] public members;
    
    mapping(bytes32 => address[]) votes;
    mapping(bytes32 => bool) processed;
    
    Transferable public transferable;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address[] _members) public {
        members = _members;
        owner = msg.sender;
    }
    
    function setTransferable(Transferable _transferable) public onlyOwner {
        require(transferable == address(0));
        transferable = _transferable;
    }
    
    function isMember(address _account) public view returns(bool) {
        uint n = members.length;
        
        for (uint16 k = 0; k < n; k++)
            if (members[k] == _account)
                return true;
                
        return false;
    }
    
    function voteTransaction(uint _blockNumber, bytes32 _blockHash, bytes32 _transactionHash, address _receiver, uint _amount) 
        public 
    {
        require(isMember(msg.sender));
        
        bytes32 voteId = getTransactionVoteId(_blockNumber, _blockHash, _transactionHash, _receiver, _amount);
        
        if (processed[voteId])
            return;

        address[] storage transactionVotes = votes[voteId];
        uint n = transactionVotes.length;
        
        for (uint16 k = 0; k < n; k++)
            if (transactionVotes[k] == msg.sender)
                return;
        
        transactionVotes.push(msg.sender);
        
        if (transactionVotes.length < members.length / 2 + 1)
            return;
            
        if (transferable.acceptTransfer(_receiver, _amount)) {
            delete votes[voteId];
            processed[voteId] = true;
        }
    }
    
    function transactionVotes(uint _blockNumber, bytes32 _blockHash, bytes32 _transactionHash, address _receiver, uint _amount) 
        public view returns(address[]) 
    {
        bytes32 voteId = getTransactionVoteId(_blockNumber, _blockHash, _transactionHash, _receiver, _amount);
        
        return votes[voteId];
    }
    
    function getTransactionVoteId(uint _blockNumber, bytes32 _blockHash, bytes32 _transactionHash, address _receiver, uint _amount)
        public pure returns(bytes32)
    {
        return keccak256(abi.encodePacked(_blockNumber, _blockHash, _transactionHash, _receiver, _amount));
    }
}

