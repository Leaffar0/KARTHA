# Sons integrados ao KARTHA

Originais preservados em Audio/. Cópias WAV mono, 44.1 kHz, com pico ajustado e fades curtos, em sounds/. Trechos longos limitados para efeitos de ação.

- `snd_papel_deslize`: Compra de carta e equipamento deslizando; origem `card-slide-1.ogg`.
- `snd_papel_encaixe`: Encaixe do equipamento; origem `card-place-2.ogg`.
- `snd_dado_mesa`: Pouso dos dados; origem `die-throw-1.ogg`.
- `snd_metal_defesa`: Defesa e crítico; origem `floraphonic-metal-hit-95-200424.mp3`.
- `snd_metal_golpe`: Golpe Duplo; origem `floraphonic-metal-whoosh-hit-4-201906.mp3`.
- `snd_madeira_mimic`: Imitação; origem `freesound_community-creaking-floor-owi-83462.mp3`.
- `snd_papel_digestao`: Digestão e Ferida Exposta; origem `freesound_community-tear-paper-103161.mp3`.
- `snd_sussurro_sombra`: Sombra e Visão do Véu; origem `freesound_community-whisper-trail-3-87622.mp3`.

Licença: License.txt acompanha o pacote Casino Audio da Kenney (CC0). Os MP3 adicionais foram fornecidos pelo usuário; esta licença não comprova os termos desses arquivos. Guarde os links/licenças correspondentes junto dos originais.

Volumes: cada recurso .yy usa volume 0.7; o ganho por ação está nas chamadas audio_play_sound. Habilidades: scripts/scr_apresentacao/scr_apresentacao.gml. Equipamentos: scripts/scr_cartas e objects/obj_controlador/Step_0.gml. Dados: objects/obj_dado/Step_0.gml.

## Variações adicionais

- `snd_papel_deslize_2`: `card-slide-2.ogg`.
- `snd_papel_deslize_3`: `card-slide-3.ogg`.
- `snd_papel_encaixe_2`: `card-place-1.ogg`.
- `snd_papel_encaixe_3`: `card-place-3.ogg`.
- `snd_dado_mesa_2`: `die-throw-2.ogg`.
- `snd_dado_mesa_3`: `die-throw-3.ogg`.
- `snd_metal_golpe_2`: `floraphonic-metal-whoosh-hit-9-201909.mp3`.
- `snd_metal_golpe_3`: `floraphonic-metal-whoosh-hit-10-202176.mp3`.
- `snd_metal_defesa_2`: `universfield-hammer-steel-impact-454390.mp3`.
- `snd_corte_ferida`: `universfield-sword-blade-slicing-flesh-352708.mp3`.
- `snd_papel_abrir`: `card-fan-1.ogg`.
- `snd_papel_abrir_2`: `card-fan-2.ogg`.
- `snd_papel_empurrao`: `card-shove-1.ogg`.
- `snd_papel_empurrao_2`: `card-shove-2.ogg`.
- `snd_recurso_toque`: `chip-lay-1.ogg`.
- `snd_recurso_toque_2`: `chip-lay-2.ogg`.

As variações alternam por categoria, sem repetir imediatamente nem consumir o gerador aleatório da partida. Intervalo mínimo de 75 ms por categoria evita acumular sons simultâneos. Grupos e volumes em `tocar_som_variado`, no script scr_apresentacao.
