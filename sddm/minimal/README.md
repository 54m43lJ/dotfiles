# minimal — cross-version SDDM fallback

This is the last-resort greeter theme. It is deliberately boring: the
QML body uses only core QtQuick types that have existed since Qt 5, so it
survives regressions in Qt Quick Controls, Qt Graphical Effects, Qt Svg,
the virtual keyboard and other add-on modules.

## Compatibility contract

- **`metadata.desktop` must not set `QtVersion`.** When the key is absent,
  SDDM falls back to its default greeter (Qt5 in SDDM 0.21). That is the
  whole point: minimal keeps working when the Qt6 greeter (and sugar-dark)
  breaks.
- **`Main.qml` may import only `QtQuick 2.15`.** Qt5 rejects unversioned
  imports; Qt6 still registers the 2.15 API surface, and the versioned
  import deliberately hides Qt6-only types and properties, so none may be
  used. Every QML file in this theme must obey that rule; do not add any
  other import.
- **Keep the body on Qt 5.15-era core QtQuick types.** No Qt Quick
  Controls, Effects, GraphicalEffects, Svg, VirtualKeyboard, or
  SddmComponents.
- The only version-sensitive construct should remain the single
  `import QtQuick 2.15` line. If a future Qt major drops that import,
  change that line alone and re-run the check below.

## Verifying

From the dotfiles repository root:

```bash
./sddm/check-minimal-compat.sh
```

The script enforces the static rules above and then loads the theme with
every installed `sddm-greeter*` binary (Qt5, Qt6, and a future
`sddm-greeter-qt7` if present). `sddm/module.sh` runs it during deploy.

Qt7 cannot be tested before it exists. The QML body is version-agnostic;
the check script will automatically pick up `sddm-greeter-qt7` and report
immediately if the import needs adapting.
