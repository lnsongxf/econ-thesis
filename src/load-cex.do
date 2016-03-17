clear all
set more off
set matsize 11000

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

// assert <= 4 observations per cuid
sort cuid bondholder
by cuid: assert _N <= 4

// replace bondholder = 1 if bondholder in last quarter
by cuid: replace bondholder = 1 if bondholder[_N] == 1
by cuid: egen sd_bondholder = sd(bondholder)
assert sd_bondholder == 0 | missing(sd_bondholder)
drop sd_bondholder


// TODO: summary stats comparing bondholders to non
keep if bondholder
assert hrs > 0

// TODO: use weights
// TODO: decide how collapse should deal with missing data
collapse (sum) exppq expcq inc bondholder (mean) hrs, by(year quarter_n)

// compute total quarter expenditures from current and previous quarter fields
reshape wide exppq expcq inc bondholder hrs, i(year) j(quarter_n)
sort year
generate exp1 = expcq1 + exppq2
generate exp2 = expcq2 + exppq3
generate exp3 = expcq3 + exppq4
generate exp4 = expcq4 + exppq1[_n+1]
drop exppq* expcq*
reshape long exp inc bondholder hrs, i(year) j(quarter_n)

// set time series
generate quarter = yq(year, quarter_n)
format quarter %tq
tsset quarter

// deflate income and consumption using nondurables implicit price deflator
merge 1:1 quarter using "data/clean/aggregate-series-all.dta", keepusing(inflation ffr cci deflator_nondurables) keep(master match) nogenerate
replace inc = inc / deflator_nondurables
replace exp = exp / deflator_nondurables

// per-capita variables
generate inc_pc = inc / bondholder
generate exp_pc = exp / bondholder
generate ymc_pc = inc_pc - exp_pc

// label variables
label variable hrs "Average hours worked per week"
label variable inc "Aggregate real income after taxes"
label variable exp "Aggregate real consumption"
label variable inc_pc "Per-capita real income after taxes"
label variable exp_pc "Per-capita real consumption"
label variable ymc_pc "Per-capita real income less consumption"

// generate VAR variables
egen mean_hrs                = mean(hrs)
generate scaled_labor_pct    = (1/3) * hrs / mean_hrs
generate scaled_leisure_pct  = 1 - scaled_labor_pct
generate log_consumption     = log(exp_pc)
generate log_rdi             = log(inc_pc)
generate log_nonconsumption  = log(ymc_pc)
local vars log_consumption inflation scaled_leisure_pct log_rdi log_nonconsumption ffr cci
