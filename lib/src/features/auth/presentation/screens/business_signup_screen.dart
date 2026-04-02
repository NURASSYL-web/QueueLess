import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:queue/src/core/constants/app_colors.dart';
import 'package:queue/src/core/widgets/brand_logo.dart';
import 'package:queue/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:queue/src/shared/models/app_plan.dart';
import 'package:queue/src/shared/models/user_role.dart';

class BusinessSignupScreen extends StatefulWidget {
  const BusinessSignupScreen({super.key});

  @override
  State<BusinessSignupScreen> createState() => _BusinessSignupScreenState();
}

class _BusinessSignupScreenState extends State<BusinessSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<AuthController>();
    final success = await controller.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: UserRole.business,
    );

    if (!mounted || success) return;
    final error = controller.error;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final plan = AppPlans.businessDemo;

    return Scaffold(
      appBar: AppBar(title: const Text('Business Registration')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: BrandLogo(height: 72),
          ),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QueueLess for business',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Business accounts help cafés, banks, and clinics manage queue visibility and attract more nearby users.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                ...const [
                  'Attract more customers through map discovery',
                  'Control your own place and queue updates',
                  'Prepare for future analytics and AI recommendations',
                ].map(
                  (item) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppColors.accentSoft,
                        ),
                        SizedBox(width: 10),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF102638), Color(0xFF17324A)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(plan.name, style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    Text(
                      '${plan.priceTenge} ₸',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(plan.tagline),
                const SizedBox(height: 8),
                Text(
                  'This is a demo subscription now. Payment flow can be connected later without changing the account model.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create owner account',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Business email',
                      hintText: 'owner@brand.kz',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'At least 6 characters',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'After registration, go to Profile -> Manage My Place to add your branch on the map.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isLoading ? null : _submit,
                      child: Text(
                        controller.isLoading
                            ? 'Activating business demo...'
                            : 'Start demo for 490 ₸',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
