pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import 'Structs.sol';

abstract contract HasConstructorWithPubKey {
   constructor(uint256 pubkey) public {}
}

interface IShoppingList {
   function addPurchase(string text, uint32 number) external;
   function deletePurchase(uint32 id) external;
   function makePurchase(uint32 id, uint price) external;
   function getPurchase() external returns (Buy[] purchases);
   function getSummary() external returns (Summary);
}
 
interface ITransactionShoppList {
   function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload) external;
}
