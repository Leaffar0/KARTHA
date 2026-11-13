var _w=display_get_gui_width(), _h=display_get_gui_height();
draw_set_alpha(1); draw_set_color(make_color_rgb(15,18,24)); draw_rectangle(0,0,_w,_h,false);
draw_set_font(Fontenil); draw_set_halign(fa_center); draw_set_valign(fa_middle); draw_set_color(c_white);
draw_text_transformed(_w/2,28,"LABORATÓRIO DE EFEITOS",0.8,0.8,0);
draw_text_transformed(_w/2,54,"Prévia visual e sonora — sua partida está guardada",0.45,0.45,0);
var _bw=(_w-40)/4;
for(var i=0;i<8;i++) {
    var _x=20+(i mod 4)*_bw, _y=80+floor(i/4)*42;
    draw_set_color(i==modo?make_color_rgb(89,65,31):make_color_rgb(30,36,45));
    draw_roundrect(_x,_y,_x+_bw-6,_y+34,false); draw_set_color(i==modo?c_yellow:c_white);
    desenhar_texto_ajustado_ui(string(i+1)+"  "+rotulos[i],_x+10,_y+17,_bw-26,0.52);
}
var _cx=_w/2, _cy=170+max(40,(_h-270)*0.5), _t=min(tempo,180);
var _altura_carta=max(40,min(160,_h-300));
if(modo==0) desenhar_marca_mesa(_cx,_cy,_t,false);
if(modo==4) {
    desenhar_quebra_castelo(_cx,_cy,_t,2);
    if(_t>=55) { draw_set_alpha(clamp((_t-55)/28,0,1)); draw_set_color(c_yellow); draw_text_transformed(_cx,_cy,"VITÓRIA",1.4,1.4,0); draw_set_alpha(1); }
} else if(modo==7) {
    draw_set_color(c_aqua); draw_text_transformed(_cx,_cy,"SOM: "+string_upper(grupos[grupo]),0.9,0.9,0);
    draw_set_color(c_white); draw_text_transformed(_cx,_cy+40,"Setas: categoria | Espaço: próxima variação",0.52,0.52,0);
} else {
    var _qtd=modo==2?3:((modo==3 || modo==1)?2:1);
    for(var i=0;i<_qtd;i++) {
        var _dados=amostras[modo==2?i:0];
        var _spr=_dados.sprite_carta==noone?spr_carta_placeholder:_dados.sprite_carta;
        var _px=_cx+(i-(_qtd-1)*0.5)*min(180,_w/4), _py=_cy;
        var _esc=min(120/sprite_get_width(_spr),_altura_carta/sprite_get_height(_spr));
        var _rot=0;
        if(modo==2) {
            var _v=personalidade_visual(_dados.nome,i==2,tempo*16.6667+6800);
            _py+=_v.y; _esc*=_v.escala; _rot=_v.rotacao;
        }
        if(modo==3 && i==0) {
            if(_t<20) _px-=sin(_t/20*pi/2)*12;
            else if(_t<32) _px+=lerp(-12,70,power((_t-20)/12,2));
            else _px+=70*power(max(0,1-(_t-32)/16),2);
        }
        if(modo==3 && i==1 && _t>=32) _px+=sin(clamp((_t-32)/18,0,1)*pi)*10;
        if(modo==5) {
            var _ispr=item.sprite_carta==noone?spr_carta_placeholder:item.sprite_carta;
            var _ie=min(120/sprite_get_width(_ispr),_altura_carta/sprite_get_height(_ispr));
            var _altura_real=sprite_get_height(_spr)*_esc;
            var _recuo=-clamp(_altura_real*0.055,12,19)+4;
            var _encaixe=posicao_encaixe_equipamento(_px,_py+130,_px,_py+_recuo,_altura_real,0,clamp(_t/32,0,1));
            draw_sprite_ext(_ispr,0,_encaixe.x,_encaixe.y,_ie,_ie,0,c_white,1);
        }
        draw_sprite_ext(_spr,0,_px,_py,_esc,_esc,_rot,c_white,1);
        draw_set_color(c_silver); draw_text_transformed(_px,_py+_altura_carta/2+18,_dados.nome,0.44,0.44,0);
    }
    if(modo==3 && _t<65) { draw_set_color(c_yellow); draw_text_transformed(_cx,_cy-115,"CONTRA-ATAQUE",0.8,0.8,0); }
    // Camada superior: os mesmos renderizadores da partida, após as cartas.
    if(modo==6) desenhar_ativacao_habilidade_gui(_cx,_cy,_altura_carta,habilidades[habilidade],tempo);
    if(modo==1) {
        var _dist=min(180,_w/4)*0.5, _tx=_cx+_dist, _ty=_cy;
        if(magia==1 && tempo<106) {
            var _p=clamp(tempo/70,0,1), _suave=_p*_p*(3-2*_p);
            var _fx=lerp(_cx-_dist,_tx,_suave), _fy=_cy-sin(_p*pi)*100;
            var _impacto=tempo>=70, _ti=max(0,tempo-70);
            var _ex=1, _ey=1;
            if(_impacto) {
                if(_ti<5) {var _q=1-power(1-_ti/5,2);_ex=lerp(1,1.5,_q);_ey=lerp(1,0.35,_q);}
                else {var _q=power(clamp((_ti-5)/8,0,1),2);_ex=lerp(1.5,0,_q);_ey=lerp(0.35,0,_q);}
            }
            desenhar_projetil_magia_gui(spr_bola_fogo_projetil,0,_fx,_fy,_ex,_ey,270,c_white,1,_impacto,_ti,1);
        } else if(magia!=1) {
            var _cores=[c_aqua,c_aqua,c_aqua,c_aqua,c_aqua];
            desenhar_ligacao_gui(_cx-_dist,_cy,_tx,_ty,max(40,_altura_carta*0.45),_cores[magia],tempo);
        }
    }
    draw_set_font(Fontenil);draw_set_halign(fa_center);draw_set_valign(fa_middle);
}
if(modo==1) { draw_set_color(c_silver); draw_text_transformed(_w/2,_h-88,magias[magia]+" — setas para escolher",0.48,0.48,0); }
if(modo==6) { draw_set_color(c_silver); draw_text_transformed(_w/2,_h-88,"Setas: escolher habilidade",0.48,0.48,0); }
draw_set_alpha(1); draw_set_color(c_silver);
draw_text_transformed(_w/2,_h-58,"Espaço: repetir | P: "+(pausado?"retomar":"pausar")+" | R: repetição "+(repetir?"ligada":"desligada"),0.5,0.5,0);
draw_text_transformed(_w/2,_h-30,"ESC / F7: voltar à partida pausada",0.55,0.55,0);
draw_set_font(-1); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_color(c_white);
