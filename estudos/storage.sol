// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract StorageMemory{

struct Usuario{
    string nome;
    uint idade;
}

Usuario public user;

 function storagesalvarStorage(string memory  _nome, uint _idade) public{

    user.nome=_nome;
    user.idade=_idade;

}

//ler storage
function lerStorage() public view returns(Usuario memory){
    return user;

}

// função interna que recebe referência do que já existe
function modificar(Usuario storage _user) internal {

    _user.idade= 40;
    _user.nome="jose";
}

// 4. Chama o modificar
function executar() public {
    modificar(user);
}

}
