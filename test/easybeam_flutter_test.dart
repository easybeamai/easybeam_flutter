import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:easybeam_flutter/easybeam_flutter.dart';

import 'easybeam_flutter_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late Easybeam easybeam;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    easybeam = Easybeam(EasyBeamConfig(token: 'test_token'));
    // Inject the mock client into the Easybeam instance
    easybeam.injectHttpClient(mockClient);
  });

  group('Easybeam', () {
    test('Constructor initializes with correct base URL', () {
      expect(easybeam.baseUrl, equals('https://api.easybeam.ai/v1'));
    });

    group('getPortal', () {
      test('returns PortalResponse on success', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
            '{"newMessage": {"content": "Test", "role": "AI", "createdAt": "2023-01-01T00:00:00.000Z", "id": "123"}, "chatId": "456"}',
            200));

        final result = await easybeam.getPortal(
          portalId: 'test_portal',
          filledVariables: {},
          messages: [],
        );

        expect(result, isA<PortalResponse>());
        expect(result.newMessage.content, equals('Test'));
        expect(result.chatId, equals('456'));
      });

      test('throws exception on non-200 response', () {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('Error', 400));

        expect(
          () => easybeam.getPortal(
            portalId: 'test_portal',
            filledVariables: {},
            messages: [],
          ),
          throwsException,
        );
      });
    });

    group('getWorkflow', () {
      test('returns PortalResponse on success', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
            '{"newMessage": {"content": "Workflow Test", "role": "AI", "createdAt": "2023-01-01T00:00:00.000Z", "id": "789"}, "chatId": "101112"}',
            200));

        final result = await easybeam.getWorkflow(
          workflowId: 'test_workflow',
          filledVariables: {},
          messages: [],
        );

        expect(result, isA<PortalResponse>());
        expect(result.newMessage.content, equals('Workflow Test'));
        expect(result.chatId, equals('101112'));
      });

      test('throws exception on non-200 response', () {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('Error', 500));

        expect(
          () => easybeam.getWorkflow(
            workflowId: 'test_workflow',
            filledVariables: {},
            messages: [],
          ),
          throwsException,
        );
      });
    });

    group('review', () {
      test('submits review successfully', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"success": true}', 200));

        await expectLater(
          easybeam.review(
            chatId: 'test_chat',
            reviewScore: 5,
            reviewText: 'Great service!',
          ),
          completes,
        );
      });

      test('throws exception on non-200 response', () {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('Error', 400));

        expect(
          () => easybeam.review(
            chatId: 'test_chat',
            reviewScore: 5,
            reviewText: 'Great service!',
          ),
          throwsException,
        );
      });
    });

    group('ChatMessage', () {
      test('toJson and fromJson work correctly', () {
        final originalMessage = ChatMessage(
          content: 'Test message',
          role: ChatRole.USER,
          createdAt: '2023-01-01T00:00:00.000Z',
          id: '123',
          inputTokens: 10,
          outputTokens: 20,
          cost: 0.005,
        );

        final json = originalMessage.toJson();
        final recreatedMessage = ChatMessage.fromJson(json);

        expect(recreatedMessage.content, equals(originalMessage.content));
        expect(recreatedMessage.role, equals(originalMessage.role));
        expect(recreatedMessage.createdAt, equals(originalMessage.createdAt));
        expect(recreatedMessage.id, equals(originalMessage.id));
        expect(
            recreatedMessage.inputTokens, equals(originalMessage.inputTokens));
        expect(recreatedMessage.outputTokens,
            equals(originalMessage.outputTokens));
        expect(recreatedMessage.cost, equals(originalMessage.cost));
      });

      test('getCurrentTimestamp returns valid timestamp', () {
        final timestamp = ChatMessage.getCurrentTimestamp();
        expect(DateTime.tryParse(timestamp), isNotNull);
      });
    });
  });
}
