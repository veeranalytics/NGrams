# Load Libraries
library(knitr)
library(dplyr)
library(doParallel)
library(stringi)
library(RColorBrewer)
library(tm)
library(ggplot2)
library(wordcloud)
library(SnowballC)

# Setting system environment for java to load rJava library.
# RWeka has dependenciy on rJava
Sys.setenv(JAVA_HOME='C:/Program Files/Java/jre1.8.0_191')
library(rJava)
library(RWeka)

# Set Working Directory
setwd("C:/Data/Studies/Projects/NLP_Ngrams/NGrams_Project")

# Read blogs data in binary mode
conn <- file("./en_US/en_US.blogs.txt", open="rb")
blogs <- readLines(conn, encoding="UTF-8") 
close(conn)
# Read news data in binary mode
conn <- file("./en_US/en_US.news.txt", open="rb")
news <- readLines(conn, encoding="UTF-8")
close(conn)
# Read twitter data in binary mode
conn <- file("./en_US/en_US.twitter.txt", open="rb")
twitter <- readLines(conn, encoding="UTF-8")
close(conn)

# Remove connection variable
rm(conn)

# Compute statistics and summary info for each dataframe
data_stats <- data.frame(
  Data=c("blogs","news","twitter"),
  t(rbind(sapply(list(blogs,news,twitter),stri_stats_general),
          WordCount=sapply(list(blogs,news,twitter),stri_stats_latex)[4,]))
)
data_stats

# Set random seed for reproducibility
set.seed(123)

sample_data <- c(sample(blogs, length(blogs) * 0.01),
                 sample(news, length(news) * 0.01),
                 sample(twitter, length(twitter) * 0.01))

# Remove non english character
sample_data <- iconv(sample_data, "latin1", "ASCII", sub="")

# Take a look at the data
#  head(sample_data)

# Remove temporary variables to free some memory space
rm(blogs, news, twitter)

# Build Corpus
corpus <- VCorpus(VectorSource(sample_data)) # Create corpus dataset
corpus <- tm_map(corpus, tolower) # Convert to lower case
corpus <- tm_map(corpus, removePunctuation) # Eliminate punctuation
corpus <- tm_map(corpus, removeNumbers) # Eliminate numbers
corpus <- tm_map(corpus, stripWhitespace) # Strip Whitespace
corpus <- tm_map(corpus, removeWords, stopwords("english")) # Eliminate English stop words
corpus <- tm_map(corpus, stemDocument) # Stem the document
corpus <- tm_map(corpus, PlainTextDocument) # Create plain text format

## Saving the final corpus
saveRDS(corpus, file = "./finalCorpus.RData")

# Tokenize and Calculate Frequencies of N-Grams
# Creating N-Grams using tokenizers
uni_gram_token <- function(x) NGramTokenizer(x, Weka_control(min = 1, max = 1))
bi_gram_token <- function(x) NGramTokenizer(x, Weka_control(min = 2, max = 2))
tri_gram_token <- function(x) NGramTokenizer(x, Weka_control(min = 3, max = 3))

# Creating a matrix for n-grams
uni_gram_matrix <- TermDocumentMatrix(corpus, control = list(tokenize = uni_gram_token))
bi_gram_matrix <- TermDocumentMatrix(corpus, control = list(tokenize = bi_gram_token))
tri_gram_matrix <- TermDocumentMatrix(corpus, control = list(tokenize = tri_gram_token))

# Dropping all the n-grams with some lomits on frequency of occurence 
uni_gram_corpus <- findFreqTerms(uni_gram_matrix,lowfreq = 50)
bi_gram_corpus <- findFreqTerms(bi_gram_matrix,lowfreq = 40)
tri_gram_corpus <- findFreqTerms(tri_gram_matrix, lowfreq = 7)

# Sorting and getting athe top 20 most appeared ngrams
uni_gram_vec <- sort(rowSums(as.matrix(uni_gram_matrix[uni_gram_corpus,])),decreasing=TRUE)
uni_gram_df <- data.frame(word = names(uni_gram_vec),freq=uni_gram_vec)
uni_gram_top20 <- uni_gram_df[1:20,]

bi_gram_vec <- sort(rowSums(as.matrix(bi_gram_matrix[bi_gram_corpus,])),decreasing=TRUE)
bi_gram_df <- data.frame(word = names(bi_gram_vec),freq=bi_gram_vec)
bi_gram_top20 <- bi_gram_df[1:20,]

tri_gram_vec <- sort(rowSums(as.matrix(tri_gram_matrix[tri_gram_corpus,])),decreasing=TRUE)
tri_gram_df <- data.frame(word = names(tri_gram_vec),freq=tri_gram_vec)
tri_gram_top20 <- tri_gram_df[1:20,]

# Generate plots and word cloud
# Uni-Gram plots and word cloud
# Plots
ggplot(data = uni_gram_top20, aes(x = word, y = freq)) + 
  geom_bar(stat = "identity", fill = "blue") + 
  ggtitle(paste("Uni-Gram Plot")) + 
  xlab("1-grams") + ylab("Frequency") + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# Word Cloud
