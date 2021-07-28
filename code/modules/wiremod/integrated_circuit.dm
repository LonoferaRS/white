/**
 * # Integrated Circuitboard
 *
 * A circuitboard that holds components that work together
 *
 * Has a limited amount of power.
 */
/obj/item/integrated_circuit_wiremod
	name = "интегральная схема"
	icon = 'icons/obj/module.dmi'
	icon_state = "integrated_circuit"
	inhand_icon_state = "electronic"

	/// The name that appears on the shell.
	var/display_name = ""

	/// The max length of the name.
	var/label_max_length = 24

	/// The power of the integrated circuit
	var/obj/item/stock_parts/cell/cell

	/// The shell that this circuitboard is attached to. Used by components.
	var/atom/movable/shell

	/// The attached components
	var/list/obj/item/circuit_component/attached_components = list()

	/// Whether the integrated circuit is on or not. Handled by the shell.
	var/on = FALSE

	/// The ID that is authorized to unlock/lock the shell so that the circuit can/cannot be removed.
	var/datum/weakref/owner_id

	/// The current examined component. Used in IntegratedCircuit UI
	var/datum/weakref/examined_component

	/// Set by the shell. Holds the reference to the owner who inserted the component into the shell.
	var/datum/weakref/inserter_mind

	/// X position of the examined_component
	var/examined_rel_x = 0

	/// Y position of the examined component
	var/examined_rel_y = 0

/obj/item/integrated_circuit_wiremod/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_ATOM_USB_CABLE_TRY_ATTACH, .proc/on_atom_usb_cable_try_attach)

/obj/item/integrated_circuit_wiremod/loaded/Initialize()
	. = ..()
	set_cell(new /obj/item/stock_parts/cell/high(src))

/obj/item/integrated_circuit_wiremod/Destroy()
	for(var/obj/item/circuit_component/to_delete in attached_components)
		remove_component(to_delete)
		qdel(to_delete)
	attached_components.Cut()
	shell = null
	examined_component = null
	owner_id = null
	QDEL_NULL(cell)
	return ..()

/obj/item/integrated_circuit_wiremod/examine(mob/user)
	. = ..()
	. += "<hr>"
	if(cell)
		. += "<span class='notice'>Заряд батарейки: [cell ? round(cell.percent(), 1) : 0]%.</span>"
	else
		. += "<span class='notice'>Внутри нет батарейки.</span>"

/obj/item/integrated_circuit_wiremod/proc/set_cell(obj/item/stock_parts/cell_to_set)
	SEND_SIGNAL(src, COMSIG_CIRCUIT_SET_CELL, cell_to_set)
	cell = cell_to_set

/obj/item/integrated_circuit_wiremod/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(istype(I, /obj/item/circuit_component))
		add_component_manually(I, user)
		return

	if(istype(I, /obj/item/stock_parts/cell))
		if(cell)
			balloon_alert(user, "Здесь уже есть батарейка!")
			return
		if(!user.transferItemToLoc(I, src))
			return
		set_cell(I)
		I.add_fingerprint(user)
		user.visible_message("<span class='notice'>[user] вставляет батарейку в [src.name].</span>", "<span class='notice'>Устанавливаю батарейку в [src.name].</span>")
		return

	if(istype(I, /obj/item/card/id))
		balloon_alert(user, "owner id set for [I]")
		owner_id = WEAKREF(I)
		return

	if(I.tool_behaviour == TOOL_SCREWDRIVER)
		if(!cell)
			return
		I.play_tool_sound(src)
		user.visible_message("<span class='notice'>[user] вытаскивает батарейку из [src.name].</span>", "<span class='notice'>Выкручиваю батарейку из [src.name].</span>")
		cell.forceMove(drop_location())
		set_cell(null)
		return

/**
 * Registers an movable atom as a shell
 *
 * No functionality is done here. This is so that input components
 * can properly register any signals on the shell.
 * Arguments:
 * * new_shell - The new shell to register.
 */
/obj/item/integrated_circuit_wiremod/proc/set_shell(atom/movable/new_shell)
	remove_current_shell()
	set_on(TRUE)
	SEND_SIGNAL(src, COMSIG_CIRCUIT_SET_SHELL, new_shell)
	shell = new_shell
	RegisterSignal(shell, COMSIG_PARENT_QDELETING, .proc/remove_current_shell)
	for(var/obj/item/circuit_component/attached_component as anything in attached_components)
		attached_component.register_shell(shell)
		// Their input ports may be updated with user values, but the outputs haven't updated
		// because on is FALSE
		TRIGGER_CIRCUIT_COMPONENT(attached_component, null)

