# Module layout and migration notes

This file describes the feature-first modularization applied to the project.
The refactor is incremental: original files are left in place and new barrel
files were added under lib/features/* and lib/shared/* to provide a stable
public API per feature. This reduces churn and makes the next steps (physical
moves, package imports) straightforward.

What was added
- lib/features/*/features_*.dart: feature-level barrel exports
- lib/shared/ui/widgets.dart: shared UI barrel
- lib/core/core.dart: core barrel

Why this approach
- Minimal changes to existing code paths while providing a clear module
  surface that other code can import from (e.g. import 'package:video_downloader/features/downloads/features_downloads.dart').
- Allows gradual migration: files can be physically moved into feature
  directories in follow-up commits without changing external imports.

Next steps (suggested)
1. Replace internal imports with package imports pointing at feature barrels.
2. Physically move files into feature directories and update paths.
3. Add documentation per feature (README.md) and adjust tests/CI if needed.

If you want, I can continue and perform the physical moves and import updates
now (one feature at a time, with full analyzer/test runs per commit).
