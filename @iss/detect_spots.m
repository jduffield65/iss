function [PeakPos, Isolated] = detect_spots(o, Image,t,c,r)
% [PeaksPos, Isolated] = o.DetectSpots(Image,t,c,r)
% 
% find positions of spots corresponding to RNA detections in a b/w image.
% The input SHOULD ALREADY HAVE BEEN TOP-HAT FILTERED (radius 3). If you
% want to smooth the image, do that first, this function won't.
% If you want to run it on generic images run DetectSpotsSingleTime
% works by finding local maxima and keeping only those where the top hat
% filter exceeds a threshold. 
%
% 
% 
% Also finds "isolated spots" for which morphological opening is less than
% a threshold. 
% 
% both thresholds are ABSOLUTE
% 
% Parameters (in iss struct):
%  DetectionThresh: threshold for top-hat filter when detecting a spot (try 0.5 * 98th Prctile)
%  DetectionRadius: radius of top-hat filter when detecting a spot (default 3)
%  IsolationThresh: threshold for morphological opening when determining if
%    a spot is isolated (try 0.05 * 98th prctile)
%  IsolationRadius: size of opening filter (default 5)
%
% For now only works on 2d but should be extendable
%
% outputs:
% PeakPos is n by 2 array of coordinates (will be y first if plotting)
% Isolation is binary array saying which are isolated
% 
% Kenneth D. Harris, 29/3/17
% GPL 3.0 https://www.gnu.org/licenses/gpl-3.0.en.html

% if strcmp(o.DetectionThresh, 'auto')
%     DetectionThresh = o.AutoThreshMultiplier*prctile(Image(:),o.AutoThreshPercentile);
% elseif strcmp(o.DetectionThresh, 'multithresh')
%     ImNot0 = double(Image(Image>0));
%     Outliers = Image>(median(ImNot0)+ 7*mad(ImNot0));
%     DetectionThresh = multithresh(Image(~Outliers));
% elseif strcmp(o.DetectionThresh, 'medianx10')
%     DetectionThresh = median(Image(:))*10;
% else
%     DetectionThresh = o.DetectionThresh;
% end
if strcmpi(o.DetectionThresh, 'auto')
    DetectionThresh = o.AutoThresh(t,c,r);
else
    DetectionThresh = o.DetectionThresh;
end

%% find peaks and lower threshold if there aren't enough

% first do morphological filtering
se1 = strel3D_2(o.DetectionRadius(1),o.DetectionRadius(2));         %SE has o.DetectionRadius length in z pixels
%se1 = o.strel3D(ceil(2*o.Zpixelsize/o.XYpixelsize));

Dilate = imdilate(Image, se1);

% local maxima are where image=dilation
Small = 1e-6; % just a small number, for computing local maxima: shouldn't matter what it is

%Iterate threshold until more than o.minPeaks peaks  (COULD DO THIS BUT WITH LOW
%VARIANCE IN THE IMAGE INSTEAD) NOT SURE ABOUT THIS STEP. USUALLY TURN OFF
%BY SETTING o.minPeaks = 1
nPeaks = 0;
i = 0;
while nPeaks < o.minPeaks              
    if i > 0
        DetectionThresh = DetectionThresh - o.ThreshParam;          
    end
    if DetectionThresh <= o.MinThresh
        %MAYBE MAKE MINTHRESH THE MEAN OF THE IMAGE OR SOMETHING - UNIQUE
        %TO EACH TILE
        DetectionThresh = o.MinThresh;
        MaxPixels = find(Image + Small >= Dilate & Image>DetectionThresh);
        break 
    end
    MaxPixels = find(Image + Small >= Dilate & Image>DetectionThresh);
    nPeaks = size(MaxPixels,1);
    i = i+1;
end

[yPeak, xPeak, zPeak] = ind2sub(size(Image), MaxPixels);
PeakPos = [yPeak, xPeak, zPeak];

%% Isolation Thresholding

if isstr(o.IsolationThresh) && ismember(o.IsolationThresh, {'auto', 'multithresh', 'medianx10'})
    IsolationThresh = -DetectionThresh/5;
else
    IsolationThresh = o.IsolationThresh;
end



%% now find isolated peaks by annular filtering
if nargout==1
    if o.Graphics==2
        plotSpotsLocal(PeakPos,Image,o.nZ,o.TileSz,'Detected Spots');
    end

    return;
end
% first make annular filter
%zIsolationRadius2 = floor(o.IsolationRadius2*o.XYpixelsize/o.Zpixelsize);       %Zpixelsize is different
[xr, yr, zr] = meshgrid(-o.IsolationRadius2(1):o.IsolationRadius2(1),-o.IsolationRadius2(1):o.IsolationRadius2(1),...
    -o.IsolationRadius2(2):o.IsolationRadius2(2));
Annulus = (xr.^2 + yr.^2+(o.Zpixelsize*zr/o.XYpixelsize).^2)<=o.IsolationRadius2(1).^2 &...
    (xr.^2 + yr.^2+(o.Zpixelsize*zr/o.XYpixelsize).^2) > o.IsolationRadius1.^2;

% filter the image with it
AnnularFiltered = imfilter(Image, double(Annulus)/sum(Annulus(:)));

% now threshold
%ScaledIsolationThresh = Range * [1-o.IsolationThresh; o.IsolationThresh];
Isolated = (AnnularFiltered(MaxPixels) < IsolationThresh);

if o.Graphics==2
    plotSpotsLocal_Isolated(PeakPos,Image,o.nZ,o.TileSz,Isolated,'Isolated and Not Isolated Spots');
end

return

% plot(xPeakBest, yPeakBest, 'wx');