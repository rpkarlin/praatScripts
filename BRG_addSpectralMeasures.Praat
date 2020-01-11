##############################################################################################
# Script for getting spectral measures for BRG
#
# Sound filename format: YK03_01_01.wav
# TextGrid filename format: YK03_01_01.TextGrid
# Starting data filename format: YK03_tgrids.csv
# Output filename format: YK03_tgrids_withspectral.csv (will overwrite anything that's already there!) 
# 
# STEP 0: Change the automatics in the UI portion of the script
# ---- experimentDirectory will probably be the only one you need/want to change 
# 
# STEP 1: Click run
# Script will open a UI window for you to change path (if necessary), participant tag, select measures, decide slices, 
# etc. 
# --- Note: depending on your computer you may want to do a subselection of the measures; spectral tilt in particular is said to take a lot of power 
#
# STEP 2: Click okay
# --- Script will open existing CSV
# --- Script will find all the sound and textgrid files, and make sure that the number of files is the same as the number of rows
#
# STEP 3
# --- Append all columns 
# --- 
# Script will find all the sound and textgrid files, make sure it is the same as the number of rows and start looping through them. 
# --- Find the vowel (currently hard-coded as the penultimate seg interval)
#
# STEP 4
# --- Add measures (according to what you selected in the UI) 
# --- Adds measure for each slice--- outer loop = file loop, inside = slice loop
# --- Write to table: set each cell 
#
# STEP 5
# --- When outer loop done, save table as CSV 
#
# Last edited: 19 November 2018 by Robin Karlin (creation edit) 
# 12 July 2019 by Robin Karlin (for BRG2)  
# 
###############################################################################################

## UI for customizing for your participant/computer: can change this basic path to be specific to your computer
# For some reason all variables, string or not, are plain (i.e., string variables do not have $)
form Choose path and participant
	comment Experiment directory path (with filesep at end)
	text expDir D:\Users\viria\Documents\00 Data\07 BRG (Burmese RegistroGenesis)\Followup\
	# Format of this is "type of entry" "variable name" "auto fill" 

	comment Handle of participant. Leave blank to do all participants; can also do all except one with ^(AB01) 
	text subj YK01

	comment Rewrite current data csv file? 
	boolean rewriteYN 0

	comment Which measures would you like to include?  
	boolean specTilt 1
	boolean jitter 1
	boolean shimmer 1
	boolean hnr 1
	boolean amplitude 1
	boolean f1 1
	boolean f2 1
	boolean f3 0
	boolean f0 1

	comment How many slices would you like per measure?
	integer nSlices 4
	
	comment Start from block(:trial)
	text startFrom 1:1

	comment End after block
	integer lastBlock 10

	comment Number of trials per block
	integer nTrials 60

	comment Tier that segs are on (number)
	integer segTier 2

	comment Interval number of vowel on aforementioned tier 
	integer vowelInt 3

endform

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
# Additional definitions from UI

## Fix the original path if you didn't give a filesep at the end
dirLastchar$ = right$ (expDir$, 1)
if dirLastchar$ != "\" and dirLastchar$ != "/"
	expDir$ = expDir$ + "\"
endif

dataDir$ = expDir$ + subj$ + "\" + subj$ + "\"

## Get the start trial so you can start in the middle of a block 
indexBtColon = index (startFrom$, ":")
@split (":", startFrom$)
startFromBlock = number (split.array$[1])
if indexBtColon
	startFromTrial = number (split.array$[2])
else
	startFromTrial = 1
endif

# For rewriting---make a new copy with date in the filename if you don't want to overwrite
if rewriteYN == 0 
	date$ = date$()
	saveFileName$ = subj$ + "_tgrids_" + date$ + ".csv" 
else
	saveFileName$ = subj$ + "_tgrids.csv")
endif

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Additional variables for the spectral measures

minHz = 100
maxHz = 400
timeStep = 0.005 ; standard for my pitch objects 

silenceThresh = -25
minPause = 0.1
minVoiced = 0.1

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# STEP 2
# Open existing files 

# Make list of tgrids and soundfiles
stringsFiles = do ("Create Strings as file list...", "files", dataDir$ + subj$ + "*.wav")
nFiles = Get number of strings
dummyColName$ = "remove" ; in case you need to create a table with a dummy column 

