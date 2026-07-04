// Conversational insurance bot.
//
// Browse cover, choose a plan and pay, all inside a chat. The intents and flow
// live next to this file as JSON, so you can edit them without touching Dart.
//
// Run:  dart run example/insurance/insurance.dart
//
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:sarufi/sarufi.dart';
import 'package:sarufi/sarufi_io.dart';

const _botName = 'My Insurance Bot';

Future<void> main() async {
  final sarufi = Sarufi('YOUR_API_KEY');

  try {
    // Reuse an existing bot if we've already created one, otherwise build it
    // from the JSON files in this folder.
    final bot = await _findOrCreateBot(sarufi);
    print('Using ${bot.name} (id: ${bot.id})\n');

    await _chat(bot);
  } on SarufiException catch (e) {
    print('Error: $e');
  } finally {
    sarufi.close();
  }
}

/// Creates the insurance bot from `intents.json` + `flow.json` + `metadata.json`.
Future<Bot> createInsuranceBot(Sarufi sarufi) {
  return sarufi.createFromFile(
    intents: 'example/insurance/intents.json',
    flow: 'example/insurance/flow.json',
    metadata: 'example/insurance/metadata.json',
  );
}

Future<Bot> _findOrCreateBot(Sarufi sarufi) async {
  for (final bot in await sarufi.bots()) {
    if (bot.name == _botName) return bot;
  }
  return createInsuranceBot(sarufi);
}

/// A reusable one-turn responder - the same shape you'd wire into Telegram,
/// WhatsApp, an HTTP webhook, or a Flutter chat screen.
Future<List<String>> respond(
  Bot bot, {
  required String chatId,
  required String message,
}) async {
  final reply = await bot.respond(chatId: chatId, message: message);
  return reply.messages;
}

Future<void> _chat(Bot bot) async {
  const chatId = 'furaha';
  print('Say hello to the insurance bot. Type "exit" to quit.\n');
  while (true) {
    stdout.write('Me : ');
    final message = stdin.readLineSync()?.trim();
    if (message == null || message.toLowerCase() == 'exit') break;
    if (message.isEmpty) continue;

    final messages = await respond(bot, chatId: chatId, message: message);
    print('Bot: ${messages.join('\n     ')}');
  }
}
