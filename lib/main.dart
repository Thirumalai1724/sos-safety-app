import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'contacts_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'camera_screen.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const SOSApp());
}

class SOSApp extends StatelessWidget {
  const SOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS Safety App',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const SOSHomePage(),
    );
  }
}

class SOSHomePage extends StatefulWidget {
  const SOSHomePage({super.key});

  @override
  State<SOSHomePage> createState() => _SOSHomePageState();
}

class _SOSHomePageState extends State<SOSHomePage> {
  static const platform = MethodChannel('com.example.sos_app/volume_button');

  String _statusMessage = "Press the SOS button in an emergency";
  Position? _currentPosition;
  bool _isSendingSOS = false;
  String? _capturedImagePath;
  String? _recordedAudioPath;

  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler((call) async {
      if (call.method == 'sosTriggered') {
        _handleSOS();
      }
    });
  }

  Future<void> _sendSMSAlert() async {
    final contacts = await ContactsService.getContacts();
    String mapLink =
        "https://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}";
    String message = "SOS! Naan aabathil irukken. Location: $mapLink";

    for (String number in contacts) {
      if (number.isNotEmpty) {
        final uri = Uri.parse("sms:$number?body=${Uri.encodeComponent(message)}");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    }
  }

  Future<void> _shareOnWhatsApp() async {
    String mapLink =
        "https://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}";
    String message = "SOS! Naan aabathil irukken. Location: $mapLink";

    if (_capturedImagePath != null) {
      await Share.shareXFiles([XFile(_capturedImagePath!)], text: message);
      await Future.delayed(const Duration(seconds: 1));
    } else {
      await Share.share(message);
    }

    if (_recordedAudioPath != null) {
      await Future.delayed(const Duration(seconds: 1));
      await Share.shareXFiles([XFile(_recordedAudioPath!)], text: "SOS Voice Message");
    }
  }

  Future<bool> _requestPermissions() async {
    final locationStatus = await Permission.location.request();
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (locationStatus.isGranted && cameraStatus.isGranted && micStatus.isGranted) {
      return true;
    } else {
      setState(() {
        _statusMessage = "Location, Camera and Microphone permissions are required!";
      });
      return false;
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = "Please enable location services!";
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
    });
  }

  Future<String?> _capturePhotoAuto() async {
    try {
      if (cameras.isEmpty) return null;
      final path = await Navigator.push<String?>(
        context,
        MaterialPageRoute(builder: (context) => CameraScreen(camera: cameras.first)),
      );
      return path;
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return null;
    }
  }

  Future<String?> _recordAudio() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/sos_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: path);
        await Future.delayed(const Duration(seconds: 10));
        final recordedPath = await _audioRecorder.stop();
        return recordedPath;
      }
      return null;
    } catch (e) {
      debugPrint('Error recording audio: $e');
      return null;
    }
  }

  Future<void> _handleSOS() async {
    setState(() {
      _isSendingSOS = true;
      _statusMessage = "Requesting permissions...";
    });

    bool granted = await _requestPermissions();
    if (!granted) {
      setState(() {
        _isSendingSOS = false;
      });
      return;
    }

    setState(() {
      _statusMessage = "Getting your location...";
    });

    await _getCurrentLocation();

    setState(() {
      _statusMessage = "Opening camera...";
    });

    String? photoPath = await _capturePhotoAuto();

    setState(() {
      _capturedImagePath = photoPath;
      _statusMessage = "Recording voice message (10 sec)...";
    });

    String? audioPath = await _recordAudio();

    setState(() {
      _recordedAudioPath = audioPath;
    });

    if (_currentPosition != null) {
      setState(() {
        _statusMessage =
            "SOS Alert Sent!\nLatitude: ${_currentPosition!.latitude}\nLongitude: ${_currentPosition!.longitude}";
      });
      await _shareOnWhatsApp();
      await Future.delayed(const Duration(seconds: 2));
      await _sendSMSAlert();
    } else {
      setState(() {
        _statusMessage = "Could not get location. Try again.";
      });
    }

    setState(() {
      _isSendingSOS = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Safety App'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _isSendingSOS ? null : _handleSOS,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSendingSOS
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              if (_capturedImagePath != null)
                Column(
                  children: [
                    const Text(
                      "Captured Photo:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Image.file(
                      File(_capturedImagePath!),
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}