/**
 * Unregisters the current shell attached to this circuit.
 */
/obj/item/integrated_circuit_wiremod/proc/remove_current_shell()
	SIGNAL_HANDLER
	if(!shell)
		return
	shell.name = initial(shell.name)
	for(var/obj/item/circuit_component/attached_component as anything in attached_components)
		attached_component.unregister_shell(shell)
	UnregisterSignal(shell, COMSIG_PARENT_QDELETING)
	shell = null
	set_on(FALSE)
	SEND_SIGNAL(src, COMSIG_CIRCUIT_SHELL_REMOVED)

/obj/item/integrated_circuit/proc/set_on(new_value)
	SEND_SIGNAL(src, COMSIG_CIRCUIT_SET_ON, new_value)
	on = new_value

/**
 * Adds a component to the circuitboard
 *
 * Once the component is added, the ports can be attached to other components
 */
/obj/item/integrated_circuit_wiremod/proc/add_component(obj/item/circuit_component/to_add, mob/living/user)
	if(to_add.parent)
		return

	if(SEND_SIGNAL(src, COMSIG_CIRCUIT_ADD_COMPONENT, to_add, user) & COMPONENT_CANCEL_ADD_COMPONENT)
		return

	if(!to_add.add_to(src))
		return

	var/success = FALSE
	if(user)
		success = user.transferItemToLoc(to_add, src)
	else
		success = to_add.forceMove(src)

	if(!success)
		return

	to_add.rel_x = rand(COMPONENT_MIN_RANDOM_POS, COMPONENT_MAX_RANDOM_POS)
	to_add.rel_y = rand(COMPONENT_MIN_RANDOM_POS, COMPONENT_MAX_RANDOM_POS)
	to_add.parent = src
	attached_components += to_add
	RegisterSignal(to_add, COMSIG_MOVABLE_MOVED, .proc/component_move_handler)
	SStgui.update_uis(src)

	if(shell)
		to_add.register_shell(shell)

/**
 * Adds a component to the circuitboard through a manual action.
 */
/obj/item/integrated_circuit_wiremod/proc/add_component_manually(obj/item/circuit_component/to_add, mob/living/user)
	if (SEND_SIGNAL(src, COMSIG_CIRCUIT_ADD_COMPONENT_MANUALLY, to_add, user) & COMPONENT_CANCEL_ADD_COMPONENT)
		return

	add_component(to_add, user)

/obj/item/integrated_circuit_wiremod/proc/component_move_handler(obj/item/circuit_component/source)
	SIGNAL_HANDLER
	if(source.loc != src)
		remove_component(source)

/**
 * Removes a component to the circuitboard
 *
 * This removes all connects between the ports
 */
/obj/item/integrated_circuit_wiremod/proc/remove_component(obj/item/circuit_component/to_remove)
	if(shell)
		to_remove.unregister_shell(shell)

	UnregisterSignal(to_remove, COMSIG_MOVABLE_MOVED)
	attached_components -= to_remove
	to_remove.disconnect()
	to_remove.parent = null
	SEND_SIGNAL(to_remove, COMSIG_CIRCUIT_COMPONENT_REMOVED, src)
	SStgui.update_uis(src)
	to_remove.removed_from(src)

/obj/item/integrated_circuit_wiremod/get_cell()
	return cell

/obj/item/integrated_circuit_wiremod/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/circuit_assets)
	)

/obj/item/integrated_circuit_wiremod/ui_data(mob/user)
	. = list()
	.["components"] = list()
	for(var/obj/item/circuit_component/component as anything in attached_components)
		var/list/component_data = list()
		component_data["input_ports"] = list()
		for(var/datum/port/input/port as anything in component.input_ports)
			var/current_data = port.input_value
			if(isatom(current_data)) // Prevent passing the name of the atom.
				current_data = null
			component_data["input_ports"] += list(list(
				"name" = port.name,
				"type" = port.datatype,
				"ref" = REF(port), // The ref is the identifier to work out what it is connected to
				"connected_to" = REF(port.connected_port),
				"color" = port.color,
				"current_data" = current_data,
			))
		component_data["output_ports"] = list()
		for(var/datum/port/output/port as anything in component.output_ports)
			component_data["output_ports"] += list(list(
				"name" = port.name,
				"type" = port.datatype,
				"ref" = REF(port),
				"color" = port.color
			))

		component_data["name"] = component.display_name
		component_data["x"] = component.rel_x
		component_data["y"] = component.rel_y
		component_data["option"] = component.current_option
		component_data["options"] = component.options
		component_data["removable"] = component.removable
		.["components"] += list(component_data)

	.["display_name"] = display_name

	var/obj/item/circuit_component/examined
	if(examined_component)
		examined = examined_component.resolve()

	.["examined_name"] = examined?.display_name
	.["examined_desc"] = examined?.display_desc
	.["examined_notices"] = examined?.get_ui_notices()
	.["examined_rel_x"] = examined_rel_x
	.["examined_rel_y"] = examined_rel_y

	.["is_admin"] = check_rights_for(user.client, R_ADMIN)

