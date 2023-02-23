// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin/contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "./LinkedList.sol";

interface IFxStateChildTunnel {
    function sendMessageToRoot(bytes memory message) external;
}

contract DaoPublic is Initializable, LinkedList, OwnableUpgradeable {
    using SafeMathUpgradeable for uint;

    uint public constant FIXED_DURATION = 86400;

    IFxStateChildTunnel public FxStateChildTunnel;

    struct NFTInfo {
        string uri;
        address owner;
        uint index;
        uint votes;
        bool isApprovedByCommittee;
        bool winnerStatus;
        uint winTime;
        uint votersCount;
    }

    address public daoCommittee;
    uint public timer;
    uint private nftIndex;

    uint[] public winnersIdexes;

    mapping(uint => NFTInfo) public nftInfoo;

    mapping(uint => mapping(address => bool)) public voteCheck;
    mapping(uint => mapping(address => bool)) public isclaimed;

    modifier onlyDaoCommitte() {
        require(msg.sender == address(daoCommittee), "Only DaoCommitte can call");
        _;
    }

    event PublicVote(address voter, uint index, NFTInfo _NFT);
    event NftApproved(uint index, NFTInfo _NFT, uint startTime);
    event Winner(uint index, NFTInfo _NFT);
    event claimed(address claimedBy, uint indexClaimed, uint amountClaimed);

    function initialize(
        address _daoCommittee,
        uint _fixedDuration,
        uint _timer
    ) public initializer {
        __LinkedList_init();
        __Ownable_init();
        daoCommittee = _daoCommittee;
        FIXED_DURATION = _fixedDuration;
        timer = block.timestamp + _timer;
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

    function voteNfts(uint index) public {
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
            winnersIdexes.push(index);
            // FxStateChildTunnel.sendMessageToRoot(abi.encode(nftInfoo[index].owner, 720 ether));
            remove(index);

            emit Winner(index, nftInfoo[index]);
        }
        uint dDays = (block.timestamp.sub(timer.sub(FIXED_DURATION))).div(FIXED_DURATION);
        timer = timer.add(dDays.mul(FIXED_DURATION));
    }

    function updateDaoCommitteeAddress(address _address) public onlyOwner {
        daoCommittee = _address;
    }

    function setFxStateChildTunnel(IFxStateChildTunnel _FxStateChildTunnel) public onlyOwner {
        FxStateChildTunnel = _FxStateChildTunnel;
    }
}