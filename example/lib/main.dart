import 'package:flutter/material.dart';
import 'package:easybeam_flutter/easybeam_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mental Health App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const JournalPage(),
    );
  }
}

class JournalPage extends StatefulWidget {
  const JournalPage({Key? key}) : super(key: key);

  @override
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final TextEditingController _journalController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _selectedMood = 'Neutral';
  final List<String> _moodOptions = [
    'Happy',
    'Excited',
    'Neutral',
    'Sad',
    'Angry',
    'Anxious'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMood,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMood = newValue!;
                });
              },
              items: _moodOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Current Mood',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _journalController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Write your thoughts here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdvicePage(
                        journalEntry: _journalController.text,
                        age: _ageController.text,
                        mood: _selectedMood,
                      ),
                    ),
                  );
                },
                child: const Text('Get Advice'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdvicePage extends StatefulWidget {
  final String journalEntry;
  final String age;
  final String mood;

  const AdvicePage({
    Key? key,
    required this.journalEntry,
    required this.age,
    required this.mood,
  }) : super(key: key);

  @override
  _AdvicePageState createState() => _AdvicePageState();
}

class _AdvicePageState extends State<AdvicePage> {
  late final Easybeam easybeam;
  String _streamingResponse = '';
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    final apiToken = dotenv.env['EASYBEAM_API_TOKEN']!;
    easybeam = Easybeam(EasyBeamConfig(token: apiToken));
    _streamAdvice();
  }

  void _streamAdvice() async {
    setState(() {
      _isStreaming = true;
      _streamingResponse = '';
    });

    try {
      final workflowId = dotenv.env['EASYBEAM_WORKFLOW_ID']!;
      easybeam.streamWorkflow(
        workflowId: workflowId,
        userId: 'example-user-id',
        filledVariables: {
          "age": widget.age,
          "userlocation": "germany",
          "journal": widget.journalEntry,
          "mood": widget.mood
        },
        messages: [],
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
        title: const Text('Advice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _streamAdvice,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advice:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_streamingResponse),
              ),
            ),
            if (_isStreaming)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
