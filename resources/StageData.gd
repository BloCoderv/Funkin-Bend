extends Resource
class_name StageData


func convert_to_bend(stage_name:String) -> Node2D:
	var stage:Node2D = Node2D.new()
	
	
	ResourceSaver.save(stage, "")
	return stage
