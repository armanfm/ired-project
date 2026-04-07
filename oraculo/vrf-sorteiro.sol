// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Contrato base que todo consumidor VRF precisa herdar
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.3.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

// Biblioteca com as structs de requisição VRF
import {VRFV2PlusClient} from "@chainlink/contracts@1.3.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract HousePicker is VRFConsumerBaseV2Plus {

    // Valor sentinela — indica que o dado ainda tá rolando
    // Usamos 4 porque as casas vão de 0 a 3
    uint256 private constant ROLL_IN_PROGRESS = 4;

    // ID da sua assinatura VRF — quem paga o LINK
    uint256 public s_subscriptionId;

    // Endereço do coordenador VRF na Sepolia
    address public constant VRF_COORDINATOR = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;

    // Key hash — define o preço máximo de gas que você aceita pagar
    bytes32 public constant KEY_HASH = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    // Gas máximo pra executar o fulfillRandomWords quando a resposta chegar
    uint32 public callbackGasLimit = 40000;

    // Quantos blocos esperar antes de retornar o número aleatório
    // Mais confirmações = mais seguro contra manipulação
    uint16 public requestConfirmations = 3;

    // Quantos números aleatórios pedir — aqui só precisamos de 1
    uint32 public numWords = 1;

    // Mapeia requestId → endereço do jogador que pediu
    mapping(uint256 => address) private s_rollers;

    // Mapeia endereço do jogador → resultado (ID da casa 0-3, ou ROLL_IN_PROGRESS)
    mapping(address => uint256) private s_results;

    // Evento emitido quando o dado é lançado — requisição enviada pro Chainlink
    event DiceRolled(uint256 indexed requestId, address indexed roller);

    // Evento emitido quando o número aleatório chega e a casa é definida
    event DiceLanded(uint256 indexed requestId, uint256 indexed result);

    // Constructor — recebe o subscriptionId e passa o coordenador pro contrato base
    constructor(uint256 subscriptionId) VRFConsumerBaseV2Plus(VRF_COORDINATOR) {
        s_subscriptionId = subscriptionId;
    }

    // Função principal — jogador chama pra sortear sua casa
    // Só pode chamar uma vez por endereço
    function rollDice() public returns (uint256 requestId) {

        // Garante que o jogador ainda não rolou o dado
        require(s_results[msg.sender] == 0, "Ja rolou");

        // Envia requisição pro Chainlink VRF pedindo 1 número aleatório
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: KEY_HASH,                    // rota de gas
                subId: s_subscriptionId,              // quem paga
                requestConfirmations: requestConfirmations, // blocos de espera
                callbackGasLimit: callbackGasLimit,   // gas pro callback
                numWords: numWords,                   // quantos números
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false}) // paga em LINK, não ETH
                )
            })
        );

        // Guarda quem fez essa requisição
        s_rollers[requestId] = msg.sender;

        // Marca como em progresso
        s_results[msg.sender] = ROLL_IN_PROGRESS;

        emit DiceRolled(requestId, msg.sender);
    }

    // Callback — Chainlink chama essa função quando tem o número aleatório
    // É chamada automaticamente pelo coordenador VRF
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {

        // Converte o número aleatório em 0, 1, 2 ou 3 (4 casas)
        // % 4 pega o resto da divisão por 4 — sempre entre 0 e 3
        uint256 d6Value = randomWords[0] % 4;

        // Salva o resultado pro jogador que fez essa requisição
        s_results[s_rollers[requestId]] = d6Value;

        emit DiceLanded(requestId, d6Value);
    }

    // Consulta qual casa foi sorteada pra um jogador
    function house(address player) public view returns (string memory) {
        require(s_results[player] != 0, "Dado nao rolado");
        require(s_results[player] != ROLL_IN_PROGRESS, "Roll in progress");
        return _getHouseName(s_results[player]);
    }

    // Converte ID da casa em nome
    function _getHouseName(uint256 id) private pure returns (string memory) {
        string[4] memory houseNames = [
            "Gryffindor", // id = 0
            "Hufflepuff",  // id = 1
            "Slytherin",   // id = 2
            "Ravenclaw"    // id = 3
        ];
        return houseNames[id];
    }
}
