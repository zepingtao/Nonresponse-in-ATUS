/*author: Zeping Tao
/*date: July 10th 2019
/*purpose:
	Calculate nonresponse rate and other interview outcome rate by certain variables, using ATUS 2004-2018 data
	further analysis on nonresponse trends
	updating with the 2018 ATUS data
	using the weighted data 2004-2016
/*input: 
	"T:\USER\Zeping\Nonresponse in ATUS\Data - 2018 update"*/
/*output:
	T:\USER\Zeping\Nonresponse in ATUS\output - weighted 2018 update*/


/*1.Input*/
libname ATUS18 "T:\USER\Zeping\Nonresponse in ATUS\Data - 2018 update";
Data ATUS;
set ATUS18.atus_00030;
HRHHID_CPS8_char = put(HRHHID_CPS8,15.);
CASEID_char = put(CASEID,14.);
run;

/*1.1 check duplicates*/
proc sql;
create table ATUS_Duppairs_SQL as
select * from ATUS
group by YEAR_CPS8, MONTH_CPS8, HRHHID_CPS8_char, HRHHID2_CPS8
having count(*) >= 2;
quit;

data ATUS18.ATUS_Duppairs;
set ATUS_Duppairs_SQL;
length RType $2;
if OUTCOME in(100,200) then RType = "C";
else if OUTCOME in(301,303) then RType = "R";
else if OUTCOME in(401,402,403) then RType = "NC";
else if OUTCOME in(501,502,503,504) then RType = "O";
else if OUTCOME in(601,602,603,604,605,607) then RType = "NE";
else if OUTCOME in(701,702,703,704,705,707,9999) then RType = "UE";
if RType = "C" then response = 1;
else if RType = "NE" then response =.;
else response =0;
run;

proc freq data=ATUS18.ATUS_Duppairs;
tables year*RType / nopercent nocol norow;
run;

Data ATUS_Dups2017;
set ATUS_Duppairs_SQL;
where year=2017;
run;

proc SQL;
create table ATUS_deduplicate as
select * from ATUS
LEFT JOIN ATUS_Dups2017
ON ATUS.CASEID_char = ATUS_Dups2017.CASEID_char
WHERE ATUS_Dups2017.CASEID_char IS NULL;
quit;

proc print data=ATUS_deduplicate;
where CASEID_char='20180110171874';
run;

Data ATUS18.ATUS;
set ATUS_deduplicate;
run;

proc print data=ATUS18.ATUS;
where CASEID_char='20171210171060';
run;

proc sql;
select * from ATUS_deduplicate
group by YEAR_CPS8, MONTH_CPS8, HRHHID_CPS8_char, HRHHID2_CPS8
having count(*) >= 2;
quit;

/*2. linking datasets*/
/*2.1 link CPS*/
Data ATUS18.CPS(rename=(HRHHID=HRHHID_CPS8	
LINENO=LINENO_CPS8	MONTH=MONTH_CPS8 YEAR=YEAR_CPS8 HRSERSUF=HRSERSUF_CPS8  HRSAMPLE=HRSAMPLE_CPS HRHHID2=HRHHID2_CPS8 AGE=AGE_CPS 
SEX=SEX_CPS Relate=Relate_CPS METRO=METRO_CPS) );
set ATUS18.cps_00010;
if MISH =8;
run;

Data ATUS18.CPS;
set ATUS18.CPS;
HRHHID_CPS8_char = put(HRHHID_CPS8,15.);
run;

	/*2.1.1 check duplicate*/
proc sql;
create table CPS_Duppairs_SQL as
select * from ATUS18.CPS
group by YEAR_CPS8, MONTH_CPS8, HRHHID_CPS8_char, HRHHID2_CPS8, LINENO_CPS8
having count(*) >= 2;
quit;

/*2.1.2 preprocess linking variables*/
Data ATUS18.ATUS;
set ATUS18.ATUS;
length HHLink2 $5;
if YEAR_CPS8 > 2004 or (YEAR_CPS8=2004 and MONTH_CPS8 >=5) then HHlink2 = put(HRHHID2_CPS8,5.);
else HHlink2 = HRSERSUF_CPS8;
run;

proc freq data=ATUS18.ATUS;
tables HHlink2*HRSERSUF_CPS8 / nopercent nocol norow;
where YEAR_CPS8 =2003 or (YEAR_CPS8=2004 and MONTH_CPS8 <5);
run;

Data ATUS18.CPS;
set ATUS18.CPS;
length HHLink2 $5;
if YEAR_CPS8 > 2004 or (YEAR_CPS8=2004 and MONTH_CPS8 >=5) then HHlink2 = put(HRHHID2_CPS8,5.);
else HHlink2 = HRSERSUF_CPS8;
run;

proc freq data=ATUS18.CPS;
tables HHlink2*HRSERSUF_CPS8 / nopercent nocol norow;
where YEAR_CPS8 =2003 or (YEAR_CPS8=2004 and MONTH_CPS8 <5);
run;

data check;
set ATUS18.CPS;
if (YEAR_CPS8 > 2004 or (YEAR_CPS8=2004 and MONTH_CPS8 >=5)) and HHlink2 NE put(HRHHID2_CPS8,5.) then check =1;
else check=0;
run;

proc print data=check;
where check=1;
run;

/*2.1.3 merging CPS with ATUS*/
proc sort data=ATUS18.ATUS;
by YEAR_CPS8 MONTH_CPS8 HRHHID_CPS8_char HHlink2 LINENO_CPS8;
run;

proc sort data=ATUS18.CPS;
by YEAR_CPS8 MONTH_CPS8 HRHHID_CPS8_char HHlink2 LINENO_CPS8;
run;

data ATUS18.ATUS_CPS;
merge ATUS18.ATUS(in=inatus) ATUS18.CPS(in=incps);
by YEAR_CPS8 MONTH_CPS8 HRHHID_CPS8_char HHlink2 LINENO_CPS8;
if inatus=1;
run;

/*2.2 checking missing values*/
proc freq data=ATUS18.ATUS_CPS;
tables METRO*METRO_CPS/nopercent nocol norow missing;
run;

data ATUS18.ATUS_CPS(drop=ASECFLAG);
set ATUS18.ATUS_CPS;
run;

proc contents data=ATUS18.ATUS_CPS out=cols noprint;
run;

proc format;
 value $missfmt ' '='Missing' other='Not Missing';
 value  missfmt  . ='Missing' other='Not Missing';
run;
 
proc freq data=ATUS18.ATUS_CPS; 
format _CHAR_ $missfmt.; /* apply format for the duration of this PROC */
tables _CHAR_ / missing missprint nocum nopercent;
format _NUMERIC_ missfmt.;
tables _NUMERIC_ / missing missprint nocum nopercent;
run;

/*3. Preprocessing */
	/*3.1 making format labels*/
