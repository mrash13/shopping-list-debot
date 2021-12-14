pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "base/Debot.sol";
import "base/Terminal.sol";
import "base/Menu.sol";
import "base/AddressInput.sol";
import "base/Upgradable.sol";
import "base/Sdk.sol";
import "Structs.sol";
import "Interfaces.sol";


abstract contract AShoppList {
   constructor(uint256 pubkey) public {}
}

abstract contract AShoppingListDebot is Debot, Upgradable {
    bytes m_icon;

    TvmCell m_ShopListCode; 
    TvmCell m_ShopListData;
    TvmCell m_ShopListStatInit;
    address m_address;
    Summary m_Summary;
    uint32 m_PurchaseId;
    string m_PurchaseValue;
    uint256 m_masterPubKey;
    address m_msigAddress;

    uint32 INITIAL_BALANCE =  200000000; 


    function setShopListCode(TvmCell code, TvmCell data) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        m_ShopListCode = code;
        m_ShopListData = data;
        m_ShopListStatInit = tvm.buildStateInit(m_ShopListCode, m_ShopListData);
    }


    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode));
        _menu();
    }

    function onSuccess() public view {
        _getSummary(tvm.functionId(setSummary));
    }

    function start() public override {
        Terminal.input(tvm.functionId(savePublicKey),"Please enter your public key",false);
    }

    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "ShoppingList DeBot";
        version = "1.0.0";
        publisher = "TON Labs";
        key = "ShoppingList DeBot";
        author = "Yaroslav Ash";
        support = address(0);
        hello = "Hi, I'm a ShoppingList DeBot!";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID ];
    }

    function savePublicKey(string value) public {
        (uint res, bool status) = stoi("0x"+value);
        if (status) {
            m_masterPubKey = res;

            Terminal.print(0, "Checking your Shopping list ...");
            // TvmCell deployState = tvm.insertPubkey(m_ShopListCode, m_masterPubKey);
            TvmCell deployState = tvm.insertPubkey(m_ShopListStatInit, m_masterPubKey);
            m_address = address.makeAddrStd(0, tvm.hash(deployState));
            Terminal.print(0, format( "Your Shopping list contract address is {}", m_address));
            Sdk.getAccountType(tvm.functionId(checkStatus), m_address);

        } else {
            Terminal.input(tvm.functionId(savePublicKey),"Wrong public key. Try again!\nPlease enter your public key",false);
        }
    }


    function checkStatus(int8 acc_type) public {
        if (acc_type == 1) { // acc is active and  contract is already deployed
            _getSummary(tvm.functionId(setSummary));

        } else if (acc_type == -1)  { // acc is inactive
            Terminal.print(0, "You don't have a Shopping list yet, so a new contract with an initial balance of 0.2 tokens will be deployed");
            AddressInput.get(tvm.functionId(creditAccount),"Select a wallet for payment. We will ask you to sign two transactions");

        } else  if (acc_type == 0) { // acc is uninitialized
            Terminal.print(0, format(
                "Deploying new contract. If an error occurs, check if your TODO contract has enough tokens on its balance"
            ));
            deploy();

        } else if (acc_type == 2) {  // acc is frozen
            Terminal.print(0, format("Can not continue: account {} is frozen", m_address));
        }
    }


    function creditAccount(address value) public {
        m_msigAddress = value;
        optional(uint256) pubkey = 0;
        TvmCell empty;
        ITransactionShoppList(m_msigAddress).sendTransaction{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(waitBeforeDeploy),
            onErrorId: tvm.functionId(onErrorRepeatCredit)  // Just repeat if something went wrong
        }(m_address, INITIAL_BALANCE, false, 3, empty);
    }

    function onErrorRepeatCredit(uint32 sdkError, uint32 exitCode) public {
        // TODO: check errors if needed.
        sdkError;
        exitCode;
        creditAccount(m_msigAddress);
    }


    function waitBeforeDeploy() public  {
        Sdk.getAccountType(tvm.functionId(checkIfStatusIs0), m_address);
    }

    function checkIfStatusIs0(int8 acc_type) public {
        if (acc_type ==  0) {
            deploy();
        } else {
            waitBeforeDeploy();
        }
    }


    function deploy() private view {
            TvmCell image = tvm.insertPubkey(m_ShopListCode, m_masterPubKey);
            optional(uint256) none;
            TvmCell deployMsg = tvm.buildExtMsg({
                abiVer: 2,
                dest: m_address,
                callbackId: tvm.functionId(onSuccess),
                onErrorId:  tvm.functionId(onErrorRepeatDeploy),    // Just repeat if something went wrong
                time: 0,
                expire: 0,
                sign: true,
                pubkey: none,
                stateInit: image,
                call: {AShoppList, m_masterPubKey}
            });
            tvm.sendrawmsg(deployMsg, 1);
    }


    function onErrorRepeatDeploy(uint32 sdkError, uint32 exitCode) public view {
        sdkError;
        exitCode;
        deploy();
    }

    function setSummary(Summary summary) public {
        m_Summary = summary;
        _menu();
    }

    function _menu() virtual internal {
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You have {}/{}/{} (todo/done/total) purchases",
                    m_Summary.notPaidCount,
                    m_Summary.paidCount,
                    m_Summary.paidCount + m_Summary.notPaidCount
            ),
            sep,
            [
                MenuItem("Add new purchase","",tvm.functionId(addPurchase)),
                MenuItem("Show purchases list","",tvm.functionId(showPurchase)),
                MenuItem("Make urchase","",tvm.functionId(makePurchase)),
                MenuItem("Delete purchase","",tvm.functionId(deletePurchase))
            ]
        );
    }

    function addPurchase(uint32 index) public{
        index = index;
        Terminal.input(tvm.functionId(addPurchase_), "One line please:", false);
    }

    function addPurchase_(string value) public {
        m_PurchaseValue = value;
        Terminal.input(tvm.functionId(addPurchase__),"Quantity:", false);
    }

    function addPurchase__(string value) public view {
        optional(uint256) pubkey = 0;
        (uint256 num,) = stoi(value);
        IShoppingList(m_address).addPurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(m_PurchaseValue, uint32(num));
    }

    function showPurchase(uint32 index) public view {
        index = index;
        optional(uint256) none;
        IShoppingList(m_address).getPurchase{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showPurchase_),
            onErrorId: 0
        }();
    }

    function showPurchase_(Buy[] purchases) public {
        uint32 i;
        
        if (purchases.length > 0 ) {
            Terminal.print(0, "Your shopping list:");
            for (i = 0; i < purchases.length; i++) {
                Buy purchases = purchases [i];
                string completed;
                if (purchases.isBought) {
                    completed = '✓';
                } else {
                    completed = ' ';
                }
                Terminal.print(0, format("{} {}  \"{}\" quantity: {} cost: {}  at {}", purchases.id, completed, purchases.name, purchases.number, purchases.price, purchases.createdAt));
            }
        } else {
            Terminal.print(0, "Your shopping list is empty");
        }
        _menu();
    }

    function makePurchase(uint32 index) public {
        index = index;
        if (m_Summary.paidCount + m_Summary.notPaidCount > 0) {
            Terminal.input(tvm.functionId(makePurchase_), "Enter purchase number:", false);
        } else {
            Terminal.print(0, "Sorry, you have no purchases to make");
            _menu();
        }
    }

    function makePurchase_(string value) public {
        (uint256 num,) = stoi(value);
        m_PurchaseId = uint32(num);
        Terminal.input(tvm.functionId(makePurchase__),"Cost:", false);
    }

    function makePurchase__(string value) public view {
        optional(uint256) pubkey = 0;
        (uint256 num,) = stoi(value);
        IShoppingList(m_address).makePurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(m_PurchaseId, uint32(num));
    }


    function deletePurchase(uint32 index) public{
        index = index;
        if (m_Summary.paidCount + m_Summary.notPaidCount > 0) {
            Terminal.input(tvm.functionId(deletePurchase_), "Enter purchase number:", false);
        } else {
            Terminal.print(0, "Sorry, you have no purchases to delete");
            _menu();
        }
    }

    function deletePurchase_(string value) public view {
        (uint256 num,) = stoi(value);
        optional(uint256) pubkey = 0;
        IShoppingList(m_address).deletePurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(uint32(num));
    }

    function _getSummary(uint32 answerId) private view {
        optional(uint256) none;
        IShoppingList(m_address).getSummary{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: answerId,
            onErrorId: 0
        }();
    }

    function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }
}