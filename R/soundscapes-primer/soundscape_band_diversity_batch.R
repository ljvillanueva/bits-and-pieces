# soundscape_script_batch.R
# Version: 1.2 (12 Sep 2012)
#
# R Script to obtain from a .wav file:
#         - frequency band diversity using Shannon’s diversity index
#         - band eveness using the Gini coefficient
#         - a raster map in ASCII format
#
# From the paper: 
#       Villanueva-Rivera, L. J., B. C. Pijanowski, J. Doucette, and B. Pekin. 2011. A primer of acoustic analysis for landscape ecologists. Landscape Ecology 26: 1233-1246. doi:10.1007/s10980-011-9636-9. 
#
# For more information visit: http://www.purdue.edu/soundscapes/
# 
# The packages 'tuneR', 'seewave', and 'ineq' are required. 
# 
# Use the default setting or edit the settings below, then run the script from
#  the GUI or from the command line.
# 
#  From the GUI:
# 	- From the 'File' menu, select 'Open script...' and open the script file "soundscape_band_diversity.R"
#	- From the 'Edit' menu, click on 'Run all' to run the script
#	- The script will ask for the file you want to extract the score from
#
#  From the command line you can use the function source():
#	- At the command line, type:	source("soundscape_band_diversity.R")
#	- The script will ask for the file you want to extract the score from
#
# 
#    Licensed under the GPLv3
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
# 
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see http://www.gnu.org/licenses/
#

########################################################################################################
# SETTINGS
########################################################################################################

	#Set the dB threshold to use. Default is -50
	db <- -50
	#How wide to make each band, in Hertz. Default is 1000
	freq_step <- 1000
	#The bands and soundmap should be calculated up to this frequency, in Hertz. Default is 10000
	max_freq <- 10000

########################################################################################################
# BODY OF THE SCRIPT
# NO NEED TO EDIT BELOW THIS LINE
########################################################################################################

#check variables and packages
check_val = 0

if (db > 0) {
	check_val=1
	}

if (db < -100) {
	check_val=4
	}

#check if required packages are installed
if (library(tuneR,logical.return=TRUE)==FALSE) {
	check_val=2
	}

if (library(seewave,logical.return=TRUE)==FALSE) {
	check_val=3
	}

if (library(ineq,logical.return=TRUE)==FALSE)
	{
	check_val=6
	}

if (freq_step>=max_freq) {
	check_val=5
	}

wav_files <- dir(pattern="wav$", ignore.case=TRUE)

if (length(wav_files)==0) {
	check_val=7
	}

Freq<-seq(from=0, to=max_freq-freq_step, by=freq_step)

