// lib/api/pod_api.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pod_status.dart';

class PodApi {
  static final PodApi _instance = PodApi._internal();
  factory PodApi() => _instance;
  PodApi._internal();

  String? _podUrl;
  bool _useMockData = false;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _podUrl = prefs.getString('pod_url');
    _useMockData = prefs.getBool('use_mock_data') ?? false;
  }

  bool isConfigured() => _useMockData || (_podUrl != null && _podUrl!.isNotEmpty);
  bool isMockMode() => _useMockData;

  // *** NEW: Define the ngrok header here ***
  Map<String, String> get _headers => {
    'ngrok-skip-browser-warning': 'true',
  };

  Future<void> connect({required String address, bool useMock = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_mock_data', useMock);
    _useMockData = useMock;

    if (useMock) {
      _podUrl = null;
      await prefs.remove('pod_url');
      return;
    }

    if (address.trim().isEmpty) {
      throw Exception('Address cannot be empty.');
    }

    String baseUrl = address.trim();
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    if (!baseUrl.toLowerCase().startsWith('http')) {
      baseUrl = 'http://$baseUrl';
    }

    final String statusUrl = '$baseUrl/status';

    try {
      // *** FIX: Pass the header to the GET request ***
      final response = await http.get(Uri.parse(statusUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _podUrl = baseUrl;
        await prefs.setString('pod_url', _podUrl!);
        return;
      } else {
        throw Exception('Pod responded with status: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Connection timed out. Check the address and network.');
    } on FormatException {
      throw Exception('Invalid URL format. Please check the address.');
    } catch (e) {
      throw Exception('Network error. Ensure your phone has Wi-Fi access.');
    }
  }

  Future<PodStatus> getStatus() async {
    if (_useMockData) {
      return _getMockStatus();
    }

    if (_podUrl == null) {
      throw Exception("Pod URL is not configured.");
    }

    final statusUrl = '$_podUrl/status';

    try {
      // *** FIX: Pass the header to the GET request here as well ***
      final response = await http.get(Uri.parse(statusUrl), headers: _headers)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return PodStatus.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load status');
      }
    } catch (e) {
      throw Exception('Connection error');
    }
  }

  PodStatus _getMockStatus() {
    final random = Random();
    int randomState = random.nextInt(4);
    String waterLevel = 'OK';
    double temperature = 25.0;

    if (randomState == 1) waterLevel = 'LOW';
    if (randomState == 2) temperature = 32.0;
    if (randomState == 3) {
      waterLevel = 'LOW';
      temperature = 32.0;
    }
    return PodStatus(waterLevel: waterLevel, temperature: temperature);
  }
}