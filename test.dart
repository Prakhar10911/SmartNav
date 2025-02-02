import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tuple/tuple.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maze Solver',
      home: InputPage(),
    );
  }
}

class InputPage extends StatefulWidget {
  @override
  _InputPageState createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  TextEditingController startRowController = TextEditingController();
  TextEditingController startColController = TextEditingController();
  TextEditingController endRowController = TextEditingController();
  TextEditingController endColController = TextEditingController();

  final SpeechToText _speechToText = SpeechToText();
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    bool speechEnabled = await _speechToText.initialize();
    if (speechEnabled) {
      _startListening();
    }
  }

  void _startListening() async {
    setState(() {
      _listening = true;
    });

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenMode: ListenMode.confirmation,
      localeId: 'en_US',
    );

    if (_listening) {
      _startListening();
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    String recognizedWords = result.recognizedWords.toLowerCase();

    if (recognizedWords.contains('solve')) {
      _solveMaze();
    } else {
      int? number = int.tryParse(recognizedWords);
      if (number != null && number >= 0 && number <= 5) {
        _updateTextBox(number);
      }
    }
  }

  void _updateTextBox(int spokenNumber) {
    final int parsedNumber = spokenNumber;

    if (parsedNumber >= 1 && parsedNumber <= 5) {
      FocusNode currentFocus = FocusScope.of(context).focusedChild ?? FocusNode();
      if (currentFocus == startRowController) {
        startRowController.text = parsedNumber.toString();
      } else if (currentFocus == startColController) {
        startColController.text = parsedNumber.toString();
      } else if (currentFocus == endRowController) {
        endRowController.text = parsedNumber.toString();
      } else if (currentFocus == endColController) {
        endColController.text = parsedNumber.toString();
      }
    }
  }

  void _solveMaze() {
    int startRow = int.tryParse(startRowController.text) ?? 0;
    int startCol = int.tryParse(startColController.text) ?? 0;
    int endRow = int.tryParse(endRowController.text) ?? 0;
    int endCol = int.tryParse(endColController.text) ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MazeResultPage(
          startRow: startRow,
          startCol: startCol,
          endRow: endRow,
          endCol: endCol,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maze Solver - Input'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Start Position"),
            TextField(
              controller: startRowController,
              decoration: InputDecoration(labelText: 'Row'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: startColController,
              decoration: InputDecoration(labelText: 'Column'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            Text("End Position"),
            TextField(
              controller: endRowController,
              decoration: InputDecoration(labelText: 'Row'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: endColController,
              decoration: InputDecoration(labelText: 'Column'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _solveMaze,
              child: Text('Solve Maze'),
            ),
            _listening
                ? Text('Listening...')
                : ElevatedButton(
              onPressed: () {
                if (!_listening) {
                  _startListening();
                }
              },
              child: Text('Start Listening'),
            ),
          ],
        ),
      ),
    );
  }
}

class MazeResultPage extends StatelessWidget {
  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;

  MazeResultPage({
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maze Solver - Result'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Start Position: $startRow, $startCol"),
            Text("End Position: $endRow, $endCol"),
            SizedBox(height: 20),
            MazeSolver(
              startRow: startRow,
              startCol: startCol,
              endRow: endRow,
              endCol: endCol,
            ),
          ],
        ),
      ),
    );
  }
}

class MazeSolver extends StatefulWidget {
  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;

  MazeSolver({
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
  });

  @override
  _MazeSolverState createState() => _MazeSolverState();
}

class _MazeSolverState extends State<MazeSolver> {
  List<List<int>> maze = [
    [1, 0, 1, 0, 1],
    [1, 1, 1, 1, 1],
    [0, 1, 0, 1, 0],
    [1, 1, 0, 1, 1],
    [0, 1, 1, 1, 1],
  ];

  List<List<bool>> visited = List.generate(5, (i) => List<bool>.filled(5, false));

  List<Tuple2<int, int>> shortestPath = [];
  List<String> directions = [];

