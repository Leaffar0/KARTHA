// =============================================================================
// KARTHA — interface e apresentação
// Dados e moedas visuais, partículas, menus, livro, áudio e ferramentas de teste.
// =============================================================================

#region Dado visual (D20 / dado de dano)
// Cria um dado animado que desliza do atacante até o defensor, gira, e para no valor
// já decidido (_resultado_final). Quando termina, chama _funcao_callback com o resultado.
function rolar_dado_visual(_x, _y, _destino_x, _destino_y, _tamanho_dado, _resultado_final, _funcao_callback, _modificador_exibido = 0, _atraso_inicio = 0, _tempo_total = -1, _dono_rolagem = "") {
    var _dado = instance_create_layer(_x, _y, "Instances", obj_dado);
    obj_controlador.rolagens_pendentes += 1;

    _dado.tamanho_dado = _tamanho_dado;
    _dado.valor_final = _resultado_final;
    _dado.modificador_exibido = _modificador_exibido;
    _dado.destino_x = _destino_x;
    _dado.destino_y = _destino_y;
    _dado.atraso_inicio = max(0, _atraso_inicio);
    _dado.image_alpha = (_dado.atraso_inicio > 0) ? 0 : 1;
    if (_tempo_total > 0) _dado.tempo_total_giro = _tempo_total;
    _dado.girando = true;
    _dado.tempo_girando = 0;
    if (_funcao_callback != noone && _dono_rolagem != "") {
        var _ctx_manipulado = { dono: _dono_rolagem, tamanho: _tamanho_dado, callback_real: _funcao_callback };
        _dado.callback = method(_ctx_manipulado, function(_valor_visual) {
            entregar_resultado_dado_manipulado(dono, tamanho, _valor_visual, callback_real);
        });
    } else {
        _dado.callback = _funcao_callback;
    }
    return _dado;
}
#endregion

#region Moeda visual (cara ou coroa)
// Mesmo princípio do dado: desliza, gira, para num resultado já sorteado, e chama o callback.
function jogar_moeda_visual(_origem_x, _origem_y, _destino_x, _destino_y, _funcao_callback) {
    var _resultado = irandom(1);

    var _moeda = instance_create_layer(_origem_x, _origem_y, "Instances", obj_moeda);
    _moeda.resultado_final = _resultado;
    _moeda.pos_inicial_x = _origem_x;
    _moeda.pos_inicial_y = _origem_y;
    _moeda.destino_x = _destino_x;
    _moeda.destino_y = _destino_y;
    _moeda.escala_moeda = global.MOEDA_LARGURA / sprite_get_width(_moeda.sprite_index);
    _moeda.desvio_lateral_moeda = choose(-1, 1) * irandom_range(6, 14);
    _moeda.girando = true;
    _moeda.tempo_girando = 0;
    _moeda.callback = _funcao_callback;

    _moeda.som_volume = 0.4;

	_moeda.som_arremesso = audio_play_sound(
	    snd_moeda_arremesso,
	    1,
	    0,
	    _moeda.som_volume,
	    0,
	    random_range(.95, 1.05)
	);

    obj_controlador.rolagens_pendentes += 1;
    debug_combate("+1 pendente (moeda id=" + string(_moeda.id) + "). Total: " + string(obj_controlador.rolagens_pendentes));
}
#endregion

#region Partículas — poeira ao jogar carta
function criar_poeira(_x, _y, _largura) {
    var _quantidade = 10; // quantas partículas por explosão

    for (var i = 0; i < _quantidade; i++) {
        // nasce numa posição aleatória ao longo da base da carta
        var _nasce_x = _x + random_range(-_largura/2, _largura/2);
        var _nasce_y = _y;

        var _particula = instance_create_layer(_nasce_x, _nasce_y, "Instances", obj_particula_poeira);

        // direção: espalha principalmente pros lados e um pouco pra baixo
        _particula.direcao_movimento = random_range(200, 340);
        _particula.velocidade_particula = random_range(1.5, 4);
        _particula.vida_particula = irandom_range(20, 35);
        _particula.vida_particula_max = _particula.vida_particula;
    }
}
	
function criar_flash(_x, _y, _tamanho = 40) {
    var _flash = instance_create_layer(_x, _y, "Instances", obj_flash_efeito);
    _flash.tamanho_flash = _tamanho;
}
#endregion

#region Menu de ação (clicar na tropa → categorias e ações)
function tropa_tem_ataque_de_item(_carta) {
    for (var _ii = 0; _ii < array_length(_carta.itens_equipados); _ii++) {
        if (_carta.itens_equipados[_ii].dado > 0) return true;
    }
    return false;
}

function obter_opcoes_menu_principal(_carta) {
    var _opcoes = [];
    var _pode_atacar = !primeiro_turno_do_lado(_carta.dono);

    var _tem_ataque = _carta.dado_dano > 0 || _carta.dado_dano_magico > 0 || tropa_tem_ataque_de_item(_carta);
    if (!_tem_ataque) array_push(_opcoes, "Ataque [sem ataque]");
    else if (!_carta.atacou_este_turno && _pode_atacar) array_push(_opcoes, "Ataque");
    else {
        array_push(_opcoes, _carta.atacou_este_turno ? "Ataque [já usado]" : "Ataque [1º turno]");
    }

    if (_carta.moveu_este_turno) array_push(_opcoes, "Movimento [já usado]");
    else if (_carta.turnos_no_campo < 1) array_push(_opcoes, "Movimento [próximo turno]");
    else array_push(_opcoes, "Movimento");
    if (array_length(_carta.itens_equipados) > 0) array_push(_opcoes, "Itens");
    if (_carta.travada && _carta.posicao_atual == posicao_entrada(_carta.dono)) {
        array_push(_opcoes, _carta.defendendo_castelo ? "Parar de Defender" : "Defender Castelo");
    }
    var _ativas = habilidades_ativas(_carta);
    for (var _ha = 0; _ha < array_length(_ativas); _ha++) {
        var _rotulo = "Habilidade: " + obter_nome_exibicao_habilidade(_ativas[_ha]);
        array_push(_opcoes, _rotulo + (_carta.habilidade_usada_este_turno ? " [já usada]" : ""));
    }
    if (tropa_tem_item_efeito(_carta, "grimorio_iniciante")) {
        var _sufixo_grimorio = _carta.grimorio_usado_este_turno ? " [já usado]" : "";
        array_push(_opcoes, "Grimório: Raio" + _sufixo_grimorio);
        array_push(_opcoes, "Grimório: Escudo" + _sufixo_grimorio);
        array_push(_opcoes, "Grimório: Curazinha" + _sufixo_grimorio);
    }
    if (_carta.funcao_evolucao != noone) {
        if (_carta.turnos_no_campo < 1) array_push(_opcoes, "Evoluir [sobreviva 1 turno]");
        else if (!evolucoes_disponiveis(_carta.dono)) array_push(_opcoes, "Evoluir [limite atingido]");
        else array_push(_opcoes, "Evoluir");
    }
    return _opcoes;
}

function obter_opcoes_menu_ataque(_carta) {
    var _opcoes = [];
    if (_carta.dado_dano > 0) array_push(_opcoes, "Atacar (Física)");
    if (_carta.dado_dano_magico > 0) array_push(_opcoes, "Atacar (Mágica)");
    for (var _ii = 0; _ii < array_length(_carta.itens_equipados); _ii++) {
        var _item = _carta.itens_equipados[_ii];
        if (_item.dado > 0) array_push(_opcoes, "Atacar com " + _item.nome);
    }
    array_push(_opcoes, "Voltar");
    return _opcoes;
}

function obter_opcoes_menu_movimento(_carta) {
    var _opcoes = [];
    array_push(_opcoes, _carta.posicao_atual == posicao_assalto(_carta.dono)
        ? "Avançar [posição de assalto]" : "Avançar");
    array_push(_opcoes, _carta.posicao_atual == posicao_entrada(_carta.dono)
        ? "Recuar [posição de base]" : "Recuar");
    array_push(_opcoes, "Voltar");
    return _opcoes;
}

function obter_opcoes_menu_itens(_carta) {
    if (troca_item_do_lado_usada(_carta.dono))
        return ["Remover Item [limite de 1 troca por turno]", "Transferir Item [limite de 1 troca por turno]", "Voltar"];
    var _opcoes = [];
    array_push(_opcoes, _carta.troca_item_usada_este_turno ? "Remover Item [já usado]" : "Remover Item");
    array_push(_opcoes, _carta.troca_item_usada_este_turno ? "Transferir Item [já usado]" : "Transferir Item");
    array_push(_opcoes, "Voltar");
    return _opcoes;
}

