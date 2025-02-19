/obj/item/tricorder
	name = "Tricorder"
	icon = 'DS13/icons/misc/star_trek.dmi'
	icon_state = "tricorder"
	item_state = "tricorder"
	var/on = FALSE
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	desc = "A hand-held scanner able to perform many functions."
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	materials = list(MAT_METAL=200)
	var/mode = 1
	var/scanmode = 0
	var/advanced = FALSE

/obj/item/tricorder/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins to analyze [user.p_them()]self with [src]! The display shows that [user.p_theyre()] dead!</span>")
	return BRUTELOSS

/obj/item/tricorder/attack_self(mob/user)
    scanmode = (scanmode + 1) % 4
    if(scanmode == 0)
        to_chat(user, "<span class='notice'>You switch the tricorder to check physical health.</span>")
    else if(scanmode == 1)
        to_chat(user, "<span class='notice'>You switch the tricorder to scan chemical contents.</span>")
    else if(scanmode == 2)
        to_chat(user, "<span class='notice'>You switch the tricorder to scan the local atmosphere.</span>")

/obj/item/tricorder/attack(mob/living/M, mob/living/carbon/human/user)

	// Clumsiness/brain damage check
	if ((user.has_trait(TRAIT_CLUMSY) || user.has_trait(TRAIT_DUMB)) && prob(50))
		to_chat(user, "<span class='notice'>You stupidly try to analyze the floor!</span>")
		user.visible_message("<span class='warning'>[user] has analyzed the floor!</span>")
		to_chat(user, "<span class='info'>Analyzing results for The floor:\n\tOverall status: <b>Healthy</b>")
		to_chat(user, "<span class='info'>Key: <span class='notice'>Suffocation</span>/<font color='green'>Toxin</font>/<font color='#FF8000'>Burn</font>/<font color='red'>Brute</font></span>")
		to_chat(user, "<span class='info'>\tDamage specifics: <span class='notice'>0</span>-<font color='green'>0</font>-<font color='#FF8000'>0</font>-<font color='red'>0</font></span>")
		to_chat(user, "<span class='info'>Body temperature: ???</span>")
		return

	user.visible_message("<span class='notice'>[user] has run a tricorder scan. </span>")

	if(scanmode == 0)
		healthscan2(user, M, mode, advanced)
	else if(scanmode == 1)
		chemscan2(user, M)
	else if(scanmode == 2)
		atmoscan(user, M)


	add_fingerprint(user)


