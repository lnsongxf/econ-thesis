clear all
set more off
set matsize 11000

// expenditure variables
local expvars totexppq totexpcq houspq houscq healthpq healthcq educapq educacq



/*** FIRST QUARTER */
forvalues year = 1997/2013 {

	// get filename
	if `year' >= 2000 {
		local yr = `year' - 2000
	}
	else {
		local yr = `year' - 1900
	}
	if `yr' >= 10 {
		local y "`yr'"
	}
	else {
		local y "0`yr'"
	}
	
	// load data
	use "data/raw/cex/fmli`y'1.dta", replace
	if `year' <= 2002 {
		generate cuid = int(newid/10)
	}
	if `year' > 2004 & `year' <= 2006 {
		rename fincatxm fincatax
	}
	
	// bondholder criteria as in Vissing-Jorgensen (2002)
	generate bondholder = 0
	replace bondholder = 1 if !missing(usbndx) & compbnd == "1" & usbndx > 0
	replace bondholder = 1 if compbnd == "3"
	replace bondholder = 1 if missing(usbndx) & compbnd == "2" & compbndx < usbndx
	replace bondholder = 1 if !missing(secestx) & compsec == "1" & secestx > 0
	replace bondholder = 1 if compsec == "3"
	replace bondholder = 1 if missing(secestx) & compsec == "2" & compsecx < secestx
	
	// consumption = nondurables + services as in V-J (2002)
	rename fincatax inc
	rename inc_hrs1 hrs
	generate exppq = totexppq - houspq - healthpq - educapq
	generate expcq = totexpcq - houscq - healthcq - educacq
	
	// save clean data
	keep cuid bondholder qintrvyr qintrvmo respstat inc hrs exppq expcq finlwt21 fam_size
	save "data/clean/cex/`year'q1.dta", replace
}



/*** PREVIOUS YEARS */
forvalues year = 1996/2012 {
	// get filename
	if `year' >= 2000 {
		local yr = `year' - 2000
	}
	else {
		local yr = `year' - 1900
	}
	if `yr' >= 10 {
		local y "`yr'"
	}
	else {
		local y "0`yr'"
	}
	
	forvalues q = 2/4 {
		// load data
		use "data/raw/cex/fmli`y'`q'.dta", replace
		if `year' <= 2001 {
			generate cuid = int(newid/10)
		}
		if `year' > 2003 & `year' <= 2005 {
			rename fincatxm fincatax
		}
		
		// bondholder criteria as in Vissing-Jorgensen (2002)
		generate bondholder = 0
		replace bondholder = 1 if !missing(usbndx) & compbnd == "1" & usbndx > 0
		replace bondholder = 1 if compbnd == "3"
		replace bondholder = 1 if missing(usbndx) & compbnd == "2" & compbndx < usbndx
		replace bondholder = 1 if !missing(secestx) & compsec == "1" & secestx > 0
		replace bondholder = 1 if compsec == "3"
		replace bondholder = 1 if missing(secestx) & compsec == "2" & compsecx < secestx
	
		// consumption = nondurables + services as in V-J (2002)
		rename fincatax inc
		rename inc_hrs1 hrs
		generate exppq = totexppq - houspq - healthpq - educapq
		generate expcq = totexpcq - houscq - healthcq - educacq
		
		// save clean data
		keep cuid bondholder qintrvyr qintrvmo respstat inc hrs exppq expcq finlwt21 fam_size
		save "data/clean/cex/`year'q`q'.dta", replace
	}
}
