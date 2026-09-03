#region Arrasto, posição e estado no campo
arrastando = false;
offset_x = 0;
offset_y = 0;
origem_x = x;
origem_y = y;
slot_atual = noone;
destino_x = x;
destino_y = y;
velocidade_movimento = 0.2;
hover_ativo = false;
hover_ativo_externo = false; // controlado pelo obj_controlador, não pela própria carta
travada = false;
dono = "jogador"; // ou "inimigo"
lane_atual = -1;
posicao_atual = -1;
moveu_este_turno = false;
defendendo_castelo = false; // intercepta ataques diretos ao castelo na mesma fileira
#endregion

#region Atributos e custos da carta
vida_maxima = 1; // usado pela condição "regeneração" (limite de cura); atualizado quando a tropa é criada
dado_dano = 4;
mod_dano = 0;
defesa_fisica = 0;
defesa_magica = 0;
// Valores sem equipamento; permitem remover, trocar e roubar itens com segurança.
dado_dano_base = dado_dano;
mod_dano_base = mod_dano;
defesa_fisica_base = defesa_fisica;
mochila_maxima = 1;
requisito_inteligencia_item = 0;
sobrescreve_dado_dano_item = 0;
sobrescreve_mod_dano_item = 0;
custo = noone;
categoria = "tropa";
tipo_recurso = "";
condicao = noone;              // "queimado", "envenenado", "paralisado", etc, ou noone
condicao_turnos_restantes = 0; // -1 = dura pra sempre (até morrer ou ser curada)
condicao_dano_por_turno = 0;
condicao_valor_sorteado = 0; // resultado fixo usado por Apodrecer/Regeneração

dado_efeito = 0;
qtd_dados_efeito = 1;
chance_queimar = 0;

// Armadilha: ciclo de vida "vigiando slot -> pronta pra ativar -> consumida"
armadilha_estado = "";       // "" = não é armadilha ou ainda na mão normal | "vigiando" | "pronta"
armadilha_lane = -1;
armadilha_posicao = -1;
armadilha_balanco_timer = 0;
armadilha_visual_id = noone;

efeito_timer = 0;
efeito_tipo = ""; // qual magia essa carta é: "bola_fogo", "veneno", "gelo", "choque"
vezes_eletrocutado_seguidas = 0; // contador pro efeito de Loucura
loucura_sem_defesa = false;
digestao_usos = 0;
digestao_cadaver_disponivel = false;
carnica_estado_proximo_ataque = ""; // "autoataque" ou "bonus"
itens_equipados = [];
item_ataque_atual = noone;
troca_item_usada_este_turno = false;
funcao_dados_origem = noone;
imune_armadilha_usos = 0;
bonus_mod_dano_item = 0;
bonus_defesa_item = 0;
requisito_inteligencia_item = 0;
cura_item = 0;
tem_item_equipado = false;
quantidade_efeito = 0;
bonus_defesa_global = 0;
efeito_terreno = "";
tem_arte_propria = false;
escala_base = 1; // recalculado sempre que o sprite for atribuído
escala_no_campo = 0.65; // ajuste esse valor até a carta caber certinho no slot
turnos_no_campo = 0;
funcao_evolucao = noone; // função que gera os dados da forma evoluída, ou noone se não evolui
efeito_passivo = "";
selo_abissal = false;
arrastar_inicio_x = 0;
arrastar_inicio_y = 0;
// Movimento visual do arrasto: a posição lógica continua no cursor, enquanto
// a arte responde com uma inércia curta, inclinação e elevação.
arrasto_mouse_anterior_x = x;
arrasto_mouse_anterior_y = y;
arrasto_velocidade_x = 0;
arrasto_velocidade_y = 0;
arrasto_offset_visual_x = 0;
arrasto_offset_visual_y = 0;
arrasto_rotacao = 0;
arrasto_escala = 1;
qtd_dados_dano = 1; // quantos dados rolar (ex: 2 pra "2D4")
qtd_dados_dano_magico = 1;
#endregion