function obter_opcoes_menu(_carta) {
    if (!instance_exists(_carta)) return [];
    switch (obj_controlador.menu_submenu) {
        case "ataque": return sinalizar_bloqueios_menu(_carta, obter_opcoes_menu_ataque(_carta));
        case "movimento": return sinalizar_bloqueios_menu(_carta, obter_opcoes_menu_movimento(_carta));
        case "itens": return sinalizar_bloqueios_menu(_carta, obter_opcoes_menu_itens(_carta));
    }
    return sinalizar_bloqueios_menu(_carta, obter_opcoes_menu_principal(_carta));
}

function categoria_bloqueada_primeiro_turno(_categoria) {
    return (_categoria == "item_equipavel" 
         || _categoria == "item_consumivel" 
         || _categoria == "magica" 
         || _categoria == "terreno");
}

function executar_opcao_menu(_carta, _opcao) {
    if (!instance_exists(_carta)) return;
    var _habilidade_escolhida = noone;
    if (string_pos("Habilidade: ", _opcao) == 1) {
        var _ativas_menu = habilidades_ativas(_carta);
        for (var _hm = 0; _hm < array_length(_ativas_menu); _hm++)
            if (_opcao == "Habilidade: " + obter_nome_exibicao_habilidade(_ativas_menu[_hm])) {
                _habilidade_escolhida = _ativas_menu[_hm];
                _opcao = "Habilidade";
                break;
            }
    }
    if (!instance_exists(_carta)) return;
    if (obj_controlador.turno != _carta.dono || (obj_controlador.modo_partida == "online" && !lado_controlado_localmente(_carta.dono))) {
        mostrar_aviso_regra("Você pode inspecionar; ações ficam para o seu turno", _carta.x, _carta.y);
        return;
    }
    if (obj_controlador.rolagens_pendentes > 0) {
        mostrar_aviso_regra("Aguarde a rolagem terminar", _carta.x, _carta.y);
        return;
    }
    if (tem_condicao(_carta, "adormecido") || tem_condicao(_carta, "loucura")) {
        mostrar_aviso_regra("Esta condição impede ações da tropa", _carta.x, _carta.y);
        return;
    }
    if (string_pos("[", _opcao) > 0) {
        mostrar_aviso_regra(string_delete(_opcao, 1, string_pos("[", _opcao) - 1), _carta.x, _carta.y);
        return;
    }
    if (obj_controlador.modo_partida == "online") {
        if (_opcao == "Avançar" || _opcao == "Recuar") {
            online_enviar_acao("move_troop", { cardId: _carta.online_instance_id, direction: (_opcao == "Avançar") ? "advance" : "retreat" });
            return;
        }
        if (_opcao == "Defender Castelo" || _opcao == "Parar de Defender") {
            online_enviar_acao("set_castle_defense", { cardId: _carta.online_instance_id,
                defending: _opcao == "Defender Castelo" });
            return;
        }
        if (_opcao == "Evoluir") {
            online_enviar_acao("evolve_troop", { cardId: _carta.online_instance_id });
            return;
        }

        if (string_pos("Atacar", _opcao) == 1) {
            if (string_pos("Atacar com ", _opcao) == 1) {
                var _nome_arma_online = string_delete(_opcao, 1, string_length("Atacar com "));
                for (var _ao = 0; _ao < array_length(_carta.itens_equipados); _ao++) {
                    var _arma_online = _carta.itens_equipados[_ao];
                    if (_arma_online.nome == _nome_arma_online && _arma_online.dado > 0
                        && variable_struct_exists(_arma_online, "online_definition_id")) {
                        online_enviar_acao("attack", { cardId: _carta.online_instance_id,
                            attackType: "fisica", itemDefinitionId: _arma_online.online_definition_id });
                        return;
                    }
                }
                mostrar_aviso_regra("A arma escolhida nao esta equipada", _carta.x, _carta.y);
                return;
            }
            var _tipo_online = (_opcao == "Atacar (Mágica)") ? "magica" : "fisica";
            online_enviar_acao("attack", { cardId: _carta.online_instance_id, attackType: _tipo_online });
            return;
        }

        if (string_pos("Grimório: ", _opcao) == 1) {
            var _magia_grimorio_online = "curazinha";
            if (_opcao == "Grimório: Raio") _magia_grimorio_online = "raio";
            else if (_opcao == "Grimório: Escudo") _magia_grimorio_online = "escudo";
            online_enviar_acao("use_item_ability", { cardId: _carta.online_instance_id,
                spell: _magia_grimorio_online });
            return;
        }
        if (_opcao == "Remover Item") {
            online_enviar_acao("remove_item", { cardId: _carta.online_instance_id });
            return;
        }
        if (_opcao == "Transferir Item") {
            obj_controlador.ui_modal.troca_item_selecao_ativa = true;
            obj_controlador.ui_modal.troca_item_origem = _carta;
            obj_controlador.tropa_selecionada = _carta;
            obj_controlador.carta_menu_aberto = noone;
            return;
        }
        if (_opcao == "Habilidade") {
            var _habilidade_online = _habilidade_escolhida != noone ? _habilidade_escolhida : tem_habilidade_ativa(_carta);
            if (_habilidade_online == "digestao" && !_carta.digestao_cadaver_disponivel) {
                var _alvos_digestao_online = [];
                with (obj_carta) if (alvo_valido_digestao(_carta, id)) array_push(_alvos_digestao_online, id);
                if (array_length(_alvos_digestao_online) == 1) {
                    online_enviar_acao("use_ability", { cardId: _carta.online_instance_id, ability: _habilidade_online,
                        targetId: _alvos_digestao_online[0].online_instance_id });
                } else if (array_length(_alvos_digestao_online) > 1) {
                    obj_controlador.ui_modal.digestao_selecao_ativa = true;
                    obj_controlador.ui_modal.digestao_origem = _carta;
                    obj_controlador.carta_menu_aberto = noone;
                    obj_controlador.tropa_selecionada = _carta;
                } else mostrar_aviso_regra("Digestao precisa de alvo adjacente com menos de 4 de vida", _carta.x, _carta.y);
            } else {
                online_enviar_acao("use_ability", { cardId: _carta.online_instance_id, ability: _habilidade_online });
            }
            return;
        }
    }
    if (string_pos("Atacar com ", _opcao) == 1) {
        var _nome_item_ataque = string_delete(_opcao, 1, string_length("Atacar com "));
        for (var _ia = 0; _ia < array_length(_carta.itens_equipados); _ia++) {
            var _item_ataque = _carta.itens_equipados[_ia];
            if (_item_ataque.nome == _nome_item_ataque && _item_ataque.dado > 0) {
                _carta.item_ataque_atual = _item_ataque;
                _carta.atacou_este_turno = processar_combate_tropa(_carta, "fisica");
                return;
            }
        }
    }
    switch (_opcao) {
        case "Atacar":
            _carta.item_ataque_atual = noone;
            var _tipo = (_carta.dado_dano_magico > 0 && _carta.dado_dano == 0) ? "magica" : "fisica";
            _carta.atacou_este_turno = processar_combate_tropa(_carta, _tipo);
            break;
        case "Atacar (Física)":
            _carta.item_ataque_atual = noone;
            _carta.atacou_este_turno = processar_combate_tropa(_carta, "fisica");
            break;
        case "Atacar (Mágica)":
            _carta.item_ataque_atual = noone;
            _carta.atacou_este_turno = processar_combate_tropa(_carta, "magica");
            break;
        case "Avançar":
        case "Recuar":
            var _direcao_movimento = (_opcao == "Avançar") ? 1 : -1;
            var _resultado = mover_tropa(_carta, _direcao_movimento);
            if (_resultado == "movido") {
                _carta.moveu_este_turno = true;
                mostrar_feedback(_direcao_movimento == 1 ? "AVANÇOU" : "RECUOU",
                    _carta.x, _carta.y - 35, _direcao_movimento == 1 ? c_lime : c_aqua, 38);
            } else if (_resultado == "recem_colocada") {
                mostrar_aviso_regra("A tropa só pode mover no próximo turno", _carta.x, _carta.y);
            } else if (_resultado == "bloqueado") {
                mostrar_aviso_regra("Uma tropa aliada bloqueia o caminho", _carta.x, _carta.y);
            } else if (_resultado == "ataque_necessario") {
                mostrar_aviso_regra("Há um inimigo no caminho", _carta.x, _carta.y);
            } else if (_resultado == "armadilha") {
                mostrar_feedback("PRESA PELAS RAÍZES", _carta.x, _carta.y - 38, c_lime, 55);
            } else {
                mostrar_aviso_regra(_direcao_movimento == 1 ? "Não pode avançar mais" : "Não pode recuar mais",
                    _carta.x, _carta.y);
            }
            break;
        case "Defender Castelo":
            _carta.defendendo_castelo = true;
            debug_combate(_carta.nome_carta + " está defendendo o castelo.");
            mostrar_feedback("DEFENDENDO", _carta.x, _carta.y - 35, c_aqua, 45);
            break;
        case "Parar de Defender":
            _carta.defendendo_castelo = false;
            debug_combate(_carta.nome_carta + " deixou de defender o castelo.");
            mostrar_feedback("DEFESA ENCERRADA", _carta.x, _carta.y - 35, c_silver, 45);
            break;
        case "Habilidade":
            usar_habilidade(_carta, _habilidade_escolhida);
            break;
        case "Grimório: Raio": usar_grimorio_iniciante(_carta, "raio"); break;
        case "Grimório: Escudo": usar_grimorio_iniciante(_carta, "escudo"); break;
        case "Grimório: Curazinha": usar_grimorio_iniciante(_carta, "curazinha"); break;
        case "Remover Item":
            if (remover_item_equipado(_carta, array_length(_carta.itens_equipados) - 1, true) != noone) {
                _carta.troca_item_usada_este_turno = true;
                mostrar_feedback("ITEM PARA A MÃO", _carta.x, _carta.y - 45, c_aqua, 45);
            }
            break;
        case "Transferir Item":
            obj_controlador.ui_modal.troca_item_selecao_ativa = true;
            obj_controlador.ui_modal.troca_item_origem = _carta;
            obj_controlador.tropa_selecionada = _carta;
            break;
        case "Evoluir":
            evoluir_tropa(_carta);
            break;
    }
}
#endregion

