import 'package:isar/isar.dart';

import 'package:todo_list_flutter/data/models/label.dart';
import 'package:todo_list_flutter/domain/entities/label_entity.dart';
import 'package:todo_list_flutter/domain/repositories/label_repository.dart';

class LabelRepositoryImpl implements LabelRepository {
  LabelRepositoryImpl({required this.isar});

  final Isar isar;

  @override
  Future<List<LabelEntity>> getLabels() async {
    try {
      final labels = await isar.labels.where().findAll()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return labels.map((label) => label.toEntity()).toList();
    } catch (error, stackTrace) {
      throw Exception('Failed to load labels: $error');
    }
  }

  @override
  Future<LabelEntity?> getLabelByName(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return null;

    try {
      final labels = await isar.labels.where().findAll();
      final match = labels.where((label) {
        return label.name.toLowerCase() == normalizedName.toLowerCase();
      }).toList();
      if (match.isEmpty) return null;
      return match.first.toEntity();
    } catch (error, stackTrace) {
      throw Exception('Failed to get label by name: $error');
    }
  }

  @override
  Future<LabelEntity?> getLabelById(int id) async {
    try {
      final label = await isar.labels.get(id);
      return label?.toEntity();
    } catch (error, stackTrace) {
      throw Exception('Failed to get label by id: $error');
    }
  }

  @override
  Future<LabelEntity> upsertLabelByName(String name, {int? color}) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Label name cannot be empty.');
    }

    try {
      final existing = await getLabelByName(normalizedName);
      if (existing != null) {
        if (color == null || color == existing.color) {
          return existing;
        }

        final updated = existing.copyWith(color: color);
        return updateLabel(updated);
      }

      return addLabel(
        LabelEntity(name: normalizedName, color: color ?? 0xFF1E88E5, createdAt: DateTime.now()),
      );
    } catch (error, stackTrace) {
      throw Exception('Failed to upsert label: $error');
    }
  }

  @override
  Future<LabelEntity> addLabel(LabelEntity label) async {
    final normalizedName = label.name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Label name cannot be empty.');
    }

    try {
      final isarLabel = Label.fromEntity(label.copyWith(name: normalizedName));
      final id = await isar.writeTxn(() async {
        return isar.labels.put(isarLabel);
      });
      return isarLabel.copyWith(id: id).toEntity();
    } catch (error, stackTrace) {
      throw Exception('Failed to add label: $error');
    }
  }

  @override
  Future<LabelEntity> updateLabel(LabelEntity label) async {
    if (label.id == null) {
      throw ArgumentError('Cannot update a label without id.');
    }

    final normalizedName = label.name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Label name cannot be empty.');
    }

    try {
      final updatedLabel = label.copyWith(name: normalizedName);
      final isarLabel = Label.fromEntity(updatedLabel);
      await isar.writeTxn(() async {
        await isar.labels.put(isarLabel);
      });
      return isarLabel.toEntity();
    } catch (error, stackTrace) {
      throw Exception('Failed to update label: $error');
    }
  }

  @override
  Future<void> deleteLabel(int id) async {
    try {
      await isar.writeTxn(() async {
        await isar.labels.delete(id);
      });
    } catch (error, stackTrace) {
      throw Exception('Failed to delete label: $error');
    }
  }
}
