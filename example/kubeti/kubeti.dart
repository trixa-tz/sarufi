// Kubeti - a Swahili sports-betting assistant.
//
// Place a bet or withdraw winnings through a chat. The intents and flow live
// next to this file as JSON, so you can edit them without touching Dart.
//
// Run:  dart run example/kubeti/kubeti.dart
//
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:sarufi/sarufi.dart';
import 'package:sarufi/sarufi_io.dart';

const _botName = 'Kubeti';

Future<void> main() async {
  final sarufi = Sarufi('YOUR_API_KEY');

  try {
    final bot = await _findOrCreateBot(sarufi);
    print('Using ${bot.name} (id: ${bot.id})\n');

    await _chat(bot);
  } on SarufiException catch (e) {
    print('Error: $e');
  } finally {
    sarufi.close();
  }
}

/// Creates the Kubeti bot from the JSON config in this folder.
Future<Bot> createKubetiBot(Sarufi sarufi) {
  return sarufi.createFromFile(
    intents: 'example/kubeti/intents.json',
    flow: 'example/kubeti/flow.json',
    metadata: 'example/kubeti/metadata.json',
  );
}

/// Re-uploads the JSON config to an existing bot [id].
Future<Bot> updateKubetiBot(Sarufi sarufi, int id) {
  return sarufi.updateFromFile(
    id: id,
    intents: 'example/kubeti/intents.json',
    flow: 'example/kubeti/flow.json',
    metadata: 'example/kubeti/metadata.json',
  );
}

Future<Bot> _findOrCreateBot(Sarufi sarufi) async {
  for (final bot in await sarufi.bots()) {
    if (bot.name == _botName) return bot;
  }
  return createKubetiBot(sarufi);
}

Future<void> _chat(Bot bot) async {
  const chatId = 'furaha';
  print('Anza kubeti! Andika "exit" kuondoka.\n');
  while (true) {
    stdout.write('Me : ');
    final message = stdin.readLineSync()?.trim();
    if (message == null || message.toLowerCase() == 'exit') break;
    if (message.isEmpty) continue;

    final reply = await bot.respond(chatId: chatId, message: message);
    print('Bot: ${reply.messages.join('\n     ')}');
  }
}
