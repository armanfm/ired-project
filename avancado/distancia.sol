// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts@1.3.0/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts@1.3.0/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract Rota is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    address constant ROUTER = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    bytes32 constant DON_ID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
    uint32 constant GAS_LIMIT = 300000;

    // Código JS que busca distância entre dois pontos via OpenStreetMap (gratuito, sem API key)
    string public constant SOURCE =
        "const origem = args[0];"
        "const destino = args[1];"
        "const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(origem)}&format=json&limit=1`;"
        "const origemRes = await Functions.makeHttpRequest({ url });"
        "const destinoRes = await Functions.makeHttpRequest({"
        "url: `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(destino)}&format=json&limit=1`"
        "});"
        "const lat1 = parseFloat(origemRes.data[0].lat);"
        "const lon1 = parseFloat(origemRes.data[0].lon);"
        "const lat2 = parseFloat(destinoRes.data[0].lat);"
        "const lon2 = parseFloat(destinoRes.data[0].lon);"
        "const R = 6371;"
        "const dLat = (lat2 - lat1) * Math.PI / 180;"
        "const dLon = (lon2 - lon1) * Math.PI / 180;"
        "const a = Math.sin(dLat/2) * Math.sin(dLat/2) +"
        "Math.cos(lat1 * Math.PI/180) * Math.cos(lat2 * Math.PI/180) *"
        "Math.sin(dLon/2) * Math.sin(dLon/2);"
        "const distanciaKm = R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));"
        "return Functions.encodeUint256(Math.round(distanciaKm));";

    // Dados da rota
    string public s_origem;
    string public s_destino;
    uint256 public s_distanciaKm;

    // Chainlink
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    event Response(bytes32 indexed requestId, uint256 distanciaKm, bytes err);
    error UnexpectedRequestID(bytes32 requestId);

    constructor() FunctionsClient(ROUTER) {}

    function calcularDistancia(
        string memory _origem,
        string memory _destino,
        uint64 subscriptionId
    ) external returns (bytes32 requestId) {

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(SOURCE);

        string[] memory args = new string[](2);
        args[0] = _origem;
        args[1] = _destino;
        req.setArgs(args);

        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            GAS_LIMIT,
            DON_ID
        );

        s_origem = _origem;
        s_destino = _destino;

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

        s_lastError = err;
        s_lastResponse = response;

        // Converte bytes para uint256 (distância em KM)
        if (response.length > 0) {
            s_distanciaKm = abi.decode(response, (uint256));
        }

        emit Response(requestId, s_distanciaKm, err);
    }
}
