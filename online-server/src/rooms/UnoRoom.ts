import { Room, Client } from "@colyseus/core";
import {
  KarthaRoomState, PlayerSchema, PublicCardSchema,
} from "./schema/UnoRoomState.ts";
import {
  CARD_DEFINITIONS, CardDefinition, ResourceType, defaultDeck, validateDeck,
} from "../game/cards.ts";

type RoomState = InstanceType<typeof KarthaRoomState>;
type PlayerState = InstanceType<typeof PlayerSchema>;
type PublicCardState = InstanceType<typeof PublicCardSchema>;

interface PrivateCard {
  lifeScale?: number;
  instanceId: string;
  definitionId: string;
}

interface ActiveTrap { instanceId: string; definitionId: string; lane: number; position: number; ready: boolean; targetId: string; }

interface PrivatePlayer {
  traps: ActiveTrap[];
  effects: string[];
  lastNonTroopDefinitionId: string;
  deck: PrivateCard[];
  hand: PrivateCard[];
  discard: PrivateCard[];
  configuredDeck: string[];
}

interface ActionMessage {
  kind?: string;
  payload?: Record<string, unknown>;
  revision?: number;
}

interface ActionResult {
  ok: boolean;
  reason?: string;
  details?: Record<string, unknown>;
  privateSeats?: number[];
}

interface AbilityState {
  used?: boolean;
  shadowTurns?: number;
  shadowCooldown?: number;
  illusion?: boolean;
  gazeTested?: boolean;
  veilUsed?: boolean;
  trapImmunity?: number;
  digestionUses?: number;
  corpseAvailable?: boolean;
  frenzy?: "bonus" | "self";
  itemActionUsed?: boolean;
  grimoireUsed?: boolean;
  grimoireShield?: boolean;
}

interface PendingMagnetChoice {
  sourceCardId: string;
  equipment: string[];
}

interface PendingMitosisChoice {
  source: PrivateCard;
  owner: number;
  candidates: Array<[number, number]>;
}

const ACTIONS = new Set([
  "place_resource", "play_troop", "play_construction",
  "move_troop", "attack", "choose_critical", "end_turn", "set_castle_defense", "evolve_troop",
  "play_spell", "play_item", "play_trap", "activate_trap", "play_effect",
  "use_ability", "use_construction", "remove_item", "transfer_item", "use_item_ability", "choose_magnet", "choose_mitosis",
]);

const RESOURCE_FIELDS: Record<ResourceType, "mana" | "sangue" | "ossos" | "sucata"> = {
  mana: "mana", sangue: "sangue", ossos: "ossos", sucata: "sucata",
};
const USED_FIELDS: Record<ResourceType, "manaUsed" | "sangueUsed" | "ossosUsed" | "sucataUsed"> = {
  mana: "manaUsed", sangue: "sangueUsed", ossos: "ossosUsed", sucata: "sucataUsed",
};
const RESOURCE_ORDER: ResourceType[] = ["mana", "sangue", "ossos", "sucata"];

function safeName(value: unknown): string {
  const name = typeof value === "string" ? value.trim() : "";
  return (name || "Jogador").slice(0, 24);
}

function numberInRange(value: unknown, min: number, max: number): number | undefined {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed >= min && parsed <= max ? parsed : undefined;
}

function decodeIncoming<T extends object>(message: T | string): T | undefined {
  if (typeof message !== "string") return message;
  try { return JSON.parse(message) as T; } catch { return undefined; }
}

export class KarthaRoom extends Room<{ state: RoomState }> {
  private privatePlayers: PrivatePlayer[] = [];
  private nextCardId = 1;
  private pendingCritical?: { seat: number; cardId: string; targetId?: string; targetSeat?: number; targetType: "card" | "castle"; attackType: "fisica" | "magica"; die: number; dice: number; modifier: number; defense: number; itemDefinitionId?: string; repeatAfter?: number };
  private pendingMagnet: PendingMagnetChoice[][] = [[], []];
  private pendingMitosis: Array<PendingMitosisChoice | undefined> = [undefined, undefined];

  private sendJson(client: Client, type: string, payload: unknown) {
    client.send(type, JSON.stringify(payload));
  }

  private broadcastJson(type: string, payload: unknown) {
    this.broadcast(type, JSON.stringify(payload));
  }

  onCreate() {
    this.maxClients = 2;
    this.setState(new KarthaRoomState());
    this.state.phase = "waiting";
    this.state.currentPlayer = -1;
    this.state.initiativeWinner = -1;
    this.state.winner = -1;
    this.state.revision = 0;
    this.state.seed = Math.floor(Math.random() * 2147483646) + 1;
    this.state.turnNumber = 0;
    this.state.terrainDefinitionId = "";
    this.state.discardCount0 = 0;
    this.state.discardCount1 = 0;
    this.state.lastAction = "";

    this.onMessage("ready", (client: Client, rawMessage: { name?: string; deck?: unknown } | string) => {
      const message = decodeIncoming<{ name?: string; deck?: unknown }>(rawMessage) ?? {};
      const player = this.findPlayer(client.sessionId);
      if (!player || this.state.phase !== "waiting") return;
      player.name = safeName(message?.name);
      const selectedDeck = validateDeck(message?.deck) ?? defaultDeck();
      this.privatePlayers[player.seatIndex].configuredDeck = selectedDeck;
      player.ready = true;
      this.startInitiativeWhenReady();
    });

    this.onMessage("request_private_state", (client: Client) => {
      const player = this.findPlayer(client.sessionId);
      if (player) {
        this.sendPrivateState(player.seatIndex);
        this.sendPublicState(client);
      }
    });

    this.onMessage("roll_initiative", (client: Client) => {
      const player = this.findPlayer(client.sessionId);
      if (!player || this.state.phase !== "initiative" || player.initiative > 0) return;
      player.initiative = Math.floor(Math.random() * 20) + 1;
      this.broadcastJson("initiative_result", { seat: player.seatIndex, value: player.initiative });
      this.finishInitiativeIfReady();
    });

    this.onMessage("choose_first", (client: Client, message: { seat?: number }) => {
      const player = this.findPlayer(client.sessionId);
      const seat = Number(message?.seat);
      if (!player || this.state.phase !== "choose_first") return;
      if (player.seatIndex !== this.state.initiativeWinner) return;
      if (seat !== 0 && seat !== 1) return;
      this.startMatch(seat);
    });

    this.onMessage("action", (client: Client, rawMessage: ActionMessage | string) => {
      const message = decodeIncoming<ActionMessage>(rawMessage) ?? {};
      const player = this.findPlayer(client.sessionId);
      const kind = typeof message?.kind === "string" ? message.kind : "";
      if (!player) return;
      if (this.state.phase !== "playing") return this.reject(client, "partida_inativa");
      const choiceOutOfTurn = kind === "activate_trap" || kind === "choose_magnet" || kind === "choose_mitosis";
      if (player.seatIndex !== this.state.currentPlayer && !choiceOutOfTurn) return this.reject(client, "fora_do_turno");
      if (this.pendingCritical && (kind !== "choose_critical" || player.seatIndex !== this.pendingCritical.seat))
        return this.reject(client, "escolha_critico_pendente");
      const choiceSeat = this.pendingChoiceSeat();
      if (choiceSeat >= 0 && (player.seatIndex !== choiceSeat
        || (kind !== "choose_magnet" && kind !== "choose_mitosis")))
        return this.reject(client, "escolha_pendente");
      if (!ACTIONS.has(kind)) return this.reject(client, "acao_desconhecida");
      if (Number(message?.revision) !== this.state.revision) return this.reject(client, "revisao");

      const result = this.applyAction(player.seatIndex, kind, message?.payload ?? {});
      if (!result.ok) return this.reject(client, result.reason ?? "acao_invalida");

      this.state.revision += 1;
      this.state.lastAction = kind;
      this.broadcastJson("action_confirmed", {
        revision: this.state.revision,
        seat: player.seatIndex,
        kind,
        payload: result.details ?? {},
      });
      for (let seat = 0; seat < 2; seat++) this.sendPrivateState(seat);
      if (!result.details?.criticalChoice) this.sendPublicState();
    });

    this.onMessage("concede", (client: Client) => {
      const player = this.findPlayer(client.sessionId);
      if (!player || this.state.phase === "finished") return;
      this.state.winner = 1 - player.seatIndex;
      this.state.phase = "finished";
      this.bump("concede");
    });
  }

  onJoin(client: Client, options: { name?: string }) {
    const seat = this.nextSeat();
    const player = new PlayerSchema();
    player.sessionId = client.sessionId;
    player.seatIndex = seat;
    player.name = safeName(options?.name);
    player.connected = true;
    player.ready = false;
    player.life = 20;
    player.handCount = 0;
    player.deckCount = 50;
    player.initiative = 0;
    player.hasTakenTurn = false;
    this.resetPlayerTurn(player);
    player.mana = 0; player.sangue = 0; player.ossos = 0; player.sucata = 0;
      player.blockedResource = ""; player.blockedTurns = 0;
    player.evolutionsUsed = 0;
    this.state.players.set(client.sessionId, player);
    this.privatePlayers[seat] = { deck: [], hand: [], discard: [], configuredDeck: defaultDeck(), traps: [], effects: [], lastNonTroopDefinitionId: "" };
    this.setMetadata({ players: this.clients.length, phase: this.state.phase });
    this.sendJson(client, "seat", { seat, roomId: this.roomId, seed: this.state.seed });
  }

  async onLeave(client: Client, code?: number) {
    const player = this.findPlayer(client.sessionId);
    if (!player) return;
    player.connected = false;

    if (code === 1000 || this.state.phase === "waiting") {
      this.state.players.delete(client.sessionId);
      return;
    }

    try {
      const reconnected = await this.allowReconnection(client, 20);
      this.state.players.delete(client.sessionId);
      player.sessionId = reconnected.sessionId;
      player.connected = true;
      this.state.players.set(reconnected.sessionId, player);
      this.sendJson(reconnected, "seat", { seat: player.seatIndex, roomId: this.roomId, seed: this.state.seed });
      this.sendPrivateState(player.seatIndex);
      this.sendPublicState(reconnected);
    } catch {
      this.state.winner = 1 - player.seatIndex;
      this.state.phase = "finished";
      this.bump("disconnect");
    }
  }

