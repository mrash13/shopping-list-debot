pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../AShoppingListDebot.sol";

contract ShoppingDebot is AShoppingListDebot {
    function _menu() internal override {
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You have {}/{}/{} (buy/bought/summary) purchases",
                    m_Summary.notPaidCount,
                    m_Summary.paidCount,
                    m_Summary.paidCount + m_Summary.notPaidCount
            ),
            sep,
            [
                MenuItem("Show purchase list","",tvm.functionId(showPurchase)),
                MenuItem("Delete purchase","",tvm.functionId(deletePurchase)),
                MenuItem("Buy","",tvm.functionId(makePurchase))
            ]
        );
    }

}