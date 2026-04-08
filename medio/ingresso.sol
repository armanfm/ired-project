// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@4.9.3/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.9.3/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts@1.3.0/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip@1.4.0/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip@1.4.0/src/v0.8/ccip/libraries/Client.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip@1.4.0/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";

contract Ingresso is ERC721URIStorage, Ownable, CCIPReceiver {

    struct Evento {
        uint id;
        string nome;
        string dataEvento;
        string local;
        uint ingressosDisponiveis;
        uint ingressosVendidos;
        uint preco;
    }

    AggregatorV3Interface public priceFeed;

    constructor() ERC721("Show Chain", "SWC") Ownable() CCIPReceiver(0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59) {
        priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    Evento[] public eventos;
    mapping(uint => address[]) public ingressosComprados;
    mapping(address => uint[]) public ingressosUsuario;
    mapping(uint256 => bool) private _minted;

    event IngressoComprado(address indexed comprador, uint indexed eventoId, uint tokenId);

    function criarEvento(
        string memory _nome,
        string memory _dataEvento,
        string memory _local,
        uint _ingressosDisponiveis,
        uint _preco
    ) public onlyOwner {
        uint _id = eventos.length;
        eventos.push(Evento(_id, _nome, _dataEvento, _local, _ingressosDisponiveis, 0, _preco));
    }

    function listar(uint _id) public view returns (Evento memory) {
        require(_id < eventos.length, "Evento nao encontrado");
        return eventos[_id];
    }

    function comprarIngresso(uint _id, uint _quantidade) public payable {
        require(_id < eventos.length, "Evento nao encontrado");
        require(eventos[_id].ingressosDisponiveis >= _quantidade, "Ingressos insuficientes");
        require(msg.value == eventos[_id].preco * _quantidade, "Valor incorreto");

        for (uint i = 0; i < _quantidade; i++) {
            uint tokenId = eventos[_id].ingressosVendidos + i;
            require(!_minted[tokenId], "Token ja mintado");
           
            _minted[tokenId] = true;
            _mint(msg.sender, tokenId);
            ingressosUsuario[msg.sender].push(tokenId);
            ingressosComprados[_id].push(msg.sender);
            emit IngressoComprado(msg.sender, _id, tokenId);
        }

        eventos[_id].ingressosDisponiveis -= _quantidade;
        eventos[_id].ingressosVendidos += _quantidade;
    }

    function listarIngressoUsuario(address _usuario) public view returns (uint[] memory) {
        require(_usuario != address(0), "Endereco invalido");
        return ingressosUsuario[_usuario];
    }

    function getETHPrice() public view returns (int) {
        (, int price,,,) = priceFeed.latestRoundData();
        return price;
    }

    function getPrecoEmUSD(uint _id) public view returns (int) {
        require(_id < eventos.length, "Evento nao encontrado");
        int ethPrice = getETHPrice();
        int precoWei = int(eventos[_id].preco);
        return (precoWei * ethPrice) / 1e26;
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        address comprador = abi.decode(message.sender, (address));
        uint eventoId = abi.decode(message.data, (uint256));

        require(eventoId < eventos.length, "Evento nao encontrado");
        require(eventos[eventoId].ingressosDisponiveis > 0, "Ingressos esgotados");
        uint256 valorRecebido = message.destTokenAmounts[0].amount;
        require(valorRecebido >= eventos[eventoId].preco, "Pagamento insuficiente");
        uint tokenId = eventos[eventoId].ingressosVendidos;
        require(!_minted[tokenId], "Token ja mintado");

    
        _minted[tokenId] = true;
        _mint(comprador, tokenId);

        ingressosUsuario[comprador].push(tokenId);
        ingressosComprados[eventoId].push(comprador);
        eventos[eventoId].ingressosDisponiveis--;
        eventos[eventoId].ingressosVendidos++;

        emit IngressoComprado(comprador, eventoId, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public pure override(ERC721URIStorage, CCIPReceiver)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IAny2EVMMessageReceiver).interfaceId;
    }

    function sacarVendas() public onlyOwner {
        require(address(this).balance > 0, "Sem saldo");
        (bool sucesso,) = payable(owner()).call{value: address(this).balance}("");
        require(sucesso, "Falha ao sacar");
    }
}
