// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;	

contract Cofre {
   address public owner;
uint public minimoDeposito = 5 ether;

mapping(address => uint) saldos;


    constructor() {              // 2. constructor
        owner = msg.sender;
    }

function depositar() public payable saldoMinimo(minimoDeposito) {
   require(msg.value > 0, "Valor deve ser maior que zero");
    saldos[msg.sender] += msg.value;



}
function sacar(uint _value, uint) public  {
   require(saldos[msg.sender] >= _value, "Saldo insuficiente");
    saldos[msg.sender] -= _value; 
     (bool sucesso, ) = payable(msg.sender).call{value: _value}("");
    require(sucesso, "Falha ao enviar ETH");

 
}
modifier onlyOwner {
    require(msg.sender == owner, "Nao e o owner"); // verifica primeiro
    _; // aí executa a função
}
function sacarTudo() public onlyOwner {
    uint total = saldos[msg.sender];
    require(total > 0, "Sem saldo");
    saldos[msg.sender] = 0;
    (bool sucesso, ) = payable(msg.sender).call{value: total}("");
    require(sucesso, "Falha ao enviar ETH");
}

modifier saldoMinimo(uint _minimo) {
    require(msg.value >= _minimo, "Valor minimo nao atingido");
    _; // executa a função depois
}

}

