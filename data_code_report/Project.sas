/* data loading and merging */
data groc_store;
infile 'H:\Data\toothbr_groc_1114_1165.dat' firstobs = 2;
input IRI_KEY WEEK SY$ GE$ VEND$ ITEM$ UNITS DOLLARS F$ D PR;
if length(SY) = 1 then SY_D = cats('0',SY);else SY_D = SY;
if length(GE) = 1 then GE_D = cats('0',GE);else GE_D = GE;
if length(VEND) = 3 then VEND_D = cats('00',VEND);else VEND_D = VEND;
if length(ITEM) = 1 then ITEM_D = cats('0000',ITEM);
else if length(ITEM) = 2 then ITEM_D = cats('000',ITEM);
else if length(ITEM) = 3 then ITEM_D = cats('00',ITEM);
else if length(ITEM) = 4 then ITEM_D = cats('0',ITEM);else ITEM_D = ITEM;
UPC = cats(SY_D,'-',GE_D,'-',VEND_D,'-',ITEM_D);run;

proc print data = groc_store(obs=30);run;

data drug_store;
infile 'H:\Data\toothbr_drug_1114_1165.dat' firstobs = 2;
input IRI_KEY WEEK SY$ GE$ VEND$ ITEM$ UNITS DOLLARS F$ D PR;
if length(SY) = 1 then SY_D = cats('0',SY);else SY_D = SY;
if length(GE) = 1 then GE_D = cats('0',GE);else GE_D = GE;
if length(VEND) = 3 then VEND_D = cats('00',VEND);else VEND_D = VEND;
if length(ITEM) = 1 then ITEM_D = cats('0000',ITEM);
else if length(ITEM) = 2 then ITEM_D = cats('000',ITEM);
else if length(ITEM) = 3 then ITEM_D = cats('00',ITEM);
else if length(ITEM) = 4 then ITEM_D = cats('0',ITEM);else ITEM_D = ITEM;
UPC = cats(SY_D,'-',GE_D,'-',VEND_D,'-',ITEM_D);run;

proc print data = drug_store(obs=30);run;

data store_data;
set drug_store
	groc_store;
run;

libname mylib 'E:\SPB';
data mylib.store_data;
set store_data;run;

data groc_panel;
infile 'H:\Data\toothbr_PANEL_GR_1114_1165.dat' firstobs = 2 expandtabs;
input panid week units outlet $ dollars iri_key colupc;
format colupc 16.;
run;

proc print data = groc_panel(obs=10);run;

data drug_panel;
infile 'H:\Data\toothbr_PANEL_DR_1114_1165.dat' firstobs = 2 expandtabs;
input panid week units outlet $ dollars iri_key colupc;
format colupc 16.;
run;

data mass_panel;
infile 'H:\Data\toothbr_PANEL_MA_1114_1165.dat' firstobs = 2 expandtabs;
input panid week units outlet $ dollars iri_key colupc;
format colupc 16.;
run;

data panel_data;
set groc_panel
	drug_panel
	mass_panel;
run;

data deliverystore;
infile 'H:\Data\Delivery_Stores.dat' firstobs = 2;
input IRI_KEY OU$ EST_ACV  Market_Name$ 20. Open Clsd MskdName$; run;

/*demo1 csv import*/
/*demo3 csv import*/
/*prod details excel import*/

/* EDA and Price Elasticity */

proc sort data=Deliverystore dupout = duplicates nodupkey;
by IRI_KEY;
run;

proc sql;
create table StoreDetails as
select * from Deliverystore
where IRI_KEY not in (select distinct IRI_KEY from duplicates)
order by IRI_KEY;
quit;


data prod_details;
set Prod_tooth (keep=L3 L4 L5 UPC BRISTLE SIZE USER_INFO TYPE_OF_BRUSH SHAPE);
run;

