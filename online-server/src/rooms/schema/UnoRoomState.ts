import { schema, t } from "@colyseus/schema";

export const PlayerSchema = schema({
  sessionId: t.string(),
  seatIndex: t.number(),
  name: t.string(),
  connected: t.boolean(),
  ready: t.boolean(),
  life: t.number(),
  handCount: t.number(),
  initiative: t.number(),
});

export const KarthaRoomState = schema({
  players: t.map(PlayerSchema),
  phase: t.string(),
  currentPlayer: t.number(),
  initiativeWinner: t.number(),
  winner: t.number(),
  revision: t.number(),
  seed: t.number(),
  lastAction: t.string(),
});
