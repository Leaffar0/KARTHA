if(tropa_oculta_nevoa(id)) { desenhar_tropa_oculta_nevoa(id); exit; }
#region Preparação e desenho base da carta
draw_set_font(Fontenil)


var _rotacao_extra = (dono == "inimigo") ? 180 : 0;
var _rotacao_total = rotacao_atual + rotacao_animacao + rotacao_evolucao + arrasto_rotacao + _rotacao_extra;

var _x_desenho = x + ataque_offset_x + arrasto_offset_visual_x + recuo_dano_x;
var _y_desenho = y + y_offset_atual + ataque_offset_y - ataque_elevacao + arrasto_offset_visual_y + recuo_dano_y;
if (evoluindo) _y_desenho -= sin(clamp(evolucao_progresso, 0, 1) * pi) * 16;
if (travada && !morrendo && !evoluindo && vida > 0 && vida <= max(1, vida_maxima * 0.2))
    _rotacao_total += sin(current_time * 0.002 + xstart * 0.013 + ystart * 0.017) * 0.35 * fator_efeitos_visuais();
var _quique_pouso = 0;
if (travada && impacto_colocacao_timer > 0 && pulso_pouso_timer > 0) {
    _quique_pouso = 2 * sin((1 - pulso_pouso_timer / pulso_pouso_duracao) * pi);
    _y_desenho -= _quique_pouso;
}

var _escala_final = escala_atual * escala_animacao * escala_evolucao * escala_base * escala_voo * arrasto_escala * (1 + ataque_escala_extra);
if (travada) {
    _escala_final *= escala_no_campo;
} else if (esta_na_mao || arrastando) {
    _escala_final *= global.escala_interface;
}

image_xscale = _escala_final;
image_yscale = _escala_final;

if (travada && categoria == "tropa" && !morrendo && !evoluindo && !pulando
    && ataque_animacao == noone && tropa_pode_agir(id)) {
    var _personalidade = personalidade_visual(nome_carta, tem_habilidade(id, "voar"), current_time + xstart*7 + ystart*3);
    _y_desenho += _personalidade.y * 0.15;
    _rotacao_total += _personalidade.rotacao * 0.5;
    _escala_final *= 1 + (_personalidade.escala - 1) * 0.3;
}
var _alpha_carta = sombra_ativa ? 0.4 : 1;
draw_set_alpha(_alpha_carta);

if (!morrendo) {
    var _altura_contato = arrastando ? 18 : (hover_ativo ? 5 : 0);
    if (pulando) _altura_contato += pulo_elevacao;
    _altura_contato += ataque_elevacao;
    desenhar_sombra_contato(sprite_index,image_index,_x_desenho,_y_desenho,
        _escala_final,_escala_final,_rotacao_total,_altura_contato,_alpha_carta);
}

// Durante a virada a largura diminui até a borda e volta a abrir pela face.
if (compra_animando && esta_na_mao) {
    var _virada = clamp((compra_progresso - 0.18) / 0.48, 0, 1);
    var _largura_virada = max(0.055, abs(cos(_virada * pi)));
    if (_virada < 0.5 || _largura_virada < 0.97) {
        var _verso = _virada < 0.5;
        var _sprite_compra = _verso ? spr_verso_kartha : sprite_index;
        var _escala_x_compra = _escala_final * sprite_get_width(sprite_index) / sprite_get_width(_sprite_compra);
        var _escala_y_compra = _escala_final * sprite_get_height(sprite_index) / sprite_get_height(_sprite_compra);
        draw_set_alpha(1);
        desenhar_carta_mesa(_sprite_compra, _verso ? 0 : image_index, _x_desenho, _y_desenho,
            _escala_x_compra * _largura_virada, _escala_y_compra, _rotacao_total, c_white, _alpha_carta);
        draw_set_font(-1);
        exit;
    }
}