  private startMatch(firstSeat: number) {
    this.state.cards.clear();
    this.nextCardId = 1;
    for (let seat = 0; seat < 2; seat++) {
      const data = this.privatePlayers[seat];
      data.hand = [];
      data.discard = [];
      data.traps = [];
      data.effects = [];
      data.lastNonTroopDefinitionId = "";
      this.pendingMagnet[seat] = [];
      this.pendingMitosis[seat] = undefined;
      data.deck = this.shuffle(data.configuredDeck.map((definitionId) => this.makePrivateCard(seat, definitionId)));
      const player = this.playerBySeat(seat);
      if (!player) continue;
      player.life = 20;
      player.hasTakenTurn = false;
      player.mana = 0; player.sangue = 0; player.ossos = 0; player.sucata = 0;
      player.blockedResource = ""; player.blockedTurns = 0;
    player.evolutionsUsed = 0;
      player.manaUsed = 0; player.sangueUsed = 0; player.ossosUsed = 0; player.sucataUsed = 0;
      this.resetPlayerTurn(player);
      this.drawCards(seat, 7);
    }

    this.state.currentPlayer = firstSeat;
    this.state.phase = "playing";
    this.state.turnNumber = 1;
    this.state.winner = -1;
    this.bump("match_started");
    for (let seat = 0; seat < 2; seat++) this.sendPrivateState(seat);
    this.broadcastJson("match_started", {
      currentPlayer: firstSeat,
      seed: this.state.seed,
      revision: this.state.revision,
    });
    this.sendPublicState();
  }

  private applyAction(seat: number, kind: string, payload: Record<string, unknown>): ActionResult {
    switch (kind) {
      case "place_resource": return this.placeResource(seat, payload);
      case "play_troop": return this.playTroop(seat, payload);
      case "play_construction": return this.playConstruction(seat, payload);
      case "play_spell": return this.playSpell(seat, payload);
      case "play_item": return this.playItem(seat, payload);
      case "play_trap": return this.playTrap(seat, payload);
      case "activate_trap": return this.activateTrap(seat, payload);
      case "play_effect": return this.playEffect(seat, payload);
      case "use_ability": return this.useAbility(seat, payload);
      case "use_construction": return this.useConstruction(seat, payload);
      case "remove_item": return this.removeItem(seat, payload);
      case "transfer_item": return this.transferItem(seat, payload);
      case "use_item_ability": return this.useItemAbility(seat, payload);
      case "move_troop": return this.moveTroop(seat, payload);
      case "attack": return this.attack(seat, payload);
      case "choose_critical": return this.chooseCritical(seat, payload);
      case "set_castle_defense": return this.setCastleDefense(seat, payload);
      case "evolve_troop": return this.evolveTroop(seat, payload);
      case "choose_magnet": return this.chooseMagnet(seat, payload);
      case "choose_mitosis": return this.chooseMitosis(seat, payload);
      case "end_turn": return this.endTurn(seat);
      default: return { ok: false, reason: "acao_desconhecida" };
    }
  }

  private placeResource(seat: number, payload: Record<string, unknown>): ActionResult {
    const player = this.playerBySeat(seat)!;
    if (player.resourcePlaced) return { ok: false, reason: "recurso_ja_colocado" };
    if (player.mana + player.sangue + player.ossos + player.sucata >= 6)
      return { ok: false, reason: "limite_recursos" };

    const found = this.handCard(seat, payload.cardId);
    if (!found || found.definition.category !== "recurso" || !found.definition.resourceType)
      return { ok: false, reason: "carta_recurso_invalida" };

    const type = found.definition.resourceType;
    player[RESOURCE_FIELDS[type]] += 1;
    player.resourcePlaced = true;
    this.discardHandCard(seat, found.index);
    return {
      ok: true,
      details: { cardId: found.card.instanceId, definitionId: found.card.definitionId, resourceType: type },
      privateSeats: [seat],
    };
  }

  private playTroop(seat: number, payload: Record<string, unknown>): ActionResult {
    const lane = numberInRange(payload.lane, 0, 2);
    if (lane === undefined) return { ok: false, reason: "coluna_invalida" };
    const player = this.playerBySeat(seat)!;
    if (player.troopsPlayed >= 1) return { ok: false, reason: "limite_tropas_turno" };
    if (this.findPublic((card) => card.category === "tropa" && card.owner === seat && card.lane === lane))
      return { ok: false, reason: "coluna_ocupada" };

    const found = this.handCard(seat, payload.cardId);
    if (!found || found.definition.category !== "tropa")
      return { ok: false, reason: "carta_tropa_invalida" };
    if (!this.payCost(player, found.definition)) return { ok: false, reason: "recursos_insuficientes" };
    const position = seat === 0 ? 4 : 0;
    if (this.findPublic((card) => card.category === "tropa" && card.lane === lane && card.position === position))
      return { ok: false, reason: "base_ocupada" };

    const publicCard = this.createPublicCard(found.card, found.definition, seat, lane, position);
    publicCard.moved = true; // só poderá se mover quando o turno deste dono voltar
    this.state.cards.set(publicCard.instanceId, publicCard);
    this.removeHandCard(seat, found.index);
    player.troopsPlayed += 1;
    this.updateTrapReadiness();
    return { ok: true, details: this.publicCardPayload(publicCard), privateSeats: [seat] };
  }

  private playConstruction(seat: number, payload: Record<string, unknown>): ActionResult {
    const lane = numberInRange(payload.lane, 0, 2);
    if (lane === undefined) return { ok: false, reason: "coluna_invalida" };
    const player = this.playerBySeat(seat)!;
    if (player.constructionsPlayed >= 1) return { ok: false, reason: "limite_construcoes_turno" };
    if (this.findPublic((card) => card.category === "construcao" && card.owner === seat && card.lane === lane))
      return { ok: false, reason: "construcao_ocupada" };

    const found = this.handCard(seat, payload.cardId);
    if (!found || found.definition.category !== "construcao")
      return { ok: false, reason: "carta_construcao_invalida" };
    if (!this.payCost(player, found.definition)) return { ok: false, reason: "recursos_insuficientes" };

    const publicCard = this.createPublicCard(found.card, found.definition, seat, lane, -1);
    this.state.cards.set(publicCard.instanceId, publicCard);
    this.removeHandCard(seat, found.index);
    player.constructionsPlayed += 1;
    return { ok: true, details: this.publicCardPayload(publicCard), privateSeats: [seat] };
  }

  private abilityState(card: PublicCardState): AbilityState {
    try {
      const value = JSON.parse(card.abilityStateJson || "{}");
      return value && typeof value === "object" ? value as AbilityState : {};
    } catch { return {}; }
  }

  private setAbilityState(card: PublicCardState, state: AbilityState) {
    card.abilityStateJson = JSON.stringify(state);
  }

  private hasAbility(card: PublicCardState, ability: string): boolean {
    return CARD_DEFINITIONS[card.definitionId]?.abilities?.includes(ability) ?? false;
  }

  private equipmentIds(card: PublicCardState): string[] {
    try {
      const parsed = JSON.parse(card.equipmentJson || "[]");
      return Array.isArray(parsed) ? parsed.filter((id) => typeof id === "string") : [];
    } catch { return []; }
  }

  private setEquipment(card: PublicCardState, ids: string[]) {
    card.equipmentJson = JSON.stringify(ids);
  }

  private equipmentAttackBonus(card: PublicCardState): number {
    return this.equipmentIds(card).reduce((sum, id) => sum + (CARD_DEFINITIONS[id]?.bonusAttack ?? 0), 0);
  }

  private equipmentDefenseBonus(card: PublicCardState): number {
    return this.equipmentIds(card).reduce((sum, id) => sum + (CARD_DEFINITIONS[id]?.bonusDefense ?? 0), 0);
  }

  private effectiveAttackDie(card: PublicCardState, base: number): number {
    return this.equipmentIds(card).reduce((die, id) => CARD_DEFINITIONS[id]?.overrideAttackDie ?? die, base);
  }

  private applyCondition(card: PublicCardState, condition: string, turns: number, power: number): boolean {
    if (card.condition && card.condition !== condition) return false;
    card.condition = condition;
    card.conditionTurns = turns;
    card.conditionPower = power;
    return true;
  }

  private discardPlayedCard(seat: number, found: { card: PrivateCard; index: number }) {
    this.discardHandCard(seat, found.index);
  }

  private pullResourceFromDeck(seat: number, type: ResourceType): PrivateCard | undefined {
    const data = this.privatePlayers[seat];
    const index = data.deck.findIndex((card) => CARD_DEFINITIONS[card.definitionId]?.resourceType === type);
    if (index < 0) return undefined;
    const [card] = data.deck.splice(index, 1);
    data.hand.push(card);
    this.shuffle(data.deck);
    this.updateCounts(seat);
    return card;
  }

