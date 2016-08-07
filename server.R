library(shiny)
library(ggplot2)


data <- read.table("o-ring-erosion-or-blowby.data",
                   col.names=c("orings","at_risk","temp","leak_test_P","test_no"))

modelFit <- function(){
        training <- subset(data, !(temp > 70 & at_risk > 1)) # Remove clear outlier
        # Linear model predicting number of at-risk O-rings using ambient temperature
        mod <- lm(at_risk ~ temp, data=training)
        return(mod)
}

model <- modelFit()

# Prediction function
predict_at_risk_orings <- function(temp){
        new <- data.frame(temp=temp)
        if(temp >= 75)
                prediction <- 0
        else
                prediction <- predict(model, new)
        return(prediction)
}

plot_temp_oring_risk <- function(){
        g <- ggplot(data, aes(temp, at_risk))
        g <- g + geom_abline(intercept = model$coefficients[1], slope = model$coefficients[2], size = 0.5)
        g <- g + geom_vline(xintercept=36, color='blue')
        g <- g + geom_point(aes(size=6, alpha=0.7))
        g <- g + theme(legend.position="none")
        g <- g + labs(x = "Ambient Temperature (degrees Fahrenheit) at Launch")
        g <- g + labs(y = "Number of O-rings At Risk of Thermal Damage")
        g <- g + annotate("text", x = 44, y = 0.5, label="Challenger Launch, 1986",color="blue")
        g <- g + annotate("text", x = 75, y = 1.9, label="Assumed Outlier")
        g <- g + annotate("text", x = 74, y = 0.4, label="Linear Model")
        g <- g + xlim(25,85)
        g <- g + ylim(0,3)
        return(g)
}

shinyServer(
        function(input, output){
                predict <- reactive({predict_at_risk_orings(input$`temp`)})
                 
                launch <- reactive({
                        if(predict() < 1)
                                return("Yes")
                        else
                                return("No")
                })
                
                output$temp <- renderPrint(input$`temp`)
                output$prediction <- renderPrint(predict())
                output$launch <- renderPrint(launch())
                output$newPlot <- renderPlot({g <- plot_temp_oring_risk()
                        g <- g + geom_vline(xintercept = input$'temp', color='red')
                        g <- g + annotate("text", x = input$temp + 5, y = 2.5, label="Launch Temp",color="red")
                        print(g)
                        
                })
        }
)
