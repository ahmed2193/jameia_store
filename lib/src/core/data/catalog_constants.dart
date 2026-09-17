/// Single supplier id for the whole Jameia store — every cart add (from any
/// category, rank, or home rail) uses this so the cart is ONE unified basket
/// (Jameia is a single store), never cleared when moving between categories.
///
/// Lives in this neutral catalogue-constants file (not on `JameiaRepository`) so
/// presentation can reference the id without importing the core repository —
/// keeping the `presentation_no_core_repo` boundary clean.
const String kJameiaSupplierId = 'jameia';
