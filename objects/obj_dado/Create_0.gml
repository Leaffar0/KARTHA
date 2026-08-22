sprite_index = spr_dado_d6;
image_speed = 0.5;
image_index = 0;
image_xscale = 3;
image_yscale = 3;
depth = -2000;

girando = false;
tempo_girando = 0;
tempo_total_giro = 78;

tamanho_dado = 6;
valor_final = 1;
modificador_exibido = 0;
callback = noone;
destino_x = x;
destino_y = y;

pos_inicial_x = x;
pos_inicial_y = y;
altura_voo = 0;
altura_maxima_dado = 85;
desvio_lateral = choose(-1, 1) * irandom_range(8, 18);
escala_base_dado = 3;
tempo_pouso = 0;
duracao_pouso = 12;
progresso_revelacao = 0;
// destino_x e destino_y já devem existir (vindos de rolar_dado_visual)
