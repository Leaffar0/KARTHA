draw_set_font(Fontenil);

draw_text(20, 20, "Vida jogador: " + string(vida_jogador));
draw_text(20, 45, "Vida inimigo: " + string(vida_inimigo));
draw_text(20, 70, "Fase: " + string(fase));
draw_set_font(-1);

if (vida_jogador <= 0) {
    draw_text(room_width/2 - 50, room_height/2, "VOCE PERDEU");
}
if (vida_inimigo <= 0) {
    draw_text(room_width/2 - 50, room_height/2, "VOCE VENCEU");
}
