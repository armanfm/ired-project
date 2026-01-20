# Hash Determinístico de Eventos — Motor ON/OFF + Prova por Odômetro

## 1. Objetivo

Este documento descreve o modelo determinístico de eventos utilizado para gerar provas **não-repetíveis** e **não-forjáveis** de uso veicular, com base em transições de estado do motor (ON / OFF) combinadas com leituras de odômetro.

O sistema foi projetado para fornecer **contabilidade auditável e resistente a adulterações** para:

- consumo de combustível
- reembolso por quilometragem
- controle operacional

sem exigir rastreamento contínuo ou telemetria invasiva.

---

## 2. Princípio Central

Um evento físico só é válido quando representa **uma transição de estado**.

Cada transição de estado gera um **hash criptográfico único**, derivado de entradas imutáveis.

O sistema **não rastreia movimento contínuo**.  
Ele **registra eventos**.

---

## 3. Tipos de Evento

Existem apenas dois eventos válidos:

- `ENGINE_ON`
- `ENGINE_OFF`

Cada evento representa um **instantâneo do estado do sistema** naquele momento.

---

## 4. Construção Determinística do Hash

Cada hash de evento é calculado a partir das seguintes entradas canônicas:

```text
HASH = H(
  tipo_evento,        // ON ou OFF
  odometro_km,        // leitura exata em km
  timestamp,          // tempo monotônico
  device_id,          // identidade do hardware
  fingerprint_veiculo
)
## Propriedades

- Todas as entradas são imutáveis no momento da captura  
- Não há interpretação externa  
- Não existem suposições de confiança off-chain  

---

## 4.1 Requisito de Tempo Monotônico

O `timestamp` utilizado **não precisa representar tempo absoluto confiável**  
(ex.: horário oficial, NTP ou GPS).

O único requisito é que ele seja:

- **monotônico**
- **não regressivo**
- **local ao dispositivo**

Formalmente:

```text
timestamp(n+1) > timestamp(n)
para qualquer par de eventos consecutivos registrados pelo mesmo dispositivo.

### Implicações

- Ajustes manuais de relógio não invalidam o sistema, desde que não causem regressão temporal  
- Não há dependência de sincronização externa  
- O sistema permanece válido em operação offline  
- A unicidade dos hashes é preservada  

### Propriedade Garantida

Mesmo sem tempo absoluto confiável:

- hashes não se repetem  
- ataques de replay continuam impossíveis  
- a reexecução determinística permanece válida  

---

## 5. Por Que Hashes Nunca se Repetem

Um hash não pode se repetir porque **ao menos uma entrada sempre muda**.

### Análise de Casos

**Primeira partida do dia**

- EVENTO: ON  
- KM: 10.000  
- HORA: 08:01  
→ `HASH_A`

**Desligamento do motor**

- EVENTO: OFF  
- KM: 10.035  
- HORA: 08:47  
→ `HASH_B`

**Nova partida**

- EVENTO: ON  
- KM: 10.035  
- HORA: 09:10  
→ `HASH_C`

Mesmo que:

- o motor seja ligado novamente  
- o veículo não se mova  
- o mesmo motorista esteja presente  

➡ o timestamp é diferente, portanto o hash é diferente.

A repetição de hash só seria possível se **o tempo parasse**.

---

## 6. Regra Contábil Válida

A única forma válida de cálculo é:

```text
Consumo / Distância / Uso =
  KM_ULTIMO_ENGINE_OFF_DO_DIA
- KM_PRIMEIRO_ENGINE_ON_DO_DIA
Eventos intermediários ON/OFF:

- são permitidos  
- aumentam a granularidade da auditoria  
- não alteram o resultado final  

---

## 7. Garantias Antifraude

### 7.1 Manipulação do Odômetro

- Exige adulteração física  
- Alto custo  
- Facilmente detectável pela inconsistência da sequência de eventos  

### 7.2 Remoção ou Realocação do Sensor

- O dispositivo é criptograficamente vinculado ao fingerprint do veículo  
- Mover o sensor quebra a continuidade  
- Veículo novo ≠ mesma cadeia de hash  

### 7.3 Ciclagem Falsa de ON/OFF

- Gera mais hashes, não mais valor  
- Não aumenta reembolso  
- A regra final de alinhamento permanece válida  

### 7.4 Ataques de Replay

Impossíveis.

- Timestamp monotônico + identidade do dispositivo quebram qualquer tentativa de replay  

---

## 8. Dados Mínimos, Prova Máxima

O sistema **intencionalmente evita**:

- GPS contínuo  
- sensores de combustível em tempo real  
- rastreamento invasivo  

Em vez disso, utiliza:

- transições de estado  
- finalidade criptográfica  
- reexecução determinística  

Isso reduz drasticamente:

- custo  
- complexidade  
- superfície de ataque  

---

## 9. Características do Sistema

- Verificação stateless  
- Ledger de eventos append-only  
- Reexecução determinística  
- Independente de hardware específico  
- Compatível com IoT, OBD-II ou módulos externos  

---

## 10. Resumo

- Cada ON ou OFF do motor gera um hash único  
- Hashes nunca se repetem  
- Apenas o primeiro ON e o último OFF importam para a contabilidade  
- Vetores de fraude colapsam sob validação determinística  
- O modelo escala de frotas governamentais a empresas privadas  

**O que importa não é o movimento.**  
**O que importa é a transição de estado.**

> **O sistema não impede o uso indevido.  
> Ele torna o uso injustificável sem explicação.**

Com timestamp, **ninguém some no tempo**.
