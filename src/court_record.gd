extends Control

var itemrow:Array
#data. Ordered by case, episode then part.
#The part resource is a RecordData
export(Array, Array, Array, Resource) var data

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	itemrow = [
		$itemrow/items/item0,
		$itemrow/items/item1,
		$itemrow/items/item2,
		$itemrow/items/item3,
		$itemrow/items/item4,
		$itemrow/items/item5,
		$itemrow/items/item6,
		$itemrow/items/item7,
		$itemrow/items/item8,
		$itemrow/items/item9,
	]
	for i in itemrow:
		(i as TextureButton).connect("pressed", self, "on_item_selected", [i])
	
	var pop_version:PopupMenu = $btn_versions.get_popup()
	var case_i := 0
	var ep_i := 0
	var part_i := 0
	for case in data:
		var case_menu = PopupMenu.new()
		case_menu.name = "Case " + str(case_i+1)#cases are counted from 1
		pop_version.add_child(case_menu)
		pop_version.add_submenu_item(case_menu.name, case_menu.name)
		ep_i = 0
		for ep in case:
			var ep_menu = PopupMenu.new()
			ep_menu.name = "Episode " + str(ep_i+1) #episodes are counted from 1
			case_menu.add_child(ep_menu)
			case_menu.add_submenu_item(ep_menu.name, ep_menu.name)
			part_i = 0
			for part in ep:
				ep_menu.add_item("part " + str(part_i)) #breaking the trend, parts are counted from 0
				part_i += 1
			ep_menu.connect("index_pressed", self, "on_part_selected", [case_i, ep_i])
			ep_i += 1 
		case_i += 1 
	#end of version select setup
		
func on_part_selected(part_i, case_i, ep_i):
	print("part_i " + str(part_i) + " - case_i " + str(case_i) + " - ep_i " + str(ep_i) )

func on_item_selected(index:int):
	print("item selected: " + str(index))
	pass

	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
