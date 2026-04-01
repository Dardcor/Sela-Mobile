## 2026-04-01 - Group screen search fix

- Added `_allTeams` in `lib/features/groups/screens/group_screen.dart` to keep unfiltered groups from `_fetch()`.
- Updated `_fetch()` to store Supabase results into `_allTeams` and call `_applySearch()`.
- Implemented `_applySearch()` to filter locally and case-insensitively by `name`, `course_name`, and `class_name`.
- Wired search interactions to `_applySearch()` via `TextField.onChanged`, `TextField.onSubmitted`, and search icon `onTap`.
- Kept filtering on the client side (no backend query changes) and preserved existing UI layout.
