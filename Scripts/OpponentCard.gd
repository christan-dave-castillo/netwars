extends Node2D

var card_type
var card_name = ""
var first_position
var attack
var health
var energy_cost = 0
var card_slot_card_is_in = null
var defeated = false
var ability_script
var can_afford = true
var is_drawing = false

func _ready() -> void:
	position = Vector2(1600, 125)
