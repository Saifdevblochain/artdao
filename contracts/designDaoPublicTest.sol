// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./LinkedList.sol";


contract DaoPublicTest is Initializable, LinkedList {
    using SafeMathUpgradeable for uint;

    struct NFTInfo {   
        string uri;
        address owner;
        uint index;
        uint votes;
        bool isApprovedByCommittee;
        bool winnerStatus;
        uint winTime;
    }

    address public daoCommittee;
    uint public timer;
    uint public nftIndex;
    uint public time;
    uint public committeeMembersCounter;

    uint[] public winnersIdexes;

    // Position[][] public allPositions;
    mapping (uint => NFTInfo ) public nftInfoo;

    mapping(uint => mapping(address => bool)) public voteCheck;

    modifier onlydaoCommitte {
        require(msg.sender == address(daoCommittee), "Only DaoCommitte can call");
        _;
    }

    event PublicVote(address voter, uint index , NFTInfo _NFT);
    event NftApproved(uint index, NFTInfo _NFT,uint startTime );
    event Winner(uint index, NFTInfo _NFT);
 
    function initialize (address _daoCommitteeContract) initializer public {  
       daoCommittee= _daoCommitteeContract;
       __LinkedList_init();
    }
 
    function setValues (uint _time, uint _timer ) public {
        
        time= _time;
        timer= block.timestamp+_timer;
    }

    function addInfo (string calldata uri, address _owner, bool _isApprovedByCommittee )  external onlydaoCommitte {
       _addInfo(uri,   _owner,   _isApprovedByCommittee);
    }

      

    function _addInfo(string calldata uri, address _owner, bool _isApprovedByCommittee) internal{
         nftInfoo[nftIndex] = NFTInfo(uri, _owner, nftIndex, 0, _isApprovedByCommittee, false, 0);
        emit NftApproved(nftIndex,nftInfoo[nftIndex],block.timestamp );
        nftIndex++;
    }

    

    function voteNfts(uint index) public {
        require(nftInfoo[index].winnerStatus==false,"Already winner");
        require( voteCheck[index][msg.sender] == false, "Already Voted" );
        require( index < nftIndex , " Choose Correct NFT to vote ");
        // nftInfoo[index].votes++;

        NFTInfo storage x = nftInfoo[index];

        x.votes++;
        insertUp(index);

        voteCheck[index][msg.sender] = true;

        emit PublicVote( msg.sender, index, nftInfoo[index] );

        if(block.timestamp >= timer){
            announceWinner();
        }else{
            return;
        }
    }


    function announceWinner() public {
       
           
        uint index= getHighest();
        if(nftInfoo[index].winnerStatus == true){
            uint dayz= (block.timestamp.sub(timer.sub(time))).div(time);
            timer = timer.add(dayz.mul(time));
            return ;
        }
        else{
           uint dayz= (block.timestamp.sub(timer.sub(time))).div(time);
            timer = timer.add(dayz.mul(time));
            nftInfoo[index].winnerStatus = true;
            nftInfoo[index].winTime = timer;
            winnersIdexes.push(index);
            emit Winner(index, nftInfoo[index]);
            remove(index);
        }

        
    }

    // function announceWinner() public {
    //     if(block.timestamp>=timer){
    //         uint winner = allPositions[allPositions.length - 1][0].index;

    //         Position storage x = nftInfoo[winner];

    //         uint lastPosition2D = allPositions[x.votes].length - 1;
 
    //         if (x.position2D != lastPosition2D) {
    //             uint lastIndex = allPositions[x.votes][lastPosition2D].index;
    //             Position storage y = nftInfoo[lastIndex];

    //             allPositions[x.votes][x.position2D] =
    //                 allPositions[x.votes][lastPosition2D];

    //             allPositions[x.votes][x.position2D].position2D = x.position2D;

    //             y.position2D = x.position2D;

    //             allPositions[x.votes].pop();
    //         }
    //         else { 
    //             allPositions[x.votes].pop();
    //             for (uint i = x.votes ; i > 0 ; i--) {
    //                 if (allPositions[i].length == 0) {
    //                     allPositions.pop();
    //                 }
    //             }
    //         }

    //         uint dayz= (block.timestamp-(timer -time))/time;
    //         timer = timer +  (dayz* time);
    //         nftInfoo[winner].winnerStatus = true;
    //         nftInfoo[winner].winTime = timer;
    //         winnersIdexes.push(winner);
    //         emit Winner(winner, nftInfoo[winner]);
            
    //     }
          
    // }
    
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