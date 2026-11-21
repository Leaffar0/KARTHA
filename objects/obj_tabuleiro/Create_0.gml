ambiente_mesa = mesa_ambiente_criar();

gravura_pronta=false;
gravura_bases = [];
turno_do_selo = "";
tempo_piscada = 1;
gravura_x=-10000;
gravura_y=-10000;

gravura_efeitos_hover=array_create(8,0);
gravura_efeitos_pressao=array_create(8,0);
gravura_efeitos_ocupados=array_create(8,false);
