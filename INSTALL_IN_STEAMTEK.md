# Install Steamtek Studio in the Godot project

1. Close Steamtek Studio.
2. Open `C:\My Game\Steamtek` in File Explorer.
3. Copy the `tools` and `.steamtek-studio` folders from this package into it.
4. Launch:

   `C:\My Game\Steamtek\tools\steamtek-studio\Launch_Steamtek_Studio.bat`

The application detects `project.godot` automatically and stores its database at:

`C:\My Game\Steamtek\.steamtek-studio\studio.db`

If you already have a Studio database, close Studio and copy it to that location,
renaming it to `studio.db`.

## Resulting project structure

```text
Steamtek/
├── .godot/                   # Godot-managed; leave alone
├── .steamtek-studio/
│   ├── studio.db             # created on first launch
│   ├── backups/
│   └── thumbnails/
├── assets/
├── docs/
├── scenes/
├── tools/
│   └── steamtek-studio/
│       ├── steamtek_studio.py
│       ├── Launch_Steamtek_Studio.bat
│       └── README.md
└── project.godot
```

## Moving to another PC

Copy or clone the entire `Steamtek` folder. Launch Studio from its `tools` folder.
Do not run the same SQLite database simultaneously from two computers.