// Used by the PDA medical scanner too
/proc/healthscan2(mob/user, mob/living/M, mode = 1, advanced = FALSE)
	if(isliving(user) && (user.incapacitated() || user.eye_blind))
		return
	//Damage specifics
	var/oxy_loss = M.getOxyLoss()
	var/tox_loss = M.getToxLoss()
	var/fire_loss = M.getFireLoss()
	var/brute_loss = M.getBruteLoss()
	var/mob_status = (M.stat == DEAD ? "<span class='alert'><b>Deceased</b></span>" : "<b>[round(M.health/M.maxHealth,0.01)*100] % healthy</b>")

	if(M.has_trait(TRAIT_FAKEDEATH) && !advanced)
		mob_status = "<span class='alert'><b>Deceased</b></span>"
		oxy_loss = max(rand(1, 40), oxy_loss, (300 - (tox_loss + fire_loss + brute_loss))) // Random oxygen loss

	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.undergoing_cardiac_arrest() && H.stat != DEAD)
			to_chat(user, "<span class='danger'>Subject suffering from heart attack: Apply defibrillation or other electric shock immediately!</span>")
		if(H.undergoing_liver_failure() && H.stat != DEAD)
			to_chat(user, "<span class='danger'>Subject is suffering from liver failure: Apply Corazone and begin a liver transplant immediately!</span>")

	to_chat(user, "<span class='info'>Analyzing results for [M]:\n\tOverall status: [mob_status]</span>")

	// Damage descriptions
	if(brute_loss > 10)
		to_chat(user, "\t<span class='alert'>[brute_loss > 50 ? "Severe" : "Minor"] tissue damage detected.</span>")
	if(fire_loss > 10)
		to_chat(user, "\t<span class='alert'>[fire_loss > 50 ? "Severe" : "Minor"] burn damage detected.</span>")
	if(oxy_loss > 10)
		to_chat(user, "\t<span class='info'><span class='alert'>[oxy_loss > 50 ? "Severe" : "Minor"] oxygen deprivation detected.</span>")
	if(tox_loss > 10)
		to_chat(user, "\t<span class='alert'>[tox_loss > 50 ? "Severe" : "Minor"] amount of toxin damage detected.</span>")
	if(M.getStaminaLoss())
		to_chat(user, "\t<span class='alert'>Subject appears to be suffering from fatigue.</span>")
		if(advanced)
			to_chat(user, "\t<span class='info'>Fatigue Level: [M.getStaminaLoss()]%.</span>")
	if (M.getCloneLoss())
		to_chat(user, "\t<span class='alert'>Subject appears to have [M.getCloneLoss() > 30 ? "Severe" : "Minor"] cellular damage.</span>")
		if(advanced)
			to_chat(user, "\t<span class='info'>Cellular Damage Level: [M.getCloneLoss()].</span>")
	if (M.getBrainLoss() >= 200 || !M.getorgan(/obj/item/organ/brain))
		to_chat(user, "\t<span class='alert'>Subject's brain function is non-existent.</span>")
	else if (M.getBrainLoss() >= 120)
		to_chat(user, "\t<span class='alert'>Severe brain damage detected. Subject likely to have mental traumas.</span>")
	else if (M.getBrainLoss() >= 45)
		to_chat(user, "\t<span class='alert'>Brain damage detected.</span>")
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		if(LAZYLEN(C.get_traumas()))
			var/list/trauma_text = list()
			for(var/datum/brain_trauma/B in C.get_traumas())
				var/trauma_desc = ""
				switch(B.resilience)
					if(TRAUMA_RESILIENCE_SURGERY)
						trauma_desc += "severe "
					if(TRAUMA_RESILIENCE_LOBOTOMY)
						trauma_desc += "deep-rooted "
					if(TRAUMA_RESILIENCE_MAGIC, TRAUMA_RESILIENCE_ABSOLUTE)
						trauma_desc += "permanent "
				trauma_desc += B.scan_desc
				trauma_text += trauma_desc
			to_chat(user, "\t<span class='alert'>Cerebral traumas detected: subject appears to be suffering from [english_list(trauma_text)].</span>")
		if(C.roundstart_quirks.len)
			to_chat(user, "\t<span class='info'>Subject has the following physiological traits: [C.get_trait_string()].</span>")
	if(advanced)
		to_chat(user, "\t<span class='info'>Brain Activity Level: [(200 - M.getBrainLoss())/2]%.</span>")
	if (M.radiation)
		to_chat(user, "\t<span class='alert'>Subject is irradiated.</span>")
		if(advanced)
			to_chat(user, "\t<span class='info'>Radiation Level: [M.radiation]%.</span>")

	if(advanced && M.hallucinating())
		to_chat(user, "\t<span class='info'>Subject is hallucinating.</span>")

	//Eyes and ears
	if(advanced)
		if(iscarbon(M))
			var/mob/living/carbon/C = M
			var/obj/item/organ/ears/ears = C.getorganslot(ORGAN_SLOT_EARS)
			to_chat(user, "\t<span class='info'><b>==EAR STATUS==</b></span>")
			if(istype(ears))
				var/healthy = TRUE
				if(C.has_trait(TRAIT_DEAF, GENETIC_MUTATION))
					healthy = FALSE
					to_chat(user, "\t<span class='alert'>Subject is genetically deaf.</span>")
				else if(C.has_trait(TRAIT_DEAF))
					healthy = FALSE
					to_chat(user, "\t<span class='alert'>Subject is deaf.</span>")
				else
					if(ears.ear_damage)
						to_chat(user, "\t<span class='alert'>Subject has [ears.ear_damage > UNHEALING_EAR_DAMAGE? "permanent ": "temporary "]hearing damage.</span>")
						healthy = FALSE
					if(ears.deaf)
						to_chat(user, "\t<span class='alert'>Subject is [ears.ear_damage > UNHEALING_EAR_DAMAGE ? "permanently ": "temporarily "] deaf.</span>")
						healthy = FALSE
				if(healthy)
					to_chat(user, "\t<span class='info'>Healthy.</span>")
			else
				to_chat(user, "\t<span class='alert'>Subject does not have ears.</span>")
			var/obj/item/organ/eyes/eyes = C.getorganslot(ORGAN_SLOT_EYES)
			to_chat(user, "\t<span class='info'><b>==EYE STATUS==</b></span>")
			if(istype(eyes))
				var/healthy = TRUE
				if(C.has_trait(TRAIT_BLIND))
					to_chat(user, "\t<span class='alert'>Subject is blind.</span>")
					healthy = FALSE
				if(C.has_trait(TRAIT_NEARSIGHT))
					to_chat(user, "\t<span class='alert'>Subject is nearsighted.</span>")
					healthy = FALSE
				if(eyes.eye_damage > 30)
					to_chat(user, "\t<span class='alert'>Subject has severe eye damage.</span>")
					healthy = FALSE
				else if(eyes.eye_damage > 20)
					to_chat(user, "\t<span class='alert'>Subject has significant eye damage.</span>")
					healthy = FALSE
				else if(eyes.eye_damage)
					to_chat(user, "\t<span class='alert'>Subject has minor eye damage.</span>")
					healthy = FALSE
				if(healthy)
					to_chat(user, "\t<span class='info'>Healthy.</span>")
			else
				to_chat(user, "\t<span class='alert'>Subject does not have eyes.</span>")


	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/ldamage = H.return_liver_damage()
		if(ldamage > 10)
			to_chat(user, "\t<span class='alert'>[ldamage > 45 ? "Severe" : "Minor"] liver damage detected.</span>")

	// Body part damage report
	if(iscarbon(M) && mode == 1)
		var/mob/living/carbon/C = M
		var/list/damaged = C.get_damaged_bodyparts(1,1)
		if(length(damaged)>0 || oxy_loss>0 || tox_loss>0 || fire_loss>0)
			to_chat(user, "<span class='info'>\tDamage: <span class='info'><font color='red'>Brute</font></span>-<font color='#FF8000'>Burn</font>-<font color='green'>Toxin</font>-<span class='notice'>Suffocation</span>\n\t\tSpecifics: <font color='red'>[brute_loss]</font>-<font color='#FF8000'>[fire_loss]</font>-<font color='green'>[tox_loss]</font>-<FONT color='#3d5bc3'>[oxy_loss]</font></span>")
			for(var/obj/item/bodypart/org in damaged)
				to_chat(user, "\t\t<span class='info'>[capitalize(org.name)]: [(org.brute_dam > 0) ? "<font color='red'>[org.brute_dam]</font></span>" : "<font color='red'>0</font>"]-[(org.burn_dam > 0) ? "<font color='#FF8000'>[org.burn_dam]</font>" : "<font color='#FF8000'>0</font>"]")

	// Species and body temperature
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/datum/species/S = H.dna.species
		var/mutant = FALSE
		if (H.dna.check_mutation(HULK))
			mutant = TRUE
		else if (S.mutantlungs != initial(S.mutantlungs))
			mutant = TRUE
		else if (S.mutant_brain != initial(S.mutant_brain))
			mutant = TRUE
		else if (S.mutant_heart != initial(S.mutant_heart))
			mutant = TRUE
		else if (S.mutanteyes != initial(S.mutanteyes))
			mutant = TRUE
		else if (S.mutantears != initial(S.mutantears))
			mutant = TRUE
		else if (S.mutanthands != initial(S.mutanthands))
			mutant = TRUE
		else if (S.mutanttongue != initial(S.mutanttongue))
			mutant = TRUE
		else if (S.mutanttail != initial(S.mutanttail))
			mutant = TRUE
		else if (S.mutantliver != initial(S.mutantliver))
			mutant = TRUE
		else if (S.mutantstomach != initial(S.mutantstomach))
			mutant = TRUE

		to_chat(user, "<span class='info'>Species: [S.name][mutant ? "-derived mutant" : ""]</span>")
	to_chat(user, "<span class='info'>Body temperature: [round(M.bodytemperature-T0C,0.1)] &deg;C ([round(M.bodytemperature*1.8-459.67,0.1)] &deg;F)</span>")

	// Time of death
	if(M.tod && (M.stat == DEAD || ((M.has_trait(TRAIT_FAKEDEATH)) && !advanced)))
		to_chat(user, "<span class='info'>Time of Death:</span> [M.tod]")
		var/tdelta = round(world.time - M.timeofdeath)
		if(tdelta < (DEFIB_TIME_LIMIT * 10))
			to_chat(user, "<span class='danger'>Subject died [DisplayTimeText(tdelta)] ago, defibrillation may be possible!</span>")

	for(var/thing in M.diseases)
		var/datum/disease/D = thing
		if(!(D.visibility_flags & HIDDEN_SCANNER))
			to_chat(user, "<span class='alert'><b>Warning: [D.form] detected</b>\nName: [D.name].\nType: [D.spread_text].\nStage: [D.stage]/[D.max_stages].\nPossible Cure: [D.cure_text]</span>")

	// Blood Level
	if(M.has_dna())
		var/mob/living/carbon/C = M
		var/blood_id = C.get_blood_id()
		if(blood_id)
			if(ishuman(C))
				var/mob/living/carbon/human/H = C
				if(H.bleed_rate)
					to_chat(user, "<span class='danger'>Subject is bleeding!</span>")
			var/blood_percent =  round((C.blood_volume / BLOOD_VOLUME_NORMAL)*100)
			var/blood_type = C.dna.blood_type
			if(blood_id != "blood")//special blood substance
				var/datum/reagent/R = GLOB.chemical_reagents_list[blood_id]
				if(R)
					blood_type = R.name
				else
					blood_type = blood_id
			if(C.blood_volume <= BLOOD_VOLUME_SAFE && C.blood_volume > BLOOD_VOLUME_OKAY)
				to_chat(user, "<span class='danger'>LOW blood level [blood_percent] %, [C.blood_volume] cl,</span> <span class='info'>type: [blood_type]</span>")
			else if(C.blood_volume <= BLOOD_VOLUME_OKAY)
				to_chat(user, "<span class='danger'>CRITICAL blood level [blood_percent] %, [C.blood_volume] cl,</span> <span class='info'>type: [blood_type]</span>")
			else
				to_chat(user, "<span class='info'>Blood level [blood_percent] %, [C.blood_volume] cl, type: [blood_type]</span>")

		var/cyberimp_detect
		for(var/obj/item/organ/cyberimp/CI in C.internal_organs)
			if(CI.status == ORGAN_ROBOTIC && !CI.syndicate_implant)
				cyberimp_detect += "[C.name] is modified with a [CI.name].<br>"
		if(cyberimp_detect)
			to_chat(user, "<span class='notice'>Detected cybernetic modifications:</span>")
			to_chat(user, "<span class='notice'>[cyberimp_detect]</span>")
	SEND_SIGNAL(M, COMSIG_NANITE_SCAN, user, FALSE)

