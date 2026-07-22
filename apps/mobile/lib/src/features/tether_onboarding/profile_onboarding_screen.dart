import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../api/generated/models/user_response.dart';
import '../../auth/auth_controller.dart';
import '../../core/dio_provider.dart';
import '../settings/legal_policy_screen.dart';
import '../../theme/bub_colors.dart';

class ProfileOnboardingSubmission {
  const ProfileOnboardingSubmission({
    required this.fullName,
    required this.age,
    required this.discoveredAppVia,
  });

  final String fullName;
  final int age;
  final String discoveredAppVia;
}

abstract interface class ProfileOnboardingSubmitter {
  Future<UserResponse> submit(ProfileOnboardingSubmission submission);
}

class DioProfileOnboardingSubmitter implements ProfileOnboardingSubmitter {
  DioProfileOnboardingSubmitter(this._dio);

  final Dio _dio;

  @override
  Future<UserResponse> submit(ProfileOnboardingSubmission submission) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/users/me',
      data: {
        'displayName': submission.fullName,
        'age': submission.age,
        'discoveredAppVia': submission.discoveredAppVia,
        'termsAccepted': true,
      },
    );
    return UserResponse.fromJson(response.data ?? const {});
  }
}

abstract interface class OnboardingPermissionRequester {
  Future<void> requestInitialMediaPermissions();
}

class DeviceOnboardingPermissionRequester
    implements OnboardingPermissionRequester {
  @override
  Future<void> requestInitialMediaPermissions() async {
    await PhotoManager.requestPermissionExtend();

    final scanner = MobileScannerController(autoStart: false);
    try {
      await scanner.start();
      await scanner.stop();
    } catch (_) {
      // The app can still continue; feature screens will show focused errors.
    } finally {
      await scanner.dispose();
    }
  }
}

final profileOnboardingSubmitterProvider = Provider<ProfileOnboardingSubmitter>(
  (ref) => DioProfileOnboardingSubmitter(ref.watch(dioProvider)),
);

final onboardingPermissionRequesterProvider =
    Provider<OnboardingPermissionRequester>(
      (ref) => DeviceOnboardingPermissionRequester(),
    );

class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  ConsumerState<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState
    extends ConsumerState<ProfileOnboardingScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  var _step = 0;
  var _accepted = false;
  var _submitting = false;
  String? _source;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          key: const Key('profile-onboarding-stepper'),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            _Header(step: _step),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: switch (_step) {
                0 => _IdentityStep(
                  nameController: _nameController,
                  ageController: _ageController,
                ),
                1 => _SourceStep(selected: _source, onChanged: _setSource),
                _ => _TermsStep(
                  accepted: _accepted,
                  onChanged: (value) =>
                      setState(() => _accepted = value ?? false),
                ),
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => setState(() {
                              _step -= 1;
                              _error = null;
                            }),
                      child: const Text('Back'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: Key(
                      _step == 2
                          ? 'profile-finish-button'
                          : 'profile-next-button',
                    ),
                    onPressed: _submitting
                        ? null
                        : _step == 2
                        ? _finish
                        : _next,
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_step == 2 ? 'Continue' : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setSource(String value) {
    setState(() {
      _source = value;
      _error = null;
    });
  }

  void _next() {
    if (_step == 0 && !_identityValid()) {
      return;
    }
    if (_step == 1 && _source == null) {
      setState(() => _error = 'Choose where you found Bub');
      return;
    }
    setState(() {
      _step += 1;
      _error = null;
    });
  }

  bool _identityValid() {
    final age = int.tryParse(_ageController.text.trim());
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Enter your full name');
      return false;
    }
    if (age == null || age < 13 || age > 120) {
      setState(() => _error = 'Enter an age from 13 to 120');
      return false;
    }
    return true;
  }

  Future<void> _finish() async {
    if (!_accepted) {
      setState(
        () => _error = 'Accept the Terms and Privacy Policy to continue',
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(onboardingPermissionRequesterProvider)
          .requestInitialMediaPermissions();
      final user = await ref
          .read(profileOnboardingSubmitterProvider)
          .submit(
            ProfileOnboardingSubmission(
              fullName: _nameController.text.trim(),
              age: int.parse(_ageController.text.trim()),
              discoveredAppVia: _source!,
            ),
          );
      await ref
          .read(authControllerProvider.notifier)
          .completeProfileOnboarding(user);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save your profile');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/illustrations/bears/bear2.png',
          height: 132,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10),
        Text(
          'Set up your profile',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).textTheme.displayMedium?.color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Container(
              width: index == step ? 28 : 9,
              height: 9,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index == step
                    ? BubColors.purple
                    : BubColors.purple.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({
    required this.nameController,
    required this.ageController,
  });

  final TextEditingController nameController;
  final TextEditingController ageController;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('identity-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('profile-full-name-field'),
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('profile-age-field'),
          controller: ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Age'),
        ),
      ],
    );
  }
}

class _SourceStep extends StatelessWidget {
  const _SourceStep({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('tiktok', 'TikTok', 'source-tiktok-option'),
      ('playstore', 'Play Store', 'source-playstore-option'),
      ('recommendation', 'Recommendation', 'source-recommendation-option'),
      ('others', 'Others', 'source-others-option'),
    ];
    return Column(
      key: const ValueKey('source-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Where did you find Bub?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ChoiceChip(
              key: Key(option.$3),
              label: Text(option.$2),
              selected: selected == option.$1,
              onSelected: (_) => onChanged(option.$1),
            ),
          ),
      ],
    );
  }
}

class _TermsStep extends StatelessWidget {
  const _TermsStep({required this.accepted, required this.onChanged});

  final bool accepted;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      key: const Key('terms-accept-checkbox'),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      value: accepted,
      onChanged: onChanged,
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('I agree to Bub '),
          _PolicyLink(
            key: const Key('terms-policy-link'),
            label: 'Terms of Service',
            slug: 'terms-of-service',
          ),
          const Text(' and '),
          _PolicyLink(
            key: const Key('privacy-policy-link'),
            label: 'Privacy Policy',
            slug: 'privacy-policy',
          ),
        ],
      ),
      subtitle: const Text('You can review these anytime in Settings.'),
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _PolicyLink extends StatelessWidget {
  const _PolicyLink({super.key, required this.label, required this.slug});

  final String label;
  final String slug;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LegalPolicyScreen(slug: slug),
          ),
        );
      },
      child: Text(label),
    );
  }
}
