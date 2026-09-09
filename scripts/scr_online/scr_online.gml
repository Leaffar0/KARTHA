/// Infraestrutura do lobby online KARTHA (Colyseus).

function online_carregar_endpoint() {
    ini_open("kartha_online.ini");
    var _endpoint = ini_read_string("online", "servidor", "wss://doily-pointy-nurture.ngrok-free.dev");
    ini_close();
    return _endpoint;
}

function online_salvar_endpoint(_endpoint) {
    var _valor = string_trim(_endpoint);
    if (_valor == "") return;
    ini_open("kartha_online.ini");
    ini_write_string("online", "servidor", _valor);
    ini_close();
}

function online_inicializar() {
    if (variable_global_exists("online_inicializado")) return;
    global.online_inicializado = true;
    global.net_client = 0;
    global.net_room = 0;
    global.net_connected = false;
    global.net_room_id = "";
    global.net_session_id = "";
    global.online_status = "desconectado";
    global.online_erro = "";
    global.online_nome = "Jogador";
    global.online_assento = -1;
    global.online_fase = "waiting";
    global.online_iniciativa = [-1, -1];
    global.online_vencedor_iniciativa = -1;
    global.online_primeiro = -1;
    global.online_seed = 0;
    global.online_revisao = 0;
    global.online_mao_privada = [];
    global.online_armadilhas_privadas = [];
    global.online_efeitos_privados = [];
    global.online_estado_publico = noone;
    global.online_deck_count = 50;
    global.online_descarte_privado = [];
    global.online_mao_pendente = false;
}

function online_ativo() {
    return variable_global_exists("net_connected") && global.net_connected
        && variable_global_exists("net_room") && global.net_room != 0;
}

function online_lado_do_assento(_assento) {
    return (_assento == 0) ? "jogador" : "inimigo";
}

function online_lado_local() {
    return online_lado_do_assento(global.online_assento);
}

function online_configurar_callbacks(_sala) {
    colyseus_on_error(_sala, function(_codigo, _mensagem) {
        global.online_status = "erro";
        global.online_erro = "Não foi possível conectar: " + string(_mensagem);
        global.net_connected = false;
    });

    colyseus_on_drop(_sala, function(_codigo, _motivo) {
        global.online_status = "reconectando";
        global.online_erro = "Conexão perdida. Tentando voltar...";
    });

    colyseus_on_reconnect(_sala, function() {
        global.net_connected = true;
        global.online_status = "na_sala";
        global.online_erro = "";
        colyseus_send(_sala, "request_private_state", {});
    });

    colyseus_on_leave(_sala, function(_codigo, _motivo) {
        global.net_connected = false;
        global.online_status = "desconectado";
        if (_codigo != 1000) global.online_erro = "Você saiu da sala: " + string(_motivo);
    });

    colyseus_on_join(_sala, function(_ref) {
        global.net_connected = true;
        global.net_room_id = colyseus_room_get_id(_ref);
        global.net_session_id = colyseus_room_get_session_id(_ref);
        global.online_status = "na_sala";
        global.online_erro = "";
        colyseus_send(_ref, "ready", json_stringify({ name: global.online_nome, deck: online_montar_deck_ids() }));
    });

    colyseus_on_message(_sala, function(_ref, _tipo, _dados) {
        // Mensagens estruturadas chegam como JSON para preservar arrays e structs aninhados.
        if (is_string(_dados)) _dados = json_parse(_dados);
        switch (_tipo) {
            case "seat":
                global.online_assento = _dados.seat;
                global.net_room_id = _dados.roomId;
                global.online_seed = _dados.seed;
                break;
            case "initiative_result":
                global.online_iniciativa[_dados.seat] = _dados.value;
                break;
            case "initiative_tie":
                global.online_iniciativa = [-1, -1];
                global.online_vencedor_iniciativa = -1;
                global.online_fase = "initiative";
                break;
            case "veil_options":
                if (instance_exists(obj_controlador)) {
                    var _origem_veu_online = online_encontrar_carta_campo(_dados.cardId);
                    if (instance_exists(_origem_veu_online)) {
                        obj_controlador.visao_veu_opcoes = [];
                        for (var _vo = 0; _vo < array_length(_dados.cards); _vo++) {
                            var _vc = _dados.cards[_vo];
                            array_push(obj_controlador.visao_veu_opcoes, {
                                nome: _vc.name,
                                armadilha: _vc.category == "armadilha",
                                online_instance_id: _vc.instanceId
                            });
                        }
                        obj_controlador.visao_veu_origem = _origem_veu_online;
                        obj_controlador.visao_veu_revelacao_timer = 0;
                        obj_controlador.visao_veu_ativa = true;
                        obj_controlador.carta_menu_aberto = noone;
                    }
                }
                break;
            case "magnet_choice":
                if (instance_exists(obj_controlador)) {
                    var _itens_ima_online = [];
                    for (var _im = 0; _im < array_length(_dados.items); _im++) {
                        var _registro_ima = _dados.items[_im];
                        var _funcao_ima = online_funcao_carta_por_id(_registro_ima.definitionId);
                        if (_funcao_ima == noone) continue;
                        var _dados_ima = _funcao_ima();
                        var _item_ima = criar_dados_item_equipado(
                            _dados_ima.nome,
                            variable_struct_exists(_dados_ima, "sprite_carta") ? _dados_ima.sprite_carta : noone,
                            _funcao_ima,
                            variable_struct_exists(_dados_ima, "bonus_mod_dano") ? _dados_ima.bonus_mod_dano : 0,
                            variable_struct_exists(_dados_ima, "bonus_defesa") ? _dados_ima.bonus_defesa : 0,
                            variable_struct_exists(_dados_ima, "sobrescreve_dado_dano") ? _dados_ima.sobrescreve_dado_dano : 0,
                            variable_struct_exists(_dados_ima, "sobrescreve_mod_dano") ? _dados_ima.sobrescreve_mod_dano : 0,
                            variable_struct_exists(_dados_ima, "efeito_item") ? _dados_ima.efeito_item : ""
                        );
                        _item_ima.online_definition_id = _registro_ima.definitionId;
                        _item_ima.online_index = _registro_ima.index;
                        array_push(_itens_ima_online, _item_ima);
                    }
                    array_push(obj_controlador.maquina_ima_pendencias, { itens: _itens_ima_online,
                        x: room_width / 2, y: room_height / 2, dono: online_lado_local(), online: true });
                }
                break;
            case "mitosis_choice":
                if (instance_exists(obj_controlador)) {
                    obj_controlador.mitose_slots_pendentes = [];
                    for (var _mc = 0; _mc < array_length(_dados.candidates); _mc++) {
                        var _slot_mc = buscar_slot(_dados.candidates[_mc].lane, _dados.candidates[_mc].position);
                        if (_slot_mc != noone) array_push(obj_controlador.mitose_slots_pendentes, _slot_mc);
                    }
                    obj_controlador.mitose_dados_pendentes = criar_dados_slimet();
                    obj_controlador.mitose_dono_pendente = online_lado_local();
                    obj_controlador.mitose_selecao_ativa = array_length(obj_controlador.mitose_slots_pendentes) > 0;
                }
                break;

            case "private_state":
                global.online_mao_privada = variable_struct_exists(_dados, "hand") && is_array(_dados.hand) ? _dados.hand : [];
                global.online_armadilhas_privadas = variable_struct_exists(_dados, "activeTraps") && is_array(_dados.activeTraps) ? _dados.activeTraps : [];
                global.online_efeitos_privados = variable_struct_exists(_dados, "activeEffects") && is_array(_dados.activeEffects) ? _dados.activeEffects : [];
                global.online_mao_pendente = true;
                global.online_deck_count = _dados.deckCount;
                global.online_descarte_privado = variable_struct_exists(_dados, "discard") && is_array(_dados.discard) ? _dados.discard : [];
                global.online_revisao = _dados.revision;
                if (instance_exists(obj_controlador)) online_reconstruir_mao_privada();
                break;
            case "public_state":
                global.online_estado_publico = _dados;
                global.online_revisao = _dados.revision;
                if (instance_exists(obj_controlador)) {
                    if (global.online_mao_pendente) online_reconstruir_mao_privada();
                    online_aplicar_estado_publico(_dados);
                }
                break;
            case "match_started":
                global.online_primeiro = _dados.currentPlayer;
                global.online_seed = _dados.seed;
                global.modo_partida = "online";
                random_set_seed(global.online_seed);
                room_goto(rm_jogo);
                break;
            case "action_confirmed":
                global.online_revisao = _dados.revision;
                online_animar_confirmacao(_dados);
                break;
            case "action_rejected":
                global.online_revisao = _dados.revision;
                global.online_erro = online_mensagem_erro(_dados.reason);
                if (instance_exists(obj_controlador)) mostrar_aviso_regra(global.online_erro);
                if (_dados.reason == "revisao" && online_ativo()) colyseus_send(_ref, "request_private_state", {});
                break;
        }
    });

    colyseus_on_state_change(_sala, function(_ref) {
        var _estado = colyseus_room_get_state(_ref);
        if (is_struct(_estado)) {
            global.online_fase = colyseus_schema_get(_estado, "phase");
            global.online_vencedor_iniciativa = colyseus_schema_get(_estado, "initiativeWinner");
            global.online_primeiro = colyseus_schema_get(_estado, "currentPlayer");
            global.online_revisao = colyseus_schema_get(_estado, "revision");
        }
    });
}

