import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AutomaticTaskDivision {
  static const _modelName = 'gemini-2.5-flash';

  static GenerativeModel _createModel() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not defined in .env');
    }

    return GenerativeModel(model: _modelName, apiKey: apiKey);
  }

  static Future<List<Map<String, dynamic>>> _generateTasks(
    String prompt, {
    List<DataPart>? fileParts,
  }) async {
    final parts = <Part>[TextPart(prompt)];
    if (fileParts != null && fileParts.isNotEmpty) {
      parts.addAll(fileParts);
    }

    try {
      final response = await _createModel().generateContent([
        Content.multi(parts),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Server AI sedang sibuk. Silakan coba beberapa saat lagi.');
      }

      final dynamic decoded = jsonDecode(_stripMarkdownFence(text));
      if (decoded is! List) {
        throw Exception('Server AI gagal memproses data dengan benar. Silakan coba lagi.');
      }

      return List<Map<String, dynamic>>.from(decoded);
    } on GenerativeAIException catch (e) {
      throw Exception('Server AI sedang sibuk atau kelebihan muatan. Silakan coba beberapa saat lagi.');
    } catch (e) {
      if (e.toString().contains('Server AI')) {
        rethrow;
      }
      throw Exception('Terjadi gangguan koneksi dengan sistem AI. Pastikan internet stabil lalu coba lagi.');
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
1. Pahami dengan sangat detail apa konteks dari tugas utama ini (berdasarkan judul, deskripsi, tautan, dan file). Jangan asal menebak.
2. Pecah tugas utama tersebut menjadi beberapa sub-tugas yang SPESIFIK dan BISA DIKERJAKAN.
3. Cocokkan sifat dari setiap sub-tugas dengan keahlian (abilities) spesifik yang dimiliki anggota di daftar JSON tersebut.
4. JIKA ada anggota yang ahli desain, beri dia tugas mendesain. JIKA ada yang ahli coding, beri dia tugas programming.
5. SETIAP ANGGOTA WAJIB MENDAPATKAN MINIMAL SATU TUGAS. Jangan ada yang menganggur.

Kembalikan HANYA format array JSON yang valid persis seperti di bawah ini tanpa blok teks markdown apa pun.
[
  {
    "title": "Judul spesifik sub-tugas",
    "description": "Langkah detail apa yang harus dia kerjakan berdasarkan tautan/file",
    "user_id": "masukkan id anggota yang cocok dari json di atas"
  }
]
""";

    return _generateTasks(prompt, fileParts: fileParts);
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

Tugasmu adalah menyusun subtask-subtask dari tugas ini secara otomatis berdasarkan deskripsi, link referensi, dan file yang dilampirkan. Urutkan subtask mulai dari yang harus dikerjakan terlebih dahulu (urutan prioritas logis). Pertimbangkan kemampuan pengguna jika tersedia.

Kembalikan HANYA array JSON yang valid tanpa blok markdown. Tiap objek berisi:
- "title": judul singkat subtask dalam Bahasa Indonesia
- "description": penjelasan subtask dalam Bahasa Indonesia
- "user_id": "$userId"

Contoh output:
[
  {
    "title": "Riset dan Pengumpulan Data",
    "description": "Mengumpulkan referensi dan data yang dibutuhkan untuk tugas ini",
    "user_id": "$userId"
  },
  {
    "title": "Membuat Kerangka",
    "description": "Menyusun outline atau kerangka pengerjaan tugas",
    "user_id": "$userId"
  }
]
""";

    return _generateTasks(prompt);
  }
}
