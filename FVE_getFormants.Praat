########################################################################################################
#
# FVE get formants
#
# This script will reference an already existing _textgrid csv, which has the start and end times for 
# relevant vowels. It will use these start and end times to find the interval in a given sound file to 
# get formants. Although the textgrids already exist (to make the _textgrid csv in R), this particular 
# script does not actually need to reference them. 
#
# Need: 
# 1. Soundfiles (I anticipate doing this by looping through all the soundfiles, not one at a time)
# 2. FVE_textgrid csv where there is one row per word, and each word has a v1 start/end and a v2 start/end
# --- This also has gender for formant range purposes, and some indication of what file to open
# --- Also indicates what the quality of the vowel is. In some cases I have consonants (since it's an excrescent vowel)
# so I check for vowel matches and only find formants if it's a string match with a set of vowels
# 
# Will create:
# 1. Modify the original CSV with added columns: v1_F1, v1_F2, v2_F1, v2_F2
# 
# This script, like my other vowel scripts, will generate a 20 ms window over the midpoint of the vowel. 
# I will make a "trust me" option or a "let me modify" option, where you can either assume that the vowels
# will be stable over the middle, or you can check and adjust as you need.  
#
# Since this script is designed for an corpus where there might not actually be 20 ms of vowel, there
# will be a check on the length of the vowel. If it is sub 20 ms the formants will be entered as N/A. 
# 
# Steps: 
# 1. Open CSV as table
# 2. Read dialect/city from the table for each trial (word). Check if an object of that name already exists;
# if yes, don't open again, if no, open 
# 3. Set start and end of relevant vowels (these are columns in the CSV)
# 4. Select V1 and get formants; 
# 5. Select V2 and get formants; 
# 6. Write formant values to Table
# 7. Save table as new CSV (doesn't overwrite original) 
#
# This is a "trust me" version where I assume you don't want to adjust the measurement intervals at all.
# You can of course add in another step that uses pauses and textgrids to adjust selections.  
# 
# Last modified by Robin Karlin 2/19/2019
#
#
########################################################################################################


## UI for customizing for your participant/computer: can change this basic path to be specific to your computer
# For some reason all variables, string or not, are plain (i.e., string variables do not have $)
form Choose path and participant
	comment Audio directory path
	text audioDir D:\Users\viria\Documents\00 Data\02 CNF (Central and Northern Finnish)\02 FVE (Finnish vowel epenthesis)\
	# Format of this is "type of entry" "variable name" "auto fill" 

	comment CSV directory path
	text csvDir D:\Users\viria\Documents\00 Data\02 CNF (Central and Northern Finnish)\02 FVE (Finnish vowel epenthesis)\00 Data structures\

	comment CSV filename (no extension) 
	text csvName FVE_tgrids

	comment Output CSV filename (no extension)
	text outputName FVE_tgrids_withformants

	comment Extension of sound files
	text ext .wav

	comment Trust me?
	boolean autoLabel 1

#	comment Gender of participant
#	optionmenu gender: 1
#	option Male
#	option Female (or child)
endform

# Formant-specific parameters
numFormant = 5
winLength = 0.025
dynRange = 30.0
dotSize = 1.0

# Sometimes I do diphthongs
phthong$ = "monophthong"

# Load CSV (get number of words)
voweltable = Read Table from comma-separated file: csvDir$ + csvName$ + ".csv"
selectObject (voweltable)
nrows = Get number of rows

# Create new columns for F1 and F2 for each vowel 
do ("Append column...", "v1_F1")
do ("Append column...", "v1_F2")
do ("Append column...", "v2_F1")
do ("Append column...", "v2_F2")

