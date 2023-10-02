/datum/species/cardassian
	name = "cardassian"
	id = "cardassian"
	default_color = "FFFFFF"
	exotic_blood = null
	species_traits = list(EYECOLOR,HAIR,FACEHAIR,LIPS)
	default_features = list("mcolor" = "FFF", "tail_human" = "None", "ears" = "None", "wings" = "None")
	use_skintones = 1
	skinned_type = /obj/item/stack/sheet/animalhide/human
	disliked_food = JUNKFOOD 
	liked_food = RAW //raw taspar is a delicacy
	attack_verb = "strike"
	armor = 1 //Cardassians recieve martial training
	hair_color = "110909" //They have black / dark brown hair.

/mob/living/carbon/human/species/cardassian
	race = /datum/species/cardassian

/datum/species/cardassian/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	if(C.client)
		if(C.client.prefs.real_name) //Random name if this isnt their chosen name
			C.real_name = C.client.prefs.real_name
			return
	var/new_name = random_name()
	C.real_name = new_name
	C.name = new_name


	to_chat(C, "<font size=4 color=red>You are playing a roleplay heavy race! As a Cardassian you are disciplined and martial. You despite weakness and see conspiracies in most things.</font>")
	var/datum/language_holder/H = C.get_language_holder()
	H.omnitongue = TRUE

/datum/species/cardassian/qualifies_for_rank(rank, list/features)
	return TRUE	

GLOBAL_LIST_INIT(cardassian_names, world.file2list("strings/names/cardassian.txt"))

/datum/species/cardassian/random_name()
	var/randname = random_unique_cardassian_name()
	return randname

/proc/random_unique_cardassian_name(attempts_to_find_unique_name=10)
	for(var/i in 1 to attempts_to_find_unique_name)
		. = capitalize(cardassian_name())
		if(!findname(.))
			break

/proc/cardassian_name()
	return "[pick(GLOB.cardassian_names)]"

