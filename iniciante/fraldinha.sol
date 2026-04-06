pragma solidity ^0.8.0;

contract Exemplo {
    string public nome;

    // Função para alterar o nome
    function pegarNome(string memory _nome) public {
        nome = _nome;
    }

    // Função para ver o nome
    function verNome() public view returns (string memory) {
        return nome;
    }
}