#region Livro de Regras
function carregar_livro_regras() {
    var _caminho = working_directory + "livro_regras.json";

    if (!file_exists(_caminho)) {
        show_debug_message("AVISO: livro_regras.json não encontrado em " + _caminho);
        return [];
    }

    var _buffer = buffer_load(_caminho);
    var _conteudo = buffer_read(_buffer, buffer_string);
    buffer_delete(_buffer);

    var _dados = json_parse(_conteudo);
    return _dados;
}

// Reduz a escala do texto aos poucos até a altura final caber no espaço disponível.
// Precisa que a fonte certa já esteja setada (draw_set_font) antes de chamar.
// Texto compacto para menus: preserva a fonte com acentos sem alterar as cartas ou o HUD.
function desenhar_texto_interface(_x, _y, _texto, _escala = 0.78) {
    draw_text_transformed(_x, _y, _texto, _escala, _escala, 0);
}

function desenhar_texto_interface_ext(_x, _y, _texto, _separacao, _largura, _escala = 0.78) {
    draw_text_ext_transformed(_x, _y, _texto, _separacao, _largura / _escala, _escala, _escala, 0);
}

function calcular_escala_texto_ajustada(_texto, _largura_alvo, _altura_alvo, _escala_inicial, _escala_minima) {
    var _escala = _escala_inicial;
    repeat (30) {
        var _largura_wrap = _largura_alvo / _escala;
        var _altura_natural = string_height_ext(_texto, -1, _largura_wrap);
        var _altura_final = _altura_natural * _escala;
        if (_altura_final <= _altura_alvo || _escala <= _escala_minima) break;
        _escala -= 0.01;
    }
    return max(_escala, _escala_minima);
}
	
// Desenha o conteúdo de UMA página (título + corpo + rodapé de parte) numa área retangular.
// Serve tanto pra folha esquerda (estática) quanto pra direita (dentro da matriz de virada),
// já que as duas mostram o mesmo tipo de conteúdo agora.
function desenhar_pagina_do_livro(_pagina, _centro_x, _centro_y, _largura_disponivel, _altura_disponivel) {
    var _margem = _largura_disponivel * 0.1;
    var _largura_texto = _largura_disponivel - (_margem * 2);

    var _altura_titulo_reservada = _altura_disponivel * 0.16;
    var _altura_rodape_reservada = (_pagina.partes > 1) ? (_altura_disponivel * 0.08) : 0;
    var _altura_corpo_disponivel = _altura_disponivel - _altura_titulo_reservada - _altura_rodape_reservada;

    var _escala_titulo = calcular_escala_texto_ajustada(_pagina.titulo, _largura_texto, _altura_titulo_reservada * 0.8, 0.72, 0.42);
    var _escala_corpo = calcular_escala_texto_ajustada(_pagina.corpo, _largura_texto, _altura_corpo_disponivel, 0.58, 0.40);

    var _topo_y = _centro_y - _altura_disponivel/2;
    var _cor_tinta = make_color_rgb(64, 44, 27);
    var _cor_titulo = make_color_rgb(90, 30, 24); // um vermelho-vinho escuro, tipo tinta de destaque

    draw_set_color(_cor_titulo);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text_transformed(_centro_x, _topo_y + (_altura_titulo_reservada * 0.15), _pagina.titulo, _escala_titulo, _escala_titulo, 0);

    draw_set_color(_cor_tinta);
    draw_set_halign(fa_left);
    draw_text_ext_transformed(_centro_x - _largura_texto/2, _topo_y + _altura_titulo_reservada, _pagina.corpo, -1, _largura_texto / _escala_corpo, _escala_corpo, _escala_corpo, 0);

    if (_pagina.partes > 1) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_bottom);
        draw_set_alpha(0.6);
        draw_text_transformed(_centro_x, _centro_y + _altura_disponivel/2, "Parte " + string(_pagina.parte) + " de " + string(_pagina.partes), 0.62, 0.62, 0);
        draw_set_alpha(1);
    }

    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
#endregion

#region Áudio
function carregar_configuracoes() {
    ini_open("kartha_config.ini");
    global.volume_musica = clamp(ini_read_real("audio", "musica", 0.8), 0, 1);
    global.volume_efeitos = clamp(ini_read_real("audio", "efeitos", 0.8), 0, 1);
    var _tela_cheia = ini_read_real("video", "tela_cheia", 0) >= 0.5;
    definir_tamanho_interface(ini_read_real("video", "tamanho_interface", 0));
    ini_close();
    if (window_get_fullscreen() != _tela_cheia) window_set_fullscreen(_tela_cheia);
    aplicar_config_audio();
}

function salvar_configuracoes() {
    ini_open("kartha_config.ini");
    ini_write_real("audio", "musica", global.volume_musica);
    ini_write_real("audio", "efeitos", global.volume_efeitos);
    ini_write_real("video", "tela_cheia", window_get_fullscreen() ? 1 : 0);
    ini_write_real("video", "tamanho_interface", global.nivel_interface);
    ini_close();
}

function definir_tamanho_interface(_nivel) {
    global.nivel_interface = clamp(round(_nivel), 0, 2);
    global.escala_interface = 1 - global.nivel_interface * 0.15;
}

function alternar_tamanho_interface() {
    definir_tamanho_interface((global.nivel_interface + 1) mod 3);
    salvar_configuracoes();
    if (instance_exists(obj_controlador)) {
        atualizar_escala_hud(obj_controlador);
        organizar_mao();
    }
}

function atualizar_escala_hud(_controle) {
    if (!surface_exists(application_surface)) return;
    var _w = surface_get_width(application_surface);
    var _h = surface_get_height(application_surface);
    var _escala = global.escala_interface;
    if (_controle.hud_escala_aplicada == _escala
        && _controle.hud_superficie_w == _w && _controle.hud_superficie_h == _h) return;

    // A GUI e device_mouse_*_to_gui continuam na mesma base de coordenadas.
    if (_escala == 1) display_set_gui_size(-1, -1);
    else display_set_gui_size(round(_w / _escala), round(_h / _escala));
    _controle.hud_escala_aplicada = _escala;
    _controle.hud_superficie_w = _w;
    _controle.hud_superficie_h = _h;
}

function desenhar_opcao_tamanho_interface(_x, _y) {
    draw_set_color(c_aqua);
    desenhar_texto_interface(_x, _y, "INTERFACE  " + string(round(global.escala_interface * 100)) + "%  >");
    draw_set_color(c_white);
}