// A forma antiga vira para o verso e então revela a evolução.
if (evoluindo && evolucao_progresso < 0.82) {
    var _fase = clamp(evolucao_progresso / 0.82, 0, 1);
    var _face = (_fase < 0.25 && evolucao_sprite_anterior != noone) ? evolucao_sprite_anterior
        : (_fase < 0.75 ? spr_verso_kartha : sprite_index);
    var _largura_flip = max(0.035, abs(cos(_fase * pi * 2)));
    desenhar_carta_mesa(_face, 0, _x_desenho, _y_desenho,
        _escala_final * sprite_get_width(sprite_index) / sprite_get_width(_face) * _largura_flip,
        _escala_final * sprite_get_height(sprite_index) / sprite_get_height(_face),
        _rotacao_total, cor_evolucao, _alpha_carta);
    draw_set_alpha(1);
    draw_set_color(c_white);
    exit;
}

// Pequenos rastros se espalham pelo chão no momento do pouso.
if (impacto_colocacao_timer > 0) {
    var _impacto_p = 1 - impacto_colocacao_timer / impacto_colocacao_duracao;
    var _resto_pouso = 1 - _impacto_p;
    var _expansao_pouso = 1 - sqr(_resto_pouso);
    var _chao_pouso = _y_desenho + _quique_pouso + sprite_get_height(sprite_index) * _escala_final * 0.46;
    var _borda_pouso = sprite_get_width(sprite_index) * _escala_final * 0.36;
    var _cor_pouso = dono == "jogador" ? make_color_rgb(153, 230, 219) : make_color_rgb(240, 168, 139);
    draw_set_alpha(_alpha_carta * sqr(_resto_pouso) * 0.46);
    draw_set_color(_cor_pouso);
    for (var _lado_pouso = -1; _lado_pouso <= 1; _lado_pouso += 2) {
        for (var _rastro = 0; _rastro < 3; _rastro++) {
            var _rastro_x = _x_desenho + _lado_pouso * (_borda_pouso + _expansao_pouso * (11 + _rastro * 6));
            var _rastro_y = _chao_pouso + (_rastro - 1) * 4;
            draw_line(_rastro_x, _rastro_y,
                _rastro_x + _lado_pouso * (4 + 7 * _resto_pouso), _rastro_y - 1);
        }
    }
    draw_set_alpha(_alpha_carta); draw_set_color(c_white);
}

// O impacto concentra a cor no primeiro instante e depois se dissipa.
var _cor_final = cor_evolucao;
if (dano_flash_timer > 0) {
    var _flash_progresso = dano_flash_timer / dano_flash_duracao;
    _cor_final = merge_color(cor_evolucao, make_color_rgb(255, 84, 67), min(0.95,0.76 * fator_efeitos_visuais()) * sqr(_flash_progresso));
}

if (efeito_timer > 0 && efeito_timer <= 18 && efeito_visual_tipo == "envenenado")
    _cor_final = merge_color(_cor_final, make_color_rgb(66, 105, 67), 0.40 * sqr(efeito_timer / 18));

// A derrota consome a carta de fora para dentro: ela escurece, queima e encolhe.
if (morrendo) {
    var _progresso_morte = 1 - (morte_timer / morte_duracao);
    if (!selo_abissal && _progresso_morte > 0.55) {
        var _pilha = instance_find(obj_descarte,0);
        if (_pilha != noone) {
            var _voo = clamp((_progresso_morte-0.55)/0.45,0,1);
            var _suave = _voo*_voo*(3-2*_voo);
            var _dx = dono=="jogador"?_pilha.x:room_width-_pilha.x;
            var _dy = dono=="jogador"?_pilha.y:room_height-_pilha.y;
            _x_desenho=lerp(_x_desenho,_dx,_suave);
            _y_desenho=lerp(_y_desenho,_dy,_suave)-sin(_voo*pi)*18;
            _rotacao_total+=sin(_voo*pi)*12;
        }
    }
    _alpha_carta *= 1 - power(_progresso_morte,3);
    _escala_final *= 1 - _progresso_morte * 0.72;
    if (tipo_morte_visual == "magica") {
        _cor_final = merge_color(_cor_final, make_color_rgb(75, 205, 255), _progresso_morte * 0.85);
    } else if (tipo_morte_visual == "fogo" || tipo_morte_visual == "queimado") {
        _cor_final = merge_color(_cor_final, make_color_rgb(255, 75, 10), _progresso_morte * 0.90);
    } else if (tipo_morte_visual == "veneno" || tipo_morte_visual == "apodrecer") {
        _cor_final = merge_color(_cor_final, make_color_rgb(80, 185, 55), _progresso_morte * 0.88);
    } else {
        _cor_final = merge_color(_cor_final, c_black, _progresso_morte * 0.82);
    }
}

