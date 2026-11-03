import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/task.dart';

class CreateLabelSheet extends StatefulWidget {
  final List<TaskLabel> existingLabels;
  final List<Color> colors;

  const CreateLabelSheet({
    super.key,
    required this.existingLabels,
    required this.colors,
  });

  @override
  State<CreateLabelSheet> createState() => _CreateLabelSheetState();
}

class _CreateLabelSheetState extends State<CreateLabelSheet> {
  static const _swatchAssets = [
    'assets/figma/new-label-purple-selected.svg',
    'assets/figma/new-label-color-green.svg',
    'assets/figma/new-label-color-orange.svg',
    'assets/figma/new-label-color-blue.svg',
    'assets/figma/new-label-color-pink.svg',
    'assets/figma/new-label-color-teal.svg',
  ];

  final TextEditingController _nameController = TextEditingController();
  int _selectedColor = 0;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveLabel() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Nama label wajib diisi.');
      return;
    }

    final alreadyExists = widget.existingLabels.any(
      (label) => label.name.toLowerCase() == name.toLowerCase(),
    );
    if (alreadyExists) {
      setState(() => _errorText = 'Label dengan nama itu sudah ada.');
      return;
    }

    Navigator.pop(
      context,
      TaskLabel(
        name: name,
        colorValue: widget.colors[_selectedColor].toARGB32(),
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
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 1,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 149,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF09090B),
                  borderRadius: BorderRadius.circular(19),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 37, 14, 21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buat label baru',
                        style: TextStyle(
                          color: Color(0xFF09090B),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Beri nama dan warna untuk label tugasmu.',
                        style: TextStyle(
                          color: Color(0xFF52525B),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    'NAMA LABEL',
                    style: TextStyle(
                      color: Color(0xFF52525B),
                      fontSize: 10,
                      height: 1.6,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 58,
                    child: TextField(
                      key: const ValueKey('new-label-name'),
                      controller: _nameController,
                      autofocus: false,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) {
                        if (_errorText != null) {
                          setState(() => _errorText = null);
                        }
                      },
                      onSubmitted: (_) => _saveLabel(),
                      decoration: InputDecoration(
                        hintText: 'Nama Label',
                        hintStyle: const TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE4E4E7),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE4E4E7),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFFBC450),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontSize: 10,
                      ),
                    ),
                  ],
                  const SizedBox(height: 17),
                  const Text(
                    'WARNA',
                    style: TextStyle(
                      color: Color(0xFF52525B),
                      fontSize: 10,
                      height: 1.6,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final spacing = ((constraints.maxWidth - 178) / 5)
                          .clamp(0, 28)
                          .toDouble();
                      return Row(
                        children: List.generate(widget.colors.length, (index) {
                          final isSelected = index == _selectedColor;
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index == widget.colors.length - 1
                                  ? 0
                                  : spacing,
                            ),
                            child: Semantics(
                              button: true,
                              selected: isSelected,
                              label: 'Warna ${index + 1}',
                              child: InkWell(
                                key: ValueKey('label-color-$index'),
                                onTap: () =>
                                    setState(() => _selectedColor = index),
                                customBorder: const CircleBorder(),
                                child: SizedBox(
                                  width: isSelected ? 38 : 28,
                                  height: 38,
                                  child: Center(
                                    child: isSelected && index == 0
                                        ? SvgPicture.asset(
                                            _swatchAssets[index],
                                            width: 38,
                                            height: 38,
                                          )
                                        : isSelected
                                        ? Container(
                                            width: 38,
                                            height: 38,
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFFFBC450),
                                                width: 2,
                                              ),
                                            ),
                                            child: SvgPicture.asset(
                                              _swatchAssets[index],
                                              width: 28,
                                              height: 28,
                                            ),
                                          )
                                        : SvgPicture.asset(
                                            _swatchAssets[index],
                                            width: 28,
                                            height: 28,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    'Label bisa diganti kapan saja.',
                    style: TextStyle(
                      color: Color(0xFF52525B),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      key: const ValueKey('save-label'),
                      onPressed: _saveLabel,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF09090B),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Simpan label',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
}
