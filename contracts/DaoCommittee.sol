// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin\contracts-upgradeable\token\ERC721\IERC721Upgradeable.sol";
import "./IDaoPublic.sol";


contract DaoCommittee is Initializable {
    uint public nftIndex;
    uint public committeeMembersCounter;
    IDaoPublic public DaoPublic;
    IERC721Upgradeable public adminNFT;
  
    struct NFT {
        string uri;
        address owner;
        uint approvedVotes;
        uint rejectedVotes;
        bool isApprovedByCommittee;
        bool rejected;
    }
   
    mapping(address => bool) public Committee;

    mapping(uint => NFT) public nftStore;

    mapping(uint => mapping(address => uint8)) public committeeVoteCheck;

    event NftAdded( uint index,NFT NFT, uint uploadTime );
    event CommitteeVote(address committeeMember,uint index, bool decision, NFT _NFT);
    
    modifier onlyComittee() {
        require(adminNFT.balanceOf(msg.sender)>=1,"only Committee");
        // require(Committee[msg.sender] == true,"Not Committee Member");
        _;
    }
    
    function initialize () initializer public {  
        //  Committee[msg.sender] = true;
        // committeeMembersCounter++;
    }
 
    
    function addNfts( string calldata uri_)  public {
            nftStore[nftIndex] =NFT (uri_,msg.sender,0,0,false,false);
            emit NftAdded(nftIndex, nftStore[nftIndex], block.timestamp);
            nftIndex++;
            if (block.timestamp>=DaoPublic.timer()){
                DaoPublic.announceWinner();
       }
    }


    function voteByCommittee(uint index, bool decision) public onlyComittee {
        // if (block.timestamp>=DaoPublic.timer()){
        //    DaoPublic.updateWinner();
        // }
        require(committeeVoteCheck[index][msg.sender] == 0, " Already Voted ");
        require(nftStore[index].owner != address(0), "NFT doesnot exist");
        require (nftStore[index].isApprovedByCommittee==false, "NFT already approved");
        require (nftStore[index].rejected == false, "NFT already approved");

        uint votesTarget =(adminNFT.totalSupply() /2)+1;
               
        if (decision == true) {
            nftStore[index].approvedVotes++;
            committeeVoteCheck[index][msg.sender] = 1;
            if (nftStore[index].approvedVotes >= votesTarget) {
                nftStore[index].isApprovedByCommittee = true;
                DaoPublic.addInfo ( nftStore[index].uri, nftStore[index].owner, true );
            }
            emit CommitteeVote(msg.sender,index , decision , nftStore[index]);

        } else {
            nftStore[index].rejectedVotes++;
            committeeVoteCheck[index][msg.sender] = 2;

            if (nftStore[index].rejectedVotes >= votesTarget) {
                nftStore[index].isApprovedByCommittee = false;
                nftStore[index].rejected =true;
            }
            emit CommitteeVote(msg.sender,index , decision,nftStore[index] );
        }
    }

    function updateDaoPublicAddress (IDaoPublic _add) public onlyComittee {
        DaoPublic= _add;
    }
  

//    function AddComitteMemberBatch(address[] calldata _addresses)
//         public
//         onlyComittee {
//         for (uint8 i; i < _addresses.length; i++) {
//             require(
//                 Committee[_addresses[i]] == false,
//                 "Already Committee Member"
//             );
//             Committee[_addresses[i]] = true;
//             committeeMembersCounter++;
//         }
//     }

    function checkCommitteeMember() external  {
        if(adminNFT.balanceOf(msg.sender)>=1){
            return true;
        }else{
            return false;
        }
    }

    // function removeCommitteeMember(address _memberToRemove) public onlyComittee {
    //     require(Committee[_memberToRemove] == true, "Not Committee member");
    //     Committee[_memberToRemove] = false;
    //     committeeMembersCounter--;
    // }

    // function withdrawFromCommittee() public onlyComittee {
    //     Committee[msg.sender] = false;
    //     committeeMembersCounter--;
    // }

    // function removeCommitteeMemberBatch(address[] calldata _addresses)
    //     public
    //     onlyComittee {
    //     for (uint8 i; i < _addresses.length; i++) {
    //         require(
    //             Committee[_addresses[i]] == true,
    //             "Not in Committee"
    //         );
    //         Committee[_addresses[i]] = false;
    //         committeeMembersCounter--;
    //     }
    // }

    
}