if fileReadable (dataDir$ + subj$ + "_tgrids.csv") 
	newlycreatedtable = 0 
	dataTable = do ("Read Table from comma-separated file...", dataDir$ + subj$ + "_tgrids.csv") 
	nDataRows = Get number of rows
	# Stop the script if you don't have the same number of rows as soundfiles 
	if nFiles <> nDataRows
		exit You don't have the same number of wav files as data rows!
	endif
else
	newlycreatedtable = 1
	dataTable = do ("Create Table with column names...", subj$ + "_tgrids", nFiles, dummyColName$)
endif

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# STEP 3
# Data table setup

# number of measures (for a later loop that generates column headers) 
nMeasures = specTilt + jitter + shimmer + hnr + amplitude + f1 + f2 + f3 + f0

# weeellll this is clunky but oh well 
c = 1
if specTilt
	measures$ [c] = "specTilt_"
	c = c+1
endif 
if jitter
	measures$ [c] = "jitter_"
	c = c+1
endif 
if shimmer
	measures$ [c] = "shimmer_"
	c = c+1
endif 
if hnr
	measures$ [c] = "hnr_"
	c = c+1
endif 
if amplitude
	measures$ [c] = "amp_"
	c = c+1
endif 
if f1
	measures$ [c] = "f1_"
	c = c+1
endif 
if f2
	measures$ [c] = "f2_"
	c = c+1
endif 
if f3
	measures$ [c] = "f3_"
	c = c+1
endif 
if f0
	measures$ [c] = "f0_" ; last one doesn't have a + 1
	c = c+1
endif 

if c <> nMeasures + 1 ; because you can't just make f0 not add, it might not actually be selected so c might get +1 on it anyway
	exit Something went wrong with your number of measures and the fields in the measure array
endif

# If you created the not-blank table then get rid of the dummy column 
if newlycreatedtable
	selectObject (dataTable)
	do ("Remove column...", dummyColName$) 
endif 


## Using different columns for each measure because I don't want to deal with "cell arrays"
# Define number of slices (why did you want this? it's already in the UI) 
# nSlices = 4

for i from 1 to nMeasures ; outer loop is the measures so you get them all together 
	for k from 1 to nSlices ; inner loop is number of slices
		slice$ = string$ (k)
		newfield$ = measures$ [i] + slice$ 
		do ("Append column...", newfield$) 
	endfor
