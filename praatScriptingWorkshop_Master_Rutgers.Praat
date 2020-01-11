####################################################################################
#
# Praat tutorial
# Rutgers (P)LUG
# Monday, October 8, 2018 (and Friday, October 12) 
#
# Goals: 
# - Quick overview of Praat scripting to catch anybody up
# --- Variables (string, number, how to denote) 
# --- Commenting
# --- Printing to an info window
# --- String concatenation
# --- "Paste history" function 
#
# - Basic Praat automation
# --- Opening sound, textgrid files (etc.) 
# --- Object selection, deselection, removal 
# --- For loops (basic Praat syntax)
# 
# - More useful Praat automation
# --- Creating lists of files, directories
# --- Opening CSVs with transcription information in it
# --- Manipulating textgrids
# ------ Creation from sound file
# ------ Pausing to manually update
# ------ Automatic manipulation: boundaries, text
# 
# Presented by Robin Karlin
# Last edited 10/6/2018
#
####################################################################################

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Basic Praat scripting
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# 1. Open Praat---note the # at the beginning of this line! 

# 2. Writing to info window---note that there are two formats for writing commands in Praat
# I call them "parentheses notation" and "colon notation" 

writeInfoLine ("Hello")
writeInfoLine: "Hello"
# Try highlighting and hitting ctrl + t

# 3. Variables

stringVariable$ = "Hello"
numberVariable = 4

writeInfoLine (Hello) 
# Oh no! 
writeInfoLine (stringVariable$)
writeInfoLine (numberVariable)

# 3a.  Converting variables back and forth---note that Praat doesn't store variables once a section is done running! 

stringNumber$ = "01"
numberVersion = number(stringNumber$)
writeInfoLine (numberVersion)

numberVariable = 4
numString$ = string$(numberVariable)
writeInfoLine (numString$)

# 4.  Concatenating / + 

stringVariable$ = "Hello"
numberVariable = 4
numString$ = string$(numberVariable)
writeInfoLine (stringVariable$ + numString$ + " World")

stringNumber$ = "01"
numberVersion = number(stringNumber$)
writeInfoLine (numberVersion)
writeInfoLine (numberVersion + numberVariable) 

# 5. adding to info line 

appendInfoLine ("!") ; creates a new line 
appendInfo ("!") ; just appends

# 6. Commenting out in the middle of a line

writeInfoLine ("Hi there") ; this is a test

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Basic Praat automation
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# 1. Opening a new script window (so you can copy/paste and type new commands as needed to have a clean script) 
# --- Praat > New Praat Script
# --- Edit > Clear history

# 1a. Open > read from file 
# --- AB01_01_01
# --- click on sound > annotate > to textgrid
# --- word seg as interval tiers 
# --- elbow as point tier
# --- come back to script
# --- Edit > Paste history (or ctrl + H) 

# 2. Script it! 
do ("Read from file...", "AB01_01_01.wav")
do ("To TextGrid...", "word seg", "elbow")

# OR 

Read from file: "C:\Users\viria\OneDrive\Documents\PraatScriptingWorkshop\PraatScriptingWorkshop\AB01_01_01.wav"
To TextGrid: "word seg", ""
# --- Note that the order of arguments after the function is the same as the order in the GUI

# 3. Opening together, using the script
selectObject ("Sound" + "AB01_01_01")
# --- oops! 
# *** need to include the space 

# --- alternatively: 
selectObject (1)

# --- even better: 
soundObject = do ("Read from file...", "AB01_01_01.wav") 
selectObject (soundObject)
# --- what are the advantages of this last type? 

# --- How do we get this to work? (Insert line of code here) 
# *** need to additionally define the tgObject 

selectObject (soundObject)
plusObject (tgObject)
do ("View & Edit") 

selectObject: "Sound AB01_01_01"
plusObject: "TextGrid AB01_01_01"
View & Edit

# 4. Insert boundaries by hand
# --- Pick some boundaries and insert
# --- Go back to the script and hit Ctrl + H
# *** Oh no! Super unhelpful command

# 4a. If your task involves very imprecise boundary additions, can script in: 
# --- Go back to objects 
# --- Select TextGrid
# --- Modify > Modify interval tier > Insert boundary
# --- Tier number 1, time 0.1

# --- Ctrl + H in script
selectObject (tgObject)
do ("Insert boundary...", 1, 0.1) 

# --- Add another boundary: let's use 100 ms from the end of the sound file
# --- How do we do this manually? 
# --- How do we script this?  
# --- Can we do the two things together? (The duration and the subtraction both included in defining the variable) 
# --- How do we get to this point: 

selectObject (tgObject)
do ("Insert boundary...", 1, boundTime)

# --- If you are adding to the point tier...? 
# --- If you are adding to the other interval tier...? 

# 4b. If not doing automatically, we'll come back to you after we do a for loop

# 5. for loops
# --- Very helpful for monotonous tasks---basically eliminate as many extraneous clicks as possible
# --- Scripting can get rid of: 
# ------ (1) Open > (2) Read from file > (3) Select file > (4) Enter/the second click of double click > 
# (5) Select object > (6) To text grid > (7) Highlight both > (8) View and edit 
# ------ (phew) 

# --- structure: 

for (variable) from (start value) to (end value) 
 	do a thing
endfor 

# 6. What's the task? 
# --- Open all the files for a participant, create text grids 
# (or check if one already exists---if we have time we'll do this) 
# --- View/Edit textgrid with sound; place boundaries
# --- Add text to some interval
# --- Save textgrid

# 7. What will you need?
# --- Sound files
# --- CSV with the text to add

# 8. Couple of ways to structure the for loop...

