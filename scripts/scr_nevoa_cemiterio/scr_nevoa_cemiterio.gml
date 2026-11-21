function nevoa_iniciar_turno(_dono) {
    var _c=obj_controlador;
    if(_c.modo_partida=="online" || _c.nevoa_turno_sorteado==_dono) return;
    _c.nevoa_turno_sorteado=_dono;
    _c.nevoa_dono="";
    if(_c.terreno_ativo=="cemiterio" && irandom_range(1,100)<=20)
        _c.nevoa_dono=lado_oposto(_dono);
}

function lado_oculto_nevoa(_lado) {
    if (!instance_exists(obj_controlador)) return false;
    var _c=obj_controlador;
    if(!variable_instance_exists(_c,"nevoa_dono") || _c.terreno_ativo!="cemiterio"
        || !_c.partida_iniciada || _c.nevoa_dono=="") return false;
    var _observador=_c.modo_partida=="local"?_c.turno:"jogador";
    return _lado==_c.nevoa_dono && _lado!=_observador;
}

function tropa_oculta_nevoa(_carta) {
    return instance_exists(_carta) && variable_instance_exists(_carta,"categoria")
        && _carta.categoria=="tropa" && _carta.travada && !_carta.esta_na_mao
        && lado_oculto_nevoa(_carta.dono);
}

function nevoa_atualizar_consulta() {
    if(terreno_ativo!="cemiterio" || !partida_iniciada) nevoa_dono="";
    if(nevoa_dono!=nevoa_dono_anunciado) {
        if(nevoa_dono!="") mostrar_feedback("NÉVOA DO CEMITÉRIO — TROPAS OCULTAS ATÉ O FIM DO TURNO",room_width/2,room_height/2,c_silver,100);
        else if(nevoa_dono_anunciado!="") mostrar_feedback("A NÉVOA SE DISSIPOU",room_width/2,room_height/2,c_silver,65);
        nevoa_dono_anunciado=nevoa_dono;
    }
    if(tropa_oculta_nevoa(carta_preview)) carta_preview=noone;
    if(tropa_oculta_nevoa(carta_menu_aberto)) carta_menu_aberto=noone;
    if(tropa_oculta_nevoa(previa_visual_carta)) previa_visual_carta=noone;
}

// Renderização substituta: nunca desenha arte, atributos, equipamento ou condições.
function desenhar_tropa_oculta_nevoa(_carta) {
    var _w=global.CARTA_LARGURA, _h=global.CARTA_ALTURA;
    if(instance_exists(_carta.slot_atual)) {
        _w=sprite_get_width(_carta.slot_atual.sprite_index);
        _h=sprite_get_height(_carta.slot_atual.sprite_index);
    }
    draw_sprite_ext(spr_verso_kartha,0,_carta.x,_carta.y,_w/sprite_get_width(spr_verso_kartha),
        _h/sprite_get_height(spr_verso_kartha),0,make_color_rgb(155,158,161),0.85);
    draw_set_font(Fontenil); draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(c_silver);draw_text_transformed(_carta.x,_carta.y,"?",0.55,0.55,0);
    draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_font(-1);draw_set_color(c_white);
}

function desenhar_cortina_nevoa() {
    if(!instance_exists(obj_controlador) || obj_controlador.nevoa_dono==""
        || obj_controlador.terreno_ativo!="cemiterio") return;
    var _observador=obj_controlador.modo_partida=="local"?obj_controlador.turno:"jogador";
    if(obj_controlador.nevoa_dono==_observador) return;
    var _cam=view_camera[0];
    var _sx=display_get_gui_width()/camera_get_view_width(_cam);
    var _sy=display_get_gui_height()/camera_get_view_height(_cam);
    // A cortina acompanha as casas do lado oculto e as tropas que avançaram.
    var _x1=100000,_x2=-100000,_y1=100000,_y2=-100000;
    for(var _i=0;_i<instance_number(obj_slot_batalha);_i++) {
        var _s=instance_find(obj_slot_batalha,_i);
        var _lado=obj_controlador.nevoa_dono=="inimigo"?_s.posicao<2:_s.posicao>2;
        var _oculta=instance_exists(_s.carta_atual)&&tropa_oculta_nevoa(_s.carta_atual);
        if(!_lado && !_oculta) continue;
        _x1=min(_x1,_s.x-38);_x2=max(_x2,_s.x+38);
        _y1=min(_y1,_s.y-42);_y2=max(_y2,_s.y+42);
    }
    if(_x2<_x1) return;
    _x1=(_x1-camera_get_view_x(_cam))*_sx;_x2=(_x2-camera_get_view_x(_cam))*_sx;
    _y1=(_y1-camera_get_view_y(_cam))*_sy;_y2=(_y2-camera_get_view_y(_cam))*_sy;
    for(var _n=0;_n<9;_n++) {
        var _yc=lerp(_y1,_y2,(_n+0.5)/9);
        for(var _lado=-1;_lado<=1;_lado+=2) {
            draw_primitive_begin(pr_trianglestrip);
            for(var _j=0;_j<=24;_j++) {
                var _p=_j/24,_px=lerp(_x1-18*_sx,_x2+18*_sx,_p);
                var _py=_yc+sin(_p*9+current_time*0.0006+_n)*9*_sy;
                var _a=power(sin(_p*pi),0.6)*0.48;
                draw_vertex_color(_px,_py,make_color_rgb(145,150,154),_a);
                draw_vertex_color(_px,_py+_lado*(_y2-_y1)*0.14,c_white,0);
            }
            draw_primitive_end();
        }
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
