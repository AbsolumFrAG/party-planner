import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../viewmodels/party_viewmodel.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/custom_button.dart';

class CreatePartyScreen extends StatefulWidget {
  const CreatePartyScreen({super.key});

  @override
  State<CreatePartyScreen> createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends State<CreatePartyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationDetailsController = TextEditingController();
  final _maxParticipantsController = TextEditingController(text: '10');
  final _accessCodeController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isPrivate = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _locationDetailsController.dispose();
    _maxParticipantsController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _createParty() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<PartyViewModel>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await viewModel.createParty(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      location: _locationController.text.trim(),
      locationDetails: _locationDetailsController.text.trim(),
      maxParticipants: int.parse(_maxParticipantsController.text),
      isPrivate: _isPrivate,
      accessCode: _isPrivate ? _accessCodeController.text.trim() : null,
    );

    if (success && mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Soirée créée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop();
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
    final viewModel = context.watch<PartyViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une soirée'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titre
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre de la soirée',
                  hintText: 'Ex: Soirée anniversaire',
                  prefixIcon: Icon(Icons.celebration),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: Validators.validatePartyTitle,
                enabled: !viewModel.isLoading,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Détails de la soirée',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
                validator: Validators.validatePartyDescription,
                enabled: !viewModel.isLoading,
              ),
              const SizedBox(height: 16),

              // Date et heure
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: viewModel.isLoading ? null : _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: viewModel.isLoading ? null : _selectTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime.format(context),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Localisation
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  hintText: 'Ex: 123 rue Example',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: Validators.validateLocation,
                enabled: !viewModel.isLoading,
              ),
              const SizedBox(height: 16),

              // Détails de localisation
              TextFormField(
                controller: _locationDetailsController,
                decoration: const InputDecoration(
                  labelText: 'Détails du lieu',
                  hintText: 'Ex: Code porte, étage, etc.',
                  prefixIcon: Icon(Icons.info),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                enabled: !viewModel.isLoading,
              ),
              const SizedBox(height: 16),

              // Nombre maximum de participants
              TextFormField(
                controller: _maxParticipantsController,
                decoration: const InputDecoration(
                  labelText: 'Nombre maximum de participants',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.validateParticipants(
                  int.tryParse(value ?? ''),
                ),
                enabled: !viewModel.isLoading,
              ),
              const SizedBox(height: 16),

              // Option soirée privée
              SwitchListTile(
                title: const Text('Soirée privée'),
                subtitle: const Text(
                  'Uniquement accessible avec un code d\'accès',
                ),
                value: _isPrivate,
                onChanged: viewModel.isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _isPrivate = value;
                          if (!value) {
                            _accessCodeController.clear();
                          }
                        });
                      },
              ),

              // Code d'accès si soirée privée
              if (_isPrivate) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accessCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Code d\'accès',
                    hintText: 'Ex: ABC123',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.validateAccessCode(
                    value,
                    isRequired: _isPrivate,
                  ),
                  enabled: !viewModel.isLoading,
                ),
              ],

              const SizedBox(height: 24),

              // Bouton de création
              CustomButton(
                text: 'Créer la soirée',
                onPressed: viewModel.isLoading ? null : _createParty,
                isLoading: viewModel.isLoading,
                variant: CustomButtonVariant.primary,
                leftIcon: Icons.celebration,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