function aplicar_config_audio() {
    var _musica = variable_global_exists("volume_musica") ? global.volume_musica : 0.8;
    var _efeitos = variable_global_exists("volume_efeitos") ? global.volume_efeitos : 0.8;
    audio_sound_gain(snd_menu, _musica, 0);
    audio_sound_gain(snd_jogo, _musica, 0);
    var _sons_efeito = [snd_bencao, snd_maldicao, snd_bola_fogo_fogo, snd_bola_fogo_impacto, snd_bola_fogo_voo, snd_colocar, snd_moeda_arremesso, snd_moeda_impacto, snd_shuffle];
    for (var i = 0; i < array_length(_sons_efeito); i++) {
        audio_sound_gain(_sons_efeito[i], _efeitos, 0);
    }
}

function tocar_musica(_musica) {
    audio_stop_all();

    if (!audio_is_playing(_musica)) {
        audio_play_sound(_musica, 0, true);
    }
    aplicar_config_audio();
}

// Divide capítulos longos em partes legíveis. Assim o livro não reduz o texto
// até ficar minúsculo só para caber em uma página.
function paginar_livro_regras(_capitulos, _limite_caracteres) {
    var _resultado = [];

    for (var i = 0; i < array_length(_capitulos); i++) {
        var _capitulo = _capitulos[i];
        var _palavras = string_split(_capitulo.corpo, " ");
        var _partes = [];
        var _texto_atual = "";

        for (var j = 0; j < array_length(_palavras); j++) {
            var _palavra = _palavras[j];
            var _candidato = (_texto_atual == "") ? _palavra : (_texto_atual + " " + _palavra);
            if (string_length(_candidato) > _limite_caracteres && _texto_atual != "") {
                array_push(_partes, _texto_atual);
                _texto_atual = _palavra;
            } else {
                _texto_atual = _candidato;
            }
        }
        if (_texto_atual != "") array_push(_partes, _texto_atual);
        if (array_length(_partes) == 0) array_push(_partes, "");

        for (var j = 0; j < array_length(_partes); j++) {
            array_push(_resultado, {
                titulo: _capitulo.titulo,
                corpo: _partes[j],
                parte: j + 1,
                partes: array_length(_partes)
            });
        }
    }
    return _resultado;
}
#endregion

#region Debug — ferramentas de teste
// Procura no baralho inteiro (todas as cartas possíveis do jogo) uma função cujo
// nome bata (parcialmente, sem diferenciar maiúsculas) com o texto digitado.
function debug_buscar_funcao_carta_por_nome(_texto_busca) {
    var _busca_lower = string_lower(_texto_busca);

    for (var i = 0; i < array_length(obj_controlador.baralho); i++) {
        var _funcao = obj_controlador.baralho[i];
        var _dados = _funcao();
        var _nome_lower = string_lower(_dados.nome);

        if (string_pos(_busca_lower, _nome_lower) > 0) {
            return _funcao;
        }
    }
    return noone;
}

// Cria a carta direto na mão do jogador, SEM consumir do monte nem gastar recursos.
// Ideal pra testar uma carta específica sem precisar montar uma run inteira.
function debug_adicionar_carta_a_mao(_texto_busca) {
    var _funcao = debug_buscar_funcao_carta_por_nome(_texto_busca);

    if (_funcao == noone) {
        debug_combate("DEBUG: nenhuma carta encontrada com o nome '" + _texto_busca + "'.");
        return false;
    }

    comprar_carta_do_deck_por_funcao(_funcao, obj_deck.x, obj_deck.y);
    debug_combate("DEBUG: carta adicionada à mão via busca '" + _texto_busca + "'.");
    return true;
}

// Enche todos os tipos de recurso do jogador de uma vez, até o limite de 6 por tipo,
// só pra testar cartas com custo sem precisar juntar recursos manualmente.
function debug_encher_recursos(_dono = "jogador") {
    var _tipos = ["sangue", "ossos", "sucata", "mana"];

    for (var i = 0; i < array_length(_tipos); i++) {
        var _slot_livre = noone;
        with (obj_slot_recurso) {
            if (!ocupado && dono == _dono) {
                _slot_livre = id;
                break;
            }
        }
        if (_slot_livre == noone) break; // campo já cheio

        // ignora o limite de "1 recurso por turno" só pro debug
        var _resultado_antigo = (_dono == "jogador") ? obj_controlador.recurso_colocado_no_turno : obj_controlador.recurso_colocado_no_turno_inimigo;
        if (_dono == "jogador") obj_controlador.recurso_colocado_no_turno = false;
        else obj_controlador.recurso_colocado_no_turno_inimigo = false;

        colocar_recurso(_tipos[i mod array_length(_tipos)], _dono, _slot_livre.x, _slot_livre.y, _slot_livre);

        if (_dono == "jogador") obj_controlador.recurso_colocado_no_turno = _resultado_antigo;
        else obj_controlador.recurso_colocado_no_turno_inimigo = _resultado_antigo;
    }

    debug_combate("DEBUG: recursos do " + _dono + " preenchidos.");
}
#endregion

#region Utilidades matemáticas
// Interpola suavemente entre dois ângulos, sempre pelo caminho mais curto
// (evita o bug clássico de girar 350° quando devia girar só 10°).
function lerp_angulo(_atual, _alvo, _fator) {
    var _diferenca = ((_alvo - _atual + 180) mod 360) - 180;
    return _atual + _diferenca * _fator;
}
#endregion

// A apresentação lê os mesmos contadores usados pelas regras.
function resumo_usos_turno(_lado) {
    var _c = obj_controlador;
    if (_c.modo_partida == "online") return variable_struct_get(_c.resumos_turno_online, _lado);
    return { troops: _c.cartas_jogadas_no_turno, items: _c.itens_usados_este_turno,
        spells: _c.magias_usadas_este_turno, constructions: _c.construcoes_jogadas_este_turno,
        terrain: _c.terrenos_jogados_este_turno, resourcePlaced: recurso_ja_colocado_no_turno(_lado) ? 1 : 0,
        resourceRemoved: (_lado == "jogador" ? _c.recurso_retirado_no_turno : _c.recurso_retirado_no_turno_inimigo) ? 1 : 0,
        evolutions: _lado == "jogador" ? _c.evolucoes_jogador_este_turno : _c.evolucoes_inimigo_este_turno };
}

function desenhar_texto_ajustado_ui(_texto, _x, _y, _largura, _escala = 0.60) {
    var _ajuste = min(_escala, _largura / max(1, string_width(_texto)));
    draw_text_transformed(_x, _y, _texto, _ajuste, _ajuste, 0);
}

function desenhar_resumo_regras_turno() {
    var _c = obj_controlador;
    if (!painel_regras_disponivel()) return;
    var _layout = layout_painel_regras();
    draw_set_font(Fontenil); draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_alpha(0.94); draw_set_color(make_color_rgb(15, 19, 27));
    draw_roundrect(_layout.x, _layout.y, _layout.x + 180, _layout.y + 28, false);
    draw_set_alpha(1); draw_set_color(c_aqua);
    draw_roundrect(_layout.x, _layout.y, _layout.x + 180, _layout.y + 28, true);
    desenhar_texto_ajustado_ui((_c.painel_regras_aberto ? "[-] " : "[+] ") + "Regras do turno [Tab]",
        _layout.x + 9, _layout.y + 5, 162, 0.55);
    if (_c.painel_regras_animacao <= 0.005) { draw_set_color(c_white); return; }
    var _p = _c.painel_regras_animacao;
    var _alpha_painel = _p * _p * (3 - 2 * _p);
    var _lado = _c.turno;
    var _usos = resumo_usos_turno(_lado);
    var _primeiro = primeiro_turno_do_lado(_lado);
    var _titulos = ["Tropas", "Itens", "Magias", "Construções", "Terreno", "Colocar recurso", "Retirar recurso", "Evoluções", "Troca de item"];
    var _chaves = ["troops", "items", "spells", "constructions", "terrain", "resourcePlaced", "resourceRemoved", "evolutions"];
    var _limites = [1, 3, 2, 1, 1, 1, 1, 1, 1];
    var _x = _layout.x;
    var _y = _layout.y + 36 - (1 - _alpha_painel) * 18;
    var _largura = _layout.largura;
    var _coluna = (_largura - 24) / 3;
    draw_set_font(Fontenil); draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_alpha(0.91 * _alpha_painel); draw_set_color(make_color_rgb(15, 19, 27));
    draw_roundrect(_x, _y, _x + _largura, _y + 139, false);
    draw_set_alpha(_alpha_painel); draw_set_color(make_color_rgb(76, 105, 125));
    draw_roundrect(_x, _y, _x + _largura, _y + 139, true);
    draw_set_color(c_aqua);
    desenhar_texto_ajustado_ui("AÇÕES DO TURNO — " + nome_jogador_lado(_lado), _x + 12, _y + 7, _largura - 24, 0.62);
    for (var i = 0; i < 9; i++) {
        var _bloqueado = _primeiro && (i == 1 || i == 2 || i == 4);
        var _valor = i == 8 ? (troca_item_do_lado_usada(_lado) ? 1 : 0)
            : (_usos == noone ? -1 : variable_struct_get(_usos, _chaves[i]));
        var _texto = _titulos[i] + "  " + (_valor < 0 ? "?" : string(_valor)) + "/" + string(_limites[i]);
        if (_bloqueado) _texto = _titulos[i] + " — 1º turno";
        var _cor = _bloqueado ? c_gray : (_valor >= _limites[i] ? make_color_rgb(255, 185, 85) : c_white);
        draw_set_color(_cor);
        desenhar_texto_ajustado_ui(_texto, _x + 12 + (i mod 3) * _coluna,
            _y + 34 + floor(i / 3) * 25, _coluna - 10, 0.56);
    }
    draw_set_color(_primeiro ? c_yellow : c_silver);
    var _nota = _primeiro ? "1º turno: ataques, itens, magias e terreno bloqueados."
        : "Usos / limite. Ataque e movimento: 1 ação por tropa.";
    if (_usos == noone) _nota = "Aguardando contadores do servidor.";
    desenhar_texto_ajustado_ui(_nota, _x + 12, _y + 113, _largura - 24, 0.48);
    draw_set_color(c_white); draw_set_alpha(1);
}

