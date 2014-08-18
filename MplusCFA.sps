* Use Mplus to run a CFA from within SPSS
* By Jamie DeCoster

* This program allows users to identify a factor structure that
* they want to test on an SPSS data set. The program then
* converts the active data set to Mplus format, writes a program
* that will perform the CFA in Mplus, then loads the important
* parts of the Mplus output into the SPSS output window.

**** Usage: MplusCFA(impfile, factornames, 
factor structure list, "CORRELATED" or "UNCORRELATED", cluster)
**** "impfile" is a string identifying the directory and filename of
* Mplus input file to be created by the program. This filename must end with
* .inp . The data file will automatically be saved to the same directory. This
* argument is required.
**** "names" is a list containing the names that will be used by
* Mplus label your factors. These should be provided as strings.
* These names must follow the rules for variable names in Mplus. 
* The order of the names in the list should correspond to the 
* order of the structures identified in the factor structure list. This argument
* is required.
**** "structure" is actually a list of lists identifying your factor structure. 
* First, you create a set of lists that each identify the items loading on a
* particular factor. Then you combine these individual factor lists 
* into a larger list identifying the entire factor structure. This argument 
* is required.
**** "corr" is an optional argument that can take on the values of 
* "CORRELATED" or "UNCORRELATED". This specifies whether you 
* want to allow the latent factors to be correlated.  This defaults to 
* "CORRELATED".
**** "cluster" is an optional argument that identifies a cluster variable.
* This defaults to None, which indicates that there is no clustering.

* Example 1: 
MplusCFA(inpfile = "C:\users\jamie\workspace\spssmplus\CFA.inp",
names = ["CO", "ES", "IS"],
structure = [ ["CO1", "CO2", "CO3"], ["ES1", "ES2", "ES3", "ES4"], ["IS1", "IS2", "IS3"] ],
corr = "CORRELATED",
cluster = "school")

* It can sometimes be clearer if you identify the item lists before putting them 
* into the MplusCFA command, as in this second example.

* Example 2: 
COstruct = ["CO1", "CO2", "CO3"]
ESstruct = ["ES1", "ES2", "ES3", "ES4"]
ISstruct = ["IS1", "IS2", "IS3"]
MplusCFA(inpfile = "C:\users\jamie\workspace\spssmplus\CFA.inp",
names = ["CO", "ES", "IS"],
structure = [COstruct, ESstruct, ISstruct],
corr = "CORRELATED",
cluster = "school")


************
* Version History
************
* 2013-08-31 Created
* 2013-09-01 Obtained variable lists
* 2013-09-02 Created MplusProgram class
    Write input file
    Write and run batch file
* 2013-09-03 Created MplusOutput class
* 2013-09-03a Changed names of arguments
    Added default arguments
    Added clustering
* 2013-09-05 Replaced variable names in coefficients sections
* 2013-09-06 Replaced variable names in MI section
* 2013-09-08 Reordered variables in active data set after exporting
* 2013-09-09 Fixed missing semicolon in usevariables
    Added 2 sec delay before opening output to give the computer a chance
to save the file.
* 2013-09-12 Converted cluster variable name
* 2013-09-12a Made classes program-specific
* 2013-09-13 Removed effects of capitalization
    Used leading zeroes in renamed variable names
* 2013-09-14 Renamed variables after exporting to Mplus 

set printback = off.
begin program python.
import spss, spssaux, os, time
from subprocess import Popen, PIPE

def MplusSplit(splitstring, linelength):
    returnstring = ""
    curline = splitstring
    while (len(curline) > linelength):
        splitloc = linelength
        while (curline[splitloc] == " " or curline[splitloc-1] == " "):
            splitloc = splitloc -1
        returnstring = returnstring + curline[:splitloc] + "\n"
        curline = curline[splitloc:]
    returnstring += curline
    return returnstring

def SPSSspaceSplit(splitstring, linelength):
    stringwords = splitstring.split()
    returnstring = "'"
    curline = ""
    for word in stringwords:
        if (len(word) > linelength):
            break
        if (len(word) + len(curline) < linelength - 1):
            curline += word + " "
        else:
            returnstring += curline + "' +\n'"
            curline = word + " "
    returnstring += curline[:-1] + "'"
    return returnstring

