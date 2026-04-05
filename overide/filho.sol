// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "./meuERC20.sol";

contract TaxToken is meuERC20 {

 function transferir(uint _value, address _para) override public returns(string memory) {
        require(_value > 0, "Valor deve ser maior que zero");
        uint taxa = _value / 10; // 10% de taxa
        _value -= taxa;
        return super.transferir(_value, _para);
    }

}
