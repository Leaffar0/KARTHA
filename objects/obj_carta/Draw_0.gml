draw_set_font(Fontenil)


var _rotacao_extra = (dono == "inimigo") ? 180 : 0;
var _rotacao_total = rotacao_atual + _rotacao_extra;

var _y_desenho = y + y_offset_atual;

var _escala_final = escala_atual * escala_base;
if (travada) {
    _escala_final *= escala_no_campo;
}

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
    c_white,
    _alpha_carta
);

if (!tem_arte_propria) {
    var _dist_nome = point_distance(0, 0, 0, -sprite_height/2 * escala_atual + 4);
    var _dir_nome = point_direction(0, 0, 0, -sprite_height/2 * escala_atual + 4);
    var _nome_x = x + lengthdir_x(_dist_nome, _dir_nome + _rotacao_total);
    var _nome_y = _y_desenho + lengthdir_y(_dist_nome, _dir_nome + _rotacao_total);
    
    var _largura_maxima = sprite_width * escala_atual * 0.85;
    var _largura_texto = string_width(nome_carta);
    var _escala_texto = 1;
    
    if (_largura_texto > _largura_maxima) {
        _escala_texto = _largura_maxima / _largura_texto;
    }
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text_transformed(_nome_x, _nome_y, nome_carta, escala_atual * _escala_texto, escala_atual * _escala_texto, _rotacao_total);
}

// --- ataque e vida: só desenha se for tropa ---
if (categoria == "tropa") {
    var _texto_atk = string(dado_dano) + "+" + string(mod_dano);
    var _texto_vida = string(vida);
    
    // limite de largura pra cada texto (metade da carta, com uma margem)
    var _largura_max_stat = sprite_width * escala_atual * 0.40;
    
    var _escala_atk = 0.8;
    var _largura_atk = string_width(_texto_atk);
    if (_largura_atk > _largura_max_stat) {
        _escala_atk = _largura_max_stat / _largura_atk;
    }
    
    var _escala_vida = 0.8;
    var _largura_vida = string_width(_texto_vida);
    if (_largura_vida > _largura_max_stat) {
        _escala_vida = _largura_max_stat / _largura_vida;
    }
    
    var _dist_atk = point_distance(0, 0, -sprite_width/2 * escala_atual + 4, sprite_height/2 * escala_atual - 4);
    var _dir_atk = point_direction(0, 0, -sprite_width/2 * escala_atual + 4, sprite_height/2 * escala_atual - 4);
    var _atk_x = x + lengthdir_x(_dist_atk, _dir_atk + _rotacao_total);
    var _atk_y = _y_desenho + lengthdir_y(_dist_atk, _dir_atk + _rotacao_total);
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_bottom);
    draw_text_transformed(_atk_x, _atk_y, _texto_atk, escala_atual * _escala_atk, escala_atual * _escala_atk, _rotacao_total);
    
    var _dist_vida = point_distance(0, 0, sprite_width/2 * escala_atual - 4, sprite_height/2 * escala_atual - 4);
    var _dir_vida = point_direction(0, 0, sprite_width/2 * escala_atual - 4, sprite_height/2 * escala_atual - 4);
    var _vida_x = x + lengthdir_x(_dist_vida, _dir_vida + _rotacao_total);
    var _vida_y = _y_desenho + lengthdir_y(_dist_vida, _dir_vida + _rotacao_total);
    
    draw_set_halign(fa_right);
    draw_set_valign(fa_bottom);
    draw_text_transformed(_vida_x, _vida_y, _texto_vida, escala_atual * _escala_vida, escala_atual * _escala_vida, _rotacao_total);
}

// desenha o sprite da condição ativa por cima da carta
if (condicao != noone && condicao != "imune_queimado") {
    var _config = obter_config_condicao(condicao);
    
    if (_config.sprite != -1) {
        efeito_timer += 1;
        
        var _num_frames = sprite_get_number(_config.sprite);
        var _frame = floor(efeito_timer / 4) mod _num_frames;
        
        if (_config.modo == "meio") {
            // aparece centralizado, tamanho normal da carta
            draw_sprite_ext(
                _config.sprite,
                _frame,
                x,
                y,
                escala_atual,
                escala_atual,
                0,
                c_white,
                0.85
            );
        } else if (_config.modo == "envolta") {
            // aparece maior, cobrindo a carta inteira (efeito de "envolvida")
            var _escala_envolta_x = (sprite_width * escala_atual * 1) / sprite_get_width(_config.sprite);
            var _escala_envolta_y = (sprite_height * escala_atual * 1) / sprite_get_height(_config.sprite);
            
            draw_sprite_ext(
                _config.sprite,
                _frame,
                x,
                y,
                _escala_envolta_x,
                _escala_envolta_y,
                0,
                c_white,
                0.8
            );
        }
    }
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(-1)
draw_set_alpha(1);