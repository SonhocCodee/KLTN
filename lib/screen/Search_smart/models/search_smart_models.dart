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

// ── CẤU HÌNH MÈO ──
const _catConfig = AnimalTypeConfig(
  key: 'cat',
  dbTable: 'cats',
  animalType: 'cat',
  emoji: '🐱',
  nameVi: 'Mèo',
  nameEn: 'Cat',
  questions: [
    QuestionConfig(
      id: 'primary_colors', question: 'Lông màu gì?', emoji: '🎨', column: 'primary_colors', isArray: true,
      options: [
        OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
        OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
        OptionConfig(label: 'Cam / Vàng', emoji: '🟠', value: 'orange'),
        OptionConfig(label: 'Xám / Xanh', emoji: '🔘', value: 'gray'),
        OptionConfig(label: 'Nâu / Kem', emoji: '🟤', value: 'cream'),
      ],
    ),
    QuestionConfig(
      id: 'coat_length', question: 'Lông dài hay ngắn?', emoji: '✂️', column: 'coat_length',
      options: [
        OptionConfig(label: 'Không lông', emoji: '🫥', value: 'hairless'),
        OptionConfig(label: 'Ngắn', emoji: '📏', value: 'short'),
        OptionConfig(label: 'Trung bình', emoji: '📐', value: 'medium'),
        OptionConfig(label: 'Dài / Rất dài', emoji: '🧶', value: 'long'),
      ],
    ),
    QuestionConfig(
      id: 'patterns', question: 'Có hoa văn không?', emoji: '🎭', column: 'patterns', isArray: true,
      options: [
        OptionConfig(label: 'Trơn (1 màu)', emoji: '⬜', value: 'solid'),
        OptionConfig(label: 'Vằn (tabby)', emoji: '🦓', value: 'tabby'),
        OptionConfig(label: 'Hai màu', emoji: '⬛', value: 'bicolor'),
        OptionConfig(label: 'Đốm', emoji: '🔵', value: 'spotted'),
        OptionConfig(label: 'Tam thể', emoji: '🌈', value: 'calico'),
      ],
    ),
    QuestionConfig(
      id: 'has_floppy_ears', question: 'Tai như thế nào?', emoji: '👂', column: 'has_floppy_ears', isBool: true,
      options: [
        OptionConfig(label: 'Tai cụp / xệ', emoji: '🐱', value: true),
        OptionConfig(label: 'Tai dựng nhọn', emoji: '🦊', value: false),
      ],
    ),
    QuestionConfig(
      id: 'is_fluffy', question: 'Lông có bông xù không?', emoji: '☁️', column: 'is_fluffy', isBool: true,
      options: [
        OptionConfig(label: 'Rất bông xù', emoji: '☁️', value: true),
        OptionConfig(label: 'Không xù', emoji: '🪶', value: false),
      ],
    ),
    QuestionConfig(
      id: 'size_category', question: 'Con to hay nhỏ?', emoji: '📏', column: 'size_category',
      options: [
        OptionConfig(label: 'Rất nhỏ (< 3kg)', emoji: '🐭', value: 'small'),
        OptionConfig(label: 'Trung bình', emoji: '🐱', value: 'medium'),
        OptionConfig(label: 'To lớn (> 6kg)', emoji: '🦁', value: 'large'),
      ],
    ),
    QuestionConfig(
      id: 'has_long_tail', question: 'Đuôi dài hay ngắn?', emoji: '〰️', column: 'has_long_tail', isBool: true,
      options: [
        OptionConfig(label: 'Đuôi dài', emoji: '〰️', value: true),
        OptionConfig(label: 'Đuôi ngắn / cụt', emoji: '✂️', value: false),
      ],
    ),
  ],
);

