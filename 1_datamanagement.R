

#title: "Economic and Environmental Indicators - Descriptive File"
#author: "Andrew Barnes"

##runs on R-Studio Version 1.4.1717
## R version 4.1.1 (2021-08-10) -- "Kick Things"


#data management and input file - do this first and then farm types can be done in any order

##Manual inputs
Curr_year <- 2020 # This is the *crop year* being studied
Prev_year <- Curr_year-1  # Calculates previous year for QA analysis
Carbon_audit_dataset_name <- "CA_test_dataset.csv" # Change to name of input dataset from carbon audit
NUE_dataset_name <- "NUE_test_dataset.csv" # Change to name of input dataset from nitrogen use efficiency


# Imported data as csv into stata - use strict binding and all variables set to lower case
# Used stata to merge FBS with NUE and KGoutput files
# these were the nue with the extra kg_ha figures for N in, out and farm surplus
# note codes relate to those extracted - some were changed at extraction from FBS variable name and needs to be 
# checked if this is run again

# block run the code to check results and numbering of clusters

#set working directory to project files - here just uploaded from the import dataset window in R studio
library(haven)
#CA <- read.csv("maindata_full_nkg3.csv")




library(tidyverse)
library(ggplot2) # Library used to create graphs
library(psych) # just for tables
library(ade4) #  used to show cluster plots

#names(CA)
#DF - testing creating Input dataset
CA_test <- read.csv(Carbon_audit_dataset_name)
colnames(CA_test) <- gsub(" ","",colnames(CA_test))
colnames(CA_test) <- gsub("\\.","",colnames(CA_test))
NUE_test <-read.csv(NUE_dataset_name)
colnames(NUE_test) <- gsub(" ","",colnames(NUE_test))
colnames(NUE_test) <- gsub("\\.","",colnames(NUE_test))
NUE_test <- NUE_test %>% 
  mutate(NUE=as.character(NUE)) %>% 
  mutate(FARM_N_SURPLUS=as.numeric(gsub(",","",as.character(FARM_N_SURPLUS)))) %>% 
  mutate(NOUTPUT_TOTAL=as.numeric(gsub(",","",as.character(NOUTPUT_TOTAL)))) %>% 
  mutate(NINPUT_TOTAL=as.numeric(gsub(",","",as.character(NINPUT_TOTAL)))) %>% 
  mutate(NOUTPUT_MILK=as.numeric(gsub(",","",as.character(NOUTPUT_MILK)))) %>% 
  mutate(NOUTPUT_SHEEP_MEAT=as.numeric(gsub(",","",as.character(NOUTPUT_SHEEP_MEAT)))) %>% 
  mutate(NOUTPUT_CATTLE_MEAT=as.numeric(gsub(",","",as.character(NOUTPUT_CATTLE_MEAT)))) %>% 
  mutate(NINPUT_FERT=as.numeric(gsub(",","",as.character(NINPUT_FERT))))
NUE_test <- NUE_test %>% 
  mutate(NUE=as.numeric(substr(NUE,1,nchar(NUE)-1))/100)



NUE_test <-NUE_test %>% filter(AN_CODE=="NNKG")
names(CA_test) <- tolower(names(CA_test))
names(NUE_test) <- tolower(names(NUE_test))
CA <- CA_test %>%  full_join(NUE_test,by="fa_id")

#table(CA$ys_year)
##wipes 2019 data
#CA <- CA %>%  filter(ys_year == 2019)
#glimpse(CA)

#specialisation

CA <- CA %>%
  mutate (totrev = fa_lrev + fa_crev ) %>%   #- no miscellanous
  mutate(lspec = fa_lrev/totrev)%>% 
  mutate(cspec = fa_crev/totrev)

