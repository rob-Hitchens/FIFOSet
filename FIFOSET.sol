pragma solidity ^0.6.6;

// SPDX-License-Identifier: MIT

import "./openzeppelin/SafeMath.sol";
import "./Bytes32Set.sol";

library FIFOSet {
    
    using SafeMath for uint;
    using Bytes32Set for Bytes32Set.Set;
    
    bytes32 constant NULL = bytes32(0);
    
    struct FIFO {
        bytes32 firstKey;
        bytes32 lastKey;
        mapping(bytes32 => KeyStruct) keyStructs;
        Bytes32Set.Set keySet;
    }

    struct KeyStruct {
            bytes32 nextKey;
            bytes32 previousKey;
    }

    function count(FIFO storage self) internal view returns(uint) {
        return self.keySet.count();
    }
    
    function first(FIFO storage self) internal view returns(bytes32) {
        return self.firstKey;
    }
    
    function last(FIFO storage self) internal view returns(bytes32) {
        return self.lastKey;
    }
    
    function exists(FIFO storage self, bytes32 key) internal view returns(bool) {
        return self.keySet.exists(key);
    }
    
    function isFirst(FIFO storage self, bytes32 key) internal view returns(bool) {
        return key==self.firstKey;
    }
    
    function isLast(FIFO storage self, bytes32 key) internal view returns(bool) {
        return key==self.lastKey;
    }    
    
    function previous(FIFO storage self, bytes32 key) internal view returns(bytes32) {
        require(exists(self, key), "FIFOSet: key not found") ;
        return self.keyStructs[key].previousKey;
    }
    
    function next(FIFO storage self, bytes32 key) internal view returns(bytes32) {
        require(exists(self, key), "FIFOSet: key not found");
        return self.keyStructs[key].nextKey;
    }
    
    function append(FIFO storage self, bytes32 key) internal {
        require(key != NULL, "FIFOSet: key cannot be zero");
        require(!exists(self, key), "FIFOSet: duplicate key"); 
        bytes32 lastKey = self.lastKey;
        KeyStruct storage k = self.keyStructs[key];
        KeyStruct storage l = self.keyStructs[lastKey];
        if(lastKey==NULL) {                     // first row
            self.firstKey = key;
        } else {
            l.nextKey = key;
        }
        k.previousKey = lastKey;
        self.keySet.insert(key);
        self.lastKey = key;
    }

    function remove(FIFO storage self, bytes32 key) internal {
        require(exists(self, key), "FIFOSet: key not found");
        KeyStruct storage k = self.keyStructs[key];
        bytes32 keyBefore = k.previousKey;
        bytes32 keyAfter = k.nextKey;
        bytes32 firstKey = first(self);
        bytes32 lastKey = last(self);
        KeyStruct storage p = self.keyStructs[keyBefore];
        KeyStruct storage n = self.keyStructs[keyAfter];
        
        if(count(self) == 1) {
            self.firstKey = NULL;
            self.lastKey = NULL;
        } else {
            if(key == firstKey) {
                n.previousKey = NULL;
                self.firstKey = keyAfter;  
            } else 
            if(key == lastKey) {
                p.nextKey = NULL;
                self.lastKey = keyBefore;
            } else {
                p.nextKey = keyAfter;
                n.previousKey = keyBefore;
            }
        }
        self.keySet.remove(key);
        delete self.keyStructs[key];
    }
}

/**
 * @dev This testing harness is not part of the production system
 */

contract FIFO {
    
    using FIFOSet for FIFOSet.FIFO;
    
    FIFOSet.FIFO list;
    
    function keyGen() public view returns(bytes32 unique) {
        return keccak256(abi.encodePacked(address(this), list.count(),  block.number, msg.sender));
    }
    function count() public view returns(uint) {
        return list.count();
    }
    function first() public view returns(bytes32 key) {
        return list.first();
    }
    function last() public view returns(bytes32 key) {
        return list.last();
    }
    function append(bytes32 key) public {
        list.append(key);
    }
    function remove(bytes32 key) public {
        list.remove(key);
    }
    function prev(bytes32 key) public view returns(bytes32 keyBefore) {
        return list.previous(key);
    }
    function next(bytes32 key) public view returns(bytes32 keyAfter) {
        return list.next(key);
    }
    function isFirst(bytes32 key) public view returns(bool isIndeed) {
        return list.isFirst(key);
    }
    function isLast(bytes32 key) public view returns(bool isIndeed) {
        return list.isLast(key);
    }
}
