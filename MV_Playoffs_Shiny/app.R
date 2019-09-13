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
#library(ggplot2)
library(plotly)

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
  LEAGUE = 'MV'
  
   output$preds2019 <- DT::renderDataTable({
     filename = paste0(LEAGUE,"_predictions_week_",toString(WEEK),"_2019.csv")
     df <- fread(filename)
     df <- df %>% select(-ID) %>% 
       rename('Proj_PPG' = proj_ppg) %>%
       mutate(Proj_PPG = round(Proj_PPG, 1)) %>%
       mutate('Playoffs' = percent(Playoffs, accuracy=1)) %>% 
       mutate('Semifinals' = percent(Semifinals, accuracy=1)) %>%
       mutate('Finals' = percent(Finals, accuracy=1)) %>%
       mutate('Champion' = percent(Champion, accuracy=1))
     df <- DT::datatable(df, options = list(dom = 't', pageLength = 12, width="100%",scrollX = TRUE, 
                                            paging=FALSE,
                                            fixedHeader=TRUE,
                                            fixedColumns = list(leftColumns = 1, rightColumns = 0)) )
     return(df)
   })
   
  output$Historyplot <- renderPlot({
     history <- fread(paste0(LEAGUE,"_predictions_history_2019.csv"))
     history <- history %>% select(Week, Playoffs, Owner) %>%
       mutate(Playoffs = Playoffs*100)
     # try dynamic legend
     p <- ggplot(history,aes(x=Week, y=Playoffs, group=Owner), show.legend = FALSE) + 
       geom_line(aes(color=Owner)) + 
       geom_point(aes(color=Owner)) +
       theme_minimal() +
       geom_text(hjust = 0, nudge_x = 0.05, aes(label=Owner)) +
       scale_x_continuous(limits = c(0,WEEK+0.5), breaks=0:WEEK, labels=waiver()) +
       scale_y_continuous(name = 'Playoffs %', limits = c(0,100)) +
       theme(legend.position = "none")
     return(p)
  })
  
   
   
}

# Run the application 
shinyApp(ui = ui, server = server)

