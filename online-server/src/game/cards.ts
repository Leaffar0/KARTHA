export type ResourceType = "mana" | "sangue" | "ossos" | "sucata";
export type CardCategory =
  | "tropa" | "recurso" | "construcao" | "magica"
  | "item_equipavel" | "item_consumivel" | "armadilha"
  | "terreno" | "bencao" | "maldicao";

export interface CostPart {
  type: ResourceType | "qualquer";
  amount: number;
}

export interface DeclarativeEffect {
  tipo: "condicao" | "dano" | "cura" | "comprar" | "recurso" | "vida_maxima" | "destruir";
  chave?: string;
  valor?: number;
  quantidade?: number;
  limite_vida?: number;
}

export interface CardSynergy {
  tag: string;
  bonus_dano?: number;
  bonus_defesa?: number;
}

export interface CardDefinition {
  id: string;
  name: string;
  category: CardCategory;
  cost: CostPart[];
  resourceType?: ResourceType;
  resourceAmount?: number;
  abyssSeal?: boolean;
  tags?: string[];
  synergies?: CardSynergy[];
  effects?: DeclarativeEffect[];
  target?: "inimigo" | "aliado" | "qualquer" | "nenhum";
  life?: number;
  attackDie?: number;
  attackDice?: number;
  attackModifier?: number;
  magicDie?: number;
  magicDice?: number;
  magicModifier?: number;
  physicalDefense?: number;
  magicDefense?: number;
  intelligence?: number;
  itemSlots?: number;
  abilities?: string[];
  effect?: string;
  bonusAttack?: number;
  bonusDefense?: number;
  overrideAttackDie?: number;
  intelligenceRequired?: number;
  effectValue?: number;
  evolvesTo?: string;
  mitosisChild?: string;
}

const cost = (type: CostPart["type"], amount: number): CostPart[] => [{ type, amount }];
const mixed = (...parts: Array<[CostPart["type"], number]>): CostPart[] =>
  parts.map(([type, amount]) => ({ type, amount }));

const troop = (
  id: string, name: string, life: number, attackDie: number, attackModifier: number,
  physicalDefense: number, magicDefense: number, intelligence: number, itemSlots: number,
  cardCost: CostPart[] = [], abilities: string[] = [], attackDice = 1,
  magicDie = 0, magicModifier = 0, magicDice = 1,
): CardDefinition => ({
  id, name, category: "tropa", cost: cardCost, life, attackDie, attackDice,
  attackModifier, magicDie, magicDice, magicModifier, physicalDefense,
  magicDefense, intelligence, itemSlots, abilities,
});

