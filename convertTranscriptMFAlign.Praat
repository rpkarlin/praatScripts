#############################################################################################
# 
# Script to prepare TextGrids for forced alignment using the Montreal Forced Aligner, using 
# times already provided in alternative segmentation
#
# Files needed:
# 1. Sound files for each trial (will have to figure out what to do with the few errors
# where the spacebar was pressed too soon and advanced the thing) 
# 2. A text file with only the information for what was said in each trial
# ----- Also it shouldn't have a header
# 3. Original (if exists)
# 
# Files created: 
# 1. .TextGrid for each trial with the sentence in all caps
# 
# Process:
# 1. Script will read in the participant's .tsv file with the trial information
# 2. Script will find list of all files for a participant, open one at a time
# 3. Check if a .TextGrid already exists, opens if so, creates if no
# ----- Will have just one tier (because only one speaker being marked), subj tag as name
# 4. Open with sound file, view and edit, pause
# ----- Mark off the interval that you want to be labeled if there isn't already a textgrid
# ----- OR just have the script make the interval automatically (if your sound file is trimmed to only contain the trial speech, no extraneous words) 
# ----- If there is one, then the intervals are automatically computed (100 ms buffer around existing boundary)
# ----- Hit continue
# 5. Praat will read the correct line (will use the loop count variable) from the text file, 
# then put that text into the second interval 
# ----- Save TextGrid... currently just going to copy the name of the sound file, not sure if 
# there needs to be some special filename for the aligner to look for
# 
# Last edited 9/13/2017 Robin Karlin
#
#############################################################################################

## UI for customizing for your participant/computer: can change this basic path to be specific to your computer
# For some reason all variables, string or not, are plain (i.e., string variables do not have $)
form Choose path and participant
	comment Experiment directory path (with filesep at end)
	text expDir D:\Users\viria\Documents\MATLAB\03 PKDL\TTC\Acoustic\
	# Format of this is "type of entry" "variable name" "auto fill" 

	comment Handle of participant. Leave blank to do all participants; can also do all except one with ^(AB01) 
	text subj SM01

	comment Data folder format 
	text dataFolderPattern ([0-9][0-9]\.[0-9][0-9])

	comment Rewrite current files? 
	boolean rewriteYN 0

	comment Start from block
	integer startFrom 1

	comment End after block
	integer numberOfBlocks 20

	comment Number of trials per block
	integer numberOfTrials 32

	comment Auto label?
	boolean autoLabel 0

endform

## Fix the original path if you didn't give a filesep at the end
dirLastchar$ = right$ (expDir$, 1)
if dirLastchar$ != "\" and dirLastchar$ != "/"
	expDir$ = expDir$ + "\"
endif

## For "overwrite all for participant" option
originalRewrite = rewriteYN

## Establishes regexp pattern for the participants in your study (one modification in-script instead of several) 
subjPattern$ = "^[A-Z][A-Z][0-9][0-9]$" 

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

############ End setup 

## Time to do the actual object loop
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
# I have an extra level: SM02's folder doesn't directly contain the soundfiles 
if index_regex (expDir$, "Articulatory")
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

elsif !index_regex (expDir$, "Articulatory")
	dataName$ = subj$

endif

# Back on track
#######	

	# Make a list of the sound files in the data directory 
	dataDir$ = subjDir$ + dataName$ + "\"
	stringsFiles = do ("Create Strings as file list...", "files", dataDir$ + subj$ + "*.wav")
	nFiles = Get number of strings

	# ********************
	saveDir$ = dataDir$ + subj$ + "_Pre-align\"
	system mkdir saveDir$
	# ********************

	# *******************************************
	stringsWords = do ("Read Strings from raw text file...", dataDir$ + subj$ + "_trialResponses.csv")
	selectObject (stringsWords)
	nWords = do ("Get number of strings") 
	if nFiles != nWords and nFiles != 0
#		exitScript: "You don't have the same number of sound files as trial transcripts"
		pause You don't have the same number of sound files as trial transcripts. Click continue if this is okay. 
