// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts@1.3.0/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts@1.3.0/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract Rota is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    address constant ROUTER    = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    bytes32 constant DON_ID    = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
    uint32  constant GAS_LIMIT = 300000;

    // JS executado no DON da Chainlink
    // Recebe lat/lon direto do GPS do celular — sem Nominatim, sem rate limit
    // OSRM: gratuito, ilimitado, sem API key, OpenStreetMap
    string public constant SOURCE =
        // Coordenadas vindas do GPS do celular do motorista
        "const lat1 = args[0];"   // lat atual do motorista
        "const lon1 = args[1];"   // lon atual do motorista
        "const lat2 = args[2];"   // lat do destino
        "const lon2 = args[3];"   // lon do destino

        // OSRM — rota real pelas ruas, uma única chamada HTTP
        "const osrmRes = await Functions.makeHttpRequest({"
        "  url: `https://router.project-osrm.org/route/v1/driving/${lon1},${lat1};${lon2},${lat2}?overview=false`"
        "});"

        // Validação da resposta
        "if (osrmRes.error) throw new Error('Erro na chamada OSRM');"
        "if (osrmRes.data.code !== 'Ok') throw new Error('OSRM: rota nao encontrada');"

        // Distância retornada em metros → converte para km e arredonda
        "const distanciaKm = osrmRes.data.routes[0].distance / 1000;"
        "return Functions.encodeUint256(Math.round(distanciaKm));";

    // Dados da corrida
    string  public s_lat1;        // lat do motorista (origem)
    string  public s_lon1;        // lon do motorista (origem)
    string  public s_lat2;        // lat do destino
    string  public s_lon2;        // lon do destino
    uint256 public s_distanciaKm; // resultado em km

    // Chainlink
    bytes32 public s_lastRequestId;
    bytes   public s_lastResponse;
    bytes   public s_lastError;

    event Response(bytes32 indexed requestId, uint256 distanciaKm, bytes err);
    event DistanciaCalculada(string lat1, string lon1, string lat2, string lon2, uint256 distanciaKm);

    error UnexpectedRequestID(bytes32 requestId);

    constructor() FunctionsClient(ROUTER) {}

    // Chamado quando o passageiro solicita cancelamento
    // lat/lon vêm do GPS do celular do motorista via backend
    function calcularDistancia(
        string memory _lat1,  // posição atual do motorista
        string memory _lon1,
        string memory _lat2,  // destino da corrida
        string memory _lon2,
        uint64 subscriptionId
    ) external returns (bytes32 requestId) {

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(SOURCE);

        // Passa as 4 coordenadas como args para o JS no DON
        string[] memory args = new string[](4);
        args[0] = _lat1;
        args[1] = _lon1;
        args[2] = _lat2;
        args[3] = _lon2;
        req.setArgs(args);

        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            GAS_LIMIT,
            DON_ID
        );

        // Salva as coordenadas para referência
        s_lat1 = _lat1;
        s_lon1 = _lon1;
        s_lat2 = _lat2;
        s_lon2 = _lon2;

        return s_lastRequestId;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {

        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }

        s_lastError    = err;
        s_lastResponse = response;

        if (response.length > 0) {
            s_distanciaKm = abi.decode(response, (uint256));
            emit DistanciaCalculada(s_lat1, s_lon1, s_lat2, s_lon2, s_distanciaKm);
        }

        emit Response(requestId, s_distanciaKm, err);
    }
}
