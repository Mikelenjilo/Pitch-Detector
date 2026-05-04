import 'package:flutter/services.dart';

class AudioService {
  static const _channel = EventChannel('pitch_detector/audio_stream');

  Stream<int> getAudioStream() {
    return _channel.receiveBroadcastStream().map((event) => event as int);
  }
}
