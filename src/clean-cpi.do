clear all
set more off
set matsize 11000

foreach x in adj unadj {
	import delimited using "data/raw/cpi/cpi-urban-nd_`x'.csv", clear
	
	rename value cpi_`x'
	capture label variable cpi_adj CPI-U Nondurables (1982-1984 = 100), Seasonally Adjsted"
	capture label variable cpi_unadj CPI-U Nondurables (1982-1984 = 100), Not Seasonally Adjusted"
	
	generate newDate = date(date, "YMD")
	generate year    = year(newDate)
	generate month   = month(newDate)
	keep year month cpi_`x'
	save "data/clean/cpi/cpi_`x'.dta", replace
}