proc sql;
create table sales_data as
select
a.IRI_KEY, a.WEEK, a.UNITS, a.DOLLARS, a.F, a.D, a.PR,
b.*,
c.OU, c.Market_Name, c.MskdName,(a.DOLLARS/a.UNITS) as DOLLARS_PER_UNIT,
case when a.D in (1,2) then 1 else 0 end as disp,
case when a.F not in ('NONE') then 1 else 0 end as Feature,
case
when b.L5 in ('COLGATE','COLGATE 360','COLGATE ACTIVE ANGLE','COLGATE BARBIE','COLGATE BLUES CLUES','COLGATE CLASSIC','COLGATE COLOR CHANGE','COLGATE DISNEY ATLANTIS','COLGATE EXTRA CLEAN','COLGATE GRIP EMS','COLGATE HE MAN','COLGATE LEGO','COLGATE MASSAGER','COLGATE NAVIGATOR','COLGATE NICK JR DORA THE EXPL','COLGATE NICK THE FRLY ODD PAR','COLGATE PLUS','COLGATE PLUS KOOL LOOKS','COLGATE PLUS RIPPLED','COLGATE PLUS ULTRA FIT','COLGATE POWER PUFF','COLGATE SENSITIVE','COLGATE SHREK','COLGATE SPONGEBOB SQUAREPANTS','COLGATE SUPER','COLGATE SUPERMAN','COLGATE TOTAL','COLGATE TOTAL DESIGNS','COLGATE TOTAL PROFESSIONAL','COLGATE WAVE','COLGATE WHITENING','COLGATE ZIGZAG','MY FIRST COLGATE') then 'COLGATE'
when b.L5 in ('ORAL B','ORAL B ADVANTAGE','ORAL B ADVANTAGE ARTICA','ORAL B ADVANTAGE PLUS','ORAL B BLUES CLUES','ORAL B CLASSIC','ORAL B CROSSACTION','ORAL B CROSSACTION VITALIZER','ORAL B GRIPPER','ORAL B INDICATOR','ORAL B NICKELODEON','ORAL B PULSAR','ORAL B RADICAL CONTROL','ORAL B RUGRATS','ORAL B SENSITIVE ADVANTAGE','ORAL B SESAME STREET','ORAL B STAGES','ORAL BRIGHT') then 'ORAL-B'
when b.L5 in ('REACH','REACH ADVANCED','REACH ADVANCED CLEAN ANGLE','REACH ADVANCED DESIGN','REACH ADVANCED GUM ACTION',
'REACH ANTIBACTERIAL','REACH BETWEEN','REACH CLEAN AND WHITEN','REACH CLEAN SWEEP','REACH CURIOUS GEORGE','REACH HARRY POTTER',
'REACH IN BETWEEN','REACH INTERDENTAL','REACH JIMMY NEUTRON','REACH JUSTICE LEAGUE','REACH MAX',
'REACH MAX BRIGHTENER','REACH MAX FRESH & CLEAN','REACH MAX TOOTH & GUM','REACH MAX TOOTH & GUM WONDERT',
'REACH PERFORMANCE','REACH PLAQUE BLASTER','REACH PLAQUE SWEEPER','REACH PLAQUE SWEEPER BETWEEN','REACH SPONGEBOB SQUAREPANTS',
'REACH SQUEEZE','REACH STRAWBERRY SHORTCAKE','REACH TOOTH & GUM CARE','REACH ULTRA CLEAN','REACH WONDER GRIP')
then 'REACH' else 'OTHER' end as brand
from store_data a inner join Prod_details b on a.UPC  = b.UPC inner join Storedetails c on a.IRI_KEY = c.IRI_KEY
order by a.IRI_KEY, a.week, b.L4, b.L5, b.UPC;
quit;

PROC SQL;
SELECT brand, sum(DOLLARS) from sales_data group by brand ;
QUIT;

PROC SQL;
SELECT market_name, sum(DOLLARS) from sales_data group by market_name ;
QUIT;

PROC SQL;
SELECT User_info, sum(DOLLARS) from sales_data group by User_info ;
QUIT;

PROC SQL;
SELECT brand, Bristle, sum(DOLLARS) from sales_data where brand in ('COLGATE', 'ORAL-B')  group by brand,Bristle ;
QUIT;

PROC SQL;
SELECT brand, Type_of_brush, sum(DOLLARS) from sales_data where brand in ('COLGATE', 'ORAL-B')  group by brand,Type_of_brush ;
QUIT;

PROC SQL;
SELECT Type_of_brush, sum(DOLLARS) from sales_data group by Type_of_brush ;
QUIT;

PROC SQL;
SELECT L5, sum(DOLLARS) from sales_data where brand = 'COLGATE' group by L5;
QUIT;


PROC SQL;
SELECT week, sum(DOLLARS) from Groc_store group by week ;
QUIT;

PROC SQL;
SELECT week, sum(DOLLARS) from Drug_store group by week ;
QUIT;

proc sql;
create table sales_data1 as
select a.*, b.tot_units from sales_data a 
inner join (select IRI_KEY, week, brand,sum(UNITS) as tot_units
			from sales_data group by IRI_KEY, week, brand) b on a.IRI_KEY = b.IRI_KEY 
			and a.week = b.week and a.brand = b.brand;
