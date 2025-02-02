
import 'package:flutter/material.dart';

class YourMapPage extends StatefulWidget {
  const YourMapPage({Key? key}) : super(key: key);

  @override
  _YourMapPageState createState() => _YourMapPageState();
}

class _YourMapPageState extends State<YourMapPage> {
  List<List<String>> grid = List.generate(5, (i) => List<String>.filled(5, ''));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Map',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 20.0,
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 3,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: 25,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final int row = index ~/ 5;
                  final int col = index % 5;
                  final String location = grid[row][col];

                  return ElevatedButton(
                    onPressed: () {
                      _showLocationDialog(row, col);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getColorForLocation(location),
                      padding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      location.isNotEmpty ? location : 'Empty',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            ElevatedButton(
              onPressed: _submitMap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForLocation(String location) {
    switch (location) {
      case 'Room':
        return Colors.blue;
      case 'Lift':
        return Colors.green;
      case 'Exit':
        return Colors.red;
      case 'Washroom':
        return Colors.purple;
      case 'Path':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  void _showLocationDialog(int row, int col) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLocationButton('Path', row, col),
              _buildLocationButton('Room', row, col),
              _buildLocationButton('Lift', row, col),
              _buildLocationButton('Exit', row, col),
              _buildLocationButton('Washroom', row, col),
              _buildLocationButton('Clear', row, col),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationButton(String location, int row, int col) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        _updateGrid(location, row, col);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _getColorForLocation(location),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(
        location,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _updateGrid(String location, int row, int col) {
    setState(() {
      grid[row][col] = location;
    });
  }

  void _submitMap() {
    // Implement your map submission logic here
    print('Map Submitted!');
  }
}