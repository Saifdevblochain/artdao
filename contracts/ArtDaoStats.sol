// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin\contracts-upgradeable\token\ERC721\IERC721Upgradeable.sol";
import "./IDaoPublic.sol";

contract ArtDaoStats is Initializable {
    struct Data {
        // address[] voters;
        uint votersCount;
        mapping(address => bool) claimed;
    }

    mapping( uint => Data)  nftStore;
    mapping(uint => mapping(address => bool)) public voteCheck;

    function initialize() public initializer {}

    function claim(uint index) public {
        require( voteCheck[index][msg.sender] == true, "You have not voted");
        require( nftStore[index].claimed[msg.sender] == false, "Already Claimed" );

        uint  amount =  nftStore[index].votersCount;
       
        // processToRoot( msg.sender, 180 ether/amount );
        voteCheck[index][msg.sender] = false;
        nftStore[index].claimed[msg.sender] = true;

        // emit claimed(msg.sender , amount);
    }

    function claimBatch(uint[] memory indexes) public {
        uint totalAmount;
        for(uint i; i < indexes.length ; ++i){
            require( voteCheck[indexes[i]][msg.sender] == true, "You have not voted");
            require( nftStore[indexes[i]].claimed[msg.sender] == false, "Already Claimed" );
            uint  amount =  nftStore[indexes[i]].votersCount;
            totalAmount+=amount;
            voteCheck[indexes[i]][msg.sender] = false;
            nftStore[indexes[i]].claimed[msg.sender] = true;
            // emit claimed(msg.sender , amount);
        }
        // processToRoot( msg.sender, 180 ether/amount );
        
    }
}
