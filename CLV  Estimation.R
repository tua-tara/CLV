

# Set the working Directory


setwd("D:/Data Analytics - Insurance/Customer Lifetime value model/clv")


# install.packages("dummies")

# Load required libraries
library(vegan)
library(dummies)
library(xgboost)


# import the Data 


CLV =read.csv("CLVtrain.csv")

CLVtest = read.csv("CLV test.csv")



# Understand the structure of data


Str(CLV)

Str(CLVtest)

customer=subset(CLVtest,select=c(CustomerID))

CLVtest$CustomerID=NULL

levels(CLVtest$EmploymentStatus)=c("Disabled","Employed","Medical Leave","Unemployed","Retired")

#b. Understand the summary of the data set


summary(CLV )

summary(CLVtest)


# Select Numeric features


numeric = CLV [sapply(CLV ,is.numeric)]

numeric = subset(numeric, select = -c(Customer.Lifetime.Value))

numerictest=CLVtest[sapply(CLVtest,is.numeric)]


# Select Response feature


target = subset(CLV , select = c(Customer.Lifetime.Value))


# Select Numeric features


cat=CLV [sapply(CLV ,is.factor)]

cattest=CLVtest[sapply(CLVtest,is.factor)]



# Convert all categorical attributes to numeric 
# 1. Using dummy function, convert education and family categorical attributes into numeric attributes

library(dummies)

cat=dummy.data.frame(cat)

colnames(cat)

cattest=dummy.data.frame(cattest)

colnames(cattest)

cattest$EmploymentStatusRetired=0

final_Data=data.frame(numeric,cat,target)

final_Data_test=data.frame(numerictest,cattest)


#############################################################
library(caret)
set.seed(123)

index_train <- createDataPartition(final_Data$Customer.Lifetime.Value, p = 0.8, list = F)

pre_train <- final_Data[index_train, ]
pre_test <- final_Data[-index_train,]
########################

# Decoupling target column
train_target <- pre_train$Customer.Lifetime.Value
test_target <- pre_test$Customer.Lifetime.Value
pre_train$Customer.Lifetime.Value <- NULL
pre_test$Customer.Lifetime.Value <- NULL

# Standardize all the real valued variables in the dataset as some models we use might be impacted due to non standardized variables
std_method <- preProcess(pre_train, method = c("center", "scale"))
train_Data <- predict(std_method, pre_train)
test_Data <- predict(std_method, pre_test)

final_test_Data<- predict(std_method,final_Data_test,drop=TRUE)

# Let's use the preProcess() function from the caret package to standardize the variables,



# Constructing the Dense matrix on the train and test data

dtrain = xgb.DMatrix(data = as.matrix(train_Data),
                     label = train_target)

dtest = xgb.DMatrix(data = as.matrix(test_Data),
                    label = test_target)


# fit the model
model = xgboost(data = dtrain, max.depth =5 , 
                eta = 0.3, nthread = 3, nround = 100, 
                objective = "reg:linear", verbose = 1)

# objective = "reg:linear": we will train a regression model ;
# max.deph = 5: the trees won't be deep, because our case is very simple ;
# nthread = 3: the number of cpu threads we are going to use;
# nround : max number of boosting iterations.
# eta : It controls the learning rate
# verbose = 1: print evaluation metric

# Both xgboost (simple) and xgb.train (advanced) functions train models.

# Because of the way boosting works, there is a time when having too many rounds lead to an overfitting. One way to measure progress in learning of a model is to provide to XGBoost a second dataset already classified. 
#Therefore it can learn on the first dataset and test its model on the second one.
#Some metrics are measured after each round during the learning.

#Use watchlist parameter. It is a list of xgb.DMatrix, 
#each of them tagged with a name.

watchlist = list(train=dtrain, test=dtest)

model = xgb.train(data=dtrain, max.depth=4,
                  eta=0.1, nthread = 2, nround=80, 
                  watchlist=watchlist,
                  eval.metric = "rmse", 
                  objective = "reg:linear", verbose = 1)
# eval.metric allows us to monitor two new metrics for each round, logloss and error.

importance <- xgb.importance(feature_names = names(train_Data), model = model)
print(importance)
xgb.plot.importance(importance_matrix = importance)

# Gain is the improvement in accuracy brought by a feature to the branches it is on. 
# Cover measures the relative quantity of observations concerned by a feature.
# Frequency is the number of times a feature is used in all generated trees. 

# save model to binary local file
xgb.save(model, "xgboost.model")
rm(model)

# load binary model to R
model <- xgb.load("xgboost.model")

# prediction on test data

Yhat <- predict(model, as.matrix(test_Data))



############################################################################################################################






