/// i18n key of the status line for a running assistant tool (L17). A tool
/// this app does not know yet reads "Working on it".
abstract final class AssistantToolLabels {
  static const String _prefix = 'assistant.tool.';
  static const String generic = '${_prefix}generic';

  static const Set<String> _known = {
    'search_products',
    'get_product',
    'add_to_cart',
    'get_cart',
    'track_order',
    'list_orders',
    'list_offers',
    'search_recipes',
    'search_faq',
    'list_categories',
    'list_brands',
    'list_delivery_slots',
    'check_delivery',
    'list_branches',
    'handoff_to_human',
  };

  static String keyOf(String toolName) =>
      _known.contains(toolName) ? '$_prefix$toolName' : generic;
}