function sinalizar_bloqueios_menu(_carta, _opcoes) {
    var _incapaz = tem_condicao(_carta, "adormecido") ? "adormecido"
        : (tem_condicao(_carta, "loucura") ? "loucura" : "");
    if (obj_controlador.turno != _carta.dono
        || (obj_controlador.modo_partida == "online" && !lado_controlado_localmente(_carta.dono))) _incapaz = "aguarde seu turno";
    else if (obj_controlador.rolagens_pendentes > 0) _incapaz = "aguarde a rolagem";
    for (var i = 0; i < array_length(_opcoes); i++) {
        var _opcao = _opcoes[i];
        if (_opcao == "Voltar") continue;
        // Atualiza o motivo em vez de acumular dois sufixos no mesmo botão.
        var _colchete = string_pos(" [", _opcao);
        var _base = _colchete > 0 ? string_copy(_opcao, 1, _colchete - 1) : _opcao;
        var _motivo = _incapaz;
        var _ataque = _base == "Ataque" || string_pos("Atacar", _base) == 1;
        var _movimento = _base == "Movimento" || _base == "Avançar" || _base == "Recuar";
        var _habilidade = _base == "Habilidade" || string_pos("Habilidade: ", _base) == 1 || string_pos("Grimório:", _base) == 1;
        if (_motivo == "" && tem_condicao(_carta, "paralisado") && (_ataque || _movimento || _habilidade)) _motivo = "paralisado";
        if (_motivo == "" && tem_condicao(_carta, "congelado") && (_ataque || _movimento)) _motivo = "congelado";
        if (_motivo == "" && _ataque && primeiro_turno_do_lado(_carta.dono)) _motivo = "1º turno";
        if (_motivo == "" && _ataque && _carta.atacou_este_turno) _motivo = "ataque usado";
        if (_motivo == "" && _movimento && _carta.moveu_este_turno) _motivo = "movimento usado";
        if (_motivo == "" && _movimento && _carta.turnos_no_campo < 1) _motivo = "próximo turno";
        if (_motivo == "" && _habilidade && tem_habilidade_ativa(_carta) == "sombra_translucida"
            && _carta.sombra_cooldown > 0 && (_base == "Habilidade" || _base == "Habilidade: Sombra Translúcida")) _motivo = "recarregando";
        if (_motivo != "") _opcoes[i] = _base + " [" + _motivo + "]";
    }
    return _opcoes;
}

function layout_previa_carta(_largura_gui, _altura_gui, _largura_sprite, _altura_sprite, _escala_hud) {
    var _margem = 20;
    var _espaco = 24;
    var _largura_util = _largura_gui - 2 * _margem;
    var _altura_util = _altura_gui - 2 * _margem - 36;
    // O tamanho do HUD não deve mudar a disposição escolhida para a janela.
    var _lado_a_lado = round(_largura_gui * _escala_hud) >= 640 || _largura_gui >= _altura_gui * 1.45;
    var _largura_painel = min(350, _lado_a_lado ? (_largura_util - _espaco) * 0.5 : _largura_util);
    var _altura_painel = _lado_a_lado ? 0 : min(260, _altura_util * 0.45);
    var _limite_largura_carta = _lado_a_lado ? _largura_util - _largura_painel - _espaco : _largura_util;
    var _limite_altura_carta = _lado_a_lado ? _altura_util : _altura_util - _altura_painel - _espaco;
    var _escala_carta = min(350 / _largura_sprite, _limite_largura_carta / _largura_sprite,
        min(520, _limite_altura_carta) / _altura_sprite);
    var _largura_carta = _largura_sprite * _escala_carta;
    var _altura_carta = _altura_sprite * _escala_carta;

    var _meio_x = _largura_gui * 0.5;
    var _meio_y = _margem + _altura_util * 0.5;
    var _carta_x = _meio_x;
    var _carta_y = _meio_y;
    var _painel_x = _meio_x - _largura_painel * 0.5;
    var _painel_y = 0;

    if (_lado_a_lado) {
        var _inicio_x = (_largura_gui - _largura_carta - _espaco - _largura_painel) * 0.5;
        _altura_painel = min(_altura_util, max(340, _altura_carta));
        _carta_x = _inicio_x + _largura_carta * 0.5;
        _painel_x = _inicio_x + _largura_carta + _espaco;
        _painel_y = _meio_y - _altura_painel * 0.5;
    } else {
        var _inicio_y = _meio_y - (_altura_carta + _espaco + _altura_painel) * 0.5;
        _carta_y = _inicio_y + _altura_carta * 0.5;
        _painel_y = _inicio_y + _altura_carta + _espaco;
    }

    return { carta_x: _carta_x, carta_y: _carta_y, escala_carta: _escala_carta,
        painel_x: _painel_x, painel_y: _painel_y, painel_largura: _largura_painel,
        painel_altura: _altura_painel, rodape_y: _painel_y + _altura_painel + 12 };
}

// Quebra em linhas e páginas sem reduzir o texto até ficar ilegível.
function paginar_detalhes_carta(_texto, _largura, _altura, _escala = 0.64) {
    var _linhas = [];
    var _paragrafos = string_split(_texto, "\n");
    for (var p = 0; p < array_length(_paragrafos); p++) {
        var _palavras = string_split(_paragrafos[p], " ");
        var _linha = "";
        for (var i = 0; i < array_length(_palavras); i++) {
            var _nova = _linha == "" ? _palavras[i] : _linha + " " + _palavras[i];
            if (_linha != "" && string_width(_nova) * _escala > _largura) {
                array_push(_linhas, _linha);
                _linha = _palavras[i];
            } else _linha = _nova;
        }
        array_push(_linhas, _linha);
    }
    var _por_pagina = max(1, floor(_altura / (string_height("Ag") * _escala + 4)));
    var _paginas = [];
    for (var l = 0; l < array_length(_linhas); l += _por_pagina) {
        var _pagina = "";
        for (var j = l; j < min(l + _por_pagina, array_length(_linhas)); j++)
            _pagina += (j > l ? "\n" : "") + _linhas[j];
        array_push(_paginas, _pagina);
    }
    return _paginas;
}

function painel_regras_disponivel() {
    if (!instance_exists(obj_controlador)) return false;
    var _c = obj_controlador;
    return (_c.turno == "jogador" || _c.turno == "inimigo")
        && controlador_modal_atual(_c) == "" && _c.carta_preview == noone
        && !(instance_exists(obj_livro) && obj_livro.preview_ativo);
}

// Mesma posição usada pelo desenho e pela área clicável, em qualquer resolução.
function layout_painel_regras() {
    var _w = display_get_gui_width();
    var _base_w = _w * global.escala_interface;
    return { x: _base_w < 900 ? 20 : 270, y: _base_w < 900 ? 115 : 12,
        largura: _base_w < 900 ? _base_w - 40 : _base_w - 490 };
}

