import 'dart:math';
import 'dart:typed_data';

/// Erzeugt eine kurze WAV-Audiodatei (16-bit PCM, mono) als Bytes, ohne
/// externe Audio-Assets. Damit gibt es keine Lizenzfragen für Sound-Dateien
/// (siehe ROADMAP_QuizApp.md Abschnitt 18e) - stattdessen ein einfacher
/// synthetischer Ton aus einer Folge von Sinuston-"Noten".
Uint8List generateWavTone({
  required List<double> frequencies,
  int sampleRate = 44100,
  Duration noteDuration = const Duration(milliseconds: 130),
}) {
  final samplesPerNote = (sampleRate * noteDuration.inMilliseconds / 1000).round();
  final totalSamples = samplesPerNote * frequencies.length;
  final samples = Int16List(totalSamples);

  var index = 0;
  for (final frequency in frequencies) {
    for (var i = 0; i < samplesPerNote; i++) {
      final t = i / sampleRate;
      // Linearer Fade-out pro Note, damit es nicht knackst.
      final envelope = 1 - (i / samplesPerNote);
      final value = sin(2 * pi * frequency * t) * envelope * 0.3;
      samples[index++] = (value * 32767).round().clamp(-32768, 32767);
    }
  }

  return _wavFromPcm16(samples, sampleRate);
}

Uint8List _wavFromPcm16(Int16List samples, int sampleRate) {
  const bitsPerSample = 16;
  const channels = 1;
  final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
  final blockAlign = channels * bitsPerSample ~/ 8;
  final dataLength = samples.lengthInBytes;

  final buffer = ByteData(44 + dataLength);
  void writeAscii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      buffer.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  writeAscii(0, 'RIFF');
  buffer.setUint32(4, 36 + dataLength, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  buffer.setUint32(16, 16, Endian.little);
  buffer.setUint16(20, 1, Endian.little);
  buffer.setUint16(22, channels, Endian.little);
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, byteRate, Endian.little);
  buffer.setUint16(32, blockAlign, Endian.little);
  buffer.setUint16(34, bitsPerSample, Endian.little);
  writeAscii(36, 'data');
  buffer.setUint32(40, dataLength, Endian.little);

  for (var i = 0; i < samples.length; i++) {
    buffer.setInt16(44 + i * 2, samples[i], Endian.little);
  }

  return buffer.buffer.asUint8List();
}
