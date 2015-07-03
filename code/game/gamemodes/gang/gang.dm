//gang.dm
//Gang War Game Mode

/datum/game_mode
	var/list/datum/mind/A_gang = list() //gang A Members
	var/list/datum/mind/B_gang = list() //gang B Members
	var/list/datum/mind/A_bosses = list() //gang A Bosses
	var/list/datum/mind/B_bosses = list() //gang B Bosses
	var/obj/item/device/gangtool/A_tools = list()
	var/obj/item/device/gangtool/B_tools = list()
	var/datum/gang_points/gang_points
	var/list/A_territory = list()
	var/list/B_territory = list()

/datum/game_mode/gang
	name = "gang war"
	config_tag = "gang"
	//antag_flag = BE_GANG
	restricted_jobs = list("Security Officer", "Warden", "Detective", "AI", "Cyborg","Captain", "Head of Personnel", "Head of Security", "Chief Engineer", "Research Director", "Chief Medical Officer")
	//required_players = 15
	required_players = 2
	required_enemies = 2
	//recommended_enemies = 4
	recommended_enemies = 2

	var/finished = 0
	var/checkwin_counter = 0
///////////////////////////
//Announces the game type//
///////////////////////////
/datum/game_mode/gang/announce()
	world << "<B>The current game mode is - Gang War!</B>"
	world << "<B>A violent turf war has erupted on the station!<BR>Gangsters -  Take over the station by claiming more than 66% of the station! <BR>Crew - The gangs will try to keep you on the station. Successfully evacuate the station to win!</B>"


///////////////////////////////////////////////////////////////////////////////
//Gets the round setup, cancelling if there's not enough players at the start//
///////////////////////////////////////////////////////////////////////////////
/datum/game_mode/gang/pre_setup()

	var/list/antag_candidates = get_players_for_role(BE_REV)

	if(config.protect_roles_from_antagonist)
		restricted_jobs += protected_jobs

	for(var/datum/mind/player in antag_candidates)
		for(var/job in restricted_jobs)//Removing heads and such from the list
			if(player.assigned_role == job)
				antag_candidates -= player

	if(antag_candidates.len >= 2)
		assign_bosses(antag_candidates)

	if(!A_bosses.len || !B_bosses.len)
		return 0

	return 1


/datum/game_mode/gang/post_setup()
	spawn(rand(10,100))
		for(var/datum/mind/boss_mind in A_bosses)
			update_gang_icons_added(boss_mind, "A")
			forge_gang_objectives(boss_mind, "A")
			greet_gang(boss_mind)
			equip_gang(boss_mind.current)

		for(var/datum/mind/boss_mind in B_bosses)
			update_gang_icons_added(boss_mind, "B")
			forge_gang_objectives(boss_mind, "B")
			greet_gang(boss_mind)
			equip_gang(boss_mind.current)

	modePlayer += A_bosses
	modePlayer += B_bosses
	..()


/datum/game_mode/gang/process()
	checkwin_counter++
	if(checkwin_counter >= 5)
		if(!finished)
			ticker.mode.check_win()
		checkwin_counter = 0
	return 0

/datum/game_mode/gang/proc/assign_bosses(var/list/antag_candidates = list())
	var/datum/mind/boss = pick(antag_candidates)
	A_bosses += boss
	antag_candidates -= boss
	boss.special_role = "[gang_name("A")] Gang (A) Boss"
	log_game("[boss.key] has been selected as the boss for the [gang_name("A")] Gang (A)")

	boss = pick(antag_candidates)
	B_bosses += boss
	antag_candidates -= boss
	boss.special_role = "[gang_name("B")] Gang (B) Boss"
	log_game("[boss.key] has been selected as the boss for the [gang_name("B")] Gang (B)")

/datum/game_mode/proc/forge_gang_objectives(var/datum/mind/boss_mind)
	var/datum/objective/rival_obj = new
	rival_obj.owner = boss_mind
	rival_obj.explanation_text = "Claim more than 66% the station before the [(boss_mind in A_bosses) ? gang_name("B") : gang_name("A")] Gang does."
	boss_mind.objectives += rival_obj


