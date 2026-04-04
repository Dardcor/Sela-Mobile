import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AutomaticTaskDivision {
  /// Membagi tugas grup secara otomatis berdasarkan kemampuan (ability) masing-masing anggota.
  /// [members] — list anggota grup, tiap item memiliki key 'profiles' dan 'abilities' (List<String>).
  static Future<List<Map<String, dynamic>>> divideTask({
    required String taskTitle,
    required String taskDescription,
    required List<dynamic> members,
    List<String>? links,
    List<String>? files,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not defined in .env');
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );

    // Bangun daftar anggota beserta kemampuannya
    final membersList = members.map((m) {
      final profile = m['profiles'] ?? {};
      final name = profile['name'] ?? profile['full_name'] ?? 'Unknown Member';
      final userId = profile['id'] ?? '';
      final abilities = (m['abilities'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
          [];
      return {
        'id': userId,
        'name': name,
        'abilities': abilities,
      };
    }).where((m) => (m['id'] as String).isNotEmpty).toList();

    if (membersList.isEmpty) {
      throw Exception('Tidak ada anggota untuk ditetapkan tugas.');
    }

    // Prompt dalam Bahasa Indonesia yang mewajibkan output Bahasa Indonesia
    final prompt = """
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

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (response.text == null || response.text!.isEmpty) {
      throw Exception('AI memberikan respons kosong.');
    }

    try {
      // Bersihkan markdown block jika ada
      String cleanedText = response.text!.trim();
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      } else if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }

      final dynamic decoded = jsonDecode(cleanedText.trim());
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      } else {
        throw Exception('Respons AI bukan array JSON yang valid.');
      }
    } catch (e) {
      throw Exception('Gagal membaca respons AI: ${response.text}');
    }
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
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not defined in .env');
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );

    final abilitiesText = (abilities != null && abilities.isNotEmpty)
        ? 'Kemampuan pengguna: ${abilities.join(', ')}'
        : 'Kemampuan pengguna: tidak terdaftar';

    final prompt = """
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

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (response.text == null || response.text!.isEmpty) {
      throw Exception('AI memberikan respons kosong.');
    }

    try {
      String cleanedText = response.text!.trim();
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      } else if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }

      final dynamic decoded = jsonDecode(cleanedText.trim());
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      } else {
        throw Exception('Respons AI bukan array JSON yang valid.');
      }
    } catch (e) {
      throw Exception('Gagal membaca respons AI: ${response.text}');
    }
  }
}
