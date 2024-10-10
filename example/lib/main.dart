import 'package:flutter/material.dart';
import 'package:easybeam_flutter/easybeam_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easybeam Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Easybeam Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final Easybeam easybeam;
  String _response = 'No response yet';
  String _streamingResponse = '123';
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    final apiToken = dotenv.env['EASYBEAM_API_TOKEN'] ?? 'default_token';
    easybeam = Easybeam(EasyBeamConfig(token: apiToken));
  }

  void _getPortalResponse() async {
    try {
      final portalId = dotenv.env['EASYBEAM_PORTAL_ID'] ?? 'default_portal_id';
      final portalResponse = await easybeam.getPortal(
        portalId: portalId,
        userId: 'example-user-id',
        filledVariables: {'animal': 'cat'},
        messages: [
          ChatMessage(
            content: 'Tell me a story about a cat.',
            role: ChatRole.USER,
            createdAt: ChatMessage.getCurrentTimestamp(),
            id: '1',
          ),
        ],
      );

      setState(() {
        _response = portalResponse.newMessage.content;
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    }
  }

  void _streamPortalResponse() async {
    setState(() {
      _isStreaming = false;
      _streamingResponse = '';
    });

    try {
      final portalId = dotenv.env['EASYBEAM_PORTAL_ID'] ?? 'default_portal_id';
      easybeam.streamPortal(
        portalId: portalId,
        userId: 'example-user-id',
        filledVariables: {'animal': 'cat'},
        messages: [
          ChatMessage(
            content: 'Tell me a story about a cat',
            role: ChatRole.USER,
            createdAt: ChatMessage.getCurrentTimestamp(),
            id: '1',
          ),
        ],
        onNewResponse: (PortalResponse response) {
          setState(() {
            _streamingResponse = response.newMessage.content;
          });
        },
        onClose: () {
          setState(() {
            _isStreaming = false;
          });
        },
        onError: (error) {
          setState(() {
            _streamingResponse = 'Error: $error';
            _isStreaming = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _streamingResponse = 'Error: $e';
        _isStreaming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Non-streaming response:',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    SizedBox(height: 8),
                    Text(_response),
                    SizedBox(height: 20),
                    Text(
                      'Streaming response:',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    SizedBox(height: 8),
                    Text(_streamingResponse),
                  ],
                ),
              ),
            ),
          ),
          if (_isStreaming)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _getPortalResponse,
            tooltip: 'Get Response',
            child: Icon(Icons.chat),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _isStreaming ? null : _streamPortalResponse,
            tooltip: 'Stream Response',
            child: Icon(Icons.stream),
            backgroundColor: _isStreaming ? Colors.grey : null,
          ),
        ],
      ),
    );
  }
}
