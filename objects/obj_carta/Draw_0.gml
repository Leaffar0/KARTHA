var _y_desenho = y + y_offset_atual;

draw_sprite_ext(
    sprite_index,
    image_index,
    x,
    _y_desenho,
    escala_atual,
    escala_atual,
    rotacao_atual,
    c_white,
    1
);

// --- posição do nome ---
var _dist_nome = point_distance(0, 0, 0, -sprite_height/2 * escala_atual + 4);
var _dir_nome = point_direction(0, 0, 0, -sprite_height/2 * escala_atual + 4);
var _nome_x = x + lengthdir_x(_dist_nome, _dir_nome + rotacao_atual);
var _nome_y = _y_desenho + lengthdir_y(_dist_nome, _dir_nome + rotacao_atual);

// calcula se o nome cabe na largura da carta; se não, encolhe o texto
var _largura_maxima = sprite_width * escala_atual * 0.85;
var _largura_texto = string_width(nome_carta);
var _escala_texto = 1;

if (_largura_texto > _largura_maxima) {
    _escala_texto = _largura_maxima / _largura_texto;
}

if (condicao != noone && condicao != "imune_queimado") {
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(c_red);
    draw_text(x, y + sprite_height/2 + 20, string_upper(condicao));
    draw_set_color(c_white);
}

draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_text_transformed(_nome_x, _nome_y, nome_carta, escala_atual * _escala_texto, escala_atual * _escala_texto, rotacao_atual);

// --- ataque e vida: só desenha se for tropa ---
if (categoria == "tropa") {
    var _dist_atk = point_distance(0, 0, -sprite_width/2 * escala_atual + 4, sprite_height/2 * escala_atual - 4);
    var _dir_atk = point_direction(0, 0, -sprite_width/2 * escala_atual + 4, sprite_height/2 * escala_atual - 4);
    var _atk_x = x + lengthdir_x(_dist_atk, _dir_atk + rotacao_atual);
    var _atk_y = _y_desenho + lengthdir_y(_dist_atk, _dir_atk + rotacao_atual);
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_bottom);
    draw_text_transformed(_atk_x, _atk_y, string(dado_dano) + "+" + string(mod_dano), escala_atual, escala_atual, rotacao_atual);
    
    var _dist_vida = point_distance(0, 0, sprite_width/2 * escala_atual - 4, sprite_height/2 * escala_atual - 4);
    var _dir_vida = point_direction(0, 0, sprite_width/2 * escala_atual - 4, sprite_height/2 * escala_atual - 4);
    var _vida_x = x + lengthdir_x(_dist_vida, _dir_vida + rotacao_atual);
    var _vida_y = _y_desenho + lengthdir_y(_dist_vida, _dir_vida + rotacao_atual);
    
    draw_set_halign(fa_right);
    draw_set_valign(fa_bottom);
    draw_text_transformed(_vida_x, _vida_y, string(vida), escala_atual, escala_atual, rotacao_atual);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);