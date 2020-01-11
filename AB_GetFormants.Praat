##############################################################################################
# Script for vowel measuring projects: tailored for Andrej Bjelakovic's assumed data structure
# Sound filename format: RK01.wav (better to not use spaces, but will not error)
# TextGrid filename format: RK01.TextGrid
# Output filename format: RK01.txt (tab-separated)
# 
# STEP 0: Change the automatics in the UI portion of the script
# ---- experimentDirectory will probably be the only one you need/want to change 
# 
# STEP 1: Click run
# Script will open a UI window for you to change path (if necessary), participant tag, gender,
# extension (defaults are provided). No need to use "" around strings
# 
# STEP 2: Click okay
# Script will find a sound file for a participant, open, and create textgrid with two tiers: 
# 1. 'vowel' for marking the whole vowel, 
# 2. 'measure' for marking the parts of the vowel that you will be measuring
# 
# STEP 3: Mark the vowel you want to measure on 'vowel' tier
# ---- labels should be in format word_VOWEL, e.g., tied_PRICE (case sensitive)
# -------- currently depends on diphthongs being accurate: use Wells set (GOAT, FACE, PRICE, MOUTH)
# -------- monophthongs can use any label 
# -------- you can adjust the words for the string comparison (line 110)
# ---- make sure you have that interval highlighted before the next step (should be automatic after having typed in it)
# 
# STEP 4: Click Continue
# ---- the script will automatically populate the second tier, 'measure' 
# ---- if the VOWEL is MOUTH, PRICE, GOAT, or FACE, there will be two intervals (head and tail)
# 
# STEP 5: Adjust intervals on 'measure'
# ---- fix the automatic intervals to be where you want them
# 
# STEP 6: Click Continue
# ---- script will get duration of the vowel (vDur)
# ---- script will get formants from measure intervals (f1_h, f1_t, f2_h, f2_t)
# ---- script will make tab-separated values file with the measures
# ---- script will loop back to step 2, repeat until done 
# 
# After you have completed step 6 for the last vowel you're going to measure, click Stop (will throw error, ignore)
#
# Last edited March 22, 2017 (RK---minor edit, fixes path for you if you entered one without filesep)
###############################################################################################

## UI for customizing for your participant/computer: can change this basic path to be specific to your computer
# For some reason all variables, string or not, are plain (i.e., string variables do not have $)
form Choose path and participant
	comment Experiment directory path
	text experimentDirectory D:\Users\Viriam\Documents\MATLAB\PraatScripts\AB_GetFormants\
	# Format of this is "type of entry" "variable name" "auto fill" 

	comment Extension of sound files
	text ext .wav

	comment Handle of participant
	text subj AB01

	comment Gender of participant
	optionmenu gender: 1
	option Male
	option Female (or child)
endform

### ********** added March 22
## Fix the original path if you didn't give a filesep at the end
dirLastchar$ = right$ (expDir$, 1)
if dirLastchar$ != "\" and dirLastchar$ != "/"
	expDir$ = expDir$ + "\"
endif
### **********

## Automatically change hz ceiling for formants
if gender = 1
	maxFormant = 5000 ; for males
else
	maxFormant = 5500 ; for females
endif

# Other formant tracking options are here in case you want to change them
numFormant = 5
winLength = 0.025
dynRange = 30.0
dotSize = 1.0
	
# # # # # # # # For non-UI version 
### Settings for customizing for your participant/computer
## Directory where you store your participant files (note that it ends with the filesep \)
#experimentDirectory$ = "C:\Users\Viriam Karo\Documents\01 Research\Vowel script testing\"
## Participant tag
#subj$ = "AB_zora"
## Extension (mp3, wav, whatever)
#ext$ = ".wav"
#
### Changing settings for formants (for easy change of maximum hz for formant)
## Command actually happens later, right when you first open the sound file and text grid
#maxFormant = 5500
# # # # # # # # 


## Specify the name of the output file: e.g. RK01.txt
outfile$ = subj$ + ".txt"
# If the output file doesn't already exist, create, and create headers
if not fileReadable (experimentDirectory$ + outfile$)
	writeFileLine (experimentDirectory$ + outfile$, "subj", tab$, "word", tab$, "vowel", tab$, "dur", tab$, "f1", tab$, "f2", tab$, "f1_t", tab$, "f2_t")
endif

## Read the sound file
do ("Read from file...", experimentDirectory$ + subj$ + ext$)
# This changes all the spaces from the subject into _ (because Praat does that when it makes objects)
# This means that the TextGrid will be saved as, e.g., AB_Zora_Story, but text file will be AB Zora Story
subj$ = replace$ (subj$, " ", "_", 0)
selectObject ("Sound " + subj$)

## Open (if exists) or create (if doesn't) the TextGrid 
if fileReadable (experimentDirectory$ + subj$ + ".TextGrid")
	do ("Read from file...", experimentDirectory$ + subj$ + ".TextGrid")
else
	selectObject ("Sound " + subj$)
	do ("To TextGrid...", "vowel measure", "")
endif

## Opens TextGrid and sound file to edit together
selectObject ("Sound " + subj$)
plusObject ("TextGrid " + subj$)
View & Edit
	
## Starting the while loop: "done" is just so that it keeps going until you hit "Stop" 
done = 0
while done < 1

