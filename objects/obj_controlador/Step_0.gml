// =============================================================================
// obj_controlador — Step Event
// =============================================================================
if (variable_global_exists("laboratorio_voltando") && global.laboratorio_voltando) {
    global.laboratorio_voltando = false;
    room_persistent = global.laboratorio_persistencia;
    view_enabled = global.laboratorio_views;
    keyboard_clear(vk_f7); keyboard_clear(vk_escape);
    exit;
}
if (keyboard_check_pressed(vk_f7) && modo_partida != "online"
    && rolagens_pendentes == 0 && (controlador_modal_atual(id) == "" || ui_modal.pausa_ativa)
    && vida_jogador > 0 && vida_inimigo > 0) {
    abrir_laboratorio_visual(); exit;
}
for (var _m = array_length(marcas_mesa)-1; _m >= 0; _m--) {
    marcas_mesa[_m].tempo++;
    if (marcas_mesa[_m].tempo >= 150) array_delete(marcas_mesa, _m, 1);
}
for(var _lv=array_length(ligacoes_visuais)-1;_lv>=0;_lv--) {
    ligacoes_visuais[_lv].t++;
    if(ligacoes_visuais[_lv].t>=54) array_delete(ligacoes_visuais,_lv,1);
}
var _painel_som=controlador_modal_atual(id);
if(_painel_som=="") _painel_som=ui_modal.historico_aberto?"historico":(instance_exists(carta_menu_aberto)?"acoes":"");
if(_painel_som!=audio_painel_anterior) {
    if(_painel_som!="fim_partida") tocar_som_variado(_painel_som==""?"painel_fechar":"painel_abrir",0.22);
    audio_painel_anterior=_painel_som;
}
if(menu_submenu!=audio_submenu_anterior) { if(instance_exists(carta_menu_aberto)) tocar_som_variado("clique",0.20); audio_submenu_anterior=menu_submenu; }
if(historico_pagina!=audio_historico_pagina) { tocar_som_variado("pagina",0.20);audio_historico_pagina=historico_pagina; }
atualizar_escala_hud(id);
if (instance_exists(carta_preview)) {
    if (previa_visual_carta != carta_preview) {
        previa_visual_carta = carta_preview;
        previa_visual_progresso = 0;
        tocar_som_variado("abrir", 0.20);
    }
    previa_visual_progresso = min(1, previa_visual_progresso + 1 / 12);
} else {
    previa_visual_progresso = max(0, previa_visual_progresso - 1 / 8);
    if (previa_visual_progresso == 0) previa_visual_carta = noone;
}
if (modo_partida == "online" && colyseus_is_ready()) colyseus_process();
if (modo_partida == "online") online_atualizar_atraso_visual();
apresentacao_atualizar(id);
if (carta_preview != noone && instance_exists(carta_preview)) {
    if (detalhes_carta != carta_preview) {
        detalhes_carta = carta_preview;
        detalhes_pagina = 0;
        detalhes_total_paginas = 1;
    }
    detalhes_pagina = clamp(detalhes_pagina + mouse_wheel_down() - mouse_wheel_up(),
        0, max(0, detalhes_total_paginas - 1));
} else {
    detalhes_carta = noone;
    detalhes_pagina = 0;
}
controlador_atualizar_fluxo(id);
atualizar_painel_regras();
if (keyboard_check_pressed(vk_f6) && global.DEBUG_COMBATE && modo_partida != "online"
    && controlador_modal_atual(id) == "" && carta_preview == noone) debug_abrir_cenarios();
if (mouse_sobre_historico()) historico_pagina = clamp(historico_pagina + mouse_wheel_down() - mouse_wheel_up(), 0, max(0, historico_total_paginas - 1));

