# Local Storage Lab – In-Class Activity 09

## Project Overview

This Flutter application uses SQLite to store information locally on an Android device. The project builds on the previous local storage activity by adding folders and cards while keeping the original guest roster functionality.

## Features

- Create and view folders with card counts.
- Add multiple cards to a folder, including cards with the same title.
- Edit and delete cards.
- Delete folders with a confirmation dialog.
- Store card titles, suits, notes, and optional image references.
- Keep saved information after the application is closed and reopened.
- Validate folder names to prevent duplicates.

## Database Design

The application uses a SQLite database named `MyDatabase.db`, version 2.

The database includes three tables:

- `my_table` – Stores guest names and ages from the original activity.
- `folders` – Stores folder IDs, names, and creation dates.
- `cards` – Stores card IDs, titles, suits, notes, optional image references, and folder IDs.

The `cards.folder_id` field references the `folders` table. An index on `cards.folder_id` supports retrieving cards by folder.

The database upgrade adds the folder and card tables without intentionally deleting the original guest table.

## Testing and Results

| Test | Result |
|---|---|
| T1 – Database upgrade and preservation | Original guest data remained visible; full before-and-after schema evidence not recorded |
| T2 – Folder and card creation | Passed: Atlas contained 2 cards, Harbor contained 1 card |
| T3 – Edit and cancel behavior | Not fully verified for the required Compass cards |
| T4 – Persistence | Passed for the Playing Cards folder after force-stop and relaunch |
| T5 – Delete confirmation and cascade | Not fully verified |
| T6 – Validation and fallback | Duplicate Atlas folder was rejected; remaining cases not fully verified |

## Flutter Analysis

Command used:

`flutter analyze`

Result:

`No issues found!`

Analysis output is saved in `evidence/analysis_output.txt`.

## Design Decisions

SQLite was used because the project requires structured local storage and relationships between folders and cards. Each card has an integer ID, allowing cards with matching titles to be managed separately.

The folder deletion workflow asks for confirmation before removing data. The application also uses a foreign-key relationship with `ON DELETE CASCADE` for cards belonging to a deleted folder.

Card image references are optional. Saving a reference instead of image bytes keeps the database smaller, although a reference may become invalid if its underlying image is removed.

## Tools Used

- Flutter and Dart
- SQLite through the `sqflite` package
- Android Studio
- Android Emulator
- Git and GitHub
- ChatGPT for development assistance and troubleshooting