## 1.0.0

First stable release: a modern, null-safe Dart 3 SDK for the Sarufi
Conversational AI platform (`developers.sarufi.io`).

### Features
* API-key authentication (`Sarufi('YOUR_API_KEY')`).
* Typed models: `Bot`, `ChatResponse`, `ChatState`, `IntentPrediction`.
* Sealed exception hierarchy (`SarufiException` and subtypes); failures throw
  instead of returning error maps.
* Full endpoint coverage: create / update / get / list / delete bots, `chat`
  (general + WhatsApp), `chatStatus`, `updateConversationState`,
  `predictIntent`.
* `Bot` convenience helpers: `respond`, `predictIntent`, `rename`, `update`,
  `addIntent`, `addFlow`, `delete`.
* `createFromFile` / `updateFromFile` (JSON & YAML) via
  `package:sarufi/sarufi_io.dart`.
* Self-documenting API: `SarufiDocs` / `Sarufi.docs` print each operation's
  fields and a runnable example inline (`print(SarufiDocs.chat)`).
* `MessageType` and `Channel` enums.
* Injectable `http.Client`, configurable `baseUrl` and `timeout`, opt-in
  console logging.
* Pure Dart package: runs on mobile, desktop, web, server and CLI.
* Runnable examples, including the bilingual Weledi Bot flagship
  (browse courses, enroll, pay) plus insurance and betting bots.
* Requires Dart `>=3.4.0`.
