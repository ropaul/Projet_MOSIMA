Projet MOSIMA: Yann ROPAUL and Jules BROCHARD

Files names *.nlogo at the root of this folder contains multi-agents simulations which reproduce the work described in "Emergence of the Matching Function in Multi.pdf".
More specifically:

  --- "basic_model.nlogo" enable the user to manipulate the initial model
  --- "basic_model_more_measures.nlogo" add more measure to the initial model
  --- "beveridge_2.nlogo" runs multiples simulations and compute beveridge curves
  --- "sensibilityParametresensibility_analysis.nlogo" propose to modify up to 3 parameters and monitors there influence on the model
  --- "extended_model.nlogo" add behavioral extensions to the model
  ---
  
These "*.nlogo" files only exploit the below files and propose specific graphic interface.

In the folder "code" there are thematic code grouped together:
  --- "go.nls" presenting all the dynamic procedures of the simulations
  --- "setup.nls" containing all the variable declarations and default values
  --- "display.nls" where all the graph and regressing are created
  --- "measures.nls" compute the different evaluation of the simulations
  --- "miscellaneous.nls" store what cannot fit elsewhere

  --- "plot.nls" is one extra file not stored in the code folder, which have the same purpose as "code/display.nls"