export const CARD_DEFINITIONS: Record<string, CardDefinition> = {
  esquilo: { ...troop("esquilo", "Esquilo", 5, 6, 0, 0, 0, 1, 2), evolvesTo: "esquilo_gigante" },
  lobo: { ...troop("lobo", "Lobo", 12, 8, 1, 1, 0, 2, 2, cost("sangue", 1)), evolvesTo: "lobo_alfa" },
  urso: troop("urso", "Urso", 14, 12, 2, 3, 0, 2, 3, cost("ossos", 2)),
  slime: { ...troop("slime", "Slime", 14, 4, 2, 0, 0, 0, 3, [], ["mitose"], 2),
    evolvesTo: "slime_digestao", mitosisChild: "slimet", tags: ["slime"] },
  slimet: troop("slimet", "Slimet", 8, 4, 1, 0, 0, 0, 1),
  mimic: troop("mimic", "Mimic", 16, 10, 0, 3, 0, 1, 3,
    mixed(["sucata", 1], ["sangue", 1]), ["imitacao"], 1, 4, 1),
  olho_demonio: troop("olho_demonio", "Olho Demônio", 8, 6, 0, 0, 0, 1, 1,
    mixed(["mana", 1], ["sangue", 1]), ["alcance_magico", "voar"], 1, 6),
  mago_sombra: troop("mago_sombra", "Mago da Sombra", 20, 0, 0, 0, 2, 2, 2,
    cost("mana", 2), ["sombra_translucida"], 1, 12),
  gato_mago: troop("gato_mago", "Gato Mago", 15, 4, 1, 0, 2, 3, 2,
    mixed(["mana", 2], ["sangue", 1]), ["visao_do_veu"], 1, 4, 1),
  goblin: troop("goblin", "Goblin", 10, 8, 0, 2, 0, 1, 2,
    cost("sangue", 2), ["golpe_duplo"]),
  hollow_jack: troop("hollow_jack", "Hollow Jack", 31, 12, 2, 1, 2, 1, 2,
    mixed(["mana", 3], ["ossos", 1]), ["alcance_magico", "olhar_vazio"], 1, 8, 1),
  esqueleto: troop("esqueleto", "Esqueleto", 14, 8, 0, 0, 0, 1, 2, cost("ossos", 1)),
  shroomilin: troop("shroomilin", "Shroomilin", 10, 4, 2, 2, 0, 0, 1,
    [], ["tiro_burro"], 2),

  sangue: { id: "sangue", name: "Sangue", category: "recurso", cost: [], resourceType: "sangue", resourceAmount: 1 },
  ossos: { id: "ossos", name: "Ossos", category: "recurso", cost: [], resourceType: "ossos", resourceAmount: 1 },
  sucata: { id: "sucata", name: "Sucata", category: "recurso", cost: [], resourceType: "sucata", resourceAmount: 1 },
  mana: { id: "mana", name: "Mana", category: "recurso", cost: [], resourceType: "mana", resourceAmount: 1 },

  torre_vigia: { id: "torre_vigia", name: "Torre de Vigia", category: "construcao", cost: cost("sucata", 1), life: 20, effect: "artilharia" },
  hemodrenario: { id: "hemodrenario", name: "Hemodrenário", category: "construcao", cost: mixed(["sangue", 1], ["sucata", 2]), life: 12, effect: "hemodrenario" },
  maquina_ima: { id: "maquina_ima", name: "Máquina Imã", category: "construcao", cost: cost("sucata", 3), life: 12, effect: "maquina_ima" },

  bola_fogo: { id: "bola_fogo", name: "Bola de Fogo", category: "magica", cost: cost("mana", 2), effect: "bola_fogo" },
  veneno_mortal: { id: "veneno_mortal", name: "Veneno Mortal", category: "magica", cost: cost("mana", 1), effect: "veneno" },
  congelante: { id: "congelante", name: "Congelante", category: "magica", cost: cost("mana", 1), effect: "gelo" },
  choque_eletrico: { id: "choque_eletrico", name: "Choque Elétrico", category: "magica", cost: cost("mana", 1), effect: "choque" },
  dados_manipulados: { id: "dados_manipulados", name: "Dados Manipulados", category: "magica", cost: mixed(["mana", 2], ["qualquer", 1]), effect: "dados_manipulados" },
  refracao_temporal: { id: "refracao_temporal", name: "Refração Temporal", category: "magica", cost: [], effect: "refracao_temporal" },
  eutanasia: { id: "eutanasia", name: "Eutanásia", category: "magica", cost: [], effect: "eutanasia" },
  bloqueio_recurso: { id: "bloqueio_recurso", name: "Bloqueio de Recurso", category: "magica", cost: [], effect: "bloqueio_recurso" },
  sangue_suga: { id: "sangue_suga", name: "Sangue Suga", category: "magica", cost: [], effect: "buscar_sangue" },

  espada_enferrujada: { id: "espada_enferrujada", name: "Espada Enferrujada", category: "item_equipavel", cost: [], bonusAttack: 2 },
  escudo_madeira: { id: "escudo_madeira", name: "Escudo de Madeira", category: "item_equipavel", cost: [], bonusDefense: 2 },
  pocao_cura: { id: "pocao_cura", name: "Poção de Cura", category: "item_consumivel", cost: cost("mana", 1), effect: "cura", effectValue: 5 },
  grimorio_iniciante: { id: "grimorio_iniciante", name: "Grimório Iniciante", category: "item_equipavel", cost: [], effect: "grimorio_iniciante", intelligenceRequired: 1 },
  pocao_mana: { id: "pocao_mana", name: "Poção de Mãna", category: "item_consumivel", cost: [], effect: "buscar_mana" },

  armadilha_urso: { id: "armadilha_urso", name: "Armadilha de Urso", category: "armadilha", cost: [], effect: "armadilha_urso" },
  loucura_mutua: { id: "loucura_mutua", name: "Loucura Mútua", category: "armadilha", cost: [], effect: "loucura_mutua" },
  raizes_espinhosas: { id: "raizes_espinhosas", name: "Raízes Espinhosas", category: "armadilha", cost: [], effect: "raizes_espinhosas" },
  destrocos: { id: "destrocos", name: "Destroços", category: "armadilha", cost: [], effect: "destrocos" },

  bencao_vida: { id: "bencao_vida", name: "Bênção da Vida", category: "bencao", cost: [], effect: "cura_ao_morrer" },
  maldicao_perda: { id: "maldicao_perda", name: "Maldição da Perda", category: "maldicao", cost: [], effect: "perde_vida_ao_morrer" },
  bencao_decomposicao: { id: "bencao_decomposicao", name: "Bênção da Decomposição", category: "bencao", cost: [], effect: "cura_ao_morrer" },
  sangue_por_sangue: { id: "sangue_por_sangue", name: "Sangue por Sangue", category: "maldicao", cost: [], effect: "perde_vida_ao_morrer" },

  bau: { id: "bau", name: "Baú", category: "item_consumivel", cost: [], effect: "comprar_cartas" },
  frasco_sangue: { id: "frasco_sangue", name: "Frasco de Sangue", category: "item_consumivel", cost: [], effect: "revirar_sangue" },
  vitamina_cerebro: { id: "vitamina_cerebro", name: "Vitamina de Cérebro", category: "item_consumivel", cost: [], effect: "aumentar_inteligencia" },
  elmo_ferro: { id: "elmo_ferro", name: "Elmo de Ferro", category: "item_equipavel", cost: [], bonusDefense: 1 },
  frasco_acido: { id: "frasco_acido", name: "Frasco de Ácido", category: "item_consumivel", cost: [], effect: "aplicar_corrosao" },

  pantano_sombrio: { id: "pantano_sombrio", name: "Pântano Sombrio", category: "terreno", cost: cost("ossos", 1), effect: "pantano" },
  cemiterio: { id: "cemiterio", name: "Cemitério", category: "terreno", cost: cost("ossos", 3), effect: "cemiterio" },
  planicies_profanas: { id: "planicies_profanas", name: "Planícies Profanas", category: "terreno", cost: [], effect: "planicies_profanas" },
  espada_quebrada: { id: "espada_quebrada", name: "Espada Quebrada", category: "item_equipavel", cost: [], overrideAttackDie: 8, intelligenceRequired: 1 },

  esquilo_gigante: troop("esquilo_gigante", "Esquilo Gigante", 12, 10, 1, 1, 0, 1, 2, cost("ossos", 1)),
  lobo_alfa: troop("lobo_alfa", "Lobo Alfa", 20, 10, 2, 2, 0, 2, 2, cost("sangue", 1), ["golpe_duplo"]),
  slime_digestao: troop("slime_digestao", "Slime Digestão", 22, 12, 2, 2, 0, 1, 5,
    mixed(["ossos", 2], ["qualquer", 3]), ["digestao", "roubo"]),
  carnica_ambulante: troop("carnica_ambulante", "Carniça Ambulante", 18, 4, 0, 1, 0, 2, 0,
    mixed(["sangue", 3], ["ossos", 3]), ["carnica_frenetica", "ferida_exposta"], 3),
};

