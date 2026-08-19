#region Preparação e desenho base da carta
draw_set_font(Fontenil)

var _rotacao_extra = (dono == "inimigo") ? 180 : 0;
var _rotacao_total = rotacao_atual + rotacao_animacao + rotacao_evolucao + _rotacao_extra;

var _y_desenho = y + y_offset_atual;

var _escala_final = escala_atual * escala_animacao * escala_evolucao * escala_base;
if (travada) {
    _escala_final *= escala_no_campo;
}

// isso ajusta a MÁSCARA DE CLIQUE de verdade, não só o desenho
image_xscale = _escala_final;
image_yscale = _escala_final;

var _alpha_carta = sombra_ativa ? 0.4 : 1;
draw_set_alpha(_alpha_carta);

draw_sprite_ext(
    sprite_index,
    image_index,
    x,
    _y_desenho,
    _escala_final,
    _escala_final,
    _rotacao_total,
    cor_evolucao,
    _alpha_carta
);
#endregion

#region Nome e atributos
// a partir daqui, sprite_width/sprite_height JÁ refletem o tamanho visual real
// (o GameMaker calcula isso automaticamente com base no image_xscale/yscale que definimos acima)

if (!tem_arte_propria) {
    // --- posição do nome (só pra cartas sem arte, usando texto) ---
    var _dist_nome = point_distance(0, 0, 0, -sprite_height/2 + 4);
    var _dir_nome = point_direction(0, 0, 0, -sprite_height/2 + 4);
    var _nome_x = x + lengthdir_x(_dist_nome, _dir_nome + _rotacao_total);
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

	desenhar_stat(self, vida, vida_pos_x, vida_pos_y, x, _y_desenho, _rotacao_total, _escala_final, _escala_texto_fallback);
	desenhar_stat(self, string(nivel_inteligencia), int_pos_x, int_pos_y, x, _y_desenho, _rotacao_total, _escala_final, _escala_texto_fallback, true);
	desenhar_stat(self, mochila, mochila_pos_x, mochila_pos_y, x, _y_desenho, _rotacao_total, _escala_final, _escala_texto_fallback);
	desenhar_stat(self, defesa_fisica, def_pos_x, def_pos_y, x, _y_desenho, _rotacao_total, _escala_final, _escala_texto_fallback);
	desenhar_stat(self, defesa_magica, def_magico_pos_x, def_magico_pos_y, x, _y_desenho, _rotacao_total, _escala_final, _escala_texto_fallback);

	// ATK e ATK mágico são especiais: têm 2 números juntos ("dado+mod"), então tratamos separado
	if (dado_dano != 0) {
    var _texto_atk = (qtd_dados_dano > 1 ? string(qtd_dados_dano) : "") + "D" + string(dado_dano) + "+" + string(mod_dano);
    desenhar_stat(self, _texto_atk, atk_pos_x, atk_pos_y, x, _y_desenho, _rotacao_total, _escala_final * global.ESCALA_TEXTO_ATK, _escala_texto_fallback * global.ESCALA_TEXTO_ATK, true);
	}
	if (dado_dano_magico != 0) {
	    var _texto_atk_m = (qtd_dados_dano_magico > 1 ? string(qtd_dados_dano_magico) : "") + "D" + string(dado_dano_magico) + "+" + string(mod_dano_magico);
	    desenhar_stat(self, _texto_atk_m, atk_magico_pos_x, atk_magico_pos_y, x, _y_desenho, _rotacao_total, _escala_final * global.ESCALA_TEXTO_ATK, _escala_texto_fallback * global.ESCALA_TEXTO_ATK, true);
	}
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
#endregion

#region Efeito visual de condição
if (condicao != noone && condicao != "imune_queimado") {
    var _config = obter_config_condicao(condicao);

    if (_config.sprite != -1) {
        efeito_timer += 1;
        var _num_frames = sprite_get_number(_config.sprite);
        var _frame = floor(efeito_timer / 4) mod _num_frames;

        if (_config.modo == "meio") {
            draw_sprite_ext(_config.sprite, _frame, x, y, _escala_final, _escala_final, 0, c_white, 0.85);
        } else if (_config.modo == "envolta") {
            var _escala_envolta_x = (sprite_width * 1.3) / sprite_get_width(_config.sprite);
            var _escala_envolta_y = (sprite_height * 1.3) / sprite_get_height(_config.sprite);
            draw_sprite_ext(_config.sprite, _frame, x, y, _escala_envolta_x, _escala_envolta_y, 0, c_white, 0.8);
        }
    }
}

draw_set_alpha(1);
#endregion