#			comment ("If this is okay, click continue")
	endif
	# </>*******************************************

	# File loop 
	for ifile from 1 to nFiles
		selectObject (stringsFiles)
		fileName$ = Get string... ifile
		@split ("_", fileName$)
		blockTag$ = split.array$[2]
		endofTag$ = split.array$[3] ; this will have both trial and .wav, eg 01.wav

		@split (".",endofTag$)
		trialNoTag$ = split.array$[1] ; this is just the trial number

		@split (".", fileName$)
		trialTag$ = split.array$[1] ; yeah this is SM01_01_01, not just the trial number

		block = number (blockTag$)
		trial = number (trialNoTag$)

		# Do something only if the block is between the start and end specified in UI

		# ******************************* This is the special thing that would be changed for each modification of the UI skeleton

		selectObject (stringsWords)
		stringIndex = ((block - 1) * numberOfTrials) + trial ; this makes it such that you don't have to have (or label) everything
		# i.e. if you are missing some sound files, you can still get the right words in (without altering the trial csv) 
		trialWords$ = Get string... stringIndex

		if block >= startFrom and block <= numberOfBlocks
			properNIntervals = 6 ; if some files are hand-segmented already, this is how many words there are supposed to be + 2 (for silence on either end)
			soundFile = do ("Read from file...", dataDir$ + fileName$)
			selectObject (soundFile)

			startSoundTime = do ("Get start time") 
			endSoundTime = do ("Get end time")

			# Make save name
			saveTGName$ = trialTag$ + ".TextGrid"

			selectObject (soundFile)
			newTextGrid = do ("To TextGrid...", subj$, "")

			# Check if a textgrid already exists; check number of intervals
			if fileReadable (dataDir$ + saveTGName$)
				origTextGrid = do ("Read from file...", dataDir$ + saveTGName$)
				selectObject (origTextGrid)
				nIntervals = do ("Get number of intervals...", 1)

				# Get start/end points if intervals is 6 (or whatever) 
				if nIntervals = properNIntervals
					selectObject (origTextGrid) 
					uttStart = do ("Get end time of interval...", 1, 1) ; tier, interval
					newUttStart = uttStart - 0.1
					uttEnd = do ("Get start time of interval...", 1, nIntervals)
					newUttEnd = uttEnd + 0.1

					# Make sure this won't crash (if I cut the sound file really short) 
					if newUttStart < startSoundTime or newUttEnd > endSoundTime
						selectObject (newTextGrid)
						plusObject (soundFile)
						View & Edit
						beginPause ("Mark interval of participant speech")
						comment ("If speech is not fluent, click Fix transcript")
						clickTranscript = endPause ("Continue to next trial", "Fix transcript", 1)

					else
						selectObject (newTextGrid)
						do ("Insert boundary...", 1, newUttStart)
						do ("Insert boundary...", 1, newUttEnd)
						clickTranscript = 0

					endif
				
				else
					selectObject (newTextGrid)
					plusObject (soundFile)
					View & Edit
					beginPause ("Mark interval of participant speech")
						comment ("If speech is not fluent, click Fix transcript")
					clickTranscript = endPause ("Continue to next trial", "Fix transcript", 1)

					minusObject (soundFile)
					selectObject (newTextGrid)
					do ("Set interval text...", 1, 2, trialWords$)

					# If there was some specific problem with disfluency in the soundfile, will let you fix 
					if clickTranscript = 2
						pause Fix transcript, then click Continue
					endif	
						
				endif

			else ; if there isn't already a file
				origTextGrid = 0
				nIntervals = 0

				if autoLabel = 1 ; if you want it to just go without you marking it
					selectObject (newTextGrid)
					do ("Insert boundary...", 1, 0.01)
					do ("Insert boundary...", 1, endSoundTime - 0.01)
					do ("Set interval text...", 1, 2, trialWords$)

				else
					selectObject (newTextGrid)
					plusObject (soundFile)
					View & Edit
					beginPause ("Mark interval of participant speech")
						comment ("If speech is not fluent, click Fix transcript")
					clickTranscript = endPause ("Continue to next trial", "Fix transcript", 1)

					minusObject (soundFile)
					selectObject (newTextGrid)
					do ("Set interval text...", 1, 2, trialWords$)

					# If there was some specific problem with disfluency in the soundfile, will let you fix 
					if clickTranscript = 2
						pause Fix transcript, then click Continue
					endif	

				endif 

			endif

			writeInfoLine (nIntervals)



		# </>******************************* All specific procedures contained between star lines

			# Save 
			if fileReadable (saveDir$ + saveTGName$) and rewriteYN = 0 and neverRewrite = 0
				beginPause ("This file, " + saveTGName$ + ", already exists! Do you want to overwrite the existing .TextGrid file?") ; ****
				comment ("Never: Don't ever rewrite")
				comment ("One file: Just overwrite this file")
				comment ("Participant: overwrite all for participant") 
				comment ("All: overwrite all files for all participants")
				click = endPause ("Never", "One file", "Participant", "All", 1)

				if click = 1 ; never overwrite
					neverRewrite = 1

				elsif click = 2 ; one file
					selectObject (newTextGrid) ; ******
					do ("Save as text file...", saveDir$ + saveTGName$)

				elsif click = 3 ; overwrite for whole participant
					selectObject (newTextGrid) ; *******
					do ("Save as text file...", saveDir$ + saveTGName$)
					rewriteYN = 1

				elsif click = 4 ; changed my mind, want to rewrite all the time
					selectObject (newTextGrid) ; *******
					do ("Save as text file...", saveDir$ + saveTGName$)
					rewriteYN = 1
					originalRewrite = 1					
					
				endif

			elsif fileReadable (saveDir$ + saveTGName$) and neverRewrite = 1 ; if you in fact never want to overwrite, just confirms
				neverRewrite = 1

			elsif fileReadable (saveDir$ + saveTGName$) and rewriteYN = 1 ; if the file exists and you said you wanted to rewrite
				selectObject (newTextGrid)
				do ("Save as text file...", saveDir$ + saveTGName$)				
			
			elsif !fileReadable (saveDir$ + saveTGName$)
				selectObject (newTextGrid)
				do ("Save as text file...", saveDir$ + saveTGName$)

			else
				exitScript: "Your logic went wrong somewhere in the if/then statements on when you should overwrite" 

			endif
		
			# Remove leftover pitch object and sound
			selectObject (soundFile)
			plusObject (newTextGrid) 
			if origTextGrid
				plusObject (origTextGrid)
			endif
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