proc format;
	value AgeGroupCode
			1="18-34"
			2="35-54"
			3="over 55";
	value MetroCode
			1='Metropolitan, central city'
			2='Metropolitan, balance of MSA'
			3='Metropolitan, not identified'
			4='Nonmetropolitan'
			5='Not identified';
	value RegionCode
			1='Northeast'
			2='Midwest'
			3='South'
			4='West';
	value PhoneCode
			1='No phone available'
			2='Phone available; not in household'
			3='Phone available in household';
	value ChildrenCode
			0='No'
			1='Yes';
	value RaceCode
			404='White-American Indian-Asian-Hawaiian'
			398='Other 3 race combinations'
			100='White only'
			110='Black only'
			120='American Indian, Alaskan Native'
			130='Asian or Pacific Islander'
			131='Asian only'
			132='Hawaiian Pacific Islander only'
			200='White-Black'
			201='White-American Indian'
			202='White-Asian'
			203='White-Hawaiian'
			210='Black-American Indian'
			211='Black-Asian'
			212='Black-Hawaiian'
			220='American Indian-Asian'
			221='American Indian-Hawaiian'
			230='Asian-Hawaiian'
			300='White-Black-American Indian'
			301='White-Black-Asian'
			302='White-Black-Hawaiian'
			310='White-American Indian-Asian'
			311='White-American Indian-Hawaiian'
			320='White-Asian-Hawaiian'
			330='Black-American Indian-Asian'
			331='Black-American Indian-Hawaiian'
			340='Black-Asian-Hawaiian'
			350='American Indian-Asian-Hawaiian'
			399='2 or 3 races, unspecified'
			400='White-Black-American Indian-Asian'
			401='White-Black-American Indian-Hawaiian'
			402='White-Black-Asian-Hawaiian'
			403='Black-American Indian-Asian-Hawaiian'
			500='White-Black-American Indian-Asian-Hawaiian'
			599='4 or 5 races, unspecified'
			9999='NIU (Not in universe)';
		value MaritalCode
			1='Married - spouse present'
			2='Married - spouse absent'
			3='Widowed'
			4='Divorced'
			5='Separated'
			6='Never married'
			99='NIU (Not in universe)';
		value Mar_KGACode
			1='Married'
			3='Widowed'
			4='Divorced'
			5='Separated'
			6='Never married'
			99='NIU (Not in universe)';
		value SexCode
			1='Male'
			2='Female'
			99='NIU (Not in universe)';
		value WorkHrGrpCode
			1= "NILF or unemployed"
			2= "Less than 35 hours/week"
			3= "35-44 hours/week"
			4= "45 or more hours/week"
			5= "Hours vary"
			9= "NIU (Not in universe)";
		value HHTenureCode
			0="Not in Universe"
			1='Owned or being bought by a household member'
			2='Rented for cash'
			3='Occupied without payment of cash rent';
		value RelateCode
			101='Head/householder'
			201='Spouse'
			301='Child'
			303='Stepchild'
			501='Parent'
			701='Sibling'
			901='Grandchild'
			1001='Other relatives, n.s.'
			1113='Partner/roommate'
			1114='Unmarried partner'
			1115='Housemate/roomate'
			1241='Roomer/boarder/lodger'
			1242='Foster children'
			1260='Other nonrelatives'
			9100='Armed Forces, relationship unknown'
			9200='Age under 14, relationship unknown'
			9900='Relationship unknown'
			9999='NIU';
		value FamincCode
			1='Less than $5,000'
			2='$5,000 to $7,499'
			3='$7,500 to $9,999'
			4='$10,000 to $12,499'
			5='$12,500 to $14,999'
			6='$15,000 to $19,999'
			7='$20,000 to $24,999'
			8='$25,000 to $29,999'
			9='$30,000 to $34,999'
			10='$35,000 to $39,999'
			11='$40,000 to $49,999'
			12='$50,000 to $59,999'
			13='$60,000 to $74,999'
			14='$75,000 to $99,999'
			15='$100,000 to $149,999'
			16='$150,000 and over'
			996='Refused'
			997="Don't know"
			998='Blank';
		value FamIncGrpCode
			1="Less than $20,000"
			2="$20,000-$39,999"
			3="$40,000-$74,999"
			4="$75,000 or more"
			9="Missing/Unknown";
		value EducGrpCode
			0="Not in Universe"
			1="Less than high school"
			2="High school"
			3="Some college"
			4="Bachelor's degree"
			5="Graduate degree"
			9="Missing/Unknown";
		value RcEhnCode
			1="Hispanic"
			2="Non-Hispanic black"
			3="Other";
		value AgeGrp5Code
			1="18-34"
			2="35-44"
			3="45-54"
			4="55-64"
			5="65+";
		value EmployCode
			1='Employed - at work'
			2='Employed - absent'
			3='Unemployed - on layoff'
			4='Unemployed - looking'
			5='Not in labor force - retired'
			6='Not in labor force - disabled'
			7='Not in labor force - other'
			99='NIU (Not in universe)';
		value Agegrp_KGACode
			1='15-30'
			2='31-45'
			3='46-55'
			4='56-65'
			5='Over 65';
		value Spouse_WorkHrGrpCode
			1= "NILF or unemployed"
			2= "Less than 35 hours/week"
			3= "35-44 hours/week"
			4= "45 or more hours/week"
			5= "Hours vary"
			7= "No spouse"
			9= "NIU or fail to link spouse";
		value HHTenure_KGACode
			1= "Owned"
			2= "Rent"
			99= "NIU (Not in Universe)";
		value METRO_CPSCode
			0 = "Not identified"
			1 = "Nonmetropolitan"
			2 = "Central City"
			3 = "Balance of MSA"
			4 = "Other metropolitan";
		value HHTypeCode
			1 = "With at least one child under 6"
			2 = "With at least one child between 6 and 17"
			3 = "Single adult, no children under 18"
			4 = "Two or more adults, no children under 18";
run;

	/*3.2 reconstruct interview outcome variables*/
Data ATUS18.ATUS_CPS;
set ATUS18.ATUS_CPS;
length RType $2;
if OUTCOME in(100,200) then RType = "C";
else if OUTCOME in(301,303) then RType = "R";
else if OUTCOME in(401,402,403) then RType = "NC";
else if OUTCOME in(501,502,503,504) then RType = "O";
else if OUTCOME in(601,602,603,604,605,607) then RType = "NE";
else if OUTCOME in(701,702,703,704,705,707,9999) then RType = "UE";
if RType = "C" then response = 1;
else if RType = "NE" then response =.;
else response =0;
if RType = "NC" or RType = "UE" then contact = 0;
else if RType = "NE" then contact =.;
else contact = 1;
if RType = "C" then cooperation = 1;
else if RType = "NC" or RType = "UE" or RType = "NE" then cooperation = .;
else cooperation = 0;
length RTypeKGA $2;
if outcome_alt in (110,120) then RTypeKGA = "C";
else if outcome_alt in(210,220,230,240,260) then RTypeKGA = "NE";
else if 300 <outcome_alt < 600 then RTypeKGA = "NC";
else if outcome_alt in (610,620,630) then RTypeKGA = "O";
else if outcome_alt in (710,720) then RTypeKGA = "R";
else if outcome_alt = 810 then RTypeKGA = "UE";
if RTypeKGA = "NE" then Resp_KGA = .;
else if RTypeKGA = "C" then Resp_KGA = 1;
else Resp_KGA = 0;
if RTypeKGA = "NE" then Cont_KGA =.;
else if RTypeKGA in ("C","R","O") then Cont_KGA= 1;
else Cont_KGA=0;
if RTypeKGA = "C" then Coop_KGA = 1;
else if RTypeKGA in ("C","R","O") then Coop_KGA =0;
else Coop_KGA =.;
if RTypeKGA = "NC" and Resp_KGA = 0 then NCinNonR = 1;
else if Resp_KGA =0 then NCinNonR =0;
if RTypeKGA = "R" and Resp_KGA = 0 then RfinNonR = 1;
else if Resp_KGA =0 then RfinNonR =0;
if RTypeKGA = "O" and Resp_KGA = 0 then OinNonR =1;
else if Resp_KGA =0 then OinNonR =0;
if RTypeKGA = "R" then Ref_KGA = 1;
else if RTypeKGA in ("C","R","NC","O","UE") then Ref_KGA = 0;
else Ref_KGA = .;
run;

	/* 3.3 make two variables about presence of children*/
data atus18.atus_HHmember;
set ATUS18.ATUS_00037HH;
CASEID_char = put(CASEID,14.);
if AGE_CPS8 <=5 then child5 = 1;
else child5=0;
if 6<=AGE_CPS8<=17 then child17 = 1;
else child17 =0;
run;

proc sort data=atus18.atus_HHmember;
by year CASEID_char;
run;

proc means data=atus18.atus_HHmember MEAN noprint;
var child17 child5;
by year CASEID_char;
output  out=child(drop=_TYPE_) mean= / autoname;
run;

data child;
set child;
if child17_Mean >0 then child17 =1;
else child17=0;
if child5_Mean >0 then child5=1;
else child5=0;
run;

proc sort data=atus18.atus_cps;
by year CASEID_char;
run;

proc sort data=child;
by year CASEID_char;
run;

proc freq data=child;
tables child5 child17/missing;
run;

data atus18.atus_cps;
merge child(drop=child17_Mean child5_Mean _FREQ_) atus18.atus_cps(in=inb);
by year CASEID_char;
if inb=1;
run;

	/*3.4 make spouse work hours variable*/
