/obj/effect/proc_holder/changeling
	panel = "Changeling"
	name = "Prototype Sting"
	desc = "" // Fluff
	var/helptext = "" // Details
	var/chemical_cost = 0 // negative chemical cost is for passive abilities (chemical glands)
	var/genomecost = -1 //cost of the sting in dna points. 0 = auto-purchase, -1 = cannot be purchased
	var/req_dna = 0  //amount of dna needed to use this ability. Changelings always have atleast 1
	var/req_human = 0 //if you need to be human to use this ability
	var/req_stat = CONSCIOUS // CONSCIOUS, UNCONSCIOUS or DEAD
	var/genetic_damage = 0 // genetic damage caused by using the sting. Nothing to do with cloneloss.
	var/max_genetic_damage = 100 // hard counter for spamming abilities. Not used/balanced much yet.

/obj/effect/proc_holder/changeling/proc/on_purchase(mob/user)
	return

/obj/effect/proc_holder/changeling/Click()
	var/mob/user = usr
	if(!user || !ischangeling(user))
		return
	try_to_sting(user)

/obj/effect/proc_holder/changeling/proc/try_to_sting(mob/user, mob/target)
	if(!can_sting(user, target))
		return
	var/datum/role/changeling/c = user.mind.GetRoleByType(/datum/role/changeling)
	if(sting_action(user, target))
		sting_feedback(user, target)
		take_chemical_cost(c)

/obj/effect/proc_holder/changeling/proc/sting_action(mob/user, mob/target)
	return FALSE

/obj/effect/proc_holder/changeling/proc/sting_feedback(mob/user, mob/target)
	return

/obj/effect/proc_holder/changeling/proc/take_chemical_cost(datum/role/changeling/changeling)
	changeling.chem_charges -= chemical_cost
	changeling.geneticdamage += genetic_damage

//Fairly important to remember to return TRUE on success >.<
/obj/effect/proc_holder/changeling/proc/can_sting(mob/user, mob/target)
	if(!ishuman(user) && !ismonkey(user)) //typecast everything from mob to carbon from this point onwards
		return FALSE
	if(req_human && !ishuman(user))
		to_chat(user, "<span class='warning'>We cannot do that in this form!</span>")
		return FALSE
	var/datum/role/changeling/c = user.mind.GetRoleByType(/datum/role/changeling)
	if(c.chem_charges<chemical_cost)
		to_chat(user, "<span class='warning'>We require at least [chemical_cost] unit\s of chemicals to do that!</span>")
		return FALSE
	if(c.absorbed_dna.len<req_dna)
		to_chat(user, "<span class='warning'>We require at least [req_dna] sample\s of compatible DNA.</span>")
		return FALSE
	if(req_stat < user.stat)
		to_chat(user, "<span class='warning'>We are incapacitated.</span>")
		return FALSE
	if((user.status_flags & FAKEDEATH) && name!="Regenerate")
		to_chat(user, "<span class='warning'>We are incapacitated.</span>")
		return FALSE
	if(c.geneticdamage > max_genetic_damage)
		to_chat(user, "<span class='warning'>Our genomes are still reassembling. We need time to recover first.</span>")
		return FALSE
	return TRUE

//used in /mob/Stat()
/obj/effect/proc_holder/changeling/proc/can_be_used_by(mob/user)
	if(req_human && !ishuman(user))
		return FALSE
	return TRUE
