extends Node
class_name CustomScript


static func run_script(script:GDScript, parent:Node) -> void:
	var node:Node = Node.new()
	node.set_script(script)
	parent.add_child(node)
