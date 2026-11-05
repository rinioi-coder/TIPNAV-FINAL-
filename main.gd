extends Node

@onready var view_container: ScrollContainer = find_child("ViewContainer", true, false)
@onready var home_content: Control = find_child("HomeContent", true, false)
@onready var category_content: Control = find_child("CategoryContent", true, false)

@onready var btn_home: Button = find_child("BtnHome", true, false)
@onready var btn_category: Button = find_child("BtnCategory", true, false)

func _ready() -> void:
	# When Home is clicked, show Home and hide Category
	btn_home.pressed.connect(func():
		home_content.visible = true
		category_content.visible = false
		view_container.scroll_vertical = 0
	)
	
	# When Category is clicked, hide Home and show Category
	btn_category.pressed.connect(func():
		home_content.visible = false
		category_content.visible = true
		view_container.scroll_vertical = 0
	)
	
	# Always start on the Home screen when the app launches
	home_content.visible = true
	category_content.visible = false
	
