pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "AShoppingListDebot.sol";
import "ShoppingList.sol";

contract FillingShoppingListDebot is AShoppingListDebot {
    function _menu() internal override {
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
                MenuItem("Show purchase list","",tvm.functionId(showPurchase)),
                MenuItem("Delete purchase","",tvm.functionId(deletePurchase))
            ]
        );
    }
}