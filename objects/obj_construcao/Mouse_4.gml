if (dono != "jogador") exit;
if (obj_controlador.turno != "jogador") exit;
if (!tem_habilidade_construcao) exit;
if (habilidade_usada_este_turno) exit;

usar_habilidade_hemodrenario(id);