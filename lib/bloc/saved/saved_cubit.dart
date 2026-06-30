import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/property_repository.dart';

/// Holds the set of saved property IDs for the current user.
/// Optimistically toggles on save/unsave and reverts on API error.
class SavedCubit extends Cubit<Set<String>> {
  SavedCubit() : super(const {});

  Future<void> load() async {
    try {
      final props =
          await const PropertyRepository().getSavedProperties(size: 200);
      if (!isClosed) emit(props.map((p) => p.id).toSet());
    } catch (_) {}
  }

  Future<void> toggle(String id) async {
    final current = Set<String>.from(state);
    final wasSaved = current.contains(id);
    // Optimistic update — show change immediately
    if (wasSaved) {
      current.remove(id);
    } else {
      current.add(id);
    }
    emit(current);
    try {
      final repo = const PropertyRepository();
      if (wasSaved) {
        await repo.unsaveProperty(id);
      } else {
        await repo.saveProperty(id);
      }
    } catch (_) {
      // Revert on API failure
      if (isClosed) return;
      final reverted = Set<String>.from(state);
      if (wasSaved) {
        reverted.add(id);
      } else {
        reverted.remove(id);
      }
      emit(reverted);
    }
  }

  void clear() => emit(const {});
}
