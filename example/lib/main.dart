import 'package:flutter/material.dart';
import 'package:easybeam_flutter/easybeam_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example Chat',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class StarRating extends StatelessWidget {
  final int rating;
  final Function(int) onRatingChanged;
  final double size;

  const StarRating({
    Key? key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 32.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: size,
          ),
          onPressed: () => onRatingChanged(index + 1),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          constraints: BoxConstraints(minWidth: size, minHeight: size),
        );
      }),
    );
  }
}

class _ChatPageState extends State<ChatPage> {
  int _rating = 0;
  bool _showRating = false;
  final TextEditingController _messageController = TextEditingController();
  String _selectedMood = 'Neutral';
  final List<String> _moodOptions = [
    'Happy',
    'Excited',
    'Neutral',
    'Sad',
    'Angry',
    'Anxious'
  ];
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitializing = true;
  late final Easybeam easybeam;
  final _uuid = const Uuid();
  String? _chatID;

  @override
  void initState() {
    super.initState();
    final apiToken = dotenv.env['EASYBEAM_API_TOKEN']!;
    easybeam = Easybeam(EasyBeamConfig(token: apiToken));
    _triggerWorkflow();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      content: _messageController.text,
      role: ChatRole.USER,
      createdAt: ChatMessage.getCurrentTimestamp(),
      id: _uuid.v4(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();

    _triggerWorkflow();
  }

  void _triggerWorkflow() async {
    try {
      easybeam.streamPortal(
        portalId: 'B1lQC0',
        userId: 'example-user-id',
        filledVariables: {
          "exampleClient": exampleClient,
          "exampleCompany": exampleCompany,
          "examplePipeline": examplePipeline,
          "exampleSalesRep": exampleSalesRep
        },
        messages: _messages,
        onNewResponse: (PortalResponse response) {
          setState(() {
            _chatID = response.chatId;
            if (_messages.isNotEmpty && _messages.last.role == ChatRole.AI) {
              _messages.last = ChatMessage(
                content: response.newMessage.content,
                role: ChatRole.AI,
                createdAt: ChatMessage.getCurrentTimestamp(),
                id: _uuid.v4(),
              );
            } else {
              _messages.add(ChatMessage(
                content: response.newMessage.content,
                role: ChatRole.AI,
                createdAt: ChatMessage.getCurrentTimestamp(),
                id: _uuid.v4(),
              ));
              if (_isInitializing) {
                _isInitializing = false;
                _showRating = true; // Show rating after first message
              }
            }
          });
        },
        onClose: () {
          setState(() {
            _isLoading = false;
          });
        },
        onError: (error) {
          setState(() {
            _messages.add(ChatMessage(
              content: 'Error: $error',
              role: ChatRole.AI,
              createdAt: ChatMessage.getCurrentTimestamp(),
              id: _uuid.v4(),
            ));
            _isLoading = false;
            _isInitializing = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          content: 'Error: $e',
          role: ChatRole.AI,
          createdAt: ChatMessage.getCurrentTimestamp(),
          id: _uuid.v4(),
        ));
        _isLoading = false;
        _isInitializing = false;
      });
    }
  }

  Widget _buildRatingWidget() {
    if (!_showRating) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Text(
            'How helpful was this response?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          StarRating(
            rating: _rating,
            onRatingChanged: (rating) {
              setState(() {
                _rating = rating;
              });
              easybeam.review(
                  chatId: _chatID!, userId: "example", reviewScore: rating);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading conversation...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Example Chat'),
        actions: [
          DropdownButton<String>(
            value: _selectedMood,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedMood = newValue;
                });
              }
            },
            items: _moodOptions.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            style: const TextStyle(color: Colors.white),
            dropdownColor: Colors.green,
            underline: Container(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.role == ChatRole.USER
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.role == ChatRole.USER
                          ? Colors.green[100]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateTime.parse(message.createdAt)
                              .toLocal()
                              .toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildRatingWidget(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// JSON Example strings of local data
const String exampleClient = '''
{
  "clientId": "CLI-2024-001",
  "firstName": "Jane",
  "lastName": "Doe",
  "title": "Chief Technology Officer",
  "email": "jane.doe@techforward.com",
  "phone": "+1-617-555-0123",
  "linkedIn": "linkedin.com/in/janedoe",
  "companyId": "COMP-2024-001",
  "preferredContactMethod": "email",
  "communicationStyle": "direct",
  "timezone": "America/New_York",
  "personalNotes": "Prefers early morning meetings, technical background",
  "status": "active",
  "createdAt": "2024-01-15T09:00:00Z",
  "lastUpdated": "2024-04-20T08:30:00Z"
}''';

const String exampleCompany = '''
{
  "companyId": "COMP-2024-001",
  "name": "TechForward Solutions",
  "industry": "Enterprise Software",
  "annualRevenue": "\$50M-\$100M",
  "employeeCount": 248,
  "headquarters": {
    "street": "123 Innovation Drive",
    "city": "Boston",
    "state": "MA",
    "country": "USA",
    "postalCode": "02110"
  },
  "offices": ["Boston", "Austin", "Toronto"],
  "website": "techforwardsolutions.com",
  "currentTechStack": ["Java", "AWS", "MongoDB"],
  "companyStage": "GROWTH",
  "fundingStatus": "Series C",
  "keyMetrics": {
    "growthRate": "25%",
    "customerCount": 150,
    "churnRate": "5%"
  },
  "status": "active",
  "createdAt": "2024-01-15T09:00:00Z",
  "lastUpdated": "2024-04-20T08:30:00Z"
}''';

const String examplePipeline = '''
{
  "pipelineId": "PIP-2024-001",
  "companyId": "COMP-2024-001",
  "primaryContactId": "CLI-2024-001",
  "salesRepId": "REP-2024-001",
  "currentStage": "TECHNICAL_EVALUATION",
  "stageHistory": [
    {
      "stage": "LEAD_QUALIFICATION",
      "enteredAt": "2024-01-15T09:00:00Z",
      "completedAt": "2024-01-28T16:30:00Z",
      "completedBy": "REP-2024-001"
    },
    {
      "stage": "DISCOVERY",
      "enteredAt": "2024-01-28T16:30:00Z",
      "completedAt": "2024-02-20T11:15:00Z",
      "completedBy": "REP-2024-001"
    },
    {
      "stage": "TECHNICAL_EVALUATION",
      "enteredAt": "2024-02-20T11:15:00Z",
      "completedAt": null,
      "completedBy": null
    }
  ],
  "actions": [
    {
      "actionId": "ACT-001",
      "type": "DEMO_PRODUCT",
      "date": "2024-01-30T15:00:00Z",
      "performedBy": "REP-2024-001",
      "attendees": ["CLI-2024-001"],
      "status": "COMPLETED",
      "notes": "Demonstrated core product features",
      "outcomes": [
        "Client impressed with UI/UX",
        "Requested technical documentation"
      ]
    },
    {
      "actionId": "ACT-002",
      "type": "SHOW_KPIS",
      "date": "2024-02-15T14:00:00Z",
      "performedBy": "REP-2024-001",
      "attendees": ["CLI-2024-001"],
      "status": "COMPLETED",
      "notes": "Presented key performance metrics",
      "outcomes": [
        "Highlighted ROI potential",
        "Discussed implementation timeline"
      ]
    }
  ],
  "requirements": {
    "budget": 500000,
    "timeframe": "Q3 2024",
    "technicalNeeds": [
      "API integration",
      "Custom reporting",
      "SSO implementation"
    ]
  },
  "probability": 75,
  "expectedDealSize": 450000,
  "expectedCloseDate": "2024-06-30",
  "status": "active",
  "createdAt": "2024-01-15T09:00:00Z",
  "lastUpdated": "2024-04-20T08:30:00Z"
}''';

const String exampleSalesRep = '''
{
  "salesRepId": "REP-2024-001",
  "firstName": "John",
  "lastName": "Seller",
  "email": "john.seller@ourcompany.com",
  "phone": "+1-617-555-9876",
  "title": "Senior Account Executive",
  "territory": "Northeast",
  "specializations": ["Enterprise", "Technical Sales"],
  "quotaAttainment": 0.85,
  "activeDeals": 12,
  "performanceMetrics": {
    "avgDealSize": 380000,
    "winRate": 0.65,
    "avgSalesCycle": 90
  },
  "status": "active",
  "createdAt": "2023-01-01T09:00:00Z",
  "lastUpdated": "2024-04-20T08:30:00Z"
}''';
