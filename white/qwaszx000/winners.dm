#define ENGINEER_WINER_CKEY "Laxesh"
#define ROBUST_WINER_CKEY "moonmandoom" // 2020. Old winner is DarkKeeper072

/obj/item/extinguisher/robust
	name = "Robust fire extinguisher"
	desc = "Used to kill humans."
	icon_state = "foam_extinguisher0"
	inhand_icon_state = "foam_extinguisher"
	dog_fashion = null
	sprite_name = "foam_extinguisher"
	throwforce = 15
	force = 15
	precision = TRUE


/obj/item/clothing/neck/cloak/engineer_winer
	name = "Senior Engineer's cloak"
	desc = "Trust me - i'm an ENGINEER!!!"
	armor = list("melee" = 15, "bullet" = 10, "laser" = 5, "energy" = 10, "bomb" = 20, "bio" = 10, "rad" = 50, "fire" = 20, "acid" = 20)
	icon_state = "cecloak"


/obj/structure/displaycase/winner
	name = "Case of Glory"
	desc = "Looks, like it has selfdestruct system. It has small fingerprint scanner with label - made by qwaszx000."
	var/need_key = null

/obj/structure/displaycase/winner/Initialize()
	.=..()
	if(start_showpieces.len > 0)
		if("trophy_message" in start_showpieces)
			trophy_message = start_showpieces["trophy_message"]
		if("need_key" in start_showpieces)
			need_key = start_showpieces["need_key"]
		if("type" in start_showpieces)
			if(showpiece)
				QDEL_NULL(showpiece)
			start_showpiece_type = start_showpieces["type"]
			showpiece = new start_showpiece_type (src)
			update_icon()

/obj/structure/displaycase/winner/obj_break(damage_flag)
	.=..()
	if(broken && !(flags_1 & NODECONSTRUCT_1))
		src.Destroy()
		QDEL_NULL(src)

/obj/structure/displaycase/winner/attackby(obj/item/W, mob/user, params)
	if(open && !showpiece)
		if(user.transferItemToLoc(W, src))
			showpiece = W
			to_chat(user, "<span class='notice'>You put [W] on display</span>")
			update_icon()
	else if(W.tool_behaviour == TOOL_WELDER && user.a_intent == INTENT_HELP && !broken)
		if(obj_integrity < max_integrity)
			if(!W.tool_start_check(user, amount=5))
				to_chat(user, "<span class='warning'>No fuel!</span>")
				return
			to_chat(user, "<span class='notice'>You begin repairing [src].</span>")
			if(W.use_tool(src, user, 40, amount=5, volume=50))
				obj_integrity = max_integrity
				update_icon()
				to_chat(user, "<span class='notice'>You repair [src].</span>")
				return
		else
			to_chat(user, "<span class='warning'>[capitalize(src.name)] is already in good condition!</span>")
			return
	else if(W.GetID() && !broken && openable)
		to_chat(user, "<span class='warning'>It has fingerprint lock! Not ID!</span>")
		return
	else
		return ..()

/obj/structure/displaycase/winner/attack_hand(mob/user)
	if(lowertext(user.ckey) == lowertext(need_key) && !broken && openable)
		to_chat(user,  "<span class='notice'>You [open ? "close":"open"] [src].</span>")
		toggle_lock(user)
	else
		to_chat(user, "<span class='warning'>You are loser.</span>")

/obj/structure/displaycase/winner/AltClick(mob/user)
	if(open)
		dump()
		update_icon()

/obj/structure/displaycase/winner/robust
	start_showpieces = list(list("type" = /obj/item/extinguisher/robust, "trophy_message" = "Glory to <span class='boldnotice'>" + ROBUST_WINER_CKEY + "</span>!", "need_key" = ROBUST_WINER_CKEY))

/obj/structure/displaycase/winner/engineer
	start_showpieces = list(list("type" = /obj/item/clothing/neck/cloak/engineer_winer, "trophy_message" = "Glory to <span class='boldnotice'>" + ENGINEER_WINER_CKEY + "</span>!", "need_key" = ENGINEER_WINER_CKEY))

/obj/structure/statue/gold/robust
	name = "Статуя Solomon Mosser"
	desc = "Победитель робаст-турнира 2020. Надпись снизу гласит: \"Хайпово\".<hr><b>Moonmandoom</b> - первое место!"
	icon = 'white/valtos/icons/robust.dmi'
	icon_state = "gold_2020"
	can_be_unanchored = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	layer = ABOVE_MOB_LAYER
	anchored = TRUE
	flags_1 = NODECONSTRUCT_1

/obj/structure/sign/plaques/robust
	name = "Портрет Daniil Bassow"
	desc = "Здесь изображён робастный мальчик. Твои трусики намокают...<hr><b>DANILCUS</b> - второе место!"
	icon = 'white/valtos/icons/robust.dmi'
	icon_state = "silver_2020"
	can_be_unanchored = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	custom_materials = list(/datum/material/silver=MINERAL_MATERIAL_AMOUNT*2)
	abstract_type = /obj/structure/statue/silver
	flags_1 = NODECONSTRUCT_1

/obj/structure/sign/plaques/robust/bronze
	name = "Портрет"
	desc = "Доктор Киара всех полечит и исцелит!<hr><b>Leviathan21</b> AKA <i>Masturbator</i> - третье место!"
	icon_state = "bronze_2020"
	custom_materials = list(/datum/material/bronze=MINERAL_MATERIAL_AMOUNT*2)
	abstract_type = /obj/structure/statue/bronze
	flags_1 = NODECONSTRUCT_1
