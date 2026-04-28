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

    final response = await _createModel().generateContent([
      Content.multi(parts),
    ]);

    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('AI memberikan respons kosong.');
    }

    try {
      final dynamic decoded = jsonDecode(_stripMarkdownFence(text));
      if (decoded is! List) {
        throw Exception('Respons AI bukan array JSON yang valid.');
      }

      return List<Map<String, dynamic>>.from(decoded);
    } catch (_) {
      throw Exception('Gagal membaca respons AI: $text');
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
Kamu adalah asisten pembagi tugas yang cerdas. Semua respons WAJIB menggunakan Bahasa Indonesia.

Tugas utama: "$taskTitle"
Deskripsi: "$taskDescription"
${links != null && links.isNotEmpty ? "Link referensi:\n${links.join('\n')}\n" : ""}
${files != null && files.isNotEmpty ? "File yang dilampirkan:\n${files.join('\n')}\n" : ""}

Anggota tim beserta kemampuan mereka:
${jsonEncode(membersList)}

Tugasmu adalah membagi tugas utama menjadi beberapa subtask yang merata di antara anggota. Setiap anggota WAJIB mendapatkan minimal satu subtask. Pertimbangkan kemampuan (abilities) masing-masing anggota saat membagi tugas — berikan subtask yang sesuai dengan kemampuan anggota tersebut. Jika anggota tidak memiliki kemampuan terdaftar, bagi secara merata.

Kembalikan HANYA array JSON yang valid tanpa blok markdown. Tiap objek berisi:
- "title": judul singkat subtask dalam Bahasa Indonesia
- "description": penjelasan subtask dalam Bahasa Indonesia
- "user_id": ID anggota yang ditugaskan (gunakan ID yang persis sama)

Contoh output:
[
  {
    "title": "Desain Antarmuka",
    "description": "Membuat tampilan dashboard utama aplikasi",
    "user_id": "member-id-1"
  },
  {
    "title": "Integrasi API",
    "description": "Menghubungkan frontend dengan layanan backend",
    "user_id": "member-id-2"
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
