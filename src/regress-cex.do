clear all
set more off
set matsize 11000

// read in data
import delimited using "data/clean/cex-nonbondholders-rates.csv", clear
generate bondholder = 0
tempfile nbh
save "`nbh'"

import delimited using "data/clean/cex-bondholders-rates.csv", clear
generate bondholder = 1
append using "`nbh'"

rename v1 ffr
rename v2 ffr_real
rename v3 implied
rename v4 implied_real

// generate spread and lags
generate spread = implied - ffr
generate spread_real = implied_real - ffr_real
forvalues i = 1/4 {
	bysort bondholder: generate spread_`i' = spread[_n - `i']
	bysort bondholder: generate spread_real_`i' = spread_real[_n - `i']
}

// correlations
correlate implied ffr if bondholder
local corr_bh = r(rho)
local fisher_r_bh = 0.5 * log((1 + `corr_bh')/(1 - `corr_bh'))
correlate implied ffr if !bondholder
local corr_nbh = r(rho)
local fisher_r_nbh = 0.5 * log((1 + `corr_nbh')/(1 - `corr_nbh'))
display(`fisher_r_bh' - `fisher_r_nbh')

count if bondholder
local n_bh = r(N)
count if !bondholder
local n_nbh = r(N)
local fisher_se = sqrt(1/(`n_bh' - 3) + 1/(`n_nbh' - 3))
display(`fisher_se')

correlate implied_real ffr_real if bondholder
local corr_real_bh = r(rho)
local fisher_r_real_bh = 0.5 * log((1 + `corr_real_bh')/(1 - `corr_real_bh'))
correlate implied_real ffr_real if !bondholder
local corr_real_nbh = r(rho)
local fisher_r_real_nbh = 0.5 * log((1 + `corr_real_nbh')/(1 - `corr_real_nbh'))
display(`fisher_r_real_bh' - `fisher_r_real_nbh')

local fisher_real_se = sqrt(1/(`n_bh' - 3) + 1/(`n_nbh' - 3))
display(`fisher_real_se')

// regressions
regress spread ffr_real bondholder i.bondholder#c.ffr_real spread_1 spread_2 spread_3 spread_4
regress spread_real ffr_real bondholder i.bondholder#c.ffr_real spread_real_1 spread_real_2 spread_real_3 spread_real_4
