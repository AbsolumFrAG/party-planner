import 'package:flutter/material.dart';
import 'package:partyplanner/config/routes.dart';
import 'package:partyplanner/core/utils/validators.dart';
import 'package:partyplanner/viewmodels/auth_viewmodel.dart';
import 'package:partyplanner/views/widgets/custom_button.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AuthViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await viewModel.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _displayNameController.text.trim(),
    );

    if (success && mounted) {
      Routes.navigateToParties(context);
    } else if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(viewModel.error ?? 'Une erreur est survenue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo ou illustration
              const SizedBox(height: 40),
              Icon(
                Icons.party_mode,
                size: 100,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 32),

              // Titre
              Text(
                'Créez votre compte',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Champ Nom d'affichage
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: "Nom d'affichage",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: Validators.validateUsername,
                enabled: !viewModel.isLoading,
              ),
              const SizedBox(height: 16),

              // Champ Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.validateEmail,
                enabled: !viewModel.isLoading,
              ),
              const SizedBox(height: 16),

              // Champ Mot de passe
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                validator: Validators.validatePassword,
                enabled: !viewModel.isLoading,
              ),
              const SizedBox(height: 16),

              // Champ Confirmation du mot de passe
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmez le mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                validator: (value) => Validators.validatePasswordConfirmation(
                  value,
                  _passwordController.text,
                ),
                enabled: !viewModel.isLoading,
              ),
              const SizedBox(height: 24),

              // Bouton d'inscription
              CustomButton(
                text: "S'inscrire",
                onPressed: viewModel.isLoading ? null : _register,
                isLoading: viewModel.isLoading,
                variant: CustomButtonVariant.primary,
                isFullWidth: true,
              ),
              const SizedBox(height: 16),

              // Lien vers la connexion
              TextButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () =>
                        Navigator.of(context).pushReplacementNamed('/login'),
                child: RichText(
                  text: TextSpan(
                    text: 'Déjà un compte ? ',
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: 'Connectez-vous',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
