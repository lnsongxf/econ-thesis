clear all
set more off

// read in CCI index
import delimited using "data/cci-index.txt", clear
generate time = qofd(date(date, "YMD")) + 1
tempfile cci_dta
save "`cci_dta'"

// get 2009 nondurables and services
foreach var in PCEND PCESV {
  import delimited using "data/`var'_2009.csv", clear
	local `var'_2009 = value[1] * 1e9
}

// read in series and save to tempfiles
local series DFF EMRATIO PRS85006023 PCEND PCESV DPIC96 GDPC96 DNDGRA3Q086SBEA DSERRA3Q086SBEA DTB3
foreach var in `series' {
	import delimited using "data/`var'.csv", clear
	tempfile `var'_dta
	save "``var'_dta'"
}

// merge tempfiles into single table
import delimited using "data/CNP16OV.csv", clear
rename value CNP16OV
foreach var in `series' {
  merge 1:1 date using "``var'_dta'"
	rename value `var'
	drop _merge
}

// replace date with quarter
generate time = qofd(date(date, "YMD"))
format time %tq
drop date
tsset time

// merge CCI index
merge 1:1 time using "`cci_dta'"
drop _merge

// rename raw series
rename CNP16OV         pop
rename DFF             effective_ffr
rename EMRATIO         emp_rate
rename PRS85006023     hours_worked
rename PCEND           nondurables
rename PCESV           services
rename DPIC96          real_disp_income
rename GDPC96          real_gdp
rename DNDGRA3Q086SBEA chain_nondurables
rename DSERRA3Q086SBEA chain_services
rename DTB3            observed_rate
rename lastprice       cci

// rescale variable units
replace pop = pop * 1000
foreach var in emp_rate chain_nondurables chain_services {
	replace `var' = `var'/100
}
foreach var in nondurables services real_disp_income real_gdp {
  replace `var' = `var' * 1e9
}

// consumption in chained 2009 dollars = nominal consumption * chain quantity index
generate real_nondurables    = chain_nondurables * `PCEND_2009'
generate real_services       = chain_services    * `PCESV_2009'
drop chain_nondurables chain_services

// generate variables
generate real_consumption_pc = (real_nondurables + real_services) / pop
generate real_disp_income_pc = real_disp_income / pop

sort time
generate deflator            = (nondurables + services) / (real_nondurables + real_services)
generate gross_inflation     = deflator[_n] / deflator[_n-1]

generate nonconsumption_pc   = (real_gdp - (real_nondurables + real_services)) / pop

generate hours_emp_rate      = hours_worked * emp_rate
foreach var of var * {
  drop if missing(`var')
}
egen mean_hours_emp_rate     = mean(hours_emp_rate)
generate scaled_labor_pct    = (1/3) * hours_emp_rate / mean_hours_emp_rate
generate scaled_leisure_pct  = 1 - scaled_labor_pct

generate real_observed_rate  = (((1 + observed_rate/100) / gross_inflation) - 1) * 100

// generate log variables
generate log_consumption     = log(real_consumption_pc)
generate log_rdi             = log(real_disp_income_pc)
generate log_nonconsumption  = log(nonconsumption_pc)
generate inflation           = log(gross_inflation) * 100

// drop extra variables
local vars log_consumption inflation scaled_leisure_pct log_rdi log_nonconsumption effective_ffr cci
keep  time real_consumption_pc `vars' observed_rate real_observed_rate
order time real_consumption_pc `vars' observed_rate real_observed_rate
label variable time                "Time period (quarter)"
label variable real_consumption_pc "Per-capital real consumption ($)"
label variable log_consumption     "Log of per-capita real consumption"
label variable inflation           "Inflation rate (% points)"
label variable scaled_leisure_pct  "Weekly leisure %, scaled to mean 2/3"
label variable log_rdi             "Log of real disposable income"
label variable log_nonconsumption  "Log of real output less consumption"
label variable effective_ffr       "Effective fed funds rate (% pts)"
label variable observed_rate       "90-day T-bill secondary market rate (% points)"
label variable real_observed_rate  "Real 90-day T-bill secondary market rate (% points)"
label variable cci                 "Continuous Commodity Index"

// plots
foreach var in real_consumption inflation scaled_leisure_pct real_observed_rate {
	tsline `var'
	graph export "figs/`var'.png", replace
}

// vector autoregression
// varsoc `vars'
var `vars', lag(4)