function online_conectar(_criar, _codigo, _nome, _endpoint = "wss://doily-pointy-nurture.ngrok-free.dev") {
    online_inicializar();
    if (!colyseus_is_ready()) {
        global.online_status = "erro";
        global.online_erro = "O módulo online ainda está carregando.";
        return false;
    }
    if (global.net_room != 0) online_desconectar();
    global.online_nome = (string_length(string_trim(_nome)) > 0) ? string_trim(_nome) : "Jogador";
    global.online_status = "conectando";
    global.online_estado_publico = noone;
    global.online_mao_privada = [];
    global.online_armadilhas_privadas = [];
    global.online_efeitos_privados = [];
    global.online_erro = "";
    global.net_client = colyseus_client_create(_endpoint);
    global.net_room = _criar
        ? colyseus_client_create_room(global.net_client, "kartha", { name: global.online_nome })
        : colyseus_client_join_by_id(global.net_client, string_trim(_codigo), { name: global.online_nome });
    online_configurar_callbacks(global.net_room);
    return true;
}

function online_rolar_iniciativa() {
    if (online_ativo() && global.online_fase == "initiative"
        && global.online_assento >= 0 && global.online_iniciativa[global.online_assento] < 0) {
        colyseus_send(global.net_room, "roll_initiative", {});
    }
}

function online_escolher_primeiro(_assento) {
    if (online_ativo() && global.online_fase == "choose_first"
        && global.online_vencedor_iniciativa == global.online_assento) {
        colyseus_send(global.net_room, "choose_first", { seat: _assento });
    }
}

function online_enviar_acao(_tipo, _dados = {}) {
    if (!online_ativo()) return false;
    colyseus_send(global.net_room, "action", json_stringify({
        kind: _tipo, payload: _dados, revision: global.online_revisao
    }));
    return true;
}

function online_desconectar() {
    if (variable_global_exists("net_room") && global.net_room != 0) {
        colyseus_room_leave(global.net_room);
        colyseus_room_free(global.net_room);
    }
    if (variable_global_exists("net_client") && global.net_client != 0) colyseus_client_free(global.net_client);
    global.net_room = 0;
    global.net_client = 0;
    global.net_connected = false;
    global.online_status = "desconectado";
}

function online_catalogo_ids() {
    return [
        "esquilo","lobo","urso","slime","slimet","mimic","olho_demonio","mago_sombra","gato_mago","goblin",
        "hollow_jack","esqueleto","shroomilin","sangue","ossos","sucata","mana","torre_vigia","hemodrenario","maquina_ima",
        "bola_fogo","veneno_mortal","congelante","choque_eletrico","dados_manipulados","refracao_temporal","eutanasia",
        "bloqueio_recurso","sangue_suga","espada_enferrujada","escudo_madeira","pocao_cura","grimorio_iniciante","pocao_mana",
        "armadilha_urso","loucura_mutua","raizes_espinhosas","destrocos","bencao_vida","maldicao_perda","bencao_decomposicao",
        "sangue_por_sangue","bau","frasco_sangue","vitamina_cerebro","elmo_ferro","frasco_acido","pantano_sombrio",
        "cemiterio","planicies_profanas","espada_quebrada"
    ];
}

function online_montar_deck_ids() {
    var _ids = online_catalogo_ids();
    var _deck = [];
    if (variable_global_exists("deck_contagens") && is_array(global.deck_contagens)
        && array_length(global.deck_contagens) == array_length(_ids)) {
        for (var i = 0; i < array_length(_ids); i++)
            for (var c = 0; c < global.deck_contagens[i]; c++) array_push(_deck, _ids[i]);
    }
    if (array_length(_deck) != 50) {
        _deck = [];
        for (var j = 0; j < 50; j++) array_push(_deck, _ids[j mod array_length(_ids)]);
    }
    return _deck;
}

function online_funcao_carta_por_id(_definition_id) {
    var _indice = array_get_index(online_catalogo_ids(), _definition_id);
    var _catalogo = catalogo_cartas();
    return (_indice >= 0 && _indice < array_length(_catalogo)) ? _catalogo[_indice] : noone;
}

