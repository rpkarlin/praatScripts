################################################################################################################################################################################################
#
# Script to open up MFA-aligned things and adjust them by hand
# 
# Files needed:
# 1. Sound file
# 2. Corresponding MFAligned textgrid
# 3. Pre-MFAlignment textgrid (utterance sized)
# 
# Files created: 
# 1. New textgrid
#
# Data directory structure: 
# Top level: Subject folder, which has a data folder in it (.../SM01/SM01/)
# --- In that data folder, the sound files, and any hand-segmented TGs that already exist: also the directory things are saved to 
# ------- Subfolder: the directory with MFAligned (not pre-alignment, but post-alignment) 
#
#
# Process: 
# 1. Create list of files to be adjusted
# 2. Open sound file and MFA textgrid
# 3. Open pre-alignment textgrid
# 4. Get words from pre-alignment textgrid 
# 5. Find the numbers of the intervals in WORD (subj - words) tier that match those words
# 6. Find the numbers of the intervals in SEG (subj - phones) tier that: 
# ---- a. starting point is the same as the starting point of the word
# ---- b. ending point is the same as the ending point of the word
# 7. Create new TG (if one doesn't exist already; will have to separate the textgrids into different directories) with two tiers: word/seg
# 8. Populate seg with the MFAlign phones tier
# 9. View and Edit sound and new TG together, pause and move phone boundaries around
# 10. Continue; word boundaries will be inserted based on where the phone boundaries are (step 6 specifies which intervals determine this)
# 11. Words automatically populated
# 12. sil turned into blanks? 
# 13. save 
# 14. Profit? 
# 15. Praafit? 
#
# Note: put a 1 in the very first interval in "word" if it needs to be marked as error
#
# Last edited April 12, 2017 by Robin Karlin
#
#
################################################################################################################################################################################################

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## UI for customizing for your participant/computer: can change this basic path to be specific to your computer
# For some reason all variables, string or not, are plain (i.e., string variables do not have $)
form Choose path and participant
	comment Experiment directory path (with filesep at end)
	text expDir D:\Users\viria\Documents\00 Data\05 STC (Serbian Tone Coordination)\STC3\Belgrade3\
	# Format of this is "type of entry" "variable name" "auto fill" 

	comment Handle of participant. Leave blank to do all participants; can also do all except one with ^(AB01) 
	text subj AP03-iii

	comment Tag of directory with MFAligned TextGrids (no subj) 
	text mfalignedTag _MFAligned

	comment Tag of directory to save realigned TextGrids (leave blank if just subj data folder)
	text newTgTag 

	comment Rewrite current TextGrid files? 
	boolean rewriteYN 0

	comment Start from block
	integer startFrom 1

	comment End after block
	integer numberOfBlocks 10

	comment Tier that words are on (number)
	integer wordTier 1

	comment Tier that segs are on (number)
	integer segTier 2

endform

## Fix the original path if you didn't give a filesep at the end
dirLastchar$ = right$ (expDir$, 1)
if dirLastchar$ != "\" and dirLastchar$ != "/"
	expDir$ = expDir$ + "\"
endif

indexSTC = index (expDir$,"STC")
indexTTC = index (expDir$,"TTC")

# So I can do different zooming (determines which project I'm working on, according to tags in directory structure) 
if indexSTC > 0
	project$ = "STC"
elsif indexTTC > 0
	project$ = "TTC"
else
	project$ = "other"
endif

## For "overwrite all for participant" option
originalRewrite = rewriteYN

## Establishes regexp pattern for the participants in your study (one modification in-script instead of several) 
subjPattern$ = "[A-Z][A-Z][0-9][0-9]" 

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

# </>~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Time to do the actual textgrid loop
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

elsif index_regex (expDir$, "Acoustic") 
	dataName$ = subj$

elsif index_regex (expDir$, "STC")
	dataName$ = subj$

else 
	dataName$ = subj$

endif

