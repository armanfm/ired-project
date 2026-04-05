// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract StorageMemory2{

struct Usuario{
    string nome;
    uint idade;
}

Usuario public user;

 function salvar(string memory _nome, uint _idade) pure public returns(Usuario memory) {
    Usuario memory temp;
    
    temp.nome=_nome;
    temp.idade=_idade;


 _nome = "alterardo";

 return temp;
   

}

 function salvar2(string calldata _nome, uint _idade) pure public returns(Usuario memory) {
    Usuario memory temp;
    
    temp.nome=_nome;
    temp.idade=_idade;


//erro de compilação, calltada não pode alterar.
 //    _nome = "alterardo";
 return temp;
}




}