  private playSpell(seat: number, payload: Record<string, unknown>): ActionResult {
    if (!this.playerBySeat(seat)!.hasTakenTurn) return { ok: false, reason: "primeiro_turno_bloqueado" };
    const player = this.playerBySeat(seat)!;
    if (player.spellsUsed >= 2) return { ok: false, reason: "limite_magias_turno" };
    const found = this.handCard(seat, payload.cardId);
    if (!found || found.definition.category !== "magica") return { ok: false, reason: "carta_magia_invalida" };
    const effect = found.definition.effect ?? "";
    const targetId = typeof payload.targetId === "string" ? payload.targetId : "";
    const targetType = payload.targetType === "castle" ? "castle" : payload.targetType === "construcao" ? "construcao" : "tropa";
    const target = targetId ? this.state.cards.get(targetId) : undefined;
    let details: Record<string, unknown> = { cardId: found.card.instanceId, definitionId: found.card.definitionId, effect };
    let searched: ResourceType | undefined;

    if (effect === "buscar_sangue") {
      if (!this.privatePlayers[seat].deck.some((card) => CARD_DEFINITIONS[card.definitionId]?.resourceType === "sangue"))
        return { ok: false, reason: "recurso_nao_encontrado" };
      searched = "sangue";
    } else if (effect === "bloqueio_recurso") {
      const resourceType = typeof payload.resourceType === "string" && RESOURCE_ORDER.includes(payload.resourceType as ResourceType)
        ? payload.resourceType as ResourceType : undefined;
      const targetSeat = numberInRange(payload.targetSeat, 0, 1);
      if (!resourceType || targetSeat === undefined) return { ok: false, reason: "recurso_invalido" };
      const targetPlayer = this.playerBySeat(targetSeat)!;
      if (targetPlayer[RESOURCE_FIELDS[resourceType]] <= 0) return { ok: false, reason: "recurso_invalido" };
      details = { ...details, resourceType, targetSeat, turns: 3 };
    } else if (effect === "dados_manipulados") {
      details = { ...details, roll: this.roll(4), remaining: 3 };
    } else if (effect === "refracao_temporal") {
      if (!this.privatePlayers[seat].lastNonTroopDefinitionId) return { ok: false, reason: "refracao_sem_carta" };
    } else if (!target && targetType !== "castle") {
      return { ok: false, reason: "alvo_invalido" };
    } else if (["veneno", "gelo", "choque"].includes(effect) && target?.category != "tropa") {
      return { ok: false, reason: "alvo_invalido" };
    } else if (effect === "bola_fogo" && targetType != "castle"
      && (!target || target.category != targetType)) {
      return { ok: false, reason: "alvo_invalido" };
    } else if (effect === "eutanasia") {
      if (!target || target.category !== "tropa" || target.life > 5) return { ok: false, reason: "eutanasia_vida" };
    } else if (targetType === "castle" && effect !== "bola_fogo") {
      return { ok: false, reason: "alvo_invalido" };
    } else if (target && effect !== "eutanasia" && target.owner === seat) {
      return { ok: false, reason: "alvo_invalido" };
    }

    if (!this.payCost(player, found.definition)) return { ok: false, reason: "recursos_insuficientes" };
    if (effect === "refracao_temporal") {
      const copiedId = this.privatePlayers[seat].lastNonTroopDefinitionId;
      const copied = this.makePrivateCard(seat, copiedId);
      if (CARD_DEFINITIONS[copiedId]?.category === "construcao") copied.lifeScale = 0.5;
      this.privatePlayers[seat].hand.push(copied);
      this.discardPlayedCard(seat, found);
      this.updateCounts(seat);
      player.spellsUsed += 1;
      return { ok: true, details: {
        cardId: found.card.instanceId, definitionId: found.card.definitionId,
        copiedDefinitionId: copiedId, copiedCardId: copied.instanceId,
      }, privateSeats: [seat] };
    }

    if (searched) {
      const drawn = this.pullResourceFromDeck(seat, searched)!;
      details = { ...details, searchedResource: searched, drawnCardId: drawn.instanceId };
    } else if (effect === "bloqueio_recurso") {
      const targetPlayer = this.playerBySeat(details.targetSeat as number)!;
      targetPlayer.blockedResource = details.resourceType as string;
      targetPlayer.blockedTurns = 3;
    } else if (effect === "dados_manipulados") {
      this.privatePlayers[seat].effects = this.privatePlayers[seat].effects.filter((value) => !value.startsWith("dados_manipulados:"));
      this.privatePlayers[seat].effects.push(`dados_manipulados:${details.roll}:3`);
    } else if (effect === "eutanasia" && target) {
      this.destroyPublicCard(target);
      details = { ...details, targetId, destroyed: true };
    } else if (effect === "bola_fogo") {
      const roll = this.rollForSeat(seat, 8);
      const coin = this.rollForSeat(seat, 2);
      if (targetType === "castle") {
        const defender = this.playerBySeat(1 - seat)!;
        defender.life = Math.max(0, defender.life - roll);
        if (defender.life <= 0) { this.state.winner = seat; this.state.phase = "finished"; }
        details = { ...details, target: "castle", damageRolls: [roll], damage: roll, coin };
      } else if (target) {
        target.life -= roll;
        const destroyed = target.life <= 0;
        if (!destroyed && target.category === "tropa" && coin === 1) this.applyCondition(target, "queimado", 3, 2);
        if (destroyed) this.destroyPublicCard(target);
        details = { ...details, targetId, targetType, damageRolls: [roll], damage: roll, coin, destroyed };
      }
    } else if (target) {
      if (effect === "veneno") this.applyCondition(target, "envenenado", -1, 1);
      if (effect === "gelo") this.applyCondition(target, "congelado", 1, 0);
      if (effect === "choque") {
        target.life -= 2;
        const coin = this.rollForSeat(seat, 2);
        if (target.life > 0) this.applyCondition(target, coin === 1 ? "paralisado" : "eletrocutado", 1, 0);
        else this.destroyPublicCard(target);
        details = { ...details, targetId, damage: 2, coin, destroyed: target.life <= 0 };
      } else {
        details = { ...details, targetId, condition: target.condition };
      }
    }

    player.spellsUsed += 1;
    this.discardPlayedCard(seat, found);
    if (effect !== "refracao_temporal") this.privatePlayers[seat].lastNonTroopDefinitionId = found.card.definitionId;
    return { ok: true, details, privateSeats: [seat] };
  }

  private playItem(seat: number, payload: Record<string, unknown>): ActionResult {
    if (!this.playerBySeat(seat)!.hasTakenTurn) return { ok: false, reason: "primeiro_turno_bloqueado" };
    const player = this.playerBySeat(seat)!;
    if (player.itemsUsed >= 3) return { ok: false, reason: "limite_itens_turno" };
    const found = this.handCard(seat, payload.cardId);
    if (!found || (found.definition.category !== "item_equipavel" && found.definition.category !== "item_consumivel"))
      return { ok: false, reason: "carta_item_invalida" };
    const targetId = typeof payload.targetId === "string" ? payload.targetId : "";
    const target = targetId ? this.state.cards.get(targetId) : undefined;
    const definition = found.definition;
    const effect = definition.effect ?? "";
    let details: Record<string, unknown> = { cardId: found.card.instanceId, definitionId: found.card.definitionId, effect };

    if (definition.category === "item_equipavel") {
      if (!target || target.category !== "tropa" || target.owner !== seat) return { ok: false, reason: "alvo_item_invalido" };
      const equipment = this.equipmentIds(target);
      const targetDefinition = CARD_DEFINITIONS[target.definitionId];
      if (equipment.length >= (targetDefinition.itemSlots ?? 0)) return { ok: false, reason: "mochila_cheia" };
      if (target.intelligence < (definition.intelligenceRequired ?? 0)) return { ok: false, reason: "inteligencia_insuficiente" };
      if (!this.payCost(player, definition)) return { ok: false, reason: "recursos_insuficientes" };
      equipment.push(found.card.definitionId);
      this.setEquipment(target, equipment);
      this.removeHandCard(seat, found.index);
      details = { ...details, targetId, equipment };
    } else {
      if (target && target.category != "tropa") return { ok: false, reason: "alvo_item_invalido" };
      if ((effect === "cura" || effect === "aumentar_inteligencia" || effect === "aplicar_corrosao") && !target)
        return { ok: false, reason: "alvo_item_invalido" };
      if ((effect === "cura" || effect === "aumentar_inteligencia") && target?.owner !== seat)
        return { ok: false, reason: "alvo_item_invalido" };
      if (effect === "buscar_mana" && !this.privatePlayers[seat].deck.some((card) => CARD_DEFINITIONS[card.definitionId]?.resourceType === "mana"))
        return { ok: false, reason: "recurso_nao_encontrado" };
      if (effect === "revirar_sangue" && player.sangueUsed <= 0) return { ok: false, reason: "recurso_nao_gasto" };
      if (!this.payCost(player, definition)) return { ok: false, reason: "recursos_insuficientes" };

      if (effect === "cura" && target) target.life = Math.min(target.maxLife, target.life + (definition.effectValue ?? 5));
      else if (effect === "comprar_cartas") this.drawCards(seat, 3);
      else if (effect === "buscar_mana") this.pullResourceFromDeck(seat, "mana");
      else if (effect === "revirar_sangue") player.sangueUsed -= 1;
      else if (effect === "aumentar_inteligencia" && target) target.intelligence += 1;
      else if (effect === "aplicar_corrosao" && target) this.applyCondition(target, "corrosao", 3, 3);
      this.discardPlayedCard(seat, found);
      details = { ...details, targetId, targetLife: target?.life };
    }
    player.itemsUsed += 1;
    if (effect !== "refracao_temporal") this.privatePlayers[seat].lastNonTroopDefinitionId = found.card.definitionId;
    return { ok: true, details, privateSeats: [seat] };
  }

  private playTrap(seat: number, payload: Record<string, unknown>): ActionResult {
    const found = this.handCard(seat, payload.cardId);
    if (!found || found.definition.category !== "armadilha") return { ok: false, reason: "carta_armadilha_invalida" };
    const lane = numberInRange(payload.lane, 0, 2);
    const position = numberInRange(payload.position, 0, 4);
    if (lane === undefined || position === undefined || (seat === 0 ? position < 2 : position > 2))
      return { ok: false, reason: "posicao_armadilha_invalida" };
    if (this.privatePlayers.some((data) => data.traps.some((trap) => trap.lane === lane && trap.position === position)))
      return { ok: false, reason: "armadilha_ocupada" };
    if (!this.payCost(this.playerBySeat(seat)!, found.definition)) return { ok: false, reason: "recursos_insuficientes" };

    const card = this.removeHandCard(seat, found.index);
    this.privatePlayers[seat].traps.push({ instanceId: card.instanceId, definitionId: card.definitionId, lane, position, ready: false, targetId: "" });
    this.privatePlayers[seat].lastNonTroopDefinitionId = card.definitionId;
    this.updateTrapReadiness();
    return { ok: true, details: { cardId: card.instanceId, definitionId: card.definitionId, lane, position }, privateSeats: [seat] };
  }

  private activateTrap(seat: number, payload: Record<string, unknown>): ActionResult {
    const data = this.privatePlayers[seat];
    const trapId = typeof payload.trapId === "string" ? payload.trapId : "";
    const index = data.traps.findIndex((trap) => trap.instanceId === trapId);
    if (index < 0) return { ok: false, reason: "armadilha_invalida" };
    const trap = data.traps[index];
    if (!trap.ready) return { ok: false, reason: "armadilha_nao_pronta" };
    const target = trap.targetId ? this.state.cards.get(trap.targetId) : undefined;
    let details: Record<string, unknown> = { trapId, definitionId: trap.definitionId, targetId: trap.targetId };

    if (target) {
      const targetState = this.abilityState(target);
      if ((targetState.trapImmunity ?? 0) > 0) {
        targetState.trapImmunity = Math.max(0, (targetState.trapImmunity ?? 0) - 1);
        this.setAbilityState(target, targetState);
        data.traps.splice(index, 1);
        data.discard.push({ instanceId: trap.instanceId, definitionId: trap.definitionId });
        this.updateCounts(seat);
        return { ok: true, details: { ...details, blockedByVeil: true }, privateSeats: [seat] };
      }
    }

    if (trap.definitionId === "armadilha_urso") {
      if (!target) return { ok: false, reason: "alvo_invalido" };
      const rolls = [this.rollForSeat(seat, 6), this.rollForSeat(seat, 6)];
      const damage = rolls[0] + rolls[1];
      target.life -= damage;
      const coin = this.rollForSeat(seat, 2);
      if (target.life > 0 && coin === 1) this.applyCondition(target, "sangrando", 1, 3);
      else if (target.life <= 0) this.destroyPublicCard(target);
      details = { ...details, damageRolls: rolls, damage, coin, destroyed: target.life <= 0 };
    } else if (trap.definitionId === "raizes_espinhosas") {
      if (!target) return { ok: false, reason: "alvo_invalido" };
      target.moved = true;
      this.applyCondition(target, "envenenado", -1, 1);
      details = { ...details, condition: "envenenado" };
    } else if (trap.definitionId === "loucura_mutua") {
      if (!target) return { ok: false, reason: "alvo_invalido" };
      this.applyCondition(target, "loucura", -1, 0);
      details = { ...details, condition: "loucura" };
    } else if (trap.definitionId === "destrocos") {
      const rolls: number[] = [];
      this.state.cards.forEach((card: PublicCardState) => {
        if (card.category === "tropa" && card.owner !== seat && card.lane === trap.lane) {
          const roll = this.roll(4); rolls.push(roll); card.life -= roll;
          if (card.life <= 0) this.destroyPublicCard(card);
        }
      });
      details = { ...details, damageRolls: rolls };
    }

    data.traps.splice(index, 1);
    data.discard.push({ instanceId: trap.instanceId, definitionId: trap.definitionId });
    this.updateCounts(seat);
    return { ok: true, details, privateSeats: [seat] };
  }