  @override
  void initState() {
    super.initState();
    shortestPath = aStar(widget.startRow, widget.startCol, widget.endRow, widget.endCol);
    if (shortestPath.isEmpty) {
      // Show a dialog indicating no path is available
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('No Path Found'),
              content: Text('There is no valid path from the start to the end.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      });
    } else {
      directions = calculateDirections(shortestPath);
    }
  }

  List<String> calculateDirections(List<Tuple2<int, int>> path) {
    List<String> directions = [];

    for (int i = 0; i < path.length - 1; i++) {
      int rowDiff = path[i + 1].item1 - path[i].item1;
      int colDiff = path[i + 1].item2 - path[i].item2;

      if (rowDiff == 1) {
        directions.add('d'); // down
      } else if (rowDiff == -1) {
        directions.add('u'); // up
      } else if (colDiff == 1) {
        directions.add('r'); // right
      } else if (colDiff == -1) {
        directions.add('l'); // left
      }
    }

    return directions;
  }

  List<Tuple2<int, int>> aStar(int startRow, int startCol, int endRow, int endCol) {
    List<Node> openSet = [];
    List<List<Node>> nodes = List.generate(5, (i) => List<Node>.filled(5, Node(row: i, col: 0)));

    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        nodes[i][j] = Node(row: i, col: j);
      }
    }

    Node startNode = nodes[startRow][startCol];
    Node endNode = nodes[endRow][endCol];

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
        if (maze[neighbor.row][neighbor.col] == 1 && !visited[neighbor.row][neighbor.col]) {
          int tentativeG = current.g + 1;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomPaint(
          size: Size(200, 200),
          painter: MazePainter(shortestPath, directions),
        ),
        SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
          ),
          itemBuilder: (context, index) {
            int i = index ~/ 5;
            int j = index % 5;
            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                color: maze[i][j] == 1 ? Colors.white : Colors.black,
              ),
              child: shortestPath.contains(Tuple2<int, int>(i, j))
                  ? Center(
                child: Text(
                  'X',
                  style: TextStyle(color: Colors.red),
                ),
              )
                  : SizedBox(),
            );
          },
          itemCount: 25,
        ),
        SizedBox(height: 20),
        Text(
          'Directions: ${directions.join(" ")}',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}

class MazePainter extends CustomPainter {
  final List<Tuple2<int, int>> path;
  final List<String> directions;

  MazePainter(this.path, this.directions);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;

    for (int i = 0; i < path.length - 1; i++) {
      canvas.drawLine(
        Offset(path[i].item2 * 40 + 20, path[i].item1 * 40 + 20),
        Offset(path[i + 1].item2 * 40 + 20, path[i + 1].item1 * 40 + 20),
        paint,
      );

      // Draw arrows based on directions
      drawArrows(canvas, path[i], path[i + 1], directions[i]);
    }
  }
  void drawArrows(Canvas canvas, Tuple2<int, int> start, Tuple2<int, int> end, String direction) {
    Paint arrowPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    double startX = start.item2 * 40 + 20;
    double startY = start.item1 * 40 + 20;
    double endX = end.item2 * 40 + 20;
    double endY = end.item1 * 40 + 20;

    double arrowSize = 10;

    // Draw a line for the arrow
    canvas.drawLine(
      Offset(startX, startY),
      Offset(endX, endY),
      arrowPaint,
    );

    // Draw the arrowhead
    switch (direction) {
      case 'u':
        drawArrowhead(canvas, endX, endY, -arrowSize, arrowSize);
        break;
      case 'd':
        drawArrowhead(canvas, endX, endY, arrowSize, arrowSize);
        break;
      case 'l':
        drawArrowhead(canvas, endX, endY, -arrowSize, -arrowSize);
        break;
      case 'r':
        drawArrowhead(canvas, endX, endY, arrowSize, -arrowSize);
        break;
    }
  }

  void drawArrowhead(Canvas canvas, double x, double y, double dx, double dy) {
    Paint arrowPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(x, y),
      Offset(x + dx, y + dy),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
class Node implements Comparable<Node> {
  int row;
  int col;
  int g; // Cost from start node to current node
  int h; // Heuristic (estimated cost from current node to end node)
  Node? parent;

  Node({required this.row, required this.col, this.g = 0, this.h = 0, this.parent});

  @override
  int compareTo(Node other) {
    return (g + h).compareTo(other.g + other.h);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Node && other.row == row && other.col == col;
  }

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}