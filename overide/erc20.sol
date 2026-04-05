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

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

        constructor() {
            totalSupply = MAX_SUPPLY;
            balanceOf[address(this)] = MAX_SUPPLY;
        }

    function transferir(uint _value, address _para) virtual public returns(string memory ){
        require(balanceOf[msg.sender] >= _value, "Saldo insuficiente"); // Verifica se o saldo é suficiente);
        balanceOf[msg.sender] -= _value;
        balanceOf[_para] += _value;
     
        return "transferido com sucesso";
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint _value) public returns(bool success){
        require(_value <= balanceOf[_from], "Saldo insuficiente"); // Verifica se o saldo é suficiente
        require(_value <= allowance[_from][msg.sender], "Saldo insuficiente"); // Verifica se o saldo é suficiente
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
}