  private playEffect(seat: number, payload: Record<string, unknown>): ActionResult {
    const player = this.playerBySeat(seat)!;
    const found = this.handCard(seat, payload.cardId);
    if (!found || !["terreno", "bencao", "maldicao"].includes(found.definition.category))
      return { ok: false, reason: "carta_efeito_invalida" };
    if (found.definition.category === "terreno" && !player.hasTakenTurn) return { ok: false, reason: "primeiro_turno_bloqueado" };
    if (found.definition.category === "terreno" && player.terrainPlayed) return { ok: false, reason: "limite_terreno_turno" };
    if (!this.payCost(player, found.definition)) return { ok: false, reason: "recursos_insuficientes" };

    if (found.definition.category === "terreno") {
      this.state.terrainDefinitionId = found.card.definitionId;
      player.terrainPlayed = true;
    } else {
      this.privatePlayers[seat].effects.push(found.definition.effect ?? found.card.definitionId);
    }
    this.discardPlayedCard(seat, found);
    this.privatePlayers[seat].lastNonTroopDefinitionId = found.card.definitionId;
    return { ok: true, details: { cardId: found.card.instanceId, definitionId: found.card.definitionId, category: found.definition.category }, privateSeats: [seat] };
  }



  private removeItem(seat: number, payload: Record<string, unknown>): ActionResult {
    const cardId = typeof payload.cardId === "string" ? payload.cardId : "";
    const card = this.state.cards.get(cardId);
    if (!card || card.owner !== seat || card.category !== "tropa")
      return { ok: false, reason: "tropa_invalida" };
    const state = this.abilityState(card);
    if (state.itemActionUsed) return { ok: false, reason: "acao_item_ja_usada" };
    const equipment = this.equipmentIds(card);
    if (equipment.length <= 0) return { ok: false, reason: "tropa_sem_item" };
    const itemDefinitionId = equipment.pop()!;
    this.setEquipment(card, equipment);
    this.privatePlayers[seat].hand.push(this.makePrivateCard(seat, itemDefinitionId));
    state.itemActionUsed = true;
    this.setAbilityState(card, state);
    this.updateCounts(seat);
    return { ok: true, details: { cardId, itemDefinitionId, equipment }, privateSeats: [seat] };
  }

  private transferItem(seat: number, payload: Record<string, unknown>): ActionResult {
    const fromId = typeof payload.cardId === "string" ? payload.cardId : "";
    const toId = typeof payload.targetId === "string" ? payload.targetId : "";
    const from = this.state.cards.get(fromId);
    const to = this.state.cards.get(toId);
    if (!from || !to || from === to || from.owner !== seat || to.owner !== seat
      || from.category !== "tropa" || to.category !== "tropa")
      return { ok: false, reason: "transferencia_invalida" };
    const fromState = this.abilityState(from);
    const toState = this.abilityState(to);
    if (fromState.itemActionUsed || toState.itemActionUsed)
      return { ok: false, reason: "acao_item_ja_usada" };
    const sourceEquipment = this.equipmentIds(from);
    if (sourceEquipment.length <= 0) return { ok: false, reason: "tropa_sem_item" };
    const destinationEquipment = this.equipmentIds(to);
    const capacity = CARD_DEFINITIONS[to.definitionId]?.itemSlots ?? 0;
    if (destinationEquipment.length >= capacity) return { ok: false, reason: "mochila_cheia" };
    const itemDefinitionId = sourceEquipment.pop()!;
    destinationEquipment.push(itemDefinitionId);
    this.setEquipment(from, sourceEquipment);
    this.setEquipment(to, destinationEquipment);
    fromState.itemActionUsed = true;
    toState.itemActionUsed = true;
    this.setAbilityState(from, fromState);
    this.setAbilityState(to, toState);
    return { ok: true, details: {
      cardId: fromId, targetId: toId, itemDefinitionId,
      sourceEquipment, destinationEquipment,
    } };
  }


  private useItemAbility(seat: number, payload: Record<string, unknown>): ActionResult {
    const cardId = typeof payload.cardId === "string" ? payload.cardId : "";
    const card = this.state.cards.get(cardId);
    if (!card || card.owner !== seat || card.category !== "tropa")
      return { ok: false, reason: "tropa_invalida" };
    if (!this.equipmentIds(card).includes("grimorio_iniciante"))
      return { ok: false, reason: "grimorio_nao_equipado" };
    const state = this.abilityState(card);
    if (state.grimoireUsed) return { ok: false, reason: "grimorio_ja_usado" };
    const spell = payload.spell === "raio" ? "raio"
      : payload.spell === "escudo" ? "escudo"
      : payload.spell === "curazinha" ? "curazinha" : "";
    if (!spell) return { ok: false, reason: "habilidade_item_invalida" };
    const player = this.playerBySeat(seat)!;
    if (player.blockedResource === "mana" || player.mana - player.manaUsed < 1)
      return { ok: false, reason: "recursos_insuficientes" };
    let target: PublicCardState | undefined;
    if (spell === "raio") {
      target = this.findPublic((other) => other.category === "tropa"
        && other.owner !== seat && other.lane === card.lane);
      if (!target) return { ok: false, reason: "habilidade_sem_alvo" };
    }
    player.manaUsed += 1;
    state.grimoireUsed = true;
    let damage = 0;
    let roll = 0;
    if (spell === "raio" && target) {
      roll = this.rollForSeat(seat, 4);
      const targetDefinition = CARD_DEFINITIONS[target.definitionId];
      const targetState = this.abilityState(target);
      const defense = (targetDefinition.magicDefense ?? 0) + (targetState.grimoireShield ? 2 : 0);
      damage = Math.max(0, roll - defense);
      target.life -= damage;
      if (target.life <= 0) this.destroyPublicCard(target);
    } else if (spell === "escudo") {
      state.grimoireShield = true;
    } else {
      card.life = Math.min(card.maxLife, card.life + 1);
    }
    this.setAbilityState(card, state);
    return { ok: true, details: {
      cardId, ability: "grimorio_iniciante", spell,
      targetId: target?.instanceId ?? "", roll, damage,
      destroyed: Boolean(target && target.life <= 0), life: card.life,
    } };
  }

  private useAbility(seat: number, payload: Record<string, unknown>): ActionResult {
    const cardId = typeof payload.cardId === "string" ? payload.cardId : "";
    const card = this.state.cards.get(cardId);
    if (!card || card.owner !== seat || card.category !== "tropa")
      return { ok: false, reason: "tropa_invalida" };
    const definition = CARD_DEFINITIONS[card.definitionId];
    const ability = typeof payload.ability === "string" && definition.abilities?.includes(payload.ability)
      ? payload.ability : definition.abilities?.find((value) =>
        ["golpe_duplo", "sombra_translucida", "ferida_exposta", "imitacao", "visao_do_veu", "digestao", "carnica_frenetica"].includes(value));
    if (!ability) return { ok: false, reason: "habilidade_indisponivel" };
    const state = this.abilityState(card);
    if (state.used && ability !== "visao_do_veu") return { ok: false, reason: "habilidade_ja_usada" };

    if (ability === "golpe_duplo") {
      if (card.attacked) return { ok: false, reason: "tropa_ja_atacou" };
      const first = this.attack(seat, { cardId, attackType: definition.magicDie && !definition.attackDie ? "magica" : "fisica" });
      if (!first.ok) return first;
      state.used = true;
      this.setAbilityState(card, state);
      if (this.pendingCritical) {
        this.pendingCritical.repeatAfter = 1;
        return { ok: true, details: { ability, cardId, attacks: [first.details], criticalChoice: true } };
      }
      card.attacked = false;
      const second = this.attack(seat, { cardId, attackType: definition.magicDie && !definition.attackDie ? "magica" : "fisica" });
      card.attacked = true;
      return { ok: true, details: { ability, cardId, attacks: [first.details, second.details] } };
    }

    if (ability === "sombra_translucida") {
      if ((state.shadowCooldown ?? 0) > 0) return { ok: false, reason: "sombra_recarregando" };
      const player = this.playerBySeat(seat)!;
      if (player.blockedResource === "mana" || player.mana - player.manaUsed < 2)
        return { ok: false, reason: "recursos_insuficientes" };
      player.manaUsed += 2;
      state.shadowTurns = 1;
      state.shadowCooldown = 2;
      state.used = true;
      this.setAbilityState(card, state);
      return { ok: true, details: { ability, cardId, shadowTurns: 1, shadowCooldown: 2 } };
    }

    const direction = seat === 0 ? -1 : 1;
    const front = this.findPublic((other) => other.category === "tropa" && other.owner !== seat
      && other.lane === card.lane && other.position === card.position + direction);

    if (ability === "ferida_exposta") {
      if (!front) return { ok: false, reason: "habilidade_sem_alvo" };
      state.used = true; this.setAbilityState(card, state);
      const coin = this.rollForSeat(seat, 2);
      let damage = 0;
      if (coin === 1) {
        damage = this.rollForSeat(seat, Math.max(1, definition.attackDie ?? 1));
        front.life -= damage;
        if (front.life > 0) this.applyCondition(front, "sangrando", 1, 3);
        else this.destroyPublicCard(front);
      }
      return { ok: true, details: { ability, cardId, targetId: front.instanceId, coin, damage, destroyed: front.life <= 0 } };
    }

    if (ability === "imitacao") {
      if (!front) return { ok: false, reason: "habilidade_sem_alvo" };
      if (front.intelligence > 0) state.used = true;
      const attackerRoll = this.rollForSeat(seat, 20) + card.intelligence;
      const defenderRoll = this.rollForSeat(1 - seat, 20) + front.intelligence;
      let counter: ActionResult | undefined;
      if (attackerRoll > defenderRoll) {
        const targetState = this.abilityState(front);
        targetState.illusion = true;
        this.setAbilityState(front, targetState);
        const previous = card.attacked;
        card.attacked = false;
        counter = this.attack(seat, { cardId, attackType: definition.magicDie && !definition.attackDie ? "magica" : "fisica" });
        card.attacked = previous;
      }
      this.setAbilityState(card, state);
      return { ok: true, details: { ability, cardId, targetId: front.instanceId, attackerRoll, defenderRoll, success: attackerRoll > defenderRoll, counter: counter?.details, criticalChoice: Boolean(counter?.details?.criticalChoice) } };
    }

    if (ability === "digestao") {
      const maximum = Math.max(0, Math.floor(card.maxLife / 10));
      if ((state.digestionUses ?? 0) >= maximum) return { ok: false, reason: "digestao_sem_usos" };
      let consumed: PublicCardState | undefined;
      if (!state.corpseAvailable) {
        const targetId = typeof payload.targetId === "string" ? payload.targetId : "";
        consumed = this.state.cards.get(targetId);
        if (!consumed || consumed.owner === seat || consumed.category !== "tropa" || consumed.life >= 4
          || Math.abs(consumed.lane - card.lane) + Math.abs(consumed.position - card.position) !== 1)
          return { ok: false, reason: "digestao_alvo_invalido" };
        this.destroyPublicCard(consumed);
      }
      state.digestionUses = (state.digestionUses ?? 0) + 1;
      state.corpseAvailable = false;
      state.used = true;
      card.maxLife += 1;
      const regeneration = this.rollForSeat(seat, 4);
      this.applyCondition(card, "regeneracao", regeneration, 1);
      this.setAbilityState(card, state);
      return { ok: true, details: { ability, cardId, targetId: consumed?.instanceId ?? "", maxLife: card.maxLife, regeneration } };
    }

    if (ability === "carnica_frenetica") {
      if (state.frenzy) return { ok: false, reason: "carnica_preparada" };
      const player = this.playerBySeat(seat)!;
      if (player.blockedResource === "sangue" || player.sangue - player.sangueUsed < 2)
        return { ok: false, reason: "recursos_insuficientes" };
      player.sangueUsed += 2;
      const coin = this.rollForSeat(seat, 2);
      state.frenzy = coin === 1 ? "bonus" : "self";
      state.used = true;
      this.setAbilityState(card, state);
      return { ok: true, details: { ability, cardId, coin, frenzy: state.frenzy } };
    }

    if (ability === "visao_do_veu") {
      if (state.veilUsed) return { ok: false, reason: "visao_ja_usada" };
      const choice = payload.choice === "destroy" ? "destroy" : payload.choice === "protect" ? "protect" : "";
      const enemy = this.privatePlayers[1 - seat];
      if (!choice) {
        const viewer = this.clientBySeat(seat);
        if (viewer) this.sendJson(viewer, "veil_options", {
          cardId,
          cards: enemy.hand.map((item) => ({
            instanceId: item.instanceId,
            name: CARD_DEFINITIONS[item.definitionId]?.name ?? "Carta",
            category: CARD_DEFINITIONS[item.definitionId]?.category ?? "",
          })),
        });
        return { ok: true, details: { ability, cardId, waitingChoice: true } };
      }
      const trapId = typeof payload.trapId === "string" ? payload.trapId : "";
      const trapIndex = enemy.hand.findIndex((item) => item.instanceId === trapId
        && CARD_DEFINITIONS[item.definitionId]?.category === "armadilha");
      if (choice === "destroy" && trapIndex < 0) return { ok: false, reason: "armadilha_invalida" };
      state.veilUsed = true;
      state.used = true;
      if (choice === "destroy") {
        const discarded = enemy.hand.splice(trapIndex, 1)[0];
        enemy.discard.push(discarded);
        this.updateCounts(1 - seat);
      } else state.trapImmunity = 1;
      this.setAbilityState(card, state);
      return { ok: true, details: { ability, cardId, destroyedTrap: choice === "destroy" }, privateSeats: [seat, 1 - seat] };
    }

    return { ok: false, reason: "habilidade_indisponivel" };
  }

