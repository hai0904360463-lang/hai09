// main.dart
// App đo tốc độ bằng GPS - Flutter
// Có nút tạm dừng/tiếp tục + bản đồ khi xoay ngang máy

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const SpeedoApp());
}

class SpeedoApp extends StatelessWidget {
  const SpeedoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đo tốc độ GPS',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const SpeedHomePage(),
    );
  }
}

class SpeedHomePage extends StatefulWidget {
  const SpeedHomePage({super.key});

  @override
  State<SpeedHomePage> createState() => _SpeedHomePageState();
}

class _SpeedHomePageState extends State<SpeedHomePage> {
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();

  double _speedKmh = 0.0;
  double _maxSpeedKmh = 0.0;
  double _accuracy = 0.0;
  String _status = 'Đang khởi động...';
  bool _isPaused = false;
  LatLng? _currentLatLng;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _status = 'Vui lòng bật GPS trong Cài đặt');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _status = 'Bạn đã từ chối quyền truy cập vị trí');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _status = 'Quyền vị trí bị chặn vĩnh viễn, vào Cài đặt để bật lại');
      return;
    }

    setState(() => _status = 'Đang đo...');

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      // Nếu đang tạm dừng, bỏ qua cập nhật, giữ nguyên số hiện tại
      if (_isPaused) return;

      final speedMs = position.speed < 0 ? 0.0 : position.speed;
      final speedKmh = speedMs * 3.6;
      final newLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _speedKmh = speedKmh;
        _accuracy = position.accuracy;
        _currentLatLng = newLatLng;
        if (speedKmh > _maxSpeedKmh) {
          _maxSpeedKmh = speedKmh;
        }
      });

      // Nếu bản đồ đang hiển thị (đang xoay ngang), tự di chuyển camera theo vị trí mới
      if (_mapReady) {
        try {
          _mapController.move(newLatLng, _mapController.camera.zoom);
        } catch (_) {
          // Bỏ qua nếu map controller chưa gắn xong, tránh crash
        }
      }
    }, onError: (e) {
      setState(() => _status = 'Lỗi GPS: $e');
    });
  }

  void _resetMax() {
    setState(() => _maxSpeedKmh = 0.0);
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      _status = _isPaused ? 'Đã tạm dừng' : 'Đang đo...';
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // Widget hiển thị đồng hồ tốc độ (dùng chung cho cả 2 chế độ dọc/ngang)
  Widget _buildSpeedDisplay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _status,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Text(
          _speedKmh.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.cyanAccent,
          ),
        ),
        const Text(
          'km/h',
          style: TextStyle(fontSize: 22, color: Colors.white70),
        ),
        const SizedBox(height: 30),
        Text(
          'Tốc độ tối đa: ${_maxSpeedKmh.toStringAsFixed(1)} km/h',
          style: const TextStyle(fontSize: 16, color: Colors.orangeAccent),
        ),
        Text(
          'Độ chính xác GPS: ±${_accuracy.toStringAsFixed(1)} m',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _togglePause,
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
              label: Text(_isPaused ? 'Tiếp tục' : 'Tạm dừng'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPaused ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _resetMax,
              child: const Text('Reset tối đa'),
            ),
          ],
        ),
      ],
    );
  }

  // Widget bản đồ, chỉ hiện khi xoay ngang
  Widget _buildMap() {
    if (_currentLatLng == null) {
      return const Center(
        child: Text(
          'Đang chờ tín hiệu GPS để hiện bản đồ...',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Đánh dấu bản đồ đã sẵn sàng để bắt đầu tự động di chuyển camera
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_mapReady) {
        setState(() => _mapReady = true);
      }
    });

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLatLng!,
        initialZoom: 16,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.speedo_app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _currentLatLng!,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.navigation,
                color: Colors.cyanAccent,
                size: 32,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tốc độ GPS'),
        backgroundColor: Colors.black,
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            // Xoay ngang: chia đôi màn hình, trái là đồng hồ, phải là bản đồ
            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Center(child: _buildSpeedDisplay()),
                ),
                const VerticalDivider(width: 1, color: Colors.white24),
                Expanded(
                  flex: 1,
                  child: _buildMap(),
                ),
              ],
            );
          }
          // Chế độ dọc: chỉ hiện đồng hồ tốc độ như bình thường
          return Center(child: _buildSpeedDisplay());
        },
      ),
    );
  }
}
