# Conversational Insurance

An example showing how to create a conversational experience for buying
insurance.

Things to consider while building the bot:

1. Intents
2. Flow of the conversation
3. Using the conversation you created
4. Deploying the bot to a messaging channel (Telegram, WhatsApp, Messenger, anywhere)

### Intents

1. greetings (closed ended)
2. goodbye (closed ended)
3. purchase_insurance
   - user's name
   - type of insurance (1. Car, 2. Home, 3. Health)
   - payment method & amount
   - pay now
4. revoke_insurance
   - insurance number
   - confirmation

### Files

- [`intents.json`](intents.json) - example utterances per intent
- [`flow.json`](flow.json) - the conversation state machine
- [`metadata.json`](metadata.json) - name / description / industry
- [`insurance.dart`](insurance.dart) - creates the bot and runs a chat loop

```bash
dart run example/insurance/insurance.dart
```
