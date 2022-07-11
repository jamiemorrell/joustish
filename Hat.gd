extends RigidBody2D

const GRAVITY : int = 100

var worn : bool = false
var bird : Node
var velocity : Vector2
var type : int = 0
var picked_up : bool = false

	
# Called when the node enters the scene tree for the first time.
func _ready():
	if not get_parent().is_in_group("bird"):
		worn=false
		bird=null
		print("dropped!")
		set_contact_monitor(true)
		set_max_contacts_reported(5)

		# Apply Godot physics at first
		set_use_custom_integrator(false) 

		$PickupArea.collision_mask=1
		#$PickupArea/Collider.disabled=true
		collision_mask=1
		yield(get_tree(), "idle_frame")
		start_spin()
	else:
		collision_mask=0
		bird=get_parent()
		set_use_custom_integrator(true) 
		$PickupArea.collision_mask=0
		#$PickupArea/Collider.disabled=true
		yield(get_tree(), "idle_frame")
		worn=true

		print("worn!")

func _integrate_forces( body_state ):
	if bird:
		var hp=bird.get_node("HatPosition")
		if hp:
			position=hp.position
			scale=hp.scale
			modulate=hp.modulate
			z_index=hp.z_index

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta)	:
#	if not worn:
#		velocity.y+=GRAVITY
#		velocity.x*=0.95
		#velocity=move_and_slide(velocity)

func start_spin():
	var spin=1000*float(randf()/2-0.25)
	yield (get_tree(),"idle_frame")
	apply_torque_impulse(spin)
	
func _on_PickupArea_body_entered(body):
	print("hat next to ", body)
	if not worn and not picked_up and body.is_in_group("bird") and body.get_node("Hat")==null:
		picked_up=true
		collision_mask=0
		yield(get_tree(), "idle_frame")
		body.put_on_hat(self)
		return
	elif not worn and body.is_in_group("floor"):
		print("hat hit floor")
		$PickupArea.collision_mask=14
		#$PickupArea/Collider.disabled=false
		yield(get_tree(), "idle_frame")

