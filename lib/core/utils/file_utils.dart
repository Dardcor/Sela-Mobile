import 'package:flutter/material.dart';

class FileUtils {
  static IconData iconForFileExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  static Color colorForFileExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Colors.red[400]!;
      case 'doc':
      case 'docx':
        return Colors.blue[600]!;
      case 'xls':
      case 'xlsx':
        return Colors.green[600]!;
      case 'ppt':
      case 'pptx':
        return Colors.orange[600]!;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.purple[400]!;
      default:
        return Colors.grey[500]!;
    }
  }
}
