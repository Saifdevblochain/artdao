//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


interface IDaoPublic{

    struct NFTInfo {
        string uri;
        address owner;
        uint index;
        uint votes;
        bool isApprovedByCommittee;
        bool winnerStatus;
        uint winTime;
        uint votersCount;
        uint favourVotes;
        uint disApprovedVotes;
    }

    function addInfo (string calldata uri,address _owner, bool _isApprovedByCommittee) external ;
    function announceWinner() external;
}