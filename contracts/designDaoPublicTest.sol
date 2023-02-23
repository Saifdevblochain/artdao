// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./LinkedList.sol";

interface IFxStateChildTunnel {
    function sendMessageToRoot(bytes memory message) external;
}

contract DaoPublicTest is Initializable, LinkedList {
    using SafeMathUpgradeable for uint;
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
    uint public nftIndex;
    uint public time;

    uint[] public winnersIdexes;

    mapping(uint => NFTInfo) public nftInfoo;

    mapping(uint => mapping(address => bool)) public voteCheck;
    mapping(uint => mapping(address => bool)) public isclaimed;

    modifier onlydaoCommitte() {
        require(
            msg.sender == address(daoCommittee),
            "Only DaoCommitte can call"
        );
        _;
    }

    event PublicVote(address voter, uint index, NFTInfo _NFT);
    event NftApproved(uint index, NFTInfo _NFT, uint startTime);
    event Winner(uint index, NFTInfo _NFT);
    event claimed(address claimedBy, uint indexClaimed, uint amountClaimed);

    function initialize(address _daoCommitteeContract) public initializer {
        daoCommittee = _daoCommitteeContract;
        __LinkedList_init();
    }

    function setValues(
        uint _time,
        uint _timer,
        IFxStateChildTunnel _FxStateChildTunnel
    ) public {
        time = _time;
        timer = block.timestamp + _timer;
        FxStateChildTunnel = _FxStateChildTunnel;
    }


    function addInfo(
        string calldata uri,
        address _owner,
        bool _isApprovedByCommittee
    ) external onlydaoCommitte {
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

        NFTInfo storage x = nftInfoo[index];

        x.votes++;
        insertUp(index);
        voteCheck[index][msg.sender] = true;

        nftInfoo[index].votersCount++;
        isclaimed[index][msg.sender] = false;

        emit PublicVote(msg.sender, index, nftInfoo[index]);

        if (block.timestamp >= timer) {
            announceWinner();
        } else {
            return;
        }
    }

    function announceWinner() public {
        (bool isValid, uint index) = getHighest();

        if (isValid && !nftInfoo[index].winnerStatus) {
            nftInfoo[index].winnerStatus = true;
            nftInfoo[index].winTime = timer;
            winnersIdexes.push(index);
            FxStateChildTunnel.sendMessageToRoot(abi.encode(nftInfoo[index].owner, 720 ether));
            remove(index);

            emit Winner(index, nftInfoo[index]);
        }
        uint dayz = (block.timestamp.sub(timer.sub(time))).div(time);
        timer = timer.add(dayz.mul(time));
    }

    function claim(uint index) public {
        require(nftInfoo[index].winnerStatus == true, "Can not Claim");
        require(voteCheck[index][msg.sender] == true, "You have not voted");
        require(isclaimed[index][msg.sender] == false, "Already Claimed");

        uint amount = 180 ether / (nftInfoo[index].votersCount);
        FxStateChildTunnel.sendMessageToRoot(abi.encode(msg.sender, amount));

        // processToRoot( msg.sender, 180 ether/amount );
        // voteCheck[index][msg.sender] = false;
        isclaimed[index][msg.sender] = true;

        emit claimed(msg.sender, index,amount);
    }

    function claimBatch(uint[] memory indexes) public {
        uint totalAmount;
        for (uint i; i < indexes.length; ++i) {
            require(nftInfoo[indexes[i]].winnerStatus == true, "Can't Claim");

            require(
                voteCheck[indexes[i]][msg.sender] == true,
                "You have not voted"
            );
            require( isclaimed[indexes[i]][msg.sender] == false,"Already Claimed");
            uint amount = nftInfoo[indexes[i]].votersCount;
            totalAmount += amount;
            isclaimed[indexes[i]][msg.sender] =true;
            emit claimed(msg.sender,indexes[i], amount);
        }
        
        FxStateChildTunnel.sendMessageToRoot(
            abi.encode(msg.sender, totalAmount)
        );
    }

    function setTimer(uint _time) public {
        time = _time;
    }

    function updateDaoCommitteeAddress(address _address) public {
        daoCommittee = _address;
    }

    function setFxStateChildTunnel(IFxStateChildTunnel _FxStateChildTunnel) public {
        FxStateChildTunnel=_FxStateChildTunnel;
    }

}
