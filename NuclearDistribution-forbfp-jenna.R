## use this to count nuclei per traced hyphae and also measure distance between nuclei
setwd(choose.dir(default = "Y:/LiviaSongster/10-Analysis/", caption = "Select folder with all analysis dirs"))
rm(list=ls())
home <- getwd()
# make output directories for each data file type
dir.create("peak-detection")
dir.create("microns-btwn-peaks")
dir.create("number-peaks-per-micron")

# load libraries
library(readr)
library(pracma)
library(ggplot2)

files <- list.files(path = ".", pattern="csv",full.names = FALSE, recursive = FALSE)

for (file in files) {
  # TEST file = "MAX_210_tall005.tif2_PlotValues.txt"
  data <- read.csv(file) #read in file
  colnames(data) <- c("microns","mean.gray.value")
  fileName <- file #save filename for later
  # expt <- unlist(strsplit(file,split="_"))[2] #find protein/expt name
  #data <- arrange(data,microns) #make sure times are listed in ascending order
  
  
  
  
  # USE MICRONS PER PIXEL BASED ON WHICH OBJECTIVE
  
  # 0.18 for 60x, 0.11 for 100x
  umperpix = 0.11
  
  data[1] = (data[1] - 1) * umperpix
  
  
  # normalize the data to the lowest value aka background
  nlength <- length(unlist(data[1]))
  background <- sort(unlist(data[100:(nlength-100),2]))
  # take average of first (smallest) values as "background"
  background <- mean(background[1:15])
  data[2] = data[2]/background
  
  ggplot(data, aes(x=microns,y=mean.gray.value)) +
    geom_line()
  
  # first we need to smooth the data so it is a bit easier to process.
  # inspired by this post - fourier transform
  # https://chem.libretexts.org/Bookshelves/Analytical_Chemistry/Chemometrics_Using_R_(Harvey)/10%3A_Cleaning_Up_Data/10.4%3A_Using_R_to_Clean_Up_Data
  intensity = as.numeric(unlist(data[2]))
  # fourier transform, fft()
  intensity_ft <- fft(intensity)
  # plot the fft - use only real component with Re()
  # only plot first 128 values of the fft
  # plot(x = seq(1,128,1), y = Re(intensity_ft)[1:128], type = "l", col = "blue", xlab = "", ylab = "intensity", lwd = 2)
  
  # look for where the signal's magnitude has decayed to what appears to be random noise
  # and set these values to zero or 0 + 0i.
  intensity_ft[50:length(intensity)] = 0 + 0i
  
  # Finally, we take the inverse Fourier transform and display the resulting filtered signal 
  intensity_ifft = fft(intensity_ft, inverse = TRUE)/length(intensity_ft)
  # make an empty matrix
  filteredData = matrix(NA,length(intensity),3)
  # populate with unlisted values
  filteredData[,1] = as.numeric(unlist(data[1]))
  filteredData[,2] = as.numeric(unlist(data[2]))
  # normalize the ifft data to the lowest value aka background
  filteredData[,3] = Re(intensity_ifft)
  # background_ifft <- min(unlist(filteredData[100:(nlength-100),3])) # want to exclude first few and last few values when finding min
  background_ifft <- sort(unlist(filteredData[100:(nlength-100),3]))
  background_ifft <- mean(background_ifft[1:15])
  
  filteredData[,3] = filteredData[,3] / background_ifft
  
  colnames(filteredData) <- c("microns","raw.mean.gray.value","filtered.mean.gray.value")
  filteredData <- as.data.frame(filteredData)
  
  # find all peaks - these are nuclei. they should be at least 2 microns apart hopefully
  # min peak height should be 125 for current laser settings but double check this for every experiment
  # each peak should be at least 1 micron, or 1/0.11
  thresh = 1.02
  
  peakData <- findpeaks(filteredData[,3], nups=2, ndowns=2, minpeakheight=thresh, minpeakdistance=8, sortstr = FALSE)
  colnames(peakData) <- c("mean.gray.value","peakX","peakStartX","peakEndX")
  
  peakData[,2:4] <- peakData[,2:4] * umperpix # multiply by micron/pixel
  
  # sort the data table
  if (nrow(peakData) > 1) {
      peakData <-  peakData[order(peakData[,3]), ] 
  }
  
  write.table(peakData,paste0("peak-detection/",fileName,"_peak_detection.csv"),row.names=F,col.names=c("mean.gray.value","peakX","peakStartX","peakEndX"),sep=",")
  
  # make and save a plot of the linescan
  # save the plot! 
  ggplot(filteredData, aes(x=microns)) +
    geom_hline(yintercept=thresh, linetype="dashed", color="red") +
    geom_vline(xintercept=peakData[,2], linetype="solid", color="yellow") +
    geom_line(aes(y=raw.mean.gray.value),color="steelblue") +
    geom_line(aes(y=filtered.mean.gray.value)) +
    ylim(0.99, 1.25) +
    theme_bw()
  
  ggsave(paste0("peak-detection/",fileName,"_plot.png"),width=10,height=6,units="in")
  
  # calculate distance between peaks
  if (nrow(peakData) > 1) {
    variables = 2 
    npeaks <- length(peakData[,1])
    dist <- matrix(ncol=variables, nrow=npeaks-1) # empty matrix
    colnames(dist) <- c("peakX","microns2next")
    for(i in 1:(npeaks-1)){ # skip the last peak since it doesnt have a "next"
      # calculations
      dist[i,1] <- peakData[i,2]
      peakXnext <- peakData[i+1,2]
      dist[i,2] <- peakXnext - dist[i,1]
    }
    
    write.table(dist,paste0("microns-btwn-peaks/",fileName,"_distance.csv"),row.names=F,col.names=c("peakX","microns2next"),sep=",")
    
    # next we need to calculate the number of peaks per micron along the line
    # simple calculation: take npeaks and divide by total microns
    density = npeaks / max(data[,1])
    finalout = data.frame(matrix(ncol = 3, nrow = 0))
    finalout[1,1] = density
    finalout[1,2] = umperpix
    finalout[1,3] = thresh
    
    write.table(finalout,paste0("number-peaks-per-micron/",fileName,"_density.csv"),row.names=F,col.names=c("peakspermicron","micronsperpixel","peakthreshhold"),sep=",")
  }
    
 }
