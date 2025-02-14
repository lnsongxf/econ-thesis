clear all
set more off
set matsize 11000

// settings
local plots      = 1
local ljung_box  = 0
local varsoc     = 0
local reestimate = 1
local source     = "`1'"

local p = 4 // number of lags
local k = 7 // number of covariates
local kp = 28

// read in CCI index
import delimited using "data/raw/cci-index.txt", clear
generate period = qofd(date(date, "YMD")) + 1
tempfile cci_dta
save "`cci_dta'"

// get 2009 nondurables and services
foreach var in PCEND PCESV {
  import delimited using "data/raw/nipa/`var'_2009.csv", clear
	local `var'_2009 = value[1] * 1e9
}

// read in series and save to tempfiles
local series DFF EMRATIO PRS85006023 PCEND PCESV DPIC96 GDPC96 DNDGRA3Q086SBEA DSERRA3Q086SBEA DTB3
foreach var in `series' {
	import delimited using "data/raw/nipa/`var'.csv", clear
	tempfile `var'_dta
	save "``var'_dta'"
}

// merge tempfiles into single table
import delimited using "data/raw/nipa/CNP16OV.csv", clear
rename value CNP16OV
foreach var in `series' {
  merge 1:1 date using "``var'_dta'"
	rename value `var'
	drop _merge
}

// replace date with quarter
generate newDate = date(date, "YMD")
generate year    = year(newDate)
generate month   = month(newDate)
generate day     = day(newDate)
generate period  = qofd(newDate)
drop newDate
format period %tq
tsset period

// merge CCI index
merge 1:1 period using "`cci_dta'"
drop _merge

// rename raw series
rename CNP16OV         pop
rename DFF             ffr
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
replace ffr                  = log((1 + ffr/100)^0.25)
replace observed_rate        = log(1 + observed_rate/100)
replace cci                  = log(cci)

// consumption in chained 2009 dollars = nominal consumption * chain quantity index
generate real_nondurables    = chain_nondurables * `PCEND_2009'
generate real_services       = chain_services    * `PCESV_2009'
drop chain_nondurables chain_services

// generate variables
generate real_consumption_pc = (real_nondurables + real_services) / pop
generate real_disp_income_pc = real_disp_income / pop

sort period
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

// generate log variables
generate log_consumption     = log(real_consumption_pc)
generate log_rdi             = log(real_disp_income_pc)
generate log_nonconsumption  = log(nonconsumption_pc)
generate inflation           = log(gross_inflation)

// drop extra variables
local timevars year month day period
local vars log_consumption inflation scaled_leisure_pct log_rdi log_nonconsumption ffr cci
keep  `timevars' real_consumption_pc `vars' observed_rate
order `timevars' real_consumption_pc `vars' observed_rate
label variable year                "Year"
label variable month               "Month"
label variable day                 "Day"
label variable period              "Quarter"
label variable real_consumption_pc "Per-capita real consumption ($)"
label variable log_consumption     "Log of per-capita real consumption"
label variable inflation           "Inflation rate (net, quarterly)"
label variable scaled_leisure_pct  "Weekly leisure %, scaled to mean 2/3"
label variable log_rdi             "Log of real disposable income"
label variable log_nonconsumption  "Log of real output less consumption"
label variable ffr					       "Effective fed funds rate (net, quarterly)"
label variable observed_rate       "90-day T-bill secondary market rate (net)"
label variable cci                 "Log of Continuous Commodity Index"

if "`source'" == "nipa-collard" {
	keep if period <= 187
}
else if "`source'" == "nipa-canzoneri" {
	keep if period >= 21 & period <= 176
}
else if "`source'" != "nipa" {
	display as error "Source was not NIPA or NIPA Collard sample"
	error 7
}

save "data/clean/`source'-series-all.dta", replace

// plots
if `plots' == 1 {
	foreach var in log_consumption inflation scaled_leisure_pct ffr {
		tsline `var'
		graph export "figs/series/`source'/`var'.png", replace
	}
}

// multivariate Ljung-Box statistic
if `ljung_box' == 1 {
	wntstmvq `vars'
}

// lag-order selection statistics
if `varsoc' == 1 {
	varsoc `vars'
}

// estimate VAR
if `reestimate' == 1 {
	local lagvars
	local pm1 = `p' - 1
	forvalues i = 1/`pm1' {
		foreach var in `vars' {
			generate `var'_`i' = `var'[_n-`i']
			local lagvars = "`lagvars' `var'_`i'"
		}
	}

	var `vars' `lagvars', lags(1)
	matrix b = e(b)
	matrix input A0 = () // constant coefficients
	forvalues i = 1/`kp' {
		matrix A0 = A0 \ b[1, 29*`i']
	}
	varstable, amat(A1) // companion matrix
	matrix Sigma = e(Sigma) // covariance of error term

	mat2txt2 A0 using "results/var-ests/`source'/A0.csv", comma clean replace
	mat2txt2 A1 using "results/var-ests/`source'/A1.csv", comma clean replace
	mat2txt2 Sigma using "results/var-ests/`source'/Sigma.csv", comma clean replace

	// export variables and lags to csv
	keep year month day `vars' `lagvars'
	export delimited "data/clean/`source'-series.csv", replace
}
