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
library(ggplot2)

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel(h1("Takes 12 To Tango 2019 Playoff Predictions", align = 'center')),
      
      # Show a plot of the generated distribution
      mainPanel(h3("How these predictions work:", align = 'center'),
                
                h6("I gather preseason point projections for each player from fantasyfootballanlytics.net, who claim
                   to have the most accurate projections. From these player projections, I project the points per game (proj_ppg) for each team
                   in our league. I model each team's score each remaining week as a normal distribution with their
                   proj_ppg as the mean and 30 (arbitrary) as the standard deviation. Then I similate the rest of the
                   season 30,000 times to determine how far each team is likely to go.", align = 'center'),
                
                tabsetPanel(
                  tabPanel("Current Prediction", DT::dataTableOutput("preds2019")), 
                  tabPanel("Prediction History", plotOutput("Historyplot"))
                )
          #,
          #plotOutput("predshistoryplot")
      )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
   
  WEEK = 1
  
   output$preds2019 <- DT::renderDataTable({
     filename = paste0("MV_predictions_week_",toString(WEEK),"_2019.csv")
     df <- fread(filename)
     df <- df %>% select(-ID) %>% 
       rename('Proj. PPG' = proj_ppg) %>%
       mutate('Playoffs' = percent(Playoffs, accuracy=2)) %>% 
       mutate('Semifinals' = percent(Semifinals, accuracy=2)) %>%
       mutate('Finals' = percent(Finals, accuracy=2)) %>%
       mutate('Champion' = percent(Champion, accuracy=2))
     df <- datatable(df, options = list(dom = 't', pageLength = 12, width="100%") )
     return(df)
   })
   
   output$Historyplot <- renderPlot({
     history <- fread("MV_predictions_history_2019.csv")
     history <- history %>% select(Week, Playoffs, Owner) %>% 
       mutate('Playoffs' = percent(Playoffs, accuracy=2)) 
     p <- ggplot(history, aes(x=Week, y=Playoffs, group=Owner) ) + 
       geom_line(aes(color=Owner)) +
       geom_point(aes(color=Owner)) +
       scale_x_continuous(breaks=0:WEEK, labels=waiver())
     return(p)
   })
   
   
}

# Run the application 
shinyApp(ui = ui, server = server)

