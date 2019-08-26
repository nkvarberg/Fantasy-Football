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

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel(h1("Varberg-Lindquist Playoff Predictions", align = 'center')),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(position = 'right',
      sidebarPanel(
         actionButton("preseason", label = "Preseason")
      ),
      
      # Show a plot of the generated distribution
      mainPanel(h3("2019 Predictions", align = 'center'),
          DT::dataTableOutput("preds2019")
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
   
   output$preds2019 <- DT::renderDataTable({
     df <- fread("/Users/nickvarberg/Desktop/Life/Fantasy-Football/VL_predictions_week_5.csv")
     df <- df %>% column_to_rownames(., 'Owner')
     df2 <- datatable(df, options = list(dom = 't'))
     return(df2)
   })
   
   
}

# Run the application 
shinyApp(ui = ui, server = server)

