import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/forms/checkout_phone.dart';
import '../../core/theme/app_colors.dart';
import 'zoovana_ui.dart';

class CountryPhoneField extends StatelessWidget {
  const CountryPhoneField({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.onCountryChanged,
    required this.onChanged,
    this.errorText,
  });
  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCountryChanged, onChanged;
  final String? errorText;
  @override
  Widget build(BuildContext context) {
    final country = CountryParser.parse(
      countryCode.isEmpty ? 'PK' : countryCode,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel('Phone number'.tr, required: false),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [CountryPhoneFormatter(country.countryCode)],
            onChanged: onChanged,
            style: fieldTextStyle,
            decoration:
                filledFieldDecoration(
                  hint: 'Phone number'.tr,
                  errorText: errorText,
                  compact: true,
                ).copyWith(
                  prefixIconConstraints: const BoxConstraints(minWidth: 0),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 8),
                    child: IntrinsicWidth(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          showCountryPicker(
                            context: context,
                            showPhoneCode: true,
                            favorite: const ['PK', 'SA', 'AE', 'GB', 'US'],
                            countryListTheme: CountryListThemeData(
                              bottomSheetHeight:
                                  MediaQuery.sizeOf(context).height * .7,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(22),
                              ),
                              inputDecoration: InputDecoration(
                                labelText: 'Search country'.tr,
                                prefixIcon: const Icon(Icons.search),
                              ),
                            ),
                            onSelect: (value) =>
                                onCountryChanged(value.countryCode),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              country.flagEmoji,
                              style: const TextStyle(fontSize: 21),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '+${country.phoneCode}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}
