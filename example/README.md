# Sarufi Dart - examples

Runnable examples for the Sarufi Dart & Flutter SDK.

Add your API key (replace `YOUR_API_KEY`) in each file before running.

| Example | What it shows |
| --- | --- |
| [`example.dart`](example.dart) | A quick end-to-end tour: create -> chat -> list -> train -> delete (inline intents & flow) |
| [`weledi/weledi.dart`](weledi/weledi.dart) | **Flagship** - a bilingual student bot: browse courses -> enroll -> pay |
| [`insurance/insurance.dart`](insurance/insurance.dart) | Build an insurance bot from JSON files and hold a conversation |
| [`kubeti/kubeti.dart`](kubeti/kubeti.dart) | Swahili betting bot, created/updated from JSON files |

```bash
dart pub get
dart run example/example.dart
dart run example/weledi/weledi.dart
dart run example/insurance/insurance.dart
dart run example/kubeti/kubeti.dart
```

Each folder's `intents.json` (example phrases) and `flow.json` (the conversation
state machine) are the bot's training data. `metadata.json` supplies the bot's
name, description and industry to `createFromFile` / `updateFromFile`.

Start with [`weledi/`](weledi/) - it's the most complete example and shows a
real multi-step payment flow.
