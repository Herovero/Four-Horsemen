extends AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func play_animation_trump():
	play("Animation1")

func play_animation_trump2():
	play("Animation2")
	
func play_animation_xi():
	play("XiAnimation1")

func play_animation_xi2():
	play("XiAnimation2")

func play_animation_kim():
	play("KimAnimation1")

func play_animation_putin():
	play("PutinAnimation1")

func play_animation_herophase():
	play("Hero Phase")

func play_animation_enemyphase():
	play("Enemy Phase")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
