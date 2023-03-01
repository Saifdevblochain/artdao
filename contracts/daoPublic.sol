// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./LinkedList.sol";

interface IFxStateChildTunnel {
    function sendMessageToRoot(bytes memory message) external;
    function SEND_MESSAGE_EVENT_SIG() external view returns(bytes32);
}

interface IDaoCommittee {
    function committeeMembersCounter() external view returns (uint);
}


contract DaoPublic is Initializable, LinkedList, OwnableUpgradeable {
    using SafeMathUpgradeable for uint;

    uint public FIXED_DURATION ;

    IFxStateChildTunnel public FxStateChildTunnel;

    struct NFTInfo {
        string uri;
        address owner;
        uint index;
        uint votes;
        uint winTime;
        uint votersCount;
        uint favourVotes;
        uint disApprovedVotes;
        bool isApprovedByCommittee;
        bool winnerStatus;
        bool blackListed;
    }

    IDaoCommittee public daoCommittee;
    uint public timer;
    uint private nftIndex;

    uint[] public winnersIndexes;
    

    mapping(uint => NFTInfo) public nftInfoo;

    mapping(uint => mapping(address => bool)) public voteCheck;
    mapping(uint => mapping(address => bool)) public isclaimed;


    modifier onlyDaoCommitte() {
        require(msg.sender == address(daoCommittee), "Only DaoCommittee can call");
        _;
    }

    event PublicVote(address voter, uint index, NFTInfo _NFT);
    event NftApproved(uint index, NFTInfo _NFT, uint startTime);
    event Winner(uint index, NFTInfo _NFT);
    event claimed(address claimedBy, uint index, uint amount,uint claimTime,bytes32 eventSign);
    event blackListed(uint index, bool decision , NFTInfo _NFT);

    function initialize( IDaoCommittee _daoCommittee, uint _timer, uint FIXED_DURATION_ ) public initializer {
        __LinkedList_init();
        __Ownable_init();
        daoCommittee = _daoCommittee;
        timer = block.timestamp + _timer;
        FIXED_DURATION=FIXED_DURATION_;
    }

    function addInfo(
        string calldata uri,
        address _owner,
        bool _isApprovedByCommittee
    ) external onlyDaoCommitte {
        _addInfo(uri, _owner, _isApprovedByCommittee);
    }

    function _addInfo(
        string calldata uri,
        address _owner,
        bool _isApprovedByCommittee
    ) internal {
        nftInfoo[nftIndex] = NFTInfo(uri,_owner, nftIndex,0,_isApprovedByCommittee, false, 0, 0);
        emit NftApproved(nftIndex, nftInfoo[nftIndex], block.timestamp);
        nftIndex++;
    }

    function voteNfts(uint index) external {
        require(nftInfoo[index].winnerStatus == false, "Already winner");
        require(voteCheck[index][msg.sender] == false, "Already Voted");
        require(index < nftIndex, " Choose Correct NFT to vote ");

        NFTInfo storage nftToVote = nftInfoo[index];

        nftToVote.votes++;
        insertUp(index);
        voteCheck[index][msg.sender] = true;

        nftInfoo[index].votersCount++;
        isclaimed[index][msg.sender] = false;

        emit PublicVote(msg.sender, index, nftInfoo[index]);

        if (block.timestamp >= timer) {
            _announceWinner();
        }
    }

    function announceWinner() external {
        if (block.timestamp >= timer) {
            _announceWinner();
        }
    }

    function _announceWinner() internal {
        (bool isValid, uint index) = getHighest();

        if (isValid && !nftInfoo[index].winnerStatus) {
            nftInfoo[index].winnerStatus = true;
            nftInfoo[index].winTime = timer;
            winnersIndexes.push(index);
            FxStateChildTunnel.sendMessageToRoot(abi.encode(nftInfoo[index].owner, 720 ether));
            remove(index);
            emit Winner(index, nftInfoo[index]);
    emit claimed( nftInfoo[index].owner ,index, 720 ether, block.timestamp,FxStateChildTunnel.SEND_MESSAGE_EVENT_SIG() );

        }
        uint dDays = (block.timestamp.sub(timer.sub(FIXED_DURATION))).div(FIXED_DURATION);
        timer = timer.add(dDays.mul(FIXED_DURATION));
    }

    function claim(uint index) public {
    require(nftInfoo[index].winnerStatus == true,"Can't Claim");
    require( voteCheck[index][msg.sender] == true, "You have not voted");
    require( isclaimed[index][msg.sender]== false , "Already Claimed" );

    uint  amount = 180 ether/ (nftInfoo[index].votersCount);
    FxStateChildTunnel.sendMessageToRoot(abi.encode(msg.sender,amount));
    
    isclaimed[index][msg.sender]=  true;
    emit claimed(msg.sender , index, amount, block.timestamp, FxStateChildTunnel.SEND_MESSAGE_EVENT_SIG() );
    }


    function claimBatch(uint[] memory indexes) public {
    uint totalAmount;
    for(uint i; i < indexes.length; ++i) {
        require(nftInfoo[indexes[i]].winnerStatus == true, "Can't Claim");
        require( voteCheck[indexes[i]][msg.sender] == true, "You have not voted" );
        require( isclaimed[indexes[i]][msg.sender] == false,"Already Claimed");
        uint amount = nftInfoo[indexes[i]].votersCount;
        totalAmount += amount;
        isclaimed[indexes[i]][msg.sender] = true;
        emit claimed(msg.sender,indexes[i], 720 ether,block.timestamp, FxStateChildTunnel.SEND_MESSAGE_EVENT_SIG());
    }
    FxStateChildTunnel.sendMessageToRoot(
        abi.encode(msg.sender, totalAmount)
    );
    }

    function updateDaoCommitteeAddress(IDaoCommittee _address) external onlyOwner {
        daoCommittee = _address;
    }

    function setFxStateChildTunnel(IFxStateChildTunnel _FxStateChildTunnel) external onlyOwner {
        FxStateChildTunnel = _FxStateChildTunnel;
    }

    function setTimer (uint _FIXED_DURATION) public {
        FIXED_DURATION=_FIXED_DURATION;
    }

    function blackListArt(uint index, bool decision) public {
        require(nftInfoo[index].blackListed == false,"Already Blacklisted");
        uint votesTarget = (daoCommittee.committeeMembersCounter() / 2) + 1;

        // require either favour /disfavour votes < target votes, "already checked"
        require(nftInfoo[index].favourVotes < votesTarget || nftInfoo[index].disApprovedVotes < votesTarget,"already voted for check");
        if (block.timestamp >= timer) {
            _announceWinner();
        }

        if (decision == true) {
            nftInfoo[index].favourVotes++;

            if (nftInfoo[index].favourVotes >= votesTarget) {
                nftInfoo[index].blackListed = true;
            emit blackListed( index, decision, nftInfoo[index]);
            }

            // emit CommitteeVote(msg.sender, index, decision, nftStore[index]);
        } else {
            nftInfoo[index].disApprovedVotes++;
            // emit commite decision here and above too
            // emit CommitteeVote(msg.sender, index, decision, nftStore[index]);
        }
    }


   
}