for nBlock from 1 to totalBlocks
	for nTrial from 1 to totalTrials

# 	do things

	endfor
endfor

OR

# Search given directory for all .wav files, for example
for nFile from 1 to totalFiles
#	do things
endfor

# --- Advantages/disadvantages? 
# --- Going to do the second one right now so if statements don't get absurd (but I have historically done the first one for probably no good reason) 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# More useful automation: automatic text grid filling
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# 1. Let's set this up

# --- In the current configuration, can you do one subject at a time if all the files are in one directory? 
# --- How would you change it such that you could? 

subj$ = "AB01" 
dataDirectory$ = "C:\Users\viria\OneDrive\Documents\PraatScriptingWorkshop\PraatScriptingWorkshop\" 

fileList = Create Strings as file list: "list", dataDirectory$ + subj$ + "*.wav"

# NB: * as wildcard
selectObject (fileList)
totalFiles = Get number of strings

for nFile from 1 to totalFiles
	# --- Step 1: open the sound file: How do? 


	# --- Step 2: make a text grid: how do? 

	
	# --- Step 3: edit text grid


	# ------ Now, how do we get the script to stop so we can do a specific thing to it? 

	# (now add boundaries to "seg" by hand; add some text) 

	# --- Step 4: continue
	# ------ Say you want to add some stuff automatically to "word" tier


	# ------ but where in the script do you read the csv? (up by the asterisks) 


	# ------ Why is it interval 2? 

	# --- Step 4a: If you want to examine your handiwork (say you're debugging)
	Pause

	# --- Step 5: Save
	# ------ What are you saving the textgrid as? AB01_01_01.TextGrid
	# ------ Do you have that string anywhere else? (Kind of) 
	# ------ Procedures! 

	@split (".", fileName$)
	trialTag$ = split.array$[1]



	# --- Step 6: Okay now you've got all these random objects...

	
endfor	



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Data collection and writing CSVs with data in them
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

if gender = 1 ; male
	maxFormant = 5000
elsif gender = 2 ; female/child
	maxFormant = 5500
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
#writeInfoLine (exists) 

# 3c. How would you create a file if one doesn't exist?  






# 3d. Populating the textfile
# writing to a file: writeFileLine ("filename", "header1", delimiter, "header2".... "headerN")
# tab delimiting: tab$ 
# Info we want: participant, word, vowel, duration, f1, f2


if exists = 0 
	writeFileLine (experimentDirectory$ + outfile$, "subj", tab$, "word", tab$, "vowel", tab$, "duration", tab$, "f1", tab$, "f2") 

endif

# Check to see if you have a file in your experiment directory now! 

# 4. Opening the sound file and existing textgrid
soundObject = do ("Read from file...", experimentDirectory$ + subj$ + ext$)
tgObject = do ("Read from file...", experimentDirectory$ + subj$ + ".TextGrid")

# 4a. Let's edit the TextGrid a little: add an interval tier called "measure" 
selectObject (tgObject)
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

# 5a. Editing/viewing the thing--- inside or outside the loop?  

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
	# NB: do$ to get strings... that's probably why my "do" command didn't work last time when trying to get that string from the list
	vowel$ = do$ ("Get label of interval") 

	# Get start and end time 
	vBeg = do ("Get start of selection") 
	vEnd = do ("Get end of selection") 

	# How do you get duration? (also in your output file) 
	# and in ms? 
	vDur = vEnd - vBeg
	vDurMs = vDur * 1000

	# Generate intervals automaticaly by finding the middle 20 ms
	# How do you do this?
	vMid = vBeg + (vDur / 2)
	bV50 = vMid - 0.01 
	eV50 = vMid + 0.01
	do ("Move cursor to...", bV50)
	do ("Add on tier 3")
	do ("Move cursor to...", eV50)
	do ("Add on tier 3")

endeditor

	# Name your interval (outside of the editor) 
	minusObject (soundObject) 
	intervalNumHead = do ("Get interval at time...", measureTier, vMid)
	do ("Set interval text...", measureTier, intervalNumHead, vowel$)


# 6. For today we're just going to assume that the intervals that are automatically generated are good (not always the case)
# How do you get formant values for the interval you just created? 
# (Go back into the editor) 

	selectObject (soundObject)
	plusObject (tgObject)
	# NB: No view and edit because it keeps opening windows and then you have a trillion windows

editor TextGrid 'subj$'

	# Get your formants
	do ("Select...", bV50, eV50)
	f1 = do ("Get first formant")
	f2 = do ("Get second formant")


endeditor

# 7. Do we have all the other information that is going to go into the text file?
# --- Nope, we need the word that the vowel belongs to!  How do we get this? 
# --- Praat can get the label of a specific (integer) interval, and the specific interval at a time, but not the label at a time
	# NB: Praat getting intervals doesn't play well with edges, so try to use values you know to be inside intervals
	wordTier = 1
	wordInterval = do ("Get interval at time...", wordTier, vMid)
	word$ = do$ ("Get label of interval...", wordTier, wordInterval) 

# 8. Okay, now write the info to the text file 
# --- Similarly to writeInfoLine vs. appendInfoLine, we have writeFileLine and appendFileLine. Which should you use? 

appendFileLine (experimentDirectory$ + outfile$, subj$, tab$, word$, tab$, vowel$, tab$, vDurMs, tab$, f1, tab$, f2)


	
# 9. Now you want to save your TextGrid so you don't lose all your work 

	minusObject (soundObject)
	selectObject (tgObject)
	do ("Save as text file...", experimentDirectory$ + subj$ + "_vowelmeasures" + ".TextGrid")



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

