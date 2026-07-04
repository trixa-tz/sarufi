# Sarufi - Dart & Flutter SDK

[![pub package](https://img.shields.io/pub/v/sarufi.svg?style=flat-square)](https://pub.dev/packages/sarufi)
[![pub points](https://img.shields.io/pub/points/sarufi?style=flat-square)](https://pub.dev/packages/sarufi/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Made in Tanzania](https://img.shields.io/badge/made%20in-tanzania-008751.svg?style=flat-square)](https://github.com/Tanzania-Developers-Community/made-in-tanzania)

A modern, null-safe Dart SDK for the [**Sarufi**](https://sarufi.io) Conversational
AI platform. Build, train and chat with Swahili-first chatbots from any Dart or
**Flutter** app: mobile, desktop, web, server or CLI.

```dart
final sarufi = Sarufi('YOUR_API_KEY');
final bot = await sarufi.getBot(42);
final reply = await bot.respond(message: 'Habari');
print(reply.messages); // ['Habari yako? Karibu Weledi']
```

## Why this SDK

- **API-key auth** - one line to get started.
- **Typed models** - `Bot`, `ChatResponse`, `ChatState`, `IntentPrediction`; no more digging through raw maps.
- **Typed errors** - a `sealed` `SarufiException` hierarchy you can exhaustively `switch` on.
- **Self-documenting** - `print(SarufiDocs.chat)` prints an endpoint's fields and an example, right in your terminal.
- **Testable** - inject your own `http.Client`; unit tests never touch the network.
- **Pure Dart** - no Flutter dependency, so it runs everywhere Dart does.

## Contents

- [Install](#install)
- [Quick start](#quick-start)
- [Authentication](#authentication)
- [Creating bots](#creating-bots)
- [Conversations](#conversations)
- [The `Bot` object](#the-bot-object)
- [Self-documenting API](#self-documenting-api)
- [Error handling](#error-handling)
- [Logging](#logging)
- [Testing](#testing)
- [API reference](#api-reference)
- [Examples](#examples)
- [Other Sarufi SDKs](#other-sarufi-sdks)

## Install

```bash
dart pub add sarufi      # or: flutter pub add sarufi
```

```yaml
dependencies:
  sarufi: ^1.0.0
```

Then import it:

```dart
import 'package:sarufi/sarufi.dart';
```

## Quick start

```dart
import 'package:sarufi/sarufi.dart';

Future<void> main() async {
  final sarufi = Sarufi('YOUR_API_KEY');

  // Create a bot with intents (example phrases) and a flow (state machine).
  final bot = await sarufi.createBot(
    name: 'Weledi Bot',
    description: 'A friendly Swahili student assistant',
    intents: {
      'salamu': ['habari', 'mambo', 'hi'],
    },
    flow: {
      'salamu': {
        'message': ['Habari! Karibu Weledi'],
        'next_state': 'end',
      },
    },
  );

  // Chat with it.
  final reply = await bot.respond(message: 'Habari');
  print(reply.messages);  // ['Habari! Karibu Weledi']
  print(reply.nextState); // 'end'

  sarufi.close(); // release the HTTP client when you're done
}
```

## Authentication

Grab an API key from the [Sarufi dashboard](https://sarufi.io) and pass it to the
constructor. Every request is authenticated with a `Bearer` token automatically.

```dart
final sarufi = Sarufi(
  'YOUR_API_KEY',
  timeout: const Duration(seconds: 30), // optional (default: 120s)
);
```

## Creating bots

Bots are defined by **intents** (a map of intent name to example phrases) and a
**flow** (the conversation state machine).

```dart
final bot = await sarufi.createBot(
  name: 'iBank',
  industry: 'banking',
  intents: {
    'greeting': ['habari', 'mambo', 'hi'],
    'balance': ['angalia salio', 'check my balance'],
  },
  flow: {
    'greeting': {
      'message': ['Karibu iBank! Naweza kukusaidiaje?'],
      'next_state': 'end',
    },
  },
);
```

### From JSON / YAML files

Keep your training data in files and load it with the IO helper (uses `dart:io`,
so it's available everywhere except Flutter web):

```dart
import 'package:sarufi/sarufi.dart';
import 'package:sarufi/sarufi_io.dart';

final bot = await sarufi.createFromFile(
  intents: 'data/intents.yaml',
  flow: 'data/flow.yaml',
  metadata: 'data/metadata.json', // name, description, industry, ...
);

// Re-upload after editing the files:
await sarufi.updateFromFile(id: bot.id!, flow: 'data/flow.yaml');
```

## Conversations

```dart
// Reuse a chat id to keep context across turns.
const chatId = 'user-123';
await sarufi.chat(botId: 42, chatId: chatId, message: 'Habari');
await sarufi.chat(botId: 42, chatId: chatId, message: 'Nataka kukopa');

// Where are we in the flow?
final state = await sarufi.chatStatus(botId: 42, chatId: chatId);
print('${state.currentState} -> ${state.nextState}');

// Classify a message without advancing the conversation.
final p = await sarufi.predictIntent(botId: 42, message: 'nataka salio langu');
print('${p.intent} (${p.confidence})');

// Send over WhatsApp instead of the default channel.
await sarufi.chat(botId: 42, message: 'Hi', channel: Channel.whatsapp);
```

## The `Bot` object

`getBot`, `bots`, `createBot` and `updateBot` all return a `Bot`: a typed
wrapper you can act on directly. Mutating helpers call the API and return a
**fresh** `Bot` (no hidden network calls behind a plain setter).

```dart
final bot = await sarufi.getBot(42);

bot.name;        // 'Weledi Bot'
bot.intents;     // Map<String, dynamic>?
bot.flows;       // Map<String, dynamic>?

await bot.respond(message: 'Habari');            // ChatResponse
await bot.predictIntent('nataka kozi');          // IntentPrediction
final trained = await bot.addIntent({'bye': ['kwaheri']}); // updated Bot
final renamed = await bot.rename('Weledi v2');   // updated Bot
await bot.delete();
```

## Self-documenting API

Every operation ships with inline docs, no browser needed. Print one endpoint,
or all of them:

```dart
print(SarufiDocs.chat);
```

```text
┌─ chat
│  POST conversation
│  Send a message to a bot and get its reply.
│
│  Set channel to whatsapp to route through the conversation/whatsapp
│  endpoint. Reuse chat_id across turns to keep conversation context.
│
│  Request body:
│    bot_id                  number   required
│    chat_id                 string   optional  Conversation session id (auto-generated if omitted).
│    message                 string   required
│    message_type            string   optional  [text, image, audio, video, file]
│
│  Response:
│    message                 array    optional  The bot's replies.
│    next_state              string   optional  The state moved to.
│
│  Example:
│    final reply = await sarufi.chat(botId: 42, chatId: 'user-1', message: 'Habari');
│    print(reply.messages);
└─
```

```dart
print(Sarufi.docs); // every operation, in reading order
```

## Error handling

Every call throws a typed `SarufiException` on failure. The base type is
`sealed`, so a `switch` is exhaustive and the analyzer keeps you honest:

```dart
try {
  await sarufi.getBot(42);
} on SarufiException catch (e) {
  final reason = switch (e) {
    SarufiAuthException()       => 'Check your API key',
    SarufiNotFoundException()   => 'That bot does not exist',
    SarufiValidationException() => 'Bad request: ${e.message}',
    SarufiNetworkException()    => 'No connection',
    SarufiServerException()     => 'Sarufi is having a bad day',
    SarufiApiException()        => e.message,
  };
  print(reason);
}
```

Each exception carries `message`, `statusCode` and the decoded `body`.

## Logging

Nothing is printed by default. Turn on diagnostics during development:

```dart
Sarufi.enableConsoleLogging(); // built on the `logging` package
```

## Testing

Inject a mock `http.Client` and your integration never hits the network:

```dart
import 'package:http/testing.dart';

final sarufi = Sarufi(
  'test-key',
  httpClient: MockClient((req) async => http.Response('{"id":1}', 200)),
);
```

## API reference

| Method | HTTP | Returns |
| --- | --- | --- |
| `createBot(...)` | `POST chatbot` | `Bot` |
| `updateBot(id, ...)` | `PUT chatbot/{id}` | `Bot` |
| `getBot(id)` | `GET chatbot/{id}` | `Bot` |
| `bots()` | `GET chatbots` | `List<Bot>` |
| `deleteBot(id)` | `DELETE chatbot/{id}` | `Map` |
| `chat(...)` | `POST conversation` | `ChatResponse` |
| `chatStatus(...)` | `POST conversation/status` | `ChatState` |
| `updateConversationState(...)` | `POST conversation-state` | `Map` |
| `predictIntent(...)` | `POST predict/intent` | `IntentPrediction` |

Base URL: `https://developers.sarufi.io/`.

## Examples

Runnable examples live in [`example/`](example/):

| Example | What it shows |
| --- | --- |
| [`example.dart`](example/example.dart) | End-to-end tour: create, chat, list, train, delete |
| [`weledi/`](example/weledi/) | **Flagship** - a bilingual student bot: browse courses, enroll, pay |
| [`insurance/`](example/insurance/) | Build an insurance bot from JSON files |
| [`kubeti/`](example/kubeti/) | Swahili betting bot, created/updated from JSON |

```bash
dart run example/weledi/weledi.dart
```

## Other Sarufi SDKs

Prefer another language? Sarufi has official and community SDKs:

- **Dart & Flutter** - this package
- **Python** - [sarufi-python-sdk](https://github.com/Neurotech-HQ/sarufi-python-sdk)

## Credits

Built and maintained by [Brightius Kalokola](https://github.com/kalokola) at [TRIXA](https://trixa.net). Thanks to the [Sarufi](https://docs.sarufi.io/) and [Neurotech Africa](https://neurotech.africa/) team for the platform.

## Support

Please open an issue on [GitHub](https://github.com/trixa-tz/sarufi/), or contact the maintainer at <brightius@trixa.net>

Licensed under the [MIT License](LICENSE).