/obj/item/integrated_circuit_wiremod/ui_host(mob/user)
	if(shell)
		return shell
	return ..()

/obj/item/integrated_circuit_wiremod/ui_state(mob/user)
	if(!shell)
		return GLOB.hands_state
	return GLOB.physical_obscured_state

/obj/item/integrated_circuit_wiremod/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IntegratedCircuit", name)
		ui.open()
		ui.set_autoupdate(FALSE)

#define WITHIN_RANGE(id, table) (id >= 1 && id <= length(table))

/obj/item/integrated_circuit_wiremod/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("add_connection")
			var/input_component_id = text2num(params["input_component_id"])
			var/output_component_id = text2num(params["output_component_id"])
			var/input_port_id = text2num(params["input_port_id"])
			var/output_port_id = text2num(params["output_port_id"])
			if(!WITHIN_RANGE(input_component_id, attached_components) || !WITHIN_RANGE(output_component_id, attached_components))
				return
			var/obj/item/circuit_component/input_component = attached_components[input_component_id]
			var/obj/item/circuit_component/output_component = attached_components[output_component_id]

			if(!WITHIN_RANGE(input_port_id, input_component.input_ports) || !WITHIN_RANGE(output_port_id, output_component.output_ports))
				return
			var/datum/port/input/input_port = input_component.input_ports[input_port_id]
			var/datum/port/output/output_port = output_component.output_ports[output_port_id]

			if(input_port.datatype != PORT_TYPE_ANY && !output_port.compatible_datatype(input_port.datatype))
				return

			input_port.register_output_port(output_port)
			. = TRUE
		if("remove_connection")
			var/component_id = text2num(params["component_id"])
			var/is_input = params["is_input"]
			var/port_id = text2num(params["port_id"])

			if(!WITHIN_RANGE(component_id, attached_components))
				return
			var/obj/item/circuit_component/component = attached_components[component_id]

			var/list/port_table
			if(is_input)
				port_table = component.input_ports
			else
				port_table = component.output_ports

			if(!WITHIN_RANGE(port_id, port_table))
				return

			var/datum/port/port = port_table[port_id]
			port.disconnect()
			. = TRUE
		if("detach_component")
			var/component_id = text2num(params["component_id"])
			if(!WITHIN_RANGE(component_id, attached_components))
				return
			var/obj/item/circuit_component/component = attached_components[component_id]
			if(!component.removable)
				return
			component.disconnect()
			remove_component(component)
			if(component.loc == src)
				usr.put_in_hands(component)
			. = TRUE
		if("set_component_coordinates")
			var/component_id = text2num(params["component_id"])
			if(!WITHIN_RANGE(component_id, attached_components))
				return
			var/obj/item/circuit_component/component = attached_components[component_id]
			component.rel_x = min(max(-COMPONENT_MAX_POS, text2num(params["rel_x"])), COMPONENT_MAX_POS)
			component.rel_y = min(max(-COMPONENT_MAX_POS, text2num(params["rel_y"])), COMPONENT_MAX_POS)
			. = TRUE
		if("set_component_option")
			var/component_id = text2num(params["component_id"])
			if(!WITHIN_RANGE(component_id, attached_components))
				return
			var/obj/item/circuit_component/component = attached_components[component_id]
			var/option = params["option"]
			if(!(option in component.options))
				return
			component.set_option(option)
			. = TRUE
		if("set_component_input")
			var/component_id = text2num(params["component_id"])
			var/port_id = text2num(params["port_id"])
			if(!WITHIN_RANGE(component_id, attached_components))
				return
			var/obj/item/circuit_component/component = attached_components[component_id]
			if(!WITHIN_RANGE(port_id, component.input_ports))
				return
			var/datum/port/input/port = component.input_ports[port_id]

			if(port.connected_port)
				return

			if(params["set_null"])
				port.set_input(null)
				return TRUE

			if(params["marked_atom"])
				if(port.datatype != PORT_TYPE_ATOM && port.datatype != PORT_TYPE_ANY)
					return
				var/obj/item/multitool/circuit/marker = usr.get_active_held_item()
				if(!istype(marker))
					return TRUE
				if(!marker.marked_atom)
					port.set_input(null)
					marker.say("Сброс значения порта ('[port.name]').")
					return TRUE
				marker.say("Обновления значения порта ('[port.name]') до значения метки.")
				port.set_input(marker.marked_atom)
				return TRUE

			var/user_input = params["input"]
			switch(port.datatype)
				if(PORT_TYPE_NUMBER)
					port.set_input(text2num(user_input))
				if(PORT_TYPE_ANY)
					port.set_input(text2num(user_input) || user_input)
				if(PORT_TYPE_STRING)
					port.set_input(user_input)
				if(PORT_TYPE_SIGNAL)
					balloon_alert(usr, "triggered [port.name]")
					port.set_input(COMPONENT_SIGNAL)
			. = TRUE
		if("get_component_value")
			var/component_id = text2num(params["component_id"])
			var/port_id = text2num(params["port_id"])
			if(!WITHIN_RANGE(component_id, attached_components))
				return
			var/obj/item/circuit_component/component = attached_components[component_id]
			if(!WITHIN_RANGE(port_id, component.output_ports))
				return

			var/datum/port/output/port = component.output_ports[port_id]
			var/value = port.output_value
			if(isatom(value))
				value = port.convert_value(port.output_value)
			else if(isnull(value))
				value = "null"
			var/string_form = copytext("[value]", 1, PORT_MAX_STRING_DISPLAY)
			if(length(string_form) >= PORT_MAX_STRING_DISPLAY-1)
				string_form += "..."
			balloon_alert(usr, "[port.name] значение: [string_form]")
			. = TRUE
		if("set_display_name")
			var/new_name = params["display_name"]

			if(new_name)
				set_display_name(strip_html(params["display_name"], label_max_length))
			else
				set_display_name("")

			if(shell)
				if(display_name != "")
					shell.name = "[initial(shell.name)] ([display_name])"
				else
					shell.name = initial(shell.name)

			. = TRUE
		if("set_examined_component")
			var/component_id = text2num(params["component_id"])
			if(!WITHIN_RANGE(component_id, attached_components))
				return
			examined_component = WEAKREF(attached_components[component_id])
			examined_rel_x = text2num(params["x"])
			examined_rel_y = text2num(params["y"])
			. = TRUE
		if("remove_examined_component")
			examined_component = null
			. = TRUE
		if("save_circuit")
			var/client/saver = usr.client
			if(!check_rights_for(saver, R_ADMIN))
				return
			var/temp_file = file("data/CircuitDownloadTempFile")
			fdel(temp_file)
			WRITE_FILE(temp_file, convert_to_json())
			DIRECT_OUTPUT(saver, ftp(temp_file, "[display_name || "circuit"].json"))
			. = TRUE

/obj/item/integrated_circuit/proc/on_atom_usb_cable_try_attach(datum/source, obj/item/usb_cable/usb_cable, mob/user)
	usb_cable.balloon_alert(user, "circuit needs to be in a compatible shell")
	return COMSIG_CANCEL_USB_CABLE_ATTACK

#undef WITHIN_RANGE

/// Sets the display name that appears on the shell.
/obj/item/integrated_circuit/proc/set_display_name(new_name)
	display_name = new_name

/**
 * Returns the creator of the integrated circuit. Used in admin messages and other related things.
 */
/obj/item/integrated_circuit/proc/get_creator_admin()
	return get_creator(include_link = TRUE)

/**
 * Returns the creator of the integrated circuit. Used in admin logs and other related things.
 */
/obj/item/integrated_circuit/proc/get_creator(include_link = FALSE)
	var/datum/mind/inserter
	if(inserter_mind)
		inserter = inserter_mind.resolve()

	var/obj/item/card/id/id_card
	if(owner_id)
		id_card = owner_id.resolve()

	return "(Shell: [shell || "*null*"], Inserter: [key_name(inserter, include_link)], Owner ID: [id_card?.name || "*null*"])"
