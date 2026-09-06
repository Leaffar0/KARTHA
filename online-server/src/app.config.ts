import express from "express";
import { createServer } from "node:http";
import { defineServer, defineRoom } from "@colyseus/core";
import { WebSocketTransport } from "@colyseus/ws-transport";
import { KarthaRoom } from "./rooms/UnoRoom.ts";

const app = express();
app.get("/health", (_req, res) => res.json({ ok: true, game: "KARTHA" }));
const httpServer = createServer(app);

export default defineServer({
  rooms: {
    kartha: defineRoom(KarthaRoom),
  },
  transport: new WebSocketTransport({
    server: httpServer,
    pingInterval: 3000,
    pingMaxRetries: 4,
    maxPayload: 64 * 1024,
  }),
});
