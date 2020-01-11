#############################################################################################
# 
# Script to semi-automatize labeling of vowels in Zora etc. texts
#
# Files needed:
# 1. Long sound file
# 2. CSV file with the words to be measured in one column (formateed word_vowel, e.g. zora_oo)
# ---- The sound file must have the words in the CSV---i.e., you can have any size sound file but
# the CSV has to match. 
# ---- Should be titled text_transcript.csv, e.g. Zora_transcript.csv
# 
# Files created (one of each for each sound file): 
# 1. .TextGrid for each sound file with two tiers, "vowel" and "measure"
# 2. .txt with the measurements (tab separated) 
#
# STEP 0: Fix defaults values for UI variables (in the first lines of the script)
# ---- experimentDirectory and text probably the ones you want to alter
# 
# STEP 1: Run script
# ---- Enter desired paths, etc. 
# 
# STEP 2: Click okay
# Script will find the specified sound file, and open the list of transcribed words. Create or open TextGrid: 
# 1. 'vowel' for marking the whole vowel, 
# 2. 'measure' for marking the parts of the vowel that you will be measuring
# 
# STEP 3: Mark the vowel you want to measure on 'vowel' tier
# ---- make sure you have that interval highlighted before the next step (should be automatic after having typed in it)
# 
# STEP 4: Click Continue
# ---- the script will automatically populate the first tier, 'vowel', from the CSV transcript file
# -------- This goes by the number of the interval and the number of the word, so do this in order
# ---- the script will automatically populate the second tier, 'measure' 
# 
# STEP 5: Adjust intervals on 'measure'
# ---- fix the automatic intervals to be where you want them
# 
# STEP 6: Click Continue
# ---- script will get duration of the vowel (vDur)
# ---- script will get formants from measure intervals (f1_h, f1_t, f2_h, f2_t)
# ---- script will make or append to tab-separated values file with the measures
# ---- script will save .TextGrid
# ---- script will loop back to step 3, repeat until done 
# 
# You can stop at any time and resume later. If you finish the transcript it'll tell you you're done
#
# Last edited March 22, 2017 (RK, minor edit regarding fileseps)
# Last edited April 17, 2017 (RK, bug fix, zoom feature added)
############################################################################################### 

## UI for customizing for your participant/computer: can change this basic path to be specific to your computer
# For some reason all variables, string or not, are plain (i.e., string variables do not have $)
form Choose path and participant
	comment Experiment directory path
	text expDir D:\Users\Viriam\Documents\MATLAB\PraatScripts\AB_GetFormants\
	# Format of this is "type of entry" "variable name" "auto fill" 

	comment Extension of sound files
	text ext .wav

	comment Handle of participant
	text subj AB01

	comment Text you are annotating
	text text ZoraRada
	# This is still here in case you use this for some other project/text---can always just change this 

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

## This does subj_text which seems a little unnecessary if every participant has just one sound file; could potentially be useful
# If you decide to make it just AB01 and not AB01_Zora and AB01_Rada, then just change it to fileTag$ = subj$ 
fileTag$ = subj$ + "_" + text$

## Automatically change hz ceiling for formants
if gender = 1
	maxFormant = 5000 ; for males
else
	maxFormant = 5500 ; for females
endif

# # # # # # # # From the non-UI version of doing it
### Settings for customizing for your participant/computer
## Directory where you store your participant files (note that it ends with the filesep \)
#expDir$ = "C:\Users\Viriam Karo\Documents\01 Research\AB_GetFormants\"
## Participant tag
#subj$ = "AB01"
#text$ = "Zora" 
## Extension (mp3, wav, whatever)
#ext$ = ".wav"
#
### Changing settings for formants (for easy change of maximum hz for formant)
## Command actually happens later, right when you first open the sound file and text grid
##maxFormant = 5500
# # # # # # # # 

# Other formant tracking options are here in case you want to change them
numFormant = 5
winLength = 0.025
dynRange = 30.0
dotSize = 1.0

## Makes a Strings object that is the text file with the order of responses
do ("Read Strings from raw text file...", expDir$ + text$ + "_transcript.csv")
selectObject ("Strings " + text$ + "_transcript")
wordsN = do ("Get number of strings")

## Specify the name of the output file: e.g. AB01_Zora.txt
outfile$ = fileTag$ + ".txt"

# If the output file doesn't already exist, create, and create headers
if not fileReadable (expDir$ + outfile$)
	writeFileLine (expDir$ + outfile$, "subj", tab$, "vowel", tab$, "word", tab$, "f1", tab$, "f2", tab$, "f3", tab$, "f1_t", tab$, "f2_t", tab$, "f3_t", tab$, "dur")
endif

## Read the sound file
do ("Read from file...", expDir$ + fileTag$ + ext$)
# This changes all the spaces from the subject into _ (because Praat does that when it makes objects)
# This means that the TextGrid will be saved as, e.g., AB_Zora_Story, but text file will be AB Zora Story
fileTag$ = replace$ (fileTag$, " ", "_", 0)
selectObject ("Sound " + fileTag$)

