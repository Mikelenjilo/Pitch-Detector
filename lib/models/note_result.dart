class NoteResult {
  final double frequency;
  final int midi;
  final String note;
  final String solfegeNote;
  final double cents;

  NoteResult({
    required this.frequency,
    required this.midi,
    required this.note,
    required this.solfegeNote,
    required this.cents,
  });

  factory NoteResult.invalid() {
    return NoteResult(frequency: 0, midi: -1, note: "N/A", solfegeNote: "N/A", cents: 0);
  }

  bool get isValid => midi != -1;
}
