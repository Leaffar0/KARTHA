if (girando) {
    tempo_girando += 1;
    
    // desliza visualmente do atacante até o defensor enquanto gira
    var _progresso = tempo_girando / tempo_total_giro;
    x = lerp(pos_inicial_x, destino_x, _progresso);
    y = lerp(pos_inicial_y, destino_y, _progresso);
    
    if (tempo_girando mod 3 == 0) {
        image_index = irandom_range(0, 5);
    }
    
    if (tempo_girando >= tempo_total_giro) {
        girando = false;
        image_index = valor_final - 1;
        alarm[0] = 45;
    }
}