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
    if (tem_habilidade_ativa(_carta) != noone) {
        array_push(_opcoes, _carta.habilidade_usada_este_turno ? "Habilidade [já usada]" : "Habilidade");
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
    var _opcoes = [];
    array_push(_opcoes, _carta.troca_item_usada_este_turno ? "Remover Item [já usado]" : "Remover Item");
    array_push(_opcoes, _carta.troca_item_usada_este_turno ? "Transferir Item [já usado]" : "Transferir Item");
    array_push(_opcoes, "Voltar");
    return _opcoes;
}

function obter_opcoes_menu(_carta) {
    if (!instance_exists(_carta)) return [];
    switch (obj_controlador.menu_submenu) {
        case "ataque": return obter_opcoes_menu_ataque(_carta);
        case "movimento": return obter_opcoes_menu_movimento(_carta);
        case "itens": return obter_opcoes_menu_itens(_carta);
    }
    return obter_opcoes_menu_principal(_carta);
}

function categoria_bloqueada_primeiro_turno(_categoria) {
    return (_categoria == "item_equipavel" 
         || _categoria == "item_consumivel" 
         || _categoria == "magica" 
         || _categoria == "terreno");
}

function executar_opcao_menu(_carta, _opcao) {
    if (!instance_exists(_carta)) return;
    if (obj_controlador.turno != _carta.dono || (obj_controlador.modo_partida == "online" && !lado_controlado_localmente(_carta.dono))) {
        mostrar_aviso_regra("Você pode inspecionar; ações ficam para o seu turno", _carta.x, _carta.y);
        return;
    }
    if (obj_controlador.rolagens_pendentes > 0) {
        mostrar_aviso_regra("Aguarde a rolagem terminar", _carta.x, _carta.y);
        return;
    }
    if (_carta.condicao == "adormecido" || _carta.condicao == "loucura") {
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
            var _habilidade_online = tem_habilidade_ativa(_carta);
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
            usar_habilidade(_carta);
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
    ini_close();
    if (window_get_fullscreen() != _tela_cheia) window_set_fullscreen(_tela_cheia);
    aplicar_config_audio();
}

function salvar_configuracoes() {
    ini_open("kartha_config.ini");
    ini_write_real("audio", "musica", global.volume_musica);
    ini_write_real("audio", "efeitos", global.volume_efeitos);
    ini_write_real("video", "tela_cheia", window_get_fullscreen() ? 1 : 0);
    ini_close();
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
