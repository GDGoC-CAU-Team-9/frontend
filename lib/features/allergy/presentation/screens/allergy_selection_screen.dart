import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/allergy_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('알레르기 설정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleSaveAndExit(context),
        ),
      ),
      body: allergiesAsyncValue.when(
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

          if (myAllergiesAsyncValue.hasError) {
            return Center(
              child: Text(
                '내 알러지 목록을 불러오는데 실패했습니다: ${myAllergiesAsyncValue.error}',
              ),
            );
          }

          final selectedIds = ref.watch(allergySelectionProvider);

          return ListView.builder(
            itemCount: allAllergies.length,
            itemBuilder: (context, index) {
              final allergy = allAllergies[index];
              final isSelected = selectedIds.contains(allergy.id);

              return CheckboxListTile(
                title: Text(allergy.name),
                value: isSelected,
                onChanged: (_) {
                  ref
                      .read(allergySelectionProvider.notifier)
                      .toggleAllergy(allergy.id);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleSaveAndExit(BuildContext context) async {
    try {
      await ref.read(allergySelectionProvider.notifier).saveMyAllergies();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알러지 설정이 저장되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    }
  }
}
