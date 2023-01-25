// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @dev The `votes` are considered as the 1D index for each `tokenId`
/// @dev The `position` is the 2D index for each `tokenId`
abstract contract LinkedList {

    struct Position {
        int votes;
        uint position;
    }

    struct Node {
        int next;
        int prev;

        uint[] tokenIds;
    }

    struct AllPosition {
        mapping (int => Node) nodes;

        int head;
        int tail;

        uint totalVoteCount;
    }

    /// @dev The LinkedList
    AllPosition public allPositions;
    /// @dev Reveals the number of votes and position in their corresponding node's `positions` array relevant to each `tokenId`
    mapping (uint => Position) public getPosition;

    function __LinkedList_init() internal {
        __LinkedList_init_unchained();
    }

    function __LinkedList_init_unchained() internal {
        // HEAD's next will always be ZERO and prev will always be HIGHEST VOTES
        allPositions.head = -1;
        // TAIL's next will always be LOWEST VOTES and prev will always be ZERO
        allPositions.tail = -2;

        allPositions.nodes[allPositions.head].prev = allPositions.tail;
        allPositions.nodes[allPositions.tail].next = allPositions.head;
    }

    function insertFirst(uint tokenId) internal {
    }

    function insertAfterZero(uint tokenId) internal {
    }

    function insertUp(uint tokenId) internal {
        bool nodeCreated;
        Position storage currentPosition = getPosition[tokenId];
        int lastVotes = currentPosition.votes;
        Node storage lastNode = allPositions.nodes[lastVotes];
        if (currentPosition.votes == 0) {
            insertAfterZero(tokenId);
        }
        else {
            uint[] storage currentTokenIds = allPositions.nodes[currentPosition.votes].tokenIds;

            // getting the last tokenId and its position data
            uint lastTokenId = currentTokenIds[currentTokenIds.length - 1];
            Position storage lastPosition = getPosition[lastTokenId];

            // replacing our given tokenId with last tokenId
            currentTokenIds[currentPosition.position] = currentTokenIds[lastPosition.position];

            // removing the duplicate last tokenId
            currentTokenIds.pop();

            if (currentTokenIds.length == 0) {
                Node storage currentNode = allPositions.nodes[currentPosition.votes];

                // getting the current node's next and prev
                Node storage nextNode = allPositions.nodes[currentNode.next];
                Node storage prevNode = allPositions.nodes[currentNode.prev];

                // changing linkage for removal
                prevNode.next = currentNode.next;
                nextNode.prev = currentNode.prev;

                // setting lastVotes and lastNode
                lastVotes = currentNode.prev;
                lastNode = allPositions.nodes[lastVotes];

                // deleting current node
                delete allPositions.nodes[currentPosition.votes];
            }

            // saving new position of last tokenId
            lastPosition.position = currentPosition.position;

            // changing votes for our given tokenId
            currentPosition.votes++;

            uint[] storage nextTokenIds = allPositions.nodes[currentPosition.votes].tokenIds;

            if (nextTokenIds.length == 0) {
                nodeCreated = true;
            }

            // pushing our given tokenId into the relevant/next node
            nextTokenIds.push(tokenId);

            // changing the position of our given tokenId to it's new position in the relevant/next node
            currentPosition.position = nextTokenIds.length - 1;
        }

        if (nodeCreated) {
            Node storage currentNode = allPositions.nodes[currentPosition.votes];

            // changing linkage for node given it was newly created
            currentNode.next = lastNode.next;
            currentNode.prev = lastVotes;

            // changing current tokenId last node's linkage
            lastNode.next = currentPosition.votes;
        }

        allPositions.totalVoteCount++;
    }

    function deleteFrom(uint tokenId) internal {
        Position storage currentPosition = getPosition[tokenId];

        uint[] storage currentTokenIds = allPositions.nodes[currentPosition.votes].tokenIds;

        // removing current tokenId
        currentTokenIds.pop();

        // adjusting next/prev if node is empty
        if (currentTokenIds.length == 0) {
            Node storage currentNode = allPositions.nodes[currentPosition.votes];

            // getting the current node's next and prev
            Node storage nextNode = allPositions.nodes[currentNode.next];
            Node storage prevNode = allPositions.nodes[currentNode.prev];

            // changing linkage for removal
            prevNode.next = currentNode.next;
            nextNode.prev = currentNode.prev;

            // deleting current node
            delete allPositions.nodes[currentPosition.votes];
        }

        // resetting the position
        currentPosition.position = 0;
    }

    function getHighest() internal view returns (uint256) {
        Node memory headNode = allPositions.nodes[allPositions.head];

        // node before head will contain tokenIds with highest votes
        Node memory highestNode = allPositions.nodes[headNode.prev];

        // arbitrarily choosing the first tokenId in the node as the one with highest votes
        return highestNode.tokenIds[0];
    }
}