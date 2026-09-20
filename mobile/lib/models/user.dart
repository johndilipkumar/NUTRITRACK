/// User profile model.
class User {
  final String id;
  final String email;
  final String? name;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? activityLevel;
  final int dailyCalorieGoal;
  final String? dietaryPreference;
  final String? createdAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.activityLevel,
    this.dailyCalorieGoal = 2000,
    this.dietaryPreference,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      activityLevel: json['activityLevel'] as String?,
      dailyCalorieGoal: json['dailyCalorieGoal'] as int? ?? 2000,
      dietaryPreference: json['dietaryPreference'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activityLevel': activityLevel,
      'dailyCalorieGoal': dailyCalorieGoal,
      'dietaryPreference': dietaryPreference,
    };
  }

  User copyWith({
    String? name,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    int? dailyCalorieGoal,
    String? dietaryPreference,
  }) {
    return User(
      id: id,
      email: email,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      createdAt: createdAt,
    );
  }
}
