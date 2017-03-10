%% This function caculate body weight SUV for PET image volumes
% SUV=CalculateSUV(Img,info)
% Img:  PET image 
% info: DICOM infomation from PET DICOM file.
% SUV: SUV image 
% PS: There are three kind of: bw,lbm or bsa.
%       Define the SUV calculation method: 
%       body weight (bw), lean body mass (lbm) or body surface area (bsa);
%  this function only calculate bw
% -----------------------------
% Example: 
% info=dicominfo('P1.dcm'); %Read a PET image sample.
% img=dicomread('P1.dcm');
% SUV=CalculateSUV(img,info);
% newnii=make_nii(SUV); % pixel size and other optional parameters
% save_nii(newnii,'SUV.img');
% -----------------------------
% Author: Jun Jiang   
% Organization: Southern Medical University,Guangzhou,China
% E-mail: smujiang@gmail.com
% Reference URL:
% http://www.clearcanvas.ca/dnn/Portals/0/ClearCanvasFiles/Documentation/UsersGuide/Personal/7_1_SP1/
%%
function SUV=CalculateSUV(Img,info)
%Method:  SUVbw, SUVlbm or SUVbsa
% Method='SUVbw';
Corinfo=info.(dicomlookup('0028', '0051'));
if isempty(Corinfo)
    Disp('Corrected Image (0x0028,0x0051) should contains ATTN and DECAY and Decay Correction (0x0054,0x1102) must be START');
    return ;
end
if  ~strfind(info.(dicomlookup('0054', '1102')),'START')  %Decay Correction (0x0054,0x1102) is START
    Disp('Decay Correction (0x0054,0x1102) must be START');
    return;
end
if  ~strfind(Corinfo,'ATTN')&&strfind(Corinfo,'DECAY')   %if Corrected Image
    Disp('Corrected Image (0x0028,0x0051) should contains ATTN and DECAY');
    return;
