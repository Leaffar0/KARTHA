import appConfig from "./app.config.ts";

const port = Number(process.env.PORT || 2567);
await appConfig.listen(port);
console.log("KARTHA online em http://localhost:" + port);
