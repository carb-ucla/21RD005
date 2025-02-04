install.packages("osfr")  # Install osfr
library(osfr)  # Load the package

# OBJ files can be found here: https://osf.io/9mw4j/
  
  
CalHealthMap_RESP <- osf_retrieve_node("9mw4j")  

# List all files in the project
files <- osf_ls_files(CalHealthMap_RESP)
print(files)

# Download all files in the project to your own directory
for (i in 1:nrow(files)) {
  file <- osf_retrieve_file(files$id[i])  
  osf_download(file, path = "~/Downloads")  # replace with your own path here
}

