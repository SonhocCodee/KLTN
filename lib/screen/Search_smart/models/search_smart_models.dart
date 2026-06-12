class OptionConfig {
  final String label;
  final String emoji;
  final dynamic value;

  const OptionConfig({
    required this.label,
    required this.emoji,
    required this.value,
  });
}

class QuestionConfig {
  final String id;
  final String question;
  final String emoji;
  final String column;
  final List<OptionConfig> options;
  final bool isArray;
  final bool isBool;
  final bool isRange;
  final String? minLabel;
  final String? maxLabel;

  const QuestionConfig({
    required this.id,
    required this.question,
    required this.emoji,
    required this.column,
    this.options = const [],
    this.isArray = false,
    this.isBool = false,
    this.isRange = false,
    this.minLabel,
    this.maxLabel,
  });
}

class AnimalTypeConfig {
  final String key;
  final String dbTable;
  final String animalType;
  final String emoji;
  final String nameVi;
  final String nameEn;
  final List<QuestionConfig> questions;

  const AnimalTypeConfig({
    required this.key,
    required this.dbTable,
    required this.animalType,
    required this.emoji,
    required this.nameVi,
    required this.nameEn,
    required this.questions,
  });
}

// Cấu hình mèo
// Bảng cat_traits: không có id riêng, dùng animal_id JOIN animals
// Chỉ dùng các cột thực tế có trong cat_traits
const _catConfig = AnimalTypeConfig(
  key: 'cat',
  dbTable: 'cat_traits',
  animalType: 'cat',
  emoji: '🐱',
  nameVi: 'Mèo',
  nameEn: 'Cat',
  questions: [
    QuestionConfig(
      id: 'coat_length',
      question: 'Lông dài hay ngắn?',
      emoji: '✂️',
      column: 'coat_length',
      options: [
        OptionConfig(label: 'Ngắn', emoji: '📏', value: 'short'),
        OptionConfig(label: 'Trung bình', emoji: '📐', value: 'medium'),
        OptionConfig(label: 'Dài', emoji: '🧶', value: 'long'),
      ],
    ),
    QuestionConfig(
      id: 'is_fluffy',
      question: 'Lông có bông xù không?',
      emoji: '☁️',
      column: 'is_fluffy',
      isBool: true,
      options: [
        OptionConfig(label: 'Rất bông xù', emoji: '☁️', value: true),
        OptionConfig(label: 'Không xù', emoji: '🪶', value: false),
      ],
    ),
    QuestionConfig(
      id: 'has_floppy_ears',
      question: 'Tai như thế nào?',
      emoji: '👂',
      column: 'has_floppy_ears',
      isBool: true,
      options: [
        OptionConfig(label: 'Tai cụp / xệ', emoji: '🐱', value: true),
        OptionConfig(label: 'Tai dựng thẳng', emoji: '🦊', value: false),
      ],
    ),
    QuestionConfig(
      id: 'has_long_tail',
      question: 'Đuôi dài hay ngắn?',
      emoji: '〰️',
      column: 'has_long_tail',
      isBool: true,
      options: [
        OptionConfig(label: 'Đuôi dài', emoji: '〰️', value: true),
        OptionConfig(label: 'Đuôi ngắn / cụt', emoji: '✂️', value: false),
      ],
    ),
    QuestionConfig(
      id: 'has_stripes',
      question: 'Lông có vằn không?',
      emoji: '🦓',
      column: 'has_stripes',
      isBool: true,
      options: [
        OptionConfig(label: 'Có vằn', emoji: '🦓', value: true),
        OptionConfig(label: 'Không có vằn', emoji: '⬜', value: false),
      ],
    ),
    QuestionConfig(
      id: 'has_spots',
      question: 'Lông có đốm không?',
      emoji: '🔵',
      column: 'has_spots',
      isBool: true,
      options: [
        OptionConfig(label: 'Có đốm', emoji: '🔵', value: true),
        OptionConfig(label: 'Không có đốm', emoji: '⬜', value: false),
      ],
    ),
    QuestionConfig(
      id: 'lap_cat',
      question: 'Thích ngồi trên lòng người không?',
      emoji: '🫂',
      column: 'lap_cat',
      isBool: true,
      options: [
        OptionConfig(label: 'Rất thích', emoji: '😻', value: true),
        OptionConfig(label: 'Thích độc lập', emoji: '🐱', value: false),
      ],
    ),
  ],
);

