import 'package:flutter/material.dart';
import 'package:partyplanner/config/routes.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AuthViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await viewModel.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
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

  void _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final viewModel = context.read<AuthViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await viewModel.resetPassword(email);

    if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Instructions envoyées à votre email'
                : viewModel.error ?? 'Une erreur est survenue',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
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
        title: const Text('Connexion'),
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
                Icons.celebration,
                size: 100,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 32),

              // Titre
              Text(
                'Bon retour parmi nous !',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

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
                autocorrect: false,
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
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                enabled: !viewModel.isLoading,
              ),
              const SizedBox(height: 8),

              // Ligne "Se souvenir de moi" et "Mot de passe oublié"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: viewModel.isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                      ),
                      Text(
                        'Se souvenir de moi',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: viewModel.isLoading ? null : _forgotPassword,
                    child: Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bouton de connexion
              CustomButton(
                text: 'Se connecter',
                onPressed: viewModel.isLoading ? null : _login,
                isLoading: viewModel.isLoading,
                variant: CustomButtonVariant.primary,
                isFullWidth: true,
              ),
              const SizedBox(height: 16),

              // Séparateur
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OU',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Lien vers l'inscription
              TextButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () =>
                        Navigator.of(context).pushReplacementNamed('/register'),
                child: RichText(
                  text: TextSpan(
                    text: 'Pas encore de compte ? ',
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: 'Inscrivez-vous',
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
