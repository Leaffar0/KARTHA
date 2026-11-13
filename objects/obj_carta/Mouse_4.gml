if (mouse_sobre_painel_regras() || mouse_sobre_historico()) exit;
if (obj_controlador.ui_modal.visao_veu_ativa || obj_controlador.ui_modal.digestao_selecao_ativa || obj_controlador.ui_modal.troca_item_selecao_ativa) exit;
if (!travada || !lado_controlado_localmente(dono)) exit;

// se o menu de outra carta estiver aberto e o clique caiu em cima dele, ignora -- deixa o Step cuidar disso
if (obj_controlador.carta_menu_aberto != noone && obj_controlador.carta_menu_aberto != id && obj_controlador.menu_escala > 0.5) {
    var _carta_menu = obj_controlador.carta_menu_aberto;
    var _opcoes_menu = obter_opcoes_menu(_carta_menu);
    var _n_menu = array_length(_opcoes_menu);
    
    var _layout_menu = layout_menu_tropa(_carta_menu, _n_menu);
    var _largura_opcao = _layout_menu.largura + 20;
    var _altura_total_menu = _layout_menu.total;
    var _menu_base_x = _layout_menu.x;
    var _menu_base_y = _layout_menu.y;

    if (mouse_x >= _menu_base_x && mouse_x <= _menu_base_x + _largura_opcao 
        && mouse_y >= _menu_base_y && mouse_y <= _menu_base_y + _altura_total_menu) {
        exit; // o clique foi no menu, não nessa carta -- ignora a seleção
    }
}

obj_controlador.menu_submenu = "";
if (obj_controlador.carta_menu_aberto == id) {
    obj_controlador.carta_menu_aberto = noone;
    obj_controlador.tropa_selecionada = noone;
} else {
    obj_controlador.carta_menu_aberto = id;
    obj_controlador.tropa_selecionada = id;
}
