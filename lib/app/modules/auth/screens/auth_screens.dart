import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/forms/input_rules.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../routes/shell_router.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/language_picker.dart';
import '../../../shared/widgets/zoovana_ui.dart';

class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: AnimalPatternBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 29, 20, 8),
              child: Column(
                children: staggered([
                  const _PhotoGrid(),
                  const SizedBox(height: 34),
                  Text.rich(
                    _brandSpan('Welcome to @brand'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Help feed cats and birds in Makkah and Madinah, with local operators and approved photo proof.'
                        .tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 30),
                  PillButton(
                    label: 'Login'.tr,
                    onPressed: () => Get.toNamed(AppRoutes.login),
                  ),
                  const SizedBox(height: 13),
                  PillButton(
                    label: 'I’m new, signup'.tr,
                    style: PillButtonStyle.white,
                    onPressed: () => Get.toNamed(AppRoutes.signup),
                  ),
                  const SizedBox(height: 16),
                  const LanguageButton(),
                  // Guest donations are out: requests need a signed-in donor.
                  // Guest browsing can return if the programme endpoints are
                  // public.
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  bool _submitting = false;
  String? errorText;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = emailController.text.trim();
    if (!InputRules.email(email) || passwordController.text.length < 6) {
      setState(() => errorText = 'Check your email and password.'.tr);
      return;
    }
    setState(() {
      errorText = null;
      _submitting = true;
    });
    try {
      final session = await Get.find<SessionRepository>().signIn(
        email: email,
        password: passwordController.text,
      );
      ShellRouter.open(session);
    } catch (exception) {
      final error = AppErrorMapper.map(exception);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        errorText = error.hasCode(ApiErrorCode.invalidCredentials)
            ? 'Check your email and password.'.tr
            : error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthSheetScaffold(
      image: AppAssets.feedingCatsMakkah,
      filled: true,
      sheetTop: 273,
      header: const _BrandTitle(template: 'Login to @brand'),
      footer: _AuthFooter(
        message: 'Don’t have an account?'.tr,
        action: 'Sign Up'.tr,
        onTap: () => Get.offNamed(AppRoutes.signup),
      ),
      children: [
        LabeledField(
          label: 'Email Address'.tr,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          icon: Iconsax.sms_copy,
          hint: 'Enter Email Address...'.tr,
          errorText: errorText,
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Password'.tr,
          controller: passwordController,
          obscureText: _obscure,
          icon: Iconsax.lock_copy,
          hint: 'Enter Password...'.tr,
          suffix: _VisibilityToggle(
            obscure: _obscure,
            onTap: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: GestureDetector(
            // The auth service has no password-reset endpoint yet, so the
            // OTP screens only run against seed data.
            onTap: () => AppConfig.useRemoteApi
                ? Get.snackbar(
                    'Password reset'.tr,
                    'Password reset isn’t available in the app yet.'.tr,
                  )
                : Get.toNamed(AppRoutes.recoverPassword),
            child: Text(
              'Forgot password?'.tr,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _AuthPrimary(
          label: 'Login'.tr,
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscure = true;
  bool _submitting = false;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (!InputRules.name(name)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Enter your full name.'.tr)));
      return;
    }
    if (!InputRules.email(email) || password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Use a valid email and a password of 8+ characters.'.tr,
          ),
        ),
      );
      return;
    }
    if (password != confirmController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Passwords do not match.'.tr)));
      return;
    }
    setState(() => _submitting = true);
    try {
      final session = await Get.find<SessionRepository>().register(
        fullName: name,
        email: email,
        password: password,
      );
      await Get.find<SharedPreferences>().setString('profile_name', name);
      // Out of charity scope: donors used to finish a local profile (city,
      // address, gender) that the profile API doesn't store. The name comes
      // from this form, so every account routes straight to its shell.
      // if (session.appMode == AppMode.donor) {
      //   Get.offAllNamed(AppRoutes.setupProfile);
      // }
      ShellRouter.open(session);
    } catch (exception) {
      final error = AppErrorMapper.map(exception);
      if (!mounted) return;
      setState(() => _submitting = false);
      final fields = error.fieldErrors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fields.isEmpty ? error.message : fields.values.join('\n'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final toggle = _VisibilityToggle(
      obscure: _obscure,
      onTap: () => setState(() => _obscure = !_obscure),
    );
    return _AuthSheetScaffold(
      image: AppAssets.feedingBirds,
      filled: true,
      sheetTop: 235,
      header: const _BrandTitle(template: 'Signup to @brand'),
      footer: _AuthFooter(
        message: 'Do you have an account?'.tr,
        action: 'Login'.tr,
        onTap: () => Get.offNamed(AppRoutes.login),
      ),
      children: [
        LabeledField(
          label: 'Full Name'.tr,
          controller: nameController,
          icon: Iconsax.user_copy,
          hint: 'Enter Full Name...'.tr,
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Email Address'.tr,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          icon: Iconsax.sms_copy,
          hint: 'Enter Email Address...'.tr,
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Password'.tr,
          controller: passwordController,
          obscureText: _obscure,
          icon: Iconsax.lock_copy,
          hint: 'Enter Password...'.tr,
          suffix: toggle,
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Confirm Password'.tr,
          controller: confirmController,
          obscureText: _obscure,
          icon: Iconsax.lock_copy,
          hint: 'Re-enter Password...'.tr,
          suffix: toggle,
        ),
        const SizedBox(height: 22),
        _AuthPrimary(
          label: 'Signup'.tr,
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  int _step = 0;
  int _secondsLeft = 300;
  Timer? _timer;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refresh);
    _confirmController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 300;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) return timer.cancel();
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _back() {
    if (_step == 0) {
      Get.back<void>();
      return;
    }
    setState(() => _step--);
    if (_step != 1) _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;
    final longEnough = password.length >= 8;
    final matches = password.isNotEmpty && password == _confirmController.text;
    return _AuthSheetScaffold(
      image: AppAssets.feedingMadinah,
      filled: true,
      sheetTop: 272,
      onBack: _back,
      contentKey: _step,
      centeredTitle: (_step == 2 ? 'Set new password' : 'Recover Password').tr,
      subtitle: switch (_step) {
        0 =>
          'Don’t worry Enter your email or phone number\nassociated with your account to receive an OTP code'
              .tr,
        1 => 'We’ve sent a 4-digit verification code to @phone'.trParams({
          'phone': '+1234****56',
        }),
        _ =>
          'create a strong password to protect your account.\nMinimum 8 characters required'
              .tr,
      },
      bottom: PillButton(
        label: const [
          'Send OTP',
          'Verify & continue',
          'Set new password',
        ][_step].tr,
        fontWeight: FontWeight.w400,
        onPressed: switch (_step) {
          0 => () {
            setState(() => _step = 1);
            _startTimer();
          },
          1 => () {
            _timer?.cancel();
            setState(() => _step = 2);
          },
          _ =>
            longEnough && matches ? () => Get.offNamed(AppRoutes.login) : null,
        },
      ),
      children: switch (_step) {
        0 => [
          LabeledField(
            label: 'Email Address'.tr,
            keyboardType: TextInputType.emailAddress,
            icon: Iconsax.sms_copy,
            hint: 'Enter Email Address...'.tr,
          ),
          const _OrDivider(),
          FieldLabel('Phone Number'.tr),
          Row(
            children: [
              Container(
                width: 85,
                height: 47,
                padding: const EdgeInsetsDirectional.only(start: 8, end: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: const Row(
                  children: [
                    Text('🇵🇰', style: TextStyle(fontSize: 17)),
                    SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '+92',
                        maxLines: 1,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    Icon(Iconsax.arrow_down_1_copy, size: 12),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.phone,
                  inputFormatters: [const PhoneInputFormatter()],
                  style: fieldTextStyle,
                  decoration: filledFieldDecoration(
                    icon: Iconsax.call_copy,
                    hint: 'Enter Phone Number'.tr,
                  ),
                ),
              ),
            ],
          ),
        ],
        1 => [
          const SizedBox(height: 84),
          Center(
            child: AppAnimatedLabel(
              '${(_secondsLeft ~/ 60).toString().padLeft(2, '0')}:'
              '${(_secondsLeft % 60).toString().padLeft(2, '0')}',
              value: _secondsLeft,
              style: const TextStyle(color: AppColors.brand, fontSize: 15),
            ),
          ),
          const SizedBox(height: 18),
          const _OtpRow(),
          const SizedBox(height: 27),
          Center(
            child: Text.rich(
              TextSpan(
                text: 'I didn’t receive the code! '.tr,
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: _startTimer,
                      child: Text(
                        'Resend'.tr,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 13.5),
            ),
          ),
        ],
        _ => [
          LabeledField(
            label: 'New Password'.tr,
            controller: _passwordController,
            obscureText: true,
            icon: Iconsax.lock_copy,
            hint: 'Enter Password'.tr,
            suffix: const _VisibilityToggle(obscure: true),
          ),
          const SizedBox(height: 18),
          LabeledField(
            label: 'Confirm Password'.tr,
            controller: _confirmController,
            obscureText: true,
            icon: Iconsax.lock_copy,
            hint: 'Enter Password'.tr,
            suffix: const _VisibilityToggle(obscure: true),
          ),
          const SizedBox(height: 14),
          Text(
            'Password Requirements :'.tr,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          _Requirement(
            label: 'At least 8 characters required'.tr,
            met: longEnough,
          ),
          _Requirement(label: 'Password match'.tr, met: matches),
        ],
      },
    );
  }
}

/// Hero photo with a white sheet overlapping it, as in the auth frames.
class _AuthSheetScaffold extends StatelessWidget {
  const _AuthSheetScaffold({
    required this.image,
    required this.children,
    this.header,
    this.centeredTitle,
    this.subtitle,
    this.bottom,
    this.onBack,
    this.filled = false,
    this.sheetTop,
    this.footer,
    this.contentKey,
  });

  /// Where the sheet starts; defaults to 244 for filled sheets, 268 otherwise.
  final double? sheetTop;

  /// Pinned just above the home indicator, as in the login frames.
  final Widget? footer;

  /// Grey sheet with white fields (signup/login) instead of the white sheet.
  final bool filled;
  final String image;
  final Widget? header;
  final String? centeredTitle;
  final String? subtitle;
  final List<Widget> children;
  final Widget? bottom;
  final VoidCallback? onBack;

  /// Changing it replays the content entrance, e.g. between recovery steps.
  final Object? contentKey;

  @override
  Widget build(BuildContext context) {
    final back = BackArrowButton(onTap: onBack ?? Get.back);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: filled ? AppColors.surfaceBase : Colors.white,
        bottomNavigationBar: footer != null
            ? Padding(
                padding: EdgeInsets.only(bottom: systemNavGap(context)),
                child: footer,
              )
            : bottom == null
            ? null
            : SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: bottom,
                ),
              ),
        body: SingleChildScrollView(
          child: Stack(
            children: [
              Image.asset(
                image,
                height: (sheetTop ?? (filled ? 244 : 268)) + 42,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                margin: EdgeInsets.only(top: sheetTop ?? (filled ? 244 : 268)),
                padding: EdgeInsets.fromLTRB(20, filled ? 26 : 38, 20, 28),
                decoration: BoxDecoration(
                  color: filled ? AppColors.surfaceBase : Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(filled ? 32 : 40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (header != null)
                      Row(
                        children: [
                          back,
                          const SizedBox(width: 4),
                          Expanded(child: header!),
                        ],
                      )
                    else
                      Row(
                        children: [
                          back,
                          Expanded(
                            child: Text(
                              centeredTitle ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                        ],
                      ),
                    for (final (index, child) in staggered([
                      if (subtitle != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF8E8E8E),
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                      SizedBox(
                        height: filled ? (subtitle == null ? 16 : 22) : 32,
                      ),
                      ...children,
                    ]).indexed)
                      KeyedSubtree(
                        key: ValueKey((contentKey, index)),
                        child: child,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Translates [key] and shows its `@brand` as the coral ZOOVANA word, which
/// sits wherever the language puts it.
TextSpan _brandSpan(String key) {
  final [before, ...after] = key.tr.split('@brand');
  return TextSpan(
    text: before,
    children: [
      const TextSpan(
        text: 'ZOOVANA',
        style: TextStyle(color: AppColors.accent),
      ),
      if (after.join().isNotEmpty) TextSpan(text: after.join()),
    ],
  );
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle({required this.template});

  /// Translation key holding `@brand`, e.g. "Login to @brand".
  final String template;

  @override
  Widget build(BuildContext context) => Text.rich(
    _brandSpan(template),
    style: const TextStyle(fontSize: 23.5, fontWeight: FontWeight.w600),
  );
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.obscure, this.onTap});
  final bool obscure;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: IconButton(
      onPressed: onTap,
      tooltip: (obscure ? 'Show password' : 'Hide password').tr,
      icon: AnimatedSwitcher(
        duration: AppMotion.fast,
        switchInCurve: AppMotion.curve,
        switchOutCurve: AppMotion.curve,
        child: Icon(
          obscure ? Iconsax.eye_slash_copy : Iconsax.eye_copy,
          key: ValueKey(obscure),
          color: const Color(0xFFA3A3A3),
          size: 22,
        ),
      ),
    ),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 25),
    child: Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE6E6E6))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR'.tr,
            style: const TextStyle(
              fontFamily: AppTheme.secondaryFontFamily,
              fontSize: 12,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE6E6E6))),
      ],
    ),
  );
}

/// Login/signup action; its label is set in Poppins in the frames.
class _AuthPrimary extends StatelessWidget {
  const _AuthPrimary({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => PillButton(
    label: label,
    fontFamily: AppTheme.secondaryFontFamily,
    fontWeight: FontWeight.w400,
    isLoading: isLoading,
    onPressed: isLoading ? null : onPressed,
  );
}

class _OtpRow extends StatelessWidget {
  const _OtpRow();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(
      6,
      (index) => SizedBox(
        width: 51,
        height: 54,
        child: TextField(
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: const TextStyle(fontSize: 24),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            if (value.isNotEmpty) FocusScope.of(context).nextFocus();
          },
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            border: _otpBorder,
            enabledBorder: _otpBorder,
            focusedBorder: _otpBorder.copyWith(
              borderSide: const BorderSide(color: AppColors.brand),
            ),
          ),
        ),
      ),
    ),
  );

  static final _otpBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
  );
}

class _AuthFooter extends StatelessWidget {
  const _AuthFooter({
    required this.message,
    required this.action,
    required this.onTap,
  });

  final String message;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Flexible(
        child: Text(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15),
        ),
      ),
      TextButton(
        onPressed: onTap,
        child: Text(
          action,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    ],
  );
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.label, required this.met});
  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            end: met ? AppColors.success : AppColors.textTertiary,
          ),
          duration: AppMotion.medium,
          curve: AppMotion.curve,
          builder: (context, color, _) =>
              Icon(Iconsax.tick_circle_copy, color: color, size: 20),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid();

  @override
  Widget build(BuildContext context) {
    Widget photo(String asset, double height) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        asset,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
    return SizedBox(
      height: 405,
      child: Row(
        children: [
          Expanded(
            flex: 218,
            child: Column(
              children: [
                photo(AppAssets.feedingCats, 220),
                const SizedBox(height: 12),
                photo(AppAssets.feedingMakkah, 173),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 126,
            child: Column(
              children: [
                photo(AppAssets.feedingBirds, 197),
                const SizedBox(height: 10),
                photo(AppAssets.feedingMadinah, 198),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