draw_set_alpha(_alpha_carta);

gpu_set_texfilter(true);

// Equipamentos ficam empilhados atrás da tropa como cartas físicas.
// Pilha original acima da tropa, com um pequeno ajuste para baixo.
if (travada && categoria == "tropa" && array_length(itens_equipados) > 0) {
    var _qtd_equipamentos = array_length(itens_equipados);
    var _largura_tropa_visual = sprite_get_width(sprite_index) * _escala_final;
    var _altura_tropa_visual = sprite_get_height(sprite_index) * _escala_final;
    var _passo_equipamento = clamp(_altura_tropa_visual * 0.055, 12, 19);
    // AJUSTE: aumente para baixar; 0 restaura a posição original (pixels locais).
    var _ajuste_vertical_equipamento = 4;

    for (var _indice_equip = 0; _indice_equip < _qtd_equipamentos; _indice_equip++) {
        var _item_visual = itens_equipados[_indice_equip];
        if (!is_struct(_item_visual) || !variable_struct_exists(_item_visual, "sprite")) continue;

        var _anim_equip = animacao_equipamento_ativo(id, _item_visual, _indice_equip);
        var _sprite_equipamento = _item_visual.sprite;
        if (_sprite_equipamento == noone || !sprite_exists(_sprite_equipamento))
            _sprite_equipamento = spr_carta_placeholder;

        var _escala_equipamento = min(
            _largura_tropa_visual / sprite_get_width(_sprite_equipamento),
            _altura_tropa_visual / sprite_get_height(_sprite_equipamento)
        );
        var _recuo_local = -_passo_equipamento * (_qtd_equipamentos - _indice_equip)
            + _ajuste_vertical_equipamento;
        var _distancia_equip = abs(_recuo_local);
        var _direcao_equip = point_direction(0, 0, 0, _recuo_local) + _rotacao_total;
        var _equip_x = _x_desenho + lengthdir_x(_distancia_equip, _direcao_equip);
        var _equip_y = _y_desenho + lengthdir_y(_distancia_equip, _direcao_equip);

        if (!is_struct(_anim_equip)) {
            _equip_x += (_indice_equip-(_qtd_equipamentos-1)*0.5)*32*leque_equipamento;
            _equip_y -= 32*leque_equipamento;
        }
        if (is_struct(_anim_equip)) {
            var _p_equip = clamp(_anim_equip.timer / _anim_equip.duracao, 0, 1);
            var _encaixe_visual=posicao_encaixe_equipamento(_anim_equip.origem_x,_anim_equip.origem_y,
                _equip_x,_equip_y,_altura_tropa_visual,_rotacao_total,_p_equip);
            _equip_x=_encaixe_visual.x;_equip_y=_encaixe_visual.y;
        }

        desenhar_carta_mesa(_sprite_equipamento, 0, _equip_x, _equip_y,
            _escala_equipamento, _escala_equipamento, _rotacao_total, _cor_final, _alpha_carta);

        // Cartas sem arte usam o placeholder; nesse caso o título é desenhado
        // manualmente para a faixa visível continuar identificando o item.
        if (_sprite_equipamento == spr_carta_placeholder || leque_equipamento > 0.5) {
            var _nome_equipamento = variable_struct_exists(_item_visual, "nome")
                ? _item_visual.nome : "Equipamento";
            var _topo_local = -(sprite_get_height(_sprite_equipamento) * _escala_equipamento * 0.5)
                + _passo_equipamento * 0.50;
            var _distancia_titulo = abs(_topo_local);
            var _direcao_titulo = point_direction(0, 0, 0, _topo_local) + _rotacao_total;
            var _titulo_x = _equip_x + lengthdir_x(_distancia_titulo, _direcao_titulo);
            var _titulo_y = _equip_y + lengthdir_y(_distancia_titulo, _direcao_titulo);
            var _escala_titulo = min(_escala_equipamento * 0.42,
                (_largura_tropa_visual * 0.82) / max(1, string_width(_nome_equipamento)));

            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_color(c_white);
            draw_text_transformed(_titulo_x, _titulo_y, _nome_equipamento,
                _escala_titulo, _escala_titulo, _rotacao_total);
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
            draw_set_color(c_white);

        }
    }
}

