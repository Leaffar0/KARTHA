#region Preparação e desenho base da carta
draw_set_font(Fontenil)


var _rotacao_extra = (dono == "inimigo") ? 180 : 0;
var _rotacao_total = rotacao_atual + rotacao_animacao + rotacao_evolucao + arrasto_rotacao + _rotacao_extra;

var _x_desenho = x + ataque_offset_x + arrasto_offset_visual_x + recuo_dano_x;
var _y_desenho = y + y_offset_atual + ataque_offset_y - ataque_elevacao + arrasto_offset_visual_y + recuo_dano_y;

var _escala_final = escala_atual * escala_animacao * escala_evolucao * escala_base * escala_voo * arrasto_escala * (1 + ataque_escala_extra);
if (travada) {
    _escala_final *= escala_no_campo;
}

image_xscale = _escala_final;
image_yscale = _escala_final;

var _alpha_carta = sombra_ativa ? 0.4 : 1;
draw_set_alpha(_alpha_carta);

// Ondas no chão reforçam a chegada da carta ao campo.
if (impacto_colocacao_timer > 0) {
    var _impacto_p = 1 - impacto_colocacao_timer / impacto_colocacao_duracao;
    draw_set_alpha((1 - _impacto_p) * 0.65);
    draw_set_color(dono == "jogador" ? c_aqua : c_red);
    draw_circle(_x_desenho, _y_desenho + sprite_height * escala_no_campo * 0.43, 18 + _impacto_p * 35, true);
    draw_circle(_x_desenho, _y_desenho + sprite_height * escala_no_campo * 0.43, 9 + _impacto_p * 23, true);
    draw_set_alpha(1); draw_set_color(c_white);
}

// Pisca vermelho quando toma dano (mistura a cor normal com vermelho, oscilando)
var _cor_final = cor_evolucao;
if (dano_flash_timer > 0) {
    var _flash_progresso = dano_flash_timer / dano_flash_duracao;
    var _piscar = (sin(dano_flash_timer * 1.4) + 1) / 2; // 0 a 1, oscila rápido
    _cor_final = merge_color(cor_evolucao, c_red, _piscar * _flash_progresso);
}

