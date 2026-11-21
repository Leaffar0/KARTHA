# Mesa de madeira — KARTHA

Arte criada com a ferramenta integrada de geração de imagens. Quatro fundos alinhados, quase monocromáticos, com alterações discretas nas bordas. Os PNGs originais ficam nesta pasta; spr_mesa_madeira usa cópias de 1152 × 648.

Ordem dos quadros: madeira, Pântano Sombrio, Cemitério, Planícies Profanas. Mistura suave em cerca de 1 segundo (95%); retorna à madeira quando não há terreno. Não afeta regras nem sorteios. F7, tecla T: prévia dos quatro fundos sem alterar a partida.

Prompt base:
Use case: stylized-concept. Production background texture for a hand-drawn monochrome dark fantasy card game, KARTHA. A wooden tabletop seen perfectly straight down, orthographic, entire landscape 16:9 image is the flat table surface, no perspective, no legs, no objects, no cards, no slots, no text, no symbols, no UI, no border frame. Five or six broad horizontal planks of aged wood, a few gentle irregular seams, small knots mostly near the outer edges. Beautiful confident hand-inked outlines, soft graphite rubbings and restrained hand-painted charcoal washes, slightly imperfect human drawn shapes, not photorealistic, not 3D, not pixel art. Palette almost entirely neutral charcoal gray, faint warm gray undertone only; mid-dark surface around #343332, ink seams #252424, faint grain highlights #484643. Low contrast fine grain, keep central 75 percent particularly quiet and spacious so pale black-and-white cards and ivory slot outlines are extremely readable. Soft darker shading toward outer corners, subdued natural overhead diffuse light center, no hard highlights or spotlights. Evocative tactile wood with only a few elegant drawn details, simple and polished, minimal visual clutter. Edge-to-edge opaque artwork, landscape.

Variações sobre a base, preservando enquadramento, tábuas, nós e área central:
pantano: Swamp terrain: a few hand-drawn damp stains and faint mossy gray-green smudges confined to outer 12 percent edges and board seams, a few restrained fine roots near corners. Very desaturated, barely green, no water covering the wood.

cemiterio: Graveyard terrain: cool neutral gray wood, wisps of dry chalky ash rubbed into outer edges, a few faint pale scratch marks at corners like weathered wood, subtle eerie gray haze at edges only. No actual gravestones, bones, skulls, objects, or illustrations.

planicies: Profane plains terrain: neutral charcoal wood with a barely perceptible dusty taupe undertone, a handful of fine branching cracks growing inward from outer corners, thin muted gray chalk traces in grain, no bright magic, no symbols, no glow.

Instruções comuns das variações: Edit this background into a subtle terrain variation for the same game. Preserve exact canvas dimensions, top-down viewpoint, plank count, plank seam positions and all large wood knots. This will crossfade over the original, so maintain registration and almost all of the original texture. Keep hand-inked graphite illustration style. Keep central 75 percent completely unchanged and quiet. All added marks should be low contrast and hand-drawn, sparse, almost monochrome. No cards, UI, text, slots, props, border, perspective, pixel art or photorealism. Opaque background.


Ajuste de cor: shd_mesa_cinza remove 92% da saturação dos quatro fundos e clareia 6% os tons. A correção acontece no desenho, também no F7; os PNGs originais ficam preservados.

## Adereços dos terrenos

O arquivo `aderecos_terrenos.png` contém a folha transparente gerada com o ImageGen integrado. Os seis quadros de `spr_aderecos_terreno` seguem a ordem de leitura da folha. O fundo das peças fica alinhado à fenda enquanto o recorte revela o desenho.

<details>
<summary>Prompt da folha de adereços</summary>

Use case: stylized-concept. A single production terrain-prop sprite atlas for KARTHA, an ink-drawn dark fantasy tabletop card game. Transparent background. Precisely TWO equal columns and THREE equal rows on a square sheet, with SIX independent, centered, fully contained cutouts. Each cell has wide clear margins all around for slicing. Read by rows: TOP LEFT a fan of dark sage marsh grass with two bent cattails pushing through one short jagged wood fissure, TOP RIGHT low creeping broad swamp leaves with a fiddlehead unfurling from a split. MIDDLE LEFT a single chunky tilted arched headstone, incised simple small diamond, chipped face, two tiny weeds where stone rises through a fissure, MIDDLE RIGHT a broken shorter carved grave cross, three small stones and a stub of melted wax candle at its foot. BOTTOM LEFT a low twisting dead thorn bramble with prominent triangular thorns, BOTTOM RIGHT dry splintered thorn stump with two angular prongs and a curl of parched grass. Style a small medieval woodcut from an old grim storybook, irregular hand-inked black contours, a few deliberate hatch strokes, sparse flat muted gray washes. Muted sage for swamp, cool slate for stones, desaturated umber for dry thorn. Must read clearly at only 50px wide in game. Slight three-quarter overhead perspective with an upright silhouette and a narrow ground contact flush at its base. Transparent negative space around every prop, no scenery, ground tiles, paper backing, text, numbers, letters, labels, grid lines, bright colors, glows, realistic rendering or white sticker rim. All six marks distinct, consistent weight and scale.

</details>
