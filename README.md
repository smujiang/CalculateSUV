## CalculateSUV
This repo demonstrates the calculation of standard uptake value (SUV) from PET images.
You will need DICOM images to run this code, as the code will use some related patient profiles saved in the DICOM header, such as body weight.

It is recommended to compare the SUV calculated using this tool with the SUV calculated on the radiologists' workstation, as different PET machines could save patient profiles into different DICOM domains. 


The code is written in Matlab script, which provides extra convenience for customizing computational analysis. Basically, SUV values are linear transformation of pixel values within PET images.
Please refer to the ./reference folder to know how this code works.
