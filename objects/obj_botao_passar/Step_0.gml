if obj_controlador.vida_jogador <= 0 or obj_controlador.vida_inimigo <= 0  exit;
if keyboard_check_pressed(vk_space){
	passar_turno_jogador();
}	