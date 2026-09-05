#region Tooltip compacto dos efeitos ativos
// Os espaços são desenhados pelo obj_tabuleiro, atrás das cartas. Aqui fica apenas o tooltip.
var _tooltip_efeito_entrada = noone;
var _tooltip_efeito_categoria = "";
var _tooltip_efeito_dono = "";
var _tooltip_efeito_largura_slot = 42;
var _tooltip_efeito_altura_slot = 58;
var _tooltip_efeito_espaco_slot = 4;

for (var _tooltip_lado = 0; _tooltip_lado < 2; _tooltip_lado++) {
    var _tooltip_dono_atual = (_tooltip_lado == 0) ? "jogador" : "inimigo";
    var _tooltip_painel_x = (_tooltip_lado == 0) ? 302 : 678;
    var _tooltip_painel_y = (_tooltip_lado == 0) ? 487 : 225;
    var _tooltip_bencaos = (_tooltip_lado == 0) ? bencaos_jogador : bencaos_inimigo;
    var _tooltip_maldicoes = (_tooltip_lado == 0) ? maldicoes_jogador : maldicoes_inimigo;

    for (var _tooltip_slot = 0; _tooltip_slot < 4; _tooltip_slot++) {
        var _tooltip_categoria_atual = (_tooltip_slot < 2) ? "bencao" : "maldicao";
        var _tooltip_indice = _tooltip_slot mod 2;
        var _tooltip_lista = (_tooltip_categoria_atual == "bencao") ? _tooltip_bencaos : _tooltip_maldicoes;
        if (_tooltip_indice >= array_length(_tooltip_lista)) continue;

        var _tooltip_x1_slot = _tooltip_painel_x + _tooltip_slot * (_tooltip_efeito_largura_slot + _tooltip_efeito_espaco_slot);
        var _tooltip_y1_slot = _tooltip_painel_y - _tooltip_efeito_altura_slot / 2;
        if (point_in_rectangle(mouse_x, mouse_y, _tooltip_x1_slot, _tooltip_y1_slot,
            _tooltip_x1_slot + _tooltip_efeito_largura_slot, _tooltip_y1_slot + _tooltip_efeito_altura_slot)) {
            _tooltip_efeito_entrada = _tooltip_lista[_tooltip_indice];
            _tooltip_efeito_categoria = _tooltip_categoria_atual;
            _tooltip_efeito_dono = _tooltip_dono_atual;
        }
    }
}

if (_tooltip_efeito_entrada != noone) {
    var _tooltip_efeito_nome = is_struct(_tooltip_efeito_entrada)
        ? _tooltip_efeito_entrada.nome
        : ((_tooltip_efeito_categoria == "bencao") ? "Bênção ativa" : "Maldição ativa");
    var _tooltip_efeito_codigo = is_struct(_tooltip_efeito_entrada)
        ? _tooltip_efeito_entrada.efeito : _tooltip_efeito_entrada;
    var _tooltip_efeito_descricao = "Efeito passivo ativo.";
    switch (_tooltip_efeito_codigo) {
        case "cura_ao_morrer":
            _tooltip_efeito_descricao = "Tropa morreu: recupera 1 de vida.";
            break;
        case "perde_vida_ao_morrer":
            _tooltip_efeito_descricao = "Morta pelo oponente: perde 1 de vida.";
            break;
    }

    var _tooltip_efeito_x1 = (_tooltip_efeito_dono == "jogador") ? 302 : 678;
    var _tooltip_efeito_y1 = (_tooltip_efeito_dono == "jogador") ? 420 : 261;
    var _tooltip_efeito_x2 = _tooltip_efeito_x1 + 170;
    var _tooltip_efeito_y2 = _tooltip_efeito_y1 + 36;
    var _tooltip_efeito_cor = (_tooltip_efeito_categoria == "bencao")
        ? make_color_rgb(235, 195, 65) : make_color_rgb(190, 45, 70);

    draw_set_alpha(0.92);
    draw_set_color(c_black);
    draw_roundrect(_tooltip_efeito_x1, _tooltip_efeito_y1, _tooltip_efeito_x2, _tooltip_efeito_y2, false);
    draw_set_alpha(1);
    draw_set_color(_tooltip_efeito_cor);
    draw_roundrect(_tooltip_efeito_x1, _tooltip_efeito_y1, _tooltip_efeito_x2, _tooltip_efeito_y2, true);
    draw_set_font(Fontenil);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text_transformed(_tooltip_efeito_x1 + 6, _tooltip_efeito_y1 + 4,
        string_copy(_tooltip_efeito_nome, 1, 28), 0.34, 0.34, 0);
    draw_set_color(c_white);
    draw_text_transformed(_tooltip_efeito_x1 + 6, _tooltip_efeito_y1 + 18,
        _tooltip_efeito_descricao, 0.27, 0.27, 0);
}

