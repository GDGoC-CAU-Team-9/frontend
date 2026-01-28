import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/allergy_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart'; // Fixed import path
import '../../data/models/allergy_model.dart';
import '../../../../core/theme/app_design.dart';

class AllergySelectionScreen extends ConsumerStatefulWidget {
  const AllergySelectionScreen({super.key});

  @override
  ConsumerState<AllergySelectionScreen> createState() =>
      _AllergySelectionScreenState();
}

class _AllergySelectionScreenState
    extends ConsumerState<AllergySelectionScreen> {
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final allergiesAsyncValue = ref.watch(allergiesProvider);
    final myAllergiesAsyncValue = ref.watch(myAllergiesProvider);
    final selectedIds = ref.watch(allergySelectionProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'USER PROFILE',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              color: Colors.black87,
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: SafeArea(
          child: allergiesAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('오류: $err')),
            data: (allAllergies) {
              if (!_isInitialized) {
                myAllergiesAsyncValue.whenData((myAllergies) {
                  Future.microtask(() {
                    if (mounted) {
                      ref
                          .read(allergySelectionProvider.notifier)
                          .initialize(myAllergies);
                      setState(() {
                        _isInitialized = true;
                      });
                    }
                  });
                });
              }

              if (myAllergiesAsyncValue.isLoading && !_isInitialized) {
                return const Center(child: CircularProgressIndicator());
              }

              final selectedAllergies = allAllergies
                  .where((a) => selectedIds.contains(a.id))
                  .toList();

              return Column(
                children: [
                  const SizedBox(height: 10),
                  Consumer(
                    builder: (context, ref, child) {
                      final authState = ref.watch(authProvider);
                      final user = authState.value;
                      return Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white.withOpacity(0.5),
                            child: Text(
                              user?.email.substring(0, 1).toUpperCase() ?? 'A',
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.teal,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user?.email ?? 'Alex\'s Account',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Avoided Ingredients',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: selectedAllergies.length,
                      itemBuilder: (context, index) {
                        final allergy = selectedAllergies[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: AppDesign.glassDecoration.copyWith(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.4),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.black54,
                            ),
                            title: Text(
                              allergy.name,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _handleRemoveAllergy(allergy.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddAllergyDialog(
                          context,
                          allAllergies,
                          selectedIds,
                        ),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'ADD NEW INGREDIENT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleRemoveAllergy(int id) {
    ref.read(allergySelectionProvider.notifier).toggleAllergy(id);
    _saveChanges();
  }

  void _showAddAllergyDialog(
    BuildContext context,
    List<Allergy> allAllergies,
    Set<int> selectedIds,
  ) {
    final availableAllergies = allAllergies
        .where((a) => !selectedIds.contains(a.id))
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              const Text(
                'Add Ingredient',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (availableAllergies.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'All available ingredients are already selected.',
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: availableAllergies.length,
                    itemBuilder: (context, index) {
                      final allergy = availableAllergies[index];
                      return ListTile(
                        title: Text(allergy.name),
                        onTap: () {
                          ref
                              .read(allergySelectionProvider.notifier)
                              .toggleAllergy(allergy.id);
                          _saveChanges();
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    try {
      await ref.read(allergySelectionProvider.notifier).saveMyAllergies();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save changes: $e')));
      }
    }
  }
}
