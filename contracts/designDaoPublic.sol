// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DaoPublic is Initializable {
   
    struct Position {   
        string uri;
        address owner;
        uint index;
        uint votes;
        uint position2D;
        // uint256 votes;
        bool isApprovedByCommittee;
        bool winnerStatus;
        uint winTime;
    }
   
    address public daoCommittee;
    uint public timer;
    using SafeMathUpgradeable for uint;
    uint public nftIndex;
    uint public time;
    uint public committeeMembersCounter;
    uint[] public winnersIdexes;

    Position[][] public allPositions;
    mapping(uint => mapping(address => bool)) public voteCheck;

    mapping (uint => Position ) public nftInfoo;

   

    modifier onlydaoCommitte {
        require(msg.sender == address(daoCommittee), "Only DaoCommitte can call");
        _;
    }

    event PublicVote(address voter, uint index , Position _NFT);
    event NftApproved(uint index, Position _NFT,uint startTime );
     
    event Winner(uint index, Position nftInfo);

    function initialize () initializer public {  
        allPositions.push();
    }
 
    function setValues (uint _time, address _daoCommitteeContract, uint _timer ) public {
        daoCommittee= _daoCommitteeContract;
        time= _time;
        timer= block.timestamp+_timer;
    }

    function addInfo (string calldata uri, address _owner, bool _isApprovedByCommittee )  external onlydaoCommitte {
       _addInfo(     uri,   _owner,   _isApprovedByCommittee);
    }

    function _addInfo(string calldata uri, address _owner, bool _isApprovedByCommittee) internal{
         nftInfoo[nftIndex] = Position(uri, _owner, nftIndex, 0, 0, _isApprovedByCommittee, false, 0);
        emit NftApproved(nftIndex,nftInfoo[nftIndex],block.timestamp );
        nftIndex++;
    }

    function checkLength(uint votes) external view returns (uint) {
        return allPositions[votes].length;
    }

    function voteNfts(uint index) public {
        require(nftInfoo[index].winnerStatus==false,"Already winner");
        require( voteCheck[index][msg.sender] == false, "Already Voted" );
        require( index < nftIndex , " Choose Correct NFT to vote ");
        // nftInfoo[index].votes++;
         
        Position storage x = nftInfoo[index];
        if (x.votes == 0) {
            x.votes = x.votes + 1;

            try this.checkLength(x.votes) returns (uint) {
            } catch {
                allPositions.push();
            }

            x.position2D = allPositions[x.votes].length;

            allPositions[x.votes].push(x);
        } else {
            uint lastPosition2D = allPositions[x.votes].length - 1;
 
            if (x.position2D != lastPosition2D) {
                uint lastIndex = allPositions[x.votes][lastPosition2D].index;
                Position storage y = nftInfoo[lastIndex];

                allPositions[x.votes][x.position2D] =
                    allPositions[x.votes][lastPosition2D];

                allPositions[x.votes][x.position2D].position2D = x.position2D;

                y.position2D = x.position2D;

                allPositions[x.votes].pop();
            }
            else {
                allPositions[x.votes].pop();
            }

            x.votes = x.votes + 1;

            try this.checkLength(x.votes) returns (uint) {
            } catch {
                allPositions.push();
            }

            x.position2D = allPositions[x.votes].length;

            allPositions[x.votes].push(x);
        }
        voteCheck[index][msg.sender] = true;
        emit PublicVote( msg.sender, index, nftInfoo[index] );
        if(block.timestamp>=timer){
            announceWinner();
        }
    }
           
    function announceWinner() public {
        if(block.timestamp>=timer){
            uint winner = allPositions[allPositions.length - 1][0].index;

            Position storage x = nftInfoo[winner];

            uint lastPosition2D = allPositions[x.votes].length - 1;
 
            if (x.position2D != lastPosition2D) {
                uint lastIndex = allPositions[x.votes][lastPosition2D].index;
                Position storage y = nftInfoo[lastIndex];

                allPositions[x.votes][x.position2D] =
                    allPositions[x.votes][lastPosition2D];

                allPositions[x.votes][x.position2D].position2D = x.position2D;

                y.position2D = x.position2D;

                allPositions[x.votes].pop();
            }
            else { 
                allPositions[x.votes].pop();
                for (uint i = x.votes ; i > 0 ; i--) {
                    if (allPositions[i].length == 0) {
                        allPositions.pop();
                    }
                }
            }

            uint dayz= (block.timestamp-(timer -time))/time;
            timer = timer +  (dayz* time);
            nftInfoo[winner].winnerStatus = true;
            nftInfoo[winner].winTime = timer;
            winnersIdexes.push(winner);
            emit Winner(winner, nftInfoo[winner]);
            
        }
          
    }
    
    // function winnerIndex() public view returns (uint){
    //     uint highest;
    //     uint highvotes;
    //     if(block.timestamp>=timer){
    //     for(uint i; i< nftIndex; i++){
    //         if(nftInfoo[i].winnerStatus==false && nftInfoo[i].isApprovedByCommittee==true){
    //            if(nftInfoo[i].votes>0 ){
    //               if(nftInfoo[i].votes > highvotes){
    //                    highvotes=nftInfoo[i].votes;
    //                    highest=i;
    //               }
    //            }

    //         }
    //     }
         
    // }
    //  return highest;
    // }


    // function updateWinner() internal {
    //     uint index = winnerIndex();

    //     // if nft is already winner or winTime > 0
    //     if (nftInfoo[index].winnerStatus==true || nftInfoo[index].winTime > 0){
    //          if(block.timestamp>timer){
    //         uint dayz= (block.timestamp-(timer -time))/time;
    //         timer = timer +  (dayz* time);
    //     }
    //         return;
    //     }
    //     nftInfoo[index].winnerStatus = true;
    //     nftInfoo[index].winTime = timer;
    //     winnersIdexes.push(index);
    //     emit Winner(index, nftInfoo[index]);
    //     if(block.timestamp>timer){
    //         uint dayz= (block.timestamp-(timer -time))/time;
    //         timer = timer +  (dayz* time);
    //     }
    // }

    function setTimer(uint _time) public{
        time=_time;
    }

    function updateDaoCommitteeAddress ( address _address ) public {
        daoCommittee= _address;
    }
}