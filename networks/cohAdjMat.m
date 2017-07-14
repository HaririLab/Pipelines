function cohAdjMat(roiTS,outDir)
addpath(genpath('/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/Pipelines/ThirdParty/wc'));
fmDat=load(roiTS);
[a b]=size(fmDat);
which modwt
%first perform wavlet decomposition of each time series, TR=2 seconds
wav2decom = zeros(a,b);
for i=1:b
    wavDec=modwt(fmDat(:,i),'LA8','conservative','circular');
    wav2decom(:,i)=wavDec(2,:); % wavelet 2 for node i
end
%create coherence adjacency matrix
cap=a-14;%upper limit of lower window edge, change if you want a shorter or longer sliding window
adjMat = zeros(b,b,cap);
for low=1:cap
    high=low+14; %high edge of window
    winTS=wav2decom(low:high,:);
    out=['generating adjMat for window frame of TRs ',num2str(low),'..',num2str(high)];
    disp(out)
    for i=1:b
        for j=1:i
            [cxy fc]=mscohere(winTS(:,i),winTS(:,j));
            %Extract average coherence across wavelet 2 frequencies (.06-.125)
            %corresponds to normalized frequencies .24 to .5 on the graph, but the fc
            %variable indexes frequency in pi radiadian so the range is .75 to 1.57
            adjMat(i,j,low)=mean(cxy(32:65));
            adjMat(j,i,low)=adjMat(i,j,low);%make adjMat symetrical
        end
    end
    dlmwrite([outDir 'adjMat_win' num2str(low)],adjMat(:,:,low));
end
