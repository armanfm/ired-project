# Plano Fundido — 30 Dias de Solidity (Versão Definitiva)

> Rigor técnico do Plano 1 + filosofia de leitura e ataque do Plano Claude + adições novas (pull over push, fuzzing, forge doc).

---

## Semana 1 — A Mente do Compilador e o Primeiro Modifier

**Objetivo:** Parar de lutar contra o compilador e começar a entender o que ele quer.

| Dia | Foco | Exercício de Ouro |
|-----|------|-------------------|
| **1** | Tipos e overflow na prática | Escreva `uint8 public x = 255;` e uma função `incrementar()` que faz `unchecked { x++; }`. Execute 3 vezes. O que acontece? Por quê? Anote. |
| **2** | storage vs memory vs calldata | Crie uma struct `Usuario { string nome; uint idade; }`. Função que modifica `storage` vs `memory` — compare gas no Remix. Descubra por que `uint256` costuma ser mais barato que `uint8` (alinhamento da EVM). |
| **3** | msg.sender e payable | Contrato "Cofre Simples": `mapping(address => uint) saldos`. Função `depositar() payable` que soma `msg.value` ao saldo de `msg.sender`. Função `sacar(uint valor)` que subtrai e envia ETH. **Sem modifier ainda.** |
| **4** | require e revert manuais | No mesmo Cofre, adicione `require(saldos[msg.sender] >= valor, "Saldo insuficiente")`. Depois refatore para `if (saldos[msg.sender] < valor) revert("Saldo insuficiente")`. Veja que fazem a mesma coisa. |
| **5** | modifier — seu primeiro | Crie `modifier onlyOwner { require(msg.sender == owner, ""); _; }`. Aplique na função `sacarTotal()` que só o dono pode chamar. Entenda que `_;` é "execute o resto da função aqui". |
| **6** | modifier com parâmetros | Crie `modifier saldoMinimo(uint min)` que verifica `saldos[msg.sender] >= min`. Use em uma função com dois modifiers: `onlyOwner` e `saldoMinimo(minimo)`. Observe a ordem de execução. |
| **7** | Diário de bugs | Pegue seu código da semana. Introduza 5 erros de propósito (ex: esquecer `_;` no modifier, inverter `>=` para `<=`). Anote **cada mensagem de erro** em português. Esse caderno será seu melhor professor. |

---

## Semana 2 — Herança, OpenZeppelin e Leitura de Código Real

**Objetivo:** Parar de "usar libs" e começar a entender o que você está herdando.

| Dia | Foco | Exercício de Ouro |
|-----|------|-------------------|
| **8** | Herança simples | Contrato `BaseToken` com `function transferir() virtual public returns(string memory)`. Contrato `TaxToken` que faz `override` e usa `super.transferir()`. |
| **9** | Herança múltipla e o problema do diamante | Crie contratos `A`, `B is A`, `C is A`, `D is B, C` — cada um com `override` de `foo()`. Execute `D.foo()` e entenda a ordem de herança linearizada (C3 linearization). |
| **10** | Lendo Ownable.sol como um livro | Abra o GitHub da OpenZeppelin. Leia `Ownable.sol` linha por linha. Escreva em um `.txt` o que cada linha faz. Depois **feche o GitHub** e reescreva `Ownable` do zero sem olhar. Compare. |
| **11** | Lendo ERC20.sol — funções principais | Leia `transfer`, `approve`, `transferFrom`, `allowance`. Anote 3 coisas que você não entendeu. Essas 3 viram perguntas para pesquisar (ex: "por que `_approve` é internal?"). |
| **12** | mapping de mapping — allowance na mão | Implemente `mapping(address => mapping(address => uint)) public allowance`. Funções `approve(address spender, uint amount)` e `transferFrom(address from, address to, uint amount)`. **Sem olhar ERC20.** |
| **13** | Pull over Push — o padrão que mata reentrância | Refatore seu Cofre da semana 1: em vez de `sacar()` enviar ETH direto, crie `mapping(address => uint) pendingWithdrawals` e funções `requestWithdraw(uint)` e `withdraw()`. Explique por que isso é mais seguro. |
| **14** | Mini projeto: Vault com tempo | Cofre onde o saque só é liberado após 24h do depósito. Use `mapping(address => uint) depositTime`. Função `sacar()` verifica `block.timestamp >= depositTime[msg.sender] + 1 days`. Use eventos para logar depósitos e saques. |

---

## Semana 3 — Tokens, Ataques e Defesa Ativa

**Objetivo:** Construir, atacar, defender. Nessa ordem.

