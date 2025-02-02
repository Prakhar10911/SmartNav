
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'login_page.dart';

void main() {
  runApp(const MyApp());
}

FlutterTts flutterTts = FlutterTts(); // Create a FlutterTts instance

Future<void> speakDirections(String directions, {double speed = 0.4}) async {
  await flutterTts.setSpeechRate(speed);
  await flutterTts.speak(directions);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Maze Solver',
      home: InputPage(),
    );
  }
}

class InputPage extends StatefulWidget {
  const InputPage({Key? key}) : super(key: key);

  @override
  _InputPageState createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  TextEditingController startLocationController = TextEditingController();
  TextEditingController endLocationController = TextEditingController();

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _listening = false;

  // List of available locations for the dropdown
  List<String> availableLocations = [
    'start',
    'end',
    'room 1',
    'room 2',
    'room 5',
    'lab ',
    'lift',
    'exit'
  ];

  // Selected values for the dropdown
  String selectedStartLocation = 'start';
  String selectedEndLocation = 'end';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    speakInitialMessage();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (_speechEnabled) {
      _startListening();
    }
  }

  void speakInitialMessage() {
    const String initialMessage = "Please enter or speak start and end locations.";
    speakDirections(initialMessage,speed : 0.4);
  }

  void _startListening() async {
    setState(() {
      _listening = true;
    });

    while (_listening) {
      await _speechToText.listen(
        onResult: _onSpeechResult,
      );

      if (!_listening) {
        break;
      }
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    print("Recognized words: $_lastWords");

    _updateTextFields(result.recognizedWords);

    if (_lastWords.toLowerCase().contains('find')) {
      _stopListening();
      _solveMaze();
    }
  }

  void _updateTextFields(String recognizedWords) {
    final RegExp regExp = RegExp(
        r'\b(?:room\s*1|room\s*2|room\s*5|exit|start|lab|lift|find)\b',
        caseSensitive: false);
    final List<String> words = regExp
        .allMatches(recognizedWords)
        .map((match) => match.group(0)!)
        .toList();

    print("Recognized words: $words");

    if (words.isNotEmpty) {
      final String location = words.join('');

      if (startLocationController.text.isEmpty) {
        startLocationController.text = location;
      } else if (endLocationController.text.isEmpty) {
        endLocationController.text = location;
      }
    }
  }

  void _solveMaze() {
    _stopListening(); // Stop listening when the solve button is pressed
    String startLocation = startLocationController.text;
    String endLocation = endLocationController.text;
    // Check if start and end locations are empty
    if (startLocation.isEmpty && endLocation.isEmpty) {
      // Notify user to enter the start location
      _speakErrorMessage("Please enter the start and end location.");
      return;
    }

    if (startLocation.isEmpty) {
      // Notify user to enter the start location
      _speakErrorMessage("Please enter the start location.");
      return;
    }


    if (endLocation.isEmpty) {
      // Notify user to enter the end location
      _speakErrorMessage("Please enter the end location.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MazeResultPage(
          startLocation: startLocation,
          endLocation: endLocation,
        ),
      ),
    ).then((value) {
      if (value != null) {
      }
    });
  }

  void _speakErrorMessage(String message) {
    // Speak the error message using FlutterTts
    speakDirections(message);
  }

  void _stopListening() async {
    if (_listening) {
      await _speechToText.stop();
      setState(() {
        _listening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('SmartNav'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Start Location",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Text field for manual input
              TextField(
                controller: startLocationController,
                decoration: const InputDecoration(labelText: 'Location'),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              const Text(
                "End Location",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Text field for manual input
              TextField(
                controller: endLocationController,
                decoration: const InputDecoration(labelText: 'Location'),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              // Dropdown menu for selecting start location
              DropdownButton<String>(
                value: selectedStartLocation,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedStartLocation = newValue;
                      startLocationController.text = newValue;
                    });
                  }
                },
                items: availableLocations.map((String location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Dropdown menu for selecting end location
              DropdownButton<String>(
                value: selectedEndLocation,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedEndLocation = newValue;
                      endLocationController.text = newValue;
                    });
                  }
                },
                items: availableLocations.map((String location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _solveMaze,
                child: const Text('Find Path'),
              ),
              _listening
                  ? const Text('Listening...')
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  if (!_listening) {
                    _startListening();
                  }
                },
                child: const Text('Start Listening'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white38, // Change the color as needed
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  // Open the login page when the button is pressed
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('Register Map'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MazeResultPage extends StatelessWidget {
  final String startLocation;
  final String endLocation;

  const MazeResultPage({
    Key? key,
    required this.startLocation,
    required this.endLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartNav - Result'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Start Location: $startLocation"),
            Text("End Location: $endLocation"),
            const SizedBox(height: 4),
            MazeSolver(
              startLocation: startLocation,
              endLocation: endLocation,
            ),
          ],
        ),
      ),
    );
  }
}

class MazeSolver extends StatefulWidget {
  final String startLocation;
  final String endLocation;

  const MazeSolver({
    Key? key,
    required this.startLocation,
    required this.endLocation,
  }) : super(key: key);

  @override
  _MazeSolverState createState() => _MazeSolverState();
}

class _MazeSolverState extends State<MazeSolver> {
  List<List<String>> mazeLocations = [
    ["start", "", "Wall", "room 2", ""],
    ["Wall", "", "", "", "Wall"],
    ["", "Wall", "lab 1", "lift", ""],
    ["Wall", "", "room 1", "", ""],
    ["room 5", "", "Wall", "", "exit"],
  ];

  List<List<bool>> visited =
  List.generate(5, (i) => List<bool>.filled(5, false));

  List<Tuple2<int, int>> shortestPath = [];
  List<String> directions = [];

  List<String> storedDirections = []; //array for storing all the dir

  @override
  void initState() {
    super.initState();
    shortestPath = aStar(widget.startLocation, widget.endLocation);
    if (shortestPath.isEmpty ||
        mazeLocations[0][0] != "start" ||
        mazeLocations[4][4] != "exit") {
      // Show a dialog indicating no path is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('No Path Found'),
              content: const Text(
                  'There is no valid path from the start to the end.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      });
    } else {
      // Generate directions based on the shortest path
      generateDirections();
    }
  }

  void generateDirections() {
    StringBuffer directionBuffer = StringBuffer();
    String currentDirection = '';
    int stepCount = 0;

    for (int i = 0; i < shortestPath.length - 1; i++) {
      int currentRow = shortestPath[i].item1;
      int currentCol = shortestPath[i].item2;
      int nextRow = shortestPath[i + 1].item1;
      int nextCol = shortestPath[i + 1].item2;

      String direction = getDirection(currentRow, currentCol, nextRow, nextCol);

      if (currentDirection.isEmpty) {
        currentDirection = direction;
        stepCount = 5;
      } else if (currentDirection == direction) {
        stepCount += 5;
      } else {
        directionBuffer.write('$stepCount steps $currentDirection, ');
        currentDirection = direction;
        stepCount = 5;
      }
    }

    if (stepCount > 0) {
      directionBuffer.write('$stepCount steps $currentDirection');
    }

    String directionsString = directionBuffer.toString().trim();
    if (directionsString.isNotEmpty) {
      setState(() {
        directions = [directionsString];
        speakDirections(directionsString);
      });
    }
  }

  String getDirection(
      int currentRow, int currentCol, int nextRow, int nextCol) {
    if (currentRow < nextRow) {
      return 'Forward';
    } else if (currentRow > nextRow) {
      return 'Backward';
    } else if (currentCol < nextCol) {
      return 'Right';
    } else if (currentCol > nextCol) {
      return 'Left';
    }
    return '';
  }

  List<Tuple2<int, int>> aStar(String startLocation, String endLocation) {
    List<Node> openSet = [];
    List<List<Node>> nodes =
    List.generate(5, (i) => List<Node>.filled(5, Node(row: i, col: 0)));

    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        nodes[i][j] = Node(row: i, col: j);
      }
    }

    Node startNode = findLocation(startLocation, nodes);
    Node endNode = findLocation(endLocation, nodes);

    openSet.add(startNode);
    startNode.g = 0;
    startNode.h = heuristic(startNode, endNode);

    while (openSet.isNotEmpty) {
      openSet.sort();
      Node current = openSet.removeAt(0);

      if (current == endNode) {
        // Reconstruct path
        List<Tuple2<int, int>> path = [];
        Node? temp = current;
        while (temp != null) {
          path.add(Tuple2<int, int>(temp.row, temp.col));
          temp = temp.parent;
        }
        path = path.reversed.toList();
        return path;
      }

      visited[current.row][current.col] = true;

      for (Node neighbor in getNeighbors(current, nodes)) {
        int neighborValue =
        mazeLocations[neighbor.row][neighbor.col] == "Wall" ? 0 : 1;

        if (neighborValue == 1 && !visited[neighbor.row][neighbor.col]) {
          int tentativeG = current.g + neighborValue;

          if (openSet.contains(neighbor) && tentativeG >= neighbor.g) {
            continue;
          }

          neighbor.parent = current;
          neighbor.g = tentativeG;
          neighbor.h = heuristic(neighbor, endNode);

          if (!openSet.contains(neighbor)) {
            openSet.add(neighbor);
          }
        }
      }
    }

    return [];
  }

  int heuristic(Node a, Node b) {
    // Manhattan distance
    return (a.row - b.row).abs() + (a.col - b.col).abs();
  }

  List<Node> getNeighbors(Node node, List<List<Node>> nodes) {
    List<Node> neighbors = [];

    if (node.row > 0) neighbors.add(nodes[node.row - 1][node.col]);
    if (node.row < 4) neighbors.add(nodes[node.row + 1][node.col]);
    if (node.col > 0) neighbors.add(nodes[node.row][node.col - 1]);
    if (node.col < 4) neighbors.add(nodes[node.row][node.col + 1]);

    return neighbors;
  }

  Node findLocation(String location, List<List<Node>> nodes) {
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        if (mazeLocations[i][j] == location) {
          return nodes[i][j];
        }
      }
    }
    return nodes[0]
    [0]; // Default to the top-left corner if not found (should not happen)
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(
              size: const Size(172, 172),
              painter: MazePainter(shortestPath),
            ),
            const SizedBox(height: 7),
            const Text(
              'Directions to Reach Destination:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(directions.first), // Print directions in one line
            const SizedBox(height: 14),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
              ),
              itemBuilder: (context, index) {
                int i = index ~/ 5;
                int j = index % 5;
                bool isStart = mazeLocations[i][j] == "Start";
                bool isEnd = mazeLocations[i][j] == "End";
                bool isWall = mazeLocations[i][j] == "Wall";
                bool isPath = shortestPath.contains(Tuple2<int, int>(i, j));

                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    color: isWall
                        ? Colors.black
                        : (isPath ? Colors.greenAccent : Colors.white),
                  ),
                  child: Stack(
                    children: [
                      if (isStart)
                        const Center(
                          child: Icon(
                            Icons.location_on,
                          ),
                        ),
                      if (isEnd)
                        const Center(
                          child: Icon(
                            Icons.location_off,
                          ),
                        ),
                      if (!isWall) // Display the location name for non-wall locations
                        Center(
                          child: Text(
                            mazeLocations[i][j],
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isPath)
                        const Center(
                          child: Text(
                            'X',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
              itemCount: 25,
            ),
          ],
        ),
      ),
    );
  }
}

