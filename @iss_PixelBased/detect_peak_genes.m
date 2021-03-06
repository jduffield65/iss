function [PeakLocalYX,PeakSpotColors,PeakLogProbOverBackground,...
    Peak2ndBestLogProb,PeakScoreDev,OriginalTile,PeakBestGene] = ...
    detect_peak_genes(o,LookupTable,GoodSpotColors,GoodLocalYX,t)
%% [PeakLocalYX,PeakSpotColors,PeakLogProbOverBackground,...
%    Peak2ndBestLogProb,PeakScoreDev,OriginalTile] = ...
%    detect_peak_genes(o,LookupTable,GoodSpotColors,GoodLocalYX,t)
%
% This finds the local maxima in log probability for each gene
% 
% Input
% o: iss object
% LookupTable(s,G,b,r) is the Log probability for spot intensity s-o.ZeroIndex+1 for gene
% G in channel b, round r.
% GoodSpotColors(S,b,r) is the intensity for spot S in channel b, round r.
% S should cover all pixel values that don't go off edge of tile in any b,r.
% GoodLocalYX(S,:) is the corresponding pixel location.
% t is the current tile of interest
%
% Output
% PeakLocalYX{G} contains the YX position of local maxima of gene G.
% PeakSpotColors{G} contains the corresponding spot colors.
% PeakLogProbOverBackground{G} contains the corresponding 
% Log Probability relative to the background.
% Peak2ndBestLogProb{G} contains the log probability relative to the
% background for the second best match at that location.
% PeakScoreDev{G} is the standard deviation of log probability across all
% genes at that location.
% OriginalTile{G} = t
% PeakBestGene{G} contains the best gene at the location of local maxima of
% gene G. I.e. most will be G but few will be overlapping. 

%% Get log probs for each spot 
AllLogProbOverBackground = o.get_LogProbOverBackground(GoodSpotColors,LookupTable);

%% For each gene, find peaks in probability images. Keep these as spots going forward
nCodes = length(o.CharCodes);
PeakSpotColors = cell(nCodes,1);
PeakLocalYX = cell(nCodes,1);
PeakLogProbOverBackground = cell(nCodes,1);
Peak2ndBestLogProb = cell(nCodes,1);
PeakScoreDev = cell(nCodes,1);
OriginalTile = cell(nCodes,1);
PeakBestGene = cell(nCodes,1);

GeneIm = zeros(max(GoodLocalYX));     %Y index is first in zeros
Ind = sub2ind(size(GeneIm),GoodLocalYX(:,1),GoodLocalYX(:,2));

fprintf('Finding peaks for gene     ');
for GeneNo = 1:nCodes    
    g_num = sprintf('%.6f', GeneNo);
    fprintf('\b\b\b\b%s',g_num(1:4));
    
    %Find local maxima in gene image
    GeneIm(Ind) = AllLogProbOverBackground(:,GeneNo); 
    Small = 1e-6;
    se1 = strel('disk', o.PixelDetectRadius);     %Needs to be bigger than in detect_spots
    Dilate = imdilate(GeneIm, se1);
    MaxPixels = find(GeneIm + Small >= Dilate);
    
    %Get Indices of Good Global Spot Colors / YX
    PeakInd = find(ismember(Ind,MaxPixels));        %As position in Ind = LogProbOverBackGround Index = Good Index
    nPeaks = length(PeakInd);
    %Save information for that gene
    PeakSpotColors{GeneNo} = GoodSpotColors(PeakInd,:,:);
    PeakLocalYX{GeneNo} = GoodLocalYX(PeakInd,:);
    peakPoverB = AllLogProbOverBackground(PeakInd,:);
    PeakLogProbOverBackground{GeneNo} = peakPoverB(:,GeneNo);    
    PeakScoreDev{GeneNo} = std(peakPoverB,[],2);
    
    %Find 2nd best gene so can give score relative to it
    [~,PeakBestGene{GeneNo}] = max(peakPoverB,[],2);
    peakPoverB(sub2ind(size(peakPoverB),(1:nPeaks)',PeakBestGene{GeneNo}))=-inf;
    Peak2ndBestLogProb{GeneNo} = max(peakPoverB,[],2);
    %SortProb = sort(peakPoverB,2,'descend');
    %Peak2ndBestLogProb{GeneNo} = SortProb(PeakInd,2);
    
    
    OriginalTile{GeneNo} = ones(nPeaks,1)*t;
end
fprintf('\n');
end

