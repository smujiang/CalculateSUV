### CalculateSUV
This repo provide a demostration of calculating standard uptake value (SUV) from PET images. 
The code is written in Matlab script, which provides extra convenience for customizing computational analysis.

You will need DICOM images to run this code, as the code will use some related patient profiles saved in the DICOM header, such as body weight.
It is recommended to compare the SUV calcualted using this tool with the SUV calculated on the radiologists' workstation, as different PET machines could save patient profiles into different DICOM domains. 

Please refer to the ./reference folder to know how this code works. Trust me, it's boring, just linear transformation of pixel values of PET images.


