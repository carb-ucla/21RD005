install.packages("osfr")  # Install osfr
library(osfr)  # Load the package

# Shapefiles can be found here: https://osf.io/qfxhs/
  
  
CalHealthMap <- osf_retrieve_node("qfxhs")  

# List all files in the project
files <- osf_ls_files(CalHealthMap)
print(files)

# Download all files in the project to your own directory
for (i in 1:nrow(files)) {
  file <- osf_retrieve_file(files$id[i])  
  osf_download(file, path = "~/You_Path_Name_Here")  # replace with your own path here
}

