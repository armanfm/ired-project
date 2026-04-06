// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Baisco is Ownable {
    struct candidato {
        string nome; 
        uint votos;


    }
    constructor() Ownable(msg.sender) {}
    candidato[] public candidatos;
    mapping(address => bool)  public votou; // mapping para armazenar se o endereço já votou ou não])
   

    function addCandidato(string memory _nome) public onlyOwner{
        candidatos.push(candidato(_nome,0));
    }

    function getCandidato(uint _index) public view returns(string memory) {
        return candidatos[_index].nome;
    }
    function votar(uint _index)  public  {
        require(!votou[msg.sender], "Ja votou"); // certo
        votou[msg.sender] = true;
        candidatos[_index].votos++;

    }




}