#farm economics```
CA <- CA %>%
  mutate (gm = (fa_outpt - fa_vcexp)) %>% 
  mutate (nm = gm - fa_tfcex) %>%
  mutate (opprof = (fa_netp + i_gross_rent + i_labour + fa_int - (fa_labu*30000)))  %>%   
  mutate(rotc = fa_netp / ((fa_tccv + fa_tcov + fa_mcv + fa_mov)/2)) %>%
  mutate (vc_p = ((fa_vcexp/fa_outpt)))  %>% 
  mutate (gm_p = ((gm/fa_outpt)))%>% 
  mutate (fc_p = ((fa_tfcex/fa_outpt) ))%>% 
  mutate (op_ha = ((opprof/fa_aaua)))%>% 
  mutate (vc_ha = ((fa_vcexp/fa_aaua)))  %>% 
  mutate (gm_ha = ((gm/fa_aaua)))%>% 
  mutate (nm_ha = ((nm/fa_aaua) ))%>% 
  mutate (op_ha = ((opprof/fa_aaua)))%>% 
  mutate (fbi_ha = ((fbi/fa_aaua)))

#stocking density and milk prices```
CA <- CA %>%
  mutate (dc_glu =  ((dcow/fa_glu))) %>%
  mutate (sd_dc =  ((dcow/fa_aaua)))%>%
  mutate (m_price = fa_miout/fa_miouq) %>%
  mutate (m_v_ha = fa_miout/fa_aaua) %>%
  mutate (m_q_ha = fa_miouq/fa_aaua) %>%
  mutate (m_q_dc = fa_miouq/dcow) %>%
  mutate (sck_glu =  ((nrc/fa_glu))) %>%
  mutate (ewe_glu =  ((noe/fa_glu))) %>%  #need to adj for grazing unit - 0.4?
  mutate (sd_glu =  ((fa_glu/fa_aaua)))

#land area```

CA <- CA %>%
  mutate (arable_ha =  ((aoc+aop+aosr+aocc)/(fa_aaua))) %>%
  mutate (fodder_ha =  (aofc/fa_aaua)) %>%
  mutate (grass_ha = (agr/fa_aaua))%>%   #though same as rg in the file
  mutate (rough_grazing_ha =  ((rough_grazing/fa_aaua)))

#indicator: main product by ha```
CA <- CA %>%
  mutate (fo_kg_ha =  (farm_output_kg/fa_aaua))

#efficiency```
CA <- CA %>%
  mutate (homefeed_per =(i_fee_ho/i_feed)) %>%
  mutate (feed_lu =(i_feed/fa_glu)) %>%
  mutate (ifeed_out =  i_feed /  fa_outpt) %>%  #feed (not adjusted for homegrown) to output value
  mutate (ifert_out =  i_fert/  fa_outpt) %>% #fc to output value
  mutate (ifert_ha =  i_fert/  fa_aaua) %>%
  mutate (inp_out =   i_totnew /  fa_outpt)%>%
  mutate (out_inp =   fa_outpt / i_totnew )

#GHG proportions```
CA <- CA %>%
  mutate (ghg_CO2e = total_de + total_ie + total_me + total_no) %>%  
  mutate (ghg_CO2e_ha = ghg_CO2e/fa_aaua) %>%  
  mutate (de_ghg = (total_de / (total_de + total_ie + total_me + total_no))) %>%  
  mutate (ie_ghg = (total_ie /(total_de + total_ie + total_me + total_no))) %>% 
  mutate (me_ghg = (total_me /(total_de + total_ie + total_me + total_no))) %>% 
  mutate (no_ghg = (total_no /(total_de + total_ie + total_me + total_no))) %>% 
  mutate (ghg_ha = ghg_CO2e/fa_aaua)%>%
  mutate (tde_ha = total_de/fa_aaua)%>%
  mutate (tie_ha = total_ie/fa_aaua)%>%
  mutate (tch4_ha = total_me/fa_aaua)%>%
  mutate (tn20_ha = total_no/fa_aaua)

