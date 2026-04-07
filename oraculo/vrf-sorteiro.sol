// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.3.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts@1.3.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract SorteioVRF is VRFConsumerBaseV2Plus {

    address public constant VRF_COORDINATOR = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    bytes32 public constant KEY_HASH = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    
    uint256 public s_subscriptionId;
    uint32 public callbackGasLimit = 40000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    // Número aleatório retornado pelo Chainlink
    uint256 public s_randomResult;
    
    // Status da requisição
    bool public s_sorteioEmProgresso;

    event SorteioSolicitado(uint256 indexed requestId);
    event SorteioRealizado(uint256 indexed requestId, uint256 resultado);

    constructor(uint256 subscriptionId) VRFConsumerBaseV2Plus(VRF_COORDINATOR) {
        s_subscriptionId = subscriptionId;
    }

    // Solicita número aleatório — você chama isso pra iniciar o sorteio
    function solicitarAleatorio() public returns (uint256 requestId) {
        require(!s_sorteioEmProgresso, "Sorteio em progresso");

        s_sorteioEmProgresso = true;

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: KEY_HASH,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        emit SorteioSolicitado(requestId);
    }

    // Chainlink chama isso automaticamente quando tem o número
    // s_randomResult fica disponível pra você usar no seu contrato
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        s_randomResult = randomWords[0];
        s_sorteioEmProgresso = false;
        emit SorteioRealizado(requestId, s_randomResult);
    }
}
