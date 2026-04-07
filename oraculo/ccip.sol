// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Ownable — controle de acesso, só o dono pode chamar funções protegidas
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// IRouterClient — interface do roteador CCIP que envia mensagens entre blockchains
import {IRouterClient} from "@chainlink/contracts-ccip@1.4.0/src/v0.8/ccip/interfaces/IRouterClient.sol";

// IERC20 — interface padrão pra interagir com tokens ERC20 externos (USDC, LINK)
import {IERC20} from "@chainlink/contracts-ccip@1.4.0/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

// SafeERC20 — versão segura das operações ERC20 — reverte se falhar (token externo)
import {SafeERC20} from "@chainlink/contracts-ccip@1.4.0/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

// Client — biblioteca com as structs de mensagem do CCIP (EVM2AnyMessage, EVMTokenAmount)
import {Client} from "@chainlink/contracts-ccip@1.4.0/src/v0.8/ccip/libraries/Client.sol";


contract CCIPTokenSender is Ownable {

    // Ativa as funções seguras do SafeERC20 pra qualquer IERC20
    // Agora você pode usar USDC.safeTransfer() em vez de USDC.transfer()
    using SafeERC20 for IERC20;

    // Endereço do roteador CCIP na Sepolia — é ele que envia a mensagem entre chains
    IRouterClient private constant CCIP_ROUTER = IRouterClient(0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59);

    // Token LINK na Sepolia — usado pra pagar a taxa do CCIP
    IERC20 private constant LINK_TOKEN = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789);

    // Token USDC na Sepolia — é o token que vai ser transferido entre blockchains
    IERC20 private constant USDC_TOKEN = IERC20(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238);

    // Identificador único da rede de destino (Base Sepolia)
    // Cada blockchain tem um seletor diferente no CCIP
    uint64 private constant DESTINATION_CHAIN_SELECTOR = 10344971235874465080;

    // Evento emitido quando a transferência é enviada com sucesso
    // messageId — ID único pra rastrear a transferência no CCIP Explorer
    // destinationChain — qual blockchain vai receber
    // receiver — quem vai receber na outra chain
    // amount — quanto USDC foi enviado
    // fees — quanto LINK foi cobrado de taxa
    event USDCTransferido(
        bytes32 indexed messageId,
        uint64 indexed destinationChain,
        address receiver,
        uint256 amount,
        uint256 fees
    );

    // Constructor — define o owner do contrato
    constructor() Ownable(msg.sender) {}

    // Função principal — transfere USDC da Sepolia pra Base Sepolia via CCIP
    // _receiver — endereço que vai receber o USDC na outra chain
    // _amount — quantidade de USDC a transferir
    // retorna messageId — ID único pra rastrear no CCIP Explorer
    function transferTokens(
        address _receiver,
        uint256 _amount
    ) external returns (bytes32 messageId) {

        // 1. CHECKS — verifica se o usuário tem USDC suficiente
        require(_amount <= USDC_TOKEN.balanceOf(msg.sender), "Saldo USDC insuficiente");

        // 2. Monta o array de tokens que vão ser transferidos
        // CCIP aceita múltiplos tokens — aqui só enviamos USDC então array tem 1 elemento
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(USDC_TOKEN), // qual token
            amount: _amount             // quanto
        });

        // 3. Monta a mensagem CCIP completa
        // É o "envelope" que o roteador vai enviar pra outra blockchain
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // endereço do destinatário em bytes
            data: "",                         // sem dados extras — só tokens
            tokenAmounts: tokenAmounts,       // os tokens que vão junto
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 0}) // gasLimit 0 pq destinatário é carteira, não contrato
            ),
            feeToken: address(LINK_TOKEN)     // paga a taxa em LINK
        });

        // 4. Calcula quanto LINK vai custar pra enviar essa mensagem
        uint256 ccipFee = CCIP_ROUTER.getFee(DESTINATION_CHAIN_SELECTOR, message);

        // 5. Verifica se o contrato tem LINK suficiente pra pagar a taxa
        require(ccipFee <= LINK_TOKEN.balanceOf(address(this)), "LINK insuficiente para taxa");

        // 6. Aprova o roteador a gastar o LINK do contrato (pra pagar a taxa)
        LINK_TOKEN.approve(address(CCIP_ROUTER), ccipFee);

        // 7. EFFECTS — puxa o USDC do usuário pro contrato (precisa de approve antes!)
        // safeTransferFrom — usa SafeERC20, reverte se falhar
        USDC_TOKEN.safeTransferFrom(msg.sender, address(this), _amount);

        // 8. Aprova o roteador a gastar o USDC do contrato (pra enviar pra outra chain)
        USDC_TOKEN.approve(address(CCIP_ROUTER), _amount);

        // 9. INTERACTIONS — envia a mensagem CCIP
        // O roteador pega o LINK (taxa) e o USDC e envia pra Base Sepolia
        messageId = CCIP_ROUTER.ccipSend(DESTINATION_CHAIN_SELECTOR, message);

        // 10. Emite evento pra rastrear a transferência
        emit USDCTransferido(
            messageId,
            DESTINATION_CHAIN_SELECTOR,
            _receiver,
            _amount,
            ccipFee
        );
    }

    // Função de emergência — owner pode sacar USDC preso no contrato
    // _beneficiary — quem vai receber o USDC sacado
    function withdrawToken(address _beneficiary) public onlyOwner {
        uint256 amount = USDC_TOKEN.balanceOf(address(this));
        require(amount > 0, "Nada para sacar");
        USDC_TOKEN.transfer(_beneficiary, amount);
    }
}
