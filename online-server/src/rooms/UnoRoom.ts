import { Room, Client } from "@colyseus/core";
import {
  KarthaRoomState, PlayerSchema, PublicCardSchema,
} from "./schema/UnoRoomState.ts";
import {
  CARD_DEFINITIONS, CardDefinition, CostPart, ResourceType, defaultDeck, validateDeck,
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
interface ActiveResource { instanceId: string; definitionId: string; type: ResourceType; amount: number; used: boolean; }
interface ActiveEffectCard {
  definitionId: string;
  effect: string;
  category: "bencao" | "maldicao";
  name: string;
}

interface PrivatePlayer {
  traps: ActiveTrap[];
  resources: ActiveResource[];
  abyss: PrivateCard[];
  effects: string[];
  effectCards: ActiveEffectCard[];
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
  electrocutions?: number;
  electrocutedThisCycle?: boolean;
  madnessNoDefense?: boolean;
  burnImmunity?: number;
  bleedingWindow?: boolean;
  bleedingHitThisCycle?: boolean;
}

interface PendingMagnetChoice {
  sourceCardId: string;
  equipment: string[];
}

interface ManipulatedRollDecision { seat: number; natural: number; fixed: number; sides: number; useAlternative: boolean; }
interface PendingManipulatedAction {
  seat: number; kind: string; payload: Record<string, unknown>; revision: number;
  decisions: ManipulatedRollDecision[]; rolls: Array<{ sides: number; value: number }>; waiting?: Omit<ManipulatedRollDecision, "useAlternative">; snapshot: MatchSnapshot;
}
interface MatchSnapshot {
  state: Record<string, unknown>; players: Array<[string, Record<string, unknown>]>; cards: Array<[string, Record<string, unknown>]>;
  privatePlayers: PrivatePlayer[]; nextCardId: number; pendingCritical?: Record<string, unknown>;
  pendingMagnet: PendingMagnetChoice[][]; pendingMitosis: Array<PendingMitosisChoice | undefined>; rematchVotes: number[];
  activeTerrain?: { owner: number; card: PrivateCard };
}

interface PendingMitosisChoice {
  source: PrivateCard;
  owner: number;
  candidates: Array<[number, number]>;
}

const ACTIONS = new Set([
  "place_resource", "play_troop", "play_construction",
  "move_troop", "attack", "choose_critical", "end_turn", "set_castle_defense", "evolve_troop",
  "play_spell", "play_item", "play_trap", "activate_trap", "play_effect", "remove_resource",
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
  private pendingCritical?: { seat: number; cardId: string; targetId?: string; targetSeat?: number; targetType: "card" | "castle"; attackType: "fisica" | "magica"; die: number; dice: number; modifier: number; defense: number; itemDefinitionId?: string; repeatAfter?: number; damageMultiplier: number };
  private pendingMagnet: PendingMagnetChoice[][] = [[], []];
  private pendingMitosis: Array<PendingMitosisChoice | undefined> = [undefined, undefined];
  private rematchVotes = new Set<number>();
  private pendingManipulated?: PendingManipulatedAction;
  private manipulatedReplay?: { decisions: ManipulatedRollDecision[]; cursor: number; rolls: Array<{ sides: number; value: number }>; rollCursor: number };
  private replayingManipulated = false;
  private actionPassiveEvents: Array<Record<string, unknown>> = [];
  private activeTerrain?: { owner: number; card: PrivateCard };

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

    this.onMessage("draw_initial", (client: Client) => {
      const player = this.findPlayer(client.sessionId);
      if (!player || this.state.phase !== "drawing" || player.initialHandDrawn) return;
      this.drawCards(player.seatIndex, 7);
      player.initialHandDrawn = true;
      this.bump("initial_hand_drawn");
      this.sendPrivateState(player.seatIndex);
      this.broadcastJson("initial_drawn", { seat: player.seatIndex, revision: this.state.revision });
      let everyoneDrew = true;
      this.state.players.forEach((participant: PlayerState) => { if (!participant.initialHandDrawn) everyoneDrew = false; });
      if (everyoneDrew) {
        this.state.phase = "playing";
        this.bump("match_ready");
        this.broadcastJson("match_ready", { currentPlayer: this.state.currentPlayer, revision: this.state.revision });
      }
      this.sendPublicState();
    });

    this.onMessage("choose_manipulated_roll", (client: Client, rawMessage: { useAlternative?: boolean } | string) => {
      const message = decodeIncoming<{ useAlternative?: boolean }>(rawMessage) ?? {};
      const player = this.findPlayer(client.sessionId);
      const pending = this.pendingManipulated;
      if (!player || !pending || !pending.waiting || pending.waiting.seat !== player.seatIndex) return;
      pending.decisions.push({ ...pending.waiting, useAlternative: message.useAlternative === true });
      pending.waiting = undefined;
      this.executeManipulatedAction(pending);
    });

    this.onMessage("action", (client: Client, rawMessage: ActionMessage | string) => {
      const message = decodeIncoming<ActionMessage>(rawMessage) ?? {};
      const player = this.findPlayer(client.sessionId);
      const kind = typeof message?.kind === "string" ? message.kind : "";
      if (!player) return;
      if (this.pendingManipulated) return this.reject(client, "escolha_dado_manipulado_pendente");
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

      const pending: PendingManipulatedAction = {
        seat: player.seatIndex, kind, payload: message?.payload ?? {}, revision: this.state.revision,
        decisions: [], rolls: [], snapshot: this.captureMatchSnapshot(),
      };
      this.executeManipulatedAction(pending);
    });

    this.onMessage("concede", (client: Client) => {
      const player = this.findPlayer(client.sessionId);
      if (!player || this.state.phase === "finished") return;
      this.state.winner = 1 - player.seatIndex;
      this.state.phase = "finished";
      this.bump("concede");
      this.sendPublicState();
    });

    this.onMessage("rematch", (client: Client) => {
      const player = this.findPlayer(client.sessionId);
      if (!player || this.state.phase !== "finished") return;
      this.rematchVotes.add(player.seatIndex);
      this.broadcastJson("rematch_status", { seats: [...this.rematchVotes] });
      if (this.rematchVotes.size < 2) return;

      this.rematchVotes.clear();
      this.pendingCritical = undefined;
      this.pendingManipulated = undefined;
      this.pendingMagnet = [[], []];
      this.pendingMitosis = [undefined, undefined];
      this.activeTerrain = undefined;
      this.state.cards.clear();
      this.state.terrainDefinitionId = "";
      this.state.currentPlayer = -1;
      this.state.initiativeWinner = -1;
      this.state.winner = -1;
      this.state.turnNumber = 0;
      this.state.phase = "initiative";
      this.state.players.forEach((participant: PlayerState) => {
        participant.initiative = 0;
        participant.ready = true;
      });
      this.bump("rematch_started");
      this.broadcastJson("rematch_started", { revision: this.state.revision });
      this.sendPublicState();
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
    player.initialHandDrawn = false;
    this.resetPlayerTurn(player);
    player.mana = 0; player.sangue = 0; player.ossos = 0; player.sucata = 0;
      player.blockedResource = ""; player.blockedTurns = 0;
    player.evolutionsUsed = 0;
    this.state.players.set(client.sessionId, player);
    this.privatePlayers[seat] = { deck: [], hand: [], discard: [], abyss: [], resources: [],
      configuredDeck: defaultDeck(), traps: [], effects: [], effectCards: [], lastNonTroopDefinitionId: "" };
    this.setMetadata({ players: this.clients.length, phase: this.state.phase });
    this.sendJson(client, "seat", { seat, roomId: this.roomId, seed: this.state.seed });
  }

  async onLeave(client: Client, code?: number) {
    const player = this.findPlayer(client.sessionId);
    if (!player) return;
    player.connected = false;

    if (code === 1000) {
      if (this.state.phase !== "waiting" && this.state.phase !== "finished") {
        this.state.winner = 1 - player.seatIndex;
        this.state.phase = "finished";
        this.bump("voluntary_leave");
        this.sendPublicState();
      }
      this.state.players.delete(client.sessionId);
      return;
    }
    if (this.state.phase === "waiting") {
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
      if (this.pendingManipulated?.waiting?.seat === player.seatIndex)
        this.sendJson(reconnected, "manipulated_roll_choice", this.pendingManipulated.waiting);
    } catch {
      this.state.winner = 1 - player.seatIndex;
      this.state.phase = "finished";
      this.bump("disconnect");
    }
  }

  private startMatch(firstSeat: number) {
    this.pendingManipulated = undefined;
    this.rematchVotes.clear();
    this.activeTerrain = undefined;
    this.state.cards.clear();
    this.nextCardId = 1;
    for (let seat = 0; seat < 2; seat++) {
      const data = this.privatePlayers[seat];
      data.hand = [];
      data.discard = [];
      data.abyss = [];
      data.resources = [];
      data.traps = [];
      data.effects = [];
      data.effectCards = [];
      data.lastNonTroopDefinitionId = "";
      this.pendingMagnet[seat] = [];
      this.pendingMitosis[seat] = undefined;
      data.deck = this.shuffle(data.configuredDeck.map((definitionId) => this.makePrivateCard(seat, definitionId)));
      const player = this.playerBySeat(seat);
      if (!player) continue;
      player.life = 20;
      player.hasTakenTurn = false;
      player.initialHandDrawn = false;
      player.mana = 0; player.sangue = 0; player.ossos = 0; player.sucata = 0;
      player.blockedResource = ""; player.blockedTurns = 0;
    player.evolutionsUsed = 0;
      player.manaUsed = 0; player.sangueUsed = 0; player.ossosUsed = 0; player.sucataUsed = 0;
      this.resetPlayerTurn(player);
    }

    this.state.currentPlayer = firstSeat;
    this.state.phase = "drawing";
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

  private cloneData<T>(value: T): T { return JSON.parse(JSON.stringify(value)) as T; }

  private captureMatchSnapshot(): MatchSnapshot {
    const players: Array<[string, Record<string, unknown>]> = [];
    this.state.players.forEach((player: PlayerState, key: string) => players.push([key, this.cloneData(player) as unknown as Record<string, unknown>]));
    const cards: Array<[string, Record<string, unknown>]> = [];
    this.state.cards.forEach((card: PublicCardState, key: string) => cards.push([key, this.cloneData(card) as unknown as Record<string, unknown>]));
    return {
      state: { phase: this.state.phase, currentPlayer: this.state.currentPlayer, initiativeWinner: this.state.initiativeWinner,
        winner: this.state.winner, revision: this.state.revision, seed: this.state.seed, turnNumber: this.state.turnNumber,
        terrainDefinitionId: this.state.terrainDefinitionId, discardCount0: this.state.discardCount0,
        discardCount1: this.state.discardCount1, lastAction: this.state.lastAction },
      players, cards, privatePlayers: this.cloneData(this.privatePlayers), nextCardId: this.nextCardId,
      pendingCritical: this.pendingCritical ? this.cloneData(this.pendingCritical) : undefined,
      pendingMagnet: this.cloneData(this.pendingMagnet), pendingMitosis: this.cloneData(this.pendingMitosis),
      rematchVotes: [...this.rematchVotes],
      activeTerrain: this.activeTerrain ? this.cloneData(this.activeTerrain) : undefined,
    };
  }

  private restoreMatchSnapshot(snapshot: MatchSnapshot) {
    Object.assign(this.state, snapshot.state);
    this.state.players.clear();
    for (const [key, data] of snapshot.players) { const player = new PlayerSchema(); Object.assign(player, data); this.state.players.set(key, player); }
    this.state.cards.clear();
    for (const [key, data] of snapshot.cards) { const card = new PublicCardSchema(); Object.assign(card, data); this.state.cards.set(key, card); }
    this.privatePlayers = this.cloneData(snapshot.privatePlayers);
    this.nextCardId = snapshot.nextCardId;
    this.pendingCritical = snapshot.pendingCritical ? this.cloneData(snapshot.pendingCritical) as typeof this.pendingCritical : undefined;
    this.pendingMagnet = this.cloneData(snapshot.pendingMagnet);
    this.pendingMitosis = this.cloneData(snapshot.pendingMitosis);
    this.rematchVotes = new Set(snapshot.rematchVotes);
    this.activeTerrain = snapshot.activeTerrain ? this.cloneData(snapshot.activeTerrain) : undefined;
  }

  private confirmAction(seat: number, kind: string, result: ActionResult) {
    this.state.revision += 1;
    this.state.lastAction = kind;
    this.broadcastJson("action_confirmed", { revision: this.state.revision, seat, kind, payload: result.details ?? {} });
    for (let targetSeat = 0; targetSeat < 2; targetSeat++) this.sendPrivateState(targetSeat);
    if (!result.details?.criticalChoice) this.sendPublicState();
  }

  private executeManipulatedAction(pending: PendingManipulatedAction) {
    const initiator = this.clientBySeat(pending.seat);
    this.restoreMatchSnapshot(pending.snapshot);
    this.pendingManipulated = pending;
    this.manipulatedReplay = { decisions: pending.decisions, cursor: 0, rolls: pending.rolls, rollCursor: 0 };
    this.replayingManipulated = true;
    this.actionPassiveEvents = [];
    let result: ActionResult;
    try {
      result = this.applyAction(pending.seat, pending.kind, pending.payload);
    } catch (error) {
      const roll = error as { manipulatedRoll?: boolean; seat?: number; natural?: number; fixed?: number; sides?: number };
      this.restoreMatchSnapshot(pending.snapshot);
      if (!roll?.manipulatedRoll) { this.pendingManipulated = undefined; throw error; }
      pending.waiting = { seat: Number(roll.seat), natural: Number(roll.natural), fixed: Number(roll.fixed), sides: Number(roll.sides) };
      this.pendingManipulated = pending;
      const chooser = this.clientBySeat(pending.waiting.seat);
      if (chooser) this.sendJson(chooser, "manipulated_roll_choice", pending.waiting);
      else { this.pendingManipulated = undefined; if (initiator) this.reject(initiator, "jogador_indisponivel"); }
      return;
    } finally {
      this.manipulatedReplay = undefined;
      this.replayingManipulated = false;
    }
    if (!result.ok) {
      this.restoreMatchSnapshot(pending.snapshot);
      this.pendingManipulated = undefined;
      if (initiator) this.reject(initiator, result.reason ?? "acao_invalida");
      return;
    }
    if (this.actionPassiveEvents.length > 0) {
      result.details = { ...(result.details ?? {}), passiveEvents: this.cloneData(this.actionPassiveEvents) };
    }
    this.pendingManipulated = undefined;
    for (let seat = 0; seat < 2; seat++) {
      this.sendNextMagnetChoice(seat);
      const mitosis = this.pendingMitosis[seat];
      const client = this.clientBySeat(seat);
      if (mitosis && client) this.sendJson(client, "mitosis_choice", {
        candidates: mitosis.candidates.map(([lane, position]) => ({ lane, position })),
      });
    }
    this.confirmAction(pending.seat, pending.kind, result);
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
      case "remove_resource": return this.removeResource(seat, payload);
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
    const data = this.privatePlayers[seat];
    if (player.resourcePlaced) return { ok: false, reason: "recurso_ja_colocado" };
    if (data.resources.length >= 6) return { ok: false, reason: "limite_recursos" };

    const found = this.handCard(seat, payload.cardId);
    if (!found || found.definition.category !== "recurso" || !found.definition.resourceType)
      return { ok: false, reason: "carta_recurso_invalida" };

    const card = this.removeHandCard(seat, found.index);
    const type = found.definition.resourceType;
    const amount = Math.max(1, Math.floor(found.definition.resourceAmount ?? 1));
    data.resources.push({ instanceId: card.instanceId, definitionId: card.definitionId, type, amount, used: false });
    player.resourcePlaced = true;
    this.syncResourceTotals(seat);
    return {
      ok: true,
      details: { cardId: card.instanceId, definitionId: card.definitionId, resourceType: type, resourceAmount: amount },
      privateSeats: [seat],
    };
  }

  private removeResource(seat: number, payload: Record<string, unknown>): ActionResult {
    const player = this.playerBySeat(seat)!;
    if (player.resourceRemoved) return { ok: false, reason: "recurso_ja_retirado" };
    const data = this.privatePlayers[seat];
    const resourceId = typeof payload.resourceId === "string" ? payload.resourceId : "";
    const type = typeof payload.resourceType === "string" ? payload.resourceType : "";
    const index = data.resources.findIndex((resource) =>
      resource.instanceId === resourceId || (!resourceId && resource.type === type));
    if (index < 0) return { ok: false, reason: "recurso_invalido" };
    const [resource] = data.resources.splice(index, 1);
    data.hand.push({ instanceId: resource.instanceId, definitionId: resource.definitionId });
    player.resourceRemoved = true;
    this.syncResourceTotals(seat);
    this.updateCounts(seat);
    return { ok: true, details: { resourceId: resource.instanceId, resourceType: resource.type }, privateSeats: [seat] };
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

  private cardHasTag(card: PublicCardState, tag: string): boolean {
    const definition = CARD_DEFINITIONS[card.definitionId];
    const wanted = tag.toLocaleLowerCase("pt-BR");
    return Boolean(definition?.tags?.some((value) => value.toLocaleLowerCase("pt-BR") === wanted)
      || (definition?.name ?? card.name).toLocaleLowerCase("pt-BR").includes(wanted));
  }

  private synergyBonus(definition: CardDefinition | undefined, card: PublicCardState, field: "bonus_dano" | "bonus_defesa"): number {
    return definition?.synergies?.reduce((sum, synergy) =>
      sum + (this.cardHasTag(card, synergy.tag) ? (synergy[field] ?? 0) : 0), 0) ?? 0;
  }

  private equipmentAttackBonus(card: PublicCardState): number {
    return this.equipmentIds(card).reduce((sum, id) => {
      const definition = CARD_DEFINITIONS[id];
      return sum + (definition?.bonusAttack ?? 0) + this.synergyBonus(definition, card, "bonus_dano");
    }, 0);
  }

  private equipmentDefenseBonus(card: PublicCardState): number {
    return this.equipmentIds(card).reduce((sum, id) => {
      const definition = CARD_DEFINITIONS[id];
      return sum + (definition?.bonusDefense ?? 0) + this.synergyBonus(definition, card, "bonus_defesa");
    }, 0);
  }

  private effectiveAttackDie(card: PublicCardState, base: number): number {
    return this.equipmentIds(card).reduce((die, id) => CARD_DEFINITIONS[id]?.overrideAttackDie ?? die, base);
  }
  private applyCondition(card: PublicCardState, condition: string, turns: number, power: number, sourceSeat?: number, sourceCardId = ""): boolean {
    const state = this.abilityState(card);
    if (condition === "queimado" && (state.burnImmunity ?? 0) > 0) return false;
    if (condition === "sangrando") {
      if (card.condition && card.condition !== condition) return false;
      if (card.condition === condition) {
        if (state.bleedingWindow || state.bleedingHitThisCycle) card.conditionTurns += Math.max(1, turns);
        else card.conditionTurns = Math.max(1, card.conditionTurns);
        card.conditionPower = Math.max(card.conditionPower, power);
      } else {
        card.condition = condition;
        card.conditionTurns = state.bleedingWindow ? 2 : Math.max(1, turns);
        card.conditionPower = power;
      }
      state.bleedingWindow = true;
      state.bleedingHitThisCycle = true;
      this.setAbilityState(card, state);
      return true;
    }
    if (card.condition && card.condition !== condition) return false;
    card.condition = condition;
    card.conditionTurns = turns;
    card.conditionPower = power;
    if (condition === "loucura" && sourceSeat !== undefined && sourceSeat !== card.owner) {
      const mutualTrap = this.privatePlayers[card.owner]?.traps.find((trap) =>
        trap.definitionId === "loucura_mutua" && !trap.ready);
      if (mutualTrap) { mutualTrap.ready = true; mutualTrap.targetId = sourceCardId; }
    }
    return true;
  }

  private moveToDiscardOrAbyss(seat: number, card: PrivateCard) {
    const data = this.privatePlayers[seat];
    if (CARD_DEFINITIONS[card.definitionId]?.abyssSeal) data.abyss.push(card);
    else data.discard.push(card);
    this.updateCounts(seat);
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

  private applyDeclarativeEffects(seat: number, definition: CardDefinition, target?: PublicCardState): Record<string, unknown>[] {
    const events: Record<string, unknown>[] = [];
    for (const effect of definition.effects ?? []) {
      if (effect.tipo === "condicao" && target && this.state.cards.has(target.instanceId)) {
        const key = effect.chave ?? "";
        if (key === "choque" || key === "eletrocutado") {
          target.life -= 2;
          const coin = this.rollForSeat(seat, 2);
          if (target.life > 0) this.applyCondition(target, coin === 1 ? "paralisado" : "eletrocutado", 1, 0);
          else this.destroyPublicCard(target);
          events.push({ tipo: effect.tipo, chave: key, targetId: target.instanceId, dano: 2, coin });
          continue;
        }
        let condition = key;
        let turns = 1;
        let power = 0;
        if (key === "veneno") { condition = "envenenado"; turns = -1; power = 1; }
        else if (key === "queimado") { turns = 3; power = 2; }
        else if (key === "corrosao") { turns = 3; power = 3; }
        else if (key === "gelo") condition = "congelado";
        else if (key === "loucura") turns = -1;
        else if (key === "adormecer") { condition = "adormecido"; turns = -1; }
        else if (key === "sangrando") power = 3;
        else if (key === "apodrecer" || key === "regeneracao") {
          const roll = this.rollForSeat(seat, 4); turns = roll; power = roll;
        }
        const applied = this.applyCondition(target, condition, turns, power, seat);
        events.push({ tipo: effect.tipo, chave: condition, targetId: target.instanceId, applied, turns, power });
      } else if (effect.tipo === "dano" && target && this.state.cards.has(target.instanceId)) {
        const value = Math.max(0, Math.floor(effect.valor ?? 0));
        target.life -= value;
        const destroyed = target.life <= 0;
        if (destroyed) this.destroyPublicCard(target);
        events.push({ tipo: effect.tipo, targetId: target.instanceId, valor: value, destroyed });
      } else if (effect.tipo === "cura" && target && this.state.cards.has(target.instanceId)) {
        const before = target.life;
        target.life = Math.min(target.maxLife, target.life + Math.max(0, Math.floor(effect.valor ?? 0)));
        events.push({ tipo: effect.tipo, targetId: target.instanceId, valor: target.life - before });
      } else if (effect.tipo === "vida_maxima" && target && this.state.cards.has(target.instanceId)) {
        target.maxLife = Math.max(1, target.maxLife + Math.floor(effect.valor ?? 0));
        events.push({ tipo: effect.tipo, targetId: target.instanceId, valor: effect.valor ?? 0 });
      } else if (effect.tipo === "destruir" && target && this.state.cards.has(target.instanceId)
        && target.life <= (effect.limite_vida ?? Number.MAX_SAFE_INTEGER)) {
        this.destroyPublicCard(target);
        events.push({ tipo: effect.tipo, targetId: target.instanceId, destroyed: true });
      } else if (effect.tipo === "comprar") {
        const amount = Math.max(1, Math.floor(effect.quantidade ?? 1));
        this.drawCards(seat, amount);
        events.push({ tipo: effect.tipo, quantidade: amount });
      } else if (effect.tipo === "recurso" && RESOURCE_ORDER.includes(effect.chave as ResourceType)) {
        const data = this.privatePlayers[seat];
        const player = this.playerBySeat(seat)!;
        if (data.resources.length >= 6 || player.resourcePlaced) continue;
        const type = effect.chave as ResourceType;
        const amount = Math.max(1, Math.floor(effect.quantidade ?? 1));
        const card = this.makePrivateCard(seat, type);
        data.resources.push({ instanceId: card.instanceId, definitionId: card.definitionId, type, amount, used: false });
        player.resourcePlaced = true;
        this.syncResourceTotals(seat);
        events.push({ tipo: effect.tipo, chave: type, quantidade: amount });
      }
    }
    return events;
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
    const declarativeTarget = found.definition.target ?? "inimigo";
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
    } else if (found.definition.effects?.length) {
      if (declarativeTarget !== "nenhum" && (!target || target.category !== "tropa"))
        return { ok: false, reason: "alvo_invalido" };
      if (target && declarativeTarget === "aliado" && target.owner !== seat)
        return { ok: false, reason: "alvo_invalido" };
      if (target && declarativeTarget === "inimigo" && target.owner === seat)
        return { ok: false, reason: "alvo_invalido" };
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
    } else if (found.definition.effects?.length) {
      details = { ...details, declarativeEvents: this.applyDeclarativeEffects(seat, found.definition, target) };
    } else if (target) {
      if (effect === "veneno") this.applyCondition(target, "envenenado", -1, 1);
      if (effect === "gelo") this.applyCondition(target, "congelado", 1, 0);
      if (effect === "choque") {
        target.life -= 2;
        const coin = this.rollForSeat(seat, 2);
        const targetState = this.abilityState(target);
        targetState.electrocutions = (targetState.electrocutions ?? 0) + 1;
        targetState.electrocutedThisCycle = true;
        let madness = false;
        if (target.life > 0 && targetState.electrocutions >= 6) {
          target.condition = ""; target.conditionTurns = 0; target.conditionPower = 0;
          madness = this.applyCondition(target, "loucura", -1, 0, seat, found.card.instanceId);
          targetState.electrocutions = 0;
        } else if (target.life > 0) {
          this.applyCondition(target, coin === 1 ? "paralisado" : "eletrocutado", 1, 0);
        } else this.destroyPublicCard(target);
        this.setAbilityState(target, targetState);
        details = { ...details, targetId, damage: 2, coin, madness, condition: target.condition, destroyed: target.life <= 0 };
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
      const targetState = this.abilityState(target);
      if (["adormecido", "loucura"].includes(target.condition)) return { ok: false, reason: "tropa_incapacitada" };
      if (targetState.itemActionUsed) return { ok: false, reason: "acao_item_ja_usada" };
      const targetDefinition = CARD_DEFINITIONS[target.definitionId];
      if (equipment.length >= (targetDefinition.itemSlots ?? 0)) return { ok: false, reason: "mochila_cheia" };
      if (target.intelligence < (definition.intelligenceRequired ?? 0)) return { ok: false, reason: "inteligencia_insuficiente" };
      if (!this.payCost(player, definition)) return { ok: false, reason: "recursos_insuficientes" };
      equipment.push(found.card.definitionId);
      this.setEquipment(target, equipment);
      targetState.itemActionUsed = true;
      this.setAbilityState(target, targetState);
      this.removeHandCard(seat, found.index);
      details = { ...details, targetId, equipment };
    } else {
      if (definition.effects?.length) {
        const targetMode = definition.target ?? "inimigo";
        if (targetMode !== "nenhum" && (!target || target.category !== "tropa"))
          return { ok: false, reason: "alvo_item_invalido" };
        if (target && targetMode === "aliado" && target.owner !== seat)
          return { ok: false, reason: "alvo_item_invalido" };
        if (target && targetMode === "inimigo" && target.owner === seat)
          return { ok: false, reason: "alvo_item_invalido" };
      } else {
        if (target && target.category != "tropa") return { ok: false, reason: "alvo_item_invalido" };
        if ((effect === "cura" || effect === "aumentar_inteligencia" || effect === "aplicar_corrosao") && !target)
          return { ok: false, reason: "alvo_item_invalido" };
        if ((effect === "cura" || effect === "aumentar_inteligencia") && target?.owner !== seat)
          return { ok: false, reason: "alvo_item_invalido" };
        if (effect === "buscar_mana" && !this.privatePlayers[seat].deck.some((card) => CARD_DEFINITIONS[card.definitionId]?.resourceType === "mana"))
          return { ok: false, reason: "recurso_nao_encontrado" };
        if (effect === "revirar_sangue" && player.sangueUsed <= 0)
          return { ok: false, reason: "recurso_nao_gasto" };
      }
      if (!this.payCost(player, definition)) return { ok: false, reason: "recursos_insuficientes" };

      if (definition.effects?.length)
        details = { ...details, declarativeEvents: this.applyDeclarativeEffects(seat, definition, target) };
      else if (effect === "cura" && target) target.life = Math.min(target.maxLife, target.life + (definition.effectValue ?? 5));
      else if (effect === "comprar_cartas") this.drawCards(seat, 3);
      else if (effect === "buscar_mana") this.pullResourceFromDeck(seat, "mana");
      else if (effect === "revirar_sangue") {
        const spent = this.privatePlayers[seat].resources.find((resource) => resource.type === "sangue" && resource.used);
        if (spent) { spent.used = false; this.syncResourceTotals(seat); }
      }
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
        this.moveToDiscardOrAbyss(seat, { instanceId: trap.instanceId, definitionId: trap.definitionId });
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
      const damageEvents: Record<string, unknown>[] = [];
      this.state.cards.forEach((card: PublicCardState) => {
        if (card.category === "tropa" && card.owner !== seat && card.lane === trap.lane) {
          const roll = this.roll(4);
          rolls.push(roll);
          card.life -= roll;
          const destroyed = card.life <= 0;
          damageEvents.push({ cardId: card.instanceId, damage: roll, destroyed });
          if (destroyed) this.destroyPublicCard(card);
        }
      });
      details = { ...details, damageRolls: rolls, damageEvents };
    }

    data.traps.splice(index, 1);
    this.moveToDiscardOrAbyss(seat, { instanceId: trap.instanceId, definitionId: trap.definitionId });
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

    const effectOwnerSeat = found.definition.category === "maldicao" ? 1 - seat : seat;
    if (found.definition.category !== "terreno") {
      const activeEffects = this.privatePlayers[effectOwnerSeat].effects;
      const boardEffects = activeEffects.filter((effect) => !effect.startsWith("dados_manipulados:"));
      if (boardEffects.length >= 2) return { ok: false, reason: "limite_efeitos_ativos" };
    }
    if (!this.payCost(player, found.definition)) return { ok: false, reason: "recursos_insuficientes" };

    if (found.definition.category === "terreno") {
      const terrainCard = this.removeHandCard(seat, found.index);
      if (this.activeTerrain) this.moveToDiscardOrAbyss(this.activeTerrain.owner, this.activeTerrain.card);
      this.activeTerrain = { owner: seat, card: terrainCard };
      this.state.terrainDefinitionId = terrainCard.definitionId;
      player.terrainPlayed = true;
    } else {
      const effectKey = found.definition.effect ?? found.card.definitionId;
      this.privatePlayers[effectOwnerSeat].effects.push(effectKey);
      this.privatePlayers[effectOwnerSeat].effectCards.push({
        definitionId: found.card.definitionId,
        effect: effectKey,
        category: found.definition.category as "bencao" | "maldicao",
        name: found.definition.name,
      });
      this.discardPlayedCard(seat, found);
    }
    this.privatePlayers[seat].lastNonTroopDefinitionId = found.card.definitionId;
    return { ok: true, details: { cardId: found.card.instanceId, definitionId: found.card.definitionId,
      category: found.definition.category, targetSeat: effectOwnerSeat }, privateSeats: [seat, effectOwnerSeat] };
  }



  private removeItem(seat: number, payload: Record<string, unknown>): ActionResult {
    const cardId = typeof payload.cardId === "string" ? payload.cardId : "";
    const card = this.state.cards.get(cardId);
    if (!card || card.owner !== seat || card.category !== "tropa")
      return { ok: false, reason: "tropa_invalida" };
    const state = this.abilityState(card);
    if (["adormecido", "loucura"].includes(card.condition)) return { ok: false, reason: "tropa_incapacitada" };
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
    if (["adormecido", "loucura"].includes(from.condition) || ["adormecido", "loucura"].includes(to.condition))
      return { ok: false, reason: "tropa_incapacitada" };
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
    if (["paralisado", "adormecido", "loucura"].includes(card.condition))
      return { ok: false, reason: "tropa_incapacitada" };
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
    if (!this.spendResourceUnits(seat, "mana", 1)) return { ok: false, reason: "recursos_insuficientes" };
    state.grimoireUsed = true;
    let damage = 0;
    let roll = 0;
    if (spell === "raio" && target) {
      roll = this.rollForSeat(seat, 4);
      const targetDefinition = CARD_DEFINITIONS[target.definitionId];
      const targetState = this.abilityState(target);
      const defense = (targetDefinition.magicDefense ?? 0) + (targetState.grimoireShield ? 2 : 0) + this.terrainDefenseModifier(target);
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
    if (["paralisado", "adormecido", "loucura"].includes(card.condition))
      return { ok: false, reason: "tropa_incapacitada" };
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
      if (!this.spendResourceUnits(seat, "mana", 2)) return { ok: false, reason: "recursos_insuficientes" };
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
      this.applyCondition(card, "regeneracao", regeneration, regeneration);
      this.setAbilityState(card, state);
      return { ok: true, details: { ability, cardId, targetId: consumed?.instanceId ?? "", maxLife: card.maxLife, regeneration } };
    }

    if (ability === "carnica_frenetica") {
      if (state.frenzy) return { ok: false, reason: "carnica_preparada" };
      const player = this.playerBySeat(seat)!;
      if (player.blockedResource === "sangue" || player.sangue - player.sangueUsed < 2)
        return { ok: false, reason: "recursos_insuficientes" };
      if (!this.spendResourceUnits(seat, "sangue", 2)) return { ok: false, reason: "recursos_insuficientes" };
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
        this.moveToDiscardOrAbyss(1 - seat, discarded);
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
    const enemyBlood = this.privatePlayers[1 - seat].resources.find((resource) =>
      resource.type === "sangue" && !resource.used && !(enemy.blockedResource === "sangue" && enemy.blockedTurns > 0));
    if (!enemyBlood) return { ok: false, reason: "hemodrenario_sem_sangue" };
    const spent = this.privatePlayers[seat].resources.find((resource) =>
      resource.used && !(owner.blockedResource === resource.type && owner.blockedTurns > 0));
    if (!spent) return { ok: false, reason: "hemodrenario_sem_recurso_gasto" };
    enemyBlood.used = true;
    spent.used = false;
    this.syncResourceTotals(1 - seat);
    this.syncResourceTotals(seat);
    state.used = true;
    this.setAbilityState(card, state);
    return { ok: true, details: { cardId, ability: "hemodrenario", restoredResource: spent.type } };
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
    if (card.turnsInPlay < 1) return { ok: false, reason: "tropa_recem_colocada" };
    if (["paralisado", "congelado", "adormecido", "loucura"].includes(card.condition)) return { ok: false, reason: "tropa_incapacitada" };
    const rootTrap = this.privatePlayers[1 - seat].traps.find((trap) => trap.definitionId === "raizes_espinhosas"
      && !trap.ready && trap.lane === card.lane && trap.position === card.position);
    if (rootTrap && card.life < 10 && !this.hasAbility(card, "voar")) {
      rootTrap.ready = true; rootTrap.targetId = card.instanceId; card.moved = true;
      return { ok: true, details: { cardId, trapReady: true, movementPrevented: true } };
    }

    const advanceDelta = seat === 0 ? -1 : 1;
    const movementDelta = direction === "advance" ? advanceDelta : -advanceDelta;
    let destination = card.position + movementDelta;
    if (destination < 0 || destination > 4) return { ok: false, reason: "movimento_fora_tabuleiro" };
    const occupant = this.findPublic((other) => other.category === "tropa"
      && other.lane === card.lane && other.position === destination);
    if (occupant) {
      if (occupant.owner === seat) return { ok: false, reason: "casa_ocupada" };
      if (!this.hasAbility(card, "voar") || this.hasAbility(occupant, "voar"))
        return { ok: false, reason: "casa_ocupada" };
      const landing = destination + movementDelta;
      const assault = seat === 0 ? 1 : 3;
      const passedAssault = seat === 0 ? landing < assault : landing > assault;
      const landingOccupied = this.findPublic((other) => other.category === "tropa"
        && other.lane === card.lane && other.position === landing);
      if (landing < 0 || landing > 4 || passedAssault || landingOccupied)
        return { ok: false, reason: "casa_ocupada" };
      destination = landing;
    }

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
    if (["adormecido", "loucura"].includes(card.condition)) return { ok: false, reason: "tropa_incapacitada" };
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
    if (["adormecido", "loucura"].includes(card.condition)) return { ok: false, reason: "tropa_incapacitada" };
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
    if (this.replayingManipulated) return;
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
      if (itemIndex !== index) this.moveToDiscardOrAbyss(seat, this.makePrivateCard(seat, definitionId));
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
    const childDefinition = CARD_DEFINITIONS[pending.source.definitionId];
    if (!childDefinition) return { ok: false, reason: "escolha_mitose_invalida" };
    const child = this.createPublicCard(pending.source, childDefinition, seat, lane, position);
    child.moved = true;
    this.state.cards.set(child.instanceId, child);
    this.pendingMitosis[seat] = undefined;
    return { ok: true, details: this.publicCardPayload(child) };
  }

  private counterAttack(defender: PublicCardState, attacker: PublicCardState): Record<string, unknown> {
    const definition = CARD_DEFINITIONS[defender.definitionId];
    if (!definition.attackDie || definition.attackDie <= 0) return { cardId: defender.instanceId, targetId: attacker.instanceId, counterAttack: true, unavailable: true, damage: 0 };
    const damageMultiplier = defender.condition === "berserker" ? 2 : 1;
    const die = this.effectiveAttackDie(defender, Math.max(1, definition.attackDie ?? 1));
    const dice = Math.max(1, definition.attackDice ?? 1);
    const damageRolls = Array.from({ length: dice }, () => this.rollForSeat(defender.owner, die));
    const modifier = (definition.attackModifier ?? 0) + this.equipmentAttackBonus(defender) + this.cemeteryBonus(defender);
    const defense = (CARD_DEFINITIONS[attacker.definitionId]?.physicalDefense ?? 0) + this.equipmentDefenseBonus(attacker) + this.terrainDefenseModifier(attacker) + (attacker.condition === "berserker" ? 4 : 0);
    const damage = Math.max(0, damageRolls.reduce((sum, value) => sum + value, 0) * damageMultiplier + modifier - defense);
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
    let modifier = usingWeapon
      ? (weaponDefinition!.attackModifier ?? 0) + this.synergyBonus(weaponDefinition, attacker, "bonus_dano")
      : (attackType === "magica" ? definition.magicModifier ?? 0 : definition.attackModifier ?? 0)
        + (attackType === "fisica" ? this.equipmentAttackBonus(attacker) : 0);
    modifier += this.cemeteryBonus(attacker);
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
        if (attacker.life <= 0) this.destroyPublicCard(attacker, false);
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
    if (!target) {
      attacker.attacked = true;
      const damageMultiplier = attacker.condition === "berserker" ? 2 : 1;
      const damageRolls = Array.from({ length: dice }, () => this.rollForSeat(seat, die));
      const damage = Math.max(0, damageRolls.reduce((sum, value) => sum + value, 0) * damageMultiplier + modifier);
      const defender = this.playerBySeat(1 - seat)!;
      defender.life = Math.max(0, defender.life - damage);
      if (defender.life <= 0) { this.state.winner = seat; this.state.phase = "finished"; }
      return { ok: true, details: { cardId, target: "castle", attackType, direct: true, hit: true, damageRolls, modifier, damage, defenderLife: defender.life, itemDefinitionId, frenzyBonus } };
    }

    const madnessState = target?.category === "tropa" ? this.abilityState(target) : undefined;
    const madnessNoDefense = madnessState?.madnessNoDefense === true;
    if (madnessState && madnessNoDefense) {
      madnessState.madnessNoDefense = false;
      this.setAbilityState(target!, madnessState);
    }
    const accuracyRolls = madnessNoDefense ? [] : (attacker.condition === "berserker" || attacker.condition === "confusao")
      ? [this.rollForSeat(seat, 20), this.rollForSeat(seat, 20)] : [this.rollForSeat(seat, 20)];
    const accuracyRoll = madnessNoDefense ? 11 : attacker.condition === "berserker"
      ? Math.max(...accuracyRolls) : attacker.condition === "confusao"
        ? Math.min(...accuracyRolls) : accuracyRolls[0];
    const damageMultiplier = attacker.condition === "berserker" ? 2 : 1;
    const accuracy = accuracyRoll + this.cemeteryBonus(attacker);
    attacker.attacked = true;
    if (accuracyRoll === 20 && this.hasAbility(attacker, "tiro_burro")) {
      const candidates: PublicCardState[] = [];
      this.state.cards.forEach((other: PublicCardState) => {
        if (other.category === "tropa") candidates.push(other);
      });
      if (candidates.length > 0) target = candidates[this.roll(candidates.length) - 1];
    }
    if (target) {
      if (accuracy <= 10) {
        const counter = (accuracyRoll === 1 || attacker.condition === "confusao") && target.category === "tropa"
          ? this.counterAttack(target, attacker) : undefined;
        return { ok: true, details: { cardId, targetId: target.instanceId, attackType, accuracy, accuracyRoll, accuracyRolls, hit: false, damageRolls: [], itemDefinitionId, stealRoll, stolenItem, counter } };
      }
      const targetDefinition = CARD_DEFINITIONS[target.definitionId];
      const targetState = this.abilityState(target);
      const defense = (ignoreDefense || madnessNoDefense) ? 0 : (attackType === "magica"
        ? (targetDefinition.magicDefense ?? 0) + (targetState.grimoireShield ? 2 : 0) + this.terrainDefenseModifier(target)
        : (targetDefinition.physicalDefense ?? 0) + this.equipmentDefenseBonus(target) + this.terrainDefenseModifier(target) + (target.condition === "berserker" ? 4 : 0));
      if (accuracyRoll === 20) {
        this.pendingCritical = { seat, cardId, targetId: target.instanceId, targetType: "card", attackType, die, dice, modifier, defense, itemDefinitionId, damageMultiplier };
        return { ok: true, details: { cardId, targetId: target.instanceId, attackType, accuracy, accuracyRoll, accuracyRolls, hit: true, critical: true, criticalChoice: true, die, dice, itemDefinitionId, stealRoll, stolenItem } };
      }
      const damageRolls = Array.from({ length: dice }, () => this.rollForSeat(seat, die));
      const damage = Math.max(0, damageRolls.reduce((sum, value) => sum + value, 0) * damageMultiplier + modifier - defense);
      target.life -= damage;
      const destroyed = target.life <= 0;
      if (destroyed) {
        if (this.hasAbility(attacker, "digestao")) {
          attackerState.corpseAvailable = true;
          this.setAbilityState(attacker, attackerState);
        }
        this.destroyPublicCard(target);
      }
      return { ok: true, details: { cardId, targetId: target.instanceId, attackType, accuracy, accuracyRoll, accuracyRolls, hit: true, critical: false, damageRolls, modifier, defense, damage, destroyed, frenzyBonus, itemDefinitionId, stealRoll, stolenItem, madnessNoDefense } };
    }
    return { ok: false, reason: "alvo_invalido" };
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
    const original = (choice === "dobrar_resultado" ? rolled * 2 : rolled) * pending.damageMultiplier;
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
      const chainedCritical = this.pendingCritical as unknown as { repeatAfter?: number; damageMultiplier: number } | undefined;
      if (chainedCritical) chainedCritical.repeatAfter = repeatAfter - 1;
      attacker.attacked = true;
    }
    return { ok: true, details: { cardId: pending.cardId, targetId: pending.targetId ?? "", target: pending.targetType === "castle" ? "castle" : "card", attackType: pending.attackType, criticalResolved: true, critical: true, choice, damageRolls, modifier: pending.modifier, defense: pending.defense, damage, destroyed, defenderLife, itemDefinitionId: pending.itemDefinitionId ?? "", followUp, criticalChoice: Boolean(this.pendingCritical) } };
  }
  private processMadness(seat: number): Record<string, unknown>[] {
    const events: Record<string, unknown>[] = [];
    const cards: PublicCardState[] = [];
    this.state.cards.forEach((card: PublicCardState) => {
      if (card.owner === seat && card.category === "tropa" && card.condition === "loucura") cards.push(card);
    });
    for (const card of cards) {
      if (!this.state.cards.has(card.instanceId)) continue;
      const definition = CARD_DEFINITIONS[card.definitionId];
      const state = this.abilityState(card);
      state.madnessNoDefense = false;
      state.used = true;
      card.attacked = true;
      card.moved = true;
      const result = this.rollForSeat(seat, 4);
      const useMagic = !(definition.attackDie && definition.attackDie > 0) && Boolean(definition.magicDie && definition.magicDie > 0);
      const die = Math.max(1, useMagic ? definition.magicDie ?? 1 : definition.attackDie ?? 1);
      const dice = Math.max(1, useMagic ? definition.magicDice ?? 1 : definition.attackDice ?? 1);
      const modifier = useMagic ? definition.magicModifier ?? 0 : definition.attackModifier ?? 0;
      const event: Record<string, unknown> = { cardId: card.instanceId, seat, result, die, attackType: useMagic ? "magica" : "fisica" };
      if (result === 1) {
        const damageRolls = Array.from({ length: dice }, () => this.rollForSeat(seat, die));
        const damage = Math.max(0, damageRolls.reduce((sum, value) => sum + value, 0) + modifier);
        card.life -= damage;
        Object.assign(event, { kind: "self", targetId: card.instanceId, damageRolls, damage, destroyed: card.life <= 0 });
        if (card.life <= 0) this.destroyPublicCard(card, false);
      } else if (result === 2) {
        const allies: PublicCardState[] = [];
        this.state.cards.forEach((other: PublicCardState) => {
          if (other.instanceId !== card.instanceId && other.category === "tropa" && other.owner === seat
            && other.lane === card.lane && Math.abs(other.position - card.position) === 1) allies.push(other);
        });
        if (allies.length > 0) {
          const target = allies[this.roll(allies.length) - 1];
          const targetDefinition = CARD_DEFINITIONS[target.definitionId];
          const targetState = this.abilityState(target);
          const defense = useMagic
            ? (targetDefinition.magicDefense ?? 0) + (targetState.grimoireShield ? 2 : 0) + this.terrainDefenseModifier(target)
            : (targetDefinition.physicalDefense ?? 0) + this.equipmentDefenseBonus(target) + this.terrainDefenseModifier(target) + (target.condition === "berserker" ? 4 : 0);
          const damageRolls = Array.from({ length: dice }, () => this.rollForSeat(seat, die));
          const damage = Math.max(0, damageRolls.reduce((sum, value) => sum + value, 0) + modifier - defense);
          target.life -= damage;
          Object.assign(event, { kind: "ally", targetId: target.instanceId, damageRolls, defense, damage, destroyed: target.life <= 0 });
          if (target.life <= 0) this.destroyPublicCard(target, false);
        } else Object.assign(event, { kind: "ally", noTarget: true });
      } else if (result === 3) {
        const entry = seat === 0 ? 4 : 0;
        if (card.position === entry) {
          const damageRolls = Array.from({ length: dice }, () => this.rollForSeat(seat, die));
          const damage = Math.max(0, damageRolls.reduce((sum, value) => sum + value, 0) + modifier);
          const owner = this.playerBySeat(seat)!;
          owner.life = Math.max(0, owner.life - damage);
          if (owner.life <= 0) { this.state.winner = 1 - seat; this.state.phase = "finished"; }
          Object.assign(event, { kind: "castle", damageRolls, damage });
        } else {
          const destination = card.position + (seat === 0 ? 1 : -1);
          const occupied = this.findPublic((other) => other.category === "tropa" && other.lane === card.lane && other.position === destination);
          const moved = destination >= 0 && destination <= 4 && !occupied;
          if (moved) card.position = destination;
          Object.assign(event, { kind: "retreat", moved, position: card.position });
        }
      } else {
        state.madnessNoDefense = true;
        Object.assign(event, { kind: "no_defense" });
      }
      if (this.state.cards.has(card.instanceId)) this.setAbilityState(card, state);
      events.push(event);
    }
    return events;
  }

  private processSleep(seat: number): Record<string, unknown>[] {
    const events: Record<string, unknown>[] = [];
    this.state.cards.forEach((card: PublicCardState) => {
      if (card.owner !== seat || card.category !== "tropa" || card.condition !== "adormecido") return;
      const coin = this.rollForSeat(seat, 2);
      const woke = coin === 1;
      if (woke) {
        card.condition = "";
        card.conditionTurns = 0;
        card.conditionPower = 0;
      }
      events.push({ cardId: card.instanceId, coin, woke });
    });
    return events;
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
      }
      if (!ability.electrocutedThisCycle) ability.electrocutions = 0;
      ability.electrocutedThisCycle = false;
      if ((ability.burnImmunity ?? 0) > 0) ability.burnImmunity = Math.max(0, (ability.burnImmunity ?? 0) - 1);
      ability.bleedingWindow = Boolean(ability.bleedingHitThisCycle);
      ability.bleedingHitThisCycle = false;
      if (card.conditionTurns > 0) {
        card.conditionTurns -= 1;
        if (card.conditionTurns <= 0) {
          if (card.condition === "queimado") ability.burnImmunity = 1;
          card.condition = "";
          card.conditionPower = 0;
        }
      }
      this.setAbilityState(card, ability);
    });

    // Processa dano e cura persistentes no início do turno do próximo jogador.
    const defeated: PublicCardState[] = [];
    const conditionEvents: Record<string, unknown>[] = [];
    this.state.cards.forEach((card: PublicCardState) => {
      if (card.owner !== nextSeat || card.category !== "tropa") return;
      if (["queimado", "envenenado", "corrosao", "sangrando", "apodrecer"].includes(card.condition)) {
        const amount = Math.max(0, card.conditionPower);
        card.life -= amount;
        if (amount > 0) conditionEvents.push({ cardId: card.instanceId, condition: card.condition, kind: "damage", amount });
        if (card.condition === "corrosao" && card.conditionPower > 1) card.conditionPower -= 1;
      } else if (card.condition === "regeneracao") {
        const lifeBefore = card.life;
        card.life = Math.min(card.maxLife, card.life + Math.max(0, card.conditionPower));
        const amount = Math.max(0, card.life - lifeBefore);
        if (amount > 0) conditionEvents.push({ cardId: card.instanceId, condition: card.condition, kind: "heal", amount });
      }
      if (card.life <= 0) defeated.push(card);
    });
    for (const card of defeated) this.destroyPublicCard(card, false);
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
    const sleepEvents = this.processSleep(nextSeat);
    const madnessEvents = this.processMadness(nextSeat);
    const artillery = this.processArtillery(nextSeat);
    this.drawCards(nextSeat, 1);
    return {
      ok: true,
      details: { currentPlayer: nextSeat, turnNumber: this.state.turnNumber, conditionEvents, sleepEvents, madnessEvents, artillery },
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

  private isUndead(card: PublicCardState): boolean {
    return ["morto-vivo", "zumbi", "esqueleto", "fantasma", "espirito", "espírito"]
      .some((tag) => this.cardHasTag(card, tag));
  }

  private cemeteryBonus(card: PublicCardState): number {
    return this.state.terrainDefinitionId === "cemiterio" && this.isUndead(card) ? 1 : 0;
  }

  private terrainDefenseModifier(card: PublicCardState): number {
    return this.cemeteryBonus(card) + (this.state.terrainDefinitionId === "pantano_sombrio" ? -1 : 0);
  }

  private adjustedCost(definition: CardDefinition): CostPart[] {
    let manaDiscount = definition.category === "tropa" && this.state.terrainDefinitionId === "planicies_profanas" ? 1 : 0;
    return definition.cost.flatMap((part) => {
      if (part.type !== "mana" || manaDiscount <= 0) return [{ ...part }];
      const amount = Math.max(0, part.amount - manaDiscount);
      manaDiscount = Math.max(0, manaDiscount - part.amount);
      return amount > 0 ? [{ ...part, amount }] : [];
    });
  }

  private syncResourceTotals(seat: number) {
    const player = this.playerBySeat(seat);
    const data = this.privatePlayers[seat];
    if (!player || !data) return;
    for (const type of RESOURCE_ORDER) {
      player[RESOURCE_FIELDS[type]] = data.resources
        .filter((resource) => resource.type === type).reduce((sum, resource) => sum + resource.amount, 0);
      player[USED_FIELDS[type]] = data.resources
        .filter((resource) => resource.type === type && resource.used).reduce((sum, resource) => sum + resource.amount, 0);
    }
  }

  private spendResourceUnits(seat: number, type: ResourceType, amount: number): boolean {
    const player = this.playerBySeat(seat)!;
    if (player.blockedResource === type && player.blockedTurns > 0) return false;
    const candidates = this.privatePlayers[seat].resources.filter((resource) => resource.type === type && !resource.used);
    if (candidates.reduce((sum, resource) => sum + resource.amount, 0) < amount) return false;
    let remaining = amount;
    for (const resource of candidates) {
      resource.used = true;
      remaining -= resource.amount;
      if (remaining <= 0) break;
    }
    this.syncResourceTotals(seat);
    return true;
  }

  private payCost(player: PlayerState, definition: CardDefinition): boolean {
    const seat = player.seatIndex;
    const resources = this.privatePlayers[seat].resources;
    const selected = new Set<string>();
    const take = (type: ResourceType | "qualquer", amount: number) => {
      let remaining = amount;
      for (const resource of resources) {
        if (resource.used || selected.has(resource.instanceId)) continue;
        if (type !== "qualquer" && resource.type !== type) continue;
        if (player.blockedResource === resource.type && player.blockedTurns > 0) continue;
        selected.add(resource.instanceId);
        remaining -= resource.amount;
        if (remaining <= 0) return true;
      }
      return remaining <= 0;
    };
    const cost = this.adjustedCost(definition);
    for (const part of cost.filter((item) => item.type !== "qualquer"))
      if (!take(part.type, part.amount)) return false;
    const wildcard = cost.filter((item) => item.type === "qualquer").reduce((sum, item) => sum + item.amount, 0);
    if (wildcard > 0 && !take("qualquer", wildcard)) return false;
    for (const resource of resources) if (selected.has(resource.instanceId)) resource.used = true;
    this.syncResourceTotals(seat);
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

  private destroyPublicCard(card: PublicCardState, causedByOpponent = true) {
    if (!this.state.cards.has(card.instanceId)) return;
    this.state.cards.delete(card.instanceId);
    const privatePlayer = this.privatePlayers[card.owner];
    this.moveToDiscardOrAbyss(card.owner, { instanceId: card.instanceId, definitionId: card.definitionId });
    const equipment = this.equipmentIds(card);
    const magnet = this.findPublic((other) => other.category === "construcao"
      && other.owner === card.owner && other.lane === card.lane
      && CARD_DEFINITIONS[other.definitionId]?.effect === "maquina_ima");
    if (card.category === "tropa" && magnet && equipment.length > 0) {
      this.pendingMagnet[card.owner].push({ sourceCardId: magnet.instanceId, equipment: [...equipment] });
      if (this.pendingMagnet[card.owner].length === 1) this.sendNextMagnetChoice(card.owner);
    } else {
      equipment.forEach((definitionId, index) =>
        this.moveToDiscardOrAbyss(card.owner, { instanceId: card.instanceId + "-item-" + index, definitionId }));
    }
    if (card.category === "tropa") {
      const owner = this.playerBySeat(card.owner);
      const healingEffects = privatePlayer.effects.filter((effect) => effect === "cura_ao_morrer").length;
      if (healingEffects > 0 && owner) {
        const lifeBefore = owner.life;
        owner.life = Math.min(20, owner.life + healingEffects);
        const amount = owner.life - lifeBefore;
        if (amount > 0) this.actionPassiveEvents.push({ kind: "blessing_heal", seat: card.owner, cardId: card.instanceId, amount });
      }
      const damagingEffects = privatePlayer.effects.filter((effect) => effect === "perde_vida_ao_morrer").length;
      if (causedByOpponent && damagingEffects > 0 && owner) {
        const lifeBefore = owner.life;
        owner.life = Math.max(0, owner.life - damagingEffects);
        const amount = lifeBefore - owner.life;
        if (amount > 0) this.actionPassiveEvents.push({ kind: "curse_damage", seat: card.owner, cardId: card.instanceId, amount });
        if (owner.life <= 0) { this.state.winner = 1 - card.owner; this.state.phase = "finished"; }
      }
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
    const childDefinitionId = CARD_DEFINITIONS[parent.definitionId]?.mitosisChild;
    const childDefinition = childDefinitionId ? CARD_DEFINITIONS[childDefinitionId] : undefined;
    if (!childDefinitionId || !childDefinition) return;
    const first = this.takeDefinitionFromHandOrDeck(parent.owner, childDefinitionId);
    if (!first) return;
    const spawn = (source: PrivateCard, lane: number, position: number) => {
      const child = this.createPublicCard(source, childDefinition, parent.owner, lane, position);
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
    const second = this.takeDefinitionFromHandOrDeck(parent.owner, childDefinitionId);
    if (!second) return;
    this.pendingMitosis[parent.owner] = { source: second, owner: parent.owner, candidates };
    const client = this.clientBySeat(parent.owner);
    if (client && !this.replayingManipulated) this.sendJson(client, "mitosis_choice", { sourceCardId: parent.instanceId, candidates: candidates.map(([lane, position]) => ({ lane, position })) });
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
    this.moveToDiscardOrAbyss(seat, card);
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
      activeEffects: [
        ...data.effectCards,
        ...data.effects.filter((effect) => effect.startsWith("dados_manipulados:")),
      ],
      abyss: data.abyss.map((card) => card.definitionId),
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
      blockedResource: player.blockedResource, blockedTurns: player.blockedTurns, hasTakenTurn: player.hasTakenTurn, initialHandDrawn: player.initialHandDrawn,
      activeEffects: this.privatePlayers[player.seatIndex]
        ? [
          ...this.privatePlayers[player.seatIndex].effectCards,
          ...this.privatePlayers[player.seatIndex].effects.filter((effect) => effect.startsWith("dados_manipulados:")),
        ]
        : [],
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
    const cemetery = this.privatePlayers.map((data) => (data?.discard ?? [])
      .filter((card) => CARD_DEFINITIONS[card.definitionId]?.category === "tropa")
      .map((card) => CARD_DEFINITIONS[card.definitionId]?.name ?? "Tropa"));
    const abyss = this.privatePlayers.map((data) => (data?.abyss ?? [])
      .map((card) => CARD_DEFINITIONS[card.definitionId]?.name ?? "Carta"));
    const resources = this.privatePlayers.flatMap((data, owner) => (data?.resources ?? []).map((resource) => ({
      ...resource, owner,
    })));
    const payload = {
      phase: this.state.phase, currentPlayer: this.state.currentPlayer,
      winner: this.state.winner, revision: this.state.revision,
      turnNumber: this.state.turnNumber,
      terrainDefinitionId: this.state.terrainDefinitionId,
      discardCounts: [this.state.discardCount0, this.state.discardCount1],
      cemetery, abyss, resources,
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
    const data = this.privatePlayers[player.seatIndex];
    if (data?.resources) {
      for (const resource of data.resources) resource.used = false;
      this.syncResourceTotals(player.seatIndex);
    } else {
      player.manaUsed = 0; player.sangueUsed = 0; player.ossosUsed = 0; player.sucataUsed = 0;
    }
    player.resourcePlaced = false;
    player.resourceRemoved = false;
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
    const replay = this.manipulatedReplay;
    let rolled: number;
    if (replay) {
      const saved = replay.rolls[replay.rollCursor];
      if (saved) {
        if (saved.sides !== sides) throw new Error("sequencia_de_dados_inconsistente");
        rolled = saved.value;
      } else {
        rolled = this.roll(sides);
        replay.rolls.push({ sides, value: rolled });
      }
      replay.rollCursor += 1;
    } else rolled = this.roll(sides);

    const data = this.privatePlayers[seat];
    if (!data) return rolled;
    const index = data.effects.findIndex((value) => value.startsWith("dados_manipulados:"));
    if (index < 0) return rolled;
    const parts = data.effects[index].split(":");
    const fixed = Number(parts[1]);
    const remaining = Number(parts[2]);
    if (!Number.isInteger(fixed) || fixed <= 0 || fixed > sides || remaining <= 0) return rolled;

    let useAlternative = fixed > rolled;
    if (replay) {
      const decision = replay.decisions[replay.cursor];
      if (!decision) throw { manipulatedRoll: true, seat, natural: rolled, fixed, sides };
      if (decision.seat !== seat || decision.natural !== rolled || decision.fixed !== fixed || decision.sides !== sides)
        throw new Error("escolha_de_dado_inconsistente");
      replay.cursor += 1;
      useAlternative = decision.useAlternative;
    }
    if (remaining <= 1) data.effects.splice(index, 1);
    else data.effects[index] = "dados_manipulados:" + fixed + ":" + (remaining - 1);
    return useAlternative ? fixed : rolled;
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
    this.broadcastJson("initiative_started", { revision: this.state.revision });
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
    this.broadcastJson("initiative_finished", { winner: winner.seatIndex, revision: this.state.revision });
    this.sendPublicState();
  }

  private reject(client: Client, reason: string) {
    this.sendJson(client, "action_rejected", { reason, revision: this.state.revision });
  }

  private bump(action: string) {
    this.state.revision += 1;
    this.state.lastAction = action;
  }
}