function mouse_sobre_painel_regras() {
    if (!painel_regras_disponivel()) return false;
    var _layout = layout_painel_regras();
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    if (point_in_rectangle(_mx, _my, _layout.x, _layout.y, _layout.x + 180, _layout.y + 28)) return true;
    var _p = obj_controlador.painel_regras_animacao;
    if (_p <= 0.005) return false;
    var _suave = _p * _p * (3 - 2 * _p);
    var _y = _layout.y + 36 - (1 - _suave) * 18;
    return point_in_rectangle(_mx, _my, _layout.x, _y, _layout.x + _layout.largura, _y + 139);
}

function atualizar_painel_regras() {
    var _c = obj_controlador;
    var _disponivel = painel_regras_disponivel();
    if (_disponivel) {
        var _layout = layout_painel_regras();
        var _clicou = mouse_check_button_pressed(mb_left)
            && point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0),
                _layout.x, _layout.y, _layout.x + 180, _layout.y + 28);
        if (_clicou || keyboard_check_pressed(vk_tab)) _c.painel_regras_aberto = !_c.painel_regras_aberto;
    }
    var _alvo = _c.painel_regras_aberto && _disponivel ? 1 : 0;
    var _passo = 1 - power(0.80, clamp(delta_time / 16666.67, 0, 3));
    _c.painel_regras_animacao = lerp(_c.painel_regras_animacao, _alvo, _passo);
    if (abs(_c.painel_regras_animacao - _alvo) < 0.005) _c.painel_regras_animacao = _alvo;
}

// Prévia de arrasto: consultas sem gastar recursos nem disparar avisos por frame.
function carta_arrastada_local() {
    if (controlador_modal_atual(obj_controlador) != "" || obj_controlador.carta_preview != noone) return noone;
    for (var i = 0; i < instance_number(obj_carta); i++) {
        var _carta = instance_find(obj_carta, i);
        if (_carta.arrastando && lado_controlado_localmente(_carta.dono)) return _carta;
    }
    return noone;
}

function motivo_bloqueio_arrasto(_carta) {
    var _c = obj_controlador;
    if (_c.turno != _carta.dono) return "Aguarde o seu turno";
    if (_c.rolagens_pendentes > 0) return "Aguarde a rolagem terminar";
    if (primeiro_turno_do_lado(_carta.dono) && categoria_bloqueada_primeiro_turno(_carta.categoria))
        return "Esta categoria está bloqueada no primeiro turno";
    var _usos = resumo_usos_turno(_carta.dono);
    if (_usos != noone) {
        switch (_carta.categoria) {
            case "tropa": if (_usos.troops >= 1) return "Limite de 1 tropa por turno"; break;
            case "item_equipavel": case "item_consumivel": if (_usos.items >= 3) return "Limite de 3 itens por turno"; break;
            case "magica": if (_usos.spells >= 2) return "Limite de 2 magias por turno"; break;
            case "construcao": if (_usos.constructions >= 1) return "Limite de 1 construção por turno"; break;
            case "terreno": if (_usos.terrain >= 1) return "Limite de 1 terreno por turno"; break;
            case "recurso": if (_usos.resourcePlaced >= 1) return "Você já colocou 1 recurso neste turno"; break;
        }
    }
    if (_carta.categoria == "armadilha" && _carta.armadilha_estado != "") return "Esta armadilha já está posicionada";
    if (_carta.categoria == "bencao" || _carta.categoria == "maldicao") {
        var _campo = _carta.categoria == "bencao" ? "bencaos_" + _carta.dono : "maldicoes_" + lado_oposto(_carta.dono);
        if (array_length(variable_instance_get(instance_find(obj_controlador, 0), _campo)) >= 2) return "Limite de 2 efeitos deste tipo atingido";
    }
    if (_c.modo_partida == "online" && variable_global_exists("online_atraso_visual_frames")
        && global.online_atraso_visual_frames > 0) return "Aguarde a animação terminar";
    if (_carta.efeito_tipo == "refracao_temporal" && ultima_carta_jogada(_carta.dono) == noone)
        return "Jogue outra carta antes da Refração Temporal";
    return "";
}

function carta_arrasto_sem_alvo(_carta) {
    if (_carta.categoria == "terreno" || _carta.categoria == "bencao" || _carta.categoria == "maldicao") return true;
    if (_carta.categoria != "magica" && _carta.categoria != "item_consumivel") return false;
    if (array_length(_carta.efeitos_declarativos) > 0 && _carta.alvo_declarativo == "nenhum") return true;
    if (_carta.categoria == "magica") return _carta.efeito_tipo == "dados_manipulados"
        || _carta.efeito_tipo == "refracao_temporal" || _carta.efeito_tipo == "buscar_sangue";
    if (_carta.categoria == "item_consumivel") return string_pos("buscar_", _carta.efeito_tipo) == 1
        || _carta.efeito_tipo == "comprar_cartas" || _carta.efeito_tipo == "revirar_sangue";
    return false;
}

function alvos_previa_arrasto(_carta) {
    var _alvos = [];
    var _categoria = _carta.categoria;
    if (carta_arrasto_sem_alvo(_carta)) return _alvos;
    var _grupo = obj_carta;
    var _raio = 60;
    if (_categoria == "tropa" || _categoria == "armadilha") { _grupo = obj_slot_batalha; _raio = global.CARTA_LARGURA * 0.7; }
    else if (_categoria == "recurso") { _grupo = obj_slot_recurso; _raio = global.CARTA_LARGURA * 0.7; }
    else if (_categoria == "construcao") { _grupo = obj_slot_construcao; _raio = global.CARTA_LARGURA * 0.7; }
    else if (_categoria == "magica") { _raio = 65; if (_carta.efeito_tipo == "bloqueio_recurso") _grupo = obj_recurso; }
    for (var i = 0; i < instance_number(_grupo); i++) {
        var _alvo = instance_find(_grupo, i);
        var _motivo = "";
        if (_grupo == obj_slot_batalha) {
            if (_categoria == "tropa") {
                if (_alvo.posicao != posicao_entrada(_carta.dono)) continue;
                if (buscar_tropa_na_coluna(_alvo.lane, _carta.dono) != noone) _motivo = "Você já possui uma tropa nesta coluna";
                else if (_alvo.ocupado) _motivo = "Esta base está ocupada";
            } else {
                if (_carta.dono == "jogador" && _alvo.posicao < posicao_ataque()) continue;
                if (_carta.dono == "inimigo" && _alvo.posicao > posicao_ataque()) continue;
                if (slot_tem_armadilha(_alvo.lane, _alvo.posicao, _carta.id)) _motivo = "Este espaço já possui uma armadilha";
            }
        } else if (_grupo == obj_slot_recurso || _grupo == obj_slot_construcao) {
            if (_alvo.dono != _carta.dono) continue;
            if (_alvo.ocupado) _motivo = "Este espaço está ocupado";
        } else if (_grupo == obj_carta) {
            if (_alvo.id == _carta.id || !_alvo.travada || _alvo.morrendo) continue;
            if (_categoria == "item_equipavel") {
                if (_alvo.dono != _carta.dono) continue;
                _motivo = motivo_recusa_equipamento(_alvo, _carta.requisito_inteligencia_item);
            } else {
                var _aceita;
                if (_categoria == "magica" && _carta.efeito_tipo == "eutanasia") _aceita = _alvo.vida <= 5;
                else if (_categoria == "item_consumivel" && _carta.efeito_tipo == "aplicar_corrosao") _aceita = true;
                else if (_carta.alvo_declarativo == "qualquer") _aceita = true;
                else if (_carta.alvo_declarativo == "aliado") _aceita = _alvo.dono == _carta.dono;
                else if (_categoria == "item_consumivel" && array_length(_carta.efeitos_declarativos) == 0) _aceita = _alvo.dono == _carta.dono;
                else _aceita = _alvo.dono != _carta.dono;
                if (!_aceita) continue;
            }
        }
        array_push(_alvos, { x: _alvo.x, y: _alvo.y, raio: _raio, motivo: _motivo });
    }
    if (_categoria == "magica" && _carta.efeito_tipo == "bola_fogo") {
        for (var i = 0; i < instance_number(obj_construcao); i++) {
            var _alvo = instance_find(obj_construcao, i);
            if (_alvo.dono == _carta.dono) continue;
            array_push(_alvos, { x: _alvo.x, y: _alvo.y, raio: 65, motivo: "" });
        }
        var _castelo = obter_posicao_castelo(lado_oposto(_carta.dono));
        array_push(_alvos, { x: _castelo.x, y: _castelo.y, raio: 95, motivo: "" });
    }
    return _alvos;
}

