import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Pengganti [showModalBottomSheet] bergaya Cupertino: konten muncul dari
/// bawah dengan latar surface dan sudut atas membulat.
Future<T?> showCupertinoBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: double.infinity,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: builder(context),
      ),
    ),
  );
}
