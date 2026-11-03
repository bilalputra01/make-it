import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/task.dart';
import 'create_label_sheet.dart';
import 'create_date_sheet.dart';

class CreateTaskSheet extends StatefulWidget {
  static const defaultLabels = [
    TaskLabel(name: 'Biologi', colorValue: 0xFFA67DD1),
    TaskLabel(name: 'Tugas kampus', colorValue: 0xFFE69E61),
    TaskLabel(name: 'Pribadi', colorValue: 0xFFD1758F),
  ];

  final List<TaskLabel> labels;
  final ValueChanged<TaskLabel> onLabelCreated;

  const CreateTaskSheet({
    super.key,
    required this.labels,
    required this.onLabelCreated,
  });

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  static const _labelAssets = {
    'Biologi': 'assets/figma/label-biologi.svg',
    'Tugas kampus': 'assets/figma/label-kampus.svg',
    'Pribadi': 'assets/figma/label-pribadi.svg',
  };
  static const _labelColors = [
    Color(0xFFA67DD1),
    Color(0xFF73A882),
    Color(0xFFE69E61),
    Color(0xFF6B94C9),
    Color(0xFFD1758F),
    Color(0xFF47A8A3),
  ];
  static const _weekdays = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
  static const _weekdayNumbers = [7, 1, 2, 3, 4, 5, 6];
  static const _fieldColor = Color(0xFFF4F4F5);
  static const _hintColor = Color(0xFFA1A1AA);

  final TextEditingController _titleController = TextEditingController();
  final Set<int> _repeatDays = {};
  late final List<TaskLabel> _labels;

  late TaskLabel _selectedLabel;
  TaskPriority _priority = TaskPriority.high;
  int _durationMinutes = 25;
  DateTime? _dueDate;
  bool _showTitleError = false;