/datum/game_mode/proc/greet_gang(var/datum/mind/boss_mind, var/you_are=1)
	var/obj_count = 1
	if (you_are)
		boss_mind.current << "<FONT size=3 color=red><B>You are the founding member of the [(boss_mind in A_bosses) ? gang_name("A") : gang_name("B")] Gang!</B></FONT>"
	for(var/datum/objective/objective in boss_mind.objectives)
		boss_mind.current << "<B>Objective #[obj_count]</B>: [objective.explanation_text]"
		obj_count++

///////////////////////////////////////////////////////////////////////////
//This equips the bosses with their gear, and makes the clown not clumsy//
///////////////////////////////////////////////////////////////////////////
/datum/game_mode/proc/equip_gang(mob/living/carbon/human/mob)
	if(!istype(mob))
		return

	if (mob.mind)
		if (mob.mind.assigned_role == "Clown")
			mob << "Your training has allowed you to overcome your clownish nature, allowing you to wield weapons without harming yourself."
			mob.mutations.Remove(CLUMSY)

	var/obj/item/weapon/pen/gang/T = new(mob)
	var/obj/item/device/gangtool/gangtool = new(mob)
	var/obj/item/toy/crayon/spraycan/gang/SC = new(mob)

	var/list/slots = list (
		"backpack" = slot_in_backpack,
		"left pocket" = slot_l_store,
		"right pocket" = slot_r_store,
		"left hand" = slot_l_hand,
		"right hand" = slot_r_hand,
	)

	. = 0

	var/where = mob.equip_in_one_of_slots(gangtool, slots)
	if (!where)
		mob << "Your Syndicate benefactors were unfortunately unable to get you a Gangtool."
	else
		gangtool.register_device(mob)
		mob << "The <b>Gangtool</b> in your [where] will allow you to purchase items for your gang and prevent the station from evacuating before you can take over. Use it to recall the emergency shuttle from anywhere on the station."
		mob << "You can also promote your gang members to lieutenant by giving them an unregistered gangtool. Lieutenants cannot be deconverted and are able to use recrtuitment pens and gangtools."
		. += 1

	var/where2 = mob.equip_in_one_of_slots(T, slots)
	if (!where2)
		mob << "Your Syndicate benefactors were unfortunately unable to get you a recruitment pen to start."
	else
		mob << "The <b>recruitment pen</b> in your [where2] will help you get your gang started. Use it on unsuspecting crew members to recruit them."
		. += 1

	var/where3 = mob.equip_in_one_of_slots(SC, slots)
	if (!where3)
		mob << "Your Syndicate benefactors were unfortunately unable to get you a territory spraycan to start."
	else
		mob << "The <b>territory spraycan</b> in your [where3] can be used to claim areas of the station for your gang. The more territory your gang controls, the more supply points you get."
		. += 1
	mob.update_icons()

	return .

/////////////////////////////////////////////
//Checks if the either gang have won or not//
/////////////////////////////////////////////
/datum/game_mode/gang/check_win()
	if(A_territory.len > (start_state.num_territories / 3))
		finished = "A" //Gang A wins

	else if(B_territory.len > (start_state.num_territories / 3))
		finished = "B" //Gang B wins

///////////////////////////////
//Checks if the round is over//
///////////////////////////////
/datum/game_mode/gang/check_finished()
	if(finished)
		return 1
	return ..() //Check for evacuation/nuke

///////////////////////////////////////////
//Deals with converting players to a gang//
///////////////////////////////////////////
/datum/game_mode/proc/add_gangster(datum/mind/gangster_mind, var/gang, var/check = 1)
	if(check && isloyal(gangster_mind.current)) //Check to see if the potential gangster is implanted
		return 0
	if((gangster_mind in A_bosses) || (gangster_mind in A_gang) || (gangster_mind in B_bosses) || (gangster_mind in B_gang))
		return 0
	if(gang == "A")
		A_gang += gangster_mind
	else
		B_gang += gangster_mind
	if(check)
		if(iscarbon(gangster_mind.current))
			var/mob/living/carbon/carbon_mob = gangster_mind.current
			carbon_mob.silent = max(carbon_mob.silent, 5)
		gangster_mind.current.Stun(5)
	gangster_mind.current << "<FONT size=3 color=red><B>You are now a member of the [gang=="A" ? gang_name("A") : gang_name("B")] Gang!</B></FONT>"
	gangster_mind.current << "<font color='red'>Help your bosses take over the station by claiming territory with the special spraycans they provide. Simply spray on any unclaimed area of the station.</font>"
	gangster_mind.current << "<font color='red'>You can identify your bosses by their brown \"B\" icon.</font>"
	gangster_mind.current.attack_log += "\[[time_stamp()]\] <font color='red'>Has been converted to the [gang=="A" ? "[gang_name("A")] Gang (A)" : "[gang_name("B")] Gang (B)"]!</font>"
	gangster_mind.special_role = "[gang=="A" ? "[gang_name("A")] Gang (A)" : "[gang_name("B")] Gang (B)"]"
	update_gang_icons_added(gangster_mind,gang)
	return 1