class MazePainter extends CustomPainter {
  final List<Tuple2<int, int>> path;

  MazePainter(this.path);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 5.0;

    double cellWidth = size.width / 5;
    double cellHeight = size.height / 5;

    // Draw maze grid
    for (int i = 1; i < 5; i++) {
      canvas.drawLine(
          Offset(0, i * cellHeight), Offset(size.width, i * cellHeight), paint);
      canvas.drawLine(
          Offset(i * cellWidth, 0), Offset(i * cellWidth, size.height), paint);
    }

    // Highlight the path
    for (int i = 0; i < path.length - 1; i++) {
      double startX = path[i].item2 * cellWidth + cellWidth / 2;
      double startY = path[i].item1 * cellHeight + cellHeight / 2;
      double endX = path[i + 1].item2 * cellWidth + cellWidth / 2;
      double endY = path[i + 1].item1 * cellHeight + cellHeight / 2;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class Node implements Comparable<Node> {
  final int row;
  final int col;
  int g; // cost from start
  int h; // heuristic (Manhattan distance to end)
  Node? parent;

  Node({
    required this.row,
    required this.col,
    this.g = 0,
    this.h = 0,
    this.parent,
  });

  int get f => g + h;

  @override
  int compareTo(Node other) {
    return f - other.f;
  }
}