function online_tentar_jogar_carta_especial(_carta) {
    if (!instance_exists(_carta) || obj_controlador.modo_partida != "online") return false;
    var _categoria = _carta.categoria;
    if (_categoria != "magica" && _categoria != "item_equipavel" && _categoria != "item_consumivel"
        && _categoria != "armadilha" && _categoria != "terreno"
        && _categoria != "bencao" && _categoria != "maldicao") return false;

    var _payload = { cardId: _carta.online_instance_id };
    var _tipo_acao = "";
    var _valido = true;
    var _distancia_arrastada = point_distance(_carta.x, _carta.y, _carta.arrastar_inicio_x, _carta.arrastar_inicio_y);

    if (_categoria == "magica") {
        _tipo_acao = "play_spell";
        if (_carta.efeito_tipo == "bloqueio_recurso") {
            var _recurso_alvo = noone;
            var _menor = 65;
            for (var i = 0; i < instance_number(obj_recurso); i++) {
                var _recurso = instance_find(obj_recurso, i);
                var _dist = point_distance(_carta.x, _carta.y, _recurso.x, _recurso.y);
                if (_dist < _menor) { _menor = _dist; _recurso_alvo = _recurso; }
            }
            if (instance_exists(_recurso_alvo)) {
                _payload.resourceType = _recurso_alvo.tipo;
                _payload.targetSeat = (_recurso_alvo.dono == "jogador") ? 0 : 1;
            } else _valido = false;
        } else if (_carta.efeito_tipo == "dados_manipulados"
            || _carta.efeito_tipo == "refracao_temporal"
            || _carta.efeito_tipo == "buscar_sangue") {
            _valido = _distancia_arrastada > 80;
        } else {
            var _alvo = noone;
            var _tipo_alvo = "tropa";
            var _menor = 65;
            for (var i = 0; i < instance_number(obj_carta); i++) {
                var _teste = instance_find(obj_carta, i);
                if (!_teste.travada || _teste.online_instance_id == "") continue;
                var _aceita = (_carta.efeito_tipo == "eutanasia")
                    ? (_teste.vida <= 5) : (_teste.dono != _carta.dono);
                var _dist = point_distance(_carta.x, _carta.y, _teste.x, _teste.y);
                if (_aceita && _dist < _menor) { _menor = _dist; _alvo = _teste; _tipo_alvo = "tropa"; }
            }
            if (_carta.efeito_tipo == "bola_fogo") {
                for (var i = 0; i < instance_number(obj_construcao); i++) {
                    var _teste_construcao = instance_find(obj_construcao, i);
                    if (_teste_construcao.dono == _carta.dono) continue;
                    var _dist = point_distance(_carta.x, _carta.y, _teste_construcao.x, _teste_construcao.y);
                    if (_dist < _menor) { _menor = _dist; _alvo = _teste_construcao; _tipo_alvo = "construcao"; }
                }
                var _pos_castelo = obter_posicao_castelo(lado_oposto(_carta.dono));
                var _dist_castelo = point_distance(_carta.x, _carta.y, _pos_castelo.x, _pos_castelo.y);
                if (_dist_castelo < 95 && _dist_castelo < _menor) {
                    _alvo = noone; _tipo_alvo = "castle"; _menor = _dist_castelo;
                }
            }
            if (instance_exists(_alvo)) {
                _payload.targetId = _alvo.online_instance_id;
                _payload.targetType = _tipo_alvo;
            } else if (_tipo_alvo == "castle" && _menor < 95) {
                _payload.targetType = "castle";
            } else _valido = false;
        }
    } else if (_categoria == "item_equipavel" || _categoria == "item_consumivel") {
        _tipo_acao = "play_item";
        var _precisa_alvo = (_categoria == "item_equipavel"
            || _carta.efeito_tipo == "aplicar_corrosao"
            || _carta.efeito_tipo == "aumentar_intelig"
            || _carta.cura_item > 0);
        if (_precisa_alvo) {
            var _alvo = noone;
            var _menor = 65;
            for (var i = 0; i < instance_number(obj_carta); i++) {
                var _teste = instance_find(obj_carta, i);
                if (!_teste.travada || _teste.online_instance_id == "") continue;
                if (_carta.efeito_tipo != "aplicar_corrosao" && _teste.dono != _carta.dono) continue;
                var _dist = point_distance(_carta.x, _carta.y, _teste.x, _teste.y);
                if (_dist < _menor) { _menor = _dist; _alvo = _teste; }
            }
            if (instance_exists(_alvo)) _payload.targetId = _alvo.online_instance_id;
            else _valido = false;
        } else _valido = _distancia_arrastada > 80;
    } else if (_categoria == "armadilha") {
        _tipo_acao = "play_trap";
        var _slot = noone;
        var _menor = global.CARTA_LARGURA * 0.7;
        for (var i = 0; i < instance_number(obj_slot_batalha); i++) {
            var _teste_slot = instance_find(obj_slot_batalha, i);
            if (_carta.dono == "jogador" && _teste_slot.posicao < posicao_ataque()) continue;
            if (_carta.dono == "inimigo" && _teste_slot.posicao > posicao_ataque()) continue;
            var _dist = point_distance(_carta.x, _carta.y, _teste_slot.x, _teste_slot.y);
            if (_dist < _menor) { _menor = _dist; _slot = _teste_slot; }
        }
        if (instance_exists(_slot)) { _payload.lane = _slot.lane; _payload.position = _slot.posicao; }
        else _valido = false;
    } else {
        _tipo_acao = "play_effect";
        _valido = _distancia_arrastada > 80;
    }

    if (_valido && _carta.online_instance_id != "") {
        online_enviar_acao(_tipo_acao, _payload);
    } else {
        mostrar_aviso_regra("Solte a carta sobre um alvo válido", _carta.x, _carta.y);
    }
    iniciar_retorno_carta(_carta);
    _carta.esta_na_mao = true;
    return true;
}

function online_mensagem_erro(_motivo) {
    switch (_motivo) {
        case "fora_do_turno": return "Aguarde o seu turno";
        case "revisao": return "A partida mudou; tente novamente";
        case "recursos_insuficientes": return "Recursos insuficientes";
        case "coluna_ocupada": return "Coluna ocupada: máximo de 1 tropa";
        case "base_ocupada": return "A casa da base está ocupada";
        case "casa_ocupada": return "A casa de destino está ocupada";
        case "construcao_ocupada": return "Já existe uma construção nessa coluna";
        case "limite_tropas_turno": return "Limite de tropas deste turno";
        case "limite_construcoes_turno": return "Limite de construções deste turno";
        case "recurso_ja_colocado": return "Você já colocou 1 recurso neste turno";
        case "limite_recursos": return "Área de recursos cheia";
        case "movimento_fora_tabuleiro": return "Movimento inválido";
        case "alvo_invalido": return "Não há alvo válido";
        case "tropa_ja_moveu": return "Essa tropa já se moveu neste turno";
        case "tropa_ja_atacou": return "Essa tropa já atacou neste turno";
        case "avance_para_assalto": return "Avance até a posição de assalto primeiro";
        case "ataque_indisponivel": return "Essa tropa não possui esse tipo de ataque";
        case "limite_magias_turno": return "Limite de 2 magias por turno";
        case "primeiro_turno_bloqueado": return "Esta categoria ainda não pode ser usada no primeiro turno";
        case "limite_itens_turno": return "Limite de 3 itens por turno";
        case "limite_terreno_turno": return "Limite de 1 terreno por turno";
        case "mochila_cheia": return "A tropa não possui espaço para outro item";
        case "inteligencia_insuficiente": return "A tropa não tem inteligência suficiente";
        case "eutanasia_vida": return "Eutanásia exige uma tropa com até 5 de vida";
        case "recurso_nao_encontrado": return "Esse recurso não está mais no baralho";
        case "recurso_nao_gasto": return "Não há recurso gasto para revirar";
        case "armadilha_ocupada": return "Este espaço já possui uma armadilha";
        case "armadilha_nao_pronta": return "A armadilha ainda não foi ativada pelo gatilho";
        case "tropa_incapacitada": return "A condição da tropa impede esta ação";
        case "refracao_sem_carta": return "Jogue outra carta antes da Refração Temporal";
        case "habilidade_indisponivel": return "Esta tropa nao possui uma habilidade ativa";
        case "habilidade_ja_usada": return "A habilidade ja foi usada neste turno";
        case "habilidade_sem_alvo": return "A habilidade precisa de um inimigo a frente";
        case "sombra_recarregando": return "Sombra Translucida ainda esta recarregando";
        case "digestao_sem_usos": return "Digestao nao possui mais usos";
        case "digestao_alvo_invalido": return "Escolha uma tropa adjacente com menos de 4 de vida";
        case "carnica_preparada": return "Carnica Frenetica ja esta preparada";
        case "visao_ja_usada": return "Visao do Veu ja foi usada";
        case "hemodrenario_sem_sangue": return "Nao ha Sangue inimigo livre para drenar";
        case "hemodrenario_sem_recurso_gasto": return "Nao ha recurso proprio gasto para recuperar";
        case "arma_invalida": return "Essa arma nao esta equipada ou nao pode atacar";
        case "acao_item_ja_usada": return "Esta tropa ja mexeu em um item neste turno";
        case "tropa_sem_item": return "A tropa nao possui equipamento";
        case "transferencia_invalida": return "Escolha outra tropa aliada";
        case "grimorio_nao_equipado": return "O Grimorio nao esta equipado";
        case "grimorio_ja_usado": return "O Grimorio ja foi usado neste turno";
        case "habilidade_item_invalida": return "Opcao do equipamento invalida";
        case "defesa_fora_da_base": return "A tropa precisa estar na base para defender o castelo";
        case "evolucao_indisponivel": return "Essa tropa não possui evolução";
        case "evolucao_muito_cedo": return "A tropa precisa sobreviver 1 turno";
        case "limite_evolucoes_turno": return "Limite de 1 evolução por turno";
        case "escolha_critico_pendente": return "Escolha como resolver o acerto crítico";
        case "escolha_pendente": return "Conclua a escolha que está aberta";
        case "escolha_ima_invalida": return "Escolha um equipamento da Máquina Imã";
        case "escolha_mitose_invalida": return "Escolha uma casa adjacente destacada";
    }
    return "A ação não foi aceita pelo servidor";
}


