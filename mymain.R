library(glmnet)
library(text2vec)

#####################################
# Loading vocabulary and training data
#####################################

myvocab <- scan(file = "myvocab.txt", what = character())

train <- read.table("train.tsv", stringsAsFactors = FALSE,
                    header = TRUE)

train$review <- gsub('<.*?>', ' ', train$review)

it_train = itoken(train$review,
                  preprocessor = tolower, 
                  tokenizer = word_tokenizer)

vectorizer = vocab_vectorizer(create_vocabulary(myvocab, 
                                                ngram = c(1L, 2L)))

dtm_train = create_dtm(it_train, vectorizer)

#####################################
#
# Training a binary classification model
#
#####################################

mylogit.cv = cv.glmnet(x = dtm_train, 
                       y = train$sentiment, 
                       alpha = 0,
                       family='binomial', 
                       type.measure = "auc")

mylogit.fit = glmnet(x = dtm_train, 
                     y = train$sentiment, 
                     alpha = 0,
                     lambda = mylogit.cv$lambda.min, 
                     family='binomial')

#####################################
# Compute predictions
# "output": col 1 is test$id
#           col 2 is the predicted probabilities
#####################################

test = read.table("test.tsv",
                  stringsAsFactors = FALSE,
                  header = TRUE)

test$review <- gsub('<.*?>', ' ', test$review)

it_test = itoken(test$review,
                 preprocessor = tolower, 
                 tokenizer = word_tokenizer)

dtm_test = create_dtm(it_test, vectorizer)

mypred = predict(mylogit.fit, dtm_test, type = "response")

output = data.frame(id = test$id, prob = as.vector(mypred))

write.table(output, file = "mysubmission.txt", 
            row.names = FALSE, sep='\t')