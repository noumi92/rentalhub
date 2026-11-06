import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../utils/cnic_text_parser.dart';

/// Phase B (C2): on-device CNIC OCR with ML Kit (Latin script). The
/// card never leaves the phone — recognition runs on-device. The
/// result is always reviewed by the owner before it is saved, because
/// OCR misreads digits and names. Only the front of the card is
/// required; the back adds the address.
class CnicOcrService {
  Future<CnicScanResult> scanFront(File image) async {
    final text = await _recognise(image);
    return CnicTextParser.parseFront(text);
  }

  Future<CnicScanResult> scanBack(File image) async {
    final text = await _recognise(image);
    return CnicTextParser.parseBack(text);
  }

  Future<String> _recognise(File image) async {
    final recognizer =
        TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(image.path);
      final result = await recognizer.processImage(input);
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}
