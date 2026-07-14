draw_set_font(Fontenil);

draw_text(20, 20, "Vida jogador: " + string(vida_jogador));
draw_text(20, 50, "Vida inimigo: " + string(vida_inimigo));
draw_text(20, 80, "Fase: " + string(fase));


if(preevile){
	draw_text(20, 680, "Clique com botão direito para preview da carta");
}


if (carta_preview != noone && instance_exists(carta_preview)) {
    var _carta = carta_preview;
    
    var _centro_x = display_get_gui_width() / 2;
    var _centro_y = display_get_gui_height() / 2;
    
    // fundo escurecido atrás, pra destacar a carta
    draw_set_alpha(0.7);
    draw_set_color(c_black);
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(1);
    
    var _escala_preview = 8; // ajuste esse número pro tamanho que quiser (2 = dobro, 4 = quádruplo, etc)
    
    draw_sprite_ext(
        _carta.sprite_index,
        _carta.image_index,
        _centro_x,     
        _centro_y,
        _escala_preview,
        _escala_preview,
        0, // sempre reto, não usa a rotação de "inimigo virado" no preview
        c_white,
        1
    );
    
    // nome
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text_transformed(_centro_x, _centro_y - (_carta.sprite_height/2 * _escala_preview) + 10, _carta.nome_carta, _escala_preview * 0.35, _escala_preview * 0.35, 0);
    
    // ataque/vida, só se for tropa
    if (_carta.categoria == "tropa") {
        var _texto_atk = string(_carta.dado_dano) + "+" + string(_carta.mod_dano);
        draw_set_halign(fa_left);
        draw_set_valign(fa_bottom);
        draw_text_transformed(_centro_x - (_carta.sprite_width/2 * _escala_preview) + 15, _centro_y + (_carta.sprite_height/2 * _escala_preview) - 10, _texto_atk, _escala_preview * 0.4, _escala_preview * 0.4, 0);
        
        draw_set_halign(fa_right);
        draw_set_valign(fa_bottom);
        draw_text_transformed(_centro_x + (_carta.sprite_width/2 * _escala_preview) - 15, _centro_y + (_carta.sprite_height/2 * _escala_preview) - 10, string(_carta.vida), _escala_preview * 0.6, _escala_preview * 0.6, 0);
    }
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    
    // dica de como fechar
    draw_set_color(c_white);
    draw_text(_centro_x - 150, display_get_gui_height() - 40, "Clique com o botão direito pra fechar");
}

if (vida_jogador <= 0) {
    draw_set_font(fnt_vitoria)
    draw_text(room_width/2 - 150, room_height/2.5, "VOCÊ PERDEU");
	draw_set_font(-1)
}
if (vida_inimigo <= 0) {
	draw_set_font(fnt_vitoria)
    draw_text(room_width/2 - 150, room_height/2.5, "VOCÊ VENCEU");
	draw_set_font(-1)
}
draw_set_font(-1);