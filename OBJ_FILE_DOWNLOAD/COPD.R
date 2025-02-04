install.packages("osfr")  # Install osfr
library(osfr)  # Load the package

# OBJ files can be found here: https://osf.io/gv94n/
  
  
CalHealthMap_COPD <- osf_retrieve_node("gv94n")  

# List all files in the project
files <- osf_ls_files(CalHealthMap_COPD)
print(files)

# Download all files in the project to your own directory
for (i in 1:nrow(files)) {
  file <- osf_retrieve_file(files$id[i])  
  osf_download(file, path = "~/Downloads")  # replace with your own path here
}

