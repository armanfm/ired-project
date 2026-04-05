// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;	

contract Cofre {

mapping(address => uint) saldos;

function depositar() public payable {
    saldos[msg.sender] += msg.value;



}
function sacar(uint _value) public  {
   require(saldos[msg.sender] >= _value, "Saldo insuficiente");
    saldos[msg.sender] -= _value; 
     (bool sucesso, ) = payable(msg.sender).call{value: _value}("");
    require(sucesso, "Falha ao enviar ETH");

 
}

}
