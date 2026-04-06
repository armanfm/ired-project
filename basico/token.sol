// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;	



import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract Cofre is  ERC20 {
  
uint public minimoDeposito = 5 ether;

mapping(address => uint) saldos;


    constructor() ERC20("CofreToken", "CFR"){
                _mint(msg.sender, 1* 10**18);
    }

function depositar() public  payable  {
   require(msg.value > 0, "Valor deve ser maior que zero");
    saldos[msg.sender] += msg.value;



}
function sacar(uint _value) public {
   require(saldos[msg.sender] >= _value, "Saldo insuficiente");
    saldos[msg.sender] -= _value; 
     (bool sucesso, ) = payable(msg.sender).call{value: _value}("");
    require(sucesso, "Falha ao enviar ETH");

 
}


function sacarTudo() public {
    uint total = saldos[msg.sender];
    require(total > 0, "Sem saldo");
    saldos[msg.sender] = 0;
    (bool sucesso, ) = payable(msg.sender).call{value: total}("");
    require(sucesso, "Falha ao enviar ETH");
}



}
