var _escala_x_final = escala_base * pulso_x;
var _escala_y_final = escala_base * pulso_y;

desenhar_sombra_contato(sprite_index,image_index,x,y,_escala_x_final,_escala_y_final,image_angle,entrando?8:0,alpha_visual);
desenhar_carta_mesa(sprite_index, image_index, x, y, _escala_x_final, _escala_y_final, image_angle, c_white, alpha_visual);
// Terrenos ainda sem ilustração mantêm seu nome visível no campo.
if(is_struct(dados_carta) && dados_carta.categoria=="terreno"
    && !sprite_exists(dados_carta.sprite_carta)) {
    var _fonte=draw_get_font(),_ha=draw_get_halign(),_va=draw_get_valign();
    draw_set_font(Fontenil);draw_set_halign(fa_center);draw_set_valign(fa_middle);
    draw_set_color(c_white);draw_set_alpha(alpha_visual);
    desenhar_texto_ajustado_ui(dados_carta.nome,x,y,global.TERRENO_LARGURA_ALVO-6,0.30);
    draw_set_font(_fonte);draw_set_halign(_ha);draw_set_valign(_va);draw_set_alpha(1);
}
