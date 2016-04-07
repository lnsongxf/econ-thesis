clear all
set more off
set matsize 11000

// settings
local plots      = 1
local ljung_box  = 0
local varsoc     = 0
local reestimate = 1
local source     = "cex-nonbondholders"

local p = 4 // number of lags
local k = 7 // number of covariates
local kp = 28



// append everything
use "data/clean/cex/2013q1.dta"
forvalues year = 1996/2012 {
	forvalues q = 1/4 {
		capture append using "data/clean/cex/`year'q`q'.dta"
	}
}

// replace bondholder = 1 if bondholder in last quarter
sort cuid bondholder
by cuid: replace bondholder = 1 if bondholder[_N] == 1

// drop invalid data as in Heathcote et al (2010)
drop if respstat == "2"
drop respstat

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

// generate month-level expenditures
/*
drop if exppq < 0  | expcq <  0
drop if exppq <= 0 & expcq <= 0
drop if mod(qintrvmo, 3) == 1 & !(exppq > 0 & expcq == 0)
*/	
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

/*
// drop invalid data
drop if inc <= 0

// drop if family size changes between interviews
quietly: unique fam_size, by(cuid) gen(size_vals)
bysort cuid: replace size_vals = size_vals[1] if missing(size_vals)
drop if size_vals > 1
drop size_vals
*/

// reshape to household-month observations
reshape long year month exp, i(cuid qintrvyr qintrvmo)
drop _j qintrvyr qintrvmo

// summary stats
tabulate bondholder, missing
bysort cuid: generate unique_cuid = _n == 1
tabulate unique_cuid bondholder, missing
count if bondholder
local sample_size = r(N)

if "`source'" == "cex-bondholders" {
	keep if bondholder
	
	summarize exp
	summarize fincatax
	summarize hrs
}
else if "`source'" == "cex-nonbondholders" {
	keep if !bondholder
	set seed 0
	sample `sample_size', count
	
	tabulate unique_cuid
	summarize exp
	summarize fincatax
	summarize hrs
}
else {
	display as error "Source was not CEX bondholders or nonbondholders"
	error 7
}

// collapse to month-level
replace weight = round(weight)
collapse (mean) hrs fincbtax fincatax fam_size exp [fw=weight], by(year month)

// deflate using CPI-U
merge 1:1 year month using "data/clean/cpi/cpi_unadj.dta", keep(master match) nogenerate
foreach var in exp fincbtax fincatax {
	rename `var' `var'_n
	generate `var' = `var'_n / cpi_unadj
}
	
// generate per-capita real expenditures
generate exp_pc = exp / fam_size

// collapse to quarterly
generate quarter = int((month - 1) / 3) + 1
collapse (sum) exp_pc (mean) fincbtax fincatax hrs, by(year quarter)
drop if _n == _N // drop last quarter because inadequate expenditure data
generate period = yq(year, quarter)
format period %tq
tsset period

// generate rdi, ymc
rename fincatax rdi
generate ymc = fincbtax - exp_pc

// label variables
label variable hrs "Average hours worked per week"
label variable rdi "Per-capita real disposable income"
label variable exp_pc "Per-capita real consumption"
label variable ymc "Per-capita real output less consumption"

// generate VAR variables
egen mean_hrs                = mean(hrs)
generate scaled_labor_pct    = (1/3) * hrs / mean_hrs
generate scaled_leisure_pct  = 1 - scaled_labor_pct
generate log_consumption     = log(exp_pc)
generate log_rdi             = log(rdi)
generate log_nonconsumption  = log(ymc)
local vars log_consumption inflation scaled_leisure_pct log_rdi log_nonconsumption ffr cci

// merge aggregate VAR variables
merge 1:1 period using "data/clean/nipa-series-all.dta", keepusing(inflation ffr cci) keep(master match) nogenerate

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
