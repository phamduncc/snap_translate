import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/language_model.dart';

class LanguageSelector extends StatelessWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final Function(String source, String target) onLanguagesChanged;

  const LanguageSelector({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.onLanguagesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Expanded(
              child: _buildLanguageDropdown(
                context,
                'Từ',
                sourceLanguage,
                (value) => onLanguagesChanged(value!, targetLanguage),
                showAutoDetect: true,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => _swapLanguages(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.swap_horiz,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildLanguageDropdown(
                context,
                'Sang',
                targetLanguage,
                (value) => onLanguagesChanged(sourceLanguage, value!),
                showAutoDetect: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(
    BuildContext context,
    String label,
    String selectedValue,
    ValueChanged<String?> onChanged, {
    bool showAutoDetect = false,
  }) {
    final languages = LanguageModel.defaultLanguages
        .where((lang) => showAutoDetect || lang.code != 'auto')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondaryColor,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimaryColor,
              ),
              onChanged: onChanged,
              items: languages.map((language) {
                return DropdownMenuItem<String>(
                  value: language.code,
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.languageColors[language.code] ?? 
                                 AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            language.code.toUpperCase().substring(0, 2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          language.nativeName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (language.isOfflineSupported)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _swapLanguages() {
    if (sourceLanguage != 'auto') {
      onLanguagesChanged(targetLanguage, sourceLanguage);
    }
  }
}