quit;

data sales_data1;
retain IRI_KEY week brand L4 L5 COLUPC DOLLARS_PER_UNIT price_wt units tot_units PR PR_wt D disp_wt F Feature Feature_wt;
set sales_data1;
format PR_wt 4.2 disp_wt 4.2 Feature_wt 4.2 DOLLARS_PER_UNIT 4.2 price_wt 4.2;
price_wt = DOLLARS_PER_UNIT*units/tot_units;
PR_wt = PR*units/tot_units;
disp_wt = disp*units/tot_units;
Feature_wt = Feature*units/tot_units;
run;

proc sql;
create table sales_brandwise as
select IRI_KEY, week, brand,
sum(price_wt) as tot_price_wt,
sum(PR_wt) as tot_PR_wt, 
sum(disp_wt) as tot_disp_wt, 
sum(Feature_wt) as tot_Feature_wt
from sales_data1
group by IRI_KEY, week, brand
order by IRI_KEY, week, brand;
quit;

proc sql;
create table iri_lt4_brands as 
select iri_key, week, count(*) as cnt from sales_brandwise group by iri_key, week having cnt < 4;
quit;

proc sql;
create table iri_weeks as 
select distinct iri_key, week from sales_brandwise where iri_key not in (select distinct iri_key from iri_lt4_brands)
order by iri_key, week;
quit;

data iri_weeks;
set iri_weeks;
retain week1;
by IRI_KEY;
id = 1;
if first.IRI_KEY then do;
	week1 = 0;
	id = 0;
end;
diff= week - week1;
week1 = week;
run;

proc sql;
create table iri_allweek as
select IRI_KEY, sum(diff) as sum, count(distinct week) as cnt from iri_weeks where id =1
group by 1;
quit;

data iri_allweek;
set iri_allweek;
miss = (sum=cnt);
run;

proc sql;
create table sales_brandwise_allweek as
select * from sales_brandwise where IRI_KEY in (select distinct IRI_KEY from iri_allweek where miss=1)
order by IRI_KEY, week ;
quit;

data brand1 brand2 brand3 brand4;
set sales_brandwise_allweek;
if brand = 'COLGATE' then output brand1;
else if brand = 'ORAL-B' then output brand2;
else if brand = 'REACH' then output brand3;
else output brand4;
run;

proc sql;
create table all_brand_wt_price as
select
a.IRI_KEY, a.week,

a.tot_price_wt as wt_price_brand1,
a.tot_PR_wt as PR_wt_brand1,
a.tot_disp_wt as disp_wt_brand1,
a.tot_Feature_wt as Feature_wt_brand1,

b.tot_price_wt as wt_price_brand2,
b.tot_PR_wt as PR_wt_brand2,
b.tot_disp_wt as disp_wt_brand2,
b.tot_Feature_wt as Feature_wt_brand2,

c.tot_price_wt as wt_price_brand3,
c.tot_PR_wt as PR_wt_brand3,
c.tot_disp_wt as disp_wt_brand3,
c.tot_Feature_wt as Feature_wt_brand3,

d.tot_price_wt as wt_price_brand4,
d.tot_PR_wt as PR_wt_brand4,
d.tot_disp_wt as disp_wt_brand4,
d.tot_Feature_wt as Feature_wt_brand4

from brand1 a 
inner join brand2 b on a.IRI_KEY = b.IRI_KEY and a.week = b.week
inner join brand3 c on a.IRI_KEY = c.IRI_KEY and a.week = c.week
inner join brand4 d on a.IRI_KEY = d.IRI_KEY and a.week = d.week
order by a.IRI_KEY, a.week;
quit;


%macro brands(brand,brand_num);
proc sql;
create table brand_&brand_num. as
select 
b.*,

b.wt_price_brand1*b.PR_wt_brand1 as price_PR1,
b.wt_price_brand2*b.PR_wt_brand1 as price_PR2,
b.wt_price_brand3*b.PR_wt_brand1 as price_PR3,
b.wt_price_brand4*b.PR_wt_brand1 as price_PR4,

b.wt_price_brand1*b.Feature_wt_brand1 as price_F1,
b.wt_price_brand2*b.Feature_wt_brand2 as price_F2,
b.wt_price_brand3*b.Feature_wt_brand3 as price_F3,
b.wt_price_brand4*b.Feature_wt_brand3 as price_F4,

b.PR_wt_brand1*b.Feature_wt_brand1 as PR_F1,
b.PR_wt_brand2*b.Feature_wt_brand2 as PR_F2,
b.PR_wt_brand3*b.Feature_wt_brand3 as PR_F3,
b.PR_wt_brand4*b.Feature_wt_brand3 as PR_F4,

