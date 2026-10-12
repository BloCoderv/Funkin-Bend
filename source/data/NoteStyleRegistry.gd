extends RefCounted
class_name NoteStyleRegistry

const DEFAULT_STYLE_ID: String = "funkin"
static var _entries: Dictionary[String, NoteStyle] = {}

## Retorna o estilo solicitado ou o estilo padrão quando o arquivo não existe.
static func fetch_entry(style_id: String) -> NoteStyle:
	var normalized_id: String = style_id.to_lower().strip_edges()
	if normalized_id.is_empty():
		normalized_id = DEFAULT_STYLE_ID
	if _entries.has(normalized_id):
		return _entries[normalized_id] as NoteStyle
	var style: NoteStyle = NoteStyle.load_style(normalized_id)
	if !style.has_data() and normalized_id != DEFAULT_STYLE_ID:
		style = fetch_entry(DEFAULT_STYLE_ID)
	_entries[normalized_id] = style
	return style

## Limpa o cache para recarregar estilos depois de alterar os dados.
static func clear() -> void:
	_entries.clear()
