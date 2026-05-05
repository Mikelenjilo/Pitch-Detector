import 'dart:math';

import 'package:pitch_detector/models/note_result.dart';

class MusicalNoteConverter {
  static const List<String> _notes = [
    "C",
    "C#",
    "D",
    "D#",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "A#",
    "B",
  ];

  static const List<String> _solfegeNotes = [
    "Do",
    "Do#",
    "Re",
    "Re#",
    "Mi",
    "Fa",
    "Fa#",
    "Sol",
    "Sol#",
    "La",
    "La#",
    "Si",
  ];

  /// Reference tuning (A4 = 440 Hz)
  final double referenceFrequency;

  MusicalNoteConverter({this.referenceFrequency = 440.0});

  /// Convert frequency to full note result
  NoteResult convert(double frequency) {
    if (frequency <= 0) {
      return NoteResult.invalid();
    }

    final midi = _frequencyToMidi(frequency);
    final noteName = _midiToNoteName(midi);
    final solfegeName = _midiToSolfegeName(midi);
    final octave = _midiToOctave(midi);
    final noteFreq = _midiToFrequency(midi);

    final cents = _centsOff(frequency, noteFreq);

    return NoteResult(
      frequency: frequency,
      midi: midi,
      note: "$noteName$octave",
      solfegeNote: "$solfegeName$octave",
      cents: cents,
    );
  }

  /// MIDI formula
  int _frequencyToMidi(double frequency) {
    return (69 + 12 * (log(frequency / referenceFrequency) / ln2)).round();
  }

  /// Convert MIDI → note index
  String _midiToNoteName(int midi) {
    return _notes[midi % 12];
  }

  /// Convert MIDI → solfege index
  String _midiToSolfegeName(int midi) {
    return _solfegeNotes[midi % 12];
  }

  /// Convert MIDI → octave
  int _midiToOctave(int midi) {
    return (midi ~/ 12) - 1;
  }

  /// Convert MIDI → ideal frequency
  double _midiToFrequency(int midi) {
    return referenceFrequency * pow(2, (midi - 69) / 12);
  }

  /// Cents difference between detected and ideal note
  double _centsOff(double freq, double noteFreq) {
    return 1200 * (log(freq / noteFreq) / ln2);
  }
}