  private useConstruction(seat: number, payload: Record<string, unknown>): ActionResult {
    const cardId = typeof payload.cardId === "string" ? payload.cardId : "";
    const card = this.state.cards.get(cardId);
    if (!card || card.owner !== seat || card.category !== "construcao")
      return { ok: false, reason: "construcao_invalida" };
    const state = this.abilityState(card);
    if (state.used) return { ok: false, reason: "habilidade_ja_usada" };
    if (CARD_DEFINITIONS[card.definitionId]?.effect !== "hemodrenario")
      return { ok: false, reason: "habilidade_indisponivel" };
    const enemy = this.playerBySeat(1 - seat)!;
    const owner = this.playerBySeat(seat)!;
    if (enemy.blockedResource === "sangue" || enemy.sangue - enemy.sangueUsed <= 0)
      return { ok: false, reason: "hemodrenario_sem_sangue" };
    const spent = RESOURCE_ORDER.find((type) => owner[USED_FIELDS[type]] > 0
      && !(owner.blockedResource === type && owner.blockedTurns > 0));
    if (!spent) return { ok: false, reason: "hemodrenario_sem_recurso_gasto" };
    enemy.sangueUsed += 1;
    owner[USED_FIELDS[spent]] -= 1;
    state.used = true;
    this.setAbilityState(card, state);
    return { ok: true, details: { cardId, ability: "hemodrenario", restoredResource: spent } };
  }

  private updateTrapReadiness() {
    for (let seat = 0; seat < this.privatePlayers.length; seat++) {
      for (const trap of this.privatePlayers[seat]?.traps ?? []) {
        if (trap.ready) continue;
        const target = this.findPublic((card) => card.category === "tropa" && card.owner !== seat
          && card.lane === trap.lane && card.position === trap.position);
        if (target && trap.definitionId === "armadilha_urso"
          && !CARD_DEFINITIONS[target.definitionId]?.abilities?.includes("voar")) {
          trap.ready = true; trap.targetId = target.instanceId;
        }
      }
    }
  }

  private moveTroop(seat: number, payload: Record<string, unknown>): ActionResult {
    const cardId = typeof payload.cardId === "string" ? payload.cardId : "";
    const direction = payload.direction === "retreat" ? "retreat" : "advance";
    const card = this.state.cards.get(cardId);
    if (!card || card.category !== "tropa" || card.owner !== seat)
      return { ok: false, reason: "tropa_invalida" };
    if (card.moved) return { ok: false, reason: "tropa_ja_moveu" };
    if (["paralisado", "congelado", "adormecido", "loucura"].includes(card.condition)) return { ok: false, reason: "tropa_incapacitada" };
    const rootTrap = this.privatePlayers[1 - seat].traps.find((trap) => trap.definitionId === "raizes_espinhosas" && !trap.ready && trap.lane === card.lane && trap.position === card.position);
    if (rootTrap && card.life < 10) { rootTrap.ready = true; rootTrap.targetId = card.instanceId; return { ok: true, details: { cardId, trapReady: true, movementPrevented: true } }; }

    const advanceDelta = seat === 0 ? -1 : 1;
    const destination = card.position + (direction === "advance" ? advanceDelta : -advanceDelta);
    if (destination < 0 || destination > 4) return { ok: false, reason: "movimento_fora_tabuleiro" };
    if (this.findPublic((other) =>
      other.category === "tropa" && other.lane === card.lane && other.position === destination))
      return { ok: false, reason: "casa_ocupada" };

    card.position = destination;
    if (destination !== (seat === 0 ? 4 : 0)) card.defendingCastle = false;
    let gazeRoll = 0;
    const state = this.abilityState(card);
    if (!state.gazeTested) {
      const hollow = this.findPublic((other) => other.category === "tropa" && other.owner !== seat
        && other.lane === card.lane && other.position === card.position + advanceDelta
        && this.hasAbility(other, "olhar_vazio"));
      if (hollow) {
        state.gazeTested = true;
        gazeRoll = this.rollForSeat(seat, 20);
        this.setAbilityState(card, state);
        if (gazeRoll <= 10) this.applyCondition(card, "paralisado", 1, 0);
      }
    }
    this.updateTrapReadiness();
    card.moved = true;
    return { ok: true, details: { cardId, lane: card.lane, position: destination, direction, gazeRoll, condition: card.condition } };
  }


  private pendingChoiceSeat(): number {
    for (let seat = 0; seat < 2; seat++) {
      if ((this.pendingMagnet[seat]?.length ?? 0) > 0 || this.pendingMitosis[seat]) return seat;
    }
    return -1;
  }

  private setCastleDefense(seat: number, payload: Record<string, unknown>): ActionResult {
    const cardId = typeof payload.cardId === "string" ? payload.cardId : "";
    const defending = payload.defending === true;
    const card = this.state.cards.get(cardId);
    if (!card || card.owner !== seat || card.category !== "tropa") return { ok: false, reason: "tropa_invalida" };
    const entry = seat === 0 ? 4 : 0;
    if (defending && card.position !== entry) return { ok: false, reason: "defesa_fora_da_base" };
    card.defendingCastle = defending;
    return { ok: true, details: { cardId, defending } };
  }

  private evolveTroop(seat: number, payload: Record<string, unknown>): ActionResult {
    const cardId = typeof payload.cardId === "string" ? payload.cardId : "";
    const card = this.state.cards.get(cardId);
    if (!card || card.owner !== seat || card.category !== "tropa") return { ok: false, reason: "tropa_invalida" };
    const current = CARD_DEFINITIONS[card.definitionId];
    const evolved = current.evolvesTo ? CARD_DEFINITIONS[current.evolvesTo] : undefined;
    if (!evolved) return { ok: false, reason: "evolucao_indisponivel" };
    if (card.turnsInPlay < 1) return { ok: false, reason: "evolucao_muito_cedo" };
    const player = this.playerBySeat(seat)!;
    if (player.evolutionsUsed >= 1) return { ok: false, reason: "limite_evolucoes_turno" };
    if (!this.payCost(player, evolved)) return { ok: false, reason: "recursos_insuficientes" };
    const damageTaken = Math.max(0, card.maxLife - card.life);
    card.definitionId = evolved.id;
    card.name = evolved.name;
    card.maxLife = evolved.life ?? card.maxLife;
    card.life = Math.max(1, card.maxLife - damageTaken);
    card.intelligence = evolved.intelligence ?? 0;
    player.evolutionsUsed += 1;
    return { ok: true, details: { cardId, definitionId: evolved.id, name: evolved.name, life: card.life, maxLife: card.maxLife } };
  }

  private sendNextMagnetChoice(seat: number) {
    const pending = this.pendingMagnet[seat]?.[0];
    const client = this.clientBySeat(seat);
    if (pending && client) this.sendJson(client, "magnet_choice", {
      sourceCardId: pending.sourceCardId,
      items: pending.equipment.map((definitionId, index) => ({ index, definitionId, name: CARD_DEFINITIONS[definitionId]?.name ?? "Item" })),
    });
  }

  private chooseMagnet(seat: number, payload: Record<string, unknown>): ActionResult {
    const pending = this.pendingMagnet[seat]?.[0];
    const index = numberInRange(payload.index, 0, Math.max(0, (pending?.equipment.length ?? 0) - 1));
    if (!pending || index === undefined) return { ok: false, reason: "escolha_ima_invalida" };
    const data = this.privatePlayers[seat];
    const selected = pending.equipment[index];
    data.hand.push(this.makePrivateCard(seat, selected));
    pending.equipment.forEach((definitionId, itemIndex) => {
      if (itemIndex !== index) data.discard.push(this.makePrivateCard(seat, definitionId));
    });
    this.pendingMagnet[seat].shift();
    this.updateCounts(seat);
    this.sendNextMagnetChoice(seat);
    return { ok: true, details: { sourceCardId: pending.sourceCardId, index, itemDefinitionId: selected } };
  }