#region Watchdog de segurança
// Se rolagens_pendentes ficar travado (algum dado/moeda não decrementou por bug),
// força o reset depois de 10 segundos pra nunca deixar o "Passar Turno" travado pra sempre.
if (rolagens_pendentes > 0) {
    rolagens_pendentes_timer += 1;
    if (rolagens_pendentes_timer > 600) {
        show_debug_message("AVISO: rolagens_pendentes travado em " + string(rolagens_pendentes) + ", forçando reset.");
        rolagens_pendentes = 0;
        rolagens_pendentes_timer = 0;
    }
} else {
    rolagens_pendentes_timer = 0;
}
#endregion

atualizar_animacao_dano_castelo();

// Atualizações visuais independentes da lógica: continuam durante modais e fim da partida.
if (onda_turno_timer > 0) onda_turno_timer--;
if (ui_modal.visao_veu_ativa) visao_veu_revelacao_timer++;
for (var _i_anim_item = array_length(animacoes_item) - 1; _i_anim_item >= 0; _i_anim_item--) {
    var _anim_carta = animacoes_item[_i_anim_item];
    _anim_carta.timer++;
    if (_anim_carta.tipo == "armadilha" && _anim_carta.timer == 6)
        tocar_som_variado("encaixe", 0.32, 1.10);
    if (_anim_carta.timer >= _anim_carta.duracao) {
        if (is_struct(_anim_carta.equipamento)) _anim_carta.equipamento.visual_em_voo = false;
        if (_anim_carta.tipo == "item" && instance_exists(_anim_carta.tropa))
            tocar_som_variado("encaixe", 0.40, 1);
        array_delete(animacoes_item, _i_anim_item, 1);
    }
}
if (vida_jogador <= 0 || vida_inimigo <= 0) {
    fim_animacao_timer = min(fim_animacao_duracao, fim_animacao_timer + 1);
    if (fim_animacao_timer == 12) tocar_som_variado("metal", 0.48, 0.8);
}

// Opção vinda da tela inicial: abre o livro assim que a instância da room existir.
if (abrir_livro_pendente && instance_exists(obj_livro)) {
    obj_livro.preview_ativo = true;
    obj_livro.mostrando_sumario = true;
    abrir_livro_pendente = false;
    exit;
}

// Compatibilidade com instâncias criadas antes da inicialização dos componentes.
if (!variable_instance_exists(id, "ui_modal") || !is_struct(ui_modal))
    ui_modal = controlador_criar_estado_modal();
if (!variable_struct_exists(ui_modal, "historico_aberto")) ui_modal.historico_aberto = false;
if (!variable_instance_exists(id, "hud_deslocamento_esquerda")) hud_deslocamento_esquerda = 160;
if (!variable_instance_exists(id, "hud_deslocamento_direita")) hud_deslocamento_direita = 180;

// Abas do HUD: só se revelam quando o mouse se aproxima do respectivo canto.
var _hud_mouse_x = device_mouse_x_to_gui(0);
var _hud_mouse_y = device_mouse_y_to_gui(0);
var _hud_largura_animacao = display_get_gui_width();
var _mostrar_esquerda = ui_modal.historico_aberto || (_hud_mouse_x < 215 && _hud_mouse_y >= 190 && _hud_mouse_y <= 270);
var _mostrar_direita = ui_modal.cemiterio_aberto || (_hud_mouse_x > _hud_largura_animacao - 220 && _hud_mouse_y >= 10 && _hud_mouse_y <= 210);
var _alvo_esquerda = _mostrar_esquerda ? 0 : 160;
var _alvo_direita = _mostrar_direita ? 0 : 180;
hud_deslocamento_esquerda += (_alvo_esquerda - hud_deslocamento_esquerda) * 0.22;
hud_deslocamento_direita += (_alvo_direita - hud_deslocamento_direita) * 0.22;


// O objeto apenas coordena; cada processador decide se consumiu o frame.
if (controlador_processar_fluxo_e_modais(id)) exit;
if (mouse_sobre_painel_regras() || mouse_sobre_historico()) exit;
controlador_processar_interacao(id);
