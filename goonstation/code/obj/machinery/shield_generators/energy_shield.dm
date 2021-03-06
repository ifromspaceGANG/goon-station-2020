/obj/machinery/shieldgenerator/energy_shield
	name = "Energy-Shield Generator"
	desc = "Solid matter can pass through the shields generated by this generator."
	icon = 'icons/obj/meteor_shield.dmi'
	icon_state = "energyShield"
	density = 0
	var/orientation = 1  //shield extend direction 0 = north/south, 1 = east/west
	power_level = 1 //1 for atmos shield, 2 for liquid, 3 for solid material
	var/const/MAX_POWER_LEVEL = 3
	var/const/MIN_POWER_LEVEL = 1
	min_range = 1
	max_range = 4
	direction = "dir"

	New()
		..()
		display_active.icon_state = "energyShieldOn"
		src.power_usage = 5

	examine()
		if(usr.client)
			var/charge_percentage = 0
			if (PCEL && PCEL.charge > 0 && PCEL.maxcharge > 0)
				charge_percentage = round((PCEL.charge/PCEL.maxcharge)*100)
				boutput(usr, "It has [PCEL.charge]/[PCEL.maxcharge] ([charge_percentage]%) battery power left.")
			else
				boutput(usr, "It seems to be missing a usable battery.")
			boutput(usr, "The unit will consume [30 * src.range * (src.power_level * src.power_level)] power a second.")
			boutput(usr, "The range setting is set to [src.range].")
			boutput(usr, "The power setting is set to [src.power_level].")

	shield_on()
		if (!PCEL)
			if (!powered()) //if NOT connected to power grid and there is power
				src.power_usage = 0
				return
			else //no power cell, not connected to grid: power down if active, do nothing otherwise
				src.power_usage = 30 * (src.range + 1) * (power_level * power_level)
				generate_shield()
				return
		else
			if (PCEL.charge > 0)
				generate_shield()
				return

	//Code for placing the shields and adding them to the generator's shield list
	proc/generate_shield()
		update_orientation()
		var/xa= -range-1
		var/ya= -range-1
		var/turf/T
		if (range == 0)
			var/obj/forcefield/energyshield/S = new /obj/forcefield/energyshield ( locate((src.x),(src.y),src.z), src , 1 )
			S.icon_state = "enshieldw"
			src.deployed_shields += S
		else
			for (var/i = 0-range, i <= range, i++)
				if (orientation)
					T = locate((src.x+i),(src.y),src.z)
					xa++
					ya = 0
				else
					T = locate((src.x),(src.y+i), src.z)
					ya++
					xa = 0

				if (T.canpass())
					createForcefieldObject(xa, ya);

		src.anchored = 1
		src.active = 1

		// update_nearby_tiles()
		playsound(src.loc, src.sound_on, 50, 1)
		if (src.power_level == 1)
			display_active.color = "#0000FA"
		else if (src.power_level == 2)
			display_active.color = "#00FF00"
		else
			display_active.color = "#FA0000"
		build_icon()

	//Changes shield orientation based on direction the generator is facing
	proc/update_orientation()
		if (src.dir == NORTH || src.dir == SOUTH)
			orientation = 0
		else
			orientation = 1

	//this is so long because I wanted the tiles to look like one seamless object. Otherwise it could just be a single line
	proc/createForcefieldObject(var/xa as num, var/ya as num)
		var/obj/forcefield/energyshield/S = new /obj/forcefield/energyshield (locate((src.x + xa),(src.y + ya),src.z), src, 1 ) //1 update tiles
		if (xa == -range)
			S.dir = SOUTHWEST
		else if (xa == range)
			S.dir = SOUTHEAST
		else if (ya == -range)
			S.dir = NORTHWEST
		else if (ya == range)
			S.dir = NORTHEAST
		else if (orientation)
			S.dir = NORTH
		else if (!orientation)
			S.dir = EAST

		src.deployed_shields += S

		return S

	//This is needed since the generator can be drawn beneath the forcefield so you can't easily left-click it
	//change to just call attack hand
	verb/toggle()
		set name = "Toggle"
		set category = "Local"
		set src in oview(1)
		if (!isliving(usr))
			boutput(usr, "<span style=\"color:red\">Your ghostly arms phase right through the [src.name] and you sadly contemplate the state of your existence.</span>")
			boutput(usr, "<span style=\"color:red\">That's what happens when you try to be a smartass, you dead sack of crap.</span>")
			return

		if (get_dist(usr,src) > 1)
			boutput(usr, "<span style=\"color:red\">You need to be closer to do that.</span>")
			return

		attack_hand(usr)
	verb/rotate()
		set name = "Rotate"
		set category = "Local"
		set src in oview(1)

		if (!isliving(usr))
			boutput(usr, "<span style=\"color:red\">Your ghostly arms phase right through the [src.name] and you sadly contemplate the state of your existence.</span>")
			boutput(usr, "<span style=\"color:red\">That's what happens when you try to be a smartass, you dead sack of crap.</span>")
			return

		if (get_dist(usr,src) > 1)
			boutput(usr, "<span style=\"color:red\">You need to be closer to do that.</span>")
			return

		if (src.active)
			boutput(usr, "<span style=\"color:red\">You can't turn [src] while it is active!</span>")
		else
			src.dir = turn(src.dir, 90)
			update_orientation()
			

			return
		boutput(usr, "<span style=\"color:blue\">Orientation set to : [orientation ? "Horizontal" : "Vertical"]</span>")

	verb/set_power_level()
		set name = "Set Power Level"
		set category = "Local"
		set src in view(1)

		if (!isliving(usr))
			boutput(usr, "<span style=\"color:red\">Your ghostly arms phase right through the [src.name] and you sadly contemplate the state of your existence.</span>")
			boutput(usr, "<span style=\"color:red\">That's what happens when you try to be a smartass, you dead sack of crap.</span>")
			return

		if (get_dist(usr,src) > 1)
			boutput(usr, "<span style=\"color:red\">You need to be closer to do that.</span>")
			return

		if (active)
			boutput(usr, "<span style=\"color:red\">You can't change the power level while the generator is active.</span>")
			return

		var/the_level = input("Enter a power level from [src.MIN_POWER_LEVEL]-[src.MAX_POWER_LEVEL]. Higher levels use more power.","[src.name]",1) as null|num
		if (!the_level)
			return
		if (get_dist(usr,src) > 1)
			boutput(usr, "<span style=\"color:red\">You flail your arms at [src] from across the room like a complete muppet. Move closer, genius!</span>")
			return
		the_level = max(MIN_POWER_LEVEL,min(the_level,MAX_POWER_LEVEL))
		src.power_level = the_level
		boutput(usr, "<span style=\"color:blue\">You set the power level to [src.power_level].</span>")