Data ATUS_spousetolink(keep=Year CASEID CASEID_char MARST UHRSWORKT_CPS8 
EMPSTAT_CPS8 RELATE LINENO_CPS8 rename=(LINENO_CPS8=ASPOUSE UHRSWORKT_CPS8=spouse_workhr 
RELATE=spouse_relate MARST=spouse_MARST EMPSTAT_CPS8=spouse_employ));
set ATUS18.ATUS_HHmember;
CASEID_char = put(CASEID,14.);
run;

proc freq data=ATUS18.ATUS_CPS;
tables ASPOUSE*year/nopercent nocol norow missing;
run;

proc freq data=ATUS18.ATUS_CPS;
tables ASPOUSE*marst/nopercent nocol norow missing;
format MARST MaritalCode.;
run;

proc means data=ATUS_spousetolink NMISS N;
var spouse_workhr;
run;

proc sql;
select * from ATUS18.ATUS_CPS
group by year, CASEID_char, ASPOUSE
having count(*) >= 2;
quit;

proc sort data=ATUS_spousetolink;
by year CASEID_char ASPOUSE;
run;

proc sort data=ATUS18.ATUS_CPS;
by year CASEID_char ASPOUSE;
run;

Data ATUS18.ATUS_CPS;
merge ATUS_spousetolink(in=ina) ATUS18.ATUS_CPS(in=inb);
by year CASEID_char ASPOUSE;
if inb=1;
format EMPSTAT_CPS8 EmployCode. spouse_employ EmployCode.;
run;

Data ATUS18.ATUS_CPS;
set ATUS18.ATUS_CPS;
if ASPOUSE in (0,-1) then spouse_WorkHrGrp=7;
else if spouse_employ = 99 then spouse_WorkHrGrp=9;
else if spouse_workhr=. and spoouse_employ=. then spouse_WorkHrGrp=9;
else if spouse_workhr = 9999 then spouse_WorkHrGrp =1;
else if spouse_workhr < 35 then spouse_WorkHrGrp =2;
else if 35<= spouse_workhr <=44 then spouse_WorkHrGrp =3;
else if 45 <= spouse_workhr <9995 then spouse_WorkHrGrp =4;
else if spouse_workhr = 9995 then spouse_WorkHrGrp = 5;
format spouse_WorkHrGrp Spouse_WorkHrGrpCode.;
run;

proc freq data=ATUS18.ATUS_CPS;
tables spouse_employ/missing;
where ASPOUSE >0 and spouse_workhr=.;
run;

proc freq data=ATUS18.ATUS_CPS;
tables AGE_CPS8;
where spouse_employ=99 and AGE_CPS8 <18;
run;

proc freq data=ATUS18.ATUS_CPS;
tables spouse_WorkHr /missing;
where year_CPS8=2004;
run;

	/*check if ASPOUSE fails to link any records*/
proc means data=ATUS18.ATUS_CPS NMISS N;
var spouse_workhr;
run;

Data spouse_checkmissing; 
set ATUS18.ATUS_CPS;
where ASPOUSE >0 and spouse_workhr=.;
run;

proc means data=ATUS18.ATUS_CPS NMISS N;
var spouse_workhr;
run;

		/*inner join*/
proc SQL; 
SELECT * FROM ATUS_spousetolink
INNER JOIN spouse_checkmissing 
ON ATUS_spousetolink.CASEID_char = spouse_checkmissing.CASEID_char
AND ATUS_spousetolink.ASPOUSE = spouse_checkmissing.ASPOUSE;
quit;
		/*0 joined --> 1331 unlinked in total*/
proc freq data=ATUS18.ATUS_CPS;
tables spouse_WorkHrGrp/missing;
where year=2004;
run;

	/*3.5 make relate/non-relate household member variables*/
data atus_HHadults;
set ATUS18.atus_HHmember;
if AGE_CPS8 > 17 and 3 < Relate_CPS8 < 9 then HHrelate=1;
else HHrelate=0;
if Relate_CPS8=999 then HHnonrela=.;
else if AGE_CPS8 > 17 and Relate_CPS8 >8 then HHnonrela=1;
else HHnonrela=0;
run;

proc sort data=ATUS_HHadults;
by year CASEID_char;
run;

proc means data=ATUS_HHadults SUM noprint;
var HHrelate HHnonrela;
by year CASEID_char;
output  out=HHadults(drop=_TYPE_) SUM= / autoname;
run;

data HHadults;
set HHadults;
if HHrelate_Sum >0 then HHrelate =1;
else HHrelate=0;
if HHnonrela_Sum >0 then HHnonrela=1;
else HHnonrela=0;
run;

proc freq data=HHadults;
tables HHrelate HHnonrela/missing;
run;

proc sort data=atus18.atus_cps;
by year CASEID_char;
run;

proc sort data=HHadults;
by year CASEID_char;
run;

data ATUS18.atus_cps;
merge HHadults(drop=HHrelate_SUM HHnonrela_Sum _FREQ_ in=ina) atus18.atus_cps(in=inb);
by year CASEID_char;
if inb=1;
run;

proc freq data=ATUS18.atus_cps;
tables HHrelate HHnonrela/missing;
where year=2004 and RTypeKGA NE "NE";
run;

	/*3.6 make stratification variable of the presence and age of children
	and the number of adults in adults-only households */
data atus_HHmember;
set ATUS18.ATUS_00037HH;
CASEID_char = put(CASEID,14.);
if AGE_CPS8 >17 then adult_count= 1;
else adult_count =0;
run;

proc means data=atus_HHmember SUM noprint;
var adult_count;
by CASEID_char;
output  out=adult(drop=_TYPE_) SUM= / autoname;
run;

data adult;
set adult;
if adult_count_Sum =1 then adult = 3;
else if adult_count_Sum >1 then adult=4;
else adult=.;
run;

proc sort data=atus18.atus_cps;
by CASEID_char;
run;

proc sort data=adult;
by CASEID_char;
run;

data atus18.atus_cps;
merge adult(drop=adult_count_Sum _FREQ_) atus18.atus_cps(in=inb);
by CASEID_char;
if inb=1;
if child5=1 then HHtype=1;
else if child17=1 then HHtype=2;
else HHtype=adult;
format HHtype HHtypeCode.;
run;

/*data atus_cps;*/
/*set atus18.atus_cps;*/
/*Strata=HHtype + (RcEhn-1)*4;*/
/*run;*/

proc freq data=atus18.atus_cps;
tables HHtype/missing;
/*where year=2005;*/
run;

	/*3.7 categorize variables and get rid of the 'NIU's*/
