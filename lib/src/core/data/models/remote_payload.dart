/// A DTO together with the envelope `results` it was parsed from — what the
/// remote datasource of a CACHED route returns. The repository saves [raw]
/// exactly as the server sent it, and the cache datasource re-parses it later
/// with the same `fromJson`: perfect fidelity, and no `toJson` to maintain on
/// the (fromJson-only) catalogue DTOs.
class RemotePayload<M> {
  const RemotePayload(this.model, this.raw);

  final M model;

  /// The decoded `results` (a map or a list). Handed to the cache once, then
  /// dropped — never kept in state.
  final Object raw;
}
