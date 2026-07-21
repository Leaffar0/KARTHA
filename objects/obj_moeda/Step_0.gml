if (girando) {
    tempo_girando += 1;
    
    var _progresso = tempo_girando / tempo_total_giro;
    x = lerp(pos_inicial_x, destino_x, _progresso);
    y = lerp(pos_inicial_y, destino_y, _progresso);
    
    if (tempo_girando mod 6 == 0) {
        image_index = irandom_range(0, sprite_get_number(sprite_index) - 1);
    }
    
    if (tempo_girando >= tempo_total_giro) {
        girando = false;
        image_index = (resultado_final == 1) ? 0 : 4;
        alarm[0] = 120;
    }
}