Data ATUS18.ATUS_CPS;
set ATUS18.ATUS_CPS;
if AGE_CPS8 <18 then AgeGroup =.;
else if 18<=AGE_CPS8 <=34 then AgeGroup = 1;
else if 35<=AGE_CPS8 <=54 then AgeGroup = 2;
else if 55<=AGE_CPS8 then AgeGroup = 3;
if EMPSTAT_CPS8 =99 then WorkHrGrp = 9;
else if UHRSWORKT_CPS8 = 9999 then WorkHrGrp =1;
else if UHRSWORKT_CPS8 < 35 then WorkHrGrp =2;
else if 35<= UHRSWORKT_CPS8 <=44 then WorkHrGrp =3;
else if 45 <= UHRSWORKT_CPS8 <9995 then WorkHrGrp =4;
else if UHRSWORKT_CPS8 = 9995 then WorkHrGrp = 5;
if FAMINCOME <7 then FamIncGrp = 1;
else if 7<= FAMINCOME <11 then FamIncGrp = 2;
else if 11<= FAMINCOME < 14 then FamIncGrp = 3;
else if 14<= FAMINCOME <= 16 then FamIncGrp = 4;
else if FAMINCOME in(996,997,998) then FamIncGrp =9;
if EDUC in(0,1) then EducGrp=0;
else if 1< EDUC <73 then EducGrp = 1; 
else if EDUC = 73 then EducGrp = 2;
else if 80<= EDUC < 111 then EducGrp =3;
else if EDUC =111 then EducGrp =4;
else if EDUC in(123,124,125) then EducGrp =5;
else if EDUC =999 then EducGrp=9;
if HISPAN ne 0 then RcEhn=1;
else if RACE = 110 then RcEhn=2;
else RcEhn=3;
if Age_CPS8 < 18 then AgeGrp5 =.;
else if 18<=age_CPS8 <=34 then AgeGrp5 = 1;
else if 35 <= AGE_CPS8 <=44 then AgeGrp5 =2;
else if 45 <= Age_CPS8 <= 54 then AgeGrp5 = 3;
else if 55 <= Age_CPS8 <=64 then AgeGrp5 = 4;
else if Age_CPS8 >= 65 then AgeGrp5 = 5;
if 15<= Age_CPS8 <=30 then Agegrp_KGA=1;
else if 31<= Age_CPS8 <= 45 then Agegrp_KGA=2;
else if 46 <= Age_CPS8 <= 55 then Agegrp_KGA=3;
else if 56 <= Age_CPS8 <= 65 then Agegrp_KGA=4;
else if Age_CPS8 >65 then Agegrp_KGA=5;
if MARST = 2 then Mar_KGA = 5;
else Mar_KGA = MARST;
if Mar_KGA=99 then Mar_KGA=.;
if HHTenure =3 then HHTenure_KGA=2;
else HHTenure_KGA=HHTenure;
if Phone=1 then Phone_KGA=0;
else if Phone in (2,3) then Phone_KGA=1;
if SEX_CPS8 = 99 then SEX_CPS8=.;
if WorkHrGrp = 9 then WorkHrGrp = .;
if HHTenure_KGA = 99 then HHTenure_KGA = .;
if FamIncGrp = 9 then FamIncGrp =.;
if EducGrp in (0,9) then EducGrp=.;
if EMPSTAT_CPS8 = 99 then EMPSTAT_CPS8 =.;
if Metro_CPS = 0 then Metro_CPS = .;
if spouse_WorkHrGrp =9 then spouse_WorkHrGrp=.;
format AgeGroup AgeGroupCode. Phone PhoneCode. Region RegionCode. Metro MetroCode. 
SEX_CPS8 SexCode. MARST MaritalCode. HH_CHILD_CPS8 ChildrenCode. WorkHrGrp WorkHrGrpCode. 
HHTenure HHTenureCode. FAMINCOME FamincCode. FamIncGrp FamIncGrpCode. EducGrp EducGrpCode.
RcEhn RcEhnCode. AgeGrp5 AgeGrp5Code. EMPSTAT_CPS8 EmployCode. Mar_KGA Mar_KGACode. 
Agegrp_KGA Agegrp_KGACode. Phone_KGA ChildrenCode. HHrelate ChildrenCode. HHNonrela ChildrenCode.
child5 ChildrenCode. child17 ChildrenCode. HHTenure_KGA HHTenure_KGACode. METRO_CPS METRO_CPSCode.;
run;

proc freq data=ATUS18.ATUS_CPS;
table HISPAN;
run;

proc freq data=ATUS18.ATUS_CPS;
tables EMPSTAT_CPS8;
where UHRSWORKT_CPS8 = 9999;
run;

proc freq data=ATUS18.ATUS_CPS;
tables Metro*Metro_CPS/nopercent nocol norow;
run;

/*3.8 merge ATUS base weights*/
Data atus_weights;
set atus18.atus_00039;
CASEID_char = put(CASEID,14.);
run;
	
	/*check missing*/
Data freq_weight;
set atus_weights;
length weight $ 10;
if BWT=. then weight='W missing';
else if BWT=0 then weight='W EQ 0';
else weight='W NE 0';
run;

proc freq data=freq_weight;
tables weight*year/nopercent nocol norow missing;
run;

proc print data=atus_weights;
where CASEID_char="20180110171874";
run;
/*0 output*/

proc sort data=atus_weights;
by CASEID_char;
run;

proc sort data=ATUS18.atus_cps;
by CASEID_char;
run;

Data ATUS18.atus_cps;
merge atus_weights(in=inw) ATUS18.atus_cps(drop=BWT in=inall);
by CASEID_char;
/*if inw=0 then in_w=0;*/
/*else in_w=1;*/
/*if inall=0 then in_all=0;*/
/*else in_all=1;*/
if inall=1;
run;

proc means data=ATUS18.atus_cps NMISS N;
var BWT;
by year;
run;

proc freq data=ATUS18.atus_cps;
tables BWT;
where Resp_KGA=0;
run;

/*3.9 check data availability, espeicially for non-respondents*/
proc freq data=ATUS18.ATUS_CPS;
tables (Agegrp_KGA Agegroup Agegrp5 MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
EducGrp HHTenure_KGA FamIncGrp spouse_WorkHrGrp Child5 Child17 HHNonrela HHrelate)*Resp_KGA /missing nofreq nopercent norow;
run;

/*4.Analysis*/
	/*4.1 overall trends */
	/*4.1.1 response, contact, cooperation and types of nonresponse*/
ods excel file="T:\USER\Zeping\Nonresponse in ATUS\output - weighted 2018 update\
Weighted ATUS survey outcome overall trend 2004-2016.xlsx" options(embedded_titles="yes"
embedded_footnotes="yes"
sheet_interval= "proc");
proc tabulate data=ATUS18.ATUS_CPS out=yearly_tabulation format=6.3;
class year;
var Resp_KGA Cont_KGA Coop_KGA Ref_KGA;
tables (Resp_KGA Cont_KGA Coop_KGA Ref_KGA)*(mean N STDERR), year;
weight BWT;
where year <2017;
title "Weighted interview outcome of ATUS 2004-2016";
footnote "Using KG Abraham et al.(2006)'s disposition code";
run;

proc SGPLOT data=yearly_tabulation;
	vline Year / response=Resp_KGA_Mean;
	vline Year / response=Cont_KGA_Mean;
	vline Year / response=Coop_KGA_Mean;
	vline Year / response=Ref_KGA_Mean;
	label Resp_KGA_Mean="Response rate"
		  Cont_KGA_Mean="Contact rate"
		  Coop_KGA_Mean="Cooperation rate"
		  Ref_KGA_Mean="Refusal rate";
run;

proc tabulate data=ATUS18.ATUS_CPS out=nonresponse_tabulation format=6.3;
class year;
var NCinNonR RfinNonR;
table year,
    (RfinNonR NCinNonR)*Mean RfinNonR*pctsum<NCinNonR>;
label NCinNonR = "Noncontact in Nonresponse"
	RfinNonR = "Refusal in Nonresponse";
weight BWT;
where year <2017;
title "Weighted types of nonresponse of ATUS 2004-2016";
footnote "The statistic made by 'pctsum' is 100*sum(Refusal)/sum(Noncontact).";
run;

proc SGPLOT data=nonresponse_tabulation;
	vline Year / response=NCinNonR_Mean;
	vline Year / response=RfinNonR_Mean;
	vline Year / response=RfinNonR_PctSum_1_NCinNonR Y2AXIS;
	label NCinNonR_Mean="Noncontact in nonresponse rate"
		  RfinNonR_Mean="Refusal in nonresponse rate"
		 RfinNonR_PctSum_1_NCinNonR="Ratio of Refusal/Noncontact";
run;
ods excel close;

	/*4.1.2 Z-Tests/risk differences for periods*/
%LET year1=04;%LET year2=08;%LET year3=16;
%Macro Risk(Start,End);
Data ATUS_CPS_&Start._&End.(keep=Year Resp_KGA Cont_KGA Coop_KGA Ref_KGA BWT);
set ATUS18.ATUS_CPS;
where year= 20&Start. or year=20&End.;
run;

proc sort data=ATUS_CPS_&Start._&End.;
by descending year Resp_KGA Cont_KGA Coop_KGA Ref_KGA;
run;

proc surveyfreq data=ATUS_CPS_&Start._&End. order=data;
weight BWT;
tables Year*(Resp_KGA Cont_KGA Coop_KGA Ref_KGA)/ risk;
ods output risk2=risk_&Start._&End.;
run;

Data risk_&Start._&End.(drop=_SkipLine);
set risk_&Start._&End.;
start=20&Start.;
end=20&End.;
run;
%MEND;
%Risk(&year1.,&year2.);%Risk(&year2.,&year3.);

