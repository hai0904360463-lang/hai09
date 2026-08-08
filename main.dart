// main.dart
// App đo tốc độ bằng GPS - Flutter
// Cần thêm package geolocator vào pubspec.yaml (xem hướng dẫn bên dưới)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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

  double _speedKmh = 0.0;
  double _maxSpeedKmh = 0.0;
  double _accuracy = 0.0;
  String _status = 'Đang khởi động...';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Kiểm tra dịch vụ định vị có bật không
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _status = 'Vui lòng bật GPS trong Cài đặt');
      return;
    }

    // Xin quyền truy cập vị trí
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

    // Lắng nghe cập nhật vị trí liên tục, độ chính xác cao nhất
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, // cập nhật liên tục, không lọc theo khoảng cách
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      // position.speed trả về đơn vị m/s
      final speedMs = position.speed < 0 ? 0.0 : position.speed;
      final speedKmh = speedMs * 3.6;

      setState(() {
        _speedKmh = speedKmh;
        _accuracy = position.accuracy;
        if (speedKmh > _maxSpeedKmh) {
          _maxSpeedKmh = speedKmh;
        }
      });
    }, onError: (e) {
      setState(() => _status = 'Lỗi GPS: $e');
    });
  }

  void _resetMax() {
    setState(() => _maxSpeedKmh = 0.0);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tốc độ GPS'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Text(
              _speedKmh.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 90,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ),
            const Text(
              'km/h',
              style: TextStyle(fontSize: 24, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            Text(
              'Tốc độ tối đa: ${_maxSpeedKmh.toStringAsFixed(1)} km/h',
              style: const TextStyle(fontSize: 18, color: Colors.orangeAccent),
            ),
            Text(
              'Độ chính xác GPS: ±${_accuracy.toStringAsFixed(1)} m',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _resetMax,
              child: const Text('Reset tốc độ tối đa'),
            ),
          ],
        ),
      ),
    );
  }
}
