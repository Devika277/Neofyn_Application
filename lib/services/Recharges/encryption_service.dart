import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static const String _edKey = "8086289ecab4a664c8410a1e79d19090";
  static const String _ivKey = "7cca987fb6cfeea37022"; // 24 chars = 12 bytes
  
  static Uint8List _hexToBytes(String hex) {
    if (hex.length % 2 != 0) throw Exception('Invalid hex string');
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }
  
  static String encrypt(String plainText) {
    try {
      final key = _hexToBytes(_edKey);
      final iv = _hexToBytes(_ivKey);
      
      if (key.length != 16 && key.length != 24 && key.length != 32) {
        throw Exception('Invalid key length: ${key.length}');
      }
      if (iv.length != 12) {
        throw Exception('IV must be 12 bytes, got ${iv.length}');
      }
      
      final keyParam = KeyParameter(key);
      final ivParam = ParametersWithIV(keyParam, iv); // ✅ CORRECT: Use ParametersWithIV
      
      final cipher = GCMBlockCipher(AESEngine())
        ..init(true, AEADParameters(keyParam, 128, ivParam as Uint8List, Uint8List(0))); // true = encrypt
      
      final plainBytes = Uint8List.fromList(utf8.encode(plainText));
      final cipherText = Uint8List(cipher.getOutputSize(plainBytes.length));
      final len = cipher.processBytes(plainBytes, 0, plainBytes.length, cipherText, 0);
      cipher.doFinal(cipherText, len);
      
      return base64.encode(cipherText);
    } catch (e) {
      print('Encryption error: $e');
      return '';
    }
  }
  
  static String decrypt(String encryptedText) {
    try {
      final key = _hexToBytes(_edKey);
      final iv = _hexToBytes(_ivKey);
      
      if (key.length != 16 && key.length != 24 && key.length != 32) {
        throw Exception('Invalid key length: ${key.length}');
      }
      if (iv.length != 12) {
        throw Exception('IV must be 12 bytes, got ${iv.length}');
      }
      
      final keyParam = KeyParameter(key);
      final ivParam = ParametersWithIV(keyParam, iv); // ✅ CORRECT
      
      final cipher = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(keyParam, 128, ivParam as Uint8List, Uint8List(0))); // false = decrypt
      
      final cipherBytes = base64.decode(encryptedText);
      final plainBytes = Uint8List(cipher.getOutputSize(cipherBytes.length));
      final len = cipher.processBytes(cipherBytes, 0, cipherBytes.length, plainBytes, 0);
      cipher.doFinal(plainBytes, len);
      
      // Remove trailing null characters
      final result = utf8.decode(plainBytes);
      return result.trim();
    } catch (e) {
      // print('Decryption error: $e');
      return '';
    }
  }
}