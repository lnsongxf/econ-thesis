clear all
set more off
set matsize 11000

// NIPA
do load-nipa.do nipa
do load-nipa.do nipa-collard

// CEX
do clean-cex.do
do clean-cpi.do
do load-cex.do cex-bondholders
do load-cex.do cex-nonbondholders
