import Testing

/// Parent suite for all tests in this target.
///
/// `ConfigManager` is a main-thread-only singleton and several tests mutate its
/// shared state (isolated to a temp directory via
/// `ConfigManager.configDirectoryOverride`). The `.serialized` trait, applied
/// here and inherited by nested suites via `extension AllTests`, forces the
/// whole suite tree to run strictly sequentially, and `@MainActor` confinement
/// (inherited by all nested suites) ensures the singleton is only touched from
/// the main thread — matching the app's own `assertMainThread()` invariant.
@MainActor
@Suite(.serialized)
enum AllTests {}