// ── CẤU HÌNH CHÓ ──
const _dogConfig = AnimalTypeConfig(
  key: 'dog',
  dbTable: 'dogs',
  animalType: 'dog',
  emoji: '🐶',
  nameVi: 'Chó',
  nameEn: 'Dog',
  questions: [
    QuestionConfig(
      id: 'size_category', question: 'Con to hay nhỏ?', emoji: '📏', column: 'size_category',
      options: [
        OptionConfig(label: 'Rất nhỏ (< 5kg)', emoji: '🐾', value: 'small'),
        OptionConfig(label: 'Vừa (5–20kg)', emoji: '🐕', value: 'medium'),
        OptionConfig(label: 'To (20–40kg)', emoji: '🦮', value: 'large'),
        OptionConfig(label: 'Khổng lồ (> 40kg)', emoji: '🐻', value: 'giant'),
      ],
    ),
    QuestionConfig(
      id: 'primary_colors', question: 'Lông màu gì?', emoji: '🎨', column: 'primary_colors', isArray: true,
      options: [
        OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
        OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
        OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
        OptionConfig(label: 'Vàng / Vàng đậm', emoji: '🟡', value: 'golden'),
        OptionConfig(label: 'Xám', emoji: '🔘', value: 'gray'),
      ],
    ),
    QuestionConfig(
      id: 'coat_length', question: 'Lông ngắn hay dài?', emoji: '✂️', column: 'coat_length',
      options: [
        OptionConfig(label: 'Ngắn sát', emoji: '📏', value: 'short'),
        OptionConfig(label: 'Trung bình', emoji: '📐', value: 'medium'),
        OptionConfig(label: 'Dài', emoji: '🧶', value: 'long'),
      ],
    ),
    QuestionConfig(
      id: 'has_floppy_ears', question: 'Tai như thế nào?', emoji: '👂', column: 'has_floppy_ears', isBool: true,
      options: [
        OptionConfig(label: 'Tai cụp / xệ', emoji: '🐶', value: true),
        OptionConfig(label: 'Tai dựng nhọn', emoji: '🦊', value: false),
      ],
    ),
    QuestionConfig(
      id: 'patterns', question: 'Lông có hoa văn không?', emoji: '🎭', column: 'patterns', isArray: true,
      options: [
        OptionConfig(label: 'Trơn (1 màu)', emoji: '⬜', value: 'solid'),
        OptionConfig(label: 'Hai màu', emoji: '⬛', value: 'bicolor'),
        OptionConfig(label: 'Đốm / vá', emoji: '🔵', value: 'spotted'),
        OptionConfig(label: 'Vằn', emoji: '🦓', value: 'brindle'),
      ],
    ),
    QuestionConfig(
      id: 'has_mane', question: 'Có bờm lông quanh cổ không?', emoji: '🦁', column: 'has_mane', isBool: true,
      options: [
        OptionConfig(label: 'Có bờm lông dày', emoji: '🦁', value: true),
        OptionConfig(label: 'Không có', emoji: '🐕', value: false),
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
  key: key, dbTable: 'animals', animalType: animalType, emoji: emoji, nameVi: nameVi, nameEn: nameEn, questions: questions,
);

final List<AnimalTypeConfig> allAnimalTypes = [
  _catConfig,
  _dogConfig,
  _makeWildConfig(
    key: 'buffalo', animalType: 'buffalo', emoji: '🐃', nameVi: 'Trâu', nameEn: 'Buffalo',
    questions: const [
      QuestionConfig(id: 'primary_colors', question: 'Màu da / lông?', emoji: '🎨', column: 'primary_colors', isArray: true,
        options: [
          OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
          OptionConfig(label: 'Xám', emoji: '🔘', value: 'gray'),
          OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
        ],
      ),
      QuestionConfig(id: 'has_horns', question: 'Có sừng không?', emoji: '🦬', column: 'has_horns', isBool: true,
        options: [
          OptionConfig(label: 'Có sừng cong lớn', emoji: '🦬', value: true),
          OptionConfig(label: 'Không có sừng', emoji: '❌', value: false),
        ],
      ),
      QuestionConfig(id: 'relative_size', question: 'To bằng cỡ nào?', emoji: '📏', column: 'relative_size',
        options: [
          OptionConfig(label: 'Bằng bò', emoji: '🐃', value: 'large'),
          OptionConfig(label: 'To hơn bò nhiều', emoji: '🦬', value: 'elephant_sized'),
        ],
      ),
    ],
  ),
  _makeWildConfig(
    key: 'cattle', animalType: 'cattle', emoji: '🐄', nameVi: 'Bò', nameEn: 'Cattle',
    questions: const [
      QuestionConfig(id: 'primary_colors', question: 'Màu lông / da?', emoji: '🎨', column: 'primary_colors', isArray: true,
        options: [
          OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
          OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
          OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
          OptionConfig(label: 'Đỏ nâu', emoji: '🔴', value: 'red'),
        ],
      ),
      QuestionConfig(id: 'has_horns', question: 'Có sừng không?', emoji: '🐮', column: 'has_horns', isBool: true,
        options: [
          OptionConfig(label: 'Có sừng', emoji: '🐮', value: true),
          OptionConfig(label: 'Không sừng', emoji: '❌', value: false),
        ],
      ),
      QuestionConfig(id: 'patterns', question: 'Có đốm không?', emoji: '🎭', column: 'patterns', isArray: true,
        options: [
          OptionConfig(label: 'Trơn (1 màu)', emoji: '⬜', value: 'solid'),
          OptionConfig(label: 'Có đốm', emoji: '⚫', value: 'spotted'),
        ],
      ),
    ],
  ),
  _makeWildConfig(
    key: 'horse', animalType: 'horse', emoji: '🐴', nameVi: 'Ngựa', nameEn: 'Horse',
    questions: const [
      QuestionConfig(id: 'primary_colors', question: 'Màu lông?', emoji: '🎨', column: 'primary_colors', isArray: true,
        options: [
          OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
          OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
          OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
          OptionConfig(label: 'Xám', emoji: '🔘', value: 'gray'),
        ],
      ),
      QuestionConfig(id: 'patterns', question: 'Lông có đốm / hoa văn không?', emoji: '🎭', column: 'patterns', isArray: true,
        options: [
          OptionConfig(label: 'Trơn (1 màu)', emoji: '⬜', value: 'solid'),
          OptionConfig(label: 'Có đốm lớn', emoji: '⚫', value: 'pinto'),
          OptionConfig(label: 'Có vằn nhỏ', emoji: '🦓', value: 'striped'),
        ],
      ),
      QuestionConfig(id: 'has_mane', question: 'Bờm có dài rậm không?', emoji: '🦄', column: 'has_mane', isBool: true,
        options: [
          OptionConfig(label: 'Có bờm dài rậm', emoji: '🦄', value: true),
          OptionConfig(label: 'Bờm ngắn / cạo', emoji: '✂️', value: false),
        ],
      ),
      QuestionConfig(id: 'relative_size', question: 'To hay nhỏ?', emoji: '📏', column: 'relative_size',
        options: [
          OptionConfig(label: 'Nhỏ (Pony)', emoji: '🐴', value: 'large'),
          OptionConfig(label: 'To (ngựa đua)', emoji: '🏇', value: 'elephant_sized'),
        ],
      ),
    ],
  ),
  _makeWildConfig(
    key: 'bear', animalType: 'bear', emoji: '🐻', nameVi: 'Gấu', nameEn: 'Bear',
    questions: const [
      QuestionConfig(id: 'primary_colors', question: 'Màu lông?', emoji: '🎨', column: 'primary_colors', isArray: true,
        options: [
          OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
          OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
          OptionConfig(label: 'Trắng / Kem', emoji: '⚪', value: 'white'),
          OptionConfig(label: 'Đen + trắng', emoji: '◑', value: 'black_white'),
        ],
      ),
      QuestionConfig(id: 'relative_size', question: 'Con to cỡ nào?', emoji: '📏', column: 'relative_size',
        options: [
          OptionConfig(label: 'Bằng người lớn', emoji: '🐻', value: 'large'),
          OptionConfig(label: 'To hơn, rất nặng', emoji: '🦬', value: 'elephant_sized'),
        ],
      ),
      QuestionConfig(id: 'primary_habitat', question: 'Sống ở đâu?', emoji: '🌍', column: 'primary_habitat',
        options: [
          OptionConfig(label: 'Rừng lá rộng', emoji: '🌲', value: 'forest'),
          OptionConfig(label: 'Bắc Cực / tuyết', emoji: '❄️', value: 'arctic'),
          OptionConfig(label: 'Rừng nhiệt đới', emoji: '🌴', value: 'tropical_forest'),
          OptionConfig(label: 'Núi cao', emoji: '⛰️', value: 'mountain'),
        ],
      ),
    ],
  ),
  _makeWildConfig(
    key: 'lion', animalType: 'lion', emoji: '🦁', nameVi: 'Sư tử', nameEn: 'Lion',
    questions: const [
      QuestionConfig(id: 'has_mane', question: 'Có bờm quanh đầu không?', emoji: '🦁', column: 'has_mane', isBool: true,
        options: [
          OptionConfig(label: 'Có bờm dày (đực)', emoji: '🦁', value: true),
          OptionConfig(label: 'Không bờm (cái)', emoji: '🐆', value: false),
        ],
      ),
      QuestionConfig(id: 'primary_colors', question: 'Màu lông?', emoji: '🎨', column: 'primary_colors', isArray: true,
        options: [
          OptionConfig(label: 'Vàng / Vàng nhạt', emoji: '🟡', value: 'tan'),
          OptionConfig(label: 'Nâu vàng', emoji: '🟤', value: 'brown'),
          OptionConfig(label: 'Trắng (hiếm)', emoji: '⚪', value: 'white'),
        ],
      ),
      QuestionConfig(id: 'primary_habitat', question: 'Sống ở môi trường nào?', emoji: '🌍', column: 'primary_habitat',
        options: [
          OptionConfig(label: 'Đồng cỏ savanna', emoji: '🌾', value: 'savanna'),
          OptionConfig(label: 'Bụi rậm / rừng thưa', emoji: '🌿', value: 'shrubland'),
        ],
      ),
    ],
  ),
];