## Open (if exists) or create (if doesn't) the TextGrid 
if fileReadable (expDir$ + fileTag$ + ".TextGrid")
	do ("Read from file...", expDir$ + fileTag$ + ".TextGrid")
else
	selectObject ("Sound " + fileTag$)
	do ("To TextGrid...", "vowel measure", "")
endif

## If you've started this file before and are resuming, this figures out where you are
selectObject ("TextGrid " + fileTag$)
intervalNo = do ("Get number of intervals...", 1)
# Number should always be odd---if it's a new TextGrid, it'll be 1, if it has INTERVALS marked 
# (i.e., a vowel, not a random boundary), it should be 3 (blank to the left, full interval, blank to the right)
intervalEven = intervalNo + 1
resume = intervalEven / 2

## Opens TextGrid and sound file to edit together
selectObject ("Sound " + fileTag$)
plusObject ("TextGrid " + fileTag$)
View & Edit

## Begin loop for going through the sound file
for itrial from resume to wordsN
	## Get the thing they said in this trial
	selectObject ("Strings " + text$ + "_transcript")
	trialWords$ = Get string... itrial
	minusObject ("Strings " + text$ + "_transcript")
	# Split into word and vowel
	@split ("_", trialWords$)
	word$ = split.array$[1]
	vowel$ = split.array$[2]

	# These editor environments seem to be necessary (goes back and forth a couple of times)
editor TextGrid 'fileTag$'
	# Fixes formant range (for male vs. female, e.g.)
	do ("Formant settings...", maxFormant, numFormant, winLength, dynRange, dotSize)
	# Pauses for you to add an interval
	pause Mark beginning and end of vowel in 'vowel' tier; select when done and hit Continue

	# Get beginning, end, and duration of interval
	vBeg = do ("Get starting point of interval")
	vEnd = do ("Get end point of interval")
	vDur = vEnd - vBeg
	vDurMs = vDur * 1000

	# Find midpoint
	vMid = vBeg + (vDur/2)
endeditor

	## Set text
	minusObject ("Sound " + fileTag$)
	selectObject ("TextGrid " + fileTag$)
	intervalNumVowel = do ("Get interval at time...", 1, vMid)
	do ("Set interval text...", 1, intervalNumVowel, trialWords$)

	## Create measurement intervals (not doing anything for diphthongs, as Serbian data doesn't have)
	# Making 20 ms intervals around the midpoint of the labeled vowel
	bV50 = vMid-0.01
	eV50 = vMid+0.01
	selectObject ("TextGrid " + fileTag$)
	do ("Insert boundary...", 2, bV50)
	do ("Insert boundary...", 2, eV50)

	## Finds the number of the interval that was just added, renames it e.g. e_H (using H b/c I'm copy pasting)
	# minusObject ("Sound " + subj$) 
	intervalNumHead = do ("Get interval at time...", 2, vMid)
	do ("Set interval text...", 2, intervalNumHead, vowel$ + "_H")

	# Pause for you to fix the measurement intervals
	pause Adjust vowel measurement intervals, then press Continue
	
	# Gets the updated start and end points of the head/tail intervals (tail only for diphthongs) 
	headStart = do ("Get start point...", 2, intervalNumHead)
	headEnd = do ("Get end point...", 2, intervalNumHead)

	# Getting formant measurements, using the start and end points of the measurement intervals
	selectObject ("TextGrid " + fileTag$)
	plusObject ("Sound " + fileTag$)
editor TextGrid 'fileTag$'

	# For convenience, just having f1_t = f1_h 
	do ("Select...", headStart, headEnd)
	f1_h = do ("Get first formant")
	f2_h = do ("Get second formant")
	f3_h = do ("Get third formant")
	# Doing as string variables since they're all monohpthongs and thus should be left blank in NORM template style
	f1_t$ = ""
	f2_t$ = ""
	f3_t$ = ""

endeditor

	## Adding to the tab-separated values file now

	# Precision for formants and ms (so you don't get 80 million digits)---shouldn't matter that it's a string
	# just using the _t's because they're already blank strings
	formantPrecision = 2;
	f1_hPrec$ = fixed$ (f1_h, formantPrecision)
	f2_hPrec$ = fixed$ (f2_h, formantPrecision)
	f3_hPrec$ = fixed$ (f3_h, formantPrecision)

	msDurPrecision = 2;
	vDurMsPrec$ = fixed$ (vDurMs, msDurPrecision)
	
	appendFileLine (expDir$ + outfile$, subj$, tab$, vowel$, tab$, word$, tab$, f1_hPrec$, tab$, f2_hPrec$, tab$, f3_hPrec$, tab$, f1_t$, tab$, f2_t$, tab$, f3_t$, tab$, vDurMsPrec$, tab$)

	# Save TextGrid
	minusObject ("Sound " + fileTag$)
	selectObject ("TextGrid " + fileTag$)
	do ("Save as text file...", expDir$ + fileTag$ + ".TextGrid")

endfor

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