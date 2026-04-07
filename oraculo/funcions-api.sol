// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts@1.3.0/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts@1.3.0/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract FunctionsConsumer is FunctionsClient {

    // Permite chamar funções da lib FunctionsRequest nas structs Request
    using FunctionsRequest for FunctionsRequest.Request;

    // Endereço do roteador Chainlink Functions na Sepolia
    address constant ROUTER = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;

    // ID da rede descentralizada de oráculos (DON) na Sepolia
    bytes32 constant DON_ID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    // Gas máximo pra executar o fulfillRequest quando a resposta chegar
    uint32 constant GAS_LIMIT = 300000;

    // Código JavaScript que roda off-chain no Chainlink
    // Busca temperatura de uma cidade via API wttr.in
    string public constant SOURCE =
        "const city = args[0];"
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://wttr.in/${city}?format=3&m`,"
        "responseType: 'text'"
        "});"
        "if (apiResponse.error) {"
        "throw Error('Request failed');"
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeString(data);";

    // Variáveis que guardam o estado das requisições
    string public s_lastCity;        // última cidade que teve temperatura buscada
    string public s_requestedCity;   // cidade da requisição atual pendente
    string public s_lastTemperature; // última temperatura recebida

    bytes32 public s_lastRequestId;  // ID da última requisição enviada
    bytes public s_lastResponse;     // resposta bruta da última requisição
    bytes public s_lastError;        // erro da última requisição (se houver)

    // Evento emitido quando o Chainlink responde com a temperatura
    event Response(
        bytes32 indexed requestId,
        string temperature,
        bytes response,
        bytes err
    );

    // Erro customizado — quando o requestId da resposta não bate com o esperado
    error UnexpectedRequestID(bytes32 requestId);

    // Constructor — passa o endereço do roteador pro FunctionsClient
    constructor() FunctionsClient(ROUTER) {}

    // Função principal — envia requisição pro Chainlink pra buscar temperatura
    // _city — nome da cidade (ex: "London", "Recife")
    // subscriptionId — ID da sua assinatura no Chainlink Functions (financiada com LINK)
    function getTemperature(
        string memory _city,
        uint64 subscriptionId
    ) external returns (bytes32 requestId) {

        // 1. Cria a struct de requisição
        FunctionsRequest.Request memory req;

        // 2. Inicializa com o código JavaScript que vai rodar off-chain
        req.initializeRequestForInlineJavaScript(SOURCE);

        // 3. Define os argumentos que o JS vai receber (args[0] = cidade)
        string[] memory args = new string[](1);
        args[0] = _city;
        req.setArgs(args);

        // 4. Envia a requisição pro Chainlink e guarda o ID
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),  // requisição codificada em CBOR
            subscriptionId,    // quem paga o LINK
            GAS_LIMIT,         // gas máximo pro callback
            DON_ID             // qual DON vai executar
        );

        // 5. Guarda a cidade que foi solicitada
        s_requestedCity = _city;

        return s_lastRequestId;
    }

    // Callback — Chainlink chama essa função quando tem a resposta
    // É chamada automaticamente pelo DON após executar o JavaScript
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {

        // Verifica se é a resposta da requisição que fizemos
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }

        // Salva erro e resposta bruta
        s_lastError = err;
        s_lastResponse = response;

        // Converte resposta de bytes pra string e salva
        s_lastTemperature = string(response);
        s_lastCity = s_requestedCity;

        // Emite evento pra rastrear a resposta
        emit Response(requestId, s_lastTemperature, s_lastResponse, s_lastError);
    }
}