for a from 1 to nrows

	# Read in soundfile
	selectObject (voweltable)
	dialect$ = do$ ("Get value...", a, "dialect")
	city$ = do$ ("Get value...", a, "city")

	soundfile$ = dialect$ + "\" + city$ + "\" + city$ + ".wav" 

	### Set intervals based on table values
	selectObject (voweltable)
	# V1 
	v1Beg = do ("Get value...", a, "m1_start") 
	v1End = do ("Get value...", a, "m1_end")
	v1Dur = do ("Get value...", a, "m1_dur")
	v1Mid = v1Beg + (v1Dur/2)
	v1$ = do$ ("Get value...", a, "m1_quality")

	# V2 
	v2Beg = do ("Get value...", a, "m2_start") 
	v2End = do ("Get value...", a, "m2_end")
	v2Dur = do ("Get value...", a, "m2_dur")
	v2Mid = v2Beg + (v2Dur/2)
	v2$ = do$ ("Get value...", a, "m2_quality")

	# But only open anew if we've gone onto a new city
	if a == 1
		soundObject = do ("Read from file...", audioDir$ + soundfile$) ; if we're on the first file you have to open
		selectObject (voweltable)
		gender$ = do$ ("Get value...", a, "gender")
		selectObject (soundObject)
		do ("View & Edit") 
	else
		selectObject (soundObject)
		objectName$ = selected$ ("Sound") ; get the handle of the selected sound object (without the "Sound" bit)
		
		if objectName$ <> city$
			# get rid of the old one
			selectObject (soundObject)
			do ("Remove") 			

			# make a new one
			soundObject = do ("Read from file...", audioDir$ + soundfile$) ; if the previously defined sound object has a name that is different from the current city
			selectObject (soundObject)
			do ("View & Edit")
			selectObject (voweltable)
			gender$ = do$ ("Get value...", a, "gender") 
		else
			soundObject = soundObject ; keep the previously defined sound object as is
			gender$ = gender$
		endif 
	endif

	# Set gender-relevant values
	if gender$ = "M"
		maxFormant = 5000 ; for males
	elsif gender$ = "F"
		maxFormant = 5500 ; for females
	elsif gender$ = "H"
		maxFormant = 7000 ; for that really high-pitched speaker 
	endif

	# Now start getting measures

# These editor environments seem to be necessary (goes back and forth a couple of times)
editor Sound 'city$'
	# Fixes formant range (for male vs. female, e.g.)
	do ("Formant settings...", maxFormant, numFormant, winLength, dynRange, dotSize)

	# Making 20 ms intervals around the midpoint of the labeled vowel (I'm only doing the "trust me" version right now) 
	# only applies if the vowel is long enough (i.e., at least 20 ms)
	if v1Dur >= 0.02
		bV150 = v1Mid-0.01
		eV150 = v1Mid+0.01

		# Select and measure
		do ("Select...", bV150, eV150)
		do ("Zoom to selection") 

# pauseScript: "Check V1 formants" 

		v1_F1 = do ("Get first formant")
		v1_F2 = do ("Get second formant")

	else 
		v1_F1 = 0
		v1_F2 = 0
		# If it's too short you won't be able to track them anyway
	endif 

	# Now for v2
	if v2$ = "i" || v2$ = "e" || v2$ = "A" || v2$ = "y" || v2$ = "O" || v2$ = "u" || v2$ = "o" || v2$ = "a" || v2$ = "ep" ; if v2 quality is a vowel
		if v2Dur >= 0.02
			bV250 = v2Mid-0.01
			eV250 = v2Mid+0.01

			# Select and measure
			do ("Select...", bV250, eV250)
			do ("Zoom to selection") 

# pauseScript: "Check V2 formants" 

			v2_F1 = do ("Get first formant")
			v2_F2 = do ("Get second formant")

		else 
			v2_F1 = 0
			v2_F2 = 0
			# If it's too short you won't be able to track them anyway. Using 0 because of the rounding issue lower down
		endif 
	else 
		v2_F1 = 0
		v2_F2 = 0
		# If it's a consonant, don't get formants

	endif 
endeditor 

	## Adding to the vowel table

	# Precision for formants and ms (so you don't get 80 million digits)---shouldn't matter that it's a string
	formantPrecision = 2;
	v1_f1_hPrec$ = fixed$ (v1_F1, formantPrecision)
	v1_f2_hPrec$ = fixed$ (v1_F2, formantPrecision)

	v2_f1_hPrec$ = fixed$ (v2_F1, formantPrecision)
	v2_f2_hPrec$ = fixed$ (v2_F2, formantPrecision)

	selectObject (voweltable) 
	do ("Set string value...", a, "v1_F1", v1_f1_hPrec$)
	do ("Set string value...", a, "v1_F2", v1_f2_hPrec$)
	do ("Set string value...", a, "v2_F1", v2_f1_hPrec$)
	do ("Set string value...", a, "v2_F2", v2_f2_hPrec$)

endfor ; number of words for

# Now save the altered table 
selectObject (voweltable)
do ("Save as comma-separated file...", csvDir$ + outputName$ + ".csv")

writeInfoLine ("tada") 

################################
procedure split (.sep$, .str$)
  .seplen = length(.sep$) 
  .length = 0
  repeat
    .strlen = length(.str$)
    .sep = index(.str$, .sep$)
    if .sep > 0
      .part$ = left$(.str$, .sep-1)
      .str$ = mid$(.str$, .sep+.seplen, .strlen)
    else
      .part$ = .str$
    endif
    .length = .length+1
    .array$[.length] = .part$
  until .sep = 0
endproc