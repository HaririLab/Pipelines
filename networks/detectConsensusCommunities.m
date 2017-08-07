
function detectConsensusCommunities(adjDir,outDir,prefix)
addpath(genpath('/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/Pipelines/ThirdParty/GenLouvain-2.1'));
addpath(genpath('/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/Pipelines/ThirdParty/netComm'));

%Inputs:    adjDir,    directory containing adjacency matrices for a single
%subject's scan. There should be one matrix for each sliding window
%timepoint
%           outDir,    directory where output will be written

%load in data
d=length(dir([adjDir '/' prefix '_adjMatWin*']));
A=cell(1,d);
for i=1:d
    A{i}=load([adjDir '/' prefix '_adjMatWin' num2str(i)]);
end

%set up variables
N=length(A{1});
T=length(A);
nreps=100;
gamma=1;
omega=1;

preagreement=cell(nreps,1);
flexIter=zeros(nreps,N);
for r=1:nreps
    %run genlouvain on a time layeredadjacency matrix 
    %taken from http://netwiki.amath.unc.edu/GenLouvain/GenLouvain
    [B,mm]=multiord(A,gamma,omega);
    S = genlouvain(B);
    S = reshape(S,N,T);
    % Write this iteration into the pre-agreement matrix
    preagreement{r} = S;
end
[Cij,cohesion_node,disjoint_node,flexibility_node,strength_cohesion,commChanges,commCohesion,commDisjoint,commIndex,cohesion_node_net,disjoint_node_net,flexibility_node_net,strength_cohesion_net,cohesion_node_std,disjoint_node_std,flexibility_node_std,strength_cohesion_std,cohesion_node_all,disjoint_node_all,flexibility_node_all,strength_cohesion_all] = calc_node_cohesion_multi(preagreement);

consCommMat=zeros(T,N); %create empty matrix for consensus
conQual=zeros(T,N);
newPre=cat(3,preagreement{:});
for t=1:T %run consensus for each time layer
    windowOpt=reshape(newPre(:,t,:),N,nreps);
    windowOpt=transpose(windowOpt);
    [S2, Q2, X_new2, qpc]=consensus_iterative(windowOpt);
    consensus=mode(S2); %not always one answer, so take the most common answer
    consCommMat(t,:)=consensus;
    %conQual(t,:)=mean(consensus==S2); %metric to determine "consensusness" 100 per is perfect, should be close
end
flex=flexibility(consCommMat);
%Write out matrix and metrics of interest
dlmwrite([outDir prefix '_consensusMat'],consCommMat);
dlmwrite([outDir prefix '_cohesionStrengthMat'],Cij);
dlmwrite([outDir prefix '_nodeAvgCohesion'],cohesion_node);
dlmwrite([outDir prefix '_nodeAvgFlexibility'],flexibility_node);
dlmwrite([outDir prefix '_nodeAvgStrengthCohesion'],strength_cohesion);
dlmwrite([outDir prefix '_nodeAvgDisjoint'],disjoint_node);
dlmwrite([outDir prefix '_nodeStdCohesion'],cohesion_node_std);
dlmwrite([outDir prefix '_nodeStdFlexibility'],flexibility_node_std);
dlmwrite([outDir prefix '_nodeStdStrengthCohesion'],strength_cohesion_std);
dlmwrite([outDir prefix '_nodeStdDisjoint'],disjoint_node_std);
dlmwrite([outDir prefix '_avgCohesion'],cohesion_node_net);
dlmwrite([outDir prefix '_avgFlexibility'],flexibility_node_net);
dlmwrite([outDir prefix '_avgStrengthCohesion'],strength_cohesion_net);
dlmwrite([outDir prefix '_avgDisjoint'],disjoint_node_net);