end
%%%%%%%%%%%%%
Corinfo=info.(dicomlookup('0054', '1001'));
if strfind(Corinfo,'BQML') %if Units (0x0054,0x1001) are BQML
    
    %half life = Radionuclide Half Life (0x0018,0x1075) in Radiopharmaceutical Information Sequence (0x0054,0x0016)
    T_half=109.8*60; %half life of FDG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    AcquisitionDateandTime=strcat(info.AcquisitionDate,info.AcquisitionTime);
    SeriesDateandTime=strcat(info.SeriesDate,info.SeriesTime);
    
    if  str2double(SeriesDateandTime)<=str2double(AcquisitionDateandTime) %if Series Date (0x0008,0x0021) and Time (0x0008,0x0031) are not after Acquisition Date (0x0008,0x0022) and Time (0x0008,0x0032)        
        ScanDateandTime=SeriesDateandTime;%scan Date and Time = Series Date and Time
    else %// may be post-processed series in which Series Date and Time are date of series creation unrelated to acquisition
        if  strcmp(info.Private_0009_10xx_Creator,'GEMS_PETD_01')%if  GE private scan Date and Time (0x0009,0x100d,¡°GEMS_PETD_01¡±) present {
            ScanDateandTime=info.(dicomlookup('0009','100d'));%scan Date and Time = GE private scan Date and Time (0x0009,0x100d,¡°GEMS_PETD_01¡±)        
        else 
                % // else may be Siemens series with altered Series Date and Time
                % // either check earliest of all images in series (for all bed positions) (wrong for case of PETsyngo 3.x multi-injection)
                % scan Date and Time = earliest Acquisition Date (0x0008,0x0022) and Time (0x0008,0x0032)  in all images of series
                % or
                % // back compute from center (average count rate ) of time window for bed position (frame) in series (reliable in all cases)
                % // Acquisition Date (0x0008,0x0022) and Time (0x0008,0x0032) are the start of the bed position (frame)
                % // Frame Reference Time (0x0054,0x1300) is the offset (ms) from the scan Date and Time we want to the average count rate time
                % if  (Frame Reference Time (0x0054,0x1300) > 0 && Actual Frame Duration (0018,1242) > 0) {
                % frame duration = Actual Frame Duration (0018,1242) / 1000		// DICOM is in ms; want seconds
                % decay constant = ln(2) /  half life
                % decay during frame = decay constant * frame duration
                % average count rate time within frame = 1/decay constant * ln(decay during frame / (1 ¨C exp(-decay during frame)))
                % scan Date and Time = Acquisition Date (0x0008,0x0022) and Time (0x0008,0x0032)
                % -	Frame Reference Time (0x0054,0x1300) /1000 + average count rate time within frame
                % 
        end
    end
%     scanTime=info.SeriesTime;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %start Time = Radiopharmaceutical Start Time (0x0018,0x1072) in Radiopharmaceutical Information Sequence (0x0054,0x0016) 
    startTime = info.RadiopharmaceuticalInformationSequence.Item_1.RadiopharmaceuticalStartTime;
    StartDateandTime=strcat(info.SeriesDate,startTime);
    decayTime= TimeSub(StartDateandTime,ScanDateandTime);%decay Time = scan Time ¨C start Time 	// seconds
    %injected Dose = Radionuclide Total Dose (0x0018,0x1074) in Radiopharmaceutical Information Sequence (0x0054,0x0016)	// Bq
    injectedDose=info.RadiopharmaceuticalInformationSequence.Item_1.RadionuclideTotalDose;   
    decayedDose = injectedDose*exp(-(decayTime)*log(2)/T_half);     %injectedDose * pow (2, -decayTime / T_half);
    weight=info.(dicomlookup('0010','1030'));
    SUVbwScaleFactor = (weight * 1000 / decayedDose);
elseif strfind(Corinfo,'CNTS') %if Units (0x0054,0x1001) are CNTS
    %Philips private scale factor (0x7053,0x1000,¡° Philips PET Private Group¡±)
%if (0x7053,0x1000) not present, but (0x7053,0x1009) is present, then (0x7053,0x1009) * Rescale Slope
% scales pixels to Bq/ml, and proceed as if Units are BQML
    if isempty(info.(dicomlookup('7053','1000')))
        RescaleSlope=info.RescaleSlope; %Rescale Slope (0x0028,0x1053)
        SUVbwScaleFactor=info.(dicomlookup('7053','1009'))*RescaleSlope;
    else
        SUVbwScaleFactor = info.(dicomlookup('7053','1000'));
    end
elseif  strfind(Corinfo,'GML')  %if Units (0x0054,0x1001) are GML    
    SUVbwScaleFactor = 1.0;	%assumes that GML indicates SUVbw instead of SUVlbm
end
RescaleIntercept=info.(dicomlookup('0028','1052'));
RescaleSlope= info.(dicomlookup('0028','1053'));
SUV=(double(Img)+RescaleIntercept )* RescaleSlope*SUVbwScaleFactor;
%(stored pixel value in Pixel Data (0x7FE0,0x0010) + Rescale Intercept (0x0028,0x1052))* Rescale Slope (0x0028,0x1053) * SUVbwScaleFactor

%sub two date and time, return the result in seconds
%20090306154346.00
% function S=TimeSub(Time1,Time2)
function S=TimeSub(Time1,Time2)
Year1=str2double(Time1(1:4));
Mon1=str2double(Time1(5:6));
Date1=str2double(Time1(7:8));
Hour1=str2double(Time1(9:10));
Min1=str2double(Time1(11:12));
Sec1=str2double(Time1(13:14));
%%%%%%%%%%%
Year2=str2double(Time2(1:4));
Mon2=str2double(Time2(5:6));
Date2=str2double(Time2(7:8));
Hour2=str2double(Time2(9:10));
Min2=str2double(Time2(11:12));
Sec2=str2double(Time2(13:14));
T1=datenum(Year1,Mon1,Date1,Hour1,Min1,Sec1);
T2=datenum(Year2,Mon2,Date2,Hour2,Min2,Sec2);
S=hour(T2-T1)*3600+minute(T2-T1)*60+second(T2-T1);

% S=(Year1-Year2)*0 +(Mon1-Mon2)*0 +(Date1-Date2)* +(Hour1-Hour2)* +(Min1-Min2)* +















