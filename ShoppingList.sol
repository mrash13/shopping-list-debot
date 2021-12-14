pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import 'Structs.sol';
import 'Interfaces.sol';

contract ShoppingList {

    constructor(uint256 pubkey) public {
        require(pubkey != 0, 120);
        tvm.accept();
        m_ownerPubkey = pubkey;
    }

    uint32 countOfPurchases;
    uint256 m_ownerPubkey;

    mapping(uint32 => Buy) m_shopping;

    modifier onlyOwner() {
        require(msg.pubkey() == tvm.pubkey(), 101);
        _;
    }

    function addPurchase(string name, uint32 number, uint price) public onlyOwner {
        tvm.accept();
        countOfPurchases++;
        m_shopping[countOfPurchases] = Buy(countOfPurchases, name, number, now, false, 0);
    }

    function deletePurchase(uint32 id) public onlyOwner {
        require(m_shopping.exists(id), 102);
        tvm.accept();
        delete m_shopping[id];
    }

    function makePurchase(uint32 id, uint price) public onlyOwner {
        optional(Buy) shopping = m_shopping.fetch(id);
        require(shopping.hasValue(), 102);
        tvm.accept();
        Buy thisPurchase = shopping.get();
        thisPurchase.isBought = true;
        thisPurchase.price = price;
        m_shopping[id] = thisPurchase;
    }

    function getPurchase() public returns (Buy[] purchases) {
        string name;
        uint32 number;
        uint64 createdAt;
        bool isBought;
        uint price;

        for((uint32 id, Buy purchase) : m_shopping) {
            name = purchase.name;
            number = purchase.number;
            isBought = purchase.isBought;
            createdAt = purchase.createdAt;
            price = purchase.price;
            purchases.push(Buy(id, name, number, createdAt, isBought, price));
       }
    }

    function getSummary() public returns (Summary stat) {

        uint32 paidCount;
        uint32 notPaidCount;    
        uint amoundPaid;

        for((, Buy taskShopp) : m_shopping) {
            if  (taskShopp.isBought) {
                paidCount += taskShopp.number;
                amoundPaid *= taskShopp.price;
            } else {
                notPaidCount++;
            }
        }
        stat = Summary(paidCount, notPaidCount, amoundPaid);
    }

}