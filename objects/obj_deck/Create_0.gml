quantidade_cartas = 30; // sincronizado com o monte real a cada Step agora

// Animação idle (respiração) e pulso ao comprar carta
bob_timer = random(1000); // offset aleatório pra não sincronizar com outras animações
offset_y_bob = 0;
pulso_timer = 0;
pulso_duracao = 14;
escala_deck_x = 1;
escala_deck_y = 1;
offset_y_pulso = 0;