# Kubeti - Swahili betting bot

A Swahili sports-betting assistant.

### Intents

1. `weka_beti` (place a bet)
   - choose the match to bet on
   - choose who wins
   - amount to stake
   - thank you
2. `toa_hela` (withdraw money)
   - specify amount
   - password
3. `salamu` (greetings)

### Files

- [`intents.json`](intents.json) - example utterances per intent
- [`flow.json`](flow.json) - the conversation state machine
- [`metadata.json`](metadata.json) - name / description / industry
- [`kubeti.dart`](kubeti.dart) - creates/updates the bot and runs a chat loop

```bash
dart run example/kubeti/kubeti.dart
```
