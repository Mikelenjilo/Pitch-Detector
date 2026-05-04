import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pitch_detector/services/native_bridge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<int> _dataPoints = [];
  final int _maxDataPoints = 100;
  StreamSubscription<int>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = AudioService().getAudioStream().listen((data) {
      if (mounted) {
        setState(() {
          _dataPoints.add(data);
          if (_dataPoints.length > _maxDataPoints) {
            _dataPoints.removeAt(0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];
    for (int i = 0; i < _dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), _dataPoints[i].toDouble()));
    }

    double minVal = 0;
    double maxVal = 100;
    
    if (_dataPoints.isNotEmpty) {
      minVal = _dataPoints.reduce(min).toDouble();
      maxVal = _dataPoints.reduce(max).toDouble();
      if (maxVal - minVal < 10) {
        double center = (maxVal + minVal) / 2;
        maxVal = center + 5;
        minVal = center - 5;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Pitch Detector")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Current Value: ${_dataPoints.isNotEmpty ? _dataPoints.last : 'Loading...'}",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withOpacity(0.02),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _dataPoints.isEmpty
                        ? const Center(child: Text("Waiting for data..."))
                        : LineChart(
                            LineChartData(
                              minY: minVal,
                              maxY: maxVal,
                              minX: 0,
                              maxX: (_maxDataPoints - 1).toDouble(),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 2,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