/proc/chemscan2(mob/living/user, mob/living/M)
	if(istype(M))
		if(M.reagents)
			if(M.reagents.reagent_list.len)
				to_chat(user, "<span class='notice'>Subject contains the following reagents:</span>")
				for(var/datum/reagent/R in M.reagents.reagent_list)
					to_chat(user, "<span class='notice'>[R.volume] units of [R.name][R.overdosed == 1 ? "</span> - <span class='boldannounce'>OVERDOSING</span>" : ".</span>"]")
			else
				to_chat(user, "<span class='notice'>Subject contains no reagents.</span>")
			if(M.reagents.addiction_list.len)
				to_chat(user, "<span class='boldannounce'>Subject is addicted to the following reagents:</span>")
				for(var/datum/reagent/R in M.reagents.addiction_list)
					to_chat(user, "<span class='danger'>[R.name]</span>")
			else
				to_chat(user, "<span class='notice'>Subject is not addicted to any reagents.</span>")

/obj/item/tricorder/verb/toggle_mode()
	set name = "Switch Verbosity"
	set category = "Object"

	if(usr.incapacitated())
		return

	mode = !mode
	switch (mode)
		if(1)
			to_chat(usr, "The scanner now shows specific limb damage.")
		if(0)
			to_chat(usr, "The scanner no longer shows limb damage.")

