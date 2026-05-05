import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pitch_detector/services/audio_service.dart';
import 'package:pitch_detector/services/musical_note_converter.dart';
import 'package:pitch_detector/models/note_result.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<double> _dataPoints = [];
  final int _maxDataPoints = 100;
  StreamSubscription<double>? _subscription;
  final _noteConverter = MusicalNoteConverter();

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
    NoteResult? currentNote;

    if (_dataPoints.isNotEmpty) {
      currentNote = _noteConverter.convert(_dataPoints.last);
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Section: Note Display
              Column(
                children: [
                  Text(
                    currentNote != null && currentNote.isValid
                        ? "${currentNote.note} / ${currentNote.solfegeNote}"
                        : "--",
                    style: GoogleFonts.outfit(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      shadows: [
                        Shadow(
                          color: Colors.cyanAccent.withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentNote != null && currentNote.isValid
                        ? "${currentNote.frequency.toStringAsFixed(1)} Hz"
                        : "Waiting for audio...",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Tuning Indicator
                  if (currentNote != null && currentNote.isValid)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Flat",
                          style: TextStyle(
                            color: currentNote.cents < -10
                                ? Colors.redAccent
                                : Colors.white30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                // Indicator dot
                                Align(
                                  alignment: Alignment(
                                    (currentNote.cents / 50).clamp(-1.0, 1.0),
                                    0,
                                  ),
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: currentNote.cents.abs() < 10
                                          ? Colors.greenAccent
                                          : Colors.cyanAccent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (currentNote.cents.abs() < 10
                                                      ? Colors.greenAccent
                                                      : Colors.cyanAccent)
                                                  .withOpacity(0.5),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Center mark
                                Container(
                                  width: 2,
                                  height: 12,
                                  color: Colors.white30,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          "Sharp",
                          style: TextStyle(
                            color: currentNote.cents > 10
                                ? Colors.redAccent
                                : Colors.white30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Bottom Section: Chart
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _dataPoints.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.cyanAccent,
                            ),
                          )
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
                                  curveSmoothness: 0.35,
                                  color: Colors.cyanAccent,
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.cyanAccent.withOpacity(0.4),
                                        Colors.cyanAccent.withOpacity(0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
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
