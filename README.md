#MplusCFA

SPSS Python Extension function that will use Mplus to run a confirmatory factor analysis from within SPSS

This program allows users to identify a factor structure that they want to test on an SPSS data set. The program then converts the active data set to Mplus format, writes a program that will perform the CFA in Mplus, then loads the important parts of the Mplus output into the SPSS output window.

This and other SPSS Python Extension functions can be found at http://www.stat-help.com/python.html

##Usage
**MplusCFA(impfile, names, structure, corr, cluster)**
* "impfile" is a string identifying the directory and filename of Mplus input file to be created by the program. This filename must end with .inp . The data file will automatically be saved to the same directory. This argument is required.
* "names" is a list containing the names that will be used by Mplus label your factors. These should be provided as strings. These names must follow the rules for variable names in Mplus. The order of the names in the list should correspond to the order of the structures identified in the factor structure list. This argument is required.
* "structure" is actually a list of lists identifying your factor structure. First, you create a set of lists that each identify the items loading on a particular factor. Then you combine these individual factor lists  into a larger list identifying the entire factor structure. This argument is required.
* "corr" is an optional argument that can take on the values of "CORRELATED" or "UNCORRELATED". This specifies whether you want to allow the latent factors to be correlated.  This defaults to "CORRELATED".
* "cluster" is an optional argument that identifies a cluster variable. This will be included using the Type = complex analysis command in Mplus. This defaults to None, which indicates that there is no clustering. 

##Example
**MplusCFA(inpfile = "C:\users\jamie\workspace\spssmplus\CFA.inp",  
names = ["CO", "ES", "IS"],  
structure = [ ["CO1", "CO2", "CO3"], ["ES1", "ES2", "ES3", "ES4"], ["IS1", "IS2", "IS3"] ],  
corr = "CORRELATED",  
cluster = "school")**
* The Mplus input file created for this analysis will be saved in the file "C:\users\jamie\workspace\spssmplus\CFA.inp".
* The CFA itself will have three latent factors with the names "CO", "ES", and "IS".
  * The CO factor is defined by the observed variables "CO1", "CO2", and "CO3".
  * The ES factor is defined by the observed variables "ES1", "ES2", "ES3", and "ES4".
  * The IS factor is defined by the observed variables "IS1", "IS2", and "IS3".
* The latent factors are allowed to correlate.
* The variable "school" is included as a cluster variable in the analysis.

It can sometimes be clearer if you identify the item lists before putting them into the MplusCFA command. The following syntax runs the same model as above, but separating the lists makes it easier to read.

**COstruct = ["CO1", "CO2", "CO3"]  
ESstruct = ["ES1", "ES2", "ES3", "ES4"]  
ISstruct = ["IS1", "IS2", "IS3"]  
MplusCFA(inpfile = "C:\users\jamie\workspace\spssmplus\CFA.inp",  
names = ["CO", "ES", "IS"],  
structure = [COstruct, ESstruct, ISstruct],  
corr = "CORRELATED",  
cluster = "school")**