| Dia | Foco | Exercício de Ouro |
|-----|------|-------------------|
| **15** | ERC-20 na mão | Implemente `balanceOf`, `transfer`, `approve`, `transferFrom`, `allowance`, eventos `Transfer` e `Approval`. Depois compare linha por linha com o OZ. |
| **16** | ERC-20 com OpenZeppelin | Substitua seu código manual por `import "@openzeppelin/contracts/token/ERC20/ERC20.sol"`. Entenda o que você ganhou de graça e o que você perderia se não tivesse implementado antes. |
| **17** | Contrato vulnerável a reentrância | Escreva `Vulneravel.sol`: `withdraw()` que faz `msg.sender.call{value: balances[msg.sender]}("")` **antes** de zerar o saldo. |
| **18** | Contrato atacante | Escreva `Atacante.sol` com `receive() external payable` que chama `vulneravel.withdraw()` recursivamente. Drene o contrato. Depois corrija o vulnerável com **checks-effects-interactions** (zerar saldo antes de enviar). |
| **19** | ERC-721 (NFT) na mão | Implemente `mint(address to, uint tokenId)`, `ownerOf(uint)`, `transferFrom`. Entenda a diferença entre `balanceOf` do ERC-20 (quantidade) e do ERC-721 (quantos tokens um endereço possui). |
| **20** | ERC-721 com metadados | Adicione `mapping(uint => string) tokenURIs`. Função `tokenURI(uint)` retorna uma string apontando para JSON (`ipfs://...` ou `https://...`). Teste no OpenSea testnet. |
| **21** | Auditoria do seu próprio código | Pegue seu ERC-20 e tente quebrar: "e se `transfer` receber `address(0)`? e se `amount` for maior que o saldo? e se `approve` for chamado duas vezes? e se `transferFrom` for chamado sem allowance?" Corrija os furos com `require`. |

---

## Semana 4 — Foundry, Fuzzing, Deploy e Independência

**Objetivo:** Sair do Remix e usar ferramentas profissionais.

| Dia | Foco | Exercício de Ouro |
|-----|------|-------------------|
| **22** | Foundry — instalação e primeiro teste | Instale Foundry (`curl -L https://foundry.paradigm.xyz \| bash`). Escreva um teste unitário para seu ERC-20: `function testTransfer() public { token.transfer(alice, 100); assertEq(token.balanceOf(alice), 100); }`. |
| **23** | Fuzzing — deixe o Foundry tentar te quebrar | Escreva `function testFuzz_transfer(address to, uint amount) public`. Use `vm.assume(to != address(0))` e `vm.assume(amount <= token.balanceOf(address(this)))`. Rode `forge test`. Anote cada falha. |
| **24** | Ethernaut — Fallback e Telephone | Nível 1 (Fallback): como `receive()` e `msg.value` podem mudar o `owner`. Nível 4 (Telephone): diferença crucial entre `tx.origin` (quem assinou a transação original) e `msg.sender` (quem chamou a função imediatamente). |
| **25** | Ethernaut — Reentrância e King | Nível 10 (Reentrancy): refaça o ataque do dia 17–18 dentro do Ethernaut. Nível 9 (King): entenda como `receive()` pode travar um contrato para sempre. |
| **26** | Projeto integrador — Staking com recompensa | Contrato que: (1) aceita depósito de um ERC-20 específico, (2) calcula recompensa baseada em `block.timestamp`, (3) só permite saque após 7 dias, (4) usa **pull over push** para pagamentos. |
| **27** | Testes Foundry do projeto + deploy Sepolia | Escreva testes para o contrato de staking. Depois use Foundry para deploy na Sepolia. Interaja via `cast send` e `cast call`. Verifique no Etherscan Sepolia. |
| **28** | NatSpec completo + forge doc | Documente com `/// @title`, `/// @notice`, `/// @dev`, `/// @param`, `/// @return`. Rode `forge doc` e gere a documentação HTML automaticamente. |
| **29** | README profissional | Escreva um README explicando: (1) o que seu contrato faz, (2) decisões de design (ex: "usei pull over push porque..."), (3) vulnerabilidades que você evitou, (4) como testar localmente. |
| **30** | Dia da Independência | Feche todos os tutoriais, IA e referências. Por **1 hora**, escreva um contrato novo do zero — leilão, votação, carteira multi-sig simples. Depois abra as referências e anote: **o que você não soube, errou ou esqueceu**. Essa lista é seu plano para o próximo mês. |

---

## O que foi adicionado de novo neste plano

| Adição | Onde está | Por que |
|--------|-----------|---------|
| Pull over Push | Dia 13 | Padrão que mata reentrância de forma elegante, não só com `ReentrancyGuard` |
| Problema do diamante (herança múltipla) | Dia 9 | Aparece em contratos reais (ERC20 + Ownable + Pausable) — quem não entende quebra |
| Ethernaut King | Dia 25 | Ensina como um contrato malicioso pode travar outro para sempre |
| forge doc | Dia 28 | Ferramenta real que gera documentação automaticamente |
| cast send / cast call | Dia 27 | Interagir com contrato via terminal, não só pelo Remix |
| vm.assume no fuzzing | Dia 23 | Técnica essencial para fuzzing real — sem ela os testes falham por casos inválidos |

---

## O que não está no plano (para o Mês 2)

Tópicos avançados que não cabem em 30 dias sem sobrecarregar:

- **Assembly Yul** — otimização extrema de gas
- **Upgradeable proxies (UUPS vs Transparent)**
- **Create2** — deploy de contratos em endereços pré-calculados
- **Multisig (Gnosis Safe)**
- **Merkle proofs** — para airdrops
- **Gas golf** — competição de quem escreve a função mais barata

---

## Para começar agora (Dia 1)

Abra o Remix. Escreva:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Overflow {
    uint8 public x = 255;

    function incrementar() public {
        unchecked { x++; }
    }
}
```

Execute `incrementar()` 3 vezes. O que acontece no terceiro clique? Por quê?

Isso vai te ensinar mais sobre a EVM do que qualquer tutorial de 2 horas.

