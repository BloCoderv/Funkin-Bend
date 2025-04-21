extends Node


func play(stream: AudioStream, volume:float = 0.0, bus:String = "Master"):
	var stream_node:AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(stream_node)
	
	# SETUP
	stream_node.stream = stream
	stream_node.bus = bus
	stream_node.volume_db = linear_to_db(volume)
	stream_node.play()
	
	stream_node.finished.connect(func(): stream_node.queue_free())