desenhar_carta_mesa(
    sprite_index,
    image_index,
    _x_desenho,
    _y_desenho,
    _escala_final,
    _escala_final,
    _rotacao_total,
    _cor_final,
    _alpha_carta
);

if (travada && !morrendo && tem_condicao(id,"congelado")) {
    draw_sprite_ext(spr_congelado,0,_x_desenho,_y_desenho,
        sprite_get_width(sprite_index)*_escala_final/sprite_get_width(spr_congelado),
        sprite_get_height(sprite_index)*_escala_final/sprite_get_height(spr_congelado),
        _rotacao_total,make_color_rgb(173,208,221),0.50*_alpha_carta);
}

if (morrendo) {
    var _brasa_alpha = (1 - _progresso_morte) * 0.85;
    var _meia_largura_brasa = sprite_width * _escala_final * 0.50;
    var _meia_altura_brasa = sprite_height * _escala_final * 0.50;
    draw_set_alpha(_brasa_alpha);
    var _cor_fragmento = c_white;
    if (tipo_morte_visual == "magica") _cor_fragmento = c_aqua;
    else if (tipo_morte_visual == "fogo" || tipo_morte_visual == "queimado") _cor_fragmento = make_color_rgb(255, 105, 25);
    else if (tipo_morte_visual == "veneno" || tipo_morte_visual == "apodrecer") _cor_fragmento = c_lime;
    else _cor_fragmento = make_color_rgb(220, 100, 55);
    draw_set_color(_cor_fragmento);
    for (var _brasa = 0; _brasa < max(2,round(5*fator_efeitos_visuais())); _brasa++) {
        var _angulo_fragmento = _brasa * 72 + morte_timer * 4;
        var _raio_fragmento = 8 + _progresso_morte * 38;
        var _fx1 = _x_desenho + lengthdir_x(_raio_fragmento, _angulo_fragmento);
        var _fy1 = _y_desenho + lengthdir_y(_raio_fragmento, _angulo_fragmento);
        draw_line(_fx1, _fy1, _fx1 + lengthdir_x(8, _angulo_fragmento), _fy1 + lengthdir_y(8, _angulo_fragmento));
    }
    draw_set_alpha(_alpha_carta);
    draw_set_color(_cor_final);
}

// Brilho pulsante quando a armadilha está ativa em campo (vigiando ou pronta)
if (armadilha_estado == "vigiando" || armadilha_estado == "pronta") {
    var _pulso_brilho = (sin(current_time / 150) + 1) / 2; // 0 a 1
    var _cor_base = (armadilha_estado == "pronta") ? c_red : c_yellow;
    var _cor_brilho = merge_color(c_white, _cor_base, 0.2); // suaviza a cor, não fica saturada

    draw_set_alpha(_pulso_brilho * 0.15); // era 0.5, bem mais discreto agora
    desenhar_carta_mesa(sprite_index, image_index, _x_desenho, _y_desenho, _escala_final * 1.05, _escala_final * 1.05, _rotacao_total, _cor_brilho, 1);
    draw_set_alpha(1);
}

// A postura de defesa aparece como escudo azul no GUI.

#endregion

#region Nome e atributos
// a partir daqui, sprite_width/sprite_height JÁ refletem o tamanho visual real
// (o GameMaker calcula isso automaticamente com base no image_xscale/yscale que definimos acima)

if (!tem_arte_propria) {
    // --- posição do nome (só pra cartas sem arte, usando texto) ---
    var _dist_nome = point_distance(0, 0, 0, -sprite_height/2 + 4);
    var _dir_nome = point_direction(0, 0, 0, -sprite_height/2 + 4);
    var _nome_x = _x_desenho + lengthdir_x(_dist_nome, _dir_nome + _rotacao_total);
    var _nome_y = _y_desenho + lengthdir_y(_dist_nome, _dir_nome + _rotacao_total);

    var _largura_maxima = sprite_width * 0.85;
    var _largura_texto = string_width(nome_carta);
    var _escala_texto = 1;
    if (_largura_texto > _largura_maxima) {
    _escala_texto = _largura_maxima / _largura_texto;
	}
	_escala_texto *= global.ESCALA_TEXTO_CARTA;

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text_transformed(_nome_x, _nome_y, nome_carta, _escala_texto, _escala_texto, _rotacao_total);
}

