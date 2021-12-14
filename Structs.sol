pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

struct Buy {
    uint32 id;
    string name;
    uint32 number;
    uint64 createdAt;
    bool isBought;
    uint price;
}

struct Summary {
    uint32 paidCount;
    uint32 notPaidCount;    
    uint amoundPaid;
}