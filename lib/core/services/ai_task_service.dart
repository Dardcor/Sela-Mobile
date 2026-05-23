import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'api_client.dart';

class AutomaticTaskDivision {
  static const _modelName = 'gemini-2.5-flash';

  static Future<GenerativeModel> _createModel() async {
    try {
      final response = await ApiClient().dio.get('/gemini-key');
      final apiKey = response.data['key'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Failed to retrieve valid API key from backend');
      }
      return GenerativeModel(model: _modelName, apiKey: apiKey);
    } catch (e) {
      final apiKeyString = dotenv.env['GEMINI_API_KEY'];
      if (apiKeyString == null || apiKeyString.isEmpty) {
        throw Exception('GEMINI_API_KEY is not defined in .env and backend failed: $e');
      }
      final keys = apiKeyString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (keys.isEmpty) {
        throw Exception('No valid API keys found in .env fallback');
      }
      final apiKey = keys[DateTime.now().microsecond % keys.length];
      return GenerativeModel(model: _modelName, apiKey: apiKey);
    }
  }

  static Future<List<Map<String, dynamic>>> _generateTasks(
    String prompt, {
    List<DataPart>? fileParts,
    void Function(String)? onStream,
  }) async {
    final parts = <Part>[TextPart(prompt)];
    if (fileParts != null && fileParts.isNotEmpty) {
      parts.addAll(fileParts);
    }

    try {
      final model = await _createModel();
      final responseStream = model.generateContentStream([
        Content.multi(parts),
      ]);

      String fullText = '';
      await for (final chunk in responseStream) {
        fullText += chunk.text ?? '';
        if (onStream != null) {
          var display = fullText;
          if (display.contains('[PEMIKIRAN]')) {
             display = display.split('[PEMIKIRAN]').last;
          }
          if (display.contains('[HASIL]')) {
             display = display.split('[HASIL]').first;
          }
          onStream(display.trimLeft());
        }
      }

      if (fullText.isEmpty) {
        throw Exception('Server AI sedang sibuk. Silakan coba beberapa saat lagi.');
      }

      String jsonText = fullText;
      if (fullText.contains('[HASIL]')) {
         jsonText = fullText.split('[HASIL]').last;
      }

      final dynamic decoded = jsonDecode(_stripMarkdownFence(jsonText));
      if (decoded is! List) {
        throw Exception('Server AI gagal memproses data dengan benar. Silakan coba lagi.');
      }

      final list = List<Map<String, dynamic>>.from(decoded);
      if (list.isEmpty) {
        throw Exception('VALIDATION_ERROR: Judul, Deskripsi, link atau file yang Anda upload tidak sesuai untuk membagikan tugas.');
      }

      return list;
    } on GenerativeAIException catch (e) {
      throw Exception('Server AI sedang sibuk atau kelebihan muatan. Detail: ${e.message}');
    } catch (e) {
      if (e.toString().contains('Server AI')) {
        rethrow;
      }
      throw Exception('Terjadi gangguan koneksi dengan sistem AI. Pastikan internet stabil lalu coba lagi. Detail: $e');
    }
  }

  static String _stripMarkdownFence(String text) {
    var cleanedText = text.trim();
    if (cleanedText.startsWith('```json')) {
      cleanedText = cleanedText.substring(7);
    } else if (cleanedText.startsWith('```')) {
      cleanedText = cleanedText.substring(3);
    }

    if (cleanedText.endsWith('```')) {
      cleanedText = cleanedText.substring(0, cleanedText.length - 3);
    }

    return cleanedText.trim();
  }

