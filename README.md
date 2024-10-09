# Easybeam Flutter SDK

A Flutter SDK for integrating with the Easybeam AI platform.

## Features

- Stream responses from Easybeam portals and workflows
- Make non-streaming requests to portals and workflows
- Handle user reviews for chat interactions

## Getting started

To use this package, add `easybeam_flutter` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  easybeam_flutter: ^0.0.1
```

## Usage

Here's a simple example of how to use the Easybeam Flutter SDK:

```dart
import 'package:easybeam_flutter/easybeam_flutter.dart';

void main() async {
  final easybeam = Easybeam(EasyBeamConfig(token: 'your-api-token'));

  final portalResponse = await easybeam.getPortal(
    portalId: 'your-portal-id',
    userId: 'user-123',
    filledVariables: {'key': 'value'},
    messages: [
      ChatMessage(
        content: 'Hello',
        role: ChatRole.USER,
        createdAt: DateTime.now().toIso8601String(),
        id: '1',
      ),
    ],
  );

  print('Portal response: ${portalResponse.newMessage.content}');
}
```

For more detailed usage instructions, please refer to the API documentation.

## Additional information

For more information about Easybeam and its capabilities, visit [https://easybeam.ai](https://easybeam.ai).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
# easybeam_flutter
