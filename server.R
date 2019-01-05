#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

# Load Libraies 
library(shiny)
library(stringr)
library(tm)
library(RCurl)
library(curl)
library(rsconnect)

# Loading bigram, trigram and quadgram frequencies words matrix frequencies
bigram <- readRDS("bigram.RData")
trigram <- readRDS("trigram.RData")
quadgram <- readRDS("quadgram.RData")

names(bigram)[names(bigram) == 'word1'] <- 'w1'
names(bigram)[names(bigram) == 'word2'] <- 'w2'
names(trigram)[names(trigram) == 'word1'] <- 'w1'
names(trigram)[names(trigram) == 'word2'] <- 'w2'
names(trigram)[names(trigram) == 'word3'] <- 'w3'
names(quadgram)[names(quadgram) == 'word1'] <- 'w1' 
names(quadgram)[names(quadgram) == 'word2'] <- 'w2' 
names(quadgram)[names(quadgram) == 'word3'] <- 'w3'
names(quadgram)[names(quadgram) == 'word4'] <- 'w4'
message <- ""

## Function to predict the next word
predictWord <- function(the_word) {
  word_add <- stripWhitespace(removeNumbers(removePunctuation(tolower(the_word),preserve_intra_word_dashes = TRUE)))
  the_word <- strsplit(word_add, " ")[[1]]
  n <- length(the_word)
  
# Check bigram
  if (n == 1) {the_word <- as.character(tail(the_word,1)); functionBigram(the_word)}
  
# Check trigram
  else if (n == 2) {the_word <- as.character(tail(the_word,2)); functionTrigram(the_word)}
  
# Check quadgram
  else if (n >= 3) {the_word <- as.character(tail(the_word,3)); functionQuadgram(the_word)}
}

# Function for bigram
functionBigram <- function(the_word) {
  if (identical(character(0),as.character(head(bigram[bigram$w1 == the_word[1], 2], 1)))) {
    message<<-"If no word found then the most used pronoun 'it' in English will be returned" 
    as.character(head("it",1))
  }
  else {
    message <<- "Trying to predict the word using Bigram Freqeuncy Matrix  "
    as.character(head(bigram[bigram$w1 == the_word[1],2], 1))
  }
}

# Function for trigram
functionTrigram <- function(the_word) {
  if (identical(character(0),as.character(head(trigram[trigram$w1 == the_word[1]
                                                       & trigram$w2 == the_word[2], 3], 1)))) {
    as.character(predictWord(the_word[2]))
  }
  else {
    message<<- "Trying to predict the pord using Trigram Frequency Matrix "
    as.character(head(trigram[trigram$w1 == the_word[1]
                              & trigram$w2 == the_word[2], 3], 1))
  }
}

# Function for quadgram
functionQuadgram <- function(the_word) {
  if (identical(character(0),as.character(head(quadgram[quadgram$w1 == the_word[1]
                                                        & quadgram$w2 == the_word[2]
                                                        & quadgram$w3 == the_word[3], 4], 1)))) {
    
    as.character(predictWord(paste(the_word[2],the_word[3],sep=" ")))
  }
  else {
    message <<- "Trying to predict the word using Quadgram Frequency Matrix"
    as.character(head(quadgram[quadgram$w1 == the_word[1] 
                               & quadgram$w2 == the_word[2]
                               & quadgram$w3 == the_word[3], 4], 1))
    
  }       
}


# ShineServer code to call the function predictWord
shinyServer(function(input, output) {
  output$prediction <- renderPrint({
    result <- predictWord(input$inputText)
    output$sentence2 <- renderText({message})
    result
  });
  output$sentence1 <- renderText({
    input$inputText});
}
)