import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  late final TextRecognizer _textRecognizer;
  bool _isInitialized = false;

  // Initialize the OCR service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      _isInitialized = true;
    } catch (e) {
      throw OCRException('Failed to initialize OCR service: $e');
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _textRecognizer.close();
      _isInitialized = false;
    }
  }

  // Extract text from image file
  Future<OCRResult> extractTextFromImage(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Validate image file
      if (!await imageFile.exists()) {
        throw OCRException('Image file does not exist');
      }

      // Check file size (limit to 10MB)
      final fileSizeInBytes = await imageFile.length();
      if (fileSizeInBytes > 10 * 1024 * 1024) {
        throw OCRException('Image file is too large (max 10MB)');
      }

      // Use original image file directly
      final processedImage = imageFile;
      
      // Create InputImage from file
      final inputImage = InputImage.fromFile(processedImage);
      
      // Perform text recognition
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Extract text blocks with positions
      final textBlocks = <TextBlock>[];
      for (final block in recognizedText.blocks) {
        textBlocks.add(TextBlock(
          text: block.text,
          boundingBox: block.boundingBox,
          confidence: 0.8, // Default confidence since ML Kit doesn't provide it
          recognizedLanguages: block.recognizedLanguages.cast<String>(),
        ));
      }

      return OCRResult(
        fullText: recognizedText.text,
        textBlocks: textBlocks,
        confidence: _calculateOverallConfidence(textBlocks),
        processingTime: DateTime.now(),
      );

    } catch (e) {
      if (e is OCRException) rethrow;
      throw OCRException('Failed to extract text from image: $e');
    }
  }

  // Extract text from image bytes
  Future<OCRResult> extractTextFromBytes(Uint8List imageBytes) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Create InputImage from bytes
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(800, 600), // Default size, should be actual image size
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: 800,
        ),
      );

      // Perform text recognition
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Extract text blocks
      final textBlocks = <TextBlock>[];
      for (final block in recognizedText.blocks) {
        textBlocks.add(TextBlock(
          text: block.text,
          boundingBox: block.boundingBox,
          confidence: 0.8, // Default confidence since ML Kit doesn't provide it
          recognizedLanguages: block.recognizedLanguages.cast<String>(),
        ));
      }

      return OCRResult(
        fullText: recognizedText.text,
        textBlocks: textBlocks,
        confidence: _calculateOverallConfidence(textBlocks),
        processingTime: DateTime.now(),
      );

    } catch (e) {
      throw OCRException('Failed to extract text from bytes: $e');
    }
  }



  // Calculate overall confidence from text blocks
  double _calculateOverallConfidence(List<TextBlock> textBlocks) {
    if (textBlocks.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    int totalLength = 0;
    
    for (final block in textBlocks) {
      final blockLength = block.text.length;
      totalConfidence += block.confidence * blockLength;
      totalLength += blockLength;
    }
    
    return totalLength > 0 ? totalConfidence / totalLength : 0.0;
  }

  // Check if OCR service is available
  bool get isAvailable => _isInitialized;

  // Get supported languages
  List<String> get supportedLanguages => [
    'en', 'vi', 'zh', 'ja', 'ko', 'fr', 'de', 'es', 'it', 'ru', 'ar', 'hi', 'th'
  ];
}

// OCR Result model
class OCRResult {
  final String fullText;
  final List<TextBlock> textBlocks;
  final double confidence;
  final DateTime processingTime;

  const OCRResult({
    required this.fullText,
    required this.textBlocks,
    required this.confidence,
    required this.processingTime,
  });

  bool get hasText => fullText.trim().isNotEmpty;
  bool get isHighConfidence => confidence > 0.7;
}

// Text Block model
class TextBlock {
  final String text;
  final Rect boundingBox;
  final double confidence;
  final List<String> recognizedLanguages;

  const TextBlock({
    required this.text,
    required this.boundingBox,
    required this.confidence,
    required this.recognizedLanguages,
  });
}

// OCR Exception
class OCRException implements Exception {
  final String message;
  const OCRException(this.message);
  
  @override
  String toString() => 'OCRException: $message';
}