function online_mao_privada_contem(_instance_id) {
    for (var i = 0; i < array_length(global.online_mao_privada); i++) {
        if (global.online_mao_privada[i].instanceId == _instance_id) return true;
    }
    for (var t = 0; t < array_length(global.online_armadilhas_privadas); t++) {
        if (global.online_armadilhas_privadas[t].instanceId == _instance_id) return true;
    }
    return false;
}

function online_encontrar_carta_mao(_instance_id) {
    for (var i = 0; i < instance_number(obj_carta); i++) {
        var _carta = instance_find(obj_carta, i);
        if (_carta.esta_na_mao && _carta.online_instance_id == _instance_id) return _carta;
    }
    return noone;
}

function online_reconstruir_mao_privada() {
    if (!instance_exists(obj_controlador) || obj_controlador.modo_partida != "online") return;

    // Mantém as instâncias e a ordem organizada manualmente pelo jogador.
    var _nova_mao = [];
    for (var i = 0; i < array_length(obj_controlador.mao); i++) {
        var _existente = obj_controlador.mao[i];
        if (instance_exists(_existente)
            && _existente.esta_na_mao
            && _existente.online_instance_id != ""
            && online_mao_privada_contem(_existente.online_instance_id)) {
            array_push(_nova_mao, _existente);
        }
    }

    // Remove apenas cartas que realmente deixaram a mão (ou sobras locais sem ID).
    with (obj_carta) {
        if (esta_na_mao && (online_instance_id == "" || !online_mao_privada_contem(online_instance_id))) {
            instance_destroy();
        }
    }

    var _mao_online = is_array(global.online_mao_privada) ? global.online_mao_privada : [];
    var _armadilhas_online = is_array(global.online_armadilhas_privadas) ? global.online_armadilhas_privadas : [];
    var _registros_visiveis = array_concat(_mao_online, _armadilhas_online);
    var _turno_anterior = obj_controlador.turno;
    var _lado = online_lado_local();
    obj_controlador.turno = _lado;
    for (var r = 0; r < array_length(_registros_visiveis); r++) {
        var _registro = _registros_visiveis[r];
        var _carta = online_encontrar_carta_mao(_registro.instanceId);
        if (!instance_exists(_carta)) {
            var _funcao = online_funcao_carta_por_id(_registro.definitionId);
            if (_funcao == noone) continue;
            var _comprada = obj_controlador.mao_inicial_comprada;
            obj_controlador.mao_inicial_comprada = false;
            _carta = comprar_carta_do_deck_por_funcao(_funcao, obj_deck.x, obj_deck.y, _lado);
            obj_controlador.mao_inicial_comprada = _comprada;
            if (!instance_exists(_carta)) continue;
            _carta.online_instance_id = _registro.instanceId;
            _carta.dono = _lado;
            _carta.compra_atraso = r * 4;
            var _indice = array_get_index(obj_controlador.mao, _carta);
            if (_indice >= 0) array_delete(obj_controlador.mao, _indice, 1);
            _indice = array_get_index(obj_controlador.mao_oculta, _carta);
            if (_indice >= 0) array_delete(obj_controlador.mao_oculta, _indice, 1);
        }
        if (variable_struct_exists(_registro, "lane")) {
            _carta.armadilha_lane = _registro.lane;
            _carta.armadilha_posicao = _registro.position;
            _carta.armadilha_estado = _registro.ready ? "pronta" : "vigiando";
        }
        if (array_get_index(_nova_mao, _carta) < 0) array_push(_nova_mao, _carta);
    }
    obj_controlador.turno = _turno_anterior;
    obj_controlador.mao = _nova_mao;
    obj_controlador.mao_oculta = [];
    obj_controlador.mao_inicial_comprada = true;
    global.online_mao_pendente = false;
    organizar_mao();
}

function online_sprite_recurso(_tipo) {
    switch (_tipo) {
        case "sangue": return spr_recurso_sangue;
        case "ossos": return spr_recurso_ossos;
        case "sucata": return spr_recurso_sucata;
        case "mana": return spr_recurso_mana;
    }
    return spr_recurso_mana;
}

function online_criar_recurso_confirmado(_tipo, _dono, _virado) {
    var _slot = noone;
    for (var i = 0; i < instance_number(obj_slot_recurso); i++) {
        var _teste = instance_find(obj_slot_recurso, i);
        if (_teste.dono == _dono && !_teste.ocupado) { _slot = _teste; break; }
    }
    if (_slot == noone) return;
    var _recurso = instance_create_layer(_slot.x, _slot.y, "Instances", obj_recurso);
    _recurso.tipo = _tipo;
    _recurso.dono = _dono;
    _recurso.virado = _virado;
    _recurso.sprite_index = online_sprite_recurso(_tipo);
    _recurso.escala_recurso = global.RECURSO_LARGURA / sprite_get_width(_recurso.sprite_index);
    _recurso.slot_atual = _slot;
    _recurso.destino_x = _slot.x;
    _recurso.destino_y = _slot.y;
    _slot.ocupado = true;
    _slot.recurso_atual = _recurso;
    if (_dono == "jogador") array_push(obj_controlador.recursos_jogador, _recurso);
    else array_push(obj_controlador.recursos_inimigo, _recurso);
}

function online_assinatura_recursos(_jogadores) {
    var _assinatura = "";
    var _tipos = ["mana", "sangue", "ossos", "sucata"];
    for (var p = 0; p < array_length(_jogadores); p++) {
        var _dados = _jogadores[p];
        _assinatura += string(_dados.seat) + ":";
        for (var t = 0; t < array_length(_tipos); t++) {
            var _tipo = _tipos[t];
            _assinatura += _tipo + "=" + string(variable_struct_get(_dados, _tipo))
                + "/" + string(variable_struct_get(_dados, _tipo + "Used")) + ";";
        }
    }
    return _assinatura;
}

function online_reconstruir_recursos(_jogadores) {
    var _assinatura = online_assinatura_recursos(_jogadores);
    if (obj_controlador.online_recursos_assinatura == _assinatura) return;
    obj_controlador.online_recursos_assinatura = _assinatura;

    with (obj_recurso) instance_destroy();
    with (obj_slot_recurso) { ocupado = false; recurso_atual = noone; }
    obj_controlador.recursos_jogador = [];
    obj_controlador.recursos_inimigo = [];
    var _tipos = ["mana", "sangue", "ossos", "sucata"];
    for (var p = 0; p < array_length(_jogadores); p++) {
        var _dados = _jogadores[p];
        var _dono = online_lado_do_assento(_dados.seat);
        for (var t = 0; t < array_length(_tipos); t++) {
            var _tipo = _tipos[t];
            var _total = variable_struct_get(_dados, _tipo);
            var _gastos = variable_struct_get(_dados, _tipo + "Used");
            for (var n = 0; n < _total; n++) online_criar_recurso_confirmado(_tipo, _dono, n < _gastos);
        }
    }
}

function online_encontrar_construcao_campo(_instance_id) {
    for (var i = 0; i < instance_number(obj_construcao); i++) {
        var _construcao = instance_find(obj_construcao, i);
        if (variable_instance_exists(_construcao, "online_instance_id")
            && _construcao.online_instance_id == _instance_id) return _construcao;
    }
    return noone;
}

