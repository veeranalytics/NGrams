#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(markdown)
library(RCurl)
library(curl)
library(rsconnect)


## SHINY UI
shinyUI(
  fluidPage(
    titlePanel("Application to Predict the Next Word using NLP techniques"),
    sidebarLayout(
      sidebarPanel(
        helpText("Enter a word or text or string or a sentence to preview the next word prediction."),
        hr(),
        textInput("inputText", "Enter a word or text or string or a sentence:",value = ""),
        hr(),
        helpText("* After entering the text the next word will be displayed.", 
                 hr(),
                 "** You should enter a text partially to view the predicted next word.",
                 hr(),
                 "*** The predicted next words are shown on the right side."),
        hr(),
        hr()
      ),
      mainPanel(
        h2("A list of predicted next words."),
        verbatimTextOutput("prediction"),
        strong("Word/Test/Sentence entered:"),
        strong(code(textOutput('sentence1'))),
        br(),
        strong("Using N-Grams search to predict the next word:"),
        strong(code(textOutput('sentence2'))),
        hr()
      )
    )
  )
)