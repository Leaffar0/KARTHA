girando = false;
tempo_girando = 0;
tempo_total_giro = 90; // duração do arremesso
resultado_final = 0;
callback = noone;
escala_moeda = 1;
pos_inicial_x = 0;
pos_inicial_y = 0;
destino_x = 0;
destino_y = 0;
depth = -3000;
image_speed = 0; // impede o GameMaker de animar sozinho, deixando só nosso controle manual

// Trajetória balística (arco de lançamento, igual o dado)
altura_voo = 0;
altura_maxima_moeda = 110;
desvio_lateral_moeda = 0; // definido em jogar_moeda_visual, dá um leve desvio lateral

// Rotação (torque) durante o voo
angulo_moeda = 0;
velocidade_rotacao = 0;

// Escala elástica (squash/stretch) pro impacto no chão
moeda_escala_x = 1;
moeda_escala_y = 1;

// Som da moeda
som_arremesso = noone;
som_volume = 0;