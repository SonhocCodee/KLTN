import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screen/models/animal_data.dart';

class AnimalApiService {
  // API Ninjas (Thông tin động vật)
  static const String _ninjasBaseUrl = 'https://api.api-ninjas.com/v1/animals';
  static const String _ninjasApiKey = '6Iuf5OY4tyKp0LzSqwLhIwEE4eCzRcXa9teNFT7m'; // Key hiện tại của bạn

  // API Pixabay (Hình ảnh) - ĐĂNG KÝ MIỄN PHÍ TẠI pixabay.com/api/docs/
  // Sau khi đăng ký, copy key của bạn paste vào đây:
  static const String _pixabayUrl = 'https://pixabay.com/api/';
  static const String _pixabayKey = 'Y54250368-3e02b997bbfb975c685ca2fbc';

  // Danh sách động vật
  static const List<String> _animalNames = [
    'lion', 'tiger', 'elephant', 'bear', 'wolf', 'eagle', 'dolphin', 'shark',
    'panda', 'giraffe', 'zebra', 'cheetah', 'gorilla', 'penguin', 'kangaroo',
    'koala', 'rhino', 'hippo', 'leopard', 'jaguar',
  ];

  static String getAnimalOfTheDay() {
    final now = DateTime.now();
    final daysSinceEpoch = now.difference(DateTime(2024, 1, 1)).inDays;
    final index = daysSinceEpoch % _animalNames.length;
    return _animalNames[index];
  }

  // Hàm mới: Fetch ảnh từ Pixabay có Debug Log
  Future<String?> _fetchPixabayImage(String query) async {
    if (_pixabayKey == '54250368-3e02b997bbfb975c685ca2fbc') {
      print('⚠️ CHƯA CẤU HÌNH KEY PIXABAY. Vui lòng lấy key tại pixabay.com');
      return null;
    }

    try {
      print('🔍 Pixabay: Đang tìm ảnh cho từ khóa "$query"...');
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_pixabayUrl?key=$_pixabayKey&q=$encodedQuery&image_type=photo&per_page=3';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['hits'] != null && (data['hits'] as List).isNotEmpty) {
          final imageUrl = data['hits'][0]['largeImageURL']; // Lấy ảnh chất lượng cao
          print('✅ Pixabay: Đã tìm thấy ảnh -> $imageUrl');
          return imageUrl;
        } else {
          print('⚠️ Pixabay: Không có kết quả nào cho "$query"');
        }
      } else {
        print('❌ Pixabay Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Pixabay Exception: $e');
    }
    return null;
  }

  Future<AnimalData?> fetchAnimalInfo(String animalName) async {
    try {
      // 1. Lấy thông tin từ API Ninjas
      final response = await http.get(
        Uri.parse('$_ninjasBaseUrl?name=$animalName'),
        headers: {'X-Api-Key': _ninjasApiKey},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final animalMap = data[0] as Map<String, dynamic>;

          // 2. Lấy ảnh từ Pixabay (Thử tên thường gọi trước)
          String? imageUrl = await _fetchPixabayImage(animalName);

          // 3. Nếu không có, thử tìm bằng tên khoa học
          if (imageUrl == null) {
            final scientificName = animalMap['taxonomy']?['scientific_classification'];
            if (scientificName != null) {
              print('🔄 Thử tìm lại bằng tên khoa học: $scientificName');
              imageUrl = await _fetchPixabayImage(scientificName);
            }
          }

          // 4. Inject ảnh vào dữ liệu để AnimalData sử dụng
          animalMap['custom_image_url'] = imageUrl;

          return AnimalData.fromJson(animalMap);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching animal data: $e');
      return null;
    }
  }

  Future<AnimalData?> getTodayAnimal() async {
    final animalName = getAnimalOfTheDay();
    return await fetchAnimalInfo(animalName);
  }
}