#all checks passed, run script
if (check_val==0) {

#Get the .wav files in the working dir

cat(paste("\nThe current working directory is: \n  ", getwd(), "\n\n The following files will be analyzed:\n", sep=""))

for (soundfile in wav_files){
	cat(paste("   ", soundfile, "\n", sep=""))
	}

#function that gets the proportion of values over a db value in a specific band
# of frequencies. Frequency is in Hz
getscore<-function(spectrum, minf, maxf, db, freq_row){
	miny<-round((minf)/freq_row)
	maxy<-round((maxf)/freq_row)

	subA=spectrum[miny:maxy,]

	index1<-length(subA[subA>db])/length(subA)

	return(index1)
	}


#Write header for results file
cat("filename", file="R_results.csv")

	for (j in seq(1,length(Freq),by=1)) {
		cat(paste(",", Freq[j], "-", Freq[j]+freq_step, "_Hz_left", sep=""), file="R_results.csv", append=TRUE)
		}

	for (j in seq(1,length(Freq),by=1)) {
		cat(paste(",", Freq[j], "-", Freq[j]+freq_step, "_Hz_right", sep=""), file="R_results.csv", append=TRUE)
		}

	cat(",diversity_left,diversity_right,eveness_left,eveness_right\n", file="R_results.csv", append=TRUE)

for (filename in wav_files){

#Load the file
cat(paste("\nOpening file ", filename, "...", sep=""))
soundfile<-readWave(filename)

#Some general values
		
	#Get sampling rate
	samplingrate<-soundfile@samp.rate

	#Get Nyquist frequency in Hz
	nyquist_freq<-(samplingrate/2)

	#window length for the spectro and spec functions
	#to keep each row every 10Hz
	#Frequencies and seconds covered by each
	freq_per_row = 10
	wlen=samplingrate/freq_per_row

#Stereo file
if (soundfile@stereo==TRUE) {

		left<-channel(soundfile, which = c("left"))
		right<-channel(soundfile, which = c("right"))
		rm(soundfile)

		#matrix of values
		cat("\n Getting values from spectrogram... \n")
		specA_left <- spectro(left, f=samplingrate, wl=wlen, plot=FALSE)$amp
		specA_right <- spectro(right, f=samplingrate, wl=wlen, plot=FALSE)$amp
		
		rm(left,right)

		if (max_freq>nyquist_freq) {
			cat(paste("\n ERROR: The maximum acoustic frequency that this file can use is ", nyquist_freq, "Hz. But the script was set to measure up to ", max_freq, "Hz.\n\n", sep=""))
			break
			}

		#LEFT CHANNEL

		#Score=seq(from=0, to=0, length=length(Freq))
		Score <- rep(NA, length(Freq))

		for (j in 1:length(Freq)) {
				Score[j]=getscore(specA_left, Freq[j], (Freq[j]+freq_step), db, freq_per_row)
			}

			left_vals=Score

		Score1=0
		for (i in 1:length(Freq)) {
				Score1=Score1 + (Score[i] * log(Score[i]+0.0000001))
			}
			
		#Average
		Score_left=(-(Score1))/length(Freq)


		#RIGHT CHANNEL

		#Score=seq(from=0, to=0, length=length(Freq))
		Score <- rep(NA, length(Freq))

		for (j in 1:length(Freq)) {
				Score[j]=getscore(specA_right, Freq[j], (Freq[j]+freq_step), db, freq_per_row)
			}

			right_vals=Score
		
		Score1=0
		for (i in 1:length(Freq)) {
				Score1=Score1 + (Score[i] * log(Score[i]+0.0000001))
			}
			
		#Average
		Score_right=(-(Score1))/length(Freq)


		#Generate soundmaps
		cat("\n Generating ASCII soundmaps... \n")
		#left channel
		max_freq_row=max_freq/10
		sound_map_left<-specA_left[1:max_freq_row,]


		nrows=dim(sound_map_left)[1]
		ncols=dim(sound_map_left)[2]

		#Create container array for db values
		sound_map=array(dim=dim(sound_map_left))

		#Using k to write the new array with lower freqs in the bottom
		k=dim(sound_map)[1]
		for (i in seq(from=1, to=dim(sound_map)[1], by=1)){
			for (j in seq(from=1, to=dim(sound_map)[2], by=1)){
				sound_map[k,j]=round(sound_map_left[i,j], digits = 4)
				}
			k=k-1
			}

		#Write header
		cat(paste("ncols         ", ncols, "\nnrows         ", nrows, "\nxllcorner     0.0\nyllcorner     0.0\ncellsize      1\nNODATA_value  -9999\n", sep=""), file=paste(strsplit(filename,".wav"), "_wav_left.asc", sep=""))

		#Write data
		write.table(sound_map, file=paste(strsplit(filename,".wav"), "_wav_left.asc", sep=""), append=TRUE, row.names=FALSE, col.names=FALSE, sep=" ")

		rm(sound_map,sound_map_left,specA_left)

		#right channel
		max_freq_row=max_freq/10
		sound_map_right<-specA_right[1:max_freq_row,]


		nrows=dim(sound_map_right)[1]
		ncols=dim(sound_map_right)[2]

		#Create container array for db values
		sound_map=array(dim=dim(sound_map_right))

		#Using k to write the new array with lower freqs in the bottom
		k=dim(sound_map)[1]
		for (i in seq(from=1, to=dim(sound_map)[1], by=1)){
			for (j in seq(from=1, to=dim(sound_map)[2], by=1)){
				sound_map[k,j]=round(sound_map_right[i,j], digits = 4)
				}
			k=k-1
			}

		#Write header
		cat(paste("ncols         ", ncols, "\nnrows         ", nrows, "\nxllcorner     0.0\nyllcorner     0.0\ncellsize      1\nNODATA_value  -9999\n", sep=""), file=paste(strsplit(filename,".wav"), "_wav_right.asc", sep=""))

		#Write data
		write.table(sound_map, file=paste(strsplit(filename,".wav"), "_wav_right.asc", sep=""), append=TRUE, row.names=FALSE, col.names=FALSE, sep=" ")

		#Write data to results file
		cat(filename, file="R_results.csv", append=TRUE)

		for (j in seq(1,length(Freq),by=1)) {
				cat(paste(",", round(left_vals[j],6), sep=""), file="R_results.csv", append=TRUE)
			}

		for (j in seq(1,length(Freq),by=1)) {
				cat(paste(",", round(right_vals[j],6), sep=""), file="R_results.csv", append=TRUE)
			}

		cat(paste(",", round(Score_left,6), sep=""), file="R_results.csv", append=TRUE)
		cat(paste(",", round(Score_right,6), sep=""), file="R_results.csv", append=TRUE)

		cat(paste(",", round(Gini(left_vals),6), sep=""), file="R_results.csv", append=TRUE)
		cat(paste(",", round(Gini(right_vals),6), "\n", sep=""), file="R_results.csv", append=TRUE)

		} else 
		{

		#matrix of values
		cat("\n Getting values from spectrogram... \n")
		specA_left <- spectro(soundfile, f=samplingrate, wl=wlen, plot=FALSE)$amp
		
		rm(soundfile)

		if (max_freq>nyquist_freq) {
			cat(paste("\n ERROR: The maximum acoustic frequency that this file can use is ", nyquist_freq, "Hz. But the script was set to measure up to ", max_freq, "Hz.\n\n", sep=""))
			break
			}

		Freq<-seq(from=0, to=max_freq-freq_step, by=freq_step)

		#Score=seq(from=0, to=0, length=length(Freq))
		Score <- rep(NA, length(Freq))

		for (j in 1:length(Freq)) {
				Score[j]=getscore(specA_left, Freq[j], (Freq[j]+freq_step), db, freq_per_row)
			}

			left_vals=Score

		Score1=0
		for (i in 1:length(Freq)) {
				Score1=Score1 + (Score[i] * log(Score[i]+0.0000001))
			}
			
		#Average
		Score_left=(-(Score1))/length(Freq)



		#Generate soundmap
		cat("\n Generating ASCII soundmap... \n")
		max_freq_row=max_freq/10
		sound_map_left<-specA_left[1:max_freq_row,]


		nrows=dim(sound_map_left)[1]
		ncols=dim(sound_map_left)[2]

		#Create container array for db values
		sound_map=array(dim=dim(sound_map_left))

		#Using k to write the new array with lower freqs in the bottom
		k=dim(sound_map)[1]
		for (i in seq(from=1, to=dim(sound_map)[1], by=1)){
			for (j in seq(from=1, to=dim(sound_map)[2], by=1)){
				sound_map[k,j]=round(sound_map_left[i,j], digits = 4)
				}
			k=k-1
			}

		#Write header
		cat(paste("ncols         ", ncols, "\nnrows         ", nrows, "\nxllcorner     0.0\nyllcorner     0.0\ncellsize      1\nNODATA_value  -9999\n", sep=""), file=paste(strsplit(filename,".wav"), "_wav.asc", sep=""))

		#Write data
		write.table(sound_map, file=paste(strsplit(filename,".wav"), "_wav.asc", sep=""), append=TRUE, row.names=FALSE, col.names=FALSE, sep=" ")


		#Write data to results file
		cat(filename, file="R_results.csv", append=TRUE)


		#printed in inverse order to keep the low frequencies in the bottom, like in a spectrogram
		for (j in seq(1,length(Freq),by=1)) {
				cat(paste(",", round(left_vals[j],6), sep=""), file="R_results.csv", append=TRUE)
			}

		for (j in seq(1,length(Freq),by=1)) {
				cat(",", file="R_results.csv", append=TRUE)
			}


		cat(paste(",", round(Score_left,6), ",", sep=""), file="R_results.csv", append=TRUE)

		cat(paste(",", round(Gini(left_vals),6), ",\n", sep=""), file="R_results.csv", append=TRUE)

	}

		}

	cat("\n\n Batch process complete!\n   Results are stored in the file R_results.csv\n\n")

	} else 
	{
	#some check failed, print error
	if (check_val==1) {
		cat("\n ERROR: The value of db was not negative, it should be between -120 and 0.\n  Please fix this and rerun the script.\n\n")
		}

	if (check_val==4) {
		cat("\n ERROR: The value of db was too low, it should be between -120 and 0.\n  Please fix this and rerun the script.\n\n")
		}
				
	if (check_val==2) {
		cat("\n ERROR: Please install the package 'tuneR' with the command:\n\n    install.packages(\"tuneR\")\n\n")
		}
		
	if (check_val==3) {
		cat("\n ERROR: Please install the package 'seewave' with the command:\n\n    install.packages(\"seewave\")\n\n")
		}

	if (check_val==5) {
		cat("\n ERROR: The variable freq_step cannot be equal or larger than max_freq.\n\n")
		}

	if (check_val==6) {
		cat("\n ERROR: Please install the package 'ineq' with the command:\n\n    install.packages(\"ineq\")\n\n")
		}

	if (check_val==7) {
		cat("\n ERROR: The working directory does not have any .wav files. \n  Please change the working directory and try again.\n\n")
		}
	} 