////////////////////////////////////////////////////////////////////
//Deals with players reverting to neutral (Not a gangster anymore)//
////////////////////////////////////////////////////////////////////
/datum/game_mode/proc/remove_gangster(datum/mind/gangster_mind, var/beingborged, var/silent, var/exclude_bosses=0)
	var/gang

	if(!exclude_bosses)
		if(gangster_mind in A_bosses)
			A_bosses -= gangster_mind
			gang = "A"

		if(gangster_mind in B_bosses)
			B_bosses -= gangster_mind
			gang = "B"

	if(gangster_mind in A_gang)
		A_gang -= gangster_mind
		gang = "A"

	if(gangster_mind in B_gang)
		B_gang -= gangster_mind
		gang = "B"

	if(!gang) //not a valid gangster
		return

	gangster_mind.special_role = null
	if(silent < 2)
		gangster_mind.current.attack_log += "\[[time_stamp()]\] <font color='red'>Has reformed and defected from the [gang=="A" ? "[gang_name("A")] Gang (A)" : "[gang_name("B")] Gang (B)"]!</font>"

		if(beingborged)
			if(!silent)
				gangster_mind.current.visible_message("The frame beeps contentedly from the MMI before initalizing it.")
			gangster_mind.current << "<FONT size=3 color=red><B>The frame's firmware detects and deletes your criminal behavior! You are no longer a gangster!</B></FONT>"
			message_admins("[key_name_admin(gangster_mind.current)] <A HREF='?_src_=holder;adminmoreinfo=\ref[gangster_mind.current]'>?</A> has been borged while being a member of the [gang=="A" ? "[gang_name("A")] Gang (A)" : "[gang_name("B")] Gang (B)"] Gang. They are no longer a gangster.")
		else
			if(!silent)
				gangster_mind.current.Paralyse(5)
				gangster_mind.current.visible_message("[gangster_mind.current] looks like they've given up the life of crime!")
			gangster_mind.current << "<FONT size=3 color=red><B>You have been reformed! You are no longer a gangster!</B></FONT>"

	update_gang_icons_removed(gangster_mind)


/////////////////////////////////////////////////////////////////////////////////////////////////
//Keeps track of players having the correct icons////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
/datum/game_mode/proc/update_all_gang_icons()
	spawn(0)
		var/list/all_gangsters = A_bosses + B_bosses + A_gang + B_gang

		//Delete all gang icons
		for(var/datum/mind/gang_mind in all_gangsters)
			if(gang_mind.current)
				if(gang_mind.current.client)
					for(var/image/I in gang_mind.current.client.images)
						if(I.icon_state == "gangster" || I.icon_state == "gang_boss")
							del(I)

		update_gang_icons("A")
		update_gang_icons("B")