  @override
  void initState() {
    super.initState();
    _labels = [...widget.labels];
    _selectedLabel = _labels.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateUtils.dateOnly(now);
    final lastDate = DateTime(now.year + 10);
    final initialDate = _dueDate ?? firstDate;
    FocusScope.of(context).unfocus();
    final date = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        final availableHeight =
            size.height - MediaQuery.viewInsetsOf(context).bottom;
        final rowCount = _calendarRowsFor(initialDate);
        final desiredHeight = rowCount > 5 ? 551.0 : 509.0;
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: availableHeight < desiredHeight
                ? availableHeight
                : desiredHeight,
            width: size.width < 420 ? size.width : 420,
            child: CreateDateSheet(
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
            ),
          ),
        );
      },
    );
    if (date != null && mounted) setState(() => _dueDate = date);
  }

  int _calendarRowsFor(DateTime date) {
    final firstWeekday = DateTime(date.year, date.month).weekday;
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    return ((firstWeekday - 1 + daysInMonth) / 7).ceil();
  }

  Future<void> _createLabel() async {
    final label = await showModalBottomSheet<TaskLabel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        final availableHeight =
            size.height - MediaQuery.viewInsetsOf(context).bottom;
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: availableHeight < 401 ? availableHeight : 401,
            width: size.width < 420 ? size.width : 420,
            child: CreateLabelSheet(
              existingLabels: _labels,
              colors: _labelColors,
            ),
          ),
        );
      },
    );
    if (label == null || !mounted) return;
    setState(() {
      _labels.add(label);
      _selectedLabel = label;
    });
    widget.onLabelCreated(label);
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _showTitleError = true);
      return;
    }

    final now = DateTime.now();
    final dueDate = _dueDate == null
        ? null
        : DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day);
    final isDueToday =
        dueDate == null ||
        (dueDate.year == now.year &&
            dueDate.month == now.month &&
            dueDate.day == now.day);

    Navigator.pop(
      context,
      Task(
        id: now.microsecondsSinceEpoch.toString(),
        title: title,
        label: _selectedLabel,
        durationMinutes: _durationMinutes,
        priority: _priority,
        schedule: isDueToday ? TaskSchedule.today : TaskSchedule.upcoming,
        dueDate: dueDate,
        repeatDays: _repeatDays.toList()..sort(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4D4D8)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Buat tugas',
              style: TextStyle(
                color: Color(0xFF09090B),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            _buildFormField(
              height: 76,
              label: 'NAMA TASK',
              child: TextField(
                key: const ValueKey('new-task-title'),
                controller: _titleController,
                autofocus: false,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 12, color: Color(0xFF09090B)),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Apa yang ingin di kerjakan?',
                  hintStyle: const TextStyle(color: _hintColor, fontSize: 12),
                  errorText: _showTitleError ? 'Nama task wajib diisi' : null,
                  errorStyle: const TextStyle(fontSize: 10, height: 1),
                ),
                onChanged: (_) {
                  if (_showTitleError) {
                    setState(() => _showTitleError = false);
                  }
                },
                onSubmitted: (_) => _saveTask(),
              ),
            ),
            const SizedBox(height: 14),
            _buildOptionField(
              title: 'WAKTU FOKUS',
              values: const [
                ('25 Menit', 25),
                ('45 Menit', 45),
                ('60 Menit', 60),
              ],
              selectedValue: _durationMinutes,
              onSelected: (value) => setState(() => _durationMinutes = value),
            ),
            const SizedBox(height: 14),
            _buildOptionField(
              title: 'PRIORITAS',
              values: const [
                ('Tinggi', TaskPriority.high),
                ('Sedang', TaskPriority.medium),
                ('Rendah', TaskPriority.low),
              ],
              selectedValue: _priority,
              onSelected: (value) => setState(() => _priority = value),
            ),
            const SizedBox(height: 14),
            _buildLabelOptions(),
            const SizedBox(height: 14),
            _buildCreateLabelButton(),
            const SizedBox(height: 14),
            _buildDateButton(),
            const SizedBox(height: 14),
            _buildRepeatSelector(),
            const SizedBox(height: 14),
            const SizedBox(
              height: 40,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Text(
                  'Harian 2 Jam, mingguan 20 jam. Bisa diubah kapan saja.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Color(0xFF52525B)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: FilledButton(
                key: const ValueKey('save-task'),
                onPressed: _saveTask,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Simpan target',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required double height,
    required String label,
    required Widget child,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 14),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionField<T>({
    required String title,
    required List<(String, T)> values,
    required T selectedValue,
    required ValueChanged<T> onSelected,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 87),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(title),
          const SizedBox(height: 22),
          Wrap(
            spacing: 18,
            runSpacing: 2,
            children: [
              for (final option in values)
                _UnderlinedOption(
                  label: option.$1,
                  selected: option.$2 == selectedValue,
                  onTap: () => onSelected(option.$2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabelOptions() {
    return Container(
      constraints: const BoxConstraints(minHeight: 172),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final label in _labels)
            InkWell(
              key: ValueKey('label-${label.name}'),
              onTap: () => setState(() => _selectedLabel = label),
              child: SizedBox(
                height: 54,
                child: Row(
                  children: [
                    if (_labelAssets[label.name] case final assetPath?)
                      SvgPicture.asset(assetPath, width: 10, height: 10)
                    else
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(label.colorValue),
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label.name,
                        style: const TextStyle(
                          color: Color(0xFF252426),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (_selectedLabel.name == label.name)
                      SvgPicture.asset(
                        'assets/figma/radio-selected.svg',
                        width: 20,
                        height: 20,
                      )
                    else
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1ECEC),
                          border: Border.all(color: const Color(0xFFA39C9E)),
                          borderRadius: BorderRadius.circular(10),
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

  Widget _buildCreateLabelButton() {
    return SizedBox(
      height: 62,
      child: FilledButton(
        onPressed: _createLabel,
        style: FilledButton.styleFrom(
          backgroundColor: _fieldColor,
          foregroundColor: const Color(0xFF252426),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const StadiumBorder(),
        ),
        child: const Row(
          children: [
            Icon(Icons.add, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Buat label baru',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton() {
    final date = _dueDate;
    final dateText = date == null
        ? 'Opsional'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return SizedBox(
      height: 60,
      child: FilledButton(
        key: const ValueKey('task-date'),
        onPressed: _selectDate,
        style: FilledButton.styleFrom(
          backgroundColor: _fieldColor,
          foregroundColor: const Color(0xFF252426),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: const StadiumBorder(),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Pilih Tanggal',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12),
              ),
            ),
            Flexible(
              child: Text(
                dateText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 12, color: _hintColor),
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              '›',
              style: TextStyle(fontSize: 22, color: Color(0xFFA39C9E)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 30,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ulangi',
              style: TextStyle(
                color: Color(0xFF252426),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final diameter = ((constraints.maxWidth - 24) / 7)
                .clamp(28, 40)
                .toDouble();
            return SizedBox(
              height: 46,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_weekdays.length, (index) {
                  final day = _weekdayNumbers[index];
                  final selected = _repeatDays.contains(day);
                  return InkWell(
                    key: ValueKey('repeat-${_weekdays[index]}'),
                    onTap: () => setState(() {
                      if (selected) {
                        _repeatDays.remove(day);
                      } else {
                        _repeatDays.add(day);
                      }
                    }),
                    borderRadius: BorderRadius.circular(diameter / 2),
                    child: Container(
                      width: diameter,
                      height: diameter,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFBC450)
                            : const Color(0xFFF1ECEC),
                        borderRadius: BorderRadius.circular(diameter / 2),
                      ),
                      child: Text(
                        _weekdays[index],
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF09090B)
                              : const Color(0xFF817B7D),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          _repeatDays.isEmpty
              ? 'Pilih hari agar task berulang tiap minggu'
              : 'Tugas diulang setiap ${_repeatDays.length} hari pilihan',
          style: const TextStyle(fontSize: 12, color: Color(0xFF817B7D)),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF52525B),
        fontSize: 10,
        letterSpacing: 0.6,
        height: 1.4,
      ),
    );
  }
}

class _UnderlinedOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnderlinedOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? const Color(0xFF09090B)
                    : const Color(0xFFA1A1AA),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: _textWidth(label),
              height: 2,
              color: selected
                  ? const Color(0xFFFBC450)
                  : const Color(0xFFF4F4F5),
            ),
          ],
        ),
      ),
    );
  }

  double _textWidth(String text) {
    switch (text) {
      case '25 Menit':
        return 48;
      case '45 Menit':
      case '60 Menit':
        return 50;
      case 'Tinggi':
        return 34;
      case 'Sedang':
      case 'Rendah':
        return 42;
      default:
        return 48;
    }
  }
}
