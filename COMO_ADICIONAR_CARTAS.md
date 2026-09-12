# Como adicionar novas cartas ao KARTHA

Este guia descreve o cadastro mínimo para uma carta funcionar contra a IA e no multiplayer online.

## Visão geral

Cada carta é cadastrada em dois lugares:

1. No GameMaker, em `scripts/scr_dados_cartas/scr_dados_cartas.gml`. Essa definição controla a aparência, a mão, a IA e a partida local.
2. No servidor, em `online-server/src/game/cards.ts`. Essa definição é a autoridade das regras no multiplayer.

O identificador online deve ser único, em minúsculas e sem espaços. Exemplo: `pocao_gelada`.

Depois de criar as duas definições, adicione a função ao fim de `catalogo_cartas()` e o identificador na mesma posição de `online_catalogo_ids()`. Adicione também o identificador em `CARD_ORDER`, no servidor.

Se a carta não deve aparecer em baralhos normais, como uma evolução ou uma criatura criada por Mitose, não a coloque nos três catálogos. Nesse caso, cadastre-a no `switch` de `online_funcao_carta_por_id()` e em `CARD_DEFINITIONS`.

## Custos

No GameMaker:

```gml
custo: { tipo: "mana", quantidade: 2 }
```

Para custos mistos:

```gml
custo: [
    { tipo: "mana", quantidade: 1 },
    { tipo: "sucata", quantidade: 2 }
]
```

No servidor:

```ts
cost: cost("mana", 2)
```

Ou:

```ts
cost: mixed(["mana", 1], ["sucata", 2])
```

Os tipos aceitos são `mana`, `sangue`, `ossos`, `sucata` e `qualquer`.

## Magia simples com o sistema genérico

Este sistema serve para efeitos diretos. Não é necessário criar um novo `switch`.

GameMaker:

```gml
function criar_dados_magica_chama_menor() {
    return {
        categoria: "magica",
        nome: "Chama Menor",
        sprite_carta: spr_carta_chama_menor,
        custo: { tipo: "mana", quantidade: 1 },
        alvo: "inimigo",
        efeitos: [
            { tipo: "dano", valor: 3 },
            { tipo: "condicao", chave: "queimado" }
        ]
    };
}
```

Servidor:

```ts
chama_menor: {
  id: "chama_menor",
  name: "Chama Menor",
  category: "magica",
  cost: cost("mana", 1),
  target: "inimigo",
  effects: [
    { tipo: "dano", valor: 3 },
    { tipo: "condicao", chave: "queimado" },
  ],
},
```

Valores de `alvo`:

- `"inimigo"`: somente tropas inimigas.
- `"aliado"`: somente tropas do jogador que usou a carta.
- `"qualquer"`: qualquer tropa.
- `"nenhum"`: a carta é usada sem selecionar tropa.

Efeitos genéricos disponíveis:

- `{ tipo: "dano", valor: 3 }`
- `{ tipo: "cura", valor: 4 }`
- `{ tipo: "vida_maxima", valor: 2 }`
- `{ tipo: "destruir", limite_vida: 5 }`
- `{ tipo: "comprar", quantidade: 2 }`
- `{ tipo: "recurso", chave: "mana", quantidade: 1 }`
- `{ tipo: "condicao", chave: "veneno" }`

Condições aceitas pelo executor atual: `veneno`, `queimado`, `gelo`, `choque`, `corrosao`, `loucura`, `adormecer`, `sangrando`, `apodrecer` e `regeneracao`.

A IA e o servidor usam esses mesmos campos. Portanto, uma magia declarativa nova já pode ser usada pelos dois jogadores e pela IA.

## Item consumível genérico

É igual à magia, mudando apenas a categoria.

GameMaker:

```gml
function criar_dados_item_tonico() {
    return {
        categoria: "item_consumivel",
        nome: "Tônico",
        sprite_carta: spr_carta_tonico,
        custo: { tipo: "mana", quantidade: 1 },
        alvo: "aliado",
        efeitos: [
            { tipo: "cura", valor: 4 },
            { tipo: "vida_maxima", valor: 1 }
        ]
    };
}
```

Servidor:

```ts
tonico: {
  id: "tonico",
  name: "Tônico",
  category: "item_consumivel",
  cost: cost("mana", 1),
  target: "aliado",
  effects: [
    { tipo: "cura", valor: 4 },
    { tipo: "vida_maxima", valor: 1 },
  ],
},
```

## Recurso que vale mais de uma unidade

Uma carta de recurso especial continua ocupando somente um espaço no tabuleiro. Ao ser virada, todas as unidades dela são gastas juntas; se o custo for menor, o excesso é perdido.

GameMaker:

```gml
function criar_dados_mana_condensada() {
    return criar_dados_recurso_especial(
        "Mana Condensada", "mana", 2, spr_mana_condensada
    );
}
```

Servidor:

```ts
mana_condensada: {
  id: "mana_condensada",
  name: "Mana Condensada",
  category: "recurso",
  cost: [],
  resourceType: "mana",
  resourceAmount: 2,
},
```

## Carta selada para o Abismo

Adicione o marcador na definição. Quando a carta sair da mão, do campo, de uma construção, de um equipamento ou de um terreno e normalmente iria ao descarte, ela será enviada ao Abismo.

GameMaker:

```gml
selo_abissal: true
```

Servidor:

```ts
abyssSeal: true
```

## Tags e sinergias de equipamento

As tags identificam grupos de tropas sem depender do nome da carta.

GameMaker, na tropa:

```gml
tags: ["morto_vivo", "guerreiro"]
```

GameMaker, no equipamento:

```gml
sinergias: [
    { tag: "morto_vivo", bonus_dano: 2, bonus_defesa: 1 }
]
```

Servidor, na tropa:

```ts
tags: ["morto_vivo", "guerreiro"]
```

Servidor, no equipamento:

```ts
synergies: [
  { tag: "morto_vivo", bonus_dano: 2, bonus_defesa: 1 },
]
```

Os bônus só são aplicados quando a tropa equipada possui a tag pedida.

## Tropa comum

GameMaker:

```gml
function criar_dados_ornitorrinco() {
    return {
        categoria: "tropa",
        nome: "Ornitorrinco",
        sprite_carta: spr_carta_ornitorrinco,
        vida: 11,
        dado_dano: 8,
        qtd_dados_dano: 1,
        mod_dano: 1,
        dado_dano_magico: 0,
        qtd_dados_dano_magico: 1,
        mod_dano_magico: 0,
        defesa_fisica: 1,
        defesa_magica: 0,
        nivel_inteligencia: 1,
        mochila: 2,
        custo: { tipo: "sangue", quantidade: 1 },
        habilidades: [],
        tags: ["animal"]
    };
}
```

Servidor:

```ts
ornitorrinco: {
  ...troop("ornitorrinco", "Ornitorrinco", 11, 8, 1, 1, 0, 1, 2,
    cost("sangue", 1)),
  tags: ["animal"],
},
```

A ordem dos números de `troop` é: vida, dado físico, modificador físico, defesa física, defesa mágica, inteligência e espaços de item. Os argumentos seguintes são custo, habilidades, quantidade de dados físicos, dado mágico, modificador mágico e quantidade de dados mágicos.

Para uma tropa puramente mágica, use dado físico `0` e um dado mágico maior que `0`.

## Evolução e Mitose

Na tropa base do GameMaker, informe:

```gml
funcao_evolucao: criar_dados_ornitorrinco_ancestral
```

No servidor:

```ts
evolvesTo: "ornitorrinco_ancestral"
```

Cadastre a evolução em `CARD_DEFINITIONS` e no `switch` de `online_funcao_carta_por_id()`, mas não no baralho normal.

Para uma tropa com Mitose, o servidor pode escolher qual criatura será criada:

```ts
mitosisChild: "filhote_ornitorrinco"
```

No GameMaker, efeitos especiais de habilidade continuam sendo tratados pelas rotinas de habilidade. O campo genérico cobre os dados da tropa, mas uma habilidade nova com comportamento próprio precisa de código próprio.

## Quando ainda é necessário programar uma regra

Use os efeitos declarativos para ações imediatas. Crie código específico quando a carta disser algo como:

- “quando uma tropa morrer”;
- “durante os próximos três turnos”;
- “copie a última carta”;
- “escolha uma carta no baralho”;
- “antes que o inimigo ataque”;
- qualquer efeito que abra uma escolha ou espere outro acontecimento.

Nesses casos, use uma chave única em `efeito_tipo`/ `effect` e trate essa chave no fluxo da categoria correspondente, tanto no GameMaker quanto no servidor.

## Checklist final

1. Importar o sprite no GameMaker.
2. Criar a função `criar_dados_...`.
3. Adicionar a função a `catalogo_cartas()`.
4. Adicionar o ID na mesma posição de `online_catalogo_ids()`.
5. Criar a entrada em `CARD_DEFINITIONS`.
6. Adicionar o ID a `CARD_ORDER` se a carta puder entrar no baralho.
7. Confirmar que o baralho continua com 50 cartas.
8. Executar a compilação do GameMaker.
9. Executar `npm run typecheck` dentro de `online-server`.
10. Testar a carta em partida local e em uma sala online com dois clientes.
