extends Control

var itemrow:Array
#data. Ordered by case, episode then part.
#The part resource is a RecordData
export(Array, Array, Array, Resource) var data
export(StreamTexture) var evidence_background
export(StreamTexture) var profile_background
export(StreamTexture) var empty_item
export(Array, Resource) var about_data
export(Array, Resource) var fallback_list

var recordData:RecordData
var itempage := 0
var profiles_mode := false
var about_mode := false
var detailspage := 0
var s_item := 0


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
	for i in len(itemrow):
		var item:TextureButton = itemrow[i]
# warning-ignore:return_value_discarded
		item.connect("pressed", self, "on_item_selected", [i])
	
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
	#Attempt to find arguments/parameters to load case episode and part indicies.
	part_i = 0
	case_i = 0
	ep_i = 0
	if OS.has_feature('JavaScript'):
		part_i = _loadparam("part") # part counts from 0
		#print("loaded part index " + str(part_i))
		case_i = _loadparam("case") -1 # case's display counts from 1
		#print("loaded part case " + str(case_i))
		ep_i = _loadparam("episode") -1 # episode's display counts from 1
		#print("loaded part episode " + str(ep_i))
		
	on_part_selected(part_i,case_i,ep_i)

func _loadparam(param):
	print("starting _loadparam(%s)"%param)
	#If in browser, load from url arguments.
	if OS.has_feature('JavaScript'):
		var js = "var url_string = window.location.href;var url = new URL(url_string);url.searchParams.get(\"%s\");"%param
		print (js)
		var data = JavaScript.eval(js, false)
		print("found " + str(data))
		return int(data) if data else 0
	return 0
func on_part_selected(part_i, case_i, ep_i):
	print("load page - part_i " + str(part_i) + " - case_i " + str(case_i) + " - ep_i " + str(ep_i) )
	#sanetize input before load (clamp to valid values)
	case_i = min(case_i, len(data)-1)
	case_i = max(0, case_i)
	ep_i = min(ep_i, len(data[case_i])-1)
	ep_i = max(0, ep_i)
	part_i = min(part_i, len(data[case_i][ep_i])-1)
	part_i = max(0, part_i)
	print("corrected to - part_i " + str(part_i) + " - case_i " + str(case_i) + " - ep_i " + str(ep_i) )
	
	#set display-text on version-button
	$btn_versions.text = "Case %s episode %s, part %s" % [case_i+1, ep_i+1, part_i]
	#if in browser, update url params
	if OS.has_feature('JavaScript'):
		var js = """
		var url = new URL(window.location.href);
		url.searchParams.set("part", %s);
		url.searchParams.set("case", %s);
		url.searchParams.set("episode", %s);
		window.history.pushState({ path: url.href }, '', url.href);
		"""%[part_i, case_i+1, ep_i+1] #case and episode count from 1. Part does not
		JavaScript.eval(js, false)
	
	#load record data
	recordData = data[case_i][ep_i][part_i]
	#refresh the court record.
	refresh()
func refresh():
	$img_background.texture = profile_background if profiles_mode or about_mode else evidence_background
	var itemlist:Array = get_itemList()
	#sanitize the itempage
	itempage = clamp(itempage, 0, int((len(itemlist)-1)/10))
	for i in range(10):
		var item_i = i + 10*itempage
		var item_btn:TextureButton = itemrow[i]
		if(item_i >= len(itemlist)):
			item_btn.disabled = true
			item_btn.texture_normal = empty_item
		else:
			item_btn.disabled = false
			item_btn.texture_normal = itemlist[item_i].icon
		$itemrow/PREV.disabled = true if itempage <= 0 else false
		$itemrow/NEXT.disabled = len(itemlist) <= ((itempage+1) * 10)
	on_item_selected(0)
	
func get_itemList():
	var itemlist:Array = about_data if about_mode else recordData.profiles if profiles_mode else recordData.evidence
	#fallback option
	itemlist = fallback_list if len(itemlist) <= 0 else itemlist
	return itemlist

func on_item_selected(index:int):
	s_item = index + 10*itempage
	var itemlist:Array = get_itemList()
	if(s_item >= len(itemlist)):
		$txt_title.text = ""
		$txt_details.bbcode_text = ""
		$img_item.texture = empty_item
		$btn_details.disabled = true
		$btn_details.visible = false
	else:
		var edata:EvidenceData = itemlist[s_item]
		if(len(edata.fullscreens) <= 0):
			$btn_details.disabled = true
			$btn_details.visible = false
		else:
			$btn_details.disabled = false
			$btn_details.visible = true
		$txt_title.text = edata.name
		$txt_details.bbcode_text = edata.description
		$img_item.texture = edata.icon	

func refresh_details():
	var itemlist:Array = get_itemList()
	if(s_item >= len(itemlist)):
		$pop_fullscreens.hide() #contingency. Hide if selected item does not exists
		return
	var edata:EvidenceData = itemlist[s_item]
	if(len(edata.fullscreens) <=0):
		$pop_fullscreens.hide() #contingency. Hide if selected item does have details to show
		return
	detailspage = clamp(detailspage, 0, len(edata.fullscreens)-1)
	$"pop_fullscreens/row/d-NEXT".visible = (len(edata.fullscreens) > 1)
	$"pop_fullscreens/row/d-PREV".visible = (len(edata.fullscreens) > 1)
	$"pop_fullscreens/row/d-NEXT".disabled = (detailspage >= len(edata.fullscreens)-1)
	$"pop_fullscreens/row/d-PREV".disabled = detailspage <= 0
	
	$pop_fullscreens/row/content.texture = edata.fullscreens[detailspage]
	
	


func _on_PREV_pressed():
	itempage-=1 #value is sanitized in refresh
	refresh()
func _on_NEXT_pressed():
	itempage+=1 #value is sanitized in refresh
	refresh()


func _on_dPREV_pressed():
	detailspage -= 1
	refresh_details()


func _on_dNEXT_pressed():
	detailspage += 1
	refresh_details()

#summoms the large pictures in a large popup
func _on_btn_details_pressed():
	detailspage = 0
	$pop_fullscreens.popup_centered()
	refresh_details()



#switch between evidence and profiles
func _on_btn_switch_pressed():
	profiles_mode = not profiles_mode
	$btn_switch.text = "Evidence" if profiles_mode else "Profiles"
	$txt_group.text = "Profiles" if profiles_mode else "Evidence"
	about_mode = false
	$btn_about.pressed = false
	refresh()
	


func _on_btn_about_toggled(state):
	about_mode = state
	$txt_group.text = "About/help" if state else "Profiles" if profiles_mode else "Evidence"
	refresh()
