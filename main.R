# main.R - Flexible pipeline for PredictR

# Load utilities and modules
source("src/utils.R")
source("src/preprocessing.R")
source("src/training.R")
source("src/evaluation.R")
source("src/persistence.R")

#' Run the PredictR pipeline
#' @param data_source Path to the data file or the data object itself
#' @param config List containing configuration (target variable, algorithm, hyperparameters, etc.)
#' @param custom_metrics Function for custom model evaluation
run_predictr_pipeline <- function(data_source, config = list(), custom_metrics = NULL) {
  
  tryCatch({
    message("--- Initializing PredictR Pipeline ---")
    
    # 1. Data preprocessing (imputation, cleaning, splitting)
    raw_data <- if(is.character(data_source)) read.csv(data_source) else data_source
    data_list <- preprocess_data(raw_data, config$target, method = config$imputation_method)
    
    # 2. Model training with dynamic algorithm selection
    message(paste("Selected Algorithm:", config$algorithm))
    model <- train_model(
      data = data_list$train, 
      target = config$target, 
      method = config$algorithm,
      params = config$hyperparameters
    )
    
    # 3. Model evaluation
    # Use default metrics if custom_metrics is not provided
    results <- evaluate_model(model, data_list$test, config$target, metric_fn = custom_metrics)
    
    # 4. Model persistence with metadata
    model_meta <- list(
      model = model,
      config = config,
      metrics = results,
      timestamp = Sys.time()
    )
    
    # Save the model object and metadata to the models/ directory
    save_model(model_meta, paste0("models/model_", format(Sys.time(), "%Y%m%d_%H%M"), ".rds"))
    
    message("--- Pipeline Finished Successfully ---")
    return(model_meta)
    
  }, error = function(e) {
    message(paste("CRITICAL ERROR in pipeline:", e$message))
    return(NULL)
  })
}

# --- Example usage ---
# config <- list(
#   target = "target_variable",
#   algorithm = "randomForest", 
#   imputation_method = "knn",
#   hyperparameters = list(ntree = 500, mtry = 3)
# )
# model_final <- run_predictr_pipeline("data/raw_data.csv", config)