function estado_previa_arrasto(_carta) {
    var _motivo = motivo_bloqueio_arrasto(_carta);
    var _pagamento = selecionar_recursos_para_custo(_carta.custo, _carta.dono, _carta.categoria);
    var _alvos = alvos_previa_arrasto(_carta);
    var _perto = noone;
    var _distancia = 999999;
    for (var i = 0; i < array_length(_alvos); i++) {
        var _dist = point_distance(_carta.x, _carta.y, _alvos[i].x, _alvos[i].y);
        if (_dist >= _alvos[i].raio) continue;
        if (_carta.categoria == "item_equipavel" && _perto != noone
            && _perto.motivo == "" && _alvos[i].motivo != "") continue;
        var _prioridade = _carta.categoria == "item_equipavel" && _perto != noone
            && _perto.motivo != "" && _alvos[i].motivo == "";
        if (_dist < _distancia || _prioridade) { _distancia = _dist; _perto = _alvos[i]; }
    }
    var _sem_alvo = carta_arrasto_sem_alvo(_carta);
    var _posicao = _sem_alvo ? point_distance(_carta.x, _carta.y, _carta.arrastar_inicio_x, _carta.arrastar_inicio_y) > 80
        : (_perto != noone && _perto.motivo == "");
    var _na_mao = mouse_na_faixa_da_mao(mouse_y);
    var _pronta = _motivo == "" && _pagamento.sucesso && _posicao && !_na_mao;
    var _dica = _sem_alvo ? "Arraste para fora da mão para usar" : "Escolha um alvo";
    if (_perto != noone && _perto.motivo != "") _dica = _perto.motivo;
    if (_pronta) _dica = "Posição válida — solte para tentar jogar";
    if (_na_mao) _dica = "Soltar aqui apenas reorganiza a mão";
    if (_motivo != "") _dica = _motivo;
    return { pagamento: _pagamento, alvos: _alvos, perto: _perto, motivo: _motivo, dica: _dica, pronta: _pronta };
}

function desenhar_ajuda_arrasto_gui() {
    var _carta = carta_arrastada_local();
    if (_carta == noone) return;
    var _estado = estado_previa_arrasto(_carta);
    var _custo = ajustar_custo_por_terreno(_carta.custo, _carta.categoria);
    var _texto_custo = array_length(_custo) == 0 ? "Sem custo" : texto_custo_exibicao(_custo);
    var _dica = _estado.dica;
    if (_estado.motivo == "" && !_estado.pagamento.sucesso) {
        _dica = "Falta: ";
        for (var i = 0; i < array_length(_estado.pagamento.faltas); i++)
            _dica += (i > 0 ? ", " : "") + _estado.pagamento.faltas[i];
    }

    draw_set_font(Fontenil);
    var _largura = min(320, display_get_gui_width() - 24,
        ceil(max(string_width(_texto_custo) * 0.60, string_width(_dica) * 0.50)) + 20);
    var _x = clamp(device_mouse_x_to_gui(0) + 18, 12, display_get_gui_width() - _largura - 12);
    var _y = clamp(device_mouse_y_to_gui(0) - 64, 12, max(12, display_get_gui_height() - 64));
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_alpha(0.90); draw_set_color(make_color_rgb(15, 19, 27));
    draw_roundrect(_x, _y, _x + _largura, _y + 48, false);
    draw_set_alpha(1); draw_set_color(c_white);
    desenhar_texto_ajustado_ui(_texto_custo, _x + 10, _y + 5, _largura - 20, 0.60);
    draw_set_color(_estado.motivo != "" || !_estado.pagamento.sucesso ? c_yellow : c_silver);
    desenhar_texto_ajustado_ui(_dica, _x + 10, _y + 25, _largura - 20, 0.50);
    draw_set_color(c_white);
}

function sigla_condicao(_tipo) {
    switch (_tipo) {
        case "queimado": return "QU"; case "envenenado": return "VE";
        case "paralisado": return "PA"; case "congelado": return "GE";
        case "confusao": return "CF"; case "adormecido": return "SO";
        case "berserker": return "BE"; case "loucura": return "LO";
        case "sangrando": return "SA"; case "corrosao": return "CO";
        case "apodrecer": return "AP"; case "regeneracao": return "RE";
        case "eletrocutado": return "EL";
    }
    return "?";
}

function desenhar_condicoes_compactas(_carta, _x, _y, _escala) {
    var _total = array_length(_carta.condicoes);
    if (_total == 0 || _carta.morrendo) return;
    var _topo = _y - sprite_get_height(_carta.sprite_index) * _escala * 0.5 - 9;
    draw_set_font(Fontenil); draw_set_halign(fa_center); draw_set_valign(fa_middle);
    for (var i = 0; i < min(9, _total); i++) {
        var _estado = _carta.condicoes[i];
        var _config = obter_config_condicao(_estado.tipo);
        var _bx = _x + ((i mod 3) - 1) * 27;
        var _by = _topo - floor(i / 3) * 15;
        draw_set_alpha(0.94); draw_set_color(make_color_rgb(14, 18, 24));
        draw_roundrect(_bx - 13, _by - 6, _bx + 13, _by + 6, false);
        draw_set_alpha(1); draw_set_color(_config.cor);
        draw_roundrect(_bx - 13, _by - 6, _bx + 13, _by + 6, true);
        var _texto = sigla_condicao(_estado.tipo) + (_estado.turnos > 0 ? string(_estado.turnos) : "-");
        if (i == 8 && _total > 9) _texto = "+" + string(_total - 8);
        draw_text_transformed(_bx, _by, _texto, 0.28, 0.28, 0);
    }
    draw_set_alpha(1); draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top);
}

function disponibilidade_carta_mao(_carta) {
    var _motivo = motivo_bloqueio_arrasto(_carta);
    if (_motivo != "") return { texto: "BLOQUEADA", motivo: _motivo, estado: 0 };
    var _pagamento = selecionar_recursos_para_custo(_carta.custo, _carta.dono, _carta.categoria);
    if (!_pagamento.sucesso) {
        _motivo = "Falta: ";
        for (var i = 0; i < array_length(_pagamento.faltas); i++) _motivo += (i > 0 ? ", " : "") + _pagamento.faltas[i];
        return { texto: "SEM RECURSO", motivo: _motivo, estado: 1 };
    }
    return { texto: "CUSTO OK", motivo: "Custo disponível. A jogada ainda depende do alvo e das regras da carta.", estado: 2 };
}

function layout_historico() {
    return { x: 14, y: 248, largura: min(390, display_get_gui_width() - 28),
        altura: min(340, display_get_gui_height() - 270) };
}

function mouse_sobre_historico() {
    if (!instance_exists(obj_controlador) || !obj_controlador.ui_modal.historico_aberto
        || controlador_modal_atual(obj_controlador) != "" || obj_controlador.carta_preview != noone) return false;
    var _l = layout_historico();
    return point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _l.x, _l.y, _l.x + _l.largura, _l.y + _l.altura);
}

function desenhar_historico_legivel() {
    var _c = obj_controlador;
    var _l = layout_historico();
    var _texto = "";
    for (var i = array_length(_c.historico_combate) - 1; i >= 0; i--)
        _texto += (_texto == "" ? "" : "\n\n") + _c.historico_combate[i];
    if (_texto == "") _texto = "As ações da partida aparecerão aqui.";
    draw_set_font(Fontenil); draw_set_halign(fa_left); draw_set_valign(fa_top);
    var _paginas = paginar_detalhes_carta(_texto, _l.largura - 24, _l.altura - 75, 0.60);
    _c.historico_total_paginas = max(1, array_length(_paginas));
    _c.historico_pagina = clamp(_c.historico_pagina, 0, _c.historico_total_paginas - 1);
    draw_set_alpha(0.96); draw_set_color(make_color_rgb(15, 19, 27));
    draw_roundrect(_l.x, _l.y, _l.x + _l.largura, _l.y + _l.altura, false);
    draw_set_alpha(1); draw_set_color(c_yellow);
    desenhar_texto_ajustado_ui("HISTÓRICO — MAIS RECENTES PRIMEIRO", _l.x + 12, _l.y + 9, _l.largura - 24, 0.58);
    draw_set_color(c_white);
    draw_text_transformed(_l.x + 12, _l.y + 39, _paginas[_c.historico_pagina], 0.60, 0.60, 0);
    draw_set_color(c_silver);
    desenhar_texto_ajustado_ui("Página " + string(_c.historico_pagina + 1) + "/" + string(_c.historico_total_paginas)
        + " — roda do mouse para navegar", _l.x + 12, _l.y + _l.altura - 25, _l.largura - 24, 0.48);
    draw_set_color(c_white);
}

