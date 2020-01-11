###########################################################################################
#
# Get pitch objects for all trials (fourth step of PKDL studies)
#
# Script to get pitch objects for all the trials of a participant 
#
# Files needed: 
# 1. Sound files 
# 
# Files generated: 
# 1. Pitch object for each trial (.Pitch) 
#
# Process:
# 1. Script will open a UI window to input data directory info
# ----- Can either put in a higher directory or the directory with all the sound files
# ----- Enter participant tag (would be nice to enter if just one, leave blank if doing all)
# ----- If save directory is the same as data dir
# ----- If male or female (for pitch processing min/max)
# 2. Find all soundfiles that match pattern: subj + [0-9][0-9]_[0-9][0-9]
# 3. Loop through (small pause to see quickly if something is going wrong) and save to directory expDir + subj
#
# For this script the save/file pattern is: 
# ---- Participant tag: [A-Z][A-Z][0-9][0-9]
# ---- Blocks and trials are all two digits (i.e., 01, 08)
# ---- eg AB01_01_03 (participant AB01, block 1, trial 3) 
#
#
# Last edited March 21, 2017 Robin Karlin
#
###########################################################################################

## UI for customizing for your participant/computer: can change this basic path to be specific to your computer
# For some reason all variables, string or not, are plain (i.e., string variables do not have $)
form Choose path and participant
	comment Experiment directory path (with filesep at end)
	text expDir D:\Users\viria\Documents\00 Data\07 BRG (Burmese RegistroGenesis)\Followup\
	# Format of this is "type of entry" "variable name" "auto fill" 

	comment Handle of participant. Leave blank to do all participants; can also do all except one with ^(AB01) 
	text subj CP01-iii

	comment Data folder format 
	text dataFolderPattern ([0-9][0-9]\.[0-9][0-9])

	comment Rewrite current Pitch files? 
	boolean rewriteYN 0

	comment Start from block
	integer startFrom 1

	comment End after block
	integer numberOfBlocks 20

	comment Lowest possible Hz
	integer pitchParamFloor 100

	comment Highest possible Hz
	integer pitchParamCeiling 300

	#comment Gender of participant
	#optionmenu gender: 2
	#option Male
	#option Female
	#option Both

endform

## Fix the original path if you didn't give a filesep at the end
dirLastchar$ = right$ (expDir$, 1)
if dirLastchar$ != "\" and dirLastchar$ != "/"
	expDir$ = expDir$ + "\"
endif

## Automatically change hz ceiling/floor for pitch 
#if gender = 1
#	pitchParamFloor = 50
#	pitchParamCeiling = 230 ; for males
#elsif gender = 2
#	pitchParamFloor = 110
#	pitchParamCeiling = 360 ; for females
#elsif gender = 3
#	pitchParamFloor = 50
#	pitchParamCeiling = 400 ; if you're doing a lot and they're 
#endif


# And smoothing param
	pitchParamSmooth = 10 ; (default)
# And time step: This is 0.005 because the sampling rate of articulatory data is 200 fps. This should be good for the majority of pitch ranges  
	pitchParamStep = 0.005 

## For "overwrite all for participant" option
originalRewrite = rewriteYN

## Establishes regexp pattern for the participants in your study (one modification in-script instead of several) 
subjPattern$ = "[A-Z][A-Z][0-9][0-9]" ; "^[A-Z][A-Z][0-9][0-9]$" 

## Either do all participants, or just one (if it's blank, all the subdirs will be listed)
stringsSubdirs = do ("Create Strings as directory list...", "subdirs", expDir$)
nSubdirs = Get number of strings

if !index_regex (subj$, subjPattern$)
	# this lists all subdirectories, loops through those strings, and compares them with the regex.
	for idir from 1 to nSubdirs
		selectObject (stringsSubdirs)
		subdir$ = Get string... idir
	
		# If match, then append to the bottom;
		if index_regex (subdir$, subjPattern$) 
			# If the subj is either blank OR a negative (do all participants except SM02) 
			if !index_regex (subdir$, subj$) or subj$ = ""
				do ("Insert string...", 0, subdir$)
			endif
		endif

	endfor

else
	# If it's just one person in the subj$, then just add their name to the bottom 
	do ("Insert string...", 0, subj$)
endif

# Now that all the good ones are appended to the bottom, remove the original list (remove first position nSubdirs times)
for idir from 1 to nSubdirs
	do ("Remove string...", 1)
endfor

## Time to do the actual pitch track loop
# Get number of participants 
selectObject (stringsSubdirs)
nSubj = Get number of strings

