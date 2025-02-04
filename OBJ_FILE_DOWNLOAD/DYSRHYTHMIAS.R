install.packages("osfr")  # Install osfr
library(osfr)  # Load the package

# OBJ files can be found here: https://osf.io/kzhys/
  
  
CalHealthMap_DYS <- osf_retrieve_node("kzhys")  

# List all files in the project
files <- osf_ls_files(CalHealthMap_DYS)
print(files)

# Download all files in the project to your own directory
for (i in 1:nrow(files)) {
  file <- osf_retrieve_file(files$id[i])  
  osf_download(file, path = "~/Downloads")  # replace with your own path here
}

