import 'package:todo_list_flutter/domain/entities/label_entity.dart';

abstract class LabelRepository {
  Future<List<LabelEntity>> getLabels();

  Future<LabelEntity?> getLabelByName(String name);

  Future<LabelEntity?> getLabelById(int id);

  Future<LabelEntity> upsertLabelByName(String name, {int? color});

  Future<LabelEntity> addLabel(LabelEntity label);

  Future<LabelEntity> updateLabel(LabelEntity label);

  Future<void> deleteLabel(int id);
}
