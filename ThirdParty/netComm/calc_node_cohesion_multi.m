function [Cij,cohesion_node,disjoint_node,flexibility_node,strength_cohesion,commChanges,commCohesion,commDisjoint,commIndex,cohesion_node_net,disjoint_node_net,flexibility_node_net,strength_cohesion_net,cohesion_node_std,disjoint_node_std,flexibility_node_std,strength_cohesion_std,cohesion_node_all,disjoint_node_all,flexibility_node_all,strength_cohesion_all] = calc_node_cohesion_multi(community_structure)
% PURPOSE: Calculates node cohesion from the community structure cell array
%          taken from multiple simulations
%
% INPUT:
%	community_structure: Cell array from multiple simulations of
%                        multilayer community structure
%
% OUTPUT:
%   * General output
%       Cij:                Cohesion strength matrix
%       cohesion_node:      Average node cohesiveness
%       disjoint_node:      Average node disjointedness
%       flexibility_node:   Average node flexibility
%       strength_cohesion:	Average node cohesion strength
%       commChanges:        Space-time diagrams showing community changes
%       commCohesion:       Space-time diagrams showing mutual community changes
%       commDisjoint:       Space-time diagrams showing indpendent commmunity changes
%       commIndex:          Legends for specific community changes in space-time diagrams 
%
%	* Average across nodes
%       cohesion_node_net
%       disjoint_node_net
%       flexibility_node_net
%       strength_cohesion_net
%
%	* Standard deviation across simulations per node
%       cohesion_node_std
%       disjoint_node_std
%       flexibility_node_std
%       strength_cohesion_std
%
%	* Output for all simulations
%       cohesion_node_all
%       disjoint_node_all
%       flexibility_node_all
%       strength_cohesion_all
%
%---------------------------------------------------------------------------
%  Author: Qawi Telesford
%	 Date: 2015-06-14
% Version: 1.2
%
% History:  1.2 (2015-06-14) | QKT
%           * Updated to include cohesiveness, disjointedness, flexibility,
%             and strength calculation (CDFS)
%
%           1.1 (2015-01-16) | QKT
%           * Minor bug fixes
%
%           1.0 (2015-01-16) | QKT
%           * Initial release
%   
%--------------------------------------------------------------------------- 
%% Error Checking
if(nargin < 1 || isempty(community_structure))
    error('Missing input, please enter cell array from multpile simulations of community structure.');
end

if(~iscell(community_structure))
    error('Input does not appear to be cell array. Please enter cell array from multpile simulations of community structure. If input is from single simulation, please use ''calc_node_cohesion'' function instead');
end

%% Initialize Variables
N = size(community_structure{1},1);
repetitions = size(community_structure,1);
Cij  = zeros(N);

cohesion_node_all       = zeros(N,repetitions);
disjoint_node_all       = zeros(N,repetitions);
flexibility_node_all	= zeros(N,repetitions);
strength_cohesion_all	= zeros(N,repetitions);

commChanges  = cell(repetitions,1);
commCohesion = cell(repetitions,1);
commDisjoint = cell(repetitions,1);
commIndex    = cell(repetitions,1);

%% Calculate CDFS
for xx = 1:repetitions
    S = community_structure{xx};
    
    [cij,c,d,f,s,commChanges{xx,1},commCohesion{xx,1},commDisjoint{xx,1},commIndex{xx,1}] = calc_node_cohesion(S); % [c,cn,~,cij,cijn] = calc_node_cohesion(S);
    
    Cij = Cij + cij;
    
    cohesion_node_all(:,xx)     = c;
    disjoint_node_all(:,xx)     = d;
    flexibility_node_all(:,xx)	= f;
    strength_cohesion_all(:,xx)	= s;
end

Cij = Cij./repetitions;

cohesion_node        = mean(cohesion_node_all,2);
cohesion_node_std	 = std(cohesion_node_all,0,2);
cohesion_node_net    = mean(cohesion_node);

disjoint_node        = mean(disjoint_node_all,2);
disjoint_node_std	 = std(disjoint_node_all,0,2);
disjoint_node_net    = mean(disjoint_node);

flexibility_node	 = mean(flexibility_node_all,2);
flexibility_node_std = std(flexibility_node_all,0,2);
flexibility_node_net = mean(flexibility_node);

strength_cohesion     = mean(strength_cohesion_all,2);
strength_cohesion_net = mean(strength_cohesion);
strength_cohesion_std = std(strength_cohesion,0,2);