endfor

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# STEP 4
# Data addition
# 
# File loop 
for ifile from 1 to nFiles
	selectObject (stringsFiles)
	fileName$ = Get string... ifile
	@split ("_", fileName$)
	blockTag$ = split.array$[2]
	endofTag$ = split.array$[3] ; this will have both trial and .wav, eg 01.wav

	# Getting trial number from the 01.wav
	@split (".", endofTag$)
	trial = number (split.array$[1])

	@split (".", fileName$)
	trialTag$ = split.array$[1]
	tgFilename$ = trialTag$ + ".TextGrid"
	soundFilename$ = trialTag$ + ".wav" 
	pitchFilename$ = trialTag$ + ".Pitch"

	block = number (blockTag$)

	# Do something only if the block is between the start and end specified in UI
	if block == startFromBlock and trial >= startFromTrial or block > startFromBlock and block <= lastBlock
		tableRow = ((block - 1) * nTrials) + trial ; so you can start in the middle and the row index will be right
	
		## Things you do for every run, regardless of what measures you're doing ; --------------------------------------------------------------
		# Open the sound file and textgrid
		soundObject = do ("Read from file...", dataDir$ + soundFilename$)
		tgObject = do ("Read from file...", dataDir$ + tgFilename$)

		# Work with the textgrid
		selectObject (tgObject)
		nSegInts = do ("Get number of intervals...", segTier) ; includes blank intervals
		# vowelInt = nSegInts - 1 ; vowel is always the second to last interval 

		# Get start and end times of vowel 
		vowelStart = do ("Get start time of interval...", segTier, vowelInt)
		vowelEnd = do ("Get end time of interval...", segTier, vowelInt)
		vowelDur = vowelEnd - vowelStart

		# Extract just the vowel 
		selectObject (soundObject)
		vowelSoundObject = do ("Extract part...", vowelStart, vowelEnd, "rectangular", 1, "yes") ; yes is to preserve times, so you can use the same times in extract and in full		

		# Make intervals (if you only have one, you'll just have one interval as big as the whole vowel) 
		intervalDur = vowelDur / nSlices

		## Objects that shouldn't be created for every slice -------------------------------------------------------------------------------------
		# Extra objects needed for jitter/shimmer 
		# Pitch object (need for jitter, shimmer, spectral tilt, and F0)
		if f0 + jitter + shimmer + specTilt > 0
			if fileReadable (dataDir$ + pitchFilename$) 
				pitchObject = do ("Read from file...", dataDir$ + pitchFilename$)
			else
				selectObject (soundFile)
				pitchObjectRough = do ("To Pitch...", timeStep, minHz, maxHz)
				pitchObject = do ("Smooth...", 10) 
			endif ; making pitchObject if

			# Pulses object (need for voice report for jitter/shimmer)
			if jitter + shimmer > 0
				selectObject (soundObject)				
				pulseObject = do ("To PointProcess (periodic, cc)...", minHz, maxHz)
			endif ; pulse object if
		endif ; pitch object if 

		# Intensity object (for amplitude)
		if amplitude
			selectObject (soundObject)
			intensityObject = do ("To Intensity...", minHz, timeStep, "yes") ; yes is subtract mean
		endif

		# Harmonics object (for hnr) 
		if hnr
			selectObject (vowelSoundObject)
			harmonicsObject = do ("To Harmonicity (cc)...", timeStep, minHz, 0.1, 4.5) ; 0.1 and 4.5 are the default silence thresholds and periods per window
		endif

		## Now make measurements in each slice and add them to the table ; -----------------------------------------------------------------------
		for islice from 1 to nSlices
			# Slice beginnings 
			if islice = 1
				intervalStart = vowelStart ; doing this so I don't get errors being out of range
			else
				intervalStart = vowelStart + (intervalDur * (islice - 1))
			endif
			# Slice ends
			if islice = nSlices
				intervalEnd = vowelEnd ; doing this so I don't get errors being out of range
			else
				intervalEnd = vowelStart + (intervalDur * islice)
			endif 

			## Measure-specific if statements ----------------------------------------------------------------------------------------------------
			# Spectral tilt and F0
			if specTilt + f0 > 0 

				selectObject (pitchObject)
				meanF0 = do ("Get mean...", intervalStart, intervalEnd, "Hertz") ; "hertz" is the unit 
				
				if f0 
					# Add to table
					selectObject (dataTable) 
					do ("Set numeric value...", ifile, "f0_" + string$ (islice), meanF0)
				endif ; F0 if 

				if specTilt 
					if meanF0 = undefined ; can't get any harmonics if the F0 is undefined (praat only gives undefined if it is ALL undefined)
						meanSpecTilt = undefined
						ltasObject = 0
						intervalSoundObject = 0 						
					else
						# Make a long-term average spectrum (Ltas). Then use the F0 (H1) to get H1 and H2 areas, and find the max inside there, then subtract
						selectObject (soundObject)
						intervalSoundObject = do ("Extract part...", intervalStart, intervalEnd, "rectangular", 1, "yes") ; still preserving times
						selectObject (intervalSoundObject)
						ltasObject = do ("To Ltas...", 50) ; 50 is the bandwidth, gotten from DiCanio

						# Reference F0 mean for H1, make reasonable intervals to find the max
						h1Hz = meanF0 
						h1Buffer = h1Hz / 10
						h1LeftBound = h1Hz - h1Buffer
						h1RightBound = h1Hz + h1Buffer

						# Double that for H2 , make reasonable intervals to find the max
						h2Hz = meanF0 * 2
						h2Buffer = h2Hz / 10
						h2LeftBound = h2Hz - h2Buffer
						h2RightBound = h2Hz + h2Buffer

						# Get measures of H1 and H2 dB
						selectObject (ltasObject)
						h1dB = do ("Get maximum...", h1LeftBound, h1RightBound, "None") ; none is the interpolation
						h2dB = do ("Get minimum...", h2LeftBound, h2RightBound, "None")
						meanSpecTilt = h1dB - h2dB 
					endif ; if F0 is undefined if	
		
					# Add to table
					selectObject (dataTable)
					do ("Set numeric value...", ifile, "specTilt_" + string$ (islice), meanSpecTilt) 	
			endif ; spectilt and f0 if

			# Jitter and shimmer
			if jitter + shimmer > 0 
				selectObject (soundObject, pulseObject, pitchObject)
				voiceReport$ = Voice report: intervalStart, intervalEnd, minHz, maxHz, 1.3, 1.6, 0.03, 0.45 ; last numbers are defaults

				if jitter
					meanJitter = extractNumber (voiceReport$, "Jitter (local): ")
	
					# Add to table
					selectObject (dataTable)
					do ("Set numeric value...", ifile, "jitter_" + string$ (islice), meanJitter)
				endif 

				if shimmer
					meanShimmer = extractNumber (voiceReport$, "Shimmer (local): ") 

					# Add to table
					selectObject (dataTable)
					do ("Set numeric value...", ifile, "shimmer_" + string$ (islice), meanShimmer) 	
				endif
			
			endif ; shimmer/jitter if		

			# HNR
			if hnr
				# get mean HNR in interval 
				selectObject (harmonicsObject)				
				meanHNR = do ("Get mean...", intervalStart, intervalEnd)

				# Add to table
				selectObject (dataTable)
				do ("Set numeric value...", ifile, "hnr_" + string$ (islice), meanHNR)
			endif

			# Amplitude
			if amplitude
				selectObject (intensityObject)
				meanIntensity = do ("Get mean...", intervalStart, intervalEnd, "energy") ; energy is the mode of averaging

				# Add to table
				selectObject (dataTable)
				do ("Set numeric value...", ifile, "amp_" + string$ (islice), meanIntensity)
			endif 

			# All formants together
			if f1 + f2 + f3 > 0 
				selectObject (vowelSoundObject)
				formantObject = do ("To Formant (burg)...", timeStep, 5, 5500, 0.025, 50) ; everything except timeStep is default

				# Get measures, add to table 
				if f1
					selectObject (formantObject)
					meanF1 = do ("Get mean...", 1, intervalStart, intervalEnd, "Hertz") ; 1 is the formant, Hz is the measure
					selectObject (dataTable)
					do ("Set numeric value...", ifile, "f1_" + string$ (islice), meanF1)
				endif

				if f2
					selectObject (formantObject)
					meanF2 = do ("Get mean...", 2, intervalStart, intervalEnd, "Hertz") ; 1 is the formant, Hz is the measure
					selectObject (dataTable)
					do ("Set numeric value...", ifile, "f2_" + string$ (islice), meanF2)
				endif 

				if f3 
					selectObject (formantObject)
					meanF3 = do ("Get mean...", 3, intervalStart, intervalEnd, "Hertz") ; 1 is the formant, Hz is the measure
					selectObject (dataTable)
					do ("Set numeric value...", ifile, "f3_" + string$ (islice), meanF3)
				endif 
			endif ; formants if 

		# Remove objects that were created for the intervals, if they exist
		if variableExists ("formantObject")
			selectObject (formantObject)
			Remove
		endif
 
		# These two have to both exist AND be non-zero (because they may or may not be created, depending on if F0 was NaN or not; 
		# have to be set to 0 if F0 was nan because it has to be updated otherwise Praat tries to delete them twice )
		if variableExists ("intervalSoundObject")
			if intervalSoundObject 
				selectObject (intervalSoundObject)
				Remove
			endif
		endif 

		if variableExists ("ltasObject")
			if ltasObject
				selectObject (ltasObject)
				Remove
			endif 
		endif

		endfor ; interval slices for

	endif ; block selection if 

	writeInfoLine ("Completed block " + string$ (block) + ", trial " + string$ (trial))

	# Remove created objects
	selectObject (soundObject, tgObject, vowelSoundObject) 
	Remove

	if variableExists ("pitchObject")
		selectObject (pitchObject)
		Remove
	endif

	if variableExists ("pulseObject")
		selectObject (pulseObject)
		Remove
	endif

	if variableExists ("intensityObject")
		selectObject (intensityObject)
		Remove
	endif

	if variableExists ("harmonicsObject")
		selectObject (harmonicsObject)
		Remove
	endif
# pause ; *********************** debugging pause 

endfor ; file loop for 

selectObject (dataTable)
do ("Save as comma-separated file...", dataDir$ + subj$ + "_tgrids_withspectral.csv")

appendInfoLine ("all done") 


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

