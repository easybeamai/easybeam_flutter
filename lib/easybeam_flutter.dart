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

class PortalResponse {
  final ChatMessage newMessage;
  final String chatId;
  final bool? streamFinished;

  PortalResponse({
    required this.newMessage,
    required this.chatId,
    this.streamFinished,
  });

  factory PortalResponse.fromJson(Map<String, dynamic> json) {
    return PortalResponse(
      newMessage: ChatMessage.fromJson(json['newMessage']),
      chatId: json['chatId'],
      streamFinished: json['streamFinished'],
    );
  }
}

typedef StreamGetter = Future<Stream<String>> Function(http.Request request);

class Easybeam {
  final EasyBeamConfig config;
  final String baseUrl = 'https://api.easybeam.ai/v1';
  StreamSubscription? _streamSubscription;
  http.Client _client = http.Client();
  StreamGetter? _streamGetterOverride;

  Easybeam(this.config);

  void injectHttpClient(http.Client client) {
    _client = client;
  }

  // This method is only for testing purposes
  void injectStreamGetter(StreamGetter streamGetter) {
    _streamGetterOverride = streamGetter;
  }

  Future<Stream<String>> _getStream(http.Request request) async {
    if (_streamGetterOverride != null) {
      return _streamGetterOverride!(request);
    }
    // Use the imported getStream function
    return (await getStream(request)).transform(utf8.decoder);
  }

  void streamEndpoint({
    required String endpoint,
    required String id,
    String? userId,
    required Map<String, String> filledVariables,
    required List<ChatMessage> messages,
    required Function(PortalResponse) onNewResponse,
    required Function() onClose,
    required Function(dynamic) onError,
  }) async {
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

    _streamSubscription?.cancel();
    try {
      final stream = await _getStream(request);
      _streamSubscription = stream.listen(
        (String chunk) {
          _processChunk(chunk, onNewResponse, onClose, onError);
        },
        onError: (error) {
          onError('Error in stream: $error');
          cancelCurrentStream();
        },
        onDone: () {
          onClose();
          cancelCurrentStream();
        },
      );
    } catch (error) {
      onError('Error starting stream: $error');
    }
  }

// Buffer to store incomplete messages
  String _buffer = '';

  void _processChunk(
    String chunk,
    Function(PortalResponse) onNewResponse,
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
          // Stream finished
          cancelCurrentStream();
          onClose();
        } else {
          try {
            final jsonResponse = jsonDecode(data);
            final portalResponse = PortalResponse.fromJson(jsonResponse);
            onNewResponse(portalResponse);
          } catch (e) {
            onError('Error processing stream data: $e');
          }
        }
      }
    }
  }

  void cancelCurrentStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  Future<PortalResponse> getEndpoint({
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

    return PortalResponse.fromJson(jsonDecode(response.body));
  }

  void streamPortal({
    required String portalId,
    String? userId,
    required Map<String, String> filledVariables,
    required List<ChatMessage> messages,
    required Function(PortalResponse) onNewResponse,
    required Function() onClose,
    required Function(dynamic) onError,
  }) {
    streamEndpoint(
      endpoint: 'portal',
      id: portalId,
      userId: userId,
      filledVariables: filledVariables,
      messages: messages,
      onNewResponse: onNewResponse,
      onClose: onClose,
      onError: onError,
    );
  }

  Future<PortalResponse> getPortal({
    required String portalId,
    String? userId,
    required Map<String, String> filledVariables,
    required List<ChatMessage> messages,
  }) async {
    return await getEndpoint(
      endpoint: 'portal',
      id: portalId,
      userId: userId,
      filledVariables: filledVariables,
      messages: messages,
    );
  }

  Future<void> streamWorkflow({
    required String workflowId,
    String? userId,
    required Map<String, String> filledVariables,
    required List<ChatMessage> messages,
    required Function(PortalResponse) onNewResponse,
    required Function() onClose,
    required Function(dynamic) onError,
  }) async {
    streamEndpoint(
      endpoint: 'workflow',
      id: workflowId,
      userId: userId,
      filledVariables: filledVariables,
      messages: messages,
      onNewResponse: onNewResponse,
      onClose: onClose,
      onError: onError,
    );
  }

  Future<PortalResponse> getWorkflow({
    required String workflowId,
    String? userId,
    required Map<String, String> filledVariables,
    required List<ChatMessage> messages,
  }) async {
    return await getEndpoint(
      endpoint: 'workflow',
      id: workflowId,
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
