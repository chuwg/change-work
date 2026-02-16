import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../services/health_data_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String? _selectedGender;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthYearController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await DatabaseService.instance.getUserProfile();
    if (profile != null) {
      _nameController.text = profile.name ?? '';
      _birthYearController.text =
          profile.birthYear?.toString() ?? '';
      _heightController.text =
          profile.heightCm?.toStringAsFixed(0) ?? '';
      _weightController.text =
          profile.weightKg?.toStringAsFixed(1) ?? '';
      _selectedGender = profile.gender;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    final profile = UserProfile(
      name: _nameController.text.isEmpty ? null : _nameController.text,
      birthYear: int.tryParse(_birthYearController.text),
      gender: _selectedGender,
      heightCm: double.tryParse(_heightController.text),
      weightKg: double.tryParse(_weightController.text),
    );
    await DatabaseService.instance.saveUserProfile(profile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다')),
      );
      Navigator.pop(context, profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('저장',
                style: TextStyle(color: AppTheme.primary, fontSize: 16)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildTextField(
                  label: '이름 (닉네임)',
                  controller: _nameController,
                  hint: '이름을 입력하세요',
                  icon: Icons.person_rounded,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: '출생년도',
                  controller: _birthYearController,
                  hint: '예: 1990',
                  icon: Icons.cake_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGenderSelector(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: '키 (cm)',
                        controller: _heightController,
                        hint: '170',
                        icon: Icons.height_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: '체중 (kg)',
                        controller: _weightController,
                        hint: '65.0',
                        icon: Icons.monitor_weight_rounded,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d{0,3}\.?\d{0,1}')),
                        ],
                      ),
                    ),
                  ],
                ),
                if (Platform.isIOS) ...[
                  const SizedBox(height: 16),
                  _buildHealthDataButton(),
                ],
                const SizedBox(height: 24),
                _buildBmiCard(),
              ],
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: AppTheme.glassCard,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.textTertiary),
              prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '성별',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildGenderChip('male', '남성', Icons.male_rounded),
            const SizedBox(width: 8),
            _buildGenderChip('female', '여성', Icons.female_rounded),
            const SizedBox(width: 8),
            _buildGenderChip('other', '기타', Icons.transgender_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderChip(String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.15)
                : AppTheme.surfaceDarkElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isFetchingHealth = false;

  Future<void> _fetchFromHealthKit() async {
    setState(() => _isFetchingHealth = true);
    try {
      final service = HealthDataService.instance;
      final hasAuth = await service.hasAuthorization();
      if (!hasAuth) {
        final authorized = await service.requestAuthorization();
        if (!authorized) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('건강 데이터 접근 권한이 필요합니다')),
            );
          }
          setState(() => _isFetchingHealth = false);
          return;
        }
      }

      final weight = await service.fetchLatestWeight();
      final height = await service.fetchLatestHeight();

      if (weight == null && height == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('건강 데이터에서 키/체중 정보를 찾을 수 없습니다')),
          );
        }
      } else {
        if (weight != null) {
          _weightController.text = weight.toStringAsFixed(1);
        }
        if (height != null) {
          _heightController.text = height.toStringAsFixed(0);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${height != null ? "키: ${height.toStringAsFixed(0)}cm" : ""}'
                '${height != null && weight != null ? ", " : ""}'
                '${weight != null ? "체중: ${weight.toStringAsFixed(1)}kg" : ""}'
                ' 가져옴',
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('건강 데이터를 가져오는 중 오류가 발생했습니다')),
        );
      }
    }
    setState(() => _isFetchingHealth = false);
  }

  Widget _buildHealthDataButton() {
    return GestureDetector(
      onTap: _isFetchingHealth ? null : _fetchFromHealthKit,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isFetchingHealth)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.favorite_rounded,
                  color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              _isFetchingHealth ? '가져오는 중...' : 'Apple Health에서 키/체중 가져오기',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBmiCard() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    if (height == null || weight == null || height == 0) {
      return const SizedBox.shrink();
    }

    final heightM = height / 100;
    final bmi = weight / (heightM * heightM);
    String category;
    Color color;

    if (bmi < 18.5) {
      category = '저체중';
      color = Colors.blue;
    } else if (bmi < 23) {
      category = '정상';
      color = AppTheme.success;
    } else if (bmi < 25) {
      category = '과체중';
      color = Colors.orange;
    } else {
      category = '비만';
      color = AppTheme.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.monitor_heart_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BMI',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                Text(
                  '${bmi.toStringAsFixed(1)} ($category)',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
