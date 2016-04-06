clear all
set more off
set matsize 11000

forvalues year = 1996/2013 {
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
	
	forvalues q = 1/4 {
		// load data
		capture use "data/raw/cex/fmli`y'`q'.dta", replace
		if !_rc {
			
			// generate/rename nonstandard variables if necessary
			capture confirm numeric variable cuid
			if _rc {
				generate cuid = int(newid / 10)
			}
			
			capture confirm numeric variable interi
			if _rc {
				generate interi = real(substr(string(newid), -1, .))
			}
			
			capture confirm numeric variable fincbtax
			if _rc {
				rename fincbtxm fincbtax
			}
			
			capture confirm numeric variable fincatax
			if _rc {
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
		
			rename inc_hrs1 hrs
			rename finlwt21 weight

			foreach t in pq cq {		
				generate foodbev`t' = food`t' + alcbev`t'
				generate medcare`t' = health`t' - hlthin`t'
				generate exp`t'     = foodbev`t' + tobacc`t' + appar`t' + persca`t'	+ gasmo`t' + pubtra`t' + housop`t' + medcare`t' + entert`t' + read`t' + educa`t'
			}
			
			// save clean data
			keep cuid bondholder qintrvyr qintrvmo respstat fincbtax fincatax hrs weight fam_size interi exppq expcq
			save "data/clean/cex/`year'q`q'.dta", replace
		}
	}
}
