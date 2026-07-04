// Weledi Bot - a bilingual (Swahili / English) student assistant.
//
// Helps students browse the courses available on the Weledi platform and pay
// for them, right inside a chat. The intents and flow live next to this file
// as JSON, so you can edit the course catalogue without touching Dart.
//
// Run:  dart run example/weledi/weledi.dart
//
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:sarufi/sarufi.dart';
import 'package:sarufi/sarufi_io.dart';

const _botName = 'Weledi Bot';

Future<void> main() async {
  final sarufi = Sarufi('YOUR_API_KEY');

  try {
    // Reuse the bot if we've already created it, otherwise build it from JSON.
    final bot = await _findOrCreateBot(sarufi);
    print('Using ${bot.name} (id: ${bot.id})\n');

    await _chat(bot);
  } on SarufiException catch (e) {
    print('Error: $e');
  } finally {
    sarufi.close();
  }
}

/// Creates the Weledi bot from the JSON config in this folder.
Future<Bot> createWelediBot(Sarufi sarufi) {
  return sarufi.createFromFile(
    intents: 'example/weledi/intents.json',
    flow: 'example/weledi/flow.json',
    metadata: 'example/weledi/metadata.json',
  );
}

/// Re-uploads the JSON config to an existing bot [id] - handy after editing the
/// course catalogue in `flow.json`.
Future<Bot> updateWelediBot(Sarufi sarufi, int id) {
  return sarufi.updateFromFile(
    id: id,
    intents: 'example/weledi/intents.json',
    flow: 'example/weledi/flow.json',
    metadata: 'example/weledi/metadata.json',
  );
}

Future<Bot> _findOrCreateBot(Sarufi sarufi) async {
  for (final bot in await sarufi.bots()) {
    if (bot.name == _botName) return bot;
  }
  return createWelediBot(sarufi);
}

Future<void> _chat(Bot bot) async {
  // One chat id per student keeps each conversation's context separate.
  const chatId = 'mwanafunzi-1';
  print("Karibu Weledi! Andika 'kozi' kuanza, au 'exit' kuondoka.\n");

  while (true) {
    stdout.write('Wewe   : ');
    final message = stdin.readLineSync()?.trim();
    if (message == null || message.toLowerCase() == 'exit') break;
    if (message.isEmpty) continue;

    final reply = await bot.respond(chatId: chatId, message: message);
    print('Weledi : ${reply.messages.join('\n         ')}');
  }
}