# Back on track
#######	

	# Define a crapload of directories
	dataDir$ = subjDir$ + dataName$ + "\"	
	saveDir$ = dataDir$ + newTgTag$

		## Fix the original path if you didn't give a filesep at the end
		dirLastchar$ = right$ (saveDir$, 1)
		if dirLastchar$ != "\" and dirLastchar$ != "/"
			expDir$ = expDir$ + "\"
		endif

	mfalignedDir$ = dataDir$ + subj$ + mfalignedTag$ + "\"

	# Make a list of the sound files in the data directory 
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
		tgFilename$ = trialTag$ + ".TextGrid"
		soundFilename$ = trialTag$ + ".wav" 

		block = number (blockTag$)


		# *******************************************************************************************************
		# Do something only if the block is between the start and end specified in UI
		if block >= startFrom and block <= numberOfBlocks
			soundFile = do ("Read from file...", dataDir$ + soundFilename$)
			
			# Check if a hand-segmented file already exists
			# If it does, just make everything uppercase so that it's all uniform
			if fileReadable (dataDir$ + tgFilename$)
				handsegTg = do ("Read from file...", dataDir$ + tgFilename$)
				mfaTg = 0
				selectObject (handsegTg) 
				plusObject (soundFile)
				View & Edit
				pause Verify that things are right

			
			# If not, create 
			else
				mfaTg = do ("Read from file...", mfalignedDir$ + tgFilename$)
				# For automatically changing daj mi to dajmi
				selectObject (mfaTg)
				thirdWord$ = Get label of interval: 1, 3

				# Get interval numbers 
				selectObject (mfaTg) 
				mfaTgTable = do ("Down to Table...", "no", 6, "yes", "no")
				selectObject (mfaTgTable)
			
				# Redefining subj$ for the ones that have -ii on them (because the row extraction uses only eg BG01, not BG01-ii
				# Doesn't matter for the ones that are only 4, since they'll automatically just be 4 anyway (so leftmost four characters are the whole string)
				
				extractPattern$ = left$ (subj$, 4) + " - words"
#				extractPattern$ = "word"
				extractCondition$ = "self$[""tier""]=" + "extractPattern$"
				prunedMfaTable = do ("Extract rows where...", extractCondition$)


				selectObject (prunedMfaTable)
				nRows = do ("Get number of rows")
				
				if project$ = "STC"
					startRow = Search column: "text", "dajmi"
					endRow = Search column: "text", "molim"
				elsif project$ = "TTC"
					endRow = Search column: "text", "diidii"
					startRow = Search column: "text", "khun"
					if startRow = 0 
						startRow = Search column: "text", "naang"
					endif
       				else
                    			endRow = 0
         			        startRow = 0
				endif

				# Loop through number of words (rows), get number of interval in the other tier that matches the min and max
				for irow from 1 to nRows
					selectObject (prunedMfaTable)
					# Getting mins, maxes, adding a buffer because I'm paranoid (and because I'm not sure how edges work) 
					irowMin = do ("Get value...", irow, "tmin")
					irowMin = irowMin + 0.001
					irowMax = do ("Get value...", irow, "tmax")
					irowMax = irowMax - 0.001
					irowWord$ = Get value: irow, "text"

					# Setting up zooming windows 
					if irow = startRow
						startSelect = irowMin - 0.100
					elsif startRow = 0 
						startSelect = 0.100
					endif

					if irow = endRow
						endSelect = irowMin + 0.100
					elsif endRow = 0 and irow = nRows
						endSelect = irowMax + 0.100
					endif

					# This makes two arrays with as many elements as words
					selectObject (mfaTg)
					wordStartSegInterval[irow] = do ("Get interval at time...", segTier, irowMin)
					wordEndSegInterval[irow] = do ("Get interval at time...", segTier, irowMax)
					wordInterval[irow] = do ("Get interval at time...", wordTier, irowMin)
					wordgetter = wordInterval[irow]
					word$[irow] = Get label of interval: wordTier, wordInterval[irow] ; I don't know why but I have to use this : formatting here 

				endfor ; row for
					
				# set up seg tier by extracting phones tier 	
				selectObject (mfaTg)
				handsegTg = do ("Extract one tier...", segTier)
				selectObject (handsegTg)
				tgName$ = selected$ ()
				do ("Set tier name...", 1, "seg")
				do ("Insert interval tier...", 1, "word")
			
				# Fix by hand
				selectObject (handsegTg)
				plusObject (soundFile)
				do ("View & Edit")

editor 'tgName$'
				do ("Select...", startSelect, endSelect)
				do ("Zoom to selection")