wordcloud(uni_gram_top20$word, uni_gram_top20$freq, scale = c(3,1), max.words=20, 
          random.order=FALSE, rot.per=0, fixed.asp = TRUE, use.r.layout = FALSE, 
          colors=brewer.pal(8, "Dark2"))

# Bi-Gram plots and word cloud
# Plots
ggplot(data = bi_gram_top20, aes(x = word, y = freq)) + 
  geom_bar(stat = "identity", fill = "blue") + 
  ggtitle(paste("Bi-Gram Plot")) + 
  xlab("2-grams") + ylab("Frequency") + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# Word Cloud
wordcloud(bi_gram_top20$word, bi_gram_top20$freq, scale = c(3,1), max.words=15, 
          random.order=FALSE, rot.per=0, fixed.asp = TRUE, use.r.layout = FALSE, 
          colors=brewer.pal(8, "Dark2"))

# Tri-Gram plots and word cloud
# Plots
ggplot(data = tri_gram_top20, aes(x = word, y = freq)) + 
  geom_bar(stat = "identity", fill = "blue") + 
  ggtitle(paste("Tri-Gram Plot")) + 
  xlab("3-grams") + ylab("Frequency") + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# Word Cloud
wordcloud(tri_gram_top20$word, tri_gram_top20$freq, scale = c(3,1), max.words=10, 
          random.order=FALSE, rot.per=0, fixed.asp = TRUE, use.r.layout = FALSE, 
          colors=brewer.pal(8, "Dark2"))  

# Building RData for word prediction
# Remove corpus data
rm(corpus, sample_data)

# Reading final Corpus as data.frame
finalCorpusMem <- readRDS("./finalCorpus.RData")

## data frame of finalcorpus
finalCorpus <-data.frame(text=unlist(sapply(finalCorpusMem,`[`, "content")),stringsAsFactors = FALSE)
rm(finalCorpusMem)

# Creating NGrams
## Tokenizer function to get unigrams
unigram <- NGramTokenizer(finalCorpus, Weka_control(min = 1, max = 1,delimiters = " \\r\\n\\t.,;:\"()?!"))
unigram <- data.frame(table(unigram))
unigram <- unigram[order(unigram$Freq,decreasing = TRUE),]
names(unigram) <- c("word1", "freq")
unigram$word1 <- as.character(unigram$word1)

#write.csv(unigram[unigram$freq > 1,],"unigram.csv",row.names=F)
#unigram <- read.csv("unigram.csv",stringsAsFactors = F)
unigram <- unigram[unigram$freq > 1,]
saveRDS(unigram, file = "unigram.RData")

# Tokenizer function to get bigrams
bigram <- NGramTokenizer(finalCorpus, Weka_control(min = 2, max = 2,delimiters = " \\r\\n\\t.,;:\"()?!"))
bigram <- data.frame(table(bigram))
bigram <- bigram[order(bigram$Freq,decreasing = TRUE),]
bigram$words <- as.character(bigram$bigram)
str2 <- strsplit(bigram$words,split=" ")
bigram <- transform(bigram, 
                    one = sapply(str2,"[[",1),   
                    two = sapply(str2,"[[",2))
bigram <- data.frame(word1 = bigram$one,word2 = bigram$two,freq = bigram$Freq,stringsAsFactors=FALSE)
bigram <- bigram[bigram$freq > 1,]
saveRDS(bigram, file = "bigram.RData")

# Tokenizer function to get trigrams
trigram <- NGramTokenizer(finalCorpus, Weka_control(min = 3, max = 3,delimiters = " \\r\\n\\t.,;:\"()?!"))
trigram <- data.frame(table(trigram))
trigram <- trigram[order(trigram$Freq,decreasing = TRUE),]
trigram$words <- as.character(trigram$trigram)
str2 <- strsplit(trigram$words,split=" ")
trigram <- transform(trigram, 
                    one = sapply(str2,"[[",1),   
                    two = sapply(str2,"[[",2),
                    three = sapply(str2,"[[",3))
trigram <- data.frame(word1 = trigram$one,word2 = trigram$two,word3 = trigram$three,
                     freq = trigram$Freq,stringsAsFactors=FALSE)
trigram <- trigram[trigram$freq > 1,]
saveRDS(trigram, file = "trigram.RData")

# Tokenizer function to get quadgrams
quadgram <- NGramTokenizer(finalCorpus, Weka_control(min = 3, max = 3,delimiters = " \\r\\n\\t.,;:\"()?!"))
quadgram <- data.frame(table(quadgram))
quadgram <- quadgram[order(quadgram$Freq,decreasing = TRUE),]
quadgram$words <- as.character(quadgram$quadgram)
str2 <- strsplit(quadgram$words,split=" ")
quadgram <- transform(quadgram, 
                      one = sapply(str2,"[[",1),   
                      two = sapply(str2,"[[",2),
                      three = sapply(str2,"[[",3))
quadgram <- data.frame(word1 = quadgram$one,word2 = quadgram$two,word3 = quadgram$three,
                       freq = quadgram$Freq,stringsAsFactors=FALSE)
quadgram <- quadgram[quadgram$freq > 1,]
saveRDS(quadgram, file = "quadgram.RData")
