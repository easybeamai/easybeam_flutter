# Easybeam Flutter SDK

[![Build and Test](https://github.com/easybeamai/easybeam_flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/easybeamai/easybeam_flutter/actions)

Easybeam Flutter SDK is a powerful and flexible library for integrating Easybeam AI functionality into your Flutter applications. This SDK provides seamless access to Easybeam's AI-powered chat capabilities, supporting both streaming and non-streaming interactions with prompts and agents, along with secure credential handling for agent integrations.

## Features

- **Advanced Agent Integration**: Securely interact with Easybeam agents using protected credentials
- **Prompt Management**: Efficiently work with Easybeam prompts for simpler AI interactions
- **Streaming Support**: Real-time streaming of AI responses for interactive experiences
- **Non-Streaming Requests**: Traditional request-response pattern for simpler interactions
- **Flexible Configuration**: Customize the SDK behavior to fit your application needs
- **Error Handling**: Robust error handling for reliable integration
- **Review Submission**: Built-in functionality to submit user reviews

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  easybeam_flutter: ^2.1.0
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

### Working with Agents

Agents provide advanced AI capabilities and can integrate with external services. Here's how to use them:

#### Streaming Agent Interaction

```dart
final userSecrets = {'apiKey': 'your-sensitive-api-key'};

final cancelFunction = easybeam.streamAgent(
  agentId: 'your_agent_id',
  userId: 'user123',
  filledVariables: {'language': 'english'},
  userSecrets: userSecrets,  // Optional secure credentials
  messages: [
    ChatMessage(
      content: 'Analyze the market data for Q2',
      role: ChatRole.USER,
      createdAt: ChatMessage.getCurrentTimestamp(),
      id: '1',
    ),
  ],
  onNewResponse: (response) {
    print('Agent response: ${response.newMessage.content}');
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

#### Non-Streaming Agent Interaction

```dart
try {
  final response = await easybeam.getAgent(
    agentId: 'your_agent_id',
    userId: 'user123',
    filledVariables: {'language': 'english'},
    userSecrets: {'apiKey': 'your-sensitive-api-key'},  // Optional secure credentials
    messages: [
      ChatMessage(
        content: 'Generate a sales report',
        role: ChatRole.USER,
        createdAt: ChatMessage.getCurrentTimestamp(),
        id: '1',
      ),
    ],
  );
  print('Agent response: ${response.newMessage.content}');
} catch (e) {
  print('Error: $e');
}
```

### Working with Prompts

For simpler AI interactions, you can use prompts:

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
```

### Submitting Reviews

To submit a review for any chat interaction:

```dart
await easybeam.review(
  chatId: 'your_chat_id',
  userId: 'user123',
  reviewScore: 5,
  reviewText: 'Great experience!',
);
```

## Advanced Configuration

### Custom HTTP Client

You can inject a custom HTTP client for more control over network requests:

```dart
import 'package:http/http.dart' as http;

final customClient = http.Client();
easybeam.injectHttpClient(customClient);
```

### Resource Management

When you're done with the Easybeam instance, dispose of it to clean up resources:

```dart
easybeam.dispose();
```

## Security Considerations

- Store sensitive credentials securely and only pass them through the `userSecrets` parameter when required
- Implement proper token management for the Easybeam API token
- Review and handle sensitive data appropriately in your application
- Consider implementing additional encryption for sensitive credentials in transit

## Error Handling

The SDK provides comprehensive error handling. Always implement try-catch blocks around API calls and provide appropriate error handling in stream callbacks.

## Notes

- Ensure you have a valid Easybeam API token before using the SDK
- The SDK uses Server-Sent Events (SSE) for streaming functionality
- Consider network conditions and implement appropriate timeout handling
- Implement proper security measures when handling sensitive credentials

## Contributing

Contributions to the Easybeam Flutter SDK are welcome! Please refer to the contributing guidelines for more information.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please contact hello@easybeam.ai or visit our [documentation](https://docs.easybeam.ai).