  private chooseMitosis(seat: number, payload: Record<string, unknown>): ActionResult {
    const pending = this.pendingMitosis[seat];
    const lane = numberInRange(payload.lane, 0, 2);
    const position = numberInRange(payload.position, 0, 4);
    if (!pending || lane === undefined || position === undefined
      || !pending.candidates.some(([candidateLane, candidatePosition]) => candidateLane === lane && candidatePosition === position))
      return { ok: false, reason: "escolha_mitose_invalida" };
    if (this.findPublic((card) => card.category === "tropa" && (card.lane === lane && card.position === position
      || card.owner === seat && card.lane === lane))) return { ok: false, reason: "coluna_ocupada" };
    const child = this.createPublicCard(pending.source, CARD_DEFINITIONS.slimet, seat, lane, position);
    child.moved = true;
    this.state.cards.set(child.instanceId, child);
    this.pendingMitosis[seat] = undefined;
    return { ok: true, details: this.publicCardPayload(child) };
  }

  private counterAttack(defender: PublicCardState, attacker: PublicCardState): Record<string, unknown> {
    const definition = CARD_DEFINITIONS[defender.definitionId];
    const die = this.effectiveAttackDie(defender, Math.max(1, definition.attackDie ?? 1));
    const dice = Math.max(1, definition.attackDice ?? 1);
    const damageRolls = Array.from({ length: dice }, () => this.rollForSeat(defender.owner, die));
    const modifier = (definition.attackModifier ?? 0) + this.equipmentAttackBonus(defender);
    const defense = (CARD_DEFINITIONS[attacker.definitionId]?.physicalDefense ?? 0) + this.equipmentDefenseBonus(attacker);
    const damage = Math.max(0, damageRolls.reduce((sum, value) => sum + value, 0) + modifier - defense);
    attacker.life -= damage;
    const destroyed = attacker.life <= 0;
    if (destroyed) this.destroyPublicCard(attacker);
    return { cardId: defender.instanceId, targetId: attacker.instanceId, attackType: "fisica", hit: true, damageRolls, modifier, defense, damage, destroyed, counterAttack: true };
  }

  private attack(seat: number, payload: Record<string, unknown>): ActionResult {
    const cardId = typeof payload.cardId === "string" ? payload.cardId : "";
    const attackType = payload.attackType === "magica" ? "magica" : "fisica";
    const attacker = this.state.cards.get(cardId);
    if (!attacker || attacker.category !== "tropa" || attacker.owner !== seat)
      return { ok: false, reason: "tropa_invalida" };
    if (attacker.attacked) return { ok: false, reason: "tropa_ja_atacou" };
    const attackerState = this.abilityState(attacker);
    if (attackerState.illusion) {
      attackerState.illusion = false;
      this.setAbilityState(attacker, attackerState);
      attacker.attacked = true;
      return { ok: true, details: { cardId, attackType, illusion: true, hit: false, damageRolls: [] } };
    }
    if (["paralisado", "congelado", "adormecido", "loucura"].includes(attacker.condition)) return { ok: false, reason: "tropa_incapacitada" };
    const definition = CARD_DEFINITIONS[attacker.definitionId];
    const itemDefinitionId = typeof payload.itemDefinitionId === "string" ? payload.itemDefinitionId : "";
    const equipped = this.equipmentIds(attacker);
    const weaponDefinition = itemDefinitionId ? CARD_DEFINITIONS[itemDefinitionId] : undefined;
    if (itemDefinitionId && (!equipped.includes(itemDefinitionId)
      || weaponDefinition?.category !== "item_equipavel" || !(weaponDefinition.overrideAttackDie && weaponDefinition.overrideAttackDie > 0)))
      return { ok: false, reason: "arma_invalida" };
    const usingWeapon = Boolean(weaponDefinition);
    const baseDie = usingWeapon ? weaponDefinition!.overrideAttackDie!
      : attackType === "magica" ? definition.magicDie ?? 0 : definition.attackDie ?? 0;
    const die = baseDie;
    const dice = usingWeapon ? 1 : attackType === "magica" ? definition.magicDice ?? 1 : definition.attackDice ?? 1;
    let modifier = usingWeapon ? weaponDefinition!.attackModifier ?? 0
      : (attackType === "magica" ? definition.magicModifier ?? 0 : definition.attackModifier ?? 0)
        + (attackType === "fisica" ? this.equipmentAttackBonus(attacker) : 0);
    let ignoreDefense = false;
    let frenzyBonus = 0;
    if (attackerState.frenzy === "self") {
      attackerState.frenzy = undefined;
      this.setAbilityState(attacker, attackerState);
      const adjacentAlly = this.findPublic((other) => other.instanceId !== attacker.instanceId
        && other.category === "tropa" && other.owner === seat
        && Math.abs(other.lane - attacker.lane) + Math.abs(other.position - attacker.position) === 1);
      if (!adjacentAlly) {
        const selfRolls = Array.from({ length: Math.max(1, definition.attackDice ?? 1) },
          () => this.rollForSeat(seat, Math.max(1, definition.attackDie ?? 1)));
        const selfDamage = Math.max(0, selfRolls.reduce((sum, value) => sum + value, 0)
          + (definition.attackModifier ?? 0) - (definition.physicalDefense ?? 0) - this.equipmentDefenseBonus(attacker));
        attacker.attacked = true;
        attacker.life -= selfDamage;
        if (attacker.life <= 0) this.destroyPublicCard(attacker);
        return { ok: true, details: { cardId, attackType, frenzySelf: true, damageRolls: selfRolls, damage: selfDamage, destroyed: attacker.life <= 0 } };
      }
    } else if (attackerState.frenzy === "bonus") {
      frenzyBonus = this.rollForSeat(seat, 8);
      modifier += frenzyBonus;
      ignoreDefense = true;
      attackerState.frenzy = undefined;
      this.setAbilityState(attacker, attackerState);
    }
    if (die <= 0) return { ok: false, reason: "ataque_indisponivel" };
    const direction = seat === 0 ? -1 : 1;
    const range = definition.abilities?.some((ability) => ability === "alcance" || ability === "alcance_magico") ? 2 : 1;
    let target = this.firstEnemyAhead(attacker, direction, range);
    if (!target && range > 1) target = this.findPublic((other) =>
      other.category === "construcao" && other.owner !== seat && other.lane === attacker.lane);
    const assaultPosition = seat === 0 ? 1 : 3;
    if (!target && attacker.position !== assaultPosition) return { ok: false, reason: "avance_para_assalto" };
    let stealRoll = 0;
    let stolenItem = "";
    if (target?.category === "tropa" && usingWeapon && this.hasAbility(target, "roubo")) {
      const targetEquipment = this.equipmentIds(target);
      const capacity = CARD_DEFINITIONS[target.definitionId]?.itemSlots ?? 0;
      if (targetEquipment.length < capacity) {
        stealRoll = this.rollForSeat(target.owner, 10);
        if (stealRoll === 10) {
          const attackerEquipment = this.equipmentIds(attacker);
          const weaponIndex = attackerEquipment.lastIndexOf(itemDefinitionId);
          if (weaponIndex >= 0) {
            attackerEquipment.splice(weaponIndex, 1);
            targetEquipment.push(itemDefinitionId);
            this.setEquipment(attacker, attackerEquipment);
            this.setEquipment(target, targetEquipment);
            stolenItem = itemDefinitionId;
          }
        }
      }
    }
    const accuracy = this.rollForSeat(seat, 20);
    attacker.attacked = true;
    if (accuracy === 20 && this.hasAbility(attacker, "tiro_burro")) {
      const candidates: PublicCardState[] = [];
      this.state.cards.forEach((other: PublicCardState) => {
        if (other.category === "tropa") candidates.push(other);
      });
      if (candidates.length > 0) target = candidates[this.roll(candidates.length) - 1];
    }
    if (target) {
      if (accuracy <= 10) {
        const counter = (accuracy === 1 || attacker.condition === "confusao") && target.category === "tropa"
          ? this.counterAttack(target, attacker) : undefined;
        return { ok: true, details: { cardId, targetId: target.instanceId, attackType, accuracy, hit: false, damageRolls: [], itemDefinitionId, stealRoll, stolenItem, counter } };
      }
      const targetDefinition = CARD_DEFINITIONS[target.definitionId];
      const targetState = this.abilityState(target);
      const defense = ignoreDefense ? 0 : (attackType === "magica"
        ? (targetDefinition.magicDefense ?? 0) + (targetState.grimoireShield ? 2 : 0)
        : (targetDefinition.physicalDefense ?? 0) + this.equipmentDefenseBonus(target));
      if (accuracy === 20) {
        this.pendingCritical = { seat, cardId, targetId: target.instanceId, targetType: "card", attackType, die, dice, modifier, defense, itemDefinitionId };
        return { ok: true, details: { cardId, targetId: target.instanceId, attackType, accuracy, hit: true, critical: true, criticalChoice: true, die, dice, itemDefinitionId, stealRoll, stolenItem } };
      }
      const damageRolls = Array.from({ length: dice }, () => this.rollForSeat(seat, die));
      const damage = Math.max(0, damageRolls.reduce((sum, value) => sum + value, 0) + modifier - defense);
      target.life -= damage;
      const destroyed = target.life <= 0;
      if (destroyed) {
        if (this.hasAbility(attacker, "digestao")) {
          attackerState.corpseAvailable = true;
          this.setAbilityState(attacker, attackerState);
        }
        this.destroyPublicCard(target);
      }
      return { ok: true, details: { cardId, targetId: target.instanceId, attackType, accuracy, hit: true, critical: false, damageRolls, modifier, defense, damage, destroyed, frenzyBonus, itemDefinitionId, stealRoll, stolenItem } };
    }
    if (accuracy <= 10) return { ok: true, details: { cardId, target: "castle", attackType, accuracy, hit: false, damageRolls: [], itemDefinitionId } };
    if (accuracy === 20) {
      this.pendingCritical = { seat, cardId, targetSeat: 1 - seat, targetType: "castle", attackType, die, dice, modifier, defense: 0, itemDefinitionId };
      return { ok: true, details: { cardId, target: "castle", attackType, accuracy, hit: true, critical: true, criticalChoice: true, die, dice, itemDefinitionId } };
    }
    const damageRolls = Array.from({ length: dice }, () => this.rollForSeat(seat, die));
    const damage = Math.max(0, damageRolls.reduce((sum, value) => sum + value, 0) + modifier);
    const defender = this.playerBySeat(1 - seat)!;
    defender.life = Math.max(0, defender.life - damage);
    if (defender.life <= 0) { this.state.winner = seat; this.state.phase = "finished"; }
    return { ok: true, details: { cardId, target: "castle", attackType, accuracy, hit: true, critical: false, damageRolls, modifier, damage, defenderLife: defender.life, itemDefinitionId } };
  }

