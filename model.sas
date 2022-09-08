data mydata.project_data_again;
set mydata.project_data_updated;
if country = "Guyana" then delete;
dummypolicy=0;
if policy = "Yes" then dummypolicy=1;
dummyeducation=0;
if education = "yes" then dummyeducation=1;
if religion = "Hindus" or religion = "Buddhists" or religion = "Jews" or religion = "Unaffiliat"
then religion = "Other";
dummyC = 0;
dummyM = 0;
if religion = "Christians" then dummyC = 1;
if religion = "Muslims" then dummyM = 1;
run;

proc sgscatter data=mydata.project_data_again;
	plot suiciderate*(gdp alcconsumption human_freedom_score 
	unemployment internet_users)/;
run;

proc corr data=mydata.project_data_again pearson nosimple noprob plots=none;
	var gdp alcconsumption human_freedom_score unemployment internet_users;
	with suiciderate;
run;

/* Multicollinearity */
proc sgscatter data=mydata.project_data_again;
	matrix alcconsumption internet_users gdp human_freedom_score unemployment; 
	*we only want to look at how explanatory 
	variables are related;
run;

proc corr data=mydata.project_data_again nosimple; 
var alcconsumption internet_users gdp human_freedom_score unemployment; 
*we only want to look at how explanatory variables are related;
run;

proc reg data=mydata.project_data_again plots=none;
model suiciderate = alcconsumption internet_users gdp human_freedom_score unemployment  / vif; 
run;

proc reg data=mydata.project_data_again plots=none;
model suiciderate = alcconsumption internet_users gdp human_freedom_score unemployment  / 
selection=stepwise SLentry=0.05 SLstay=0.10 details; 
*The defaults for SLStay (SLS) and SLEntry (SLE) 0.15 for STEPWISE.;
run;
/* Variable Screening */
proc reg data=mydata.project_data_again plots=none;
model suiciderate = alcconsumption internet_users gdp human_freedom_score unemployment  / 
selection=stepwise details; 
*The defaults for SLStay (SLS) and SLEntry (SLE) 0.15 for STEPWISE.;
run;

/* add qualitative predictors */
proc reg data=mydata.project_data_again;
model suiciderate= alcconsumption internet_users;
run;

/* qualitative eda */
proc sgplot data=mydata.project_data_again;
vline education/response=suiciderate datalabel stat=mean;
title 'Mean Suicide Rate by Education';
run;

proc sgplot data=mydata.project_data_again;
vline policy/response=suiciderate datalabel stat=mean;
title 'Mean Suicide Rate by Policy';
run;

proc sgplot data=mydata.project_data_again;
vline religion/response=suiciderate datalabel stat=mean;
title 'Mean Suicide Rate by Religion';
run;

/* add qualitative predictors (dummy variables) */
proc reg data=mydata.project_data_again plots=none;
model suiciderate= alcconsumption internet_users dummyC dummyM;
test dummyC, dummyM;
run;

proc reg data=mydata.project_data_again;
model suiciderate= alcconsumption internet_users
dummyC dummyM dummypolicy;
run;

proc reg data=mydata.project_data_again;
model suiciderate= alcconsumption internet_users
dummyC dummyM;
run;

/* EDA for quant x qual interactions */
proc sgplot data=mydata.project_data_again;
scatter y=suiciderate x= alcconsumption/group= religion;
reg y=suiciderate x= alcconsumption/group= religion;
run;

proc sgplot data=mydata.project_data_again;
scatter y=suiciderate x= internet_users/group= religion;
reg y=suiciderate x= internet_users/group= religion;
run;

/* create quant x qual interactions */
data mydata.project_data_again1;
set mydata.project_data_again;
internet_usersxdummyC = internet_users * dummyC;
internet_usersxdummyM = internet_users * dummyM;
run;

/* global and nested f test on interaction */
proc reg data=mydata.project_data_again1 plots=none;
model suiciderate= alcconsumption internet_users dummyC dummyM 
internet_usersxdummyC internet_usersxdummyM;
test internet_usersxdummyC, internet_usersxdummyM;
run;

/* remove interaction bc it's insignificant */
proc reg data=mydata.project_data_again1 plots=none;
model suiciderate= alcconsumption internet_users dummyC dummyM;

/* Checking assumptions */
proc reg data=mydata.project_data_again1 plots(only)=(residualbypredicted 
residualplot qqplot residualhistogram);
model suiciderate= alcconsumption internet_users dummyC dummyM/dwprob;
run;

/* Finding influential observations */
 proc reg data=mydata.project_data_again1 plots(only label)=(cooksd 
 rstudentbypredicted rstudentbyleverage); 
model suiciderate= alcconsumption internet_users dummyC dummyM / r influence;
run;