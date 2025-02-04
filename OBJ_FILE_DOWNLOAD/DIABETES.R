install.packages("osfr")  # Install osfr
library(osfr)  # Load the package

# OBJ files can be found here: https://osf.io/2cdwa/
  
  
CalHealthMap_DIABETES <- osf_retrieve_node("2cdwa")  

# List all files in the project
files <- osf_ls_files(CalHealthMap_DIABETES)
print(files)

# Download all files in the project to your own directory
for (i in 1:nrow(files)) {
  file <- osf_retrieve_file(files$id[i])  
  osf_download(file, path = "~/Downloads")  # replace with your own path here
}

