// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TarefaContrato { 
    struct Tarefa {
        uint id;
        string descricao;
        bool concluida;
        bool ativa;
    }

    Tarefa[] public tarefas;
    mapping(uint => Tarefa) public tarefasMap;
    
    // MUDANÇA: Ajustei os eventos para baterem com o que é emitido nas funções
    event TarefaCriada(uint id, string descricao);
    event TarefaConcluida(uint id);
    event TarefaExcluida(uint id);

    // MUDANÇA: Removi 'novoId' do parâmetro. O contrato gera o ID sozinho.
    function criarTarefa(string memory _descricao) public {
        require(bytes(_descricao).length > 0, "A descricao nao pode estar vazia");
        
        uint novoId = tarefas.length + 1;
        
        // MUDANÇA: O último campo (ativa) deve ser TRUE. Se for false, ela nasce "deletada".
        Tarefa memory novaTarefa = Tarefa(novoId, _descricao, false, true);
        
        // MUDANÇA: Adicionado push. Sem isso, a função listar() retorna vazio.
        tarefas.push(novaTarefa); 
        tarefasMap[novoId] = novaTarefa;
      
        emit TarefaCriada(novoId, _descricao);
    }

    // MUDANÇA: Simplifiquei. Se é para concluir, não precisa de descrição nova.
    function marcarComoConcluida(uint _id) public {
        // MUDANÇA: Verificamos se o ID existe e se a tarefa está ativa
        require(tarefasMap[_id].id != 0, "Tarefa nao encontrada");
        require(tarefasMap[_id].ativa == true, "Tarefa foi excluida");

        tarefasMap[_id].concluida = true;
        
        // MUDANÇA: Sincroniza com o array (índice é sempre ID - 1)
        tarefas[_id - 1].concluida = true;

        emit TarefaConcluida(_id);
    }


    // Removi o 'bool _ativa' da entrada, pois o contrato já sabe esse valor
    function listarPorId(uint _id) public view returns (Tarefa memory) {
        // 1. Verifica se o ID existe
        require(tarefasMap[_id].id != 0, "Tarefa nao encontrada");
        
        // 2. Verifica se o campo 'ativa' gravado no mapping é verdadeiro
        require(tarefasMap[_id].ativa == true, "Tarefa foi excluida ou nao existe");
        
        return tarefasMap[_id];
    }

    // NOVA FUNÇÃO: Para usar o seu campo 'ativa' como um "Delete"
    function excluirTarefa(uint _id) public {
        require(tarefasMap[_id].id != 0, "Tarefa nao encontrada");
        
        tarefasMap[_id].ativa = false;
        tarefas[_id - 1].ativa = false;

        emit TarefaExcluida(_id);
    }
function listarAtivas() public view returns (Tarefa[] memory) {
    uint contadorAtivas = 0;

    // 1. Descobrir o tamanho exato do array de retorno
    for (uint i = 0; i < tarefas.length; i++) {
        if (tarefas[i].ativa == true) {
            contadorAtivas++;
        }
    }

    // 2. Criar o array na memória com o tamanho que contamos
    Tarefa[] memory somenteAtivas = new Tarefa[](contadorAtivas);
    uint indiceBusca = 0;

    // 3. Preencher o novo array apenas com quem está ativo
    for (uint i = 0; i < tarefas.length; i++) {
        if (tarefas[i].ativa == true) {
            somenteAtivas[indiceBusca] = tarefas[i];
            indiceBusca++;
        }
    }

    return somenteAtivas;
}
}