case when a.tot_units is null then 0
else a.tot_units end as tot_units

from all_brand_wt_price b
inner join (select IRI_KEY, week, brand,sum(UNITS) as tot_units
			from sales_data
			where brand = &brand.
			group by IRI_KEY, week, brand ) a
on a.IRI_KEY = b.IRI_KEY and a.week = b.week
order by IRI_KEY, week;
quit;

proc panel data=brand_&brand_num.;
model tot_units =   wt_price_brand1 wt_price_brand2 wt_price_brand3 wt_price_brand4
					disp_wt_brand1 disp_wt_brand2 disp_wt_brand3 disp_wt_brand4
					Feature_wt_brand1 Feature_wt_brand2 Feature_wt_brand3 Feature_wt_brand4
					PR_wt_brand1 PR_wt_brand2 PR_wt_brand3 PR_wt_brand4

					price_PR1 price_PR2 price_PR3 price_PR4
					price_F1 price_F2 price_F3 price_F4
					PR_F1 PR_F2 PR_F3 PR_F4
				    / fixtwo vcomp=fb plots=none;
id IRI_KEY week;
run;

%mend;
%brands('COLGATE',1);


proc sql;
select avg(wt_price_brand1 ),avg(wt_price_brand2 ),avg(wt_price_brand3 ),avg(wt_price_brand4 ),avg(disp_wt_brand1 ),
avg(disp_wt_brand2 ),avg(disp_wt_brand3 ),avg(disp_wt_brand4 ),avg(Feature_wt_brand1 ),avg(Feature_wt_brand2 ),
avg(Feature_wt_brand3 ),avg(Feature_wt_brand4 ),avg(PR_wt_brand1 ),avg(PR_wt_brand2 ),avg(PR_wt_brand3 ),
avg(PR_wt_brand4 ),avg(price_PR1 ),avg(price_PR2 ),avg(price_PR3 ),avg(price_PR4 ),avg(price_F1 ),avg(price_F2 ),avg(price_F3 ),
avg(price_F4 ),avg(PR_F1 ),avg(PR_F2 ) ,avg(PR_F3 ),avg(PR_F4 )from Brand_1;quit;

proc sql;
select avg(tot_units)from Brand_4;quit;

/*panel_prod_details csv import */

/* Study of preference of customer based on price reduction flag, display etc.*/
proc sql; 
create table panel_prod_details1 as select a.*,case when a.L5 in ('COLGATE','COLGATE 360','COLGATE ACTIVE ANGLE','COLGATE BARBIE','COLGATE BLUES CLUES','COLGATE CLASSIC','COLGATE COLOR CHANGE','COLGATE DISNEY ATLANTIS','COLGATE EXTRA CLEAN','COLGATE GRIP EMS','COLGATE HE MAN','COLGATE LEGO','COLGATE MASSAGER','COLGATE NAVIGATOR','COLGATE NICK JR DORA THE EXPL','COLGATE NICK THE FRLY ODD PAR','COLGATE PLUS','COLGATE PLUS KOOL LOOKS','COLGATE PLUS RIPPLED','COLGATE PLUS ULTRA FIT','COLGATE POWER PUFF','COLGATE SENSITIVE','COLGATE SHREK','COLGATE SPONGEBOB SQUAREPANTS','COLGATE SUPER','COLGATE SUPERMAN','COLGATE TOTAL','COLGATE TOTAL DESIGNS','COLGATE TOTAL PROFESSIONAL','COLGATE WAVE','COLGATE WHITENING','COLGATE ZIGZAG','MY FIRST COLGATE') then 'COLGATE'
when a.L5 in ('ORAL B','ORAL B ADVANTAGE','ORAL B ADVANTAGE ARTICA','ORAL B ADVANTAGE PLUS','ORAL B BLUES CLUES','ORAL B CLASSIC','ORAL B CROSSACTION','ORAL B CROSSACTION VITALIZER','ORAL B GRIPPER','ORAL B INDICATOR','ORAL B NICKELODEON','ORAL B PULSAR','ORAL B RADICAL CONTROL','ORAL B RUGRATS','ORAL B SENSITIVE ADVANTAGE','ORAL B SESAME STREET','ORAL B STAGES','ORAL BRIGHT') then 'ORAL-B'
when a.L5 in ('REACH','REACH ADVANCED','REACH ADVANCED CLEAN ANGLE','REACH ADVANCED DESIGN','REACH ADVANCED GUM ACTION',
'REACH ANTIBACTERIAL','REACH BETWEEN','REACH CLEAN AND WHITEN','REACH CLEAN SWEEP','REACH CURIOUS GEORGE','REACH HARRY POTTER',
'REACH IN BETWEEN','REACH INTERDENTAL','REACH JIMMY NEUTRON','REACH JUSTICE LEAGUE','REACH MAX',
'REACH MAX BRIGHTENER','REACH MAX FRESH & CLEAN','REACH MAX TOOTH & GUM','REACH MAX TOOTH & GUM WONDERT',
'REACH PERFORMANCE','REACH PLAQUE BLASTER','REACH PLAQUE SWEEPER','REACH PLAQUE SWEEPER BETWEEN','REACH SPONGEBOB SQUAREPANTS',
'REACH SQUEEZE','REACH STRAWBERRY SHORTCAKE','REACH TOOTH & GUM CARE','REACH ULTRA CLEAN','REACH WONDER GRIP')
then 'REACH' else 'OTHER' end as brand from panel_prod_details a; quit;

