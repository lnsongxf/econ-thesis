clear all
set more off
set matsize 11000

// settings
local plots      = 0
local ljung_box  = 0
local varsoc     = 0
local reestimate = 1
local source     = "cex-nonbondholders"

local p = 4 // number of lags
local k = 7 // number of covariates
local kp = 28



// append everything
use "data/clean/cex/2013q1.dta"
forvalues q = 2/4 {
	append using "data/clean/cex/1996q`q'.dta"
}
forvalues year = 1997/2012 {
	forvalues q = 1/4 {
		append using "data/clean/cex/`year'q`q'.dta"
	}
}

// generate reference months and years
destring qintrvyr, replace
destring qintrvmo, replace

generate month1 = mod(qintrvmo - 3, 12)
generate month2 = mod(qintrvmo - 2, 12)
generate month3 = mod(qintrvmo - 1, 12)
forvalues i = 1/3 {
	replace month`i' = 12 if month`i' == 0
	
	generate year`i' = .
	replace year`i' = qintrvyr     if month`i' < qintrvmo
	replace year`i' = qintrvyr - 1 if month`i' > qintrvmo
}

// drop invalid data
drop if inc <= 0
drop if exppq < 0  | expcq <  0
drop if exppq <= 0 & expcq <= 0
drop if mod(qintrvmo, 3) == 1 & !(exppq > 0 & expcq == 0)

/*
// drop if family size changes between interviews
quietly: unique fam_size, by(cuid) gen(size_vals)
by cuid: replace size_vals = size_vals[1] if missing(size_vals)
drop if size_vals > 1
drop size_vals
*/

// generate month-level expenditures
forvalues i = 1/3 {
	generate exp`i' = .
	replace exp`i' = exppq / 3 if mod(qintrvmo, 3) == 1
}

replace exp1 = exppq / 2 if mod(qintrvmo, 3) == 2
replace exp2 = exppq / 2 if mod(qintrvmo, 3) == 2
replace exp3 = expcq     if mod(qintrvmo, 3) == 2

replace exp1 = exppq     if mod(qintrvmo, 3) == 0
replace exp2 = expcq / 2 if mod(qintrvmo, 3) == 0
replace exp3 = expcq / 2 if mod(qintrvmo, 3) == 0

drop exppq expcq

// replace bondholder = 1 if bondholder in last quarter
sort cuid bondholder
by cuid: replace bondholder = 1 if bondholder[_N] == 1

// reshape to household-month observations
reshape long year month exp, i(cuid qintrvyr qintrvmo)
drop _j qintrvyr qintrvmo

// take weighted averages of consumption, hours worked, income
//generate wt = finlwt21 * fam_size
rename finlwt21 wt
foreach var in exp hrs inc {
	generate wt_`var' = wt * `var'
}

if "`source'" == "cex-bondholders" {
	keep if bondholder
}
else {
	keep if !bondholder
}

// collapse to quarter-level
generate quarter = int((month - 1) / 3) + 1
collapse (sum) wt_exp wt_hrs wt_inc wt, by(year quarter)
drop if _n == _N // drop last quarter because inadequate expenditure data
generate exp = wt_exp / (wt / 3)
generate inc = wt_inc / wt
generate hrs = wt_hrs / wt

// set time series
generate period = yq(year, quarter)
format period %tq
tsset period

// deflate income and consumption using nondurables implicit price deflator
merge 1:1 period using "data/clean/aggregate-series-all.dta", keepusing(inflation ffr cci deflator_nondurables) keep(master match) nogenerate
replace inc = inc / deflator_nondurables
replace exp = exp / deflator_nondurables
generate ymc = inc - exp

// label variables
label variable hrs "Average hours worked per week"
label variable inc "Per-capita real income after taxes"
label variable exp "Per-capita real consumption"
label variable ymc "Per-capita real income less consumption"

foreach var of var * {
  drop if missing(`var')
}

// generate VAR variables
egen mean_hrs                = mean(hrs)
generate scaled_labor_pct    = (1/3) * hrs / mean_hrs
generate scaled_leisure_pct  = 1 - scaled_labor_pct
generate log_consumption     = log(exp)
generate log_rdi             = log(inc)
generate log_nonconsumption  = log(ymc)
local vars log_consumption inflation scaled_leisure_pct log_rdi log_nonconsumption ffr cci

// seasonally adjust log consumption
regress log_consumption i.quarter
matrix b = e(b)
rename log_consumption log_consumption_unadj
generate log_consumption = .
forvalues i = 1/4 {
	replace log_consumption = log_consumption_unadj - b[1, `i'] if quarter == `i'
}
if `plots' == 1 {
	twoway (tsline log_consumption_unadj) (tsline log_consumption)
	graph export "figs/series/`source'/log_consumption_adjustment.png", replace
}

// plots
if `plots' == 1 {
	foreach var in log_consumption inflation scaled_leisure_pct ffr {
		tsline `var'
		graph export "figs/series/`source'/`var'.png", replace
	}
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

	// generate month and day for saving
	generate month = (quarter - 1) * 3 + 1
	generate day = 1

	// export variables and lags to csv
	order year month day `vars' `lagvars'
	keep year month day `vars' `lagvars'
	export delimited "data/clean/`source'-series.csv", replace
}
