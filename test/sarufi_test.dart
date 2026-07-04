import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sarufi/sarufi.dart';
import 'package:test/test.dart';

/// Builds a [Sarufi] whose HTTP layer is backed by [handler], so tests never
/// touch the network.
Sarufi clientWith(
  Future<http.Response> Function(http.Request request) handler,
) {
  return Sarufi(
    'test-api-key',
    baseUrl: 'https://example.test/',
    httpClient: MockClient(handler),
  );
}

http.Response json(Object body, {int status = 200}) =>
    http.Response(jsonEncode(body), status, headers: {
      'content-type': 'application/json',
    });

void main() {
  group('authentication & requests', () {
    test('sends the api key as a bearer token', () async {
      late http.Request captured;
      final sarufi = clientWith((req) async {
        captured = req;
        return json({'id': 1, 'name': 'Maria'});
      });

      await sarufi.getBot(1);

      expect(captured.headers['Authorization'], 'Bearer test-api-key');
      expect(captured.headers['Content-Type'], contains('application/json'));
      expect(captured.url.toString(), 'https://example.test/chatbot/1');
    });
  });

  group('createBot', () {
    test('strips null fields and returns a Bot', () async {
      late Map<String, dynamic> sentBody;
      final sarufi = clientWith((req) async {
        sentBody = jsonDecode(req.body) as Map<String, dynamic>;
        return json({'id': 5, 'name': 'Maria', 'industry': 'general'});
      });

      final bot = await sarufi.createBot(name: 'Maria', industry: 'general');

      expect(bot, isA<Bot>());
      expect(bot.id, 5);
      expect(bot.name, 'Maria');
      // description/flows/etc. were null and must not be sent.
      expect(sentBody.containsKey('description'), isFalse);
      expect(sentBody.containsKey('flows'), isFalse);
      expect(sentBody['name'], 'Maria');
      expect(sentBody['industry'], 'general');
    });
  });

  group('bots', () {
    test('maps a JSON array into a list of Bot', () async {
      final sarufi = clientWith((req) async {
        return json([
          {'id': 1, 'name': 'iBank'},
          {'id': 2, 'name': 'Maria'},
        ]);
      });

      final bots = await sarufi.bots();

      expect(bots, hasLength(2));
      expect(bots.map((b) => b.name), ['iBank', 'Maria']);
    });
  });

  group('chat', () {
    test('posts to /conversation and parses the reply', () async {
      late Uri url;
      late Map<String, dynamic> body;
      final sarufi = clientWith((req) async {
        url = req.url;
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return json({
          'message': ['Habari yako?'],
          'next_state': 'greeting',
        });
      });

      final reply = await sarufi.chat(botId: 5, message: 'Habari');

      expect(url.toString(), 'https://example.test/conversation');
      expect(body['bot_id'], 5);
      expect(body['message'], 'Habari');
      expect(body['message_type'], 'text');
      expect(reply.messages, ['Habari yako?']);
      expect(reply.nextState, 'greeting');
    });

    test('routes WhatsApp messages to /conversation/whatsapp', () async {
      late Uri url;
      final sarufi = clientWith((req) async {
        url = req.url;
        return json({'message': <String>[]});
      });

      await sarufi.chat(botId: 5, message: 'Hi', channel: Channel.whatsapp);

      expect(url.toString(), 'https://example.test/conversation/whatsapp');
    });

    test('extracts messages from the actions payload shape', () async {
      final sarufi = clientWith((req) async {
        return json({
          'actions': [
            {
              'send_message': ['Karibu']
            },
          ],
          'next_state': 'end',
        });
      });

      final reply = await sarufi.chat(botId: 1, message: 'x');
      expect(reply.messages, ['Karibu']);
    });
  });

  group('Bot helpers', () {
    test('respond() delegates to chat with the bot id', () async {
      late Map<String, dynamic> body;
      final sarufi = clientWith((req) async {
        if (req.url.path.endsWith('chatbot/7')) {
          return json({'id': 7, 'name': 'Maria'});
        }
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return json({
          'message': ['ok']
        });
      });

      final bot = await sarufi.getBot(7);
      await bot.respond(message: 'Hi');

      expect(body['bot_id'], 7);
      expect(body['chat_id'], isNotEmpty);
    });

    test('addIntent merges with existing intents', () async {
      late Map<String, dynamic> putBody;
      final sarufi = clientWith((req) async {
        if (req.method == 'GET') {
          return json({
            'id': 3,
            'name': 'Maria',
            'intents': {
              'bye': ['kwaheri'],
            },
          });
        }
        putBody = jsonDecode(req.body) as Map<String, dynamic>;
        return json({'id': 3, 'name': 'Maria', 'intents': putBody['intents']});
      });

      final bot = await sarufi.getBot(3);
      final updated = await bot.addIntent({
        'greeting': ['habari'],
      });

      expect(putBody['intents'], containsPair('bye', ['kwaheri']));
      expect(putBody['intents'], containsPair('greeting', ['habari']));
      expect(updated.intents?.keys, containsAll(['bye', 'greeting']));
    });
  });

  group('error handling', () {
    test('throws SarufiAuthException on 401', () async {
      final sarufi = clientWith((req) async {
        return json({'detail': 'Invalid API key'}, status: 401);
      });

      expect(
        () => sarufi.getBot(1),
        throwsA(isA<SarufiAuthException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', 'Invalid API key')),
      );
    });

    test('throws SarufiNotFoundException on 404', () async {
      final sarufi = clientWith((req) async {
        return json({'message': 'Bot not found'}, status: 404);
      });

      expect(() => sarufi.getBot(999), throwsA(isA<SarufiNotFoundException>()));
    });

    test('throws SarufiValidationException on 400', () async {
      final sarufi = clientWith((req) async {
        return json({'message': 'name is required'}, status: 400);
      });

      expect(() => sarufi.createBot(name: ''),
          throwsA(isA<SarufiValidationException>()));
    });

    test('throws SarufiServerException on 500', () async {
      final sarufi = clientWith((req) async {
        return http.Response('oops', 500);
      });

      expect(() => sarufi.bots(), throwsA(isA<SarufiServerException>()));
    });

    test('wraps transport failures as SarufiNetworkException', () async {
      final sarufi = clientWith((req) async {
        throw http.ClientException('connection reset');
      });

      expect(() => sarufi.bots(), throwsA(isA<SarufiNetworkException>()));
    });
  });
}
