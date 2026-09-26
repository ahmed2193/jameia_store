Captured from the live host (https://api.jm3eia.store) on 2026-09-24 with a throwaway guest key.

- `sse_*.json`: every SSE frame of one `POST /v1/assistant/messages` turn, as
  `[{ ms, event, data, comment }]` (`data` is the raw JSON string; `ms` = elapsed since the request).
  Recorded by `.claude/skills/jameia-api-verify/scripts/assistant_sse_probe.js`.
- `sse_cart_action_persist_error_*`: the backend bug L7. A `cart_action` block is streamed, then a
  terminal `error {INTERNAL_ERROR, "Document failed validation"}` arrives and nothing is saved.
- `conversation_detail_en.json` / `conversations_list_en.json`: full JSON envelopes.
- `confirm_404_action_not_found.json`: confirming the orphaned action from the L7 turn.

Contract notes L1–L20: `docs/prompts/assistant_chat_prompt.md`.
