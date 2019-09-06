#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(DT)
library(data.table)
library(tibble)
library(scales)
library(dplyr)

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel(h1("Takes 12 To Tango 2019 Playoff Predictions", align = 'center')),
      
      # Show a plot of the generated distribution
      mainPanel(h3("How these predictions work:", align = 'center'),
                h6("I gather preseason point projections for each player from fantasyfootballanlytics.net, who claim
                   to have the most accurate projections. From these player projections, I project the points per game (proj_ppg) for each team
                   in our league. I model each team's score each remaining week as a normal distribution with their
                   proj_ppg as the mean and 25 (arbitrary) as the standard deviation. Then I similate the rest of the
                   season 30,000 times to determine how far each team is likely to go.", align = 'center'),
          DT::dataTableOutput("preds2019")#,
          #plotOutput("predshistoryplot")
      )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
   
   output$preds2019 <- DT::renderDataTable({
     df <- fread("MV_predictions_week_0.csv")
     df <- df %>% select(-ID)
     df <- datatable(df, options = list(dom = 't', pageLength = 12, width="100%"
                                        )
                     )
     return(df)
   })
   
   #output$predshistoryplot <- renderPlot({
  #   week4 <- fread("/Users/nickvarberg/Desktop/Life/Fantasy-Football/VL_predictions_week_4.csv")
  #   week5 <- fread("/Users/nickvarberg/Desktop/Life/Fantasy-Football/VL_predictions_week_5.csv")
  #   week4 <- week4 %>% column_to_rownames(., 'Owner')
  #   df2 <- datatable(df, options = list(dom = 't'))
  #   return(df2)
  # })
   
   
}

# Run the application 
shinyApp(ui = ui, server = server)