  private chooseCritical(seat: number, payload: Record<string, unknown>): ActionResult {
    const pending = this.pendingCritical;
    if (!pending || pending.seat !== seat) return { ok: false, reason: "critico_inexistente" };
    const choice = payload.choice === "dobrar_dados" ? "dobrar_dados" : payload.choice === "dobrar_resultado" ? "dobrar_resultado" : "";
    if (!choice) return { ok: false, reason: "escolha_critico_invalida" };
    const target = pending.targetType === "card" && pending.targetId ? this.state.cards.get(pending.targetId) : undefined;
    if (pending.targetType === "card" && !target) { this.pendingCritical = undefined; return { ok: false, reason: "alvo_invalido" }; }
    const rollCount = choice === "dobrar_dados" ? pending.dice * 2 : pending.dice;
    const damageRolls = Array.from({ length: rollCount }, () => this.rollForSeat(seat, pending.die));
    const rolled = damageRolls.reduce((sum, value) => sum + value, 0);
    const original = choice === "dobrar_resultado" ? rolled * 2 : rolled;
    const damage = Math.max(0, original + pending.modifier - pending.defense);
    const attacker = this.state.cards.get(pending.cardId);
    let destroyed = false;
    let defenderLife: number | undefined;
    if (target) {
      target.life -= damage;
      destroyed = target.life <= 0;
      if (destroyed) {
        if (attacker && this.hasAbility(attacker, "digestao")) {
          const state = this.abilityState(attacker);
          state.corpseAvailable = true;
          this.setAbilityState(attacker, state);
        }
        this.destroyPublicCard(target);
      }
    } else {
      const defender = this.playerBySeat(pending.targetSeat ?? (1 - seat))!;
      defender.life = Math.max(0, defender.life - damage);
      defenderLife = defender.life;
      if (defender.life <= 0) { this.state.winner = seat; this.state.phase = "finished"; }
    }
    const repeatAfter = pending.repeatAfter ?? 0;
    this.pendingCritical = undefined;
    let followUp: Record<string, unknown> | undefined;
    if (repeatAfter > 0 && attacker && this.state.cards.has(attacker.instanceId)) {
      attacker.attacked = false;
      const repeated = this.attack(seat, { cardId: attacker.instanceId, attackType: pending.attackType });
      followUp = repeated.details;
      const chainedCritical = this.pendingCritical as unknown as { repeatAfter?: number } | undefined;
      if (chainedCritical) chainedCritical.repeatAfter = repeatAfter - 1;
      attacker.attacked = true;
    }
    return { ok: true, details: { cardId: pending.cardId, targetId: pending.targetId ?? "", target: pending.targetType === "castle" ? "castle" : "card", attackType: pending.attackType, criticalResolved: true, critical: true, choice, damageRolls, modifier: pending.modifier, defense: pending.defense, damage, destroyed, defenderLife, itemDefinitionId: pending.itemDefinitionId ?? "", followUp, criticalChoice: Boolean(this.pendingCritical) } };
  }
  private endTurn(seat: number): ActionResult {
    if (seat !== this.state.currentPlayer) return { ok: false, reason: "fora_do_turno" };
    const nextSeat = 1 - seat;
    const endingPlayer = this.playerBySeat(seat)!;
    endingPlayer.hasTakenTurn = true;
    if (endingPlayer.blockedTurns > 0) {
      endingPlayer.blockedTurns -= 1;
      if (endingPlayer.blockedTurns <= 0) endingPlayer.blockedResource = "";
    }
    const nextPlayer = this.playerBySeat(nextSeat)!;
    // Expira as condições do jogador que terminou o turno.
    this.state.cards.forEach((card: PublicCardState) => {
      if (card.owner !== seat || card.category !== "tropa") return;
      const ability = this.abilityState(card);
      if ((ability.shadowCooldown ?? 0) > 0) {
        ability.shadowCooldown = Math.max(0, (ability.shadowCooldown ?? 0) - 1);
        if (ability.shadowCooldown === 1) ability.shadowTurns = 0;
        this.setAbilityState(card, ability);
      }
      if (card.conditionTurns <= 0) return;
      card.conditionTurns -= 1;
      if (card.conditionTurns <= 0) {
        card.condition = "";
        card.conditionPower = 0;
      }
    });

    // Processa dano e cura persistentes no início do turno do próximo jogador.
    const defeated: PublicCardState[] = [];
    this.state.cards.forEach((card: PublicCardState) => {
      if (card.owner !== nextSeat || card.category !== "tropa") return;
      if (["queimado", "envenenado", "corrosao", "sangrando", "apodrecer"].includes(card.condition)) {
        card.life -= Math.max(0, card.conditionPower);
        if (card.condition === "corrosao" && card.conditionPower > 1) card.conditionPower -= 1;
      } else if (card.condition === "regeneracao") {
        card.life = Math.min(card.maxLife, card.life + Math.max(0, card.conditionPower));
      }
      if (card.life <= 0) defeated.push(card);
    });
    for (const card of defeated) this.destroyPublicCard(card);
    this.state.currentPlayer = nextSeat;
    this.state.turnNumber += 1;
    this.resetPlayerTurn(nextPlayer);
    this.state.cards.forEach((card: PublicCardState) => {
      if (card.owner === nextSeat) {
        const ability = this.abilityState(card);
        ability.used = false;
        ability.itemActionUsed = false;
        ability.grimoireUsed = false;
        ability.grimoireShield = false;
        this.setAbilityState(card, ability);
      }
      if (card.owner === nextSeat && card.category === "tropa") {
        card.turnsInPlay += 1;
        card.moved = false;
        card.attacked = false;
      }
    });
    const artillery = this.processArtillery(nextSeat);
    this.drawCards(nextSeat, 1);
    return {
      ok: true,
      details: { currentPlayer: nextSeat, turnNumber: this.state.turnNumber, artillery },
      privateSeats: [nextSeat],
    };
  }

  private processArtillery(seat: number): Record<string, unknown>[] {
    const events: Record<string, unknown>[] = [];
    const towers: PublicCardState[] = [];
    this.state.cards.forEach((card: PublicCardState) => {
      if (card.owner === seat && card.category === "construcao"
        && CARD_DEFINITIONS[card.definitionId]?.effect === "artilharia") towers.push(card);
    });
    for (const tower of towers) {
      let target: PublicCardState | undefined;
      let bestDistance = Infinity;
      this.state.cards.forEach((card: PublicCardState) => {
        if (card.category !== "tropa" || card.owner === seat || card.lane !== tower.lane) return;
        const entry = seat === 0 ? 4 : 0;
        const distance = Math.abs(card.position - entry);
        if (distance < bestDistance) { bestDistance = distance; target = card; }
      });
      if (!target) continue;
      const damage = this.rollForSeat(seat, 6);
      target.life -= damage;
      const destroyed = target.life <= 0;
      const targetId = target.instanceId;
      if (destroyed) this.destroyPublicCard(target);
      events.push({ cardId: tower.instanceId, targetId, damageRolls: [damage], damage, destroyed });
    }
    return events;
  }

  private payCost(player: PlayerState, definition: CardDefinition): boolean {
    const planned: Partial<Record<ResourceType, number>> = {};
    const available = (type: ResourceType) =>
      player.blockedResource === type && player.blockedTurns > 0 ? 0 :
      player[RESOURCE_FIELDS[type]] - player[USED_FIELDS[type]] - (planned[type] ?? 0);

    for (const part of definition.cost.filter((part) => part.type !== "qualquer")) {
      const type = part.type as ResourceType;
      if (available(type) < part.amount) return false;
      planned[type] = (planned[type] ?? 0) + part.amount;
    }

    const wildcard = definition.cost
      .filter((part) => part.type === "qualquer")
      .reduce((sum, part) => sum + part.amount, 0);
    let remaining = wildcard;
    for (const type of RESOURCE_ORDER) {
      const amount = Math.min(available(type), remaining);
      planned[type] = (planned[type] ?? 0) + amount;
      remaining -= amount;
      if (remaining === 0) break;
    }
    if (remaining > 0) return false;

    for (const type of RESOURCE_ORDER) player[USED_FIELDS[type]] += planned[type] ?? 0;
    return true;
  }

  private createPublicCard(
    card: PrivateCard, definition: CardDefinition, owner: number, lane: number, position: number,
  ): PublicCardState {
    const result = new PublicCardSchema();
    result.instanceId = card.instanceId;
    result.definitionId = card.definitionId;
    result.name = definition.name;
    result.category = definition.category;
    result.owner = owner;
    result.lane = lane;
    result.position = position;
    result.life = Math.max(0, Math.ceil((definition.life ?? 0) * (card.lifeScale ?? 1)));
    result.maxLife = result.life;
    result.moved = false;
    result.attacked = false;
    result.defendingCastle = false;
    result.turnsInPlay = 0;
    result.condition = "";
    result.conditionTurns = 0;
    result.conditionPower = 0;
    result.intelligence = definition.intelligence ?? 0;
    result.equipmentJson = "[]";
    result.abilityStateJson = "{}";
    return result;
  }

  private firstEnemyAhead(attacker: PublicCardState, direction: number, range: number): PublicCardState | undefined {
    for (let distance = 1; distance <= range; distance++) {
      const position = attacker.position + direction * distance;
      const target = this.findPublic((card) => {
        if (card.category !== "tropa" || card.owner === attacker.owner
          || card.lane !== attacker.lane || card.position !== position) return false;
        const abilities = CARD_DEFINITIONS[attacker.definitionId]?.abilities ?? [];
        const targetAbilities = CARD_DEFINITIONS[card.definitionId]?.abilities ?? [];
        if (targetAbilities.includes("voar") && !abilities.includes("voar")
          && !abilities.includes("alcance") && !abilities.includes("alcance_magico")) return false;
        if ((this.abilityState(card).shadowTurns ?? 0) > 0) return false;
        const assault = attacker.owner === 0 ? 1 : 3;
        const enemyEntry = attacker.owner === 0 ? 0 : 4;
        if (attacker.position === assault && position === enemyEntry && !card.defendingCastle) return false;
        return true;
      });
      if (target) return target;
      if (distance === 1 && range === 1) break;
    }
    return undefined;
  }

  private destroyPublicCard(card: PublicCardState) {
    if (!this.state.cards.has(card.instanceId)) return;
    this.state.cards.delete(card.instanceId);
    const privatePlayer = this.privatePlayers[card.owner];
    privatePlayer.discard.push({ instanceId: card.instanceId, definitionId: card.definitionId });
    const equipment = this.equipmentIds(card);
    const hasMagnet = Boolean(this.findPublic((other) => other.category === "construcao"
      && other.owner === card.owner && other.lane === card.lane
      && CARD_DEFINITIONS[other.definitionId]?.effect === "maquina_ima"));
    if (card.category === "tropa" && hasMagnet && equipment.length > 0) {
      this.pendingMagnet[card.owner].push({ sourceCardId: card.instanceId, equipment: [...equipment] });
      if (this.pendingMagnet[card.owner].length === 1) this.sendNextMagnetChoice(card.owner);
    } else {
      equipment.forEach((definitionId, index) =>
        privatePlayer.discard.push({ instanceId: card.instanceId + "-item-" + index, definitionId }));
    }
    if (privatePlayer.effects.includes("cura_ao_morrer")) {
      const owner = this.playerBySeat(card.owner); if (owner) owner.life = Math.min(20, owner.life + 1);
    }
    const enemyEffects = this.privatePlayers[1 - card.owner]?.effects ?? [];
    if (enemyEffects.includes("perde_vida_ao_morrer")) {
      const owner = this.playerBySeat(card.owner); if (owner) owner.life = Math.max(0, owner.life - 1);
    }
    if (card.category === "construcao") {
      for (const trap of privatePlayer.traps) if (trap.definitionId === "destrocos" && trap.lane === card.lane) trap.ready = true;
    }
    if (card.category === "tropa" && this.hasAbility(card, "mitose")) this.performMitosis(card);
    this.updateCounts(card.owner);
  }
  private takeDefinitionFromHandOrDeck(seat: number, definitionId: string): PrivateCard | undefined {
    const data = this.privatePlayers[seat];
    let index = data.hand.findIndex((item) => item.definitionId === definitionId);
    if (index >= 0) return data.hand.splice(index, 1)[0];
    index = data.deck.findIndex((item) => item.definitionId === definitionId);
    if (index >= 0) return data.deck.splice(index, 1)[0];
    return undefined;
  }