proc sql;
create table brand_choice_store_features as
select a.*,b.*
from panel_prod_details1 a
inner join All_brand_wt_price b 
on a.iri_key = b.iri_key and a.week = b.week
order by a.panid, a.week;
quit;

data brand_choice_store_features;
set brand_choice_store_features(drop= outlet dollars iri_key L4);
if brand = 'COLGATE' then brand_id = 1;
else if brand = 'ORAL-B' then brand_id = 2;
else if brand = 'REACH' then brand_id = 3;
else brand_id = 4;
run;

data brand_choice_store_features;
set brand_choice_store_features;
if brand_id = 4 then delete;
run;

proc logistic data=brand_choice_store_features; 
class brand (ref= 'COLGATE');
model brand = disp_wt_brand1 disp_wt_brand2 disp_wt_brand3 disp_wt_brand4 
				Feature_wt_brand1 Feature_wt_brand2 Feature_wt_brand3 Feature_wt_brand4
				PR_wt_brand1 PR_wt_brand2 PR_wt_brand3 PR_wt_brand4
				/ link = glogit expb clodds=PL; 
run; 

/* RFM Analysis */
libname A1 'H:\';
data rfm1;
set A1.panel_prod_details;
run;

proc sql;
create table rfm_colgate as select * from rfm1
where (L5 Like '%COLGATE%');quit;

PROC SQL;
CREATE TABLE RFM_data
AS
(
SELECT PANID, MAX(WEEK) AS Rec, COUNT(WEEK) AS Freq, SUM(DOLLARS) AS Mon
FROM rfm_colgate
GROUP BY PANID
);
quit;

proc sort data= RFM_data out=RFM_out;
by DESCENDING Rec;
run;
proc print data = rfm_out(obs=10);run;

PROC RANK DATA=RFM_out out=RFM_r ties=low groups=4;
var Rec;
ranks R;
run;

proc print data = rfm_r(obs=10);run;

PROC RANK DATA=RFM_r out=RFM_rf ties=low groups=4;
var Freq;
ranks F;
run;

proc print data = rfm_rf(obs=10);run;

PROC RANK DATA=RFM_rf out=RFM_rfm ties=low groups=4;
var Mon;
ranks M;
run;

proc print data = rfm_rfm(obs=10);run;

PROC CORR DATA = rfm_rfm;
VAR R F M; run;

data RFMX;
set RFM_rfm;
R+1;
M+1;
RFMScore=cats(of R M);
run;

DATA groups; SET RFMx;
IF  RFMScore = 44 THEN groups = "Best Customers";
IF  (R= 4) AND (1 <= M <= 3 ) THEN groups = "Potential Loyals";
IF  (R = 3) AND (M = 4 ) THEN groups = "Big Spenders";
IF  (R = 3) AND (1 <= M <= 3 ) THEN groups = "At risk";
IF  (R = 2) AND (3 <= M <= 4 ) THEN groups = "At risk";
IF  (R = 2) AND (1 <= M <= 2 ) THEN groups = "Potential Loyals";
IF  (R = 1) AND (M = 4 ) THEN groups = "Potential Loyals";
IF  (R = 1) AND (1 <= M <= 3 ) THEN groups = "Lost and Non monetary";
RUN;

proc print data = groups(obs = 10);run;

proc means data = groups;
  class groups;
  var M;
  output out=bucketsummary;
run;

proc freq data = groups;run;

proc gchart data = groups;
pie groups/percent = arrow;run;

