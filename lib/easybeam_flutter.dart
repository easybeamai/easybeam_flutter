import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import './sse_stream.dart' if (dart.library.js) './sse_stream_web.dart';

class EasyBeamConfig {
  final String token;

  EasyBeamConfig({required this.token});
}

// ignore: constant_identifier_names
enum ChatRole { AI, USER }

class ChatMessage {
  final String content;
  final ChatRole role;
  final String createdAt;
  final String? providerId;
  final String id;
  final double? inputTokens;
  final double? outputTokens;
  final double? cost;

  ChatMessage({
    required this.content,
    required this.role,
    required this.createdAt,
    this.providerId,
    required this.id,
    this.inputTokens,
    this.outputTokens,
    this.cost,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'role': role.toString().split('.').last,
        'createdAt': createdAt,
        'providerId': providerId,
        'id': id,
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
        'cost': cost,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      content: json['content'],
      role: ChatRole.values
          .firstWhere((e) => e.toString() == 'ChatRole.${json['role']}'),
      createdAt: json['createdAt'],
      providerId: json['providerId'],
      id: json['id'],
      inputTokens: json['inputTokens'],
      outputTokens: json['outputTokens'],
      cost: json['cost'],
    );
  }

  static String getCurrentTimestamp() {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
        .format(DateTime.now().toUtc());
  }
}

class ChatResponse {
  final ChatMessage newMessage;
  final String chatId;
  final bool? streamFinished;

  ChatResponse({
    required this.newMessage,
    required this.chatId,
    this.streamFinished,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      newMessage: ChatMessage.fromJson(json['newMessage']),
      chatId: json['chatId'],
      streamFinished: json['streamFinished'],
    );
  }
}

typedef StreamGetter = Future<Stream<String>> Function(http.Request request);
typedef CancelFunction = void Function();

class Easybeam {
  final EasyBeamConfig config;
  final String baseUrl = 'https://api.easybeam.ai/v1';
  final Map<String, StreamSubscription> _streamSubscriptions = {};
  final Map<String, http.Client> _clients = {};
  http.Client _client = http.Client();

  StreamGetter? _streamGetterOverride;

  Easybeam(this.config);

  void injectStreamGetter(StreamGetter streamGetter) {
    _streamGetterOverride = streamGetter;
  }

  void injectHttpClient(http.Client client) {
    _client = client;
  }

  void dispose() {
    for (var streamId in _streamSubscriptions.keys) {
      _cleanupStream(streamId);
    }
  }

  Future<Stream<String>> _getStream(http.Request request) async {
    if (_streamGetterOverride != null) {
      return _streamGetterOverride!(request);
    }
    return (await getStream(request)).transform(utf8.decoder);
  }

  CancelFunction streamEndpoint({
    required String endpoint,
    required String id,
    String? userId,
    required Map<String, String> filledVariables,
    required List<ChatMessage> messages,
    required Function(ChatResponse) onNewResponse,
    required Function() onClose,
    required Function(dynamic) onError,
  }) {
    final streamId =
        '${endpoint}_${id}_${DateTime.now().millisecondsSinceEpoch}';
    final url = Uri.parse('$baseUrl/$endpoint/$id');
    final body = jsonEncode({
      'variables': filledVariables,
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': 'true',
      'userId': userId,
    });

    final request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer ${config.token}';
    request.body = body;

    _clients[streamId] = http.Client();

    _getStream(request).then((stream) {
      _streamSubscriptions[streamId] = stream.listen(
        (String chunk) {
          _processChunk(chunk, onNewResponse, onClose, onError);
        },
        onError: (error) {
          onError('Error in stream: $error');
          _cleanupStream(streamId);
        },
        onDone: () {
          onClose();
          _cleanupStream(streamId);
        },
      );
    }).catchError((error) {
      onError('Error starting stream: $error');
      _cleanupStream(streamId);
    });

    return () => _cleanupStream(streamId);
  }

  void _cleanupStream(String streamId) {
    _streamSubscriptions[streamId]?.cancel();
    _streamSubscriptions.remove(streamId);
    _clients[streamId]?.close();
    _clients.remove(streamId);
  }

  String _buffer = '';

  void _processChunk(
    String chunk,
    Function(ChatResponse) onNewResponse,
    Function() onClose,
    Function(dynamic) onError,
  ) {
    _buffer += chunk;
    while (true) {
      int index = _buffer.indexOf('\n\n');
      if (index == -1) {
        break;
      }

      String rawMessage = _buffer.substring(0, index);
      _buffer = _buffer.substring(index + 2);

      if (rawMessage.startsWith('data: ')) {
        final data = rawMessage.substring(6);
        if (data.trim() == '[DONE]') {
          // close called at top level
        } else {
          try {
            final jsonResponse = jsonDecode(data);
            final chatResponse = ChatResponse.fromJson(jsonResponse);
            onNewResponse(chatResponse);
          } catch (e) {
            onError('Error processing stream data: $e');
          }
        }
      }
    }
  }

  Future<ChatResponse> getEndpoint({
    required String endpoint,
    required String id,
    String? userId,
    required Map<String, String> filledVariables,
    required List<ChatMessage> messages,
  }) async {
    final url = Uri.parse('$baseUrl/$endpoint/$id');
    final body = jsonEncode({
      'variables': filledVariables,
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': 'false',
      'userId': userId,
    });

    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.token}',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to process request: ${response.body}');
    }

    return ChatResponse.fromJson(jsonDecode(response.body));
  }

  CancelFunction streamPrompt({
    required String promptId,
    String? userId,
    required Map<String, String> filledVariables,
    required List<ChatMessage> messages,
    required Function(ChatResponse) onNewResponse,
    required Function() onClose,
    required Function(dynamic) onError,
  }) {
    return streamEndpoint(
      endpoint: 'prompt',
      id: promptId,
      userId: userId,
      filledVariables: filledVariables,
      messages: messages,
      onNewResponse: onNewResponse,
      onClose: onClose,
      onError: onError,
    );
  }

  Future<ChatResponse> getPrompt({
    required String promptId,
    String? userId,
    required Map<String, String> filledVariables,
    required List<ChatMessage> messages,
  }) async {
    return await getEndpoint(
      endpoint: 'prompt',
      id: promptId,
      userId: userId,
      filledVariables: filledVariables,
      messages: messages,
    );
  }

  CancelFunction streamAgent({
    required String agentId,
    String? userId,
    required Map<String, String> filledVariables,
    required List<ChatMessage> messages,
    required Function(ChatResponse) onNewResponse,
    required Function() onClose,
    required Function(dynamic) onError,
  }) {
    return streamEndpoint(
      endpoint: 'agent',
      id: agentId,
      userId: userId,
      filledVariables: filledVariables,
      messages: messages,
      onNewResponse: onNewResponse,
      onClose: onClose,
      onError: onError,
    );
  }

  Future<ChatResponse> getAgent({
    required String agentId,
    String? userId,
    required Map<String, String> filledVariables,
    required List<ChatMessage> messages,
  }) async {
    return await getEndpoint(
      endpoint: 'agent',
      id: agentId,
      userId: userId,
      filledVariables: filledVariables,
      messages: messages,
    );
  }

  Future<void> review({
    required String chatId,
    String? userId,
    int? reviewScore,
    String? reviewText,
  }) async {
    final url = Uri.parse('$baseUrl/review');
    final body = jsonEncode({
      'chatId': chatId,
      'userId': userId,
      'reviewScore': reviewScore,
      'reviewText': reviewText,
    });

    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.token}',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit review: ${response.body}');
    }
  }
}
