#***********************************************
#*Sample code to estimate MNL models with apollo
#***********************************************

# install the package if it has not been installed
if (!("apollo" %in% rownames(installed.packages()))){
  install.packages("apollo")
} 
if (!("tidyverse" %in% rownames(installed.packages()))){
  install.packages("tidyverse")
} 

# ################################################################# #
#### LOAD LIBRARY AND DEFINE CORE SETTINGS                       ####
# ################################################################# #

### Clear memory｜メモリをクリアする
rm(list = ls()) ##ça supprime tout 

### Load Apollo library｜パッケージをロードする
library(apollo)
library(tidyverse)

### Initialise code｜コードを初期化する
apollo_initialise()

### Set core controls｜コア項目を設定する（モデル名、モデルの説明、個人IDの変数設定）
apollo_control = list(
  modelName  ="Apollo MidTerm normal",
  modelDescr ="Simple MNL model on mode choice RP data",
  indivID    ="ID" #based on the dataset
)

# ################################################################# #
#### LOAD DATA AND APPLY ANY TRANSFORMATIONS                     ####
# ################################################################# #

### read data|データを読み込む
database = read.csv("smdata_ps1.csv",header=TRUE)

#Question 1
total = sum(database$CHOICE==0)+ sum(database$CHOICE==1) + sum(database$CHOICE==2) + sum(database$CHOICE==3)
unknown = sum(database$CHOICE==0)/total
train = sum(database$CHOICE==1)/total
SM = sum(database$CHOICE==2)/total
car = sum(database$CHOICE==3)/total

d = c(unknown,train,SM,car)
# Labels correspondant aux portions du camembert
labels <- c("Unknown", "Train", "SM", "Car")
# Couleurs pour chaque portion

pie(d,label = labels)
title("Proportion of different mean of transport")


# ################################################################# #
#### ANALYSIS OF CHOICES                                         ####
# ################################################################# #

choiceAnalysis_settings <- list(
  alternatives = c(train=1, SM=2, car=3),
  avail        = list(train=database$TRAIN_AV, SM=database$SM_AV,  car=database$CAR_AV),
  choiceVar    = database$CHOICE,
  explanators  = database[,c("TICKET","WHO","LUGGAGE","AGE","MALE","INCOME","GA","ORIGIN","DEST","INCOME")],
  rows         = 'all'
)

apollo_choiceAnalysis(choiceAnalysis_settings, apollo_control, database)



# ################################################################# #
#### DEFINE MODEL PARAMETERS                                     ####
# ################################################################# #

### Vector of parameters, including any that are kept fixed in estimation
### 固定パラメータを含むパラメータのベクトル
apollo_beta=c(asc_train   = 0,    #Initial value start from 0
              asc_sm   = 0,
              b_ctr = 0,
              b_csm = 0,
              b_ccar = 0,
              b_tt_pt = 0,
              b_tt_car  = 0,
              b_ga = 0,
              b_income = 0)

### Vector with names (in quotes) of parameters to be kept fixed at their starting value in apollo_beta, use apollo_beta_fixed = c() if none
###　初期値で固定する定数項（固定パラメータがない場合、apollo_beta_fixed = c()を使う）
apollo_fixed = c()
# ################################################################# #
#### GROUP AND VALIDATE INPUTS                                   ####
# ################################################################# #
### 入力確認
apollo_inputs = apollo_validateInputs()

# ################################################################# #
#### DEFINE MODEL AND LIKELIHOOD FUNCTION                        ####
# ################################################################# #

apollo_probabilities=function(apollo_beta, apollo_inputs, functionality="estimate"){
  
  ### Attach inputs and detach after function exit
  apollo_attach(apollo_beta, apollo_inputs)
  on.exit(apollo_detach(apollo_beta, apollo_inputs))
  
  ### Create list of probabilities P｜確率のリストを作成する
  P = list()
  
  ### List of utilities: these must use the same names as in mnl_settings, order is irrelevant
  ### 効用関数のリスト：選択肢の名義は以下の「mnl_settings」と同じでなければならない（順番は関係ない）
  V = list()
  V[['train']]  = asc_train  + b_ctr  * TRAIN_CO + b_tt_pt * TRAIN_TT + b_ga*GA + b_income*INCOME
  V[['SM']]  = asc_sm  + b_csm*SM_CO + b_tt_pt * SM_TT + b_ga*GA + b_income*INCOME
  V[['car']]  = b_ccar*CAR_CO + b_tt_car*CAR_TT + b_income*INCOME
  
  ### Define settings for MNL model component
  ###　MNLモデル項目を設定する
  mnl_settings = list(
    alternatives  = c(train=1, SM=2, car=3), 
    avail         = list(train=TRAIN_AV, SM=SM_AV,  car=CAR_AV),
    choiceVar     = CHOICE,
    V             = V
  )
  
  ### Compute probabilities using MNL model
  ### MNLを用いて選択確率を求める
  P[['model']] = apollo_mnl(mnl_settings, functionality)
  
  ### Take product across observation for same individuals(panel data only)
  ###　個体（意思決定者）毎の確率積を求める（パネルデータの場合のみ）
 # P = apollo_panelProd(P, apollo_inputs, functionality)
  
  ### Prepare and return outputs of function
  ### アウトプットを整理して返す
  P = apollo_prepareProb(P, apollo_inputs, functionality)
  return(P)
}

