################################################################################################
#
# Praat tutorial, workshop 3
# Cornell phonetics lab
# Friday, October 27, 2017
#
# Goals:
# --- Introduce Praat UI 
# --- Introduce (semi-)automation of data gathering
# --- Introduce creation of delimited text files with data 
#
# Addressed: 
# --- UI 
# --- If statements (jumps) 
# --- While loops 
# --- Writing text files 
# --- Editor environments
# --- Semi-automatic work with text grids
# --- Formant measures
# 
# Presented by Robin Karlin
# Last edited 10/27/2017
#
################################################################################################

# 1. Sometimes you want to make your script a little more friendly for people that don't know how to script, 
# or simply make it less prone to "argh, forgot to change my variable" errors
# --- UI! 
# --- Praat has decent UI capability
# --- For the full list of form types: http://www.fon.hum.uva.nl/praat/manual/Scripting_6_1__Arguments_to_the_script.html

# syntax: 
# form Text to display in top bar 
##	stuff to do in the form
# endform 

# type variablename defaultvalue
# --- e.g.: text dataDirectory D:\Users\Viriam\Documents\MATLAB\PraatScripts\AB_GetFormants\
# --- NB: default values don't get "" for string variables 

form Choose path and participant
	comment Experiment directory path ; this is so there's some text telling your user what the variable is doing
	text experimentDirectory C:\Users\Viriam Karo\OneDrive\Documents\PraatScriptingWorkshop\

	comment Extension of sound files
	text ext .wav

	comment Handle of participant
	text subj SS01

	comment Gender of participant
	optionmenu gender: 1
	option Male
	option Female (or child)

endform

# 2. What is the gender specification good for? 
# --- Formant tracking, pitch tracking
# --- What needs to be changed for formant tracking based on pitch range of the participant? 
# 
# If statements! 
# --- if a condition is met, then do this; otherwise do another thing

# syntax: 
# if condition
# 	do a thing
# elsif condition2
# 	do a second thing
# else ; (all other conditions)
# 	do a third thing
# endif 
# NB: elsif, not elseif

# Using the number variable for gender, how do we specify the value where we should find the highest formant? 

if gender = 1 ; NB: Praat uses =, not == for establishing equivalence
	maxFormant = 5000 ; for males
else
	maxFormant = 5500 ; for females
endif

# Other formant tracking options are here in case you want to change them
numFormant = 5
winLength = 0.025
dynRange = 30.0
dotSize = 1.0

# 3. Outputting files
# --- Praat can write to delimited text files 
# --- Good for formant values, maximum pitch times, etc. etc. (today we'll do formants, obviously) 

# 3a. How do you want to save your output? 
# Specify the name of the output file: e.g. RK01.txt
outfile$ = subj$ + ".txt"

# 3b. What if this file already exists?
# --- Don't want to overwrite (especially if you want to be able to pause and restart your markup) 

# checking if a file exists: fileReadable ("filename") 
exists = fileReadable (experimentDirectory$ + outfile$)

# 3c. How would you create a file if one doesn't exist?  

if not fileReadable (experimentDirectory$ + outfile$)
	#do a thing 
endif

# 3d. Populating the textfile
# writing to a file: writeFileLine ("filename", "header1", delimiter, "header2".... "headerN")
# tab delimiting: tab$ 
# Info we want: participant, word, vowel, duration, f1, f2

if not fileReadable (experimentDirectory$ + outfile$)
	writeFileLine (experimentDirectory$ + outfile$, "subj", tab$, "word", tab$, "vowel", tab$, "dur", tab$, "f1", tab$, "f2")
endif

# Check to see if you have a file in your experiment directory now! 

# 4. Opening the sound file and existing textgrid

soundObject = do ("Read from file...", experimentDirectory$ + subj$ + ext$)
tgObject = do ("Read from file...", experimentDirectory$ + subj$ + ".TextGrid") 

# 4a. Let's edit the TextGrid a little: add an interval tier called "measure" 

selectObject (tgObject)
do ("Insert interval tier...", 3, "measure") 

# better: 
measureTier = 3
do ("Insert interval tier...", measureTier, "measure") 

# How would you insert a tier only if there aren't already three (or a tier called "measure")? 

# 5. Indicating what you want to measure 
# --- Let's use a "while" loop: don't have to know exactly how many things exist, just go until you're done 
# syntax: 
# while condition
# 	keep doing things
# endwhile 

done = 0 
#while done < 1
# 	do things
#endwhile 

# 5a. Opening the thing--- inside or outside the loop?  

selectObject (soundObject)
plusObject (tgObject)
View & Edit


while done < 1

# 5b. NB: Editor environments---I don't fully understand these but you have to be inside them to do certain things
# Pause your script to do something to it!

	pause

editor TextGrid 'subj$'
	# First thing to do : fix your formant settings
	do ("Formant settings...", maxFormant, numFormant, winLength, dynRange, dotSize)	

	# Click on your vowel. What vowel is it? (This goes in your output file!)
	vowel$ = do$ ("Get label of interval")
	# NB: do$ to get strings... that's probably why my "do" command didn't work last time when trying to get that string from the list

	# Get start and end time 
	vBeg = do ("Get start of selection")
	vEnd = do ("Get end of selection")

	# How do you get duration? (also in your output file) 
	vDur = vEnd - vBeg
	# and in ms? 
	vDurMs = vDur * 1000

	# Generate intervals automaticaly by finding the middle 20 ms
	# How do you do this?
	vMid = vBeg + (vDur / 2)
	bV50 = vMid - 0.01 ; note that this is in seconds
	eV50 = vMid + 0.01 
	do ("Move cursor to...", bV50)
	do ("Add on tier 3")
	do ("Move cursor to...", eV50)
	do ("Add on tier 3")
endeditor

	# Name your interval (outside of the editor) 
	minusObject ("Sound " + subj$) 
	intervalNumHead = do ("Get interval at time...", measureTier, vMid)
	do ("Set interval text...", measureTier, intervalNumHead, vowel$)

# 6. For today we're just going to assume that the intervals that are automatically generated are good (not always the case)
# How do you get formant values for the interval you just created? 
# (Go back into the editor) 

	selectObject (soundObject)
	plusObject (tgObject)
	# NB: No view and edit because it keeps opening windows and then you have a trillion windows

editor TextGrid 'subj$'

	do ("Select...", vBeg, vEnd)
	f1 = do ("Get first formant")
	f2 = do ("Get second formant")

endeditor

# 7. Do we have all the other information that is going to go into the text file?
# --- Nope, we need the word that the vowel belongs to!  How do we get this? 
# --- Praat can get the label of a specific (integer) interval, and the specific interval at a time, but not the label at a time
	wordTier = 1
	wordInterval = do ("Get interval at time...", wordTier, vMid)
	# NB: Praat getting intervals doesn't play well with edges, so try to use values you know to be inside intervals
	word$ = do$ ("Get label of interval...", wordTier, wordInterval) 

# 8. Okay, now write the info to the text file 
# --- Similarly to writeInfoLine vs. appendInfoLine, we have writeFileLine and appendFileLine. Which should you use? 

appendFileLine (experimentDirectory$ + outfile$, subj$, tab$, word$, tab$, vowel$, tab$, vDurMs$, tab$, f1$, tab$, f2$
	
# 9. Now you want to save your TextGrid so you don't lose all your work 
	minusObject (soundObject)
	selectObject (tgObject)
	do ("Save as text file...", experimentDirectory$ + subj$ + "_vowelmeasures" + ".TextGrid")

endwhile