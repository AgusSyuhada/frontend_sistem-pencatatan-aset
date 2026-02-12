import 'package:flutter/material.dart';

class DialogActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final String id;

  DialogActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.id,
  });
}

void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Loading..."),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void showErrorDialog(
  BuildContext context,
  String message, {
  VoidCallback? onOkPressed,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Gagal'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              if (onOkPressed != null) {
                onOkPressed();
              }
            },
          ),
        ],
      );
    },
  );
}

void showSuccessDialog(
  BuildContext context,
  String message,
  VoidCallback onOkPressed,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Berhasil'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onOkPressed();
            },
          ),
        ],
      );
    },
  );
}

void showFileDownloadSuccessDialog({
  required BuildContext context,
  required String filePath,
  required VoidCallback onOpenFile,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Download Berhasil'),
        content: Text("File berhasil disimpan di:\n$filePath"),
        actions: <Widget>[
          TextButton(
            child: const Text('Tutup'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          TextButton(
            child: const Text('Buka File'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onOpenFile();
            },
          ),
        ],
      );
    },
  );
}

void showConfirmationDialog(
  BuildContext context,
  String title,
  String content,
  VoidCallback onConfirm, {
  VoidCallback? onCancel,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          child: const Text('Batal'),
          onPressed: () {
            Navigator.of(context).pop();
            if (onCancel != null) {
              onCancel();
            }
          },
        ),
        TextButton(
          child: const Text('Ya'),
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
        ),
      ],
    ),
  );
}

void showPermissionDialog(
  BuildContext context,
  String title,
  String message, {
  VoidCallback? onSettingsPressed,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          child: const Text('Batal'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        if (onSettingsPressed != null)
          TextButton(
            child: const Text('Buka Pengaturan'),
            onPressed: () {
              Navigator.of(ctx).pop();
              onSettingsPressed();
            },
          )
        else
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
      ],
    ),
  );
}

void showSelectionActionDialog({
  required BuildContext context,
  required String title,
  required List<DialogActionItem> actions,
  required Function(String actionId) onSelected,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ...actions.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _actionDialogButton(
                    label: item.label,
                    icon: item.icon,
                    color: item.color,
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(item.id);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _actionDialogButton({
  required String label,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    child: Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Icon(icon, size: 32, color: Colors.white.withValues(alpha: 0.2)),
        ),
      ],
    ),
  );
}

void showGenericFilterDialog({
  required BuildContext context,
  required Widget content,
  required VoidCallback onReset,
  required VoidCallback onApply,
  String title = "Atur Filter",
}) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                Flexible(child: SingleChildScrollView(child: content)),

                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onReset();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Reset Filter"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onApply();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Terapkan",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