Data ATUS18.Risks08weighted;
set Risk_:;
weight="weighted";
run;

%LET year1=04;%LET year2=08;%LET year3=16;
%Macro Risk(Start,End);
Data ATUS_CPS_&Start._&End.(keep=Year Resp_KGA Cont_KGA Coop_KGA Ref_KGA BWT);
set ATUS18.ATUS_CPS;
where year= 20&Start. or year=20&End.;
run;

proc sort data=ATUS_CPS_&Start._&End.;
by descending year Resp_KGA Cont_KGA Coop_KGA Ref_KGA;
run;

proc surveyfreq data=ATUS_CPS_&Start._&End. order=data;
tables Year*(Resp_KGA Cont_KGA Coop_KGA Ref_KGA)/ risk;
ods output risk2=Riskuwtd_&Start._&End.;
run;

Data Riskuwtd_&Start._&End.(drop=_SkipLine);
set Riskuwtd_&Start._&End.;
start=20&Start.;
end=20&End.;
run;
%MEND;
%Risk(&year1.,&year2.);%Risk(&year2.,&year3.);

Data ATUS18.Risks08unweighted;
set Riskuwtd_:;
weight="unweighted";
run;

ods excel file="Weighted risk differences in period 2004-2008 and 2008-2016.xlsx" options(embedded_titles="yes"
embedded_footnotes="yes"
sheet_interval= "proc");
proc tabulate data=ATUS18.Risks08weighted(rename=(StdErr=SE Row=item)) FORMAT=6.3;
class Table start item;
var Risk SE LowerCL UpperCL;
tables Table*(Risk SE LowerCL UpperCL),start*item;
where item NE "Total" and weight="weighted";
title "Weighted response outcomes and their differences";
footnote;
run;
ods excel close;

Data ATUS18.Risks_wtduwtd;
set ATUS18.Risks08weighted ATUS18.Risks08unweighted;
where row="Difference";
run;

proc sort data=ATUS18.Risks_wtduwtd;
by start table;
run;

proc freq data=ATUS_CPS_04_08 order=data;
   tables Year*(Resp_KGA Cont_KGA Coop_KGA Ref_KGA) / riskdiff(equal method=SCORE var=null );
run;

/*4.2 cross-tablution*/
	/*4.2.1 cross-tabluation interview outcome by explanotory variables*/
ods excel file="Weighted ATUS interview outcome subgroup cross-tabulation 2004-2016.xlsx" options(embedded_titles="yes"
sheet_interval= "proc");
%LET Out1=Resp_KGA;%LET Out2=Cont_KGA;%LET Out3=Coop_KGA;%LET Out4=Ref_KGA;
%LET LBout1=response rates;%LET LBout2=contact rates;
%LET LBout3=cooperation rates;%LET LBout4=refusal rates;
%MACRO Tab(Out,LBout);
proc tabulate data=ATUS18.ATUS_CPS out=ATUS18.wtd_&Out._tab format=6.3;
class Agegrp_KGA Agegroup Agegrp5 MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
EducGrp HHTenure_KGA FamIncGrp spouse_WorkHrGrp Child5 Child17 HHNonrela HHrelate year /missing;
var &Out.;
weight BWT;
where year <2017;
tables Agegrp_KGA Agegroup Agegrp5 MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
EducGrp HHTenure_KGA FamIncGrp spouse_WorkHrGrp Child5 Child17 HHNonrela HHrelate, year*&Out.*(mean N STDERR);
title "Weighted &LBout. of ATUS 2004-2016";
run;
%MEND;
%Tab(&Out1.,&LBout1.);%Tab(&Out2.,&LBout2.);%Tab(&Out3.,&LBout3.);%Tab(&Out4.,&LBout4.);

proc tabulate data=ATUS18.ATUS_CPS out=ATUS18.wtd_ratio_tab format=6.3;
	class Agegrp_KGA Agegroup Agegrp5 MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
			EducGrp HHTenure_KGA FamIncGrp spouse_WorkHrGrp Child5 Child17 HHNonrela HHrelate year;
	var  NCinNonR RfinNonR;
	weight BWT;
	where year <2017;
	table Agegrp_KGA Agegroup Agegrp5 MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
			EducGrp HHTenure_KGA FamIncGrp spouse_WorkHrGrp Child5 Child17 HHNonrela HHrelate,year*RfinNonR*pctsum<NCinNonR>;
	title "Weighted Ratio of Refusal to Noncontact in ATUS 2004-2016";
	footnote "The statistic made by 'pctsum' is 100*sum(RfinNonR)/sum(NCinNonR).";
run;
ods excel close;

	/*4.2.2 Line charts - by each variable */
	/*Agegrp_KGA Agegroup Agegrp5 MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp */
	/*EducGrp HHTenure_KGA FamIncGrp spouse_WorkHrGrp Child5 Child17 HHNonrela HHrelate*/
%LET VAR100=Agegrp_KGA;%LET LABEL100= Age group KGA;
%LET VAR101=Agegroup;%LET LABEL101=Age group from 18;
%LET VAR102=Agegrp5;%LET LABEL102=Age group from 18 in 5 categories;
%LET VAR103=WorkHrGrp;%LET LABEL103=R Hours Worked;
%LET VAR104=EducGrp;%LET LABEL104=Education;
%LET VAR105=FamIncGrp;%LET LABEL105=Family Income Group;
%LET VAR106=spouse_WorkHrGrp;%LET LABEL106=Spouse Hours Worked;
%LET VAR1=MAR_KGA;%LET LABEL1=Marital Status;
%LET VAR2=METRO_CPS;%LET LABEL2=Metropolitan central city status;
%LET VAR3=Phone_KGA;%LET LABEL3=Telephone availability;
%let VAR4=RcEhn;%let LABEL4= Race ethnicity;
%let VAR5=Region;%LET LABEL5=Region;
%LET VAR6=HHTenure_KGA;%LET LABEL6=Housing tenure;
%LET VAR7=SEX_CPS8;%LET LABEL7=Sex;
%LET VAR8=child5;%Let LABEL8=Presence of children age 5 and under;
%LET VAR9=child17;%LET LABEL9=Presence of children age 6-17;
%LET VAR10=HHNonrela;%LET LABEL10=Presence of Other Adults Not Related to Householder;
%LET VAR11=HHrelate;%LET LABEL11=Presence of Other Adults Related to Householder;

%MACRO PLOT(VAR,LABEL);
ods excel file="T:\USER\Zeping\Nonresponse in ATUS\output - weighted 2018 update\Line Charts - Weighted &LABEL..xlsx" options(embedded_titles="yes"
embedded_footnotes="yes"
sheet_interval= "proc");
proc SGPLOT data=ATUS18.wtd_Resp_KGA_tab;
   vline Year / response=Resp_KGA_Mean GROUP= &VAR.;
   title "Weighted response rate by &LABEL. in ATUS 2004-2016";
   footnote;
run;

proc SGPLOT data=ATUS18.wtd_Cont_KGA_tab;
   vline Year / response=Cont_KGA_Mean  GROUP=&VAR.;
	title "Weighted contact rate by &LABEL. in ATUS 2004-2016";
run;

proc SGPLOT data=ATUS18.wtd_Coop_KGA_tab;
   vline Year / response=Coop_KGA_Mean  GROUP= &VAR.;
   title "Weighted cooperation rate by &LABEL. in ATUS 2004-2016";
run;

proc SGPLOT data=ATUS18.wtd_Ref_KGA_tab;
   vline Year / response=Ref_KGA_mean  GROUP=&VAR.;
   title "Weighted refusal rate by &LABEL. in ATUS 2004-2016";
run;

