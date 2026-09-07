/// Infraestrutura do lobby online KARTHA (Colyseus).

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
        colyseus_send(_ref, "ready", { name: global.online_nome });
    });

    colyseus_on_message(_sala, function(_ref, _tipo, _dados) {
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
            case "match_started":
                global.online_primeiro = _dados.currentPlayer;
                global.online_seed = _dados.seed;
                global.modo_partida = "online";
                random_set_seed(global.online_seed);
                room_goto(rm_jogo);
                break;
            case "action_confirmed":
                global.online_revisao = _dados.revision;
                if (_dados.kind == "end_turn" && instance_exists(obj_controlador)) online_aplicar_fim_turno();
                break;
            case "action_rejected":
                global.online_revisao = _dados.revision;
                global.online_erro = "A ação não foi aceita pelo servidor.";
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
    colyseus_send(global.net_room, "action", {
        kind: _tipo, payload: _dados, revision: global.online_revisao
    });
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