/datum/game_mode/proc/update_gang_icons(var/gang)
	var/list/bosses
	var/list/gangsters
	if(gang == "A")
		bosses = A_bosses
		gangsters = A_gang
	else if(gang == "B")
		bosses = B_bosses
		gangsters = B_gang
	else
		world << "ERROR: Invalid gang in update_gang_icons()"

	//Update gang icons for boss' visions
	for(var/datum/mind/boss_mind in bosses)
		if(boss_mind.current)
			if(boss_mind.current.client)
				for(var/datum/mind/gangster_mind in gangsters)
					if(gangster_mind.current)
						var/I = image('icons/mob/mob.dmi', loc = gangster_mind.current, icon_state = "gangster")
						boss_mind.current.client.images += I
				for(var/datum/mind/boss2_mind in bosses)
					if(boss2_mind.current)
						var/I = image('icons/mob/mob.dmi', loc = boss2_mind.current, icon_state = "gang_boss")
						boss_mind.current.client.images += I

	//Update boss and self icons for gangsters' visions
	for(var/datum/mind/gangster_mind in gangsters)
		if(gangster_mind.current)
			if(gangster_mind.current.client)
				for(var/datum/mind/boss_mind in bosses)
					if(boss_mind.current)
						var/I = image('icons/mob/mob.dmi', loc = boss_mind.current, icon_state = "gang_boss")
						gangster_mind.current.client.images += I
					//Tag themselves to see
					var/K
					if(gangster_mind in bosses) //If the new gangster is a boss himself
						K = image('icons/mob/mob.dmi', loc = gangster_mind.current, icon_state = "gang_boss")
					else
						K = image('icons/mob/mob.dmi', loc = gangster_mind.current, icon_state = "gangster")
					gangster_mind.current.client.images += K

/////////////////////////////////////////////////
//Assigns icons when a new gangster is recruited//
/////////////////////////////////////////////////
/datum/game_mode/proc/update_gang_icons_added(datum/mind/recruit_mind, var/gang)
	var/list/bosses
	if(gang == "A")
		bosses = A_bosses
	else if(gang == "B")
		bosses = B_bosses
	if(!gang)
		world << "ERROR: Invalid gang in update_gang_icons_added()"

	spawn(0)
		for(var/datum/mind/boss_mind in bosses)
			//Tagging the new gangster for the bosses to see
			if(boss_mind.current)
				if(boss_mind.current.client)
					var/I
					if(recruit_mind in bosses) //If the new gangster is a boss himself
						I = image('icons/mob/mob.dmi', loc = recruit_mind.current, icon_state = "gang_boss")
					else
						I = image('icons/mob/mob.dmi', loc = recruit_mind.current, icon_state = "gangster")
					boss_mind.current.client.images += I
			//Tagging every boss for the new gangster to see
			if(recruit_mind.current)
				if(recruit_mind.current.client)
					var/image/J = image('icons/mob/mob.dmi', loc = boss_mind.current, icon_state = "gang_boss")
					recruit_mind.current.client.images += J
		//Tag themselves to see
		if(recruit_mind.current)
			if(recruit_mind.current.client)
				var/K
				if(recruit_mind in bosses) //If the new gangster is a boss himself
					K = image('icons/mob/mob.dmi', loc = recruit_mind.current, icon_state = "gang_boss")
				else
					K = image('icons/mob/mob.dmi', loc = recruit_mind.current, icon_state = "gangster")
				recruit_mind.current.client.images += K

////////////////////////////////////////
//Keeps track of deconverted gangsters//
////////////////////////////////////////
/datum/game_mode/proc/update_gang_icons_removed(datum/mind/defector_mind)
	var/list/all_gangsters = A_bosses + B_bosses + A_gang + B_gang

	spawn(0)
		//Remove defector's icon from gangsters' visions
		for(var/datum/mind/boss_mind in all_gangsters)
			if(boss_mind.current)
				if(boss_mind.current.client)
					for(var/image/I in boss_mind.current.client.images)
						if((I.icon_state == "gangster" || I.icon_state == "gang_boss") && I.loc == defector_mind.current)
							del(I)

		//Remove gang icons from defector's vision
		if(defector_mind.current)
			if(defector_mind.current.client)
				for(var/image/I in defector_mind.current.client.images)
					if(I.icon_state == "gangster" || I.icon_state == "gang_boss")
						del(I)

//////////////////////////////////////////////////////////////////////
//Announces the end of the game with all relavent information stated//
//////////////////////////////////////////////////////////////////////
/datum/game_mode/gang/declare_completion()
	if(!finished)
		world << "<FONT size=3 color=red><B>The station was [station_was_nuked ? "destroyed!" : "evacuated before either gang could claim it!"]</B></FONT>"
	else
		world << "<FONT size=3 color=red><B>The [finished=="A" ? gang_name("A") : gang_name("B")] Gang has taken over the station!</B></FONT>"
	..()
	return 1