ods excel close;
%MEND;
%PLOT(&VAR100.,&LABEL100.);%PLOT(&VAR101.,&LABEL101.);%PLOT(&VAR102.,&LABEL102.);
%PLOT(&VAR103.,&LABEL103.);%PLOT(&VAR104.,&LABEL104.);%PLOT(&VAR105.,&LABEL105.);
%PLOT(&VAR106.,&LABEL106.);
%PLOT(&VAR1.,&LABEL1.);%PLOT(&VAR2.,&LABEL2.);%PLOT(&VAR3.,&LABEL3.);%PLOT(&VAR4.,&LABEL4.);
%PLOT(&VAR5.,&LABEL5.);%PLOT(&VAR6.,&LABEL6.);%PLOT(&VAR7.,&LABEL7.);%PLOT(&VAR8.,&LABEL8.);
%PLOT(&VAR9.,&LABEL9.);%PLOT(&VAR10.,&LABEL10.);%PLOT(&VAR11.,&LABEL11.);

%macro PLOT(X,Y);
%DO i=1 %to 18;
%let X&i = %scan(&X.,&i);
%put &&X&i..;
ods excel file="T:\USER\Zeping\Nonresponse in ATUS\output - weighted 2018 update\Line Charts - weighted &&X&i...xlsx" options(embedded_titles="yes"
embedded_footnotes="yes"
sheet_interval= "proc");
	%DO j=1 %to 4;
	%let Y&j = %scan(&Y.,&j);
	%put &&Y&j..;
	proc SGPLOT data=ATUS18.wtd_&&Y&j.._tab;
	   vline Year / response=&&Y&j.._Mean GROUP= &&X&i..;
	   title "Weighted &&Y&j.. by &&X&i.. in ATUS 2004-2016";
	   footnote;
	run;
	%END; 
ods excel close;
%END; 
%MEND;
%PLOT(X=Agegrp_KGA Agegroup Agegrp5 MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
		EducGrp HHTenure_KGA FamIncGrp spouse_WorkHrGrp Child5 Child17 HHNonrela HHrelate, Y=Resp_KGA Cont_KGA Coop_KGA Ref_KGA);

	/*4.2.3 cross-tabulation in 2004 for comparing with Abraham 2004*/
ods excel file="Tabulations - 2004 for comparision 3.0.xlsx" options(embedded_titles="yes"
embedded_footnotes="yes"
sheet_interval= "proc");
proc tabulate data=ATUS18.ATUS_CPS;
class Agegrp_KGA Agegroup Agegrp5 MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
			EducGrp HHTenure_KGA FamIncGrp spouse_WorkHrGrp Child5 Child17 HHNonrela HHrelate/missing;
var Resp_KGA Cont_KGA Coop_KGA Ref_KGA;
tables Agegrp_KGA Agegroup Agegrp5 MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
			EducGrp HHTenure_KGA FamIncGrp spouse_WorkHrGrp Child5 Child17 HHNonrela HHrelate, (Resp_KGA Cont_KGA Coop_KGA Ref_KGA)*(mean N);
where year=2004;
title "Interview outcome of ATUS by variables in 2004";
run;
ods excel close;

	/*4.3 weighted difference between 2004 and 2008 by demographics*/
	/*2004-2008*/
Data ATUS_CPS_04_08(rename=(spouse_workhrGrp=spuswk));
set ATUS18.ATUS_CPS;
where (year= 2004 or year=2008) and EDUCgrp NE 9 and HHTenure_KGA NE 99 and MAR_KGA NE 99;
run;

ods html gpath="T:\USER\Zeping\Nonresponse in ATUS\output - weighted 2018 update\Plots - weighted differences between 2004 and 2008 by demographics";
%Macro Subgrp_0408(X,Y);
%DO i=1 %to 16;
%let X&i = %scan(&X.,&i);
%put &&X&i..;
	%DO j=1 %to 4;
	%let Y&j = %scan(&Y.,&j);
	%put &&Y&j..;
	proc sort data=ATUS_CPS_04_08;
	by descending year descending &&Y&j.. &&X&i..;
	run;

	ODS GRAPHICS ON / imagename="Weighted &&X&i.._&&Y&j.._0408";
	ods select riskdiffplot;
	proc surveyfreq data=ATUS_CPS_04_08 order=data;
	weight BWT;
	tables &&X&i..*Year*&&Y&j../ risk plots=riskdiffplot;
	ods output RISK1=risk_0408_&&X&i.._&&Y&j..;
	run;
	ods graphics off;

	Data risk_0408_&&X&i.._&&Y&j..(drop=_Skipline);
	set risk_0408_&&X&i.._&&Y&j..;
	length VAR $15;
	VAR = "&&X&i..";
	run;
	%END;
	Data risk_0408&&X&i..;
	set Risk_0408_&&X&i.._:;
	run;
%END;
%MEND;
%Subgrp_0408(X=Agegrp_KGA MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
		EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate, Y=Resp_KGA Cont_KGA Coop_KGA Ref_KGA);
ods html close;

ods excel file="Weighted proportion Differences_0408.xlsx" options(embedded_titles="yes"
sheet_interval= "proc");
%Macro Print(X);
%DO i=1 %to 16;
%let X&i = %scan(&X.,&i);
%put &&X&i..;
	proc print Data=risk_0408&&X&i..;
	title "Weighted proportions about &&X&i.. and their differences between 2004 and 2008";
	run;
%END;
%MEND;
%Print(X=Agegrp_KGA MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
		EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate);
ods excel close;

	/*2008-2016*/
Data ATUS_CPS_08_18(rename=(spouse_workhrGrp=spuswk));
set ATUS18.ATUS_CPS;
where (year= 2018 or year=2008) and EDUCgrp NE 9 and HHTenure_KGA NE 99 and MAR_KGA NE 99 and FamIncGrp NE 9;
run;

ods html gpath="T:\USER\Zeping\Nonresponse in ATUS\output - 2018 update\Plots - difference between 2008 and 2018 by demographics";
%Macro Subgrp_0818(X,Y);
%DO i=1 %to 16;
%let X&i = %scan(&X.,&i);
%put &&X&i..;
	%DO j=1 %to 4;
	%let Y&j = %scan(&Y.,&j);
	%put &&Y&j..;
	proc sort data=ATUS_CPS_08_18;
	by descending year descending &&Y&j.. &&X&i..;
	run;

/*	ODS GRAPHICS ON / imagename="&&X&i.._&&Y&j.._0818";*/
/*	ods select RiskDiffPlot;*/
	proc surveyfreq data=ATUS_CPS_08_18 order=data;
	tables &&X&i..*Year*&&Y&j../ risk;
/*	plots=riskdiffplot*/
	ods output RISK1=risk_0818_&&X&i.._&&Y&j..;
	run;
/*	ods graphics off;*/

	Data risk_0818_&&X&i.._&&Y&j..(drop=_Skipline);
	set risk_0818_&&X&i.._&&Y&j..;
	length VAR $15;
	VAR = "&&X&i..";
	run;
	%END;
	Data risk_0818&&X&i..;
	set Risk_0818_&&X&i.._:;
	run;
%END;
%MEND;
%Subgrp_0818(X=Agegrp_KGA MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
		EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate, Y=Resp_KGA Cont_KGA Coop_KGA Ref_KGA);
ods html close;

ods excel file="Weighted Proportion Differences_0818.xlsx" options(embedded_titles="yes"
embedded_footnotes="yes"
sheet_interval= "proc");
%Macro Print(X);
%DO i=1 %to 16;
%let X&i = %scan(&X.,&i);
%put &&X&i..;
	proc print Data=risk_0818&&X&i..;
	title "Proportions about &&X&i.. and their differences between 2008 and 2018";
	run;
%END;
%MEND;
%Print(X=Agegrp_KGA MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
		EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate);
ods excel close;

proc sort data=ATUS_CPS_08_18;
by descending year descending Cont_KGA Agegroup;
run;

ods graphics on;
proc surveyfreq data=ATUS_CPS_08_18 order=data;
tables Agegroup*Year*Cont_KGA/ risk plots=riskdiffplot;
ods output RISK1=test1;
run;
ods graphics off;

proc surveyfreq data=ATUS_CPS_04_08 order=data;
tables Mar_KGA*Year*Cont_KGA/ risk plots(only)=riskdiffplot;
ods output RISK1=risk_0408_Mar_KGA_Cont;
run;

proc sort data=ATUS_CPS_04_08;
by DESCENDING year agegroup DESCENDING Cont_KGA;
run;

