// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Sorteio{
    struct Usuario {
        uint idade;
        string nome;
         uint id;    
        bool sorteado;


    }
Usuario[] public usuarios;
uint public premio = 100 ether;
mapping(uint => Usuario) public premiados;

event UsuarioCadastrado(uint idade, string indexed  nome, uint id);
event UsuarioSorteado(uint idade, string indexed  nome, uint id);

function cadastrarUsuario(uint _idade, string memory _nome) public { // Removi o _id daqui
    require(bytes(_nome).length > 0, "Nome invalido");
    require(_idade >= 18, "Idade minima de 18 anos");
    
    uint novoId = usuarios.length + 1; // Geramos o ID aqui
    usuarios.push(Usuario(_idade, _nome, novoId, false));
    
    emit UsuarioCadastrado(_idade, _nome, novoId);
}

    function verificarUsuario() public view returns (Usuario[] memory) {
        return usuarios;
}
// 1. Removi o 'view' para o 'emit' funcionar
// 2. Mudei o retorno para apenas 'Usuario memory'
function sortear() public returns (Usuario memory) {
    require(usuarios.length > 0, "Nenhum usuario cadastrado");

    uint indexSorteado = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, usuarios.length))) % usuarios.length;
    
    // 1. MUDANÇA: Use STORAGE para mexer no banco de dados real
    Usuario storage sorteado = usuarios[indexSorteado];

    require(sorteado.sorteado == false, "Este usuario ja ganhou, sorteie novamente");

    // 2. ADIÇÃO: Você PRECISA marcar como true para o require funcionar na próxima vez!
    sorteado.sorteado = true;

    emit UsuarioSorteado(sorteado.idade, sorteado.nome, sorteado.id);
    premiados[sorteado.id] = sorteado;

    return sorteado;
}

}
