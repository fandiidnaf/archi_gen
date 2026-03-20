class FormTemplates {
  static String formPage({
    required String featureName,
    required String className,
  }) =>
      '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/${featureName}_entity.dart';
import '../bloc/${featureName}_bloc.dart';

class ${className}FormPage extends StatefulWidget {
  /// Pass an existing entity to enter edit mode; null for create mode.
  final ${className}Entity? entity;

  const ${className}FormPage({super.key, this.entity});

  bool get isEditing => entity != null;

  @override
  State<${className}FormPage> createState() => _${className}FormPageState();
}

class _${className}FormPageState extends State<${className}FormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entity?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final entity = ${className}Entity(
      id: widget.entity?.id ?? '',
      name: _nameController.text.trim(),
      createdAt: widget.entity?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.isEditing) {
      context.read<${className}Bloc>().add(${className}Update(entity));
    } else {
      context.read<${className}Bloc>().add(${className}Create(entity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<${className}Bloc>(),
      child: BlocConsumer<${className}Bloc, ${className}State>(
        listener: (context, state) {
          if (state is ${className}ActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.of(context).pop(true);
          } else if (state is ${className}Error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ${className}Loading;
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.isEditing ? 'Edit $className' : 'New $className'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Name field ──────────────────────────────────────────
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        hintText: 'Enter name',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // ── TODO: add more fields here ──────────────────────────

                    const SizedBox(height: 32),

                    // ── Submit button ───────────────────────────────────────
                    ElevatedButton(
                      onPressed: isLoading ? null : () => _submit(context),
                      child: isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(widget.isEditing ? 'Save Changes' : 'Create'),
                    ),

                    if (widget.isEditing) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () => _confirmDelete(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete "\${widget.entity!.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<${className}Bloc>().add(${className}Delete(widget.entity!.id));
    }
  }
}
''';
}
