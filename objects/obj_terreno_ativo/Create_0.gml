entrando = true;
entrada_progresso = 0;
entrada_duracao = 45; // dramático: mais longo que o pulo normal de carta

origem_x = x;
origem_y = y;
destino_x = x;
destino_y = y;

rotacoes_extras = 2;     // quantas voltas completas dá no ar antes de assentar (drama)
angulo_final = +90;      // deitada, virada pra direita -- igual à rotação do próprio slot na room

escala_base = 1;         // recalculado externamente logo após a criação (ver obj_carta)
pulso_x = 1;
pulso_y = 1;
depth = -500;