# These editor environments seem to be necessary (goes back and forth a couple of times)
editor TextGrid 'subj$'
	# Fixes formant range (for male vs. female, e.g.)
	do ("Formant settings...", maxFormant, numFormant, winLength, dynRange, dotSize)
	# Pauses for you to add an interval
	pause Mark beginning and end of vowel in 'vowel' tier; label with word_VOWEL

	# Get beginning, end, and duration of interval
	vBeg = do ("Get starting point of interval")
	vEnd = do ("Get end point of interval")
	vDur = vEnd - vBeg
	vDurMs = vDur * 1000

	# Find midpoint
	vMid = vBeg + (vDur/2)

	# Get label of interval; split into component parts (word and vowel) 
	label$ = do$ ("Get label of interval")
	@split ("_", label$)
	word$ = split.array$[1]
	vowel$ = split.array$[2]
	
	# If diphthong, then head/tail; if not, then midpoint ish (this is case sensitive)
	if vowel$="PRICE" or vowel$="MOUTH" or vowel$="FACE" or vowel$="GOAT"
		# making "phthong" variable so you only have to specify which vowels once
		phthong$ = "diphthong"

		# Making 20 ms intervals around the 30 and 70% marks (customizable) 
		locV33 = vDur * 0.30 *1000
		locV33 = round (locV33)
		locV33 = (locV33/1000)+vBeg
		locV66 = vDur * 0.70 *1000
		locV66 = round (locV66)
		locV66 = (locV66/1000)+vBeg
		bV33 = locV33-0.01
		eV33 = locV33+0.01
		bV66 = locV66-0.01
		eV66 = locV66+0.01

		do ("Move cursor to...", bV33)
		do ("Add on tier 2")
		do ("Move cursor to...", eV33)
		do ("Add on tier 2")
		do ("Move cursor to...", bV66)
		do ("Add on tier 2")
		do ("Move cursor to...", eV66)
		do ("Add on tier 2")

	else
		phthong$ = "monophthong"

		# Making 20 ms intervals around the midpoint of the labeled vowel
		bV50 = vMid-0.01
		eV50 = vMid+0.01
		do ("Move cursor to...", bV50)
		do ("Add on tier 2")
		do ("Move cursor to...", eV50)
		do ("Add on tier 2")

	endif
endeditor 

	## Naming the automatically created intervals
	if phthong$="diphthong"
		# Finds the number of the interval that was just added, renames it e.g. PRICE_H or PRICE_T
		minusObject ("Sound " + subj$)
		intervalNumHead = do ("Get interval at time...", 2, locV33)
		do ("Set interval text...", 2, intervalNumHead, vowel$ + "_H")

		intervalNumTail = do ("Get interval at time...", 2, locV66)
		do ("Set interval text...", 2, intervalNumTail, vowel$ + "_T")

	else
		# Finds the number of the interval that was just added, renames it e.g. KIT_H (using H to be parallel with above)
		minusObject ("Sound " + subj$) 
		intervalNumHead = do ("Get interval at time...", 2, vMid)
		do ("Set interval text...", 2, intervalNumHead, vowel$ + "_H")

	endif

# Pause for you to fix the measurement intervals
pause Adjust vowel measurement intervals, then press Continue
	
	# Gets the updated start and end points of the head/tail intervals (tail only for diphthongs) 
	headStart = do ("Get start point...", 2, intervalNumHead)
	headEnd = do ("Get end point...", 2, intervalNumHead)

	if phthong$="diphthong"
		tailStart = do ("Get start point...", 2, intervalNumTail)
		tailEnd = do ("Get end point...", 2, intervalNumTail)
	endif

	selectObject ("Sound " + subj$)
	plusObject ("TextGrid " + subj$)
	# View & Edit # I commented this out because otherwise you keep getting new windows

# Getting formant measurements, using the start and end points of the measurement intervals
editor TextGrid 'subj$'
	if phthong$="diphthong"
		do ("Select...", headStart, headEnd)
		f1_h = do ("Get first formant")
		f2_h = do ("Get second formant")
		do ("Select...", tailStart, tailEnd)
		f1_t = do ("Get first formant")
		f2_t = do ("Get second formant")
	else
		# For convenience, just having f1_t = f1_h 
		do ("Select...", headStart, headEnd)
		f1_h = do ("Get first formant")
		f2_h = do ("Get second formant")
		f1_t = f1_h
		f2_t = f2_h
	endif
endeditor

	## Adding to the tab-separated values file now

	# Precision for formants and ms (so you don't get 80 million digits)---shouldn't matter that it's a string
	formantPrecision = 2;
	f1_hPrec$ = fixed$ (f1_h, formantPrecision)
	f1_tPrec$ = fixed$ (f1_t, formantPrecision)
	f2_hPrec$ = fixed$ (f2_h, formantPrecision)
	f2_tPrec$ = fixed$ (f2_t, formantPrecision)

	msDurPrecision = 2;
	vDurMsPrec$ = fixed$ (vDurMs, msDurPrecision)
	
	appendFileLine (experimentDirectory$ + outfile$, subj$, tab$, word$, tab$, vowel$, tab$, vDurMsPrec$, tab$, f1_hPrec$, tab$, f2_hPrec$, tab$, f1_tPrec$, tab$, f2_tPrec$)

	# Save TextGrid
	minusObject ("Sound " + subj$)
	selectObject ("TextGrid " + subj$)
	do ("Save as text file...", experimentDirectory$ + subj$ + ".TextGrid")

endwhile

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