  private performMitosis(parent: PublicCardState) {
    const first = this.takeDefinitionFromHandOrDeck(parent.owner, "slimet");
    if (!first) return;
    const spawn = (source: PrivateCard, lane: number, position: number) => {
      const child = this.createPublicCard(source, CARD_DEFINITIONS.slimet, parent.owner, lane, position);
      child.moved = true;
      this.state.cards.set(child.instanceId, child);
    };
    spawn(first, parent.lane, parent.position);
    const candidates = ([
      [parent.lane, parent.position - 1], [parent.lane, parent.position + 1],
      [parent.lane - 1, parent.position], [parent.lane + 1, parent.position],
    ] as Array<[number, number]>).filter(([lane, position]) => lane >= 0 && lane <= 2 && position >= 0 && position <= 4
      && !this.findPublic((other) => other.category === "tropa" && other.lane === lane && other.position === position)
      && !this.findPublic((other) => other.category === "tropa" && other.owner === parent.owner && other.lane === lane));
    if (candidates.length <= 0) return;
    const second = this.takeDefinitionFromHandOrDeck(parent.owner, "slimet");
    if (!second) return;
    this.pendingMitosis[parent.owner] = { source: second, owner: parent.owner, candidates };
    const client = this.clientBySeat(parent.owner);
    if (client) this.sendJson(client, "mitosis_choice", { sourceCardId: parent.instanceId, candidates: candidates.map(([lane, position]) => ({ lane, position })) });
  }

  private handCard(seat: number, cardId: unknown) {
    if (typeof cardId !== "string") return undefined;
    const hand = this.privatePlayers[seat].hand;
    const index = hand.findIndex((card) => card.instanceId === cardId);
    if (index < 0) return undefined;
    const card = hand[index];
    const definition = CARD_DEFINITIONS[card.definitionId];
    return definition ? { card, definition, index } : undefined;
  }

  private removeHandCard(seat: number, index: number): PrivateCard {
    const [card] = this.privatePlayers[seat].hand.splice(index, 1);
    this.updateCounts(seat);
    return card;
  }

  private discardHandCard(seat: number, index: number) {
    const card = this.removeHandCard(seat, index);
    this.privatePlayers[seat].discard.push(card);
    this.updateCounts(seat);
  }

  private drawCards(seat: number, amount: number) {
    const data = this.privatePlayers[seat];
    for (let i = 0; i < amount && data.deck.length > 0; i++) {
      const card = data.deck.shift();
      if (card) data.hand.push(card);
    }
    this.updateCounts(seat);
  }

  private sendPrivateState(seat: number) {
    const client = this.clientBySeat(seat);
    const data = this.privatePlayers[seat];
    if (!client || !data) return;
    this.sendJson(client, "private_state", {
      hand: data.hand.map((card) => {
        const definition = CARD_DEFINITIONS[card.definitionId];
        return {
          instanceId: card.instanceId,
          definitionId: card.definitionId,
          name: definition.name,
          category: definition.category,
          cost: definition.cost,
        };
      }),
      deckCount: data.deck.length,
      discard: data.discard.map((card) => card.definitionId),
      activeTraps: data.traps.map((trap) => ({ ...trap, name: CARD_DEFINITIONS[trap.definitionId]?.name ?? "Armadilha" })),
      activeEffects: data.effects,
      revision: this.state.revision,
    });
  }

  private sendPublicState(client?: Client) {
    if (!client) { for (const target of this.clients) this.sendPublicState(target); return; }
    const viewerSeat = this.findPlayer(client.sessionId)?.seatIndex ?? -1;
    const players: Record<string, unknown>[] = [];
    this.state.players.forEach((player: PlayerState) => players.push({
      seat: player.seatIndex, name: player.name, connected: player.connected,
      life: player.life, handCount: player.handCount, deckCount: player.deckCount,
      mana: player.mana, sangue: player.sangue, ossos: player.ossos, sucata: player.sucata,
      manaUsed: player.manaUsed, sangueUsed: player.sangueUsed,
      ossosUsed: player.ossosUsed, sucataUsed: player.sucataUsed,
      blockedResource: player.blockedResource, blockedTurns: player.blockedTurns, hasTakenTurn: player.hasTakenTurn,
      activeEffects: this.privatePlayers[player.seatIndex]?.effects ?? [],
    }));
    const cards: Record<string, unknown>[] = [];
    this.state.cards.forEach((card: PublicCardState) => cards.push({
      ...this.publicCardPayload(card), moved: card.moved,
      attacked: card.attacked, condition: card.condition, conditionTurns: card.conditionTurns,
      conditionPower: card.conditionPower, intelligence: card.intelligence,
      equipment: this.equipmentIds(card), abilityState: this.abilityState(card),
    }));
    const traps: Record<string, unknown>[] = [];
    for (let owner = 0; owner < this.privatePlayers.length; owner++) {
      for (const trap of this.privatePlayers[owner]?.traps ?? []) traps.push({
        instanceId: trap.instanceId, owner, lane: trap.lane, position: trap.position,
        definitionId: owner === viewerSeat ? trap.definitionId : "",
        name: owner === viewerSeat ? CARD_DEFINITIONS[trap.definitionId]?.name : "Armadilha",
        ready: owner === viewerSeat ? trap.ready : false,
      });
    }
    const payload = {
      phase: this.state.phase, currentPlayer: this.state.currentPlayer,
      winner: this.state.winner, revision: this.state.revision,
      turnNumber: this.state.turnNumber,
      terrainDefinitionId: this.state.terrainDefinitionId,
      discardCounts: [this.state.discardCount0, this.state.discardCount1],
      players, cards, traps,
    };
    this.sendJson(client, "public_state", payload);
  }

  private updateCounts(seat: number) {
    const player = this.playerBySeat(seat);
    const data = this.privatePlayers[seat];
    if (!player || !data) return;
    player.handCount = data.hand.length;
    player.deckCount = data.deck.length;
    if (seat === 0) this.state.discardCount0 = data.discard.length;
    else this.state.discardCount1 = data.discard.length;
  }

  private resetPlayerTurn(player: PlayerState) {
    player.manaUsed = 0; player.sangueUsed = 0; player.ossosUsed = 0; player.sucataUsed = 0;
    player.resourcePlaced = false;
    player.troopsPlayed = 0;
    player.constructionsPlayed = 0;
    player.spellsUsed = 0;
    player.itemsUsed = 0;
    player.terrainPlayed = false;
    player.evolutionsUsed = 0;
  }

  private makePrivateCard(seat: number, definitionId: string): PrivateCard {
    return { instanceId: `p${seat}-c${this.nextCardId++}`, definitionId };
  }

  private shuffle<T>(items: T[]): T[] {
    for (let i = items.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [items[i], items[j]] = [items[j], items[i]];
    }
    return items;
  }

  private roll(sides: number): number {
    return Math.floor(Math.random() * sides) + 1;
  }

  private rollForSeat(seat: number, sides: number): number {
    const rolled = this.roll(sides);
    const data = this.privatePlayers[seat];
    if (!data) return rolled;
    const index = data.effects.findIndex((value) => value.startsWith("dados_manipulados:"));
    if (index < 0) return rolled;
    const parts = data.effects[index].split(":");
    const fixed = Number(parts[1]);
    const remaining = Number(parts[2]);
    if (!Number.isInteger(fixed) || fixed <= 0 || fixed > sides || remaining <= 0) return rolled;
    if (remaining <= 1) data.effects.splice(index, 1);
    else data.effects[index] = "dados_manipulados:" + fixed + ":" + (remaining - 1);
    return Math.max(rolled, fixed);
  }

  private publicCardPayload(card: PublicCardState) {
    return {
      instanceId: card.instanceId, definitionId: card.definitionId, name: card.name,
      category: card.category, owner: card.owner, lane: card.lane, position: card.position,
      life: card.life, maxLife: card.maxLife, defendingCastle: card.defendingCastle, turnsInPlay: card.turnsInPlay,
    };
  }

  private findPublic(predicate: (card: PublicCardState) => boolean): PublicCardState | undefined {
    let result: PublicCardState | undefined;
    this.state.cards.forEach((card: PublicCardState) => {
      if (!result && predicate(card)) result = card;
    });
    return result;
  }

  private nextSeat(): number {
    return this.playerBySeat(0) ? 1 : 0;
  }

  private playerBySeat(seat: number): PlayerState | undefined {
    let result: PlayerState | undefined;
    this.state.players.forEach((player: PlayerState) => {
      if (player.seatIndex === seat) result = player;
    });
    return result;
  }

  private clientBySeat(seat: number): Client | undefined {
    const player = this.playerBySeat(seat);
    return player ? this.clients.find((client) => client.sessionId === player.sessionId) : undefined;
  }

  private findPlayer(sessionId: string): PlayerState | undefined {
    return this.state.players.get(sessionId);
  }

  private startInitiativeWhenReady() {
    if (this.clients.length !== 2 || this.state.players.size !== 2) return;
    let allReady = true;
    this.state.players.forEach((player: PlayerState) => { if (!player.ready) allReady = false; });
    if (!allReady) return;
    this.state.phase = "initiative";
    this.bump("initiative_started");
    this.sendPublicState();
  }

  private finishInitiativeIfReady() {
    const players: PlayerState[] = [];
    this.state.players.forEach((player: PlayerState) => players.push(player));
    if (players.length !== 2 || players.some((player) => player.initiative <= 0)) return;
    if (players[0].initiative === players[1].initiative) {
      players.forEach((player) => { player.initiative = 0; });
      this.bump("initiative_tie");
      this.broadcastJson("initiative_tie", {});
      return;
    }
    const winner = players[0].initiative > players[1].initiative ? players[0] : players[1];
    this.state.initiativeWinner = winner.seatIndex;
    this.state.phase = "choose_first";
    this.bump("initiative_finished");
  }

  private reject(client: Client, reason: string) {
    this.sendJson(client, "action_rejected", { reason, revision: this.state.revision });
  }

  private bump(action: string) {
    this.state.revision += 1;
    this.state.lastAction = action;
  }
}