#GHG per output
CA <- CA %>%
  mutate (ghg_kgout = ghg_CO2e/farm_output_kg)%>%  #emissions intensity
  mutate (ghg_ha_kg = ghg_ha/farm_output_kg)%>%
  mutate (tde_ha_kg = tde_ha/farm_output_kg)%>%
  mutate (tie_ha_kg = tie_ha/farm_output_kg)%>%
  mutate (tch4_ha_kg = tch4_ha/farm_output_kg)%>%
  mutate (tn20_ha_kg = tn20_ha/farm_output_kg)%>%
  mutate (fuelelect = de_d + de_e + de_of + de_re + de_rh)%>%
  mutate (fuel_kg = fuelelect /farm_output_kg )
CA <- CA %>% 
  mutate (ghg_p = total_de/ghg_CO2e)%>%
  mutate (tie_ha_p = total_ie/ghg_CO2e)%>%
  mutate (tch4_ha_p = (total_me)/ghg_CO2e)%>%
  mutate (tn20_ha_p = (total_no)/ghg_CO2e) %>%
  mutate (ch4_n20_kg = (total_me + total_no)) %>% # total kg of bad stuff
  mutate (ch4_n20_kg_ha = (ch4_n20_kg / fa_aaua))


#net emissions```
CA <- CA %>% 
  mutate (netem_ha = (netmlandu / fa_aaua))%>%
  mutate (seq_ha = (seqfor / fa_aaua))%>%
  mutate (seq_emms_p = seqfor / (total_de + total_ie + total_me + total_no))%>%
  mutate (wood_aua_p = (afwl+aowl) / (fa_aaua+ afwl+aowl))%>%
  mutate (fwood_aua_p = (afwl / (fa_aaua + afwl +aowl)))

CA <- CA %>%
  mutate (lu_ha = fa_glu / fa_aaua) %>%   
  mutate(slr_ha = averagessizeofbusiness / fa_aaua)%>%
  mutate(eff_area = fa_aaua /(fa_aaua+afwl+aowl))  # effective area is farm area 

#nitrogen use efficiency - from SAC report```
CA <-  CA %>%
  mutate(nue_p = (nue *100))%>%
  mutate(nue_p_ha = (nue / fa_aaua)*100) %>%
  mutate(nsurplus_p_ha = (farm_n_surplus / fa_aaua)*100)%>%
  mutate(noutput_p_ha = (noutput_total / fa_aaua)*100) %>%
  mutate(ninput_p_ha = (ninput_total / fa_aaua)*100) %>%
  mutate(n_inp_fert_p_ha = (ninput_fert / fa_aaua)*100) 

CA <-  CA %>%
  mutate(n_milk = (noutput_milk / noutput_total)) %>%
  mutate(n_sheep = (noutput_sheep_meat / noutput_total))%>%
  mutate(n_cattle = (noutput_cattle_meat / noutput_total))%>%
  mutate(n_wholecrop = (noutput_wholecrop / noutput_total))%>%
  mutate(noutput_straw = (noutput_wholecrop / noutput_total))%>%
  mutate(noutput_silage = (noutput_wholecrop / noutput_total))

#develop farm types```
glimpse(CA$farmtype)
CA$type <- CA$farmtype  #changed the name of the variable between loads - watch out for changes
unique(CA$type) 
C <-  CA %>% filter(type == "Cereal",ys_year==Curr_year) # Cereal Variable
GC <- CA %>% filter(type == "General Cropping",ys_year==Curr_year) # General Cropping
M <- CA %>%  filter(type == "Mixed",ys_year==Curr_year) # Mixed
LCS <- CA %>%  filter(type == "Lowland Cattle & Sheep",ys_year==Curr_year)  # Lowland Cattle & Sheep
D <- CA %>%  filter(type == "Dairy",ys_year==Curr_year) # Dairy
SDASS <- CA %>%  filter(type == "SDA Specialist Sheep",ys_year==Curr_year) # SDA Spacialist Sheep
SDASC <- CA %>%  filter(type == "SDA Sheep & Cattle",ys_year==Curr_year) #SDA Sheep and Cattle /not error here
SDAC <- CA %>%  filter(type == "SDA Cattle",ys_year==Curr_year)
ALLCS  <- CA %>% filter (type == "SDA Cattle" | type == "Lowland Cattle & Sheep" | type == "SDA Specialist Sheep" | type == "SDA Sheep & Cattle",ys_year==Curr_year)
ALLLFA  <- CA %>% filter (type == "SDA Cattle" |  type == "SDA Specialist Sheep" | type == "SDA Sheep & Cattle",ys_year==Curr_year)
CROP <- CA %>% filter(type == "Cereal" | type == "General Cropping",ys_year==Curr_year) 
table(CA$type)