def exportMplus(filepath):
######
# Get list of current variables in SPSS data set
######
 SPSSvarlist = []
 for varnum in range(spss.GetVariableCount()):
  SPSSvarlist.append(spss.GetVariableName(varnum))

#########
# Rename variables with names > 8 characters
#########
	for t in range(spss.GetVariableCount()):
		if (len(spss.GetVariableName(t)) > 8):
			name = spss.GetVariableName(t)[0:8]
			for i in range(spss.GetVariableCount()):
				compname = spss.GetVariableName(i)
				if (name.lower() == compname.lower()):
					name = "var" + "%05d" %(t+1)
			submitstring = "rename variables (%s = %s)." %(spss.GetVariableName(t), name)
			spss.Submit(submitstring)

##########
# Replace . with _ in the variable names
##########
	for t in range(spss.GetVariableCount()):
		oldname = spss.GetVariableName(t)
		newname = ""
		for i in range(len(oldname)):
			if(oldname[i] == "."):
				newname = newname +"_"
			else:
				newname = newname+oldname[i]
		for i in range(t):
			compname = spss.GetVariableName(i)
			if (newname.lower() == compname.lower()):
				newname = "var" + str(t+1)
		if (oldname != newname):
			submitstring = "rename variables (%s = %s)." %(oldname, newname)
			spss.Submit(submitstring)

# Obtain lists of variables in the dataset
	varlist = []
	numericlist = []
	stringlist = []
	for t in range(spss.GetVariableCount()):
		varlist.append(spss.GetVariableName(t))
		if (spss.GetVariableType(t) == 0):
			numericlist.append(spss.GetVariableName(t))
		else:
			stringlist.append(spss.GetVariableName(t))

###########
# Automatically recode string variables into numeric variables
###########
# First renaming string variables so the new numeric vars can take the 
# original variable names
	submitstring = "rename variables"
	for var in stringlist:
		submitstring = submitstring + "\n " + var + "=" + var + "_str"
	submitstring = submitstring + "."
	spss.Submit(submitstring)

# Recoding variables
 if (len(stringlist) > 0):
 	submitstring = "AUTORECODE VARIABLES="
	 for var in stringlist:
		 submitstring = submitstring + "\n " + var + "_str"
 	submitstring = submitstring + "\n /into"
	 for var in stringlist:
		 submitstring = submitstring + "\n " + var
 	submitstring = submitstring + """
   /BLANK=MISSING
   /PRINT."""
	 spss.Submit(submitstring)
	
# Dropping string variables
	submitstring = "delete variables"
	for var in stringlist:
		submitstring = submitstring + "\n " + var + "_str"
	submitstring = submitstring + "."
	spss.Submit(submitstring)

# Set all missing values to be -999
	submitstring = "RECODE "
	for var in varlist:
		submitstring = submitstring + " " + var + "\n"
	submitstring = submitstring + """ (MISSING=-999).
EXECUTE."""
	spss.Submit(submitstring)

########
# Convert date and time variables to numeric
########
# SPSS actually stores dates as the number of seconds that have elapsed since October 14, 1582.
# This syntax takes variables with a date type and puts them in their natural numeric form

 submitstring = """numeric ddate7663804 (f11.0).
alter type ddate7663804 (date11).
ALTER TYPE ALL (DATE = F11.0).
alter type ddate7663804 (adate11).
ALTER TYPE ALL (ADATE = F11.0).
alter type ddate7663804 (time11).
ALTER TYPE ALL (TIME = F11.0).

delete variables ddate7663804."""
 spss.Submit(submitstring)

######
# Obtain list of transformed variables
######
 submitstring = """MATCH FILES /FILE=*
  /keep="""
 for var in varlist:
		submitstring = submitstring + "\n " + var
 submitstring = submitstring + """.
EXECUTE."""
 spss.Submit(submitstring)
 MplusVarlist = []
 for varnum in range(spss.GetVariableCount()):
  MplusVarlist.append(spss.GetVariableName(varnum))

############
# Create data file
############
# Break filename over multiple lines
 splitfilepath = SPSSspaceSplit(filepath, 40)
