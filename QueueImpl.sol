// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Queue {
    mapping(uint256 => address) queue;
    uint256 first = 1;
    uint256 last = 0;

    function enqueue(address data) external {
        last += 1;
        queue[last] = data;
    }

    function dequeue() external returns(address data) {
        require(last >= first);  // non-empty queue
        data = queue[first];
        delete queue[first];
        first += 1;
        return data;
    }
    function getFirst() external view returns( address data) {
        require(last >= first);
        return queue[first];
    }
    
}