#including one for LFA-only drystock```
CA$ob <- as.character(CA$type)
CA$ob[CA$ob %in% c("SDA Cattle", "SDA Specialist Sheep", "SDA Sheep & Cattle")] <- "LFA_Drystock"
#DF - commenting the next line to match figures in final report
#CA$ob[CA$ob %in% c("SDA Cattle", "SDA Specialist Sheep", "SDA Sheep & Cattle", "Lowland Cattle & Sheep")] <- "All_Drystock"
CA$ob[CA$ob %in% c("Lowland Cattle & Sheep")] <- "Low_Drystock"
CA$ob[CA$ob %in% c("Cereal")] <- "Cereal"
CA$ob[CA$ob %in% c("General Cropping")] <- "General Cropping"
CA$ob[CA$ob %in% c("Mixed")] <- "Mixed"
CA$ob[CA$ob %in% c("Dairy")] <- "Dairy"
CA$nftype <- factor(CA$ob)


table(CA$nftype)

CA$Type <- CA$nftype



#Figure 1 main plot by kg and ghg scatter```
p <-ggplot(CA, aes(x=fo_kg_ha, y=ghg_ha, col=Type)) +
  geom_point(size=2, alpha=1) + 
  theme(legend.title=element_blank())+  
  theme_bw() +
  scale_size(range = c(0, 5), name="Farm Type")
p + xlab("Product (kg/ha)") + ylab("Gross emissions (co2eq.kg/ha)")    
ggsave("Figure_1_total_ghg_scatter.png")  

#Figure 2(GHG Boxplots by farm typey and by HA ```
p <- ggplot(CA, aes(x=Type, y=ghg_ha, fill=Type)) +
  geom_boxplot()  +
  theme_bw() + 
  ylab("Gross emissions (co2eq.kg/ha)")    
p
ggsave("Figure_2_total_ghgha.png")

#Figure 2b(GHG TOTAL Boxplots by farm type farm environmental indicators```
p <- ggplot(CA, aes(x=Type, y=ghg_CO2e, fill=Type)) +
  geom_boxplot()  +
  theme(axis.text.x=element_blank()) +
  theme_bw() + 
  scale_y_continuous(name="Gross emissions (co2eq.kg)", labels = scales::comma)
p
ggsave("Figure_2b_total_ghg.png")

##DF - trying to recreate bar chart of emissions types by farmtype, in R


Fig3 <- CA %>% 
  group_by(Type) %>% 
  summarize(count=n(),direct=sum(total_de),indirect=sum(total_ie),methane=sum(total_me),nitrous=sum(total_no))
Fig3a <- Fig3 %>% 
  gather('nitrous', 'methane','indirect','direct',key="Emission_type",value="Emissions")

p <- ggplot(Fig3a, aes(x=Type,y=Emissions,fill=Emission_type)) +
  geom_col(position="fill")
p + xlab("Farm type") + ylab("Fraction of emissions")

###Year-on-year QA
source("Carbon_audit_QA.R")




###then conduct the individual farm analysis###

##runs the R code for each farm type - needs to have all files in same project
##note you have no control on the numbering of the clusters running in batch
source("2_drystock_LFAonly.R")
source("3_cereals.R")
source("4_dairy.R")
source("5_gencrop.R")
source("6_mixed.R")