# ################################################################# #
#### MODEL ESTIMATION                                            ####
# ################################################################# #

model = apollo_estimate(apollo_beta, apollo_fixed, apollo_probabilities, apollo_inputs)

# ################################################################# #
#### MODEL OUTPUTS                                               ####
# ################################################################# #

# ----------------------------------------------------------------- #
#---- FORMATTED OUTPUT (TO SCREEN)                               ----
# ----------------------------------------------------------------- #

apollo_modelOutput(model)

# ----------------------------------------------------------------- #
#---- FORMATTED OUTPUT (TO FILE, using model name)               ----
# ----------------------------------------------------------------- #

#apollo_saveOutput(model)

# ################################################################# #
#### PREDICTION                                                  ####
# ################################################################# #

# ----------------------------------------------------------------- #
#---- ESTIMATED PROBABILITIES                                    ----
# ----------------------------------------------------------------- #

predictions = apollo_prediction(model, apollo_probabilities, apollo_inputs)
print(as_tibble(predictions))

#Change the value of travel time
database$SM_TT = database$SM_TT*0.8

#MODIFICATION POUR QUESTION 4/5 
database$TRAIN_TT = mean(subset(database,database$DEST == 22& database$ORIGIN == 1)$TRAIN_TT)
database$CAR_TT = mean(subset(database,database$DEST == 22& database$ORIGIN == 1)$CAR_TT)
database$SM_TT = 200

#Rerun predictions with the new data｜変更したデータを用いて予測する
apollo_inputs = apollo_validateInputs()
predictions_new = apollo_prediction(model, apollo_probabilities, apollo_inputs)
print(as_tibble(predictions_new))

#Return to original data (Important!)｜データ元に戻す（重要！）
database = read.csv("/Users/jordan/Documents/UTokyo_UTPA/Midterm Assignement/smdata_ps1.csv",header=TRUE)
apollo_inputs = apollo_validateInputs()



#Question 3 
agg_train = mean(predictions$train)
agg_car = mean(predictions$car)
agg_sm = mean(predictions$SM)

#Question 4
#Creating a subset with only GA holder
GA_holder = subset(database,database$GA==1)
pred_GA_holder = subset(predictions_new,  predictions_new$ID %in%  GA_holder$ID)
plot(GA_holder$SM_TT,pred_GA_holder$train,col= "#5DCDF4", xlab="Swissmetro travel time for GA holder",ylab="Choice probabilities for GA holder")
points(GA_holder$SM_TT,pred_GA_holder$SM, col="#F45D82" )
points(GA_holder$SM_TT,pred_GA_holder$car, col ="#845DF4")
legend(200,0.8,legend=c("Train","SM","Car"),col=c("#5DCDF4","#F45D82","#845DF4"),pch=1)


#Creating a subset with only non GA holder
GA_nonholder = subset(database,database$GA==0)
pred_GA_nonholder = subset(predictions_new,  predictions_new$ID %in%  GA_nonholder$ID)
plot(GA_nonholder$SM_TT,pred_GA_nonholder$train,col= "#5DCDF4", xlab="Swissmetro travel time for GA holder",ylab="Choice probabilities for GA nonholder")
points(GA_nonholder$SM_TT,pred_GA_nonholder$SM, col="#F45D82" )
points(GA_nonholder$SM_TT,pred_GA_nonholder$car, col ="#845DF4")
legend(650,0.25,legend=c("Train","SM","Car"), col=c("#5DCDF4","#F45D82","#845DF4"),pch = 1)

#Question 5
agg_train_SMTT200 = mean(predictions_new$train)
agg_car_SMTT200 = mean(predictions_new$car)
agg_sm_SMTT200 = mean(predictions_new$SM)

#Question 6
est_asc_train   = apollo_modelOutput(model)[1]
est_sc_sm   = apollo_modelOutput(model)[2]
est_b_ctr = apollo_modelOutput(model)[3]
est_b_csm = apollo_modelOutput(model)[4]
est_b_ccar = apollo_modelOutput(model)[5]
est_b_tt_pt = apollo_modelOutput(model)[6]
est_b_tt_car  = apollo_modelOutput(model)[7]
b_ga = apollo_modelOutput(model)[8]

