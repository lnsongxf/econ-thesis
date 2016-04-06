clear all
set more off
set matsize 11000

foreach x in adj unadj {
	import delimited using "data/raw/cpi/cpi-urban-nd_`x'.csv", clear
	
	generate newDate = date(date, "YMD")
	generate year    = year(newDate)
	generate month   = month(newDate)
	
	rename value cpi_`x'
	summarize cpi_`x' if year == 2009
	local 2009_index = r(mean)
	replace cpi_`x' = cpi_`x' / `2009_index'
	
	capture label variable cpi_adj CPI-U Nondurables (2009 = 1), Seasonally Adjsted"
	capture label variable cpi_unadj CPI-U Nondurables (2009 = 1), Not Seasonally Adjusted"
	
	keep year month cpi_`x'
	save "data/clean/cpi/cpi_`x'.dta", replace
}