function online_slot_construcao(_dono, _lane) {
    for (var i = 0; i < instance_number(obj_slot_construcao); i++) {
        var _slot = instance_find(obj_slot_construcao, i);
        if (_slot.dono == _dono && _slot.lane == _lane) return _slot;
    }
    return noone;
}

function online_criar_carta_publica(_registro) {
    var _funcao = online_funcao_carta_por_id(_registro.definitionId);
    if (_funcao == noone) return noone;
    var _dados = _funcao();
    var _dono = online_lado_do_assento(_registro.owner);

    if (_registro.category == "tropa") {
        var _slot = buscar_slot(_registro.lane, _registro.position);
        if (_slot == noone) return noone;
        var _comprada = obj_controlador.mao_inicial_comprada;
        obj_controlador.mao_inicial_comprada = false;
        var _carta = comprar_carta_do_deck_por_funcao(_funcao, _slot.x, _slot.y, _dono);
        obj_controlador.mao_inicial_comprada = _comprada;
        var _indice = array_get_index(obj_controlador.mao, _carta);
        if (_indice >= 0) array_delete(obj_controlador.mao, _indice, 1);
        _indice = array_get_index(obj_controlador.mao_oculta, _carta);
        if (_indice >= 0) array_delete(obj_controlador.mao_oculta, _indice, 1);
        _carta.online_instance_id = _registro.instanceId;
        _carta.online_presente = true;
        _carta.esta_na_mao = false;
        _carta.compra_animando = false;
        _carta.travada = true;
        _carta.dono = _dono;
        _carta.lane_atual = _registro.lane;
        _carta.posicao_atual = _registro.position;
        _carta.vida = _registro.life;
        _carta.vida_maxima = _registro.maxLife;
        _carta.moveu_este_turno = _registro.moved;
        _carta.turnos_no_campo = _registro.moved ? 0 : 1;
        _carta.atacou_este_turno = _registro.attacked;
        _carta.defendendo_castelo = variable_struct_exists(_registro, "defendingCastle") && _registro.defendingCastle;
        _carta.condicao = (_registro.condition == "") ? noone : _registro.condition;
        _carta.slot_atual = _slot;
        _carta.x = _slot.x; _carta.y = _slot.y;
        _slot.ocupado = true; _slot.carta_atual = _carta;
        return _carta;
    }

    if (_registro.category == "construcao") {
        var _slot_construcao = online_slot_construcao(_dono, _registro.lane);
        if (_slot_construcao == noone) return noone;
        var _construcao = instance_create_layer(_slot_construcao.x, _slot_construcao.y, "Instances", obj_construcao);
        _construcao.online_instance_id = _registro.instanceId;
        _construcao.online_presente = true;
        _construcao.nome_construcao = _dados.nome;
        _construcao.nome_carta = _dados.nome;
        _construcao.custo = _dados.custo;
        _construcao.dono = _dono;
        _construcao.lane_atual = _registro.lane;
        _construcao.vida = _registro.life;
        _construcao.vida_maxima = _registro.maxLife;
        _construcao.slot_atual = _slot_construcao;
        _construcao.efeito_construcao = variable_struct_exists(_dados, "efeito_construcao") ? _dados.efeito_construcao : "";
        _construcao.dado_efeito = variable_struct_exists(_dados, "dado_efeito") ? _dados.dado_efeito : 0;
        _construcao.tem_habilidade_construcao = (_construcao.efeito_construcao != "");
        if (_dados.sprite_carta != noone) {
            _construcao.sprite_index = _dados.sprite_carta;
            _construcao.usa_sprite_carta = true;
            _construcao.tem_arte_propria = true;
            _construcao.escala_visual_base = min((global.CARTA_LARGURA * 0.60) / sprite_get_width(_dados.sprite_carta), (global.CARTA_ALTURA * 0.60) / sprite_get_height(_dados.sprite_carta));
            _construcao.image_xscale = _construcao.escala_visual_base;
            _construcao.image_yscale = _construcao.escala_visual_base;
            _construcao.vida_pos_x = clamp((variable_struct_exists(_dados, "vida_pos_x") ? _dados.vida_pos_x : 0.11) + 0.05, 0, 1);
            _construcao.vida_pos_y = clamp((variable_struct_exists(_dados, "vida_pos_y") ? _dados.vida_pos_y : 0.07) + 0.05, 0, 1);
        }
        _slot_construcao.ocupado = true;
        _slot_construcao.construcao_atual = _construcao;
        return _construcao;
    }
    return noone;
}

function online_sincronizar_equipamentos(_carta, _ids) {
    if (!is_array(_ids)) _ids = [];
    var _assinatura = "";
    for (var i = 0; i < array_length(_ids); i++) _assinatura += string(_ids[i]) + ";";
    if (variable_instance_exists(_carta, "online_equipamentos_assinatura")
        && _carta.online_equipamentos_assinatura == _assinatura) return;
    _carta.online_equipamentos_assinatura = _assinatura;
    _carta.itens_equipados = [];
    for (var i = 0; i < array_length(_ids); i++) {
        var _funcao = online_funcao_carta_por_id(_ids[i]);
        if (_funcao == noone) continue;
        var _dados = _funcao();
        var _item_online = criar_dados_item_equipado(
            _dados.nome,
            variable_struct_exists(_dados, "sprite_carta") ? _dados.sprite_carta : noone,
            _funcao,
            variable_struct_exists(_dados, "bonus_mod_dano") ? _dados.bonus_mod_dano : 0,
            variable_struct_exists(_dados, "bonus_defesa") ? _dados.bonus_defesa : 0,
            variable_struct_exists(_dados, "sobrescreve_dado_dano") ? _dados.sobrescreve_dado_dano : 0,
            variable_struct_exists(_dados, "sobrescreve_mod_dano") ? _dados.sobrescreve_mod_dano : 0,
            variable_struct_exists(_dados, "efeito_item") ? _dados.efeito_item : ""
        );
        _item_online.online_definition_id = _ids[i];
        array_push(_carta.itens_equipados, _item_online);
    }
    recalcular_itens_tropa(_carta);
}

function online_sincronizar_efeitos_ativos(_jogadores, _terreno_id) {
    with (obj_recurso) bloqueado_turnos = 0;
    obj_controlador.bencaos_jogador = [];
    obj_controlador.bencaos_inimigo = [];
    obj_controlador.maldicoes_jogador = [];
    obj_controlador.maldicoes_inimigo = [];
    for (var p = 0; p < array_length(_jogadores); p++) {
        var _dados = _jogadores[p];
        var _dono = online_lado_do_assento(_dados.seat);
        var _efeitos = variable_struct_exists(_dados, "activeEffects") ? _dados.activeEffects : [];
        for (var e = 0; e < array_length(_efeitos); e++) {
            var _efeito = _efeitos[e];
            if (_efeito == "cura_ao_morrer") adicionar_bencao(_dono, _efeito, "Bênção ativa", noone);
            else if (_efeito == "perde_vida_ao_morrer") adicionar_maldicao(_dono, _efeito, "Maldição ativa", noone);
        }
        if (variable_struct_exists(_dados, "blockedResource") && _dados.blockedResource != "") {
            with (obj_recurso) {
                if (dono == _dono && tipo == _dados.blockedResource) bloqueado_turnos = _dados.blockedTurns;
            }
        }
    }
    obj_controlador.terreno_ativo = "";
    if (_terreno_id != "") {
        var _funcao_terreno = online_funcao_carta_por_id(_terreno_id);
        if (_funcao_terreno != noone) {
            var _dados_terreno = _funcao_terreno();
            obj_controlador.terreno_ativo = variable_struct_exists(_dados_terreno, "efeito_terreno")
                ? _dados_terreno.efeito_terreno : "";
        }
    }
}