#Individual direct elasticity
Eid_train_CO = (1-train)*database$TRAIN_CO*est_b_ctr
Eid_train_TT = (1-train)*database$TRAIN_TT*est_b_tt_pt
Eid_SM_CO = (1-SM)*database$SM_CO*est_b_csm
Eid_SM_TT = (1-SM)*database$SM_TT*est_b_tt_pt
Eid_car_CO = (1-car)*database$CAR_CO*est_b_ccar
Eid_car_TT = (1-car)*database$CAR_TT*est_b_tt_car

#Individual cross elasticity
Eic_SM_CO = -SM*database$SM_CO*est_b_csm
Eic_SM_TT = -SM*database$SM_TT*est_b_tt_pt
Eic_CAR_CO = -car*database$CAR_CO*est_b_ccar
Eic_CAR_TT = -car*database$CAR_TT*est_b_tt_car
Eic_TRAIN_CO = -train*database$TRAIN_CO*est_b_ctr
Eic_TRAIN_TT = -train*database$TRAIN_TT*est_b_tt_pt

#Aggregate direct elasticity
Ead_train_CO = sum(predictions$train*Eid_train_CO)/sum(predictions$train)
Ead_train_TT = sum(predictions$train*Eid_train_TT)/sum(predictions$train)
Ead_SM_CO = sum(predictions$SM*Eid_SM_CO)/sum(predictions$SM)
Ead_SM_TT = sum(predictions$SM*Eid_SM_TT)/sum(predictions$SM)
Ead_car_CO = sum(predictions$car*Eid_car_CO)/sum(predictions$car)
Ead_car_TT = sum(predictions$car*Eid_car_TT)/sum(predictions$car)

#Aggregate cross elasticity
Eac_train_SM_CO = sum(predictions$train*Eic_SM_CO)/sum(predictions$train)
Eac_train_SM_TT = sum(predictions$train*Eic_SM_TT)/sum(predictions$train)
Eac_train_CAR_CO = sum(predictions$train*Eic_CAR_CO)/sum(predictions$train)
Eac_train_CAR_TT = sum(predictions$train*Eic_CAR_TT)/sum(predictions$train)

Eac_SM_TRAIN_CO = sum(predictions$SM*Eic_TRAIN_CO)/sum(predictions$SM)
Eac_SM_TRAIN_TT = sum(predictions$SM*Eic_TRAIN_TT)/sum(predictions$SM)
Eac_SM_CAR_CO = sum(predictions$SM*Eic_CAR_CO)/sum(predictions$SM)
Eac_SM_CAR_TT = sum(predictions$SM*Eic_CAR_TT)/sum(predictions$SM)

Eac_car_SM_CO = sum(predictions$car*Eic_SM_CO)/sum(predictions$car)
Eac_car_SM_TT = sum(predictions$car*Eic_SM_TT)/sum(predictions$car)
Eac_car_TRAIN_CO = sum(predictions$car*Eic_TRAIN_CO)/sum(predictions$car)
Eac_car_TRAIN_TT = sum(predictions$car*Eic_TRAIN_TT)/sum(predictions$car)


#Question 8
#Individual direct marginal
Mid_train_CO = train*(1-train)*est_b_ctr
Mid_train_TT = train*(1-train)*est_b_tt_pt
Mid_train_GA = train*(1-train)*b_ga
Mid_SM_CO = SM*(1-SM)*est_b_csm
Mid_SM_TT = SM*(1-SM)*est_b_tt_pt
Mid_SM_GA = SM*(1-SM)*b_ga
Mid_car_CO = car*(1-car)*est_b_ccar
Mid_car_TT = car*(1-car)*est_b_tt_car
Mid_car_GA = car*(1-car)*b_ga

#Aggregate direct marginal
Mad_train_CO = sum(predictions$train*Mid_train_CO)/sum(predictions$train)
Mad_train_TT = sum(predictions$train*Mid_train_TT)/sum(predictions$train)
Mad_train_GA = sum(predictions$train*Mid_train_GA)/sum(predictions$train)
Mad_SM_CO = sum(predictions$SM*Mid_SM_CO)/sum(predictions$SM)
Mad_SM_TT = sum(predictions$SM*Mid_SM_TT)/sum(predictions$SM)
Mad_SM_GA = sum(predictions$SM*Mid_SM_GA)/sum(predictions$SM)
Mad_car_CO = sum(predictions$car*Mid_car_CO)/sum(predictions$car)
Mad_car_TT = sum(predictions$car*Mid_car_TT)/sum(predictions$car)
Mad_car_GA = sum(predictions$car*Mid_car_GA)/sum(predictions$car)

#Question 10
VTTS_train = est_b_tt_pt/est_b_ctr
VTTS_SM = est_b_tt_pt/est_b_csm
VTTS_car = est_b_tt_car/est_b_ccar

#Question 11
#database modified : database$SM_TT = database$SM_TT*0.8
agg_train_smttreduced = mean(predictions_new$train)
agg_car_smttreduced = mean(predictions_new$car)
agg_sm_smttreduced = mean(predictions_new$SM)

