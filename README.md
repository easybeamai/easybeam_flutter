# Easybeam Flutter SDK

[![Build and Test](https://github.com/easybeamai/easybeam_flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/easybeamai/easybeam_flutter/actions)

Easybeam Flutter SDK is a powerful and flexible library for integrating Easybeam AI functionality into your Flutter applications. This SDK provides seamless access to Easybeam's AI-powered chat capabilities, supporting both streaming and non-streaming interactions with prompts and agents.

## Features

- **Prompt and Agent Integration**: Easily interact with Easybeam prompts and agents.
- **Streaming Support**: Real-time streaming of AI responses for interactive experiences.
- **Non-Streaming Requests**: Traditional request-response pattern for simpler interactions.
- **Flexible Configuration**: Customize the SDK behavior to fit your application needs.
- **Error Handling**: Robust error handling for reliable integration.
- **Review Submission**: Built-in functionality to submit user reviews.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  easybeam_flutter: ^2.0.0
```

Then run:

```
flutter pub get
```

## Usage

### Initialization

First, import the package and create an instance of Easybeam:

```dart
import 'package:easybeam_flutter/easybeam_flutter.dart';

final easybeam = Easybeam(EasyBeamConfig(token: 'your_api_token_here'));
```

### Streaming Interaction

To start a streaming interaction with a prompt:

```dart
final cancelFunction = easybeam.streamPrompt(
  promptId: 'your_prompt_id',
  filledVariables: {'key': 'value'},
  messages: [
    ChatMessage(
      content: 'Hello, AI!',
      role: ChatRole.USER,
      createdAt: ChatMessage.getCurrentTimestamp(),
      id: '1',
    ),
  ],
  onNewResponse: (response) {
    print('New message: ${response.newMessage.content}');
  },
  onClose: () {
    print('Stream closed');
  },
  onError: (error) {
    print('Error: $error');
  },
);

// To cancel the stream later:
cancelFunction();
```

### Non-Streaming Interaction

For a simple request-response interaction:

```dart
try {
  final response = await easybeam.getPrompt(
    promptId: 'your_prompt_id',
    filledVariables: {'key': 'value'},
    messages: [
      ChatMessage(
        content: 'Hello, AI!',
        role: ChatRole.USER,
        createdAt: ChatMessage.getCurrentTimestamp(),
        id: '1',
      ),
    ],
  );
  print('AI response: ${response.newMessage.content}');
} catch (e) {
  print('Error: $e');
}
```

### Submitting a Review

To submit a review for a chat interaction:

```dart
await easybeam.review(
  chatId: 'your_chat_id',
  userId: 'user123',
  reviewScore: 5,
  reviewText: 'Great experience!',
);
```

## Advanced Usage

### Custom HTTP Client

You can inject a custom HTTP client for more control over network requests:

```dart
import 'package:http/http.dart' as http;

final customClient = http.Client();
easybeam.injectHttpClient(customClient);
```

### Cleanup

When you're done with the Easybeam instance, make sure to dispose of it to clean up resources:

```dart
easybeam.dispose();
```

## Error Handling

The SDK provides detailed error messages. Always wrap API calls in try-catch blocks for proper error handling.

## Notes

- Ensure you have a valid Easybeam API token before using the SDK.
- The SDK uses Server-Sent Events (SSE) for streaming, which may have implications for backend compatibility and network configurations.
- For production applications, consider implementing proper token management and security practices.

## Contributing

Contributions to the Easybeam Flutter SDK are welcome! Please refer to the contributing guidelines for more information.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please contact hello@easybeam.ai or visit our [documentation](https://docs.easybeam.ai).