# Save data as a tab-delimited text file
	submitstring = """SAVE TRANSLATE OUTFILE=
	%s
  /TYPE=TAB
  /MAP
  /REPLACE
  /CELLS=VALUES
	/keep""" %(splitfilepath)
	for var in varlist:
		submitstring = submitstring + "\n " + var
	submitstring = submitstring + "."
	spss.Submit(submitstring)

##############
# Rename variables back to original values
##############
 submitstring = "rename variables"
 for s, m in zip(SPSSvarlist, MplusVarlist):
  submitstring += "\n(" + m + "=" + s + ")"
 submitstring += "."
 spss.Submit(submitstring)

 return MplusVarlist

class MplusCFAprogram:
    def __init__(self):
        self.title = "TITLE:\n"
        self.data = "DATA:\n"
        self.variable = "VARIABLE:\n"
        self.define = "DEFINE:\n"
        self.analysis = "ANALYSIS:\n"
        self.model = "MODEL:\n"
        self.output = "OUTPUT:\n"
        self.savedata = "SAVEDATA:\n"
        self.plot = "PLOT:\n"
        self.montecarlo = "MONTECARLO:\n"

    def setTitle(self, titleText):
        self.title += titleText

    def setData(self, filename):
        self.data += "File is\n"
        splitName = MplusSplit(filename, 75)
        self.data += "'" + splitName + "';"

    def setVariable(self, fullList, struct, cluster):
        self.variable += "Names are\n"
        for var in fullList:
            self.variable += var + "\n"
        self.variable += ";\n\n"

# Determine usevaribles
        useList = []
        for factor in struct:
            for var in factor:
                if (var not in useList):
                    useList.append(var)
        self.variable += "Usevariables are\n"
        for var in useList:
            self.variable += var + "\n"
        if (cluster != None):
            self.variable += ";\n\ncluster is " + cluster + ";"
        else:
            self.variable += ";"
        self.variable += "\n\nMISSING ARE ALL (-999);"

    def setAnalysis(self, cluster):
        if (cluster != None):
            self.analysis += "type = complex;"

    def setModel(self, factorNames, struct, corrUncorr):
# Factor definition statements
        for t in range(len(factorNames)):
            if (t == 0):
                curLine = ""
            else:
                curLine = "\n"
            curLine += factorNames[t] + " by"
            for var in struct[t]:
                if (len(curLine) + len(var) < 75):
                    curLine += " " + var
                else:
                    self.model += curLine
                    curLine = var
            self.model += curLine + ";"

# Covariances
        if (corrUncorr == "CORRELATED"):
            for t in range(len(factorNames)):
                var1 = factorNames[t]
                for var2 in factorNames[t+1:]:
                    if (var1 != var2):
                        self.model += "\n" + var1 + " with " + var2 + ";"

    def setOutput(self, outputText):
        self.output += outputText

    def write(self, filename):
# Write input file
        sectionList = [self.title, self.data, self.variable, self.define,
self.analysis, self.model, self.output, self.savedata, 
self.plot, self.montecarlo]
        outfile = open(filename, "w")
        for sec in sectionList:
            if (sec[-2:] != ":\n"):
                outfile.write(sec)
                outfile.write("\n\n")
        outfile.close()

def batchfile(directory, filestem):
# Write batch file
    batchFile = open(directory + "/" + filestem + ".bat", "w")
    batchFile.write("cd " + directory + "\n")
    batchFile.write("call mplus \"" + filestem + ".inp" + "\"\n")
    batchFile.close()

# Run batch file
    p = Popen(directory + "/" + filestem + ".bat", cwd=directory)

def removeBlanks(processString):
    for t in range(len(processString), 0, -1):
            if (processString[t-1] != "\n"):
                return (processString[0:t])

class MplusCFAoutput:
    def __init__(self, filename, latents, Mplus, SPSS):
        time.sleep(2)
        infile = open(filename, "r")
        fileText = infile.read()
        infile.close()
        outputList = fileText.split("\n")

# Summary
        for t in range(len(outputList)):
            if ("SUMMARY OF ANALYSIS" in outputList[t]):
                start = t
            if ("Number of continuous latent variables" in outputList[t]):
                end = t
        self.summary = "\n".join(outputList[start:end+1])