/proc/atmoscan(mob/living/user, mob/living/M)
	if (user.stat || user.eye_blind)
		return

	if (user.stat || user.eye_blind)
		return

	var/turf/location = user.loc
	if(!istype(location))
		return

	var/datum/gas_mixture/environment = location.return_air()

	var/pressure = environment.return_pressure()
	var/total_moles = environment.total_moles()

	to_chat(user, "<span class='info'><B>Results:</B></span>")
	if(abs(pressure - ONE_ATMOSPHERE) < 10)
		to_chat(user, "<span class='info'>Pressure: [round(pressure, 0.01)] kPa</span>")
	else
		to_chat(user, "<span class='alert'>Pressure: [round(pressure, 0.01)] kPa</span>")
	if(total_moles)
		var/list/env_gases = environment.gases

		environment.assert_gases(arglist(GLOB.hardcoded_gases))
		var/o2_concentration = env_gases[/datum/gas/oxygen][MOLES]/total_moles
		var/n2_concentration = env_gases[/datum/gas/nitrogen][MOLES]/total_moles
		var/co2_concentration = env_gases[/datum/gas/carbon_dioxide][MOLES]/total_moles
		var/plasma_concentration = env_gases[/datum/gas/plasma][MOLES]/total_moles

		if(abs(n2_concentration - N2STANDARD) < 20)
			to_chat(user, "<span class='info'>Nitrogen: [round(n2_concentration*100, 0.01)] % ([round(env_gases[/datum/gas/nitrogen][MOLES], 0.01)] mol)</span>")
		else
			to_chat(user, "<span class='alert'>Nitrogen: [round(n2_concentration*100, 0.01)] % ([round(env_gases[/datum/gas/nitrogen][MOLES], 0.01)] mol)</span>")

		if(abs(o2_concentration - O2STANDARD) < 2)
			to_chat(user, "<span class='info'>Oxygen: [round(o2_concentration*100, 0.01)] % ([round(env_gases[/datum/gas/oxygen][MOLES], 0.01)] mol)</span>")
		else
			to_chat(user, "<span class='alert'>Oxygen: [round(o2_concentration*100, 0.01)] % ([round(env_gases[/datum/gas/oxygen][MOLES], 0.01)] mol)</span>")

		if(co2_concentration > 0.01)
			to_chat(user, "<span class='alert'>CO2: [round(co2_concentration*100, 0.01)] % ([round(env_gases[/datum/gas/carbon_dioxide][MOLES], 0.01)] mol)</span>")
		else
			to_chat(user, "<span class='info'>CO2: [round(co2_concentration*100, 0.01)] % ([round(env_gases[/datum/gas/carbon_dioxide][MOLES], 0.01)] mol)</span>")

		if(plasma_concentration > 0.005)
			to_chat(user, "<span class='alert'>Plasma: [round(plasma_concentration*100, 0.01)] % ([round(env_gases[/datum/gas/plasma][MOLES], 0.01)] mol)</span>")
		else
			to_chat(user, "<span class='info'>Plasma: [round(plasma_concentration*100, 0.01)] % ([round(env_gases[/datum/gas/plasma][MOLES], 0.01)] mol)</span>")

		environment.garbage_collect()

		for(var/id in env_gases)
			if(id in GLOB.hardcoded_gases)
				continue
			var/gas_concentration = env_gases[id][MOLES]/total_moles
			to_chat(user, "<span class='alert'>[env_gases[id][GAS_META][META_GAS_NAME]]: [round(gas_concentration*100, 0.01)] % ([round(env_gases[id][MOLES], 0.01)] mol)</span>")
		to_chat(user, "<span class='info'>Temperature: [round(environment.temperature-T0C, 0.01)] &deg;C ([round(environment.temperature, 0.01)] K)</span>")

/obj/item/tricorder/AltClick(mob/user)
	toggle_on()

/obj/item/tricorder/proc/toggle_on()
	on = !on
	if(on)
		START_PROCESSING(SSobj, src)
	else
		STOP_PROCESSING(SSobj, src)



/obj/item/tricorder/cyborg_unequip(mob/user)
	if(!on)
		return
	toggle_on()

/obj/item/tricorder/process()
	if(!on)
		STOP_PROCESSING(SSobj, src)
		return null
	scan()

/obj/item/tricorder/proc/scan()
	t_ray_scan(loc)

/proc/trayscan(mob/viewer, flick_time = 8, distance = 3)
	if(!ismob(viewer) || !viewer.client)
		return
	var/list/t_ray_images = list()
	for(var/obj/O in orange(distance, viewer) )
		if(O.level != 1)
			continue

		if(O.invisibility == INVISIBILITY_MAXIMUM)
			var/image/I = new(loc = get_turf(O))
			var/mutable_appearance/MA = new(O)
			MA.alpha = 128
			MA.dir = O.dir
			I.appearance = MA
			t_ray_images += I
	if(t_ray_images.len)
		flick_overlay(t_ray_images, list(viewer.client), flick_time)