  /// Membagi tugas grup secara otomatis berdasarkan kemampuan (ability) masing-masing anggota.
  /// [members] — list anggota grup, tiap item memiliki key 'profiles' dan 'abilities' (List<String>).
  static Future<List<Map<String, dynamic>>> divideTask({
    required String taskTitle,
    required String taskDescription,
    required List<dynamic> members,
    List<String>? links,
    List<String>? files,
    List<DataPart>? fileParts,
    void Function(String)? onStream,
  }) async {
    // Bangun daftar anggota beserta kemampuannya
    final membersList = members
        .map((m) {
          final userMap = m as Map<String, dynamic>? ?? {};
          final profile = userMap['profiles'] ?? userMap;
          final name =
              profile['full_name'] ?? profile['username'] ?? userMap['full_name'] ?? userMap['username'] ?? 'Unknown Member';
          final userId = profile['id']?.toString() ?? userMap['id']?.toString() ?? '';
          final abilities =
              (userMap['abilities'] as List<dynamic>?)
                  ?.map((a) => a.toString())
                  .toList() ??
              [];
          return {'id': userId, 'name': name, 'abilities': abilities};
        })
        .where((m) => (m['id']?.toString() ?? '').isNotEmpty)
        .toList();

    if (membersList.isEmpty) {
      throw Exception('Tidak ada anggota untuk ditetapkan tugas.');
    }

    // Prompt dalam Bahasa Indonesia yang mewajibkan output Bahasa Indonesia
    final prompt =
        """
Kamu adalah manajer proyek yang ahli dalam menganalisis tugas dan membaginya. Semua respons WAJIB dalam Bahasa Indonesia yang profesional.

TUGAS UTAMA: "$taskTitle"
DESKRIPSI: "$taskDescription"
${links != null && links.isNotEmpty ? "TAUTAN REFERENSI TUGAS:\n${links.join('\n')}\n" : ""}
${files != null && files.isNotEmpty ? "FILE REFERENSI TERLAMPIR:\n${files.join('\n')}\n" : ""}

DAFTAR ANGGOTA & KEAHLIAN MEREKA (JSON):
${jsonEncode(membersList)}

INSTRUKSI WAJIB UNTUKMU:
1. Mulailah dengan tag [PEMIKIRAN]. Di bawah tag ini, berikan 1-2 paragraf singkat berisi pemikiran/analisis kamu tentang tugas ini menggunakan bahasa Indonesia yang rapi (seperti sedang mengetik).
2. VALIDASI INPUT: JIKA input (Judul, Deskripsi, tautan, atau file) asal-asalan, tidak nyambung, atau tidak masuk akal untuk dijadikan tugas, nyatakan dengan jelas di bagian pemikiranmu: "Judul, Deskripsi, link atau file yang Anda upload tidak sesuai untuk membagikan tugas."
3. Jika input tidak valid, setelah tag [PEMIKIRAN], berikan tag [HASIL] lalu berikan array JSON kosong [].
4. Jika input valid dan masuk akal, setelah tag [PEMIKIRAN], berikan tag [HASIL] dan pecah tugas utama menjadi beberapa sub-tugas yang SPESIFIK dan BISA DIKERJAKAN. Cocokkan dengan keahlian anggota, pastikan semua anggota mendapat tugas.

FORMAT WAJIB HASILMU (Jangan ubah format tag ini):
[PEMIKIRAN]
(analisismu di sini...)

[HASIL]
```json
[
  {
    "title": "Judul spesifik sub-tugas",
    "description": "Langkah detail apa yang harus dia kerjakan",
    "user_id": "masukkan id anggota"
  }
]
```
""";

    return _generateTasks(prompt, fileParts: fileParts, onStream: onStream);
  }

  /// Menyusun urutan pengerjaan tugas mandiri secara otomatis.
  /// [taskTitle], [taskDescription], [userId], [links], [files], [abilities] — informasi tugas mandiri.
  static Future<List<Map<String, dynamic>>> arrangeIndependentTask({
    required String taskTitle,
    required String taskDescription,
    required String userId,
    List<String>? links,
    List<String>? files,
    List<String>? abilities,
    void Function(String)? onStream,
  }) async {
    final abilitiesText = (abilities != null && abilities.isNotEmpty)
        ? 'Kemampuan pengguna: ${abilities.join(', ')}'
        : 'Kemampuan pengguna: tidak terdaftar';

    final prompt =
        """
Kamu adalah asisten penyusun tugas yang cerdas. Semua respons WAJIB menggunakan Bahasa Indonesia.

Tugas: "$taskTitle"
Deskripsi: "$taskDescription"
${links != null && links.isNotEmpty ? "Link referensi:\n${links.join('\n')}\n" : ""}
${files != null && files.isNotEmpty ? "File yang dilampirkan:\n${files.join('\n')}\n" : ""}
$abilitiesText

Tugasmu adalah menyusun subtask-subtask dari tugas ini secara otomatis. 
INSTRUKSI WAJIB UNTUKMU:
1. Mulailah dengan tag [PEMIKIRAN]. Di bawah tag ini, berikan 1-2 paragraf singkat berisi pemikiran/analisis kamu tentang tugas ini menggunakan bahasa Indonesia yang rapi (seperti sedang mengetik).
2. VALIDASI INPUT: JIKA input (Judul, Deskripsi, tautan, atau file) asal-asalan, tidak nyambung, atau tidak masuk akal untuk dijadikan tugas, nyatakan dengan jelas di bagian pemikiranmu: "Judul, Deskripsi, link atau file yang Anda upload tidak sesuai untuk membagikan tugas."
3. Jika input tidak valid, setelah tag [PEMIKIRAN], berikan tag [HASIL] lalu berikan array JSON kosong [].
4. Jika input valid dan masuk akal, setelah tag [PEMIKIRAN], berikan tag [HASIL] dan berikan array JSON berisi subtask-subtask yang diurutkan secara logis.

FORMAT WAJIB HASILMU:
[PEMIKIRAN]
(analisismu di sini...)

[HASIL]
```json
[
  {
    "title": "Riset dan Pengumpulan Data",
    "description": "Mengumpulkan referensi dan data",
    "user_id": "$userId"
  }
]
```
""";

    return _generateTasks(prompt, onStream: onStream);
  }
}