draw_set_font(-1);
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
#endregion

#region Efeitos temporários de dados
draw_set_font(Fontenil);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
if (dados_manipulados_usos_jogador > 0) {
    draw_set_color(c_aqua);
    draw_text_transformed(302, 520, "D4 = " + string(dados_manipulados_valor_jogador)
        + "  •  " + string(dados_manipulados_usos_jogador) + " uso(s)", 0.34, 0.34, 0);
}
if (dados_manipulados_usos_inimigo > 0) {
    draw_set_color(c_purple);
    draw_text_transformed(678, 258, "DADOS MANIPULADOS  •  "
        + string(dados_manipulados_usos_inimigo) + " uso(s)", 0.34, 0.34, 0);
}
draw_set_font(-1);
draw_set_color(c_white);
#endregion

#region Indicadores da tropa selecionada
if (tropa_selecionada != noone && instance_exists(tropa_selecionada)) {
    var _selecionada = tropa_selecionada;
    var _pulso_selecao = 0.65 + sin(current_time / 110) * 0.25;
    var _meia_largura_selecao = global.CARTA_LARGURA * 0.28;
    var _meia_altura_selecao = global.CARTA_ALTURA * 0.28;

    // Moldura, nunca preenchimento: o círculo preenchido escondia a própria carta.
    draw_set_alpha(_pulso_selecao);
    draw_set_color(c_yellow);
    draw_roundrect(_selecionada.x - _meia_largura_selecao, _selecionada.y - _meia_altura_selecao,
        _selecionada.x + _meia_largura_selecao, _selecionada.y + _meia_altura_selecao, true);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_roundrect(_selecionada.x - _meia_largura_selecao - 2, _selecionada.y - _meia_altura_selecao - 2,
        _selecionada.x + _meia_largura_selecao + 2, _selecionada.y + _meia_altura_selecao + 2, true);

    var _posicao_frente = _selecionada.posicao_atual + direcao_avanco(_selecionada.dono);
    var _slot_frente = buscar_slot(_selecionada.lane_atual, _posicao_frente);
    var _na_posicao_assalto = _selecionada.posicao_atual == posicao_assalto(_selecionada.dono);
    var _pode_mover_visual = !_selecionada.moveu_este_turno && _selecionada.turnos_no_campo >= 1 && !_na_posicao_assalto;
    var _pode_atacar_visual = !_selecionada.atacou_este_turno && !(primeiro_turno_jogador);

    if (_slot_frente != noone) {
        var _cor_alvo = c_gray;
        var _texto_alvo = "BLOQUEADO";
        if (_slot_frente.ocupado && _slot_frente.carta_atual.dono != _selecionada.dono && _pode_atacar_visual) {
            _cor_alvo = c_red;
            _texto_alvo = "ATACAR";
        } else if (!_slot_frente.ocupado && _na_posicao_assalto && _pode_atacar_visual) {
            _cor_alvo = c_red;
            _texto_alvo = "ATACAR CASTELO";
        } else if (!_slot_frente.ocupado && _pode_mover_visual) {
            _cor_alvo = c_lime;
            _texto_alvo = (_selecionada.posicao_atual == posicao_ataque()) ? "AVANÇAR PARA ASSALTO" : "MOVER";
        }

        draw_set_alpha(0.25 + _pulso_selecao * 0.25);
        draw_set_color(_cor_alvo);
        draw_circle(_slot_frente.x, _slot_frente.y, 33, false);
        draw_set_alpha(1);
        draw_set_halign(fa_center);
        draw_set_valign(fa_bottom);
        draw_set_color(_cor_alvo);
        draw_text_transformed(_slot_frente.x, _slot_frente.y - 38, _texto_alvo, 0.4, 0.4, 0);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }
    draw_set_color(c_white);
}
#endregion

#region Escolhas de alvo
if (mitose_selecao_ativa) {
    draw_set_halign(fa_center); draw_set_valign(fa_bottom); draw_set_color(c_lime);
    draw_text_transformed(room_width / 2, room_height / 2, "MITOSE: escolha a casa do segundo Slimet", 0.45, 0.45, 0);
    for (var _mdi = 0; _mdi < array_length(mitose_slots_pendentes); _mdi++) {
        var _mds = mitose_slots_pendentes[_mdi];
        if (_mds != noone && !_mds.ocupado) {
            draw_set_alpha(0.4); draw_set_color(c_lime); draw_circle(_mds.x, _mds.y, 34, false); draw_set_alpha(1);
        }
    }
}
if (digestao_selecao_ativa && instance_exists(digestao_origem)) {
    draw_set_halign(fa_center); draw_set_valign(fa_bottom); draw_set_color(c_lime);
    draw_text_transformed(digestao_origem.x, digestao_origem.y - 55, "DIGESTÃO: escolha o alvo", 0.42, 0.42, 0);
    with (obj_carta) if (alvo_valido_digestao(other.digestao_origem, id)) {
        draw_set_alpha(0.35); draw_set_color(c_lime); draw_circle(x, y, 34, false); draw_set_alpha(1);
    }
}
if (troca_item_selecao_ativa && instance_exists(troca_item_origem)) {
    draw_set_halign(fa_center); draw_set_valign(fa_bottom); draw_set_color(c_aqua);
    draw_text_transformed(troca_item_origem.x, troca_item_origem.y - 55, "TRANSFERIR: escolha a tropa", 0.42, 0.42, 0);
    with (obj_carta) if (id != other.troca_item_origem && travada && dono == "jogador" && mochila > 0 && !troca_item_usada_este_turno) {
        draw_set_alpha(0.35); draw_set_color(c_aqua); draw_circle(x, y, 34, false); draw_set_alpha(1);
    }
}
draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_color(c_white); draw_set_alpha(1);
#endregion