// Cấu hình chó
// Bảng dog_traits: không có id riêng, dùng animal_id JOIN animals
// Chỉ dùng các cột thực tế có trong dog_traits
const _dogConfig = AnimalTypeConfig(
  key: 'dog',
  dbTable: 'dog_traits',
  animalType: 'dog',
  emoji: '🐶',
  nameVi: 'Chó',
  nameEn: 'Dog',
  questions: [
    QuestionConfig(
      id: 'coat_length',
      question: 'Lông ngắn hay dài?',
      emoji: '✂️',
      column: 'coat_length',
      options: [
        OptionConfig(label: 'Ngắn sát', emoji: '📏', value: 'short'),
        OptionConfig(label: 'Trung bình', emoji: '📐', value: 'medium'),
        OptionConfig(label: 'Dài', emoji: '🧶', value: 'long'),
      ],
    ),
    QuestionConfig(
      id: 'has_floppy_ears',
      question: 'Tai như thế nào?',
      emoji: '👂',
      column: 'has_floppy_ears',
      isBool: true,
      options: [
        OptionConfig(label: 'Tai cụp / xệ', emoji: '🐶', value: true),
        OptionConfig(label: 'Tai dựng nhọn', emoji: '🦊', value: false),
      ],
    ),
    QuestionConfig(
      id: 'is_fluffy',
      question: 'Lông có bông xù không?',
      emoji: '☁️',
      column: 'is_fluffy',
      isBool: true,
      options: [
        OptionConfig(label: 'Rất bông xù', emoji: '☁️', value: true),
        OptionConfig(label: 'Không xù', emoji: '🪶', value: false),
      ],
    ),
    QuestionConfig(
      id: 'has_spots',
      question: 'Lông có đốm không?',
      emoji: '🔵',
      column: 'has_spots',
      isBool: true,
      options: [
        OptionConfig(label: 'Có đốm', emoji: '🔵', value: true),
        OptionConfig(label: 'Không có đốm', emoji: '⬜', value: false),
      ],
    ),
    QuestionConfig(
      id: 'has_stripes',
      question: 'Lông có vằn không?',
      emoji: '🦓',
      column: 'has_stripes',
      isBool: true,
      options: [
        OptionConfig(label: 'Có vằn', emoji: '🦓', value: true),
        OptionConfig(label: 'Không có vằn', emoji: '⬜', value: false),
      ],
    ),
    QuestionConfig(
      id: 'good_with_children',
      question: 'Thân thiện với trẻ em không?',
      emoji: '👶',
      column: 'good_with_children',
      isBool: true,
      options: [
        OptionConfig(label: 'Rất thân thiện', emoji: '😄', value: true),
        OptionConfig(label: 'Cần thận trọng', emoji: '⚠️', value: false),
      ],
    ),
  ],
);

AnimalTypeConfig _makeWildConfig({
  required String key,
  required String animalType,
  required String emoji,
  required String nameVi,
  required String nameEn,
  required List<QuestionConfig> questions,
}) => AnimalTypeConfig(
  key: key,
  dbTable: 'animals',
  animalType: animalType,
  emoji: emoji,
  nameVi: nameVi,
  nameEn: nameEn,
  questions: questions,
);

