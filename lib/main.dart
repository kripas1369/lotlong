import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Geolocator _geolocator = Geolocator();
  Position? _currentPosition;
  double _previousLatitude = 0;
  double _previousLongitude = 0;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied.");
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            "Location permissions are permanently denied, we cannot request permissions.");
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      setState(() {
        _currentPosition = position;
        _previousLatitude = position.latitude;
        _previousLongitude = position.longitude;
      });
    } catch (e) {
      print(e);
      // Handle location permission denied
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Location Access Required'),
            content: Text(
                'Please grant location access for the app to function properly.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
              TextButton(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                  Navigator.of(context).pop();
                  _getLocation(); // Re-request location after returning from settings
                },
                child: Text('Open Settings'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _checkDistance() async {
    if (_currentPosition != null) {
      double distanceInMeters = await Geolocator.distanceBetween(
          _previousLatitude,
          _previousLongitude,
          _currentPosition!.latitude,
          _currentPosition!.longitude);

      if (distanceInMeters > 2) {
        // Display text message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are too far from the location'),
          ),
        );
      } else {
        // Update previous latitude and longitude
        setState(() {
          _previousLatitude = _currentPosition!.latitude;
          _previousLongitude = _currentPosition!.longitude;
        });
      }
    } else {
     Text("waiting for the location ");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Alarm'),
      ),
      body: Center(
        child: _currentPosition != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Latitude: ${_currentPosition!.latitude}',
            ),
            Text(
              'Longitude: ${_currentPosition!.longitude}',
            ),
            ElevatedButton(
              onPressed: _checkDistance,
              child: Text('Activate Alarm'),
            ),
          ],
        )
            : CircularProgressIndicator(),
      ),
    );
  }
}
