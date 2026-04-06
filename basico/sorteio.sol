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
// 1. Removi o 'view' para o 'emit' funcionar
// 2. Mudei o retorno para apenas 'Usuario memory'
// 1. Criamos o Array que permite LISTAR
Usuario[] public listaGanhadores;

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


function sortear() public returns (Usuario memory) {
    require(usuarios.length > 0, "Nenhum usuario cadastrado");

    uint indexSorteado = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, usuarios.length))) % usuarios.length;
    
    // Usamos STORAGE para alterar o banco de dados real
    Usuario storage sorteado = usuarios[indexSorteado];
    require(sorteado.sorteado == false, "Este usuario ja ganhou");

    sorteado.sorteado = true;

    // 2. A MÁGICA: Além de salvar no mapping, jogamos para o Array de listagem
    listaGanhadores.push(sorteado);

    emit UsuarioSorteado(sorteado.idade, sorteado.nome, sorteado.id);
    premiados[sorteado.id] = sorteado;

    return sorteado;
}

// 3. A FUNÇÃO QUE VOCÊ QUERIA: Ela devolve a lista completa
function verTodosOsGanhadores() public view returns (Usuario[] memory) {
    return listaGanhadores;
}




}
