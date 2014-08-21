# score_nback_log.R
#
# filelist = list.files(path="/path/to/files/", pattern="*.log", full.names=T)
# keyfile = "keyfile.xlsx"
# outfile = "your_output.csv" [OPTIONAL]
# trialColumn = index of column in keyfile with trial #'s (default=2)
# stimClassColumn = index of column in keyfile with stim class names(defualt=3)
# correctResponseColumn = index of column in keyfile with correct reponse flag (default=6)

#require(xlsx)

score_nback_log <- function( filelist=NA, keyfile=NA, outfile=NA ) {
  
  ext = ".log"

  if ( is.na(filelist) || (length(filelist)==0) ) {
    stop( "No input files specified" )
  }

  if ( is.na(keyfile) ) {
    stop( "No key file specified")
  }

  #key = read.xlsx(keyfile,1)
  key = read.csv(keyfile)
  nFiles = length(filelist)

  subject = rep("NA",nFiles)
  trueCount = matrix(0,nFiles,4)
  falseCount = matrix(0,nFiles,4)
  trueMRT = matrix(0,nFiles,4)
  falseMRT = matrix(0,nFiles,4)
  
  nBackList = c("NBack0", "NBack1", "NBack2", "NBack3")
  colnames(trueCount) = nBackList
  colnames(trueMRT) = nBackList
  colnames(falseCount) = nBackList
  colnames(falseMRT) = nBackList

  subIdx = 1
  for ( file in filelist ) {
    filename = basename( file )
    id = sub(ext, "", filename)
    subject[subIdx] = id

    idat = read.csv(file, skip=3, sep="\t")

    responses = which( (idat$Event.Type=="Response") & (idat$Code==2) )
    trials = as.numeric(as.character(idat$Trial)[responses])
    times = as.numeric( as.character(idat$TTime[responses] ))
    #print(times)

    #print( filename )
    #print( paste( id, "has", length(responses), "responses" ))

    
    trialTypes = rep("NA", length(trials))
    correctTrials = rep(0, length(trials))
    for ( idx in c(1:length(trials)) ) {
      keyRow = which(key$TR == trials[idx])

      if ( length(keyRow) < 0 ) {
        print( paste("WARNING: NO TRIAL TYPE FOUND FOR:", trials[idx]))
        }
      else {
        trialTypes[idx] = as.character(key$Stim.Class[keyRow])
        correctTrials[idx] = key$response[keyRow]    
        }  
      }

    nBackTrials = which( (trialTypes=="0-back") | ( trialTypes=="1-back") | (trialTypes=="2-back") | (trialTypes=="3-back") )
    trials = trials[nBackTrials]
    trialTypes = trialTypes[nBackTrials]
    correctTrials = correctTrials[nBackTrials]
    times = times[nBackTrials]

    #print( paste( id, "has", length(trials), "n-back responses" ))
    #print( paste( id, "has", length(which(trialTypes=="0-back")), "0-back responses"))
    #print( paste( id, "has", length(which(trialTypes=="1-back")), "1-back responses"))
    #print( paste( id, "has", length(which(trialTypes=="2-back")), "2-back responses"))
    #print( paste( id, "has", length(which(trialTypes=="3-back")), "3-back responses"))

    back0_tp = which( (trialTypes=="0-back") & (correctTrials==1) )
    back0_fp = which( (trialTypes=="0-back") & (correctTrials==0) )

    trueCount[subIdx, 1]  = length(back0_tp)
    trueMRT[subIdx, 1]    = mean( times[back0_tp] )
    falseCount[subIdx, 1] = length(back0_fp)
    falseMRT[subIdx, 1]   = mean( times[back0_fp] )

    back1_tp = which( (trialTypes=="1-back") & (correctTrials==1) )
    back1_fp = which( (trialTypes=="1-back") & (correctTrials==0) )

    trueCount[subIdx, 2]  = length(back1_tp)
    trueMRT[subIdx, 2]    = mean( times[back1_tp] )
    falseCount[subIdx, 2] = length(back1_fp)
    falseMRT[subIdx, 2]   = mean( times[back1_fp] )

    back2_tp = which( (trialTypes=="2-back") & (correctTrials==1) )
    back2_fp = which( (trialTypes=="2-back") & (correctTrials==0) )

    trueCount[subIdx, 3]  = length(back2_tp)
    trueMRT[subIdx, 3]    = mean( times[back2_tp] )
    falseCount[subIdx, 3] = length(back2_fp)
    falseMRT[subIdx, 3]   = mean( times[back2_fp] )

    back3_tp = which( (trialTypes=="3-back") & (correctTrials==1) )
    back3_fp = which( (trialTypes=="3-back") & (correctTrials==0) )

    trueCount[subIdx, 4]  = length(back3_tp)
    trueMRT[subIdx, 4]    = mean( times[back3_tp] )
    falseCount[subIdx, 4] = length(back3_fp)
    falseMRT[subIdx, 4]   = mean( times[back3_fp] )
    
    subIdx = subIdx + 1
  }

  trueMRT[trueCount==0]=0
  falseMRT[falseCount==0]=0
  trueMRT = trueMRT * 10.0
  falseMRT = falseMRT * 10.0

  odat = data.frame(Subject=subject, TruePositives=trueCount, TrueMRT=trueMRT, FalsePositives=falseCount, FalseMRT=falseMRT)
  if ( !is.na(outfile) ) {
    write.csv(odat, outfile)
  }

  return( odat )

} 

