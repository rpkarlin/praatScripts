
click = 0
tgName$ = "Sofija_i_Petrik"
saveDir$ = "D:\Users\Viriam\Desktop\Recordings for Andrej\Sofija-i-Petrik\"

while click < 2

beginPause ("I'm a save pause")
	comment ("Click 'save' when you wanna save")
	comment ("Click 'All done!' if you want to save and stop") 
	comment ("'Stop' will end the script (no saving)")
click = endPause ("Save", "All done!", 1)


# Hardcoded style
# selectObject ("TextGrid Sofija_i_Petrik_-_Copy")
# Save as text file: "D:\Users\Viriam\Desktop\Recordings for Andrej\Sofija-i-Petrik\Sofija_i_Petrik_-_Copy.TextGrid"

# Or do it variable style
selectObject ("TextGrid " + tgName$)
do ("Save as text file...", saveDir$ + tgName$ + ".TextGrid.")

endwhile

# Hardcoded style 
# selectObject ("TextGrid Sofija_i_Petrik")
# do ("Save as text file...", "D:\Users\Viriam\Desktop\Recordings for Andrej\Sofija-i-Petrik\Sofija_i_Petrik.TextGrid")

# Or do it variable style
selectObject ("TextGrid " + tgName$)
do ("Save as text file...", saveDir$ + tgName$ + ".TextGrid.")

writeInfoLine ("Good work!") 

