// =============================================================================
// obj_controlador — Step Event
// =============================================================================

#region Watchdog de segurança
// Se rolagens_pendentes ficar travado (algum dado/moeda não decrementou por bug),
// força o reset depois de 5 segundos pra nunca deixar o "Passar Turno" travado pra sempre.
if (rolagens_pendentes > 0) {
    rolagens_pendentes_timer += 1;
    if (rolagens_pendentes_timer > 300) {
        show_debug_message("AVISO: rolagens_pendentes travado em " + string(rolagens_pendentes) + ", forçando reset.");
        rolagens_pendentes = 0;
        rolagens_pendentes_timer = 0;
    }
} else {
    rolagens_pendentes_timer = 0;
}
#endregion

// Enquanto a IA joga, o turno é processado em etapas e o jogador não pode interagir.
if (turno == "inimigo" && ia_ativa) {
    processar_turno_ia();
    exit;
}

#region Atalhos de teclado (debug/teste)
if (keyboard_check_pressed(vk_escape)) {
    var _fechou_algum_preview = false;

    // Preview de carta ampliada (botão direito numa carta)
    if (carta_preview != noone) {
        carta_preview = noone;
        _fechou_algum_preview = true;
    }

    // Preview do livro de regras
    if (instance_exists(obj_livro) && obj_livro.preview_ativo) {
        obj_livro.preview_ativo = false;
        _fechou_algum_preview = true;
    }

    // Se nenhum preview estava aberto, ESC fecha o jogo normalmente
    if (!_fechou_algum_preview) {
        game_end();
    }
}
if (keyboard_check_pressed(ord("R")) && global.DEBUG_COMBATE) {
    room_restart();
}

if (keyboard_check_pressed(ord("K")) && global.DEBUG_COMBATE) {
    vida_inimigo = 0;
}

// NOVO: pede o nome de uma carta e coloca ela direto na mão (sem gastar do monte).
if (keyboard_check_pressed(ord("V")) && global.DEBUG_COMBATE) {
    var _estava_fullscreen = window_get_fullscreen();
    if (_estava_fullscreen) {
        window_set_fullscreen(false);
    }

    var _nome_digitado = get_string("DEBUG - Nome da carta (ou parte dele):", "");

    if (_estava_fullscreen) {
        window_set_fullscreen(true);
    }

    if (_nome_digitado != "") {
        debug_adicionar_carta_a_mao(_nome_digitado);
    }
}

// NOVO: enche os recursos do jogador instantaneamente.
if (keyboard_check_pressed(ord("F")) && global.DEBUG_COMBATE) {
    debug_encher_recursos("jogador");
}

if (keyboard_check_pressed(ord("C")) && global.DEBUG_COMBATE) {
    var _quantidade_debug = 10;
    for (var i = 0; i < _quantidade_debug; i++) {
        if (array_length(monte) == 0) break;
        comprar_carta_do_deck(obj_deck.x, obj_deck.y);
    }
    debug_combate("DEBUG: comprou " + string(_quantidade_debug) + " cartas pro jogador.");
}

if (keyboard_check_pressed(ord("M"))&& global.DEBUG_COMBATE) {
    jogar_moeda_visual(mao_x_centro, mao_y, room_width / 2, room_height / 2, noone);
}
#endregion

if (vida_jogador <= 0) exit; // jogo acabou, para de processar interação

#region Preview ampliado (botão direito numa carta da mão)
// detecta hover sobre carta travada no campo (pro preview funcionar lá também)
var _hover_campo = noone;
with (obj_carta) {
    if (!travada) continue;
    var _meia_largura = sprite_width / 2;
    var _meia_altura = sprite_height / 2;
    if (point_in_rectangle(mouse_x, mouse_y, x - _meia_largura, y - _meia_altura, x + _meia_largura, y + _meia_altura)) {
        _hover_campo = id;
        break;
    }
}

if (mouse_check_button_pressed(mb_right)) {
    if (carta_preview == noone) {
        var _alvo_preview = (hover_atual != noone) ? hover_atual : _hover_campo;
        if (_alvo_preview != noone) {
            carta_preview = _alvo_preview;
        }
    } else {
        carta_preview = noone;
    }
}

// enquanto o preview está ativo, ignora todo o resto do Step (hover, clique, arrasto, menu)
if (carta_preview != noone) {
    if (!instance_exists(carta_preview)) {
        carta_preview = noone;
    }
    exit;
}
#endregion

#region Hover e clique nas cartas da mão
var _total = array_length(mao);
var _melhor_carta = noone;
var _menor_distancia = 999999;