# Warnings
        for t in range(len(outputList)):
            if ("Covariance Coverage" in outputList[t]):
                covcov = t
        blank = 0
        for t in range(covcov, len(outputList)):
            if (len(outputList[t]) < 2):
                blank = 1
            if (blank == 1 and len(outputList[t]) > 1):
                start = t
                break
        for t in range(start, len(outputList)):
            if ("MODEL FIT INFORMATION" in outputList[t]):
                end = t
                break
        self.warnings = "\n".join(outputList[start:end])
        self.warnings = removeBlanks(self.warnings)

# Fit statistics
        start = end
        for t in range(start, len(outputList)):
            if ("MODEL RESULTS" in outputList[t]):
                end = t
                break
        self.fit = "\n".join(outputList[start:end])
        self.fit = removeBlanks(self.fit)

# Unstandardized estimates
        start = end
        for t in range(start, len(outputList)):
            if ("STANDARDIZED MODEL RESULTS" in outputList[t]):
                end = t
                break

        self.estimates = "\n".join(outputList[start:end])
        self.estimates = removeBlanks(self.estimates)

# Standardized estimates
        for t in range(end, len(outputList)):
            if ("STDYX" in outputList[t]):
                start = t
                break
        for t in range(start, len(outputList)):
            if ("R-SQUARE" in outputList[t]):
                end = t
                break
        self.standardized = "\n".join(outputList[start:end])
        self.standardized = removeBlanks(self.standardized)

# R squares
        start = end
        for t in range(start, len(outputList)):
            if ("QUALITY OF NUMERICAL RESULTS" in outputList[t]):
                end = t
                break
        self.r2 = "\n".join(outputList[start:end])
        self.r2 = removeBlanks(self.r2)

# Modification indices
        for t in range(end, len(outputList)):
            if ("MODEL MODIFICATION INDICES" in outputList[t]):
                start = t
                break
        for t in range(start, len(outputList)):
            if ("Beginning Time" in outputList[t]):
                end = t-1
                break
        self.mi = "\n".join(outputList[start:end])
        self.mi = removeBlanks(self.mi)

# Replacing variable names
# In the Coefficients section, initially room for 17
#    A) Increasing overall width from 61 to 75 = gain of 14
# In the Modification indices section, 
# there is initially room for 2 vars X 10 characters
#    A) Increasing overall width from 67 to 77 = gain of 5 for each var
#    B) Drop STD EPC = gain of 6 for each var
#    C) Change "StdYX E.P.C." to "StdYX EPC" = gain of 2 for each var
# Making all variables length of 23

# Coefficients sections
# Variables
        for var1, var2 in zip(Mplus, SPSS):
            var1 += " "*(8-len(var1))
            if (len(var2) < 23):
                var2 += " "*(23-len(var2))
            else:
                var2 = var2[:23]
            self.estimates = self.estimates.replace(var1.upper(), var2)
            self.standardized = self.standardized.replace(var1.upper(), var2)
# Latents
        for var in latents:
            oldvar = var.upper() + " "*(8-len(var))
            newvar = var + " "*(23-len(var))
            self.estimates = self.estimates.replace(oldvar, newvar)
            self.standardized = self.standardized.replace(oldvar, newvar)
# Headers
        oldheader = """                                                    Two-Tailed
                    Estimate       S.E.  Est./S.E.    P-Value"""
        newheader = """                                                                   Two-Tailed
                                   Estimate       S.E.  Est./S.E.    P-Value"""
        self.estimates = self.estimates.replace(oldheader, newheader)
        self.standardized = self.standardized.replace(oldheader, newheader)

# MI section
        for var1, var2 in zip(Mplus, SPSS):
            if (len(var2) > 23):
                var2 = var2[:23]
            self.mi = self.mi.replace(var1.upper(), var2)
        self.mi = self.mi.replace("""M.I.     E.P.C.  Std E.P.C.  StdYX E.P.C.""",
"""                          MI         EPC   StdYX EPC""")
        newMI = []
        miLines = self.mi.split("\n")
        for line in miLines:
            if (("BY" in line or "WITH" in line) and "Statements" not in line):
                miWords = line.split()
                newLine = miWords[0] + " "*(23-len(miWords[0]))
                newLine += " " + miWords[1] + " "*(5-len(miWords[1]))
                newLine += miWords[2] + " "*(23-len(miWords[2]))
                newLine += " "*(8-len(miWords[3])) + miWords[3] + "  "
                newLine += " "*(8-len(miWords[4])) + miWords[4] + "  "
                newLine += " "*(8-len(miWords[6])) + miWords[6] + "  "
                newMI.append(newLine)
            else:
                newMI.append(line)
        self.mi = "\n".join(newMI)

