# Weledi Bot

The flagship example - a bilingual (Swahili / English) student assistant for the
**Weledi** platform. Students chat to **browse the available courses** and **pay
for them** without ever leaving the conversation.

### What it can do

- **salamu** - greets the student and explains how it helps
- **kozi** - walks the student through enrolling:
  ask their name -> list courses -> pick one -> pick a payment method
  (M-Pesa / Mixx by Yas / Airtel Money) -> enter phone -> confirm -> done
- **kozi_zangu** - shows the courses the student has joined
- **msaada / shukrani / kwaheri** - help, thanks and goodbye

The "pay for a course" path is a multi-step **flow** (a state machine) - exactly
what Sarufi is built for. Each step remembers where the conversation is, and the
`{name}` placeholder shows how the bot personalises replies from memory.

### Files

- [`intents.json`](intents.json) - example phrases per intent (Swahili + English)
- [`flow.json`](flow.json) - the conversation state machine (courses, prices, payment)
- [`metadata.json`](metadata.json) - bot name / description / industry
- [`weledi.dart`](weledi.dart) - creates the bot from the files and runs a chat loop

```bash
dart run example/weledi/weledi.dart
```

### Try this conversation

| You type | The bot does |
| --- | --- |
| `Habari` | Greets you, explains how to start |
| `kozi` | Starts enrolment - asks your name |
| `Amina` | Lists the courses with prices |
| `1` | Picks Hisabati, shows the price, asks how to pay |
| `1` | Picks M-Pesa, asks for your phone number |
| `0754123456` | Sends a (mock) payment request |
| `thibitisha` | Confirms payment and enrolls you |

> Editing the catalogue is just editing `flow.json` - add a course by adding a
> numbered option under `pata_jina` and a matching `kozi_*` state, then re-run
> with `updateWelediBot`.
