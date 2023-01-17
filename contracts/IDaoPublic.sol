//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


interface IDaoPublic{

     struct NFT {   
        string uri;
        address owner;
        uint index;
        uint votes;
        uint position2D;
        bool isApprovedByCommittee;
        bool winnerStatus;
        uint winTime;
    }

    function addInfo (string calldata uri,address _owner, bool _isApprovedByCommittee) external ;
    function timer() external view returns(uint);
    function announceWinner() external;
}