#region Menu contextual da carta
if (carta_menu_aberto != noone && instance_exists(carta_menu_aberto) && menu_escala > 0.01) {
    // Fontenil contém os glifos acentuados usados pelas opções em português.
    draw_set_font(Fontenil);
	
    var _carta = carta_menu_aberto;
    var _opcoes = obter_opcoes_menu(_carta);
    var _n = array_length(_opcoes);
    
    var _largura_opcao = 170;
    var _altura_opcao = 23;
    var _espaco_opcao = 6;
    var _altura_total = _n * _altura_opcao + (_n - 1) * _espaco_opcao;
    
    var _base_x = _carta.x + (global.CARTA_LARGURA * 0.5);
	var _base_y = _carta.y - _altura_total/2;
    
    for (var i = 0; i < _n; i++) {
        var _opt_y = _base_y + i * (_altura_opcao + _espaco_opcao);
        var _centro_opt_y = _opt_y + _altura_opcao/2;
        
        // cresce a partir da esquerda (perto da carta), não do centro
        var _largura_atual = _largura_opcao * menu_escala;
        var _altura_atual = _altura_opcao * menu_escala;
        
        var _x1 = _base_x;
        var _y1 = _centro_opt_y - _altura_atual/2;
        var _x2 = _base_x + _largura_atual;
        var _y2 = _centro_opt_y + _altura_atual/2;
        
        var _opcao_indisponivel = string_pos("[", _opcoes[i]) > 0;
        draw_set_alpha(menu_escala);
        draw_set_color(c_black);
        draw_rectangle(_x1, _y1, _x2, _y2, false);
        draw_set_color(_opcao_indisponivel ? c_gray : c_white);
        draw_rectangle(_x1, _y1, _x2, _y2, true);
        
		// tooltip com o nome da habilidade, mostrado só quando o mouse está exatamente nesta opção
		if (i == opcao_hover_index && tooltip_escala > 0.01 && _opcoes[i] == "Habilidade") {
	    var _nome_habilidade = obter_nome_exibicao_habilidade(tem_habilidade_ativa(_carta))
    
	    var _tooltip_x_base = _base_x + _largura_opcao + 10;
	    var _tooltip_y_centro = _base_y + opcao_hover_index * (_altura_opcao + _espaco_opcao) + _altura_opcao/2;
    
	    var _largura_tooltip_final = string_width(_nome_habilidade) + 20;
	    var _altura_tooltip_final = 28;
    
	    var _largura_tooltip_atual = _largura_tooltip_final * tooltip_escala;
	    var _altura_tooltip_atual = _altura_tooltip_final * tooltip_escala;
    
	    var _tx1 = _tooltip_x_base;
	    var _ty1 = _tooltip_y_centro - _altura_tooltip_atual/2;
	    var _tx2 = _tooltip_x_base + _largura_tooltip_atual;
	    var _ty2 = _tooltip_y_centro + _altura_tooltip_atual/2;
    
	    draw_set_alpha(tooltip_escala);
	    draw_set_color(c_black);
	    draw_rectangle(_tx1, _ty1, _tx2, _ty2, false);
	    draw_set_color(c_yellow);
	    draw_rectangle(_tx1, _ty1, _tx2, _ty2, true);
    
    if (tooltip_escala > 0.7) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text((_tx1 + _tx2)/2, (_ty1 + _ty2)/2, _nome_habilidade);
    }
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_set_alpha(1);
}
		
        if (menu_escala > 0.7) {
		    draw_set_halign(fa_center);
		    draw_set_valign(fa_middle);
		    var _escala_texto_opcao = _opcao_indisponivel ? 0.40 : 0.60;
		    draw_text_transformed((_x1 + _x2)/2, (_y1 + _y2)/2, _opcoes[i], _escala_texto_opcao, _escala_texto_opcao, 0);
		}
        draw_set_alpha(1);
    }
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(-1)
}
#endregion
