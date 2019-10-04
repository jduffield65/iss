function iss_color_diagnostics(o)
% iss_color_diagnostics(o)
%
% does some diagnostics of signal and noise in each color channel and
% round. Makes a matrix of histograms. In each one, the blue bars are the
% histogram of intensities on spots which should not have fluorescence on
% that color and round. The red bars are the ones that should have
% fluorescence. So the red bars should be to the right of the blue ones.
% Note the same x-axis scale is used for all rounds of one color, but
% differs between colors

nc = size(o.cSpotColors,2);
nr = size(o.cSpotColors,3);

figure(349075); clf; 

nBins = 50;

for c=1:nc
    for r=1:nr

        rc = (r-1)*o.nBP + c;
        subplot(nr,nc,rc);


        ShouldBe1(o.SpotCombi) = (o.UnbledCodes(o.SpotCodeNo(o.SpotCombi),rc)>0);

        cla; hold on
        MaxVal = max(reshape(o.cSpotColors(:,c,:),1,[]));
        histogram(o.cSpotColors(~ShouldBe1,c,r), nBins, 'BinLimits', [0 MaxVal], 'FaceColor', 'b', 'EdgeColor', 'b', 'Normalization', 'probability');
        histogram(o.cSpotColors( ShouldBe1,c,r), nBins, 'BinLimits', [0 MaxVal], 'FaceColor', 'r', 'EdgeColor', 'r', 'Normalization', 'probability');
        
        title(sprintf('Color %d Round %d', c-1, r))
   %     set(gca, 'yscale', 'log')
    end
end