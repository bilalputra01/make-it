import 'package:flutter/material.dart';

class CreateDateSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const CreateDateSheet({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<CreateDateSheet> createState() => _CreateDateSheetState();
}

class _CreateDateSheetState extends State<CreateDateSheet> {
  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  static const _weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const _weekdayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  late DateTime _selectedDate;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDate);
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _changeMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
  }

  bool _isSameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  bool _isMonthBefore(DateTime first, DateTime second) =>
      first.year < second.year ||
      (first.year == second.year && first.month < second.month);

  int get _calendarRowCount {
    final firstWeekday = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
    ).weekday;
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    return ((firstWeekday - 1 + daysInMonth) / 7).ceil();
  }

  List<Widget> _buildCalendarRows() {
    final firstWeekday = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
    ).weekday;
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final cells = <Widget>[];

    for (var index = 0; index < _calendarRowCount * 7; index++) {
      final day = index - firstWeekday + 2;
      if (day < 1 || day > daysInMonth) {
        cells.add(const SizedBox(height: 42));
        continue;
      }

      final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      final isEnabled =
          !DateUtils.dateOnly(date).isBefore(widget.firstDate) &&
          !DateUtils.dateOnly(date).isAfter(widget.lastDate);
      final isSelected = _isSameDate(date, _selectedDate);

      cells.add(
        SizedBox(
          height: 42,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = constraints.maxWidth < 32
                  ? constraints.maxWidth
                  : 32.0;
              return Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: Semantics(
                    button: true,
                    enabled: isEnabled,
                    selected: isSelected,
                    label:
                        '${_weekdayNames[date.weekday - 1]}, $day ${_months[date.month - 1]} ${date.year}',
                    child: InkWell(
                      key: ValueKey(
                        'calendar-day-${date.year}-${date.month}-$day',
                      ),
                      onTap: isEnabled
                          ? () => setState(() => _selectedDate = date)
                          : null,
                      customBorder: const CircleBorder(),
                      child: isSelected
                          ? Container(
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFF141417),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$day',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  color: isEnabled
                                      ? const Color(0xFF141417)
                                      : const Color(0xFFA1A1AA),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return [
      for (var row = 0; row < _calendarRowCount; row++)
        Row(
          children: [
            for (var column = 0; column < 7; column++)
              Expanded(child: cells[row * 7 + column]),
          ],
        ),
    ];
  }

  String get _selectedDateLabel =>
      '${_weekdayNames[_selectedDate.weekday - 1]}, ${_selectedDate.day} ${_months[_selectedDate.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final canGoToPreviousMonth = !_isMonthBefore(
      DateTime(_visibleMonth.year, _visibleMonth.month - 1),
      DateTime(widget.firstDate.year, widget.firstDate.month),
    );
    final canGoToNextMonth = !_isMonthBefore(
      DateTime(widget.lastDate.year, widget.lastDate.month),
      DateTime(_visibleMonth.year, _visibleMonth.month + 1),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E5EB)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(19, 19, 19, 23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pilih tanggal',
              style: TextStyle(
                color: Color(0xFF141417),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 24,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Semantics(
                      button: true,
                      enabled: canGoToPreviousMonth,
                      label: 'Bulan sebelumnya',
                      child: InkWell(
                        key: const ValueKey('calendar-previous-month'),
                        onTap: canGoToPreviousMonth
                            ? () => _changeMonth(-1)
                            : null,
                        child: const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '‹',
                            style: TextStyle(
                              color: Color(0xFF141417),
                              fontSize: 18,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${_months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF141417),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: Semantics(
                      button: true,
                      enabled: canGoToNextMonth,
                      label: 'Bulan berikutnya',
                      child: InkWell(
                        key: const ValueKey('calendar-next-month'),
                        onTap: canGoToNextMonth ? () => _changeMonth(1) : null,
                        child: const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '›',
                            style: TextStyle(
                              color: Color(0xFF141417),
                              fontSize: 18,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (final weekday in _weekdays)
                  Expanded(
                    child: Text(
                      weekday,
                      style: const TextStyle(
                        color: Color(0xFF85858C),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ..._buildCalendarRows(),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE5E5EB)),
            const SizedBox(height: 14),
            Text(
              _selectedDateLabel,
              style: const TextStyle(
                color: Color(0xFF141417),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 48,
              child: FilledButton(
                key: const ValueKey('use-selected-date'),
                onPressed: () => Navigator.pop(context, _selectedDate),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF141417),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Gunakan tanggal',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