// A derrota consome a carta de fora para dentro: ela escurece, queima e encolhe.
if (morrendo) {
    var _progresso_morte = 1 - (morte_timer / morte_duracao);
    _alpha_carta *= 1 - _progresso_morte;
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


// Sombra deslocada dá altura e peso à carta enquanto ela acompanha o mouse.
if (arrastando) {
    var _sombra_distancia = 8 + min(5, point_distance(0, 0, arrasto_velocidade_x, arrasto_velocidade_y) * 0.15);
    draw_sprite_ext(sprite_index, image_index, _x_desenho + _sombra_distancia, _y_desenho + _sombra_distancia,
        _escala_final * 1.015, _escala_final * 1.015, _rotacao_total, c_black, 0.24);
}

draw_sprite_ext(
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
    for (var _brasa = 0; _brasa < 5; _brasa++) {
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
    draw_sprite_ext(sprite_index, image_index, _x_desenho, _y_desenho, _escala_final * 1.05, _escala_final * 1.05, _rotacao_total, _cor_brilho, 1);
    draw_set_alpha(1);
}

// Sinal curto para a tropa que intercepta ataques direcionados ao castelo.
if (travada && defendendo_castelo) {
    var _tag_y = _y_desenho - sprite_height * 0.56;
    draw_set_alpha(0.92);
    draw_set_color(make_color_rgb(55, 145, 190));
    draw_rectangle(_x_desenho - 16, _tag_y - 8, _x_desenho + 16, _tag_y + 8, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_x_desenho, _tag_y, "DEF");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(1);
}

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

	desenhar_stat(self, vida, vida_pos_x, vida_pos_y, _x_desenho, _y_desenho, _rotacao_total, _escala_final, _escala_texto_fallback);
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

// Defesa reage ao golpe com um arco que se fecha e desaparece.
if (defesa_impacto_timer > 0) {
    var _def_p = defesa_impacto_timer / defesa_impacto_duracao;
    draw_set_alpha(_def_p * 0.75); draw_set_color(c_aqua);
    draw_circle(_x_desenho, _y_desenho, 25 + (1 - _def_p) * 14, true);
    draw_line(_x_desenho - 20, _y_desenho, _x_desenho, _y_desenho - 24);
    draw_line(_x_desenho, _y_desenho - 24, _x_desenho + 20, _y_desenho);
    draw_set_alpha(1); draw_set_color(c_white);
}
if (evoluindo) {
    var _anel_evo = sin(clamp(evolucao_progresso, 0, 1) * pi);
    draw_set_alpha(_anel_evo * 0.8); draw_set_color(c_aqua);
    draw_circle(_x_desenho, _y_desenho, 28 + _anel_evo * 35, true);
    draw_circle(_x_desenho, _y_desenho, 20 + _anel_evo * 48, true);
    draw_set_alpha(1); draw_set_color(c_white);
}

#region Efeito visual de condição
if (condicao != noone && condicao != "imune_queimado") {
    var _config = obter_config_condicao(condicao);

    efeito_timer += 1;
    if (_config.sprite == -1) {
        var _orbita = efeito_timer * 4;
        var _altura_condicao = _y_desenho - sprite_height * _escala_final * 0.50;
        draw_set_halign(fa_center); draw_set_valign(fa_bottom);
        draw_set_color(_config.cor);
        draw_text_transformed(_x_desenho, _altura_condicao + sin(efeito_timer / 8) * 3,
            string_upper(condicao), 0.30, 0.30, sin(efeito_timer / 12) * 2);
        draw_set_alpha(0.65);
        for (var _mote = 0; _mote < 3; _mote++) {
            var _ang_mote = _orbita + _mote * 120;
            draw_circle(_x_desenho + lengthdir_x(18, _ang_mote), _altura_condicao - 6 + lengthdir_y(5, _ang_mote), 2, false);
        }
        draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_color(c_white);
    } else {
        var _num_frames = sprite_get_number(_config.sprite);
        var _frame = floor(efeito_timer / 4) mod _num_frames;
        var _cor_efeito = tem_arte_propria ? c_black : c_white;
        if (_config.modo == "meio") {
            var _escala_efeito_x = (sprite_width * 0.8) / sprite_get_width(_config.sprite);
            var _escala_efeito_y = (sprite_height * 0.8) / sprite_get_height(_config.sprite);
            draw_sprite_ext(_config.sprite, _frame, _x_desenho, _y_desenho, _escala_efeito_x, _escala_efeito_y, 0, _cor_efeito, 0.85);
        } else if (_config.modo == "envolta") {
            var _escala_envolta_x = (sprite_width * 1.3) / sprite_get_width(_config.sprite);
            var _escala_envolta_y = (sprite_height * 1.3) / sprite_get_height(_config.sprite);
            draw_sprite_ext(_config.sprite, _frame, _x_desenho, _y_desenho, _escala_envolta_x, _escala_envolta_y, 0, _cor_efeito, 0.8);
        }
    }
}

draw_set_alpha(1);
#endregion


#region Alvos da Bola de Fogo
if (arrastando && categoria == "magica" && efeito_tipo == "bola_fogo") {
    draw_set_alpha(0.7);
    draw_set_color(c_red);
    with (obj_construcao) {
        if (dono == "inimigo") draw_circle(x, y, 38, true);
    }
    var _castelo = obter_posicao_castelo("inimigo");
    draw_circle(_castelo.x, _castelo.y, 46, true);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_text_transformed(_castelo.x, _castelo.y - 48, "CASTELO", 0.55, 0.55, 0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(1);
    draw_set_color(c_white);
}
#endregion