# Print function
    def toSPSS(self):
        spss.Submit("title 'SUMMARY'.")
        print self.summary
        spss.Submit("title 'WARNINGS'.")
        print self.warnings
        spss.Submit("title 'FIT STATISTICS'.")
        print self.fit
        spss.Submit("title 'UNSTANDARDIZED ESTIMATES'.")
        print self.estimates
        spss.Submit("title 'STANDARDIZED ESTIMATES'.")
        print self.standardized
        spss.Submit("title 'R-SQUARES'.")
        print self.r2
        spss.Submit("title 'MODIFICATION INDICES'.")
        print self.mi    

def MplusCFA(inpfile, names, structure, corr = "CORRELATED", cluster = None):
# Find directory and filename
    for t in range(len(inpfile)):
        if (inpfile[-t] == "/"):
            break
    outdir = inpfile[:-t+1]
    fname, fext = os.path.splitext(inpfile[-(t-1):])

# Obtain list of variables in data set
    SPSSvariables = []
    SPSSvariablesCaps = []
    for varnum in range(spss.GetVariableCount()):
        SPSSvariables.append(spss.GetVariableName(varnum))
        SPSSvariablesCaps.append(spss.GetVariableName(varnum).upper())

# Check for errors
    error = 0
    if (fext.upper() != ".INP"):
        print ("Error: Input file specification does not end with .inp")
        error = 1
    if (len(names) != len(structure)):
        print ("Error: Name list and structure list have different lengths")
        error = 1
    if (not os.path.exists(outdir)):
        print("Error: Output directory does not exist")
        error = 1
    variableError = 0
    for factor in structure:
        for var in factor:
            if (var.upper() not in SPSSvariablesCaps):
                variableError = 1
    if (variableError == 1):
        print("Error: Variable listed in structure not in current data set")
        error = 1
    variableError = 0
    for var in names:
        if len(var) > 8:
            variableError = 1
    if (variableError == 1):
        print ("Error: Latent variable names must be 8 characters or fewer")
        error = 1
    if (corr.upper() != "CORRELATED" and corr.upper() != "UNCORRELATED"):
        print ('Error: Must declare factors as \"CORRELATED\" or \"UNCORRELATED\"')
        error = 1

# Replace . with _ in latent variable names
    for t in range(len(names)):
        names[t] = names[t].replace(".", "_")

    if (error == 0):
# Export data
        dataname = outdir + fname + ".dat"
        MplusVariables = exportMplus(dataname)

# Define structure using Mplus variables
        MplusStructureList = []
        for factor in structure:
            newStruct = []
            for var in factor:
                for t in range(len(SPSSvariables)):
                    if (var.upper() == SPSSvariablesCaps[t]):
                        newStruct.append(MplusVariables[t])
            MplusStructureList.append(newStruct)

# Convert cluster variable to Mplus
        if (cluster == None):
            MplusCluster = None
        else:
            for s, m in zip(SPSSvariablesCaps, MplusVariables):
                if (cluster.upper() == s):
                    MplusCluster = m
        

# Create input program
        cfaProgram = MplusCFAprogram()
        cfaProgram.setTitle("Created by MplusCFA")
        cfaProgram.setData(dataname)
        cfaProgram.setVariable(MplusVariables, MplusStructureList, MplusCluster)
        cfaProgram.setAnalysis(MplusCluster)
        cfaProgram.setModel(names, MplusStructureList, corr)
        cfaProgram.setOutput("stdyx;\nmodindices;")
        cfaProgram.write(outdir + fname + ".inp")
        
# Run input program
        batchfile(outdir, fname)

# Parse output
        CFAoutput = MplusCFAoutput(outdir + fname + ".out", 
names, MplusVariables, SPSSvariables)
        CFAoutput.toSPSS()

end program python.
set printback = on.
COMMENT BOOKMARK;LINE_NUM=360;ID=1.
COMMENT BOOKMARK;LINE_NUM=480;ID=2.
