// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";


contract Leilao is Ownable{
    struct Produto{
        uint id;
        string nome;
        uint preco;
        uint lance;
        address enderecoComprador;
        uint tempoFinal;
        bool finalizado; // ✅ ADICIONADO → você estava usando mas não existia
    }
    constructor() Ownable(msg.sender) {}



    uint public precoMinimo = 1 ether; 
    uint public precoALvo = 10 ether; 
    Produto[] public produtos;

    event LanceProduto(uint indexed id, uint lance);
    event ProdutoAdicionado(uint indexed id, string nome, uint preco);

    // Função para adicionar um produto
    function adicionarProduto(string memory _nome, uint _preco) public onlyOwner {
        uint id = produtos.length;

        produtos.push(Produto(
            id,
            _nome,
            _preco,
            0,
            address(0),
            block.timestamp + 60, // ✅ CORRIGIDO → antes era 60 (tempo errado)
            false // ✅ ADICIONADO → inicializa o leilão como não finalizado
        ));

        emit ProdutoAdicionado(id, _nome, _preco);
    }

    function verProduto(uint _id) public view returns (uint, string memory, uint, uint, address) {
        require(_id < produtos.length, "Produto nao encontrado");
        Produto memory p = produtos[_id];
        return (p.id, p.nome, p.preco, p.lance, p.enderecoComprador);
    }

    function buscarPorNome(string memory _nome) public view returns (uint, string memory, uint, uint, address) {
        for (uint i = 0; i < produtos.length; i++) {
            if (keccak256(abi.encodePacked(produtos[i].nome)) == keccak256(abi.encodePacked(_nome))) {
                Produto memory p = produtos[i];
                return (p.id, p.nome, p.preco, p.lance, p.enderecoComprador);
            }
        }
        revert("Produto nao encontrado");
    }

    function lanceProduto(uint _id, uint _lance) public {
        require(_id < produtos.length, "Produto nao encontrado");

        // ✅ CORRIGIDO → agora funciona porque tempoFinal é válido
        require(block.timestamp < produtos[_id].tempoFinal, "Leilao expirado");

        // ✅ AGORA EXISTE → finalizado foi adicionado na struct
        require(!produtos[_id].finalizado, "Leilao encerrado");

        require(_lance > produtos[_id].lance, "Lance deve ser maior");

        produtos[_id].lance = _lance;
        produtos[_id].enderecoComprador = msg.sender;

        // ✅ FINALIZA quando atinge preço alvo
        if (_lance >= precoALvo) {
            produtos[_id].finalizado = true;
        }

        emit LanceProduto(_id, _lance); // ✅ BOA PRÁTICA → emitir evento no lance
    }
}