// Cenários aditivos para depuração local; não alteram o deck salvo nem o online.
function debug_preparar_cenario(_opcao) {
    var _c = obj_controlador;
    if (!global.DEBUG_COMBATE || _c.modo_partida == "online") return false;
    var _lado = _c.turno;
    if ((_lado != "jogador" && _lado != "inimigo") || !lado_controlado_localmente(_lado)
        || controlador_modal_atual(_c) != "" || _c.rolagens_pendentes > 0) return false;
    if (_opcao == 1) {
        var _cartas = [criar_dados_esquilo, criar_dados_item_espada, criar_dados_item_escudo,
            criar_dados_item_pocao, criar_dados_magica_bola_fogo, criar_dados_magica_veneno];
        for (var i = 0; i < array_length(_cartas); i++)
            comprar_carta_do_deck_por_funcao(_cartas[i], room_width / 2, _c.mao_y, _lado);
        debug_encher_recursos(_lado);
    } else if (_opcao == 2 || _opcao == 3) {
        var _slots = [];
        for (var i = 0; i < instance_number(obj_slot_batalha); i++) {
            var _slot = instance_find(obj_slot_batalha, i);
            if (_slot.posicao == posicao_entrada(_lado) && !_slot.ocupado
                && buscar_tropa_na_coluna(_slot.lane, _lado) == noone) array_push(_slots, _slot);
        }
        var _necessarios = _opcao == 2 ? 1 : 2;
        if (array_length(_slots) < _necessarios) {
            mostrar_aviso_regra("O cenário precisa de " + string(_necessarios) + " coluna(s) livre(s)");
            return false;
        }
        for (var i = 0; i < _necessarios; i++) {
            var _dados = criar_dados_lobo();
            _dados.vida = 20;
            var _tropa = criar_tropa_no_slot(_dados, _slots[i], _lado);
            _tropa.funcao_dados_origem = criar_dados_lobo;
            _tropa.dados_carta = _dados;
            _tropa.turnos_no_campo = 1;
            if (_opcao == 2) {
                aplicar_condicao(_tropa, "envenenado", -1, 1);
                aplicar_condicao(_tropa, "queimado", 3, 2);
                aplicar_condicao(_tropa, "paralisado", 2, 0);
            } else {
                var _funcao_item = i == 0 ? criar_dados_item_espada : criar_dados_item_escudo;
                var _item = _funcao_item();
                var _sprite_item = _item.sprite_carta == noone ? spr_carta_placeholder : _item.sprite_carta;
                equipar_item_dados(_tropa, criar_dados_item_equipado(_item.nome, _sprite_item,
                    _funcao_item, _item.bonus_mod_dano, _item.bonus_defesa, 0, 0));
            }
        }
    } else if (_opcao == 4) {
        if (variable_struct_get(_c.debug_montes_guardados, _lado) != noone) {
            mostrar_aviso_regra("Já existe um baralho guardado; restaure-o primeiro"); return false;
        }
        var _monte = _lado == "jogador" ? _c.monte : _c.monte_inimigo;
        var _guardado = [];
        for (var i = 0; i < array_length(_monte); i++) array_push(_guardado, _monte[i]);
        variable_struct_set(_c.debug_montes_guardados, _lado, _guardado);
        if (_lado == "jogador") _c.monte = []; else _c.monte_inimigo = [];
    } else if (_opcao == 5) {
        var _guardado = variable_struct_get(_c.debug_montes_guardados, _lado);
        if (_guardado == noone) { mostrar_aviso_regra("Nenhum baralho de teste para restaurar"); return false; }
        var _monte = _lado == "jogador" ? _c.monte : _c.monte_inimigo;
        for (var i = 0; i < array_length(_guardado); i++) array_push(_monte, _guardado[i]);
        if (_lado == "jogador") _c.monte = _monte; else _c.monte_inimigo = _monte;
        variable_struct_set(_c.debug_montes_guardados, _lado, noone);
    } else return false;
    organizar_mao();
    debug_combate("CENÁRIO DE TESTE " + string(_opcao) + " preparado para " + nome_jogador_lado(_lado) + ".");
    mostrar_feedback("CENÁRIO LOCAL DE TESTE PREPARADO", room_width / 2, room_height / 2, c_aqua, 90);
    return true;
}

function debug_abrir_cenarios() {
    if (!global.DEBUG_COMBATE || obj_controlador.modo_partida == "online") return;
    var _tela_cheia = window_get_fullscreen();
    if (_tela_cheia) window_set_fullscreen(false);
    var _opcao = get_integer("CENÁRIOS LOCAIS — limites do turno são mantidos.\n"
        + "1: adicionar cartas e recursos para testar custos/alvos\n"
        + "2: criar tropa com Veneno + Queimado + Paralisado\n"
        + "3: criar duas tropas equipadas para testar trocas\n"
        + "4: guardar e esvaziar o baralho do jogador ativo\n"
        + "5: restaurar o baralho guardado\n0: cancelar", 0);
    if (_tela_cheia) window_set_fullscreen(true);
    if (_opcao != 0) debug_preparar_cenario(_opcao);
}

// A sombra permanece na mesa e se concentra quando a peça pousa.
function desenhar_sombra_mesa(_x, _y, _largura, _altura_relativa, _alpha = 1) {
    var _altura = clamp(_altura_relativa, 0, 1);
    var _meia_largura = _largura * lerp(0.39, 0.53, _altura);
    var _meia_altura = _largura * lerp(0.085, 0.14, _altura);
    draw_set_color(c_black);
    draw_set_alpha(_alpha * lerp(0.31, 0.11, _altura));
    draw_ellipse(_x - _meia_largura, _y - _meia_altura, _x + _meia_largura, _y + _meia_altura, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

function desenhar_animacoes_cartas_mesa() {
    var _animacoes = obj_controlador.animacoes_item;
    for (var i = 0; i < array_length(_animacoes); i++) {
        var _anim = _animacoes[i];
        var _p = clamp(_anim.timer / _anim.duracao, 0, 1);
        if (_anim.tipo == "armadilha") {
            var _virada = clamp(_anim.timer / 12, 0, 1);
            var _sprite = _virada < 0.5 ? spr_deck : _anim.sprite;
            var _esc = 51 / sprite_get_width(_sprite);
            draw_sprite_ext(_sprite, 0, _anim.destino_x, _anim.destino_y - 9 * sin(_p * pi),
                _esc * max(0.05, abs(cos(_virada * pi))), _esc, 0, c_white, min(1, (1 - _p) * 4));
        } else {
            // Equipamentos são desenhados no Draw da tropa, atrás dela.
            if (instance_exists(_anim.tropa)) continue;
            var _x_final = _anim.destino_x;
            var _y_final = _anim.destino_y;
            if (instance_exists(_anim.tropa)) {
                _x_final = _anim.tropa.x;
                _y_final = _anim.tropa.y - 15;
            }
            var _deslize = _p * _p * (3 - 2 * _p);
            var _x = lerp(_anim.origem_x, _x_final, _deslize);
            var _y = lerp(_anim.origem_y, _y_final, _deslize) - sin(_p * pi) * 13;
            var _esc = lerp(64, 76, _deslize) / sprite_get_width(_anim.sprite);
            // Some no encaixe para revelar a carta que já está na pilha.
            var _alpha = instance_exists(_anim.tropa) ? min(1, (1 - _p) * 5) : min(1, (1 - _p) * 3);
            draw_sprite_ext(_anim.sprite, 0, _x, _y, _esc, _esc,
                -9 * sin(_p * pi), merge_color(c_white, _anim.cor, 0.10 * sin(_p * pi)), _alpha);
        }
    }
}

// Shared by rendering and hit testing, in camera/world coordinates.
function layout_menu_tropa(_carta, _quantidade) {
    var _cam = view_camera[0];
    var _vx = camera_get_view_x(_cam), _vy = camera_get_view_y(_cam);
    var _vw = camera_get_view_width(_cam), _vh = camera_get_view_height(_cam);
    var _w = min(175, _vw - 48), _gap = 4;
    var _h = min(23, (_vh - 48 - max(0, _quantidade - 1) * _gap) / max(1, _quantidade));
    var _total = _quantidade * _h + max(0, _quantidade - 1) * _gap;
    var _x = _carta.x + global.CARTA_LARGURA * 0.5 + 8;
    // Mantém o menu à direita; junto à borda, apenas limita o deslocamento.
    return { x: clamp(_x, _vx + 12, _vx + _vw - _w - 24),
        y: clamp(_carta.y - _total * 0.5, _vy + 12, _vy + _vh - _total - 16),
        largura: _w, altura: _h, espaco: _gap, total: _total };
}
