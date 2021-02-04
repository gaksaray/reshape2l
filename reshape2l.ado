*! version 1.4  04feb2021  Gorkem Aksaray

capture program drop reshape2l
program define reshape2l
	version 11
	syntax newvarlist, i(varlist) [j(name) Counter]

	local stublist `varlist'

	* Confirm j is a new variable if specified
	if "`j'" != "" {
		confirm new variable `j'
	}

	* Error if any stub is the same as j
	if subinword("`stublist'", "`j'", "", .) != "`stublist'" {
		noi di as err "j = {bf:`j'} cannot be used as a stub"
		error 101
		exit
	}

	* Create jlist (for jnote)
	local jlist

	* Unabbreviate used variable list for all stubs
	foreach stub of local stublist {

		// unabbreviate variables starting with `stub'
		capture unab `stub'vars : `stub'*
		if _rc {
			noi di as err "no variables with stub {bf:`stub'} found"
			exit _rc
		}

		// pick the numeric or string after `stub'
		local `stub'num = `: word count ``stub'vars''
		forvalues n = 1/``stub'num' {
			local `stub'var = word("``stub'vars'", `n')
			local w = regexr("``stub'var'", "^`stub'", "")

			capture confirm number `w'

			// if w is string
			if _rc {
				noi di as err "warning: variable {bf:``stub'var'} contains nonnumeric `j' {bf:`w'}"
			}

			// if w is numeric
			local passcount = 0
			else {
				local ++passcount

				local r = real("`w'")

				// add r to jlist
				local jlist = "`jlist'" + " `r' "

				// calculate range of r
				if `n' == 1 & `passcount' == 1 { //record r as is in the first pass
					local min = `r'
					local max = `r'
				}
				else {
					local min = min(`r', `min')
					local max = max(`r', `max')
				}
				local usedvarlist `usedvarlist' `stub'`r'
			}
		}
	}

// 	noi di as err "usedvarlist: `usedvarlist'"

	* Save unused variable list
	qui ds `i' `usedvarlist', not
	local unusedvarlist `r(varlist)'

// 	noi di as err "unusedvarlist: `unusedvarlist'"

	* Simplify jlist to produce jnote
	forvalues n = `min'/`max' {
		if strpos("`jlist'", " `n' ") != 0 {
			local jnote `jnote' `n'
		}
	}
	di as text "(note: j = `jnote')"

	* Save main data
	tempfile main
	qui save "`main'"

	* Get the list of `n'th variable of all stubs
	forvalues n = `min'/`max' {
		foreach stub of local stublist {
			capture confirm variable `stub'`n'
			if !_rc {
				local vars`n' `vars`n'' `stub'`n'
			}
		}
	}

	* Set counter
	if "`counter'" != "" {
		local count = 0
		forvalue n = `min'/`max' {
			if "`vars`n''" == "" continue
			local ++count
		}
	local cratio "(100 / `count')"
	di "Progress:"
	}

	local N = 0
	forvalues n = `min'/`max' {

		* Pass `n' if the list of `n'th variables of all stubs is empty
		if "`vars`n''" == "" continue
		local ++N

		* Reload main data
		qui use `i' `vars`n'' `unusedvarlist' using "`main'", clear

		* Delete the number after `stub'
		foreach stub of local stublist {
			capture confirm variable `stub'`n'
			if !_rc {
				rename `stub'`n' `stub'
			}
		}

		* Generate j
		if "`j'" != "" generate `j' = `n'
		else generate _j = `n'

		* Build `file' for concentation
		tempfile temp
		qui save "`temp'", replace
		local files `"`files'"`temp'" "'
		macro drop _vars

		* Counter display
		if "`counter'" != "" {
			local pct = `N' * `cratio'
			di %6.2f `pct' "%"
		}
	}

	* Concatenate
	capture which dsconcat
	if _rc == 111 ssc install dsconcat
	dsconcat `files'

	* Order and sort
	order `i' `j' `unusedvarlist'
	sort  `i' `j'

end
