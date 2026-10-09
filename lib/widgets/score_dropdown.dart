import 'package:flutter/material.dart';



import '../theme/app_colors.dart';

import '../utils/student_score_display.dart';



/// 1–10 arası not, devamsızlık (`a`) ve boş (`—`) seçimi.

class ScoreDropdown extends StatelessWidget {

  const ScoreDropdown({

    super.key,

    required this.value,

    required this.absent,

    required this.readOnly,

    required this.onChanged,

  });



  static const List<int> scores = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1];



  static const int _clearSentinel = -1;

  static const int _absentSentinel = -2;



  final int? value;

  final bool absent;

  final bool readOnly;

  final void Function({int? score, bool absent}) onChanged;



  Future<void> _openMenu(BuildContext context) async {

    final box = context.findRenderObject() as RenderBox?;

    if (box == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);

    final selected = await showMenu<int>(

      context: context,

      position: RelativeRect.fromLTRB(

        offset.dx,

        offset.dy + box.size.height,

        offset.dx + box.size.width,

        offset.dy,

      ),

      constraints: const BoxConstraints(minWidth: 56, maxWidth: 72),

      items: [

        ...scores.map(

          (score) => PopupMenuItem<int>(

            value: score,

            height: 36,

            child: Center(

              child: Text(

                '$score',

                style: const TextStyle(fontWeight: FontWeight.w600),

              ),

            ),

          ),

        ),

        const PopupMenuDivider(),

        PopupMenuItem<int>(

          value: _absentSentinel,

          height: 36,

          child: Center(

            child: Text(

              'a',

              style: TextStyle(

                fontWeight: FontWeight.w700,

                color: AppColors.accentOrange,

              ),

            ),

          ),

        ),

        PopupMenuItem<int>(

          value: _clearSentinel,

          height: 36,

          child: Center(

            child: Text(

              '—',

              style: TextStyle(color: AppColors.textSecondary),

            ),

          ),

        ),

      ],

    );

    if (selected == null) return;

    if (selected == _absentSentinel) {

      onChanged(score: null, absent: true);

      return;

    }

    if (selected == _clearSentinel) {

      onChanged(score: null, absent: false);

      return;

    }

    onChanged(score: selected, absent: false);

  }



  @override

  Widget build(BuildContext context) {

    final display = formatStudentScoreDisplay(

      numericScore: value,

      absent: absent,

    );

    if (readOnly) {

      return SizedBox(

        height: 32,

        child: Center(

          child: Text(

            display,

            textAlign: TextAlign.center,

            style: TextStyle(

              fontWeight: FontWeight.w500,

              color: absent ? AppColors.accentOrange : null,

            ),

          ),

        ),

      );

    }



    return SizedBox(

      height: 32,

      child: Material(

        color: Colors.transparent,

        child: InkWell(

          onTap: () => _openMenu(context),

          borderRadius: BorderRadius.circular(6),

          child: Container(

            alignment: Alignment.center,

            decoration: BoxDecoration(

              border: Border.all(color: AppColors.border),

              borderRadius: BorderRadius.circular(6),

            ),

            child: Text(

              display,

              textAlign: TextAlign.center,

              style: TextStyle(

                fontWeight: FontWeight.w600,

                color: absent

                    ? AppColors.accentOrange

                    : value == null

                        ? AppColors.textSecondary

                        : AppColors.textPrimary,

              ),

            ),

          ),

        ),

      ),

    );

  }

}


