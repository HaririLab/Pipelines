addpath(genpath('/munin/DNS.01/Analysis/Max/scripts/Pipelines/ThirdParty/GenLouvain-2.1'));
addpath(genpath('/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/Pipelines/ThirdParty/netComm'));

A=cell(1,114);
for i=1:114
    A{i}=load(['/munin/DNS.01/Analysis/All_Imaging/DNS0565/rest/rest1/commDetection/matrices/adjMat_win' num2str(i)]);
end

%can you multiord to do everthing below up to genLouvain
%Need to decide if you want to use iterated_genLouvain or Baum style
%iterating, also might want to ask Bassett about this
%Can you ever talk about the same communities across participants? May
%want to ask Bassett about this as well...group community detection
%look at Bassett consensus scripts
N=length(A{1});
T=length(A);
nreps=100;

preagreement = zeros(N,T,nreps);
for r=1:nreps
    gamma=1;
    omega=1;
    [B,mm]=multiord(A,gamma,omega);
    S = genlouvain(B);
    S = reshape(S,N,T);
    % Write it into the pre-agreement matrix
    preagreement(:,:,r) = S;
end
consCommMat=zeros(T,N);
conQual=zeros(T,N)
for t=1:T
    windowOpt=reshape(preagreement(:,t,:),163,100);
    windowOpt=transpose(windowOpt);
    [S2, Q2, X_new2, qpc]=consensus_iterative(windowOpt);
    consensus=mode(S2);
    consCommMat(t,:)=consensus;
    conQual(t,:)=mean(consensus==S2); %metric to determine "consensusness" 100 per is perfect, should be close
end