endeditor

				beginPause ("Fix segment boundaries (don't do anything to word tier)")
					comment ("If speech is not fluent, click Fix transcript")
				clickTranscript = endPause ("Continue to next trial", "Fix transcript", 1)

				# re-adjust word boundaries automatically
				for irow from 1 to nRows
					selectObject (handsegTg)
					newWordStart = do ("Get start time of interval...", segTier, wordStartSegInterval[irow])
					newWordEnd = do ("Get end time of interval...", segTier, wordEndSegInterval[irow])

					do ("Insert boundary...", wordTier, newWordStart)

					if irow = nRows
						newWordEnd = do ("Get end time of interval...", segTier, wordEndSegInterval[irow])
						do ("Insert boundary...", wordTier, newWordEnd)

					else ; find nextWordStart (if irow = nrows this would throw an error as the index goes beyond array size)
						nextWordIx = irow+1;
						nextWordStart = do ("Get start time of interval...", segTier, wordStartSegInterval[nextWordIx])

						# if the current word's end point is before the start point of the next word, then insert that boundary too
						if newWordEnd < nextWordStart ; 
							do ("Insert boundary...", wordTier, newWordEnd)
						
						endif
						
					endif

				endfor ; irow for
	
				# Now that intervals are in, put in words in (since you can't just shift boundaries around I guess?) 
				# This should work even if there are weird blanks because I got the number of the interval originally and those should stay the same
				for irow from 1 to nRows
					selectObject (handsegTg)
					do ("Set interval text...", wordTier, wordInterval[irow], word$[irow])

				endfor ; irow for the millionth

				# Changing daj mi to dajmi
				if thirdWord$ = "mi"
					Remove left boundary: 1, 3
				endif
				

				# If there was some specific weird problem with disfluency in the soundfile, will let you fix 
				if clickTranscript = 2
					pause Fix transcript, then click Continue
				endif

				# Slight pruning here 
				selectObject (mfaTgTable)
				plusObject (prunedMfaTable) 
				do ("Remove")

			endif ; hand-segmented filereadable if


		# </> *****************************************************************************************************
#pause Debugging pause if you hit this without editing something went wrong; debugging pause 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			# Make save name
			saveName$ = trialTag$ + ".TextGrid"
			# Determine object to be saved (so you only have to replace it here, not through the entire save code) 
			saveObject = handsegTg

			# Save 
			if fileReadable (dataDir$ + saveName$) and rewriteYN = 0 and neverRewrite = 0
				beginPause ("This file, " + saveName$ + ", already exists! Do you want to overwrite the existing .TextGrid file?")
				comment ("Never: Don't ever rewrite")
				comment ("One file: Just overwrite this file")
				comment ("Not now: Don't overwrite this particular file") 
				comment ("Participant: overwrite all for participant") 
				comment ("All: overwrite all files for all participants")
				click = endPause ("Never", "One file", "Not now", "Participant", "All", 1)

				if click = 1 ; never overwrite
					neverRewrite = 1

				elsif click = 2 ; one file
					selectObject (saveObject)
					do ("Save as text file...", dataDir$ + saveName$)

				# "Not now" should correspond to doing nothing (i.e., no saving, no changing of values) 	

				elsif click = 4 ; overwrite for whole participant
					selectObject (saveObject)
					do ("Save as text file...", dataDir$ + saveName$)
					rewriteYN = 1

				elsif click = 5 ; changed my mind, want to rewrite all the time
					selectObject (saveObject)
					do ("Save as text file...", dataDir$ + saveName$)
					rewriteYN = 1
					originalRewrite = 1
					
				endif

			elsif fileReadable (dataDir$ + saveName$) and neverRewrite = 1 ; if you in fact never want to overwrite, just confirms
				neverRewrite = 1

			elsif fileReadable (dataDir$ + saveName$) and rewriteYN = 1 ; if the file exists and you said you wanted to rewrite
				selectObject (saveObject)
				do ("Save as text file...", dataDir$ + saveName$)				
			
			elsif !fileReadable (dataDir$ + saveName$)
				selectObject (saveObject)
				do ("Save as text file...", dataDir$ + saveName$)

			else
				exitScript: "Your logic went wrong somewhere in the if/then statements on when you should overwrite" 

			endif ; save if
		
			# Remove leftover pitch object and sound
			selectObject (soundFile)
			if mfaTg
				plusObject (mfaTg)
			endif
			plusObject (handsegTg)
			do ("Remove")
			
		endif ; doit if
# </>~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	endfor ; file loop 
	
	# Clean up strings files object
	selectObject (stringsFiles)
	do ("Remove") 

endfor ; subj loop 

writeInfoLine ("good job!")



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