function online_atualizar_carta_publica(_registro) {
    var _instancia = (_registro.category == "construcao")
        ? online_encontrar_construcao_campo(_registro.instanceId)
        : online_encontrar_carta_campo(_registro.instanceId);
    if (!instance_exists(_instancia)) return online_criar_carta_publica(_registro);

    if (_registro.category == "tropa" && _instancia.nome_carta != _registro.name) {
        var _slot_antigo_evo = _instancia.slot_atual;
        if (_slot_antigo_evo != noone) {
            _slot_antigo_evo.ocupado = false;
            _slot_antigo_evo.carta_atual = noone;
        }
        instance_destroy(_instancia);
        var _nova_evo = online_criar_carta_publica(_registro);
        if (instance_exists(_nova_evo)) {
            _nova_evo.evoluindo = true;
            _nova_evo.evolucao_progresso = 0;
            mostrar_feedback("EVOLUIU!", _nova_evo.x, _nova_evo.y - 45, c_lime, 55);
        }
        return _nova_evo;
    }

    _instancia.online_presente = true;
    _instancia.vida = _registro.life;
    _instancia.vida_maxima = _registro.maxLife;
    _instancia.dono = online_lado_do_assento(_registro.owner);
    _instancia.lane_atual = _registro.lane;

    if (_registro.category == "tropa") {
        var _slot = buscar_slot(_registro.lane, _registro.position);
        if (_slot != noone && _instancia.slot_atual != _slot) {
            if (_instancia.slot_atual != noone) {
                _instancia.slot_atual.ocupado = false;
                _instancia.slot_atual.carta_atual = noone;
            }
            _instancia.slot_atual = _slot;
            _slot.ocupado = true;
            _slot.carta_atual = _instancia;
            iniciar_pulo_tropa(_instancia, _slot.x, _slot.y);
        }
        _instancia.posicao_atual = _registro.position;
        _instancia.moveu_este_turno = _registro.moved;
        if (!_registro.moved) _instancia.turnos_no_campo = max(1, _instancia.turnos_no_campo);
        _instancia.atacou_este_turno = _registro.attacked;
        _instancia.defendendo_castelo = variable_struct_exists(_registro, "defendingCastle") && _registro.defendingCastle;
        if (variable_struct_exists(_registro, "turnsInPlay")) _instancia.turnos_no_campo = _registro.turnsInPlay;
        if (variable_struct_exists(_registro, "abilityState") && is_struct(_registro.abilityState)) {
            var _habilidade_estado = _registro.abilityState;
            _instancia.habilidade_usada_este_turno = variable_struct_exists(_habilidade_estado, "used") && _habilidade_estado.used;
            _instancia.sombra_ativa = variable_struct_exists(_habilidade_estado, "shadowTurns") && _habilidade_estado.shadowTurns > 0;
            _instancia.sombra_cooldown = variable_struct_exists(_habilidade_estado, "shadowCooldown") ? _habilidade_estado.shadowCooldown : 0;
            _instancia.iludido_por_imitacao = variable_struct_exists(_habilidade_estado, "illusion") && _habilidade_estado.illusion;
            _instancia.testado_olhar_vazio = variable_struct_exists(_habilidade_estado, "gazeTested") && _habilidade_estado.gazeTested;
            _instancia.visao_do_veu_usada = variable_struct_exists(_habilidade_estado, "veilUsed") && _habilidade_estado.veilUsed;
            _instancia.imune_armadilha_usos = variable_struct_exists(_habilidade_estado, "trapImmunity") ? _habilidade_estado.trapImmunity : 0;
            _instancia.imune_armadilha = _instancia.imune_armadilha_usos > 0;
            _instancia.digestao_usos = variable_struct_exists(_habilidade_estado, "digestionUses") ? _habilidade_estado.digestionUses : 0;
            _instancia.digestao_cadaver_disponivel = variable_struct_exists(_habilidade_estado, "corpseAvailable") && _habilidade_estado.corpseAvailable;
            _instancia.carnica_estado_proximo_ataque = variable_struct_exists(_habilidade_estado, "frenzy")
                ? ((_habilidade_estado.frenzy == "self") ? "autoataque" : _habilidade_estado.frenzy) : "";
            _instancia.troca_item_usada_este_turno = variable_struct_exists(_habilidade_estado, "itemActionUsed")
                && _habilidade_estado.itemActionUsed;
            _instancia.grimorio_usado_este_turno = variable_struct_exists(_habilidade_estado, "grimoireUsed")
                && _habilidade_estado.grimoireUsed;
            _instancia.grimorio_escudo_ativo = variable_struct_exists(_habilidade_estado, "grimoireShield")
                && _habilidade_estado.grimoireShield;
            _instancia.defesa_magica = _instancia.defesa_magica_base + (_instancia.grimorio_escudo_ativo ? 2 : 0);
        }
        _instancia.condicao = (_registro.condition == "") ? noone : _registro.condition;
        _instancia.condicao_turnos_restantes = variable_struct_exists(_registro, "conditionTurns") ? _registro.conditionTurns : 0;
        _instancia.condicao_dano_por_turno = variable_struct_exists(_registro, "conditionPower") ? _registro.conditionPower : 0;
        if (variable_struct_exists(_registro, "intelligence")) _instancia.nivel_inteligencia = _registro.intelligence;
        online_sincronizar_equipamentos(_instancia, variable_struct_exists(_registro, "equipment") ? _registro.equipment : []);
    } else {
        var _slot_construcao = online_slot_construcao(_instancia.dono, _registro.lane);
        if (_slot_construcao != noone && _instancia.slot_atual != _slot_construcao) {
            if (_instancia.slot_atual != noone) {
                _instancia.slot_atual.ocupado = false;
                _instancia.slot_atual.construcao_atual = noone;
            }
            _instancia.slot_atual = _slot_construcao;
            _instancia.x = _slot_construcao.x;
            _instancia.y = _slot_construcao.y;
            _slot_construcao.ocupado = true;
            _slot_construcao.construcao_atual = _instancia;
        }
        if (variable_struct_exists(_registro, "abilityState") && is_struct(_registro.abilityState))
            _instancia.habilidade_usada_este_turno = variable_struct_exists(_registro.abilityState, "used") && _registro.abilityState.used;
    }
    return _instancia;
}

function online_remover_cartas_ausentes() {
    with (obj_carta) {
        if (travada && online_instance_id != "" && !online_presente) {
            if (slot_atual != noone) {
                slot_atual.ocupado = false;
                slot_atual.carta_atual = noone;
            }
            instance_destroy();
        }
    }
    with (obj_construcao) {
        if (variable_instance_exists(id, "online_instance_id")
            && online_instance_id != ""
            && !online_presente) {
            if (slot_atual != noone) {
                slot_atual.ocupado = false;
                slot_atual.construcao_atual = noone;
            }
            instance_destroy();
        }
    }
}

function online_encontrar_visual_armadilha(_instance_id) {
    for (var i = 0; i < instance_number(obj_terreno_ativo); i++) {
        var _visual = instance_find(obj_terreno_ativo, i);
        if (variable_instance_exists(_visual, "online_trap_id") && _visual.online_trap_id == _instance_id) return _visual;
    }
    return noone;
}