/datum/game_mode/proc/auto_declare_completion_gang()
	var/winner
	var/datum/game_mode/gang/game_mode = ticker.mode
	if(istype(game_mode))
		if(game_mode.finished)
			winner = game_mode.finished
		else
			winner = "Draw"

	if(A_bosses.len || A_gang.len)
		if(winner)
			world << "<br><b>The [gang_name("A")] Gang was [winner=="A" ? "<font color=green>victorious</font>" : "<font color=red>defeated</font>"] with [round((ticker.mode.A_territory.len/start_state.num_territories)*100, 1)]% control of the station!</b>"
		world << "<br>The [gang_name("A")] Gang Bosses were:"
		gang_membership_report(A_bosses)
		world << "<br>The [gang_name("A")] Gangsters were:"
		gang_membership_report(A_gang)
		world << "<br>"

	if(B_bosses.len || B_gang.len)
		if(winner)
			world << "<br><b>The [gang_name("B")] Gang was [winner=="B" ? "<font color=green>victorious</font>" : "<font color=red>defeated</font>"] with [round((ticker.mode.B_territory.len/start_state.num_territories)*100, 1)]% control of the station!</b></b>"
		world << "<br>The [gang_name("B")] Gang Bosses were:"
		gang_membership_report(B_bosses)
		world << "<br>The [gang_name("B")] Gangsters were:"
		gang_membership_report(B_gang)
		world << "<br>"

/datum/game_mode/proc/gang_membership_report(var/list/membership)
	var/text = ""
	for(var/datum/mind/gang_mind in membership)
		text += "<br><b>[gang_mind.key]</b> was <b>[gang_mind.name]</b> ("
		if(gang_mind.current)
			if(gang_mind.current.stat == DEAD || isbrain(gang_mind.current))
				text += "died"
			else if(gang_mind.current.z != 1)
				text += "fled the station"
			else
				text += "survived"
			if(gang_mind.current.real_name != gang_mind.name)
				text += " as <b>[gang_mind.current.real_name]</b>"
		else
			text += "body destroyed"
		text += ")"

	world << text


//////////////////////////////////
//Handles gang points and income//
//////////////////////////////////

/datum/gang_points
	var/A = 30
	var/B = 30
	var/next_point_time = 0

/datum/gang_points/proc/start()
	next_point_time = world.time + 3000
	spawn(3000)
		income()

/datum/gang_points/proc/income()
	var/A_new = min(100,(A + 10 + min(ticker.mode.A_territory.len,40)))
	var/A_message = ""
	if(A_new != A)
		A_message += "Your gang has gained [A_new - A] Influence from their control of [round((ticker.mode.A_territory.len/start_state.num_territories)*100, 1)]% of the station."
	if(A_new == 100)
		A_message += "Maximum influence reached."
	A = A_new
	ticker.mode.message_gangtools(ticker.mode.A_tools,A_message)

	var/B_new = min(100,(B + 10 + min(ticker.mode.B_territory.len,40)))
	var/B_message = ""
	if(B_new != B)
		B_message += "Your gang has collected [B_new - B] Influence from their control of [round((ticker.mode.B_territory.len/start_state.num_territories)*100, 1)]% of the station."
	if(B_new == 100)
		B_message += "Maximum influence reached."
	B = B_new
	ticker.mode.message_gangtools(ticker.mode.B_tools,B_message)

	start()


////////////////////////////////////////////////
//Sends a message to the boss via his gangtool//
////////////////////////////////////////////////

/datum/game_mode/proc/message_gangtools(var/list/gangtools,var/message,var/priority=2) //0 Territories Gained | 1 Territories lost | 2 Beep!
	if(!gangtools.len || !message)
		return
	for(var/obj/item/device/gangtool/tool in gangtools)
		if(tool.ignore_messages <= priority)
			var/mob/living/mob = get(tool.loc,/mob/living)
			if(mob && mob.mind)
				if(((tool.gang == "A") && ((mob.mind in A_gang) || (mob.mind in A_bosses))) || ((tool.gang == "B") && ((mob.mind in B_gang) || (mob.mind in B_bosses))))
					mob << "<span class='notice'>\icon[tool] [message]</span>"
					if(priority>=2)
						playsound(mob.loc, 'sound/machines/twobeep.ogg', 50, 1) 
