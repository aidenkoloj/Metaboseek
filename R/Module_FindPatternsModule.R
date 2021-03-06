#' FindPatternModule
#' 
#' Module for loading an entire Metaboseek session
#' 
#' @inherit MseekModules
#' 
#' @return nothing, but modifies values
#' 
#' @param useActionLink if TRUE, will use an \code{actionLink} instead 
#' of an \code{actionButton} to open the modal Dialog
#'  
#' @describeIn FindPatternsModule server logic
#' 
#' @export 
FindPatternsModule <- function(input,output, session, values,
                            useActionLink = F
){
    ns <- NS(session$ns(NULL))
    
    internalValues  <- reactiveValues(df = NULL,
                                      filename = NULL,
                                      patternTable = data.frame(active = FALSE,
                                                                name = "Phosphate",
                                                                pattern = "78.95905",
                                                                stringsAsFactors = FALSE
                                                                )
                                      )
    
    patternTab <- callModule(simpleTableModule,'patterntab', 
                              df = reactive({internalValues$patternTable}),
                              static = list(readOnly = F,
                                            contextMenu = T,
                                            height = "auto")
    )
    
    callModule(SaveTableModule, "savevariable",
               reactives = reactive({list(df = patternTab$liveView,
                                          filename = file.path("patternTables",
                                                               paste0("variableModifications.tsv")))}),
               values = reactiveValues(projectData = values$projectData),
               static = list(tooltip = "Save pattern table",
                             label = "Save",
                             format = c("tsv"))
    )
    
    TableLoader <- callModule(LoadTableModule, "loadvariable",
                              values = reactiveValues(projectData = values$projectData,
                                                      featureTables = NULL),
                              static = list(tooltip = "Load pattern table",
                                            label = "Load",
                                            format = list(header = T,
                                                          sep = "\t",
                                                          quote = '"',
                                                          stringsAsFactors = F),
                                            pattern = "\\.tsv$")
    )
    
    
    
    
    observeEvent(TableLoader$df,{
        
        if(!is.null(TableLoader$df)){
            
            fixme <- TableLoader$df
            
            #making sure no problems arise from empty columns(which would be loaded as logical)
            fixme$active <- as.logical(fixme$active)
            
            fixme$name <- as.character(fixme$name)
            fixme$pattern <- as.character(fixme$pattern)
            
            
            internalValues$patternTable <- fixme
        }
    })
    
    observeEvent(c(patternTab$liveView),{
        tryCatch({
            
            prevariable <- patternTab$liveView[(!is.na(patternTab$liveView$active)
                                                 & !is.na(patternTab$liveView$name)
                                                 & !is.na(patternTab$liveView$pattern)),]
            
            
            values$GlobalOpts$patternTable <- prevariable[prevariable$active,]
            
            
            
        }, error = function(e){warning(e)})
        
    }, ignoreNULL = T)
    
    
    dialog <- callModule(ModalWidget, "openModal",
                         reactives = reactive({  
                             list(fp = fluidPage(
                                 
                                 fluidRow(
                                     p("Find patterns in MS2 spectra")
                                 ),
                                 fluidRow(
                                     
                                     box(width = 12,
                                              div(class = "centerContainer", h4("Search Patterns")),
                                              fluidRow(
                                                  div(class = "centerContainer",
                                                      LoadTableModuleUI(ns("loadvariable")),
                                                      SaveTableModuleUI(ns("savevariable"))
                                                  )
                                              ),
                                              fluidRow(
                                                  div(class = "centerContainer",
                                                      simpleTableModuleUI(ns("patterntab"))))
                                 )
                                     ),
                                 fluidRow(
                                     column(2, div(title = "Define m/z tolerance for MS2 fragment peak and pattern matching. Peaks will be matched if they are within m/z tolerance AND/OR ppm tolerance!",
                                                   numericInput(ns("mzdiff"),"m/z tolerance", value = 0.002))),
                                     column(2, div(title = "Define m/z tolerance for MS2 fragment peak and pattern matching in ppm. Peaks will be matched if they are within m/z tolerance AND/OR ppm tolerance!",
                                                   numericInput(ns("ppmdiff"),"ppm tolerance", value = 5))),
                                     column(3, div( title = "Remove noise (peaks below this reltaive intensity in a merged MS2 spectrum will be ignored)", 
                                                    numericInput(ns("noise"), "Noise level in %", value = 2)))
                                     ),
                                 fluidRow(
                                     actionButton(ns("findpattern"),"Find Patterns")
                                     )
                                 ))}),
                         static = list(tooltip = "Find patterns in MS2 spectra",
                                       title = "Find patterns in MS2 spectra", 
                                       label = "MS2 patterns",
                                       icon = icon("braille", lib = "font-awesome")),
                         useActionLink = useActionLink)
    
    
    
    observeEvent(input$findpattern,{
        tryCatch({
            withProgress(message = 'Please wait!', detail = "Finding Patterns", value = 0, {
              
                updateFT(values)

                incProgress(0.1, detail = "Extracting MS2 scans")
                
                AllSpecLists <- lapply(makeScanlist2(FeatureTable(values)$df$MS2scans),
                                       getAllScans, values$MSData$data,
                                       removeNoise = NULL)#input$noise*0.01)
                
                
                incProgress(0.2, detail = "Merging MS2 scans for each feature in Feature Table")
                
                
                MergedSpecs <- lapply(AllSpecLists, mergeMS, ppm = input$ppmdiff, mzdiff = 0, noiselevel = input$noise*0.01)
                
                incProgress(0.5, detail = "Finding Patterns")
                
                prevariable <- patternTab$liveView[(!is.na(patternTab$liveView$active)
                                                    & !is.na(patternTab$liveView$name)
                                                    & !is.na(patternTab$liveView$pattern)),]
                
                
                values$GlobalOpts$patternTable <- prevariable[prevariable$active,]
                
                matchedPatterns <- data.frame(matched_patterns = matchedToCharacter(findPatterns(MergedSpecs,
                                                parsePatterns(values$GlobalOpts$patternTable),
                                         ppm = input$ppmdiff,
                                         mzdiff = input$mzdiff)), 
                                       stringsAsFactors = FALSE)
                
                FeatureTable(values) <- updateFeatureTable(FeatureTable(values),matchedPatterns)
                
                
            })
            
            removeModal()
            showNotification(paste("Pattern finding completed!"), duration = 0, type = "message")
            
        }
        ,
        error = function(e){
            
            showNotification(paste("An error occured: ", e), duration = 0, type = "error")
            
            
        })
        
    })
    
    
}

#' @describeIn FindPatternsModule UI elements
#' @export
FindPatternsModuleUI <- function(id)
{
    ns <- NS(id)
    
    ModalWidgetUI(ns("openModal"))
    
}