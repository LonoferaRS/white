/client/proc/jumptoarea()
	set name = "Jump to Area"
	set desc = "Area to jump to"
	set category = "Адм.Игра"
	if(!src.holder)
		to_chat(src, "Only administrators may use this command.")
		return

	var/area/A = tgui_input_list(usr, "Area to jump to", "Jump to Area", GLOB.sortedAreas)

	if(!A)
		return

	var/list/turfs = list()
	for(var/turf/T in A)
		if(T.density)
			continue
		turfs.Add(T)

	if(length(turfs))
		var/turf/T = pick(turfs)
		usr.forceMove(T)
		log_admin("[key_name(usr)] jumped to [AREACOORD(T)]")
		message_admins("[key_name_admin(usr)] jumped to [AREACOORD(T)]")
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Jump To Area") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	else
		to_chat(src, "Nowhere to jump to!")
		return


/client/proc/jumptoturf(turf/T in world)
	set name = "Jump to Turf"
	set category = "Адм.Игра"
	if(!src.holder)
		to_chat(src, "Only administrators may use this command.")
		return

	log_admin("[key_name(usr)] jumped to [AREACOORD(T)]")
	message_admins("[key_name_admin(usr)] jumped to [AREACOORD(T)]")
	usr.forceMove(T)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Jump To Turf") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	return

/client/proc/jumptomob()
	set category = "Адм.Игра"
	set name = "Jump to Mob"

	if(!src.holder)
		to_chat(src, "Only administrators may use this command.")
		return

	var/mob/M = tgui_input_list(usr, "Mob to jump to", "Jump to mob", GLOB.mob_list)

	log_admin("[key_name(usr)] jumped to [key_name(M)]")
	message_admins("[key_name_admin(usr)] jumped to [ADMIN_LOOKUPFLW(M)] at [AREACOORD(M)]")
	if(src.mob)
		var/mob/A = src.mob
		var/turf/T = get_turf(M)
		if(T && isturf(T))
			SSblackbox.record_feedback("tally", "admin_verb", 1, "Jump To Mob") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
			A.forceMove(M.loc)
		else
			to_chat(A, "This mob is not located in the game world.")

/client/proc/jumptocoord(tx as num, ty as num, tz as num)
	set category = "Адм.Игра"
	set name = "Jump to Coordinate"

	if (!holder)
		to_chat(src, "Only administrators may use this command.")
		return

	if(src.mob)
		var/mob/A = src.mob
		var/turf/T = locate(tx,ty,tz)
		A.forceMove(T)
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Jump To Coordiate") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	message_admins("[key_name_admin(usr)] jumped to coordinates [tx], [ty], [tz]")

/client/proc/jumptokey()
	set category = "Адм.Игра"
	set name = "Jump to Key"

	if(!src.holder)
		to_chat(src, "Only administrators may use this command.")
		return

	var/list/keys = list()
	for(var/mob/M in GLOB.player_list)
		keys += M.client
	var/client/selection = tgui_input_list(usr, "Please, select a player!", "Admin Jumping", sortKey(keys))
	if(!selection)
		to_chat(src, "No keys found.")
		return
	var/mob/M = selection.mob
	log_admin("[key_name(usr)] jumped to [key_name(M)]")
	message_admins("[key_name_admin(usr)] jumped to [ADMIN_LOOKUPFLW(M)]")

	usr.forceMove(M.loc)

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Jump To Key") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/Getmob(mob/M in world)
	set category = "Адм.Игра"
	set name = "Get Mob"
	set desc = "Mob to teleport"
	if(!src.holder)
		to_chat(src, "Only administrators may use this command.")
		return

	// var/mob/M = tgui_input_list(usr, "Mob to teleport", "Get Mob", GLOB.mob_list - GLOB.dummy_mob_list)
	var/atom/loc = get_turf(usr)
	M.admin_teleport(loc)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Get Mob") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!


/// Proc to hook user-enacted teleporting behavior and keep logging of the event.
/atom/movable/proc/admin_teleport(atom/new_location)
	if(isnull(new_location))
		log_admin("[key_name(usr)] teleported [key_name(src)] to nullspace")
		moveToNullspace()
	else
		log_admin("[key_name(usr)] teleported [key_name(src)] to [AREACOORD(loc)]")
		forceMove(new_location)

/mob/admin_teleport(atom/new_location)
	var/msg = "[key_name_admin(usr)] teleported [ADMIN_LOOKUPFLW(src)] to [isnull(new_location) ? "nullspace" : ADMIN_VERBOSEJMP(loc)]"
	message_admins(msg)
	admin_ticket_log(src, msg)
	return ..()


/client/proc/Getkey()
	set category = "Адм.Игра"
	set name = "Get Key"
	set desc = "Key to teleport"

	if(!src.holder)
		to_chat(src, "Only administrators may use this command.")
		return

	var/list/keys = list()
	for(var/mob/M in GLOB.player_list)
		keys += M.client
	var/client/selection = tgui_input_list(usr, "Please, select a player!", "Admin Jumping", sortKey(keys))
	if(!selection)
		return
	var/mob/M = selection.mob

	if(!M)
		return
	log_admin("[key_name(usr)] teleported [key_name(M)]")
	var/msg = "[key_name_admin(usr)] teleported [ADMIN_LOOKUPFLW(M)]"
	message_admins(msg)
	admin_ticket_log(M, msg)
	if(M)
		M.forceMove(get_turf(usr))
		usr.forceMove(M.loc)
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Get Key") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/sendmob(mob/M in sort_mobs())
	set category = "Адм.Игра"
	set name = "Send Mob"
	if(!src.holder)
		to_chat(src, "Only administrators may use this command.")
		return
	var/area/A = tgui_input_list(usr, "Pick an area.", "Pick an area", GLOB.sortedAreas|null)
	if(A && istype(A))
		var/list/turfs = get_area_turfs(A)
		if(length(turfs) && M.forceMove(pick(turfs)))

			log_admin("[key_name(usr)] teleported [key_name(M)] to [AREACOORD(M)]")
			var/msg = "[key_name_admin(usr)] teleported [ADMIN_LOOKUPFLW(M)] to [AREACOORD(M)]"
			message_admins(msg)
			admin_ticket_log(M, msg)
		else
			to_chat(src, "Failed to move mob to a valid location.")
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Send Mob") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
