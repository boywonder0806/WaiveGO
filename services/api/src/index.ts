import cors from "cors";
import express from "express";
import { config } from "./config";
import { checkinRouter } from "./routes/checkin";
import { guestsRouter } from "./routes/guests";
import { healthRouter } from "./routes/health";
import { webhooksRouter } from "./routes/webhooks";

const app = express();

app.use(cors());
app.use(express.json()); // for the webhook route's JSON body — photo routes use multipart, not this

app.use(healthRouter);
app.use(checkinRouter);
app.use(guestsRouter);
app.use(webhooksRouter);

app.listen(config.port, () => {
  console.log(`WaiveGO API listening on port ${config.port}`);
});
