import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/pod_api.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({Key? key}) : super(key: key);
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  bool _useMockData = false;
  double _faceSizeDivisor = 2.2;

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _urlController.text = prefs.getString('pod_url') ?? '';
    setState(() {
      _useMockData = prefs.getBool('use_mock_data') ?? false;
      _faceSizeDivisor = prefs.getDouble('face_size_divisor') ?? 2.2;
    });
  }

  Future<void> _connectToPod() async {
    setState(() => _isLoading = true);

    try {
      await PodApi().connect(
        address: _urlController.text,
        useMock: _useMockData,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/face');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Enter Pod URL or IP Address'), // Updated title
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Row(
            children: [
              Icon(Icons.bug_report, color: _useMockData ? Colors.amber : Colors.white54),
              Switch(
                value: _useMockData,
                onChanged: (value) => setState(() => _useMockData = value),
                activeColor: Colors.amber,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _urlController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                  enabled: !_useMockData,
                  decoration: InputDecoration(
                    hintText: 'e.g., https://name.ngrok.io',
                    border: const OutlineInputBorder(),
                    fillColor: _useMockData ? Colors.grey[850] : Colors.grey[900],
                    filled: true,
                  ),
                  keyboardType: TextInputType.url, // Changed to URL keyboard type
                ),
                const SizedBox(height: 24),
                Text(
                  'Face Size',
                  style: TextStyle(color: Colors.white70),
                ),

                Slider(
                  value: _faceSizeDivisor,
                  min: 2.0,   // Max size
                  max: 4.0,   // Small size
                  divisions: 20,
                  label: _faceSizeDivisor.toStringAsFixed(1),
                  activeColor: Colors.amber,
                  inactiveColor: Colors.grey[800],
                  onChanged: (newValue) async {
                    setState(() {
                      _faceSizeDivisor = newValue;
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setDouble('face_size_divisor', newValue);
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(onPressed: _connectToPod, child: const Text('Connect & Save')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}