// --- VIDA: sempre desenhada, inclusive em cima da arte de verdade ---
// posição no canto superior esquerdo, perto de onde fica o ícone de coração na sua arte
if (categoria == "tropa") {
    var _escala_texto_fallback = escala_atual * (travada ? escala_no_campo : 1) * global.ESCALA_TEXTO_CARTA;

	var _pulso = escala_pulso_vida(vida_pulso_inicio);
    desenhar_stat(self, string(vida), vida_pos_x, vida_pos_y, _x_desenho, _y_desenho, _rotacao_total,
        _escala_final * _pulso, _escala_texto_fallback * _pulso, true);
	desenhar_stat(self, string(nivel_inteligencia), int_pos_x, int_pos_y, _x_desenho, _y_desenho, _rotacao_total, _escala_final, _escala_texto_fallback, true);
	desenhar_stat(self, string(mochila), mochila_pos_x, mochila_pos_y, _x_desenho, _y_desenho, _rotacao_total, _escala_final, _escala_texto_fallback, true);
	desenhar_stat(self, calcular_defesa_fisica_total(self), def_pos_x, def_pos_y, _x_desenho, _y_desenho, _rotacao_total, _escala_final, _escala_texto_fallback);
	desenhar_stat(self, calcular_defesa_magica_total(self), def_magico_pos_x, def_magico_pos_y, _x_desenho, _y_desenho, _rotacao_total, _escala_final, _escala_texto_fallback);

	// ATK e ATK mágico são especiais: têm 2 números juntos ("dado+mod"), então tratamos separado
	if (dado_dano != 0) {
	    var _texto_atk = (qtd_dados_dano > 1 ? string(qtd_dados_dano) : "") + "D" + string(dado_dano) + "+" + string(calcular_mod_dano_total(self));
	    desenhar_stat(self, _texto_atk, atk_pos_x, atk_pos_y, x, _y_desenho, _rotacao_total, _escala_final * global.ESCALA_TEXTO_ATK, _escala_texto_fallback * global.ESCALA_TEXTO_ATK, true);
	}
	if (dado_dano_magico != 0) {
	    var _texto_atk_m = (qtd_dados_dano_magico > 1 ? string(qtd_dados_dano_magico) : "") + "D" + string(dado_dano_magico) + "+" + string(calcular_mod_dano_total(self));
	    desenhar_stat(self, _texto_atk_m, atk_magico_pos_x, atk_magico_pos_y, x, _y_desenho, _rotacao_total, _escala_final * global.ESCALA_TEXTO_ATK, _escala_texto_fallback * global.ESCALA_TEXTO_ATK, true);
	}
}

// Construções com arte própria também mostram a vida diretamente na carta
// enquanto estão na mão. O deslocamento acompanha a posição usada no campo.
if (categoria == "construcao" && tem_arte_propria) {
    var _escala_texto_construcao = escala_atual * (travada ? escala_no_campo : 1) * global.ESCALA_TEXTO_CARTA;
    var _vida_construcao_x = clamp(vida_pos_x + 0.05, 0, 1);
    var _vida_construcao_y = clamp(vida_pos_y + 0.05, 0, 1);
    desenhar_stat(self, vida, _vida_construcao_x, _vida_construcao_y,
        _x_desenho, _y_desenho, _rotacao_total, _escala_final, _escala_texto_construcao);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
#endregion

// O escudo de defesa é desenhado no GUI, acima das cartas.
desenhar_efeitos_identidade(id, _x_desenho, _y_desenho, _escala_final, _rotacao_total, _alpha_carta);

// A faixa lateral acompanha a posição efetivamente desenhada, inclusive durante o recuo.
condicoes_visual_x = _x_desenho;
condicoes_visual_y = _y_desenho;
