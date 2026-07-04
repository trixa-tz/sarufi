// A quick end-to-end tour of the Sarufi Dart SDK, using a tiny inline "Weledi"
// student bot. For the full, file-based Weledi Bot (courses + payments) see
// example/weledi/.
//
// Add your API key below, then run:  dart run example/example.dart
//
// ignore_for_file: avoid_print

import 'package:sarufi/sarufi.dart';

Future<void> main() async {
  // Opt-in diagnostics - the SDK is silent by default.
  Sarufi.enableConsoleLogging();

  final sarufi = Sarufi('YOUR_API_KEY');

  try {
    // 1. Create a bot with intents + flow defined inline as Dart maps.
    final bot = await sarufi.createBot(
      name: 'Weledi Demo',
      description: 'A tiny student assistant',
      industry: 'education',
      intents: {
        'salamu': ['Habari', 'Mambo', 'Hi', 'Hello'],
        'kozi': ['kozi', 'nataka kozi', 'available courses', 'nataka kusoma'],
      },
      flow: {
        'salamu': {
          'message': ['Habari! Karibu Weledi', "Andika 'kozi' kuona kozi."],
          'next_state': 'end',
        },
        'kozi': {
          'message': [
            'Kozi zinazopatikana:',
            '1. Hisabati (TZS 10,000)',
            '2. Fizikia (TZS 10,000)',
          ],
          'next_state': 'end',
        },
      },
    );
    print('Created ${bot.name} (id: ${bot.id})');

    // 2. Chat with it.
    final reply = await bot.respond(message: 'Habari');
    print('Bot said: ${reply.messages}');

    // 3. List all your bots.
    final all = await sarufi.bots();
    print('You have ${all.length} bot(s).');

    // 4. Teach it a new intent (returns an updated Bot).
    final trained = await bot.addIntent({
      'kwaheri': ['kwaheri', 'bye', 'goodbye'],
    });
    print('Intents: ${trained.intents?.keys.toList()}');

    // 5. Clean up.
    await bot.delete();
    print('Deleted bot ${bot.id}');
  } on SarufiException catch (e) {
    // Typed errors - switch on the sealed hierarchy for precise handling.
    print('Sarufi request failed: $e');
  } finally {
    sarufi.close();
  }
}
