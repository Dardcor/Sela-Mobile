class LecturerMockData {
  // Data Profil Dosen
  static Map<String, dynamic> lecturerProfile = {
    'name': 'Jokowidodo',
    'role': 'Dosen',
    'avatar': 'assets/images/default_profile.png',
  };

  // Data Kelas yang diampu oleh Dosen
  static List<Map<String, dynamic>> classes = [
    {
      'id': 'c1',
      'name': '2 D3 IT B',
      'total_groups': 20,
      'total_tasks': 15,
      'last_updated': '2 hours ago',
    },
    {
      'id': 'c2',
      'name': '1 D3 IT A',
      'total_groups': 18,
      'total_tasks': 10,
      'last_updated': '1 day ago',
    },
    {
      'id': 'c3',
      'name': '2 D3 IT A',
      'total_groups': 22,
      'total_tasks': 14,
      'last_updated': '3 hours ago',
    },
    {
      'id': 'c4',
      'name': '1 D3 IT B',
      'total_groups': 15,
      'total_tasks': 8,
      'last_updated': '5 mins ago',
    },
  ];

  // Data Tugas berdasarkan Kelas (Contoh untuk '2 D3 IT B')
  static List<Map<String, dynamic>> classTasks = [
    {
      'id': 't1',
      'class_id': 'c1',
      'group_name': 'Kelompok 1',
      'task_name': 'Makalah AWS',
      'progress': 78,
      'date_range': '4 Feb - 10 Mar',
      'subject': 'Praktek Komputasi Awan',
      'completed_tasks': 12,
      'unfinished_tasks': 20,
      'countdown': '12 Days',
      'top_contributors': 'Syahrul, Rafif',
      'recent_update': 'Syahrul has just finished\n"Bab 2: bagaimana cara daftar akun aws"',
      'members': [
        {
          'name': 'Dino Ariel Putra',
          'avatar': 'assets/images/default_profile.png',
          'task_count': '8 SubTask',
          'subtasks': [
            {'name': 'Pendahuluan', 'status': 'Done'},
            {'name': 'Latar belakang', 'status': 'Upcoming'},
            {'name': 'Daftar isi', 'status': 'In progress'},
            {'name': 'Isi', 'status': 'In progress'},
          ]
        },
        {
          'name': 'Rafif',
          'avatar': 'assets/images/default_profile.png',
          'task_count': '10 SubTask',
          'subtasks': [
            {'name': 'Bab 1', 'status': 'Done'},
            {'name': 'Bab 2', 'status': 'Done'},
          ]
        },
        {
          'name': 'Syahrul',
          'avatar': 'assets/images/default_profile.png',
          'task_count': '14 SubTask',
          'subtasks': [
            {'name': 'Kesimpulan', 'status': 'Upcoming'},
          ]
        }
      ]
    },
    {
      'id': 't2',
      'class_id': 'c1',
      'group_name': 'Kelompok 2',
      'task_name': 'Implementasi Docker',
      'progress': 45,
      'date_range': '10 Feb - 20 Mar',
      'subject': 'Praktek Komputasi Awan',
      'completed_tasks': 5,
      'unfinished_tasks': 15,
      'countdown': '22 Days',
      'top_contributors': 'Budi, Andi',
      'recent_update': 'Budi started "Setup Docker Compose"',
      'members': [
        {
          'name': 'Budi',
          'avatar': 'assets/images/default_profile.png',
          'task_count': '5 SubTask',
          'subtasks': [
            {'name': 'Setup Docker', 'status': 'In progress'},
          ]
        }
      ]
    },
  ];
}