for (var i = 0; i < _total; i++) {
    var _carta = mao[i];
    if (!instance_exists(_carta)) continue;
    if (_carta.arrastando) continue;
    if (!_carta.esta_na_mao) continue;
    if (_carta.travada) continue;

    var _dentro_y = (mouse_y >= _carta.y - global.CARTA_ALTURA/2 - 40)
                  && (mouse_y <= _carta.y + global.CARTA_ALTURA/2);

    if (_dentro_y) {
        var _dist_x = abs(mouse_x - _carta.x);
        if (_dist_x < global.CARTA_LARGURA/2 && _dist_x < _menor_distancia) {
            _menor_distancia = _dist_x;
            _melhor_carta = _carta;
        }
    }
}

hover_atual = _melhor_carta;

for (var i = 0; i < _total; i++) {
    var _carta = mao[i];
    if (!instance_exists(_carta)) continue;
    _carta.hover_ativo_externo = (_carta == hover_atual);
}

if (mouse_check_button_pressed(mb_left)) {
    if (hover_atual != noone && instance_exists(hover_atual) && hover_atual.armadilha_estado == "pronta") {
        ativar_armadilha(hover_atual.id);
    } else if (hover_atual != noone && instance_exists(hover_atual) && !hover_atual.travada) {
        with (hover_atual) {
            arrastando = true;
            esta_na_mao = false;
            rotacao_atual = 0;
            escala_atual = 1;
            y_offset_atual = 0;
			arrastar_inicio_x = x;
			arrastar_inicio_y = y;

            if (slot_atual != noone) {
                slot_atual.ocupado = false;
                slot_atual.carta_atual = noone;
                slot_atual = noone;
            }
        }
    }
}
#endregion

#region Scroll horizontal da mão (perto das bordas da tela, só quando o mouse está sobre a mão)
if (mao_scroll_max > 0) {
    var _mouse_gui_x = device_mouse_x_to_gui(0);
    var _zona_scroll_h = 100;
    var _velocidade_scroll_h = 15;

    // só ativa se o mouse estiver na altura da mão (não em qualquer lugar da tela)
    var _dentro_faixa_mao = (mouse_y >= mao_y - global.CARTA_ALTURA/2 - 40) 
                          && (mouse_y <= mao_y + global.CARTA_ALTURA/2 + 40);

    if (_dentro_faixa_mao) {
        if (_mouse_gui_x < _zona_scroll_h) {
            mao_scroll_offset_alvo += _velocidade_scroll_h;
        } else if (_mouse_gui_x > (display_get_gui_width() - _zona_scroll_h)) {
            mao_scroll_offset_alvo -= _velocidade_scroll_h;
        }
    }

    mao_scroll_offset_alvo = clamp(mao_scroll_offset_alvo, -mao_scroll_max, mao_scroll_max);
}

mao_scroll_offset += (mao_scroll_offset_alvo - mao_scroll_offset) * 0.15;
#endregion

#region Menu de ação (animação + clique nas opções)
var _alvo_escala_menu = (carta_menu_aberto != noone && instance_exists(carta_menu_aberto)) ? 1 : 0;
menu_escala += (_alvo_escala_menu - menu_escala) * 0.25;
if (_alvo_escala_menu == 0 && menu_escala < 0.02) {
    menu_escala = 0;
}

opcao_hover_index = -1;

if (carta_menu_aberto != noone && instance_exists(carta_menu_aberto) && menu_escala > 0.9) {
    var _carta = carta_menu_aberto;
    var _opcoes = obter_opcoes_menu(_carta);
    var _n = array_length(_opcoes);

    var _largura_opcao = 100;
    var _altura_opcao = 20;
    var _espaco_opcao = 6;
    var _altura_total = _n * _altura_opcao + (_n - 1) * _espaco_opcao;

    var _base_x = _carta.x + (global.CARTA_LARGURA * 0.5);
    var _base_y = _carta.y - _altura_total/2;

    for (var i = 0; i < _n; i++) {
        var _opt_y = _base_y + i * (_altura_opcao + _espaco_opcao);
        if (mouse_x > _base_x && mouse_x < _base_x + _largura_opcao && mouse_y > _opt_y && mouse_y < _opt_y + _altura_opcao) {
            opcao_hover_index = i;

            if (mouse_check_button_pressed(mb_left)) {
                executar_opcao_menu(_carta, _opcoes[i]);
                carta_menu_aberto = noone;
            }
            break;
        }
    }
}
#endregion

#region Tooltip do nome da habilidade (hover na opção "Habilidade")
var _mostrar_tooltip = false;
if (carta_menu_aberto != noone && opcao_hover_index != -1) {
    var _opcoes_atuais = obter_opcoes_menu(carta_menu_aberto);
    if (opcao_hover_index < array_length(_opcoes_atuais) && _opcoes_atuais[opcao_hover_index] == "Habilidade") {
        _mostrar_tooltip = true;
    }
}

var _alvo_tooltip = _mostrar_tooltip ? 1 : 0;
tooltip_escala += (_alvo_tooltip - tooltip_escala) * 0.3;
if (_alvo_tooltip == 0 && tooltip_escala < 0.02) {
    tooltip_escala = 0;
}
#endregion
