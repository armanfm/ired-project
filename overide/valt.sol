// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CofreVault is ERC20, Ownable, AccessControl {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    mapping(address => uint) public saldos;
    mapping(address => uint) public depositTime;
   
event Deposito(address indexed carteira, uint valor);
event Saque(address indexed carteira, uint valor);

    constructor() ERC20("CofreToken", "CFR") Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _mint(msg.sender, 1* 10**18);
    }

    function depositar() public payable {

        require(msg.value > 0, "Valor deve ser maior que zero");
        saldos[msg.sender] += msg.value;
        depositTime[msg.sender] = block.timestamp;
        emit Deposito(msg.sender, msg.value);
    }

    function sacar(uint _value) public {
        require(block.timestamp >= depositTime[msg.sender] + 1 days, "Aguarde 24h");
        require(saldos[msg.sender] >= _value, "Saldo insuficiente");
        saldos[msg.sender] -= _value;
        (bool sucesso, ) = payable(msg.sender).call{value: _value}("");
        require(sucesso, "Falha ao enviar");
        emit Saque(msg.sender, _value);
    }

    function mintTokens(address _para, uint _valor) public onlyRole(ADMIN_ROLE) {
        _mint(_para, _valor);
    }
}