#region Animação e apresentação na mão
pulando = false;
pulo_origem_x = 0;
pulo_origem_y = 0;
pulo_destino_x = 0;
pulo_destino_y = 0;
pulo_progresso = 0;
pulo_duracao = 20; // quantos frames o pulo demora (ajuste a velocidade aqui)
pulo_altura = 25;  // altura máxima do arco do pulo
pulo_escala_origem = 1;
pulo_poeira_ao_pousar = false;
escala_animacao = 1;
rotacao_animacao = 0;
pulso_pouso_timer = 0;
pulso_pouso_duracao = 5;
impacto_colocacao_timer = 0;
impacto_colocacao_duracao = 22;
compra_animando = false;
compra_progresso = 0;
compra_duracao = 32;
compra_atraso = 0;
compra_origem_x = x;
compra_origem_y = y;
retorno_invalido_timer = 0;
retorno_invalido_duracao = 24;
evoluindo = false;
evolucao_progresso = 0;
evolucao_duracao = 42;
escala_evolucao = 1;
rotacao_evolucao = 0;
cor_evolucao = c_white;
rotacao_alvo = 0;      // rotação que a carta "deveria" ter (definida pelo leque)
rotacao_atual = 0;     // rotação sendo exibida (suaviza a transição)
escala_alvo = 1;        // tamanho que a carta "deveria" ter
escala_atual = 1;       // escala sendo exibida
y_offset_alvo = 0;      // deslocamento vertical (arco do leque)
y_offset_atual = 0;
esta_na_mao = true;     // controla se aplica os efeitos de mão
mao_base_x = 0;
mao_base_y = 0;
atacou_este_turno = false;
habilidades = [];
iludido_por_imitacao = false;
testado_olhar_vazio = false;
visao_do_veu_usada = false;
imune_armadilha = false;
funcao_mitose = noone;
habilidade_usada_este_turno = false;
sombra_ativa = false;
sombra_cooldown = 0; // turnos restantes até poder usar de novo
habilidade = noone;
nivel_inteligencia = 1;
dado_dano_magico = 0;
mod_dano_magico = 0;
mochila = 1; // quantos itens a tropa pode carregar
#endregion

#region Posições dos atributos no layout da carta
vida_pos_x = 0.10; vida_pos_y = 0.07;
int_pos_x = 0.91; int_pos_y = 0.073;
mochila_pos_x = 0.91; mochila_pos_y = 0.185;
atk_pos_x = 0.12; atk_pos_y = 0.92;
atk_magico_pos_x = 0.37; atk_magico_pos_y = 0.92;
def_pos_x = 0.62; def_pos_y = 0.92;
def_magico_pos_x = 0.87; def_magico_pos_y = 0.92;
#endregion

#region Animação de ataque (golpe estilo Inscryption) e flash de dano
ataque_offset_x = 0;
ataque_offset_y = 0;
ataque_elevacao = 0;
ataque_escala_extra = 0;

// guarda temporário dos parâmetros do golpe em andamento (evita bug de closure com method())
ataque_calc_dir_x = 0;
ataque_calc_dir_y = 0;
ataque_calc_intensidade = 0;
ataque_calc_tempo_golpe = 0;
ataque_calc_tempo_retorno = 0;

dano_flash_timer = 0;
dano_flash_duracao = 25;
recuo_dano_x = 0;
recuo_dano_y = 0;
defesa_impacto_timer = 0;
defesa_impacto_duracao = 20;
tipo_morte_visual = "normal";
morrendo = false;
morte_timer = 0;
morte_duracao = 30;
#endregion

#region Efeito de voo (tropas com a habilidade Voar)
voo_timer = irandom_range(0, 1000); // offset aleatório, pra as tropas não flutuarem todas em sincronia
escala_voo = 1;
#endregion
