// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract meuERC20{

    uint public constant MAX_SUPPLY = 1e18;
    uint public value;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "meuERC20";
    string public symbol = "MEU";
    uint8 public decimals = 18;

    function transferir(uint _value, address _para) virtual public returns(string memory ){
        require(balanceOf[msg.sender] >= _value, "Saldo insuficiente"); // Verifica se o saldo é suficiente);
        balanceOf[msg.sender] -= _value;
        balanceOf[_para] += _value;
     
        return "transferido com sucesso";
    }
    







}