function online_sincronizar_armadilhas_publicas(_armadilhas) {
    if (!is_array(_armadilhas)) _armadilhas = [];
    with (obj_terreno_ativo) {
        if (variable_instance_exists(id, "online_trap_id") && online_trap_id != "") online_presente = false;
    }
    for (var i = 0; i < array_length(_armadilhas); i++) {
        var _registro = _armadilhas[i];
        var _slot = buscar_slot(_registro.lane, _registro.position);
        if (_registro.definitionId != "") {
            var _botao = online_encontrar_carta_mao(_registro.instanceId);
            if (instance_exists(_botao)) {
                _botao.armadilha_lane = _registro.lane;
                _botao.armadilha_posicao = _registro.position;
                _botao.armadilha_estado = _registro.ready ? "pronta" : "vigiando";
            }
        }
        if (_slot == noone) continue;
        var _visual = online_encontrar_visual_armadilha(_registro.instanceId);
        if (!instance_exists(_visual)) {
            _visual = instance_create_layer(_slot.x, _slot.y, "Instances", obj_terreno_ativo);
            _visual.online_trap_id = _registro.instanceId;
            _visual.entrando = false;
            _visual.image_angle = 0;
            _visual.depth = 50;
            _visual.alpha_visual = 0.48;
        }
        _visual.online_presente = true;
        _visual.x = _slot.x;
        _visual.y = _slot.y;
        var _sprite = spr_deck;
        if (_registro.definitionId != "") {
            var _funcao = online_funcao_carta_por_id(_registro.definitionId);
            if (_funcao != noone) {
                var _dados = _funcao();
                if (variable_struct_exists(_dados, "sprite_carta") && _dados.sprite_carta != noone) _sprite = _dados.sprite_carta;
            }
        }
        _visual.sprite_index = _sprite;
        _visual.escala_base = (global.CARTA_LARGURA * 0.60) / sprite_get_width(_sprite);
    }
    with (obj_terreno_ativo) {
        if (variable_instance_exists(id, "online_trap_id") && online_trap_id != "" && !online_presente) instance_destroy();
    }
}

function online_aplicar_estado_publico(_estado) {
    if (!instance_exists(obj_controlador) || obj_controlador.modo_partida != "online") return;
    if (_estado.revision < obj_controlador.online_estado_aplicado_revisao) return;

    global.online_revisao = _estado.revision;
    obj_controlador.online_estado_aplicado_revisao = _estado.revision;
    obj_controlador.turno = online_lado_do_assento(_estado.currentPlayer);
    obj_controlador.partida_iniciada = (_estado.phase == "playing");
    if (obj_controlador.partida_iniciada) obj_controlador.disputa_inicial_estado = "concluida";
    obj_controlador.online_aguardando_turno = false;
    for (var p = 0; p < array_length(_estado.players); p++) {
        var _jogador = _estado.players[p];
        if (_jogador.seat == 0) { obj_controlador.vida_jogador = _jogador.life; obj_controlador.primeiro_turno_jogador = !_jogador.hasTakenTurn; }
        else { obj_controlador.vida_inimigo = _jogador.life; obj_controlador.primeiro_turno_inimigo = !_jogador.hasTakenTurn; }
    }

    online_reconstruir_recursos(_estado.players);
    online_sincronizar_efeitos_ativos(_estado.players, _estado.terrainDefinitionId);
    with (obj_carta) {
        if (travada && online_instance_id != "") online_presente = false;
    }
    with (obj_construcao) {
        if (variable_instance_exists(id, "online_instance_id") && online_instance_id != "") online_presente = false;
    }
    for (var c = 0; c < array_length(_estado.cards); c++) online_atualizar_carta_publica(_estado.cards[c]);
    online_remover_cartas_ausentes();
    online_sincronizar_armadilhas_publicas(variable_struct_exists(_estado, "traps") ? _estado.traps : []);
    organizar_mao();
}


function online_encontrar_carta_campo(_instance_id) {
    for (var i = 0; i < instance_number(obj_carta); i++) {
        var _carta = instance_find(obj_carta, i);
        if (_carta.travada && _carta.online_instance_id == _instance_id) return _carta;
    }
    return noone;
}