# Set the neverRewrite parameter: neverRewrite 1 means you never, never, ever rewrite (doesn't change for Pp)
# neverRewrite 0 means it's still an option to rewrite (you'll be asked once if rewriting comes up) 
# This has to be here (before the subj loop) so it doesn't reset for every participant
neverRewrite = 0 

# Loop for participants
for isubj from 1 to nSubj

	# Get the participant
	selectObject (stringsSubdirs)
	subj$ = Get string... isubj
	subjDir$ = expDir$ + subj$ + "\"

	# Reset the rewrite parameter if you had only wanted to rewrite all for one participant
	rewriteYN = originalRewrite

#######
if index_regex (expDir$, "Articulatory")
# I have an extra level: SM02's folder doesn't directly contain the soundfiles 
	stringsSubsubdirs = do ("Create Strings as directory list...", "subsubdirs", subjDir$)
	nSubsubdirs = Get number of strings

	for isubsub from 1 to nSubsubdirs
		selectObject (stringsSubsubdirs)
		subsubdir$ = Get string... isubsub
	
		# If match dataFolderPattern, then append to the bottom;
		if index_regex (subsubdir$, dataFolderPattern$) 
			do ("Insert string...", 0, subsubdir$)
		endif
	endfor

	for isubsub from 1 to nSubsubdirs
		do ("Remove string...", 1)
	endfor

	selectObject (stringsSubsubdirs)
	dataName$ = Get string... 1

#elsif index_regex (expDir$, "STC")
else 
	dataName$ = subj$

endif

# Back on track
#######	

	# Make a list of the sound files in the data directory 
	dataDir$ = subjDir$ + dataName$ + "\"
	stringsFiles = do ("Create Strings as file list...", "files", dataDir$ + subj$ + "*.wav")
	nFiles = Get number of strings

	# File loop 
	for ifile from 1 to nFiles
		selectObject (stringsFiles)
		fileName$ = Get string... ifile
		@split ("_", fileName$)
		blockTag$ = split.array$[2]
		endofTag$ = split.array$[3] ; this will have both trial and .wav, eg 01.wav

		@split (".", fileName$)
		trialTag$ = split.array$[1]

		block = number (blockTag$)

		# Do something only if the block is between the start and end specified in UI
		if block >= startFrom and block <= numberOfBlocks
			soundFile = do ("Read from file...", dataDir$ + fileName$)
			selectObject (soundFile)
			roughPitch = do ("To Pitch...", pitchParamStep, pitchParamFloor, pitchParamCeiling)
			smoothPitch = do ("Smooth...", pitchParamSmooth)

			# Make save name
			savePitchName$ = trialTag$ + ".Pitch"

			# Save 
			if fileReadable (dataDir$ + savePitchName$) and rewriteYN = 0 and neverRewrite = 0
				beginPause ("This file, " + savePitchName$ + ", already exists! Do you want to overwrite the existing .Pitch file?")
				comment ("Never: Don't ever rewrite")
				comment ("One file: Just overwrite this file")
				comment ("Participant: overwrite all for participant") 
				comment ("All: overwrite all files for all participants")
				click = endPause ("Never", "One file", "Participant", "All", 1)

				if click = 1 ; never overwrite
					neverRewrite = 1

				elsif click = 2 ; one file
					selectObject (smoothPitch)
					do ("Save as text file...", dataDir$ + savePitchName$)

				elsif click = 3 ; overwrite for whole participant
					selectObject (smoothPitch)
					do ("Save as text file...", dataDir$ + savePitchName$)
					rewriteYN = 1

				elsif click = 4 ; changed my mind, want to rewrite all the time
					selectObject (smoothPitch)
					do ("Save as text file...", dataDir$ + savePitchName$)
					rewriteYN = 1
					originalRewrite = 1					
					
				endif

			elsif fileReadable (dataDir$ + savePitchName$) and neverRewrite = 1 ; if you in fact never want to overwrite, just confirms
				neverRewrite = 1

			elsif fileReadable (dataDir$ + savePitchName$) and rewriteYN = 1 ; if the file exists and you said you wanted to rewrite
				selectObject (smoothPitch)
				do ("Save as text file...", dataDir$ + savePitchName$)				
			
			elsif !fileReadable (dataDir$ + savePitchName$)
				selectObject (smoothPitch)
				do ("Save as text file...", dataDir$ + savePitchName$)

			else
				exitScript: "Your logic went wrong somewhere in the if/then statements on when you should overwrite" 

			endif
		
			# Remove leftover pitch object and sound
			selectObject (roughPitch)
			plusObject (soundFile)
			plusObject (smoothPitch) 
			do ("Remove")
			
		endif
	endfor ; file loop 
	
	# Clean up strings files object
	selectObject (stringsFiles)
	do ("Remove") 

endfor ; subj loop 

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