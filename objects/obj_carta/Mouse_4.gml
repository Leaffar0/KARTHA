if (!travada || dono != "jogador") exit;
if (obj_controlador.turno != "jogador") exit;
if (obj_controlador.rolagens_pendentes > 0) exit;
if (!tropa_pode_agir(id)) exit;

// se o menu de outra carta estiver aberto e o clique caiu em cima dele, ignora -- deixa o Step cuidar disso
if (obj_controlador.carta_menu_aberto != noone && obj_controlador.carta_menu_aberto != id && obj_controlador.menu_escala > 0.5) {
    var _carta_menu = obj_controlador.carta_menu_aberto;
    var _opcoes_menu = obter_opcoes_menu(_carta_menu);
    var _n_menu = array_length(_opcoes_menu);
    
    var _largura_opcao = 80;
    var _altura_opcao = 20;
    var _espaco_opcao = 6;
    var _altura_total_menu = _n_menu * _altura_opcao + (_n_menu - 1) * _espaco_opcao;
    
    var _menu_base_x = _carta_menu.x + (global.CARTA_LARGURA * 0.5);
    var _menu_base_y = _carta_menu.y - _altura_total_menu/2;
    
    if (mouse_x >= _menu_base_x && mouse_x <= _menu_base_x + _largura_opcao 
        && mouse_y >= _menu_base_y && mouse_y <= _menu_base_y + _altura_total_menu) {
        exit; // o clique foi no menu, não nessa carta -- ignora a seleção
    }
}

if (obj_controlador.carta_menu_aberto == id) {
    obj_controlador.carta_menu_aberto = noone;
} else {
    obj_controlador.carta_menu_aberto = id;
}