/*4.4 weighted logistic regressions*/
Data ATUS_CPS(rename=(spouse_workhrGrp=spuswk));
set ATUS18.ATUS_CPS;
run;
	/*4.4.1. Weighted logistic regression: outcome = factor + year*/
/*2004-2008*/
%macro EST04WT(X,Y);
%DO i=1 %to 18;
%let X&i = %scan(&X.,&i);
%put &&X&i..;
	%DO j=1 %to 4;
	%let Y&j = %scan(&Y.,&j);
	%put &&Y&j..;
PROC LOGISTIC data=ATUS_CPS;
class &&X&i../param=ref ref=FIRST;
model &&Y&j..(event='1')=&&X&i.. Year;
weight BWT /normalize;
where 2004<=year<=2008;
ods output ParameterEstimates=ESTWO04_&&X&i.._&&Y&j..;
run;

Data ESTWO04_&&X&i.._&&Y&j..;
set ESTWO04_&&X&i.._&&Y&j.. ;
outcome="&&Y&j..";
run;
%END; 
%END;
%mend;
%EST04WT(X=Agegrp_KGA Agegroup Agegrp5 MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
		EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate, Y=Resp_KGA Cont_KGA Coop_KGA Ref_KGA);

Data ESTWO04all_wt;
length ClassVal0 $25;
set ESTWO04_:;
length period $10;
period="2004-2008";
run;

	/*2009-2016*/
%macro EST09WT(X,Y);
%DO i=1 %to 18;
%let X&i = %scan(&X.,&i);
%put &&X&i..;
	%DO j=1 %to 4;
	%let Y&j = %scan(&Y.,&j);
	%put &&Y&j..;
PROC LOGISTIC data=ATUS_CPS;
class &&X&i../param=ref ref=FIRST;
model &&Y&j..(event='1')=&&X&i.. Year;
weight BWT /normalize;
where 2009<=year<=2016;
ods output ParameterEstimates=ESTWO09_&&X&i.._&&Y&j..;
run;

Data ESTWO09_&&X&i.._&&Y&j..;
set ESTWO09_&&X&i.._&&Y&j.. ;
outcome="&&Y&j..";
run;
%END; 
%END;
%mend;
%EST09WT(X=Agegrp_KGA Agegroup Agegrp5 MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
		EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate, Y=Resp_KGA Cont_KGA Coop_KGA Ref_KGA);

Data ESTWO09all_wt;
length ClassVal0 $25;
set ESTWO09_:;
length period $10;
period="2009-2016";
run;

Data ATUS18.ESTWOall_wt;
set ESTWO04all_wt ESTWO09all_wt;
run;

ods excel file="Weighted sub-period estimates of logistic regression for the model without interaction term 2.0.xlsx" options(embedded_titles="yes"
embedded_footnotes="yes"
sheet_interval= "proc");
proc tabulate data=ATUS18.ESTWOall_wt;
var Estimate;
class Variable ClassVal0 outcome period;
tables Variable*ClassVal0*Estimate, period*outcome;
where Variable not in ("Intercept","YEAR");
run;

proc print data=ATUS18.ESTWOall_wt;
run;

proc tabulate data=ATUS18.ESTWOall_wt format=5.3;
var ProbChiSq;
class Variable ClassVal0 outcome period;
tables Variable*ClassVal0*ProbChiSq, period*outcome;
where Variable not in ("Intercept","YEAR");
run;
ods excel close;

proc freq data=ATUS18.ATUS_CPS;
tables HISPAN*RcEhn/nopercent nocol norow;
run;

	/*4.4.2. LR test: the full model with interaction term and the reduced model without the interaction term*/
/*2004-2008*/
%macro LR04WT(X,Y);
%DO i=1 %to 18;
%let X&i = %scan(&X.,&i);
%put &&X&i..;
	%DO j=1 %to 4;
	%let Y&j = %scan(&Y.,&j);
	%put &&Y&j..;
PROC LOGISTIC data=ATUS_CPS;
class &&X&i../param=ref ref=FIRST;
model &&Y&j..(event='1')=&&X&i.. Year &&X&i..*Year;
weight BWT /normalize;
where 2004<=year<=2008;
ods output FitStatistics=Full04_wt_&&X&i.._&&Y&j..;
ods output ParameterEstimates=EST04_&&X&i.._&&Y&j..;
run;

PROC LOGISTIC data=ATUS_CPS;
class &&X&i../param=ref ref=FIRST;
model &&Y&j..(event='1')=&&X&i.. Year;
weight BWT /normalize;
where 2004<=year<=2008;
ods output FitStatistics=Red04_wt_&&X&i.._&&Y&j..;
run;

proc sort data=Full04_wt_&&X&i.._&&Y&j..;
by Criterion;
run;

proc sort data=Red04_wt_&&X&i.._&&Y&j..;
by Criterion;
run;

Data LR04_wt_&&X&i.._&&Y&j..;
merge Full04_wt_&&X&i.._&&Y&j..(drop=InterceptOnly rename=(InterceptAndCovariates=Full))
Red04_wt_&&X&i.._&&Y&j..(drop=InterceptOnly rename=(InterceptAndCovariates=Reduced));
by Criterion;
if Criterion="-2 Log L";
length factor $15;
G=Reduced - Full;
factor="&&X&i..";
outcome="&&Y&j..";
run;

Data EST04_&&X&i.._&&Y&j..;
set EST04_&&X&i.._&&Y&j.. ;
outcome="&&Y&j..";
run;
%END; 
%END;
%mend;
%LR04WT(X=Agegrp_KGA Agegroup Agegrp5 MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
		EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate, Y=Resp_KGA Cont_KGA Coop_KGA Ref_KGA);

Data LR04all_wt;
set LR04_wt:;
length period $10;
period="2004-2008";
run;

Data EST04all_wt;
length ClassVal0 $25;
set Est04_:;
length period $10;
period="2004-2008";
run;

%macro LR08WT(X,Y);
%DO i=1 %to 18;
%let X&i = %scan(&X.,&i);
%put &&X&i..;
	%DO j=1 %to 4;
	%let Y&j = %scan(&Y.,&j);
	%put &&Y&j..;
PROC LOGISTIC data=ATUS_CPS;
class &&X&i../param=ref ref=FIRST;
model &&Y&j..(event='1')=&&X&i.. Year &&X&i..*Year;
weight BWT /normalize;
where 2008<=year<=2016;
ods output FitStatistics=Full08_wt_&&X&i.._&&Y&j..;
ods output ParameterEstimates=EST08_&&X&i.._&&Y&j..;
run;

PROC LOGISTIC data=ATUS_CPS;
class &&X&i../param=ref ref=FIRST;
model &&Y&j..(event='1')=&&X&i.. Year;
weight BWT /normalize;
where 2008<=year<=2016;
ods output FitStatistics=Red08_wt_&&X&i.._&&Y&j..;
run;

proc sort data=Full08_wt_&&X&i.._&&Y&j..;
by Criterion;
run;

proc sort data=Red08_wt_&&X&i.._&&Y&j..;
by Criterion;
run;

Data LR08_wt_&&X&i.._&&Y&j..;
merge Full08_wt_&&X&i.._&&Y&j..(drop=InterceptOnly rename=(InterceptAndCovariates=Full))
Red08_wt_&&X&i.._&&Y&j..(drop=InterceptOnly rename=(InterceptAndCovariates=Reduced));
by Criterion;
if Criterion="-2 Log L";
length factor $15;
G=Reduced - Full;
factor="&&X&i..";
outcome="&&Y&j..";
run;

Data EST08_&&X&i.._&&Y&j..;
set EST08_&&X&i.._&&Y&j.. ;
outcome="&&Y&j..";
run;
%END; 
%END;
%mend;
%LR08WT(X=Agegrp_KGA Agegroup Agegrp5 MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
		EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate, Y=Resp_KGA Cont_KGA Coop_KGA Ref_KGA)

Data LR08all_wt;
set LR08_wt:;
length period $10;
period="2008-2016";
run;

Data EST08all_wt;
length ClassVal0 $25;
set Est08_:;
length period $10;
period="2008-2016";
run;

Data ATUS18.LRall_wt_revised;
set LR04all_wt LR08all_wt;
run;

Data ATUS18.ESTall_wt;
set EST04all_wt EST08all_wt;
run;

ods excel file="Weighted sub-period likelihood ratio tests for the interaction term (revised).xlsx" options(embedded_titles="yes"
embedded_footnotes="yes"
sheet_interval= "proc");
proc tabulate data=ATUS18.LRall_wt_revised;
var G;
class factor period outcome;
tables factor*G,period*outcome;
run;

proc print data=ATUS18.LRall_wt_revised;
run;
ods excel close;

ods excel file="Weighted sub-period estimates of logistic regression.xlsx" options(embedded_titles="yes"
embedded_footnotes="yes"
sheet_interval= "proc");
proc tabulate data=ATUS18.ESTall_wt(keep=Variable ClassVal0 Estimate outcome period);
var Estimate;
class Variable ClassVal0 outcome period;
tables Variable*ClassVal0*Estimate, period*outcome;
where Variable not in ("Intercept","YEAR");
run;

proc print data=ATUS18.ESTall_wt;
run;

proc tabulate data=ATUS18.ESTall_wt(keep=Variable ClassVal0 ProbChiSq outcome period) format=5.3;
var ProbChiSq;
class Variable ClassVal0 outcome period;
tables Variable*ClassVal0*ProbChiSq, period*outcome;
where Variable not in ("Intercept","YEAR");
run;
ods excel close;

	/*4.4.4 case: housholds no related with response and contact*/
%macro HHno04WT(X,Y);
%DO j=1 %to 2;
%let Y&j = %scan(&Y.,&j);
%put &&Y&j..;
PROC LOGISTIC data=ATUS_CPS;
class HHnonrela(ref="Yes");
model &&Y&j..(event='1')=HHnonrela Year;
weight BWT /normalize;
where 2004<=year<=2008;
ods output ParameterEstimates=HHno04_&&Y&j..;
run;

Data HHno04_&&Y&j..;
set HHno04_&&Y&j..;
outcome="&&Y&j..";
period="2004-2008";
run;
%END; 
%mend;
%HHno04WT(Y=Resp_KGA Cont_KGA);

	/*2009-2016*/
%macro HHno09WT(X,Y);
%DO j=1 %to 2;
%let Y&j = %scan(&Y.,&j);
%put &&Y&j..;
PROC LOGISTIC data=ATUS_CPS;
class HHnonrela(ref="Yes");
model &&Y&j..(event='1')=HHnonrela Year;
weight BWT /normalize;
where 2009<=year<=2016;
ods output ParameterEstimates=HHno09_&&Y&j..;
run;

Data HHno09_&&Y&j..;
set HHno09_&&Y&j..;
outcome="&&Y&j..";
period="2009-2016";
run;
%END; 
%mend;
%HHno09WT(Y=Resp_KGA Cont_KGA);

Data HHnoall_wt;
set HHno04_: HHno09_:;
run;

proc tabulate data=HHnoall_wt;
var Estimate;
class Variable ClassVal0 outcome period;
tables Variable*ClassVal0*Estimate, period*outcome;
where Variable not in ("Intercept","YEAR");
run;

	/*4.4.5 convert estimates into average marginal probability*/
PROC LOGISTIC data=ATUS_CPS outest=logparms;
class Metro_CPS(ref='Central City')/param=ref;
model Resp_KGA(event='1')=Metro_CPS Year;
weight BWT /normalize;
where 2009<=year<=2016;
output out=outlog p=p;
run;

data outlog;
if _n_=1 then set logparms;
set outlog;
MEffNonmetro = p*(1-p)*METRO_CPSNonmetropolitan;
run;

proc means data=outlog mean;
var MEffNonmetro;
run;

PROC LOGISTIC data=ATUS_CPS outest=logparms;
class Metro_CPS(ref='Central City')/param=ref;
model Coop_KGA(event='1')=Metro_CPS Year;
weight BWT /normalize;
where 2009<=year<=2016;
output out=outlog p=p;
run;

data outlog;
if _n_=1 then set logparms;
set outlog;
MEff = p*(1-p)*METRO_CPSNonmetropolitan;
run;
proc means data=outlog mean;
var MEff;
run;

PROC LOGISTIC data=ATUS_CPS outest=logparms;
class Mar_KGA(ref='Divorced')/param=ref;
model Resp_KGA(event='1')=Mar_KGA Year;
weight BWT /normalize;
where 2009<=year<=2016;
output out=outlog p=p;
run;

data outlog;
if _n_=1 then set logparms;
set outlog;
MEff = p*(1-p)*Mar_KGAMarried;
run;
proc means data=outlog mean;
var MEff;
run;

PROC LOGISTIC data=ATUS_CPS outest=logparms;
class HHnonrela(ref='Yes')/param=ref;
model Cont_KGA(event='1')=HHnonrela Year;
weight BWT /normalize;
where 2008<=year<=2016;
output out=outlog p=p;
run;

data outlog;
if _n_=1 then set logparms;
set outlog;
MEff = p*(1-p)*HHnonrelaNo;
run;
proc means data=outlog mean;
var MEff;
run;

/*4.5.Decision tree*/
/*Response rate*/
ods graphics on;
proc hpsplit data=ATUS_CPS cvmodelfit seed=1234;
class Resp_KGA Agegrp_KGA MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
	EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate;
model Resp_KGA(event='1') =
	Agegrp_KGA MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
	EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate Year;
grow entropy;
prune costcomplexity;
/*ods output VarImportance=VarImp_Resp;*/
run;

/*Contact rate*/
ods graphics on;
proc hpsplit data=ATUS_CPS cvmodelfit seed=123;
class Cont_KGA Agegrp_KGA MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
	EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate;
model Cont_KGA(event='1') =
	Agegrp_KGA MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
	EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate Year;
grow entropy;
prune costcomplexity;
ods output VarImportance=VarImp_Cont;
run;

/*Cooperation rate*/
ods graphics on;
proc hpsplit data=ATUS_CPS cvmodelfit seed=123;
class Coop_KGA Agegrp_KGA MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
	EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate;
model Coop_KGA(event='1') =
	Agegrp_KGA MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
	EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate Year;
grow entropy;
prune costcomplexity;
ods output VarImportance=VarImp_Coop;
run;

/*Refusal rate*/
ods graphics on;
proc hpsplit data=ATUS_CPS cvmodelfit seed=123;
class Ref_KGA Agegrp_KGA MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
	EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate;
model Ref_KGA(event='1') =
	Agegrp_KGA MAR_KGA Metro_CPS Phone_KGA RcEhn Region SEX_CPS8 WorkHrGrp 
	EducGrp HHTenure_KGA FamIncGrp spuswk Child5 Child17 HHNonrela HHrelate Year;
grow entropy;
prune costcomplexity;
ods output VarImportance=VarImp_Ref;
run;

%LET Resp=Resp;%LET Cont=Cont;%LET Coop=Coop;%LET Ref=Ref;
%MACRO COL(VAR);
Data VarImp_&VAR.;
set VarImp_&VAR.;
length Outcome $5;
Outcome="&VAR.";
%MEND;
%COL(&Resp.);%COL(&Cont.);%COL(&Coop.);%COL(&Ref.);
run;

proc format;
INVALUE outcome_order
	'Resp' = 1
	'Cont' = 2
	'Coop' = 3
	'Ref' = 4;
value outcome_code
	1 = 'Resp'
	2 = 'Cont'
	3 = 'Coop'
	4 = 'Ref';
run;
	
Data ATUS18.VarImpAll;
set VarImp:;
by Outcome;
Rank+1;
if first.outcome then Rank=1;
outcome_order = INPUT(outcome,outcome_order.);
run;

proc sort data=ATUS18.VarImpAll;
by outcome_order rank;
run;

ods excel file="Variable importance of decision trees.xlsx" options(
sheet_interval= "proc");
proc tabulate Data=ATUS18.VarImpAll order=DATA;
format outcome_order outcome_code.;
class Variable Outcome_order;
var RelativeImportance Rank;
tables Variable,Outcome_order*(Rank RelativeImportance);
run;
ods excel close;
