# Placeholder character atlas sheets

The PNG files generated from `character_atlas/` are temporary, original lotus-themed stand-ins, not recovered game artwork and not the Bé Sen mascot. They occupy the frame rectangles described by the existing plist files so atlas-based previews can load while the original sheets are unavailable.

Regenerate them on Windows with:

```powershell
.\assets\character\tools\generate_placeholders.ps1
```

Existing files are left untouched by default. Pass `-Force` only to replace generated sheets.