function online_animar_confirmacao(_mensagem) {
    if (!instance_exists(obj_controlador) || !is_struct(_mensagem) || !is_struct(_mensagem.payload)) return;
    var _dados = _mensagem.payload;
    if (_mensagem.kind == "use_ability") {
        var _origem_habilidade = online_encontrar_carta_campo(_dados.cardId);
        if (variable_struct_exists(_dados, "attacks") && is_array(_dados.attacks)) {
            for (var _ga = 0; _ga < array_length(_dados.attacks); _ga++)
                if (is_struct(_dados.attacks[_ga]))
                    online_animar_confirmacao({ kind: "attack", payload: _dados.attacks[_ga] });
        }
        if (variable_struct_exists(_dados, "counter") && is_struct(_dados.counter))
            online_animar_confirmacao({ kind: "attack", payload: _dados.counter });
        if (instance_exists(_origem_habilidade)) {
            var _nome_habilidade = variable_struct_exists(_dados, "ability") ? string_upper(_dados.ability) : "HABILIDADE";
            mostrar_feedback(_nome_habilidade, _origem_habilidade.x, _origem_habilidade.y - 48, c_aqua, 58);
        }
        return;
    }
    if (_mensagem.kind == "use_construction") {
        var _construcao_habilidade = online_encontrar_construcao_campo(_dados.cardId);
        if (instance_exists(_construcao_habilidade))
            mostrar_feedback("DRENOU SANGUE", _construcao_habilidade.x, _construcao_habilidade.y - 38, c_red, 55);
        return;
    }
    if (_mensagem.kind == "end_turn" && variable_struct_exists(_dados, "artillery") && is_array(_dados.artillery)) {
        for (var _ar = 0; _ar < array_length(_dados.artillery); _ar++) {
            var _evento_ar = _dados.artillery[_ar];
            var _torre_ar = online_encontrar_construcao_campo(_evento_ar.cardId);
            var _alvo_ar = online_encontrar_carta_campo(_evento_ar.targetId);
            if (instance_exists(_torre_ar) && instance_exists(_alvo_ar)) {
                rolar_dado_visual(_torre_ar.x, _torre_ar.y, _alvo_ar.x, _alvo_ar.y - 35, 6, _evento_ar.damage, noone, _ar * 8, 0, 55);
                mostrar_feedback("ARTILHARIA " + string(_evento_ar.damage), _alvo_ar.x, _alvo_ar.y - 50, c_yellow, 60);
            }
        }
        return;
    }
    if (_mensagem.kind == "play_spell" || _mensagem.kind == "play_item"
        || _mensagem.kind == "play_trap" || _mensagem.kind == "activate_trap"
        || _mensagem.kind == "play_effect") {
        var _alvo_especial = noone;
        if (variable_struct_exists(_dados, "targetId")) {
            _alvo_especial = online_encontrar_carta_campo(_dados.targetId);
            if (!instance_exists(_alvo_especial)) _alvo_especial = online_encontrar_construcao_campo(_dados.targetId);
        }
        var _fx = instance_exists(_alvo_especial) ? _alvo_especial.x : room_width / 2;
        var _fy = instance_exists(_alvo_especial) ? _alvo_especial.y - 45 : room_height / 2;
        var _texto = "CARTA USADA";
        var _cor = c_aqua;
        if (_mensagem.kind == "play_item") _texto = variable_struct_exists(_dados, "equipment") ? "EQUIPADO" : "ITEM USADO";
        else if (_mensagem.kind == "play_trap") { _texto = "ARMADILHA POSICIONADA"; _cor = c_purple; }
        else if (_mensagem.kind == "activate_trap") { _texto = "ARMADILHA ATIVADA"; _cor = c_red; }
        else if (_mensagem.kind == "play_effect") _texto = "EFEITO ATIVO";
        else if (variable_struct_exists(_dados, "copiedDefinitionId")) _texto = "REFRAÇÃO CRIADA";
        else if (variable_struct_exists(_dados, "condition")) _texto = string_upper(_dados.condition);
        mostrar_feedback(_texto, _fx, _fy, _cor, 55);

        if (variable_struct_exists(_dados, "damageRolls") && is_array(_dados.damageRolls)) {
            var _lados = 6;
            if (variable_struct_exists(_dados, "effect") && _dados.effect == "bola_fogo") _lados = 8;
            if (variable_struct_exists(_dados, "definitionId") && _dados.definitionId == "destrocos") _lados = 4;
            for (var d = 0; d < array_length(_dados.damageRolls); d++) {
                rolar_dado_visual(_fx - 20 + d * 40, _fy + 55, _fx - 20 + d * 40, _fy,
                    _lados, _dados.damageRolls[d], noone, d * 8, 0, 48);
            }
        }
        if (variable_struct_exists(_dados, "roll") && _dados.effect == "dados_manipulados") {
            rolar_dado_visual(_fx, _fy + 55, _fx, _fy, 4, _dados.roll, noone, 0, 0, 55);
        }
        return;
    }

    if (_mensagem.kind == "use_item_ability") {
        var _grimorio_origem = online_encontrar_carta_campo(_dados.cardId);
        var _grimorio_alvo = variable_struct_exists(_dados, "targetId")
            ? online_encontrar_carta_campo(_dados.targetId) : noone;
        var _gx = room_width / 2;
        var _gy = room_height / 2;
        if (instance_exists(_grimorio_origem)) { _gx = _grimorio_origem.x; _gy = _grimorio_origem.y; }
        if (instance_exists(_grimorio_alvo)) { _gx = _grimorio_alvo.x; _gy = _grimorio_alvo.y; }
        if (_dados.spell == "raio" && _dados.roll > 0) {
            rolar_dado_visual(_grimorio_origem.x, _grimorio_origem.y, _gx, _gy - 42, 4, _dados.roll, noone, 0, 0, 55);
            mostrar_feedback("RAIO: " + string(_dados.damage) + " DANO", _gx, _gy - 52, c_aqua, 60);
        } else if (_dados.spell == "escudo") {
            mostrar_feedback("+2 DEF MAGICA", _gx, _gy - 45, c_aqua, 60);
        } else mostrar_feedback("CURAZINHA +1", _gx, _gy - 45, c_lime, 60);
        return;
    }

    if (_mensagem.kind == "remove_item" || _mensagem.kind == "transfer_item") {
        var _origem_item = online_encontrar_carta_campo(_dados.cardId);
        var _destino_item = variable_struct_exists(_dados, "targetId")
            ? online_encontrar_carta_campo(_dados.targetId) : noone;
        var _texto_item = (_mensagem.kind == "transfer_item") ? "ITEM TRANSFERIDO" : "ITEM PARA A MAO";
        var _x_item = room_width / 2;
        var _y_item = room_height / 2;
        if (instance_exists(_origem_item)) { _x_item = _origem_item.x; _y_item = _origem_item.y; }
        if (instance_exists(_destino_item)) { _x_item = _destino_item.x; _y_item = _destino_item.y; }
        if (_mensagem.kind == "transfer_item" && instance_exists(_origem_item) && instance_exists(_destino_item)) {
            var _funcao_item_anim = online_funcao_carta_por_id(_dados.itemDefinitionId);
            if (_funcao_item_anim != noone) {
                var _dados_item_anim = _funcao_item_anim();
                criar_animacao_item(variable_struct_exists(_dados_item_anim, "sprite_carta")
                    ? _dados_item_anim.sprite_carta : noone,
                    _origem_item.x, _origem_item.y, _destino_item.x, _destino_item.y, c_aqua);
            }
        }
        mostrar_feedback(_texto_item, _x_item, _y_item - 45, c_aqua, 50);
        return;
    }

    if (_mensagem.kind == "move_troop") {
        if (variable_struct_exists(_dados, "movementPrevented") && _dados.movementPrevented) {
            mostrar_feedback("ARMADILHA PRONTA", room_width / 2, room_height / 2, c_purple, 60);
            return;
        }
        var _movida = online_encontrar_carta_campo(_dados.cardId);
        if (instance_exists(_movida)) mostrar_feedback(_dados.direction == "advance" ? "AVANÇOU" : "RECUOU", _movida.x, _movida.y - 35, c_aqua, 38);
        return;
    }
    if (_mensagem.kind != "attack" && _mensagem.kind != "choose_critical") return;
    var _atacante = online_encontrar_carta_campo(_dados.cardId);
    if (!instance_exists(_atacante)) return;
    var _alvo = variable_struct_exists(_dados, "targetId") ? online_encontrar_carta_campo(_dados.targetId) : noone;
    if (!instance_exists(_alvo) && variable_struct_exists(_dados, "targetId"))
        _alvo = online_encontrar_construcao_campo(_dados.targetId);
    if (variable_struct_exists(_dados, "criticalChoice") && _dados.criticalChoice) {
        obj_controlador.critico_contexto = { atacante: _atacante, defensor: _alvo, qtd_usada: _dados.dice, dado_usado: _dados.die, online: true };
        obj_controlador.critico_escolha_ativa = true;
        obj_controlador.carta_menu_aberto = noone;
    }
    var _destino_x = instance_exists(_alvo) ? _alvo.x : _atacante.x;
    var _destino_y = instance_exists(_alvo) ? _alvo.y : _atacante.y - 70;
    if (variable_struct_exists(_dados, "stealRoll") && _dados.stealRoll > 0) {
        rolar_dado_visual(_atacante.x, _atacante.y, _destino_x, _destino_y - 70, 10, _dados.stealRoll, noone, 0, 0, 55);
        if (variable_struct_exists(_dados, "stolenItem") && _dados.stolenItem != "")
            mostrar_feedback("ROUBOU O EQUIPAMENTO", _destino_x, _destino_y - 55, c_yellow, 65);
    }
    if (variable_struct_exists(_dados, "counter") && is_struct(_dados.counter))
        online_animar_confirmacao({ kind: "attack", payload: _dados.counter });
    if (variable_struct_exists(_dados, "accuracy")) {
        rolar_dado_visual(_atacante.x, _atacante.y, _destino_x, _destino_y - 48, 20, _dados.accuracy, noone, 0, 0, 58);
        if (variable_struct_exists(_dados, "hit") && !_dados.hit) {
            mostrar_feedback("ERROU — " + string(_dados.accuracy), _destino_x, _destino_y - 55, c_gray, 60);
            return;
        }
    }
    if (variable_struct_exists(_dados, "damageRolls") && is_array(_dados.damageRolls)) {
        var _tamanho = (_dados.attackType == "magica") ? _atacante.dado_dano_magico : _atacante.dado_dano;
        if (variable_struct_exists(_dados, "itemDefinitionId") && _dados.itemDefinitionId != "") {
            var _funcao_arma_dado = online_funcao_carta_por_id(_dados.itemDefinitionId);
            if (_funcao_arma_dado != noone) {
                var _dados_arma_dado = _funcao_arma_dado();
                if (variable_struct_exists(_dados_arma_dado, "sobrescreve_dado_dano"))
                    _tamanho = _dados_arma_dado.sobrescreve_dado_dano;
            }
        }
        for (var d = 0; d < array_length(_dados.damageRolls); d++) {
            var _deslocamento = (d - (array_length(_dados.damageRolls) - 1) * 0.5) * 34;
            rolar_dado_visual(_atacante.x, _atacante.y, _destino_x + _deslocamento, _destino_y - 28, _tamanho, _dados.damageRolls[d], noone, 0, 14 + d * 8, 62 + irandom_range(-5, 7));
        }
    }
    if (variable_struct_exists(_dados, "damage")) {
        iniciar_animacao_ataque(_atacante, _alvo, 18, 18);
        mostrar_feedback("DANO " + string(_dados.damage), _destino_x, _destino_y - 55, (variable_struct_exists(_dados, "critical") && _dados.critical) ? c_yellow : c_red, 70);
    }
}