export const CARD_ORDER = [
  "esquilo", "lobo", "urso", "slime", "slimet", "mimic", "olho_demonio",
  "mago_sombra", "gato_mago", "goblin", "hollow_jack", "esqueleto", "shroomilin",
  "sangue", "ossos", "sucata", "mana", "torre_vigia", "hemodrenario", "maquina_ima",
  "bola_fogo", "veneno_mortal", "congelante", "choque_eletrico", "dados_manipulados",
  "refracao_temporal", "eutanasia", "bloqueio_recurso", "sangue_suga",
  "espada_enferrujada", "escudo_madeira", "pocao_cura", "grimorio_iniciante",
  "pocao_mana", "armadilha_urso", "loucura_mutua", "raizes_espinhosas", "destrocos",
  "bencao_vida", "maldicao_perda", "bencao_decomposicao", "sangue_por_sangue",
  "bau", "frasco_sangue", "vitamina_cerebro", "elmo_ferro", "frasco_acido",
  "pantano_sombrio", "cemiterio", "planicies_profanas", "espada_quebrada",
] as const;

export function defaultDeck(): string[] {
  const result: string[] = [];
  for (let i = 0; i < 50; i++) result.push(CARD_ORDER[i % CARD_ORDER.length]);
  return result;
}

export function validateDeck(deck: unknown): string[] | undefined {
  if (!Array.isArray(deck) || deck.length !== 50) return undefined;
  if (!deck.every((id) => typeof id === "string" && CARD_DEFINITIONS[id])) return undefined;
  return [...deck];
}
