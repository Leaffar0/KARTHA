import { Room, Client } from "@colyseus/core";
import { KarthaRoomState, PlayerSchema } from "./schema/UnoRoomState.ts";

type RoomState = InstanceType<typeof KarthaRoomState>;
type PlayerState = InstanceType<typeof PlayerSchema>;

const ACTIONS = new Set([
  "play_card", "place_resource", "move_troop", "attack",
  "use_ability", "choose_effect", "discard_card", "end_turn",
]);

function safeName(value: unknown): string {
  const name = typeof value === "string" ? value.trim() : "";
  return (name || "Jogador").slice(0, 24);
}

export class KarthaRoom extends Room<{ state: RoomState }> {
  onCreate() {
    this.maxClients = 2;
    this.setState(new KarthaRoomState());
    this.state.phase = "waiting";
    this.state.currentPlayer = -1;
    this.state.initiativeWinner = -1;
    this.state.winner = -1;
    this.state.revision = 0;
    this.state.seed = Math.floor(Math.random() * 2147483646) + 1;
    this.state.lastAction = "";

    this.onMessage("ready", (client: Client, message: { name?: string }) => {
      const player = this.findPlayer(client.sessionId);
      if (!player || this.state.phase !== "waiting") return;
      player.name = safeName(message?.name);
      player.ready = true;
      this.startInitiativeWhenReady();
    });

    this.onMessage("roll_initiative", (client: Client) => {
      const player = this.findPlayer(client.sessionId);
      if (!player || this.state.phase !== "initiative" || player.initiative > 0) return;
      player.initiative = Math.floor(Math.random() * 20) + 1;
      this.broadcast("initiative_result", {
        seat: player.seatIndex,
        value: player.initiative,
      });
      this.finishInitiativeIfReady();
    });

    this.onMessage("choose_first", (client: Client, message: { seat?: number }) => {
      const player = this.findPlayer(client.sessionId);
      const seat = Number(message?.seat);
      if (!player || this.state.phase !== "choose_first") return;
      if (player.seatIndex !== this.state.initiativeWinner) return;
      if (seat !== 0 && seat !== 1) return;
      this.state.currentPlayer = seat;
      this.state.phase = "playing";
      this.bump("match_started");
      this.broadcast("match_started", {
        currentPlayer: seat,
        seed: this.state.seed,
      });
    });

    this.onMessage("action", (client: Client, message: { kind?: string; payload?: unknown; revision?: number }) => {
      const player = this.findPlayer(client.sessionId);
      const kind = typeof message?.kind === "string" ? message.kind : "";
      if (!player || this.state.phase !== "playing" || player.seatIndex !== this.state.currentPlayer) return;
      if (!ACTIONS.has(kind)) return;
      if (Number(message?.revision) !== this.state.revision) {
        client.send("action_rejected", { reason: "revision", revision: this.state.revision });
        return;
      }

      this.state.revision += 1;
      this.state.lastAction = kind;
      this.broadcast("action_confirmed", {
        revision: this.state.revision,
        seat: player.seatIndex,
        kind,
        payload: message?.payload ?? {},
      });

      if (kind === "end_turn") {
        this.state.currentPlayer = player.seatIndex === 0 ? 1 : 0;
      }
    });

    this.onMessage("concede", (client: Client) => {
      const player = this.findPlayer(client.sessionId);
      if (!player || this.state.phase === "finished") return;
      this.state.winner = player.seatIndex === 0 ? 1 : 0;
      this.state.phase = "finished";
      this.bump("concede");
    });
  }

  onJoin(client: Client, options: { name?: string }) {
    const player = new PlayerSchema();
    player.sessionId = client.sessionId;
    player.seatIndex = this.nextSeat();
    player.name = safeName(options?.name);
    player.connected = true;
    player.ready = false;
    player.life = 20;
    player.handCount = 0;
    player.initiative = 0;
    this.state.players.set(client.sessionId, player);
    this.setMetadata({ players: this.clients.length, phase: this.state.phase });
    client.send("seat", {
      seat: player.seatIndex,
      roomId: this.roomId,
      seed: this.state.seed,
    });
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
    } catch {
      this.state.winner = player.seatIndex === 0 ? 1 : 0;
      this.state.phase = "finished";
      this.bump("disconnect");
    }
  }

  private nextSeat(): number {
    let used0 = false;
    this.state.players.forEach((player: PlayerState) => {
      if (player.seatIndex === 0) used0 = true;
    });
    return used0 ? 1 : 0;
  }

  private findPlayer(sessionId: string): PlayerState | undefined {
    return this.state.players.get(sessionId);
  }

  private startInitiativeWhenReady() {
    if (this.clients.length !== 2 || this.state.players.size !== 2) return;
    let allReady = true;
    this.state.players.forEach((player: PlayerState) => {
      if (!player.ready) allReady = false;
    });
    if (!allReady) return;
    this.state.phase = "initiative";
    this.bump("initiative_started");
  }

  private finishInitiativeIfReady() {
    const players: PlayerState[] = [];
    this.state.players.forEach((player: PlayerState) => players.push(player));
    if (players.length !== 2 || players.some((player) => player.initiative <= 0)) return;

    if (players[0].initiative === players[1].initiative) {
      players.forEach((player) => player.initiative = 0);
      this.bump("initiative_tie");
      this.broadcast("initiative_tie", {});
      return;
    }

    const winner = players[0].initiative > players[1].initiative ? players[0] : players[1];
    this.state.initiativeWinner = winner.seatIndex;
    this.state.phase = "choose_first";
    this.bump("initiative_finished");
  }

  private bump(action: string) {
    this.state.revision += 1;
    this.state.lastAction = action;
  }
}