final List<AnimalTypeConfig> allAnimalTypes = [
  _catConfig,
  _dogConfig,
  _makeWildConfig(
    key: 'buffalo',
    animalType: 'buffalo',
    emoji: '🐃',
    nameVi: 'Trâu',
    nameEn: 'Buffalo',
    questions: const [
      QuestionConfig(
        id: 'primary_colors',
        question: 'Màu da / lông?',
        emoji: '🎨',
        column: 'primary_colors',
        isArray: true,
        options: [
          OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
          OptionConfig(label: 'Xám', emoji: '🔘', value: 'gray'),
          OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
        ],
      ),
      QuestionConfig(
        id: 'has_horns',
        question: 'Có sừng không?',
        emoji: '🦬',
        column: 'has_horns',
        isBool: true,
        options: [
          OptionConfig(label: 'Có sừng cong lớn', emoji: '🦬', value: true),
          OptionConfig(label: 'Không có sừng', emoji: '❌', value: false),
        ],
      ),
      QuestionConfig(
        id: 'relative_size',
        question: 'To bằng cỡ nào?',
        emoji: '📏',
        column: 'relative_size',
        options: [
          OptionConfig(label: 'Bằng bò', emoji: '🐃', value: 'large'),
          OptionConfig(
            label: 'To hơn bò nhiều',
            emoji: '🦬',
            value: 'elephant_sized',
          ),
        ],
      ),
    ],
  ),
  _makeWildConfig(
    key: 'cattle',
    animalType: 'cattle',
    emoji: '🐄',
    nameVi: 'Bò',
    nameEn: 'Cattle',
    questions: const [
      QuestionConfig(
        id: 'primary_colors',
        question: 'Màu lông / da?',
        emoji: '🎨',
        column: 'primary_colors',
        isArray: true,
        options: [
          OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
          OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
          OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
          OptionConfig(label: 'Đỏ nâu', emoji: '🔴', value: 'red'),
        ],
      ),
      QuestionConfig(
        id: 'has_horns',
        question: 'Có sừng không?',
        emoji: '🐮',
        column: 'has_horns',
        isBool: true,
        options: [
          OptionConfig(label: 'Có sừng', emoji: '🐮', value: true),
          OptionConfig(label: 'Không sừng', emoji: '❌', value: false),
        ],
      ),
      QuestionConfig(
        id: 'patterns',
        question: 'Có đốm không?',
        emoji: '🎭',
        column: 'patterns',
        isArray: true,
        options: [
          OptionConfig(label: 'Trơn (1 màu)', emoji: '⬜', value: 'solid'),
          OptionConfig(label: 'Có đốm', emoji: '⚫', value: 'spotted'),
        ],
      ),
    ],
  ),
  _makeWildConfig(
    key: 'horse',
    animalType: 'horse',
    emoji: '🐴',
    nameVi: 'Ngựa',
    nameEn: 'Horse',
    questions: const [
      QuestionConfig(
        id: 'primary_colors',
        question: 'Màu lông?',
        emoji: '🎨',
        column: 'primary_colors',
        isArray: true,
        options: [
          OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
          OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
          OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
          OptionConfig(label: 'Xám', emoji: '🔘', value: 'gray'),
        ],
      ),
      QuestionConfig(
        id: 'patterns',
        question: 'Lông có đốm / hoa văn không?',
        emoji: '🎭',
        column: 'patterns',
        isArray: true,
        options: [
          OptionConfig(label: 'Trơn (1 màu)', emoji: '⬜', value: 'solid'),
          OptionConfig(label: 'Có đốm lớn', emoji: '⚫', value: 'pinto'),
          OptionConfig(label: 'Có vằn nhỏ', emoji: '🦓', value: 'striped'),
        ],
      ),
      QuestionConfig(
        id: 'has_mane',
        question: 'Bờm có dài rậm không?',
        emoji: '🦄',
        column: 'has_mane',
        isBool: true,
        options: [
          OptionConfig(label: 'Có bờm dài rậm', emoji: '🦄', value: true),
          OptionConfig(label: 'Bờm ngắn / cạo', emoji: '✂️', value: false),
        ],
      ),
      QuestionConfig(
        id: 'relative_size',
        question: 'To hay nhỏ?',
        emoji: '📏',
        column: 'relative_size',
        options: [
          OptionConfig(label: 'Nhỏ (Pony)', emoji: '🐴', value: 'large'),
          OptionConfig(
            label: 'To (ngựa đua)',
            emoji: '🏇',
            value: 'elephant_sized',
          ),
        ],
      ),
    ],
  ),
  _makeWildConfig(
    key: 'bear',
    animalType: 'bear',
    emoji: '🐻',
    nameVi: 'Gấu',
    nameEn: 'Bear',
    questions: const [
      QuestionConfig(
        id: 'primary_colors',
        question: 'Màu lông?',
        emoji: '🎨',
        column: 'primary_colors',
        isArray: true,
        options: [
          OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
          OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
          OptionConfig(label: 'Trắng / Kem', emoji: '⚪', value: 'white'),
          OptionConfig(label: 'Đen + trắng', emoji: '◑', value: 'black_white'),
        ],
      ),
      QuestionConfig(
        id: 'relative_size',
        question: 'Con to cỡ nào?',
        emoji: '📏',
        column: 'relative_size',
        options: [
          OptionConfig(label: 'Bằng người lớn', emoji: '🐻', value: 'large'),
          OptionConfig(
            label: 'To hơn, rất nặng',
            emoji: '🦬',
            value: 'elephant_sized',
          ),
        ],
      ),
      QuestionConfig(
        id: 'primary_habitat',
        question: 'Sống ở đâu?',
        emoji: '🌍',
        column: 'primary_habitat',
        options: [
          OptionConfig(label: 'Rừng lá rộng', emoji: '🌲', value: 'forest'),
          OptionConfig(label: 'Bắc Cực / tuyết', emoji: '❄️', value: 'arctic'),
          OptionConfig(
            label: 'Rừng nhiệt đới',
            emoji: '🌴',
            value: 'tropical_forest',
          ),
          OptionConfig(label: 'Núi cao', emoji: '⛰️', value: 'mountain'),
        ],
      ),
    ],
  ),
  _makeWildConfig(
    key: 'lion',
    animalType: 'lion',
    emoji: '🦁',
    nameVi: 'Sư tử',
    nameEn: 'Lion',
    questions: const [
      QuestionConfig(
        id: 'has_mane',
        question: 'Có bờm quanh đầu không?',
        emoji: '🦁',
        column: 'has_mane',
        isBool: true,
        options: [
          OptionConfig(label: 'Có bờm dày (đực)', emoji: '🦁', value: true),
          OptionConfig(label: 'Không bờm (cái)', emoji: '🐆', value: false),
        ],
      ),
      QuestionConfig(
        id: 'primary_colors',
        question: 'Màu lông?',
        emoji: '🎨',
        column: 'primary_colors',
        isArray: true,
        options: [
          OptionConfig(label: 'Vàng / Vàng nhạt', emoji: '🟡', value: 'tan'),
          OptionConfig(label: 'Nâu vàng', emoji: '🟤', value: 'brown'),
          OptionConfig(label: 'Trắng (hiếm)', emoji: '⚪', value: 'white'),
        ],
      ),
      QuestionConfig(
        id: 'primary_habitat',
        question: 'Sống ở môi trường nào?',
        emoji: '🌍',
        column: 'primary_habitat',
        options: [
          OptionConfig(label: 'Đồng cỏ savanna', emoji: '🌾', value: 'savanna'),
          OptionConfig(
            label: 'Bụi rậm / rừng thưa',
            emoji: '🌿',
            value: 'shrubland',
          ),
        ],
      ),
    ],
  ),

  _makeWildConfig(
    key: 'fish',
    animalType: 'fish',
    emoji: '🐟',
    nameVi: 'Cá',
    nameEn: 'Fish',
    questions: const [
      QuestionConfig(
        id: 'primary_habitat',
        question: 'Cá sống ở môi trường nào?',
        emoji: '🌊',
        column: 'primary_habitat',
        options: [
          OptionConfig(label: 'Nước ngọt', emoji: '🏞️', value: 'freshwater'),
          OptionConfig(label: 'Biển / đại dương', emoji: '🌊', value: 'ocean'),
          OptionConfig(label: 'Vùng nước lợ', emoji: '🌅', value: 'brackish'),
          OptionConfig(label: 'Sống đáy', emoji: '🪨', value: 'benthic'),
        ],
      ),
      QuestionConfig(
        id: 'diet_type',
        question: 'Kiểu ăn của cá?',
        emoji: '🍽️',
        column: 'diet_type',
        options: [
          OptionConfig(label: 'Ăn thịt', emoji: '🦈', value: 'carnivore'),
          OptionConfig(label: 'Ăn tạp', emoji: '🐟', value: 'omnivore'),
          OptionConfig(label: 'Ăn thực vật', emoji: '🌿', value: 'herbivore'),
          OptionConfig(
            label: 'Ăn sinh vật phù du',
            emoji: '🫧',
            value: 'planktivore',
          ),
        ],
      ),
      QuestionConfig(
        id: 'relative_size',
        question: 'Kích thước cá?',
        emoji: '📏',
        column: 'relative_size',
        options: [
          OptionConfig(label: 'Nhỏ', emoji: '🐠', value: 'small'),
          OptionConfig(label: 'Vừa', emoji: '🐟', value: 'medium'),
          OptionConfig(label: 'Lớn', emoji: '🐡', value: 'large'),
          OptionConfig(label: 'Rất lớn', emoji: '🦈', value: 'giant'),
        ],
      ),
      QuestionConfig(
        id: 'conservation_status',
        question: 'Tình trạng bảo tồn?',
        emoji: '🛡️',
        column: 'conservation_status',
        options: [
          OptionConfig(
            label: 'Ít quan tâm',
            emoji: '✅',
            value: 'Least Concern',
          ),
          OptionConfig(
            label: 'Sắp bị đe dọa',
            emoji: '⚠️',
            value: 'Near Threatened',
          ),
          OptionConfig(
            label: 'Dễ tổn thương',
            emoji: '🟠',
            value: 'Vulnerable',
          ),
          OptionConfig(label: 'Nguy cấp', emoji: '🔴', value: 'Endangered'),
        ],
      ),
    ],
  ),
  _makeWildConfig(
    key: 'bird',
    animalType: 'bird',
    emoji: '🐦',
    nameVi: 'Chim',
    nameEn: 'Bird',
    questions: const [
      QuestionConfig(
        id: 'primary_habitat',
        question: 'Chim sống chủ yếu ở đâu?',
        emoji: '🌍',
        column: 'primary_habitat',
        options: [
          OptionConfig(label: 'Rừng', emoji: '🌲', value: 'forest'),
          OptionConfig(label: 'Đất liền', emoji: '🌾', value: 'terrestrial'),
          OptionConfig(
            label: 'Nước ngọt / đầm lầy',
            emoji: '🦆',
            value: 'freshwater',
          ),
          OptionConfig(label: 'Biển / ven biển', emoji: '🌊', value: 'ocean'),
          OptionConfig(label: 'Sa mạc', emoji: '🏜️', value: 'desert'),
        ],
      ),
      QuestionConfig(
        id: 'diet_type',
        question: 'Chim ăn gì là chính?',
        emoji: '🍽️',
        column: 'diet_type',
        options: [
          OptionConfig(
            label: 'Ăn côn trùng',
            emoji: '🐛',
            value: 'insectivore',
          ),
          OptionConfig(label: 'Ăn cá', emoji: '🐟', value: 'piscivore'),
          OptionConfig(label: 'Ăn mật hoa', emoji: '🌺', value: 'nectarivore'),
          OptionConfig(label: 'Ăn thịt', emoji: '🦅', value: 'carnivore'),
          OptionConfig(label: 'Ăn tạp', emoji: '🐦', value: 'omnivore'),
          OptionConfig(label: 'Ăn thực vật', emoji: '🌿', value: 'herbivore'),
        ],
      ),
      QuestionConfig(
        id: 'locomotion',
        question: 'Cách di chuyển nổi bật?',
        emoji: '🪽',
        column: 'locomotion',
        options: [
          OptionConfig(label: 'Bay', emoji: '🪽', value: 'flying'),
          OptionConfig(label: 'Đi bộ / chạy', emoji: '🐧', value: 'walking'),
          OptionConfig(label: 'Bơi', emoji: '🦆', value: 'swimming'),
        ],
      ),
      QuestionConfig(
        id: 'activity_pattern',
        question: 'Hoạt động vào lúc nào?',
        emoji: '⏰',
        column: 'activity_pattern',
        options: [
          OptionConfig(label: 'Ban ngày', emoji: '☀️', value: 'diurnal'),
          OptionConfig(label: 'Ban đêm', emoji: '🌙', value: 'nocturnal'),
        ],
      ),
      QuestionConfig(
        id: 'conservation_status',
        question: 'Tình trạng bảo tồn?',
        emoji: '🛡️',
        column: 'conservation_status',
        options: [
          OptionConfig(
            label: 'Ít quan tâm',
            emoji: '✅',
            value: 'Least Concern',
          ),
          OptionConfig(
            label: 'Sắp bị đe dọa',
            emoji: '⚠️',
            value: 'Near Threatened',
          ),
          OptionConfig(
            label: 'Dễ tổn thương',
            emoji: '🟠',
            value: 'Vulnerable',
          ),
          OptionConfig(label: 'Nguy cấp', emoji: '🔴', value: 'Endangered'),
        ],
      ),
    ],
  ),
];
