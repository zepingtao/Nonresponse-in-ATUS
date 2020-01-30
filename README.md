# Nonresponse trends in American Time Use Survey: 2004-2016

This is a study I did with Z. Tuba Suzer-Gurtekin, Assistant Research Scientist, Survey Research Center, University of Michigan. We studied how nonresponse pattern changes in American Time Use Survey (ATUS) from 2004 to 2016. The sample of ATUS is draw from Current Population Survey (CPS) respondents, so we have comparable information for both ATUS respondents and nonrespondents, such as age, marital status, education, presence of children, etc. We applied logistic regression to analyze the data and I presented the result at the 2019 annual conference of Midwest Association for Public Opinion Research (MAPOR). After the presentation, we applied classification tree method for further analysis. 

[The SAS program](NonresponseATUS_update2018_weighted.sas) (["NonresponseATUS_update2018_weighted.sas"](NonresponseATUS_update2018_weighted.sas)) includes how we cleaned and preprocessed data that we extracted from [IPUMS TIME USE](https://timeuse.ipums.org/) and [IPUMS CPS](https://cps.ipums.org/cps/). It also includes how we analyzed the data using logistic regression and classification tree method. The steps in the program code are listed in ["Steps in data cleaning and analysis.docx"](Steps in data cleaning and analysis.docx).


Here is a brief summary of our analysis result:

1.	Conclusion from logistic regression
* In both periods (2004-2008 and 2009-2016), we find household with children (both under 6 and 6-17) tend not to respond and are harder to be contacted.
*	In both periods (2004-2008 and 2009-2016), we find respondent working 35-44 hours per hour has no significant difference on response or cooperation compared to the respondents not in labor force or unemployed. The pattern is similar in terms of the working status of respondent's spouse. 
*	The positive effect on response or cooperation of certain predictors shrink from period 2004-2008 to 2009-2016
  *	Married compared to Divorced
  *	Nonmetropolitan compared to Central city
  
2.	Conclusion from classification tree
*	Housing tenure, education, survey year, age and race/ethnicity are the five most important variables to predict response rate. 
*	Certain variables perform differently between prediction on contact rate and on cooperation rate.
  *	Housing tenure is the most important variable to predict contact rate and response rate but one of the least important variables to predict cooperation rate (the 15th important variable out of 17 variables in total).
  *	Phone availability, marital status are important variables to predict contact rate but much less important to predict cooperation rate.
  *	Metropolitan status is an important variable to predict cooperation rate but is one of the least important variable to predict cooperation rate.
  *	Survey year is the most important variable to predict cooperation rate but is much less important to predict contact rate. 

See [full MAPOR presentation slides](https://drive.google.com/file/d/1_xYzXlo6uWyXwu8zEUL8E_A9luQepBZx/view?usp=sharing).


