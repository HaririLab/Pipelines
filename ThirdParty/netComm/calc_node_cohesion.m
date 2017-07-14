function [Cij,node_cohesion,node_disjoint,node_flexibility,strength_cohesion,commChanges,commCohesion,commDisjoint,commIndex] = calc_node_cohesion(S,options)
% PURPOSE:	Calculates node cohesion of a node in a multilayer network
%           Node cohesion is a measure of how often a node changes from one
%           community to another with other nodes. Highly cohesive nodes
%           change communities with other nodes often.
%
% INPUT:
%           S: Multilayer community structure with community assignment,
%              rows represent each node while columns denote layer
%
% OUTPUT:
%         * node_cohesion: Node cohesion for a given node
%            
%                             # Times Node Changes Communities Mutually
%             Cohesiveness = -------------------------------------------
%                             # Possible Times Nodes Change Communities
%
%         * node_disjoint: Node disjointedness for a given node
%            
%                            # Times Node Changes Communities Independently
%           Disjointedness = ----------------------------------------------
%                              # Possible Times Nodes Change Communities
%
%         * node_flexiibility: Node flexibility for a given node
%            
%                                # Times Node Changes Communities
%              Flexibility = -------------------------------------------
%                             # Possible Times Nodes Change Communities
%
%         * Cij: Cohesion matrix, similar to adjacency matrix but edge
%                weights represent the number of times two nodes change
%                communities mutually
%
%         * commChanges:  Array contains all community changes
%
%         * commCohesion: Array contains all mutual community changes
%
%         * commDisjoint: Array contains all independent community changes
%
%         * commIndex: Array showing all possible community change
%                      iterations including index in commX arrays
%
%--------------------------------------------------------------------------
%
%  Author: Qawi Telesford
%    Date: 2015-06-13
% Version: 1.2
%
%	History:	1.2 (2015-06-13) | QKT
%               * Removed cohesion normalization
%               * Updated cohesion calculation, now calculates only when
%                 node changes with other nodes
%               * Added node disjointedness, a measure of how often a node
%                 changes communities by itself
%               * Added community change arrays and index
%
%               1.1 (2015-01-16) | QKT
%               * Updated cohesion normalization
%
%               1.0 (2014-10-22) | QKT
%               * Initial release
%
%--------------------------------------------------------------------------
%% Error Checking
if(size(S,2)<2)
    error('Input matrix invalid or contains one layer, please input multilayer community structure matrix.');
end

% Check if matrix contains values of community assignment
S_check = sum(sum(S - double(int16(S))));

if(S_check ~= 0)
    error('Input matrix contains non-integer values, please input multilayer community structure matrix with integer values.');
end

if(nargin < 2 || isempty(options))
    options.figureFlag	= 0;
    options.colormap	= 'jet';
end

%% Initialize Cohesion Matrices and Vectors
N	= size(S,1);                % network size
Cij	= zeros(N);                 % cohesion matrix
P = power(10*ones(size(S)),S);	% converts community assignment to power values, base 10

%% Community structure changes
commChanges = P(:,2:end) - P(:,1:end-1); % Node difference matrix, shows unique shifts of nod
commPossible = size(commChanges,2); % Number of possible community changes

%% Community Change Arrays and Index
commNum = max(S(:));

% commIndex = zeros(2*nchoosek(commNum,2),3);

commIndex = [];
for aa = 1:commNum
    for bb = 1:commNum
        if(aa ~= bb)
            commIndex = [commIndex; aa bb]; %#ok<AGROW>
        end
    end
end

commVal = 1:size(commIndex,1);
commPower = 10.^commIndex(:,2)-10.^commIndex(:,1);
commIndex = [commIndex commPower];
commIndex = [commIndex commVal'];

for xx = 1:size(commIndex,1)
    commFind = commChanges==commIndex(xx,3);
    commChanges(commFind) = xx;
end

commCohesion = commChanges;
commDisjoint = zeros(size(commChanges));
for yy = 1:size(commChanges,2)
    commCount = hist(commChanges(:,yy),max(commChanges(:,yy))+1);
    commColumn = find(commCount==1)-1;
    
    for zz = 1:length(commColumn)
        commCohesion(commChanges(:,yy)==commColumn(zz),yy) = 0;
        commDisjoint(commChanges(:,yy)==commColumn(zz),yy) = 1;
    end
end

commDisjoint = commDisjoint.*commChanges;

%% Calculate node flexibility, cohesiveness, and disjointedness
commChange = logical(commChanges);      % Indicates if node changed communities
cohesionChange = logical(commCohesion); % Indicates if node changed communities mutually
disjointChange = logical(commDisjoint); % Indicates if node changed communities independently

nodeChangeAll = sum(commChange,2);       % Number of times a node changed communities
nodeChangeCoh = sum(cohesionChange,2);
nodeChangeDis = sum(disjointChange,2);

node_flexibility = nodeChangeAll./commPossible; % node flexibility
node_cohesion =    nodeChangeCoh./commPossible; % node cohesiveness
node_disjoint =    nodeChangeDis./commPossible; % node disjointedness

%% Cohesion array

% Finds all unique node changes in each layer
communityShift = unique(commCohesion);
communityShift(communityShift==0) = []; % Remove nodes that do not change communities
cohesion = cell(size(communityShift,1),size(commChanges,2)); % Cell matrix indicating which nodes made unique community shift together

% Finds all unique node changes in each layer
if(isempty(communityShift))
    % disp('Multilayer network contains no changes in community assignment across layers.');
    for xx = 1:size(cohesion,1)
        for yy = 1:size(cohesion,2)
            cohesion{xx,yy} = 0;
        end
    end
else
    for xx = 1:size(cohesion,1)
        communityShiftXX = communityShift(xx);
        for yy = 1:size(cohesion,2)
            if(communityShiftXX == 0)
                cohesion{xx,yy} = 0; % nodes did not change communities
            else
                findCohesion = find(commChanges(:,yy)==communityShiftXX);
                
                if(isempty(findCohesion) || length(findCohesion)==1)
                    cohesion{xx,yy} = 0; % layer without unique community shift or single node community changes set to 0
                else
                    cohesion{xx,yy} = findCohesion;
                end
            end
        end
    end
end

%% Cohesion Matrix
cij = zeros(N);

for ii = 1:size(cohesion,1)
    for jj = 1:size(cohesion,2)
        if(cohesion{ii,jj} ~= 0)
            [p,q] = meshgrid(cohesion{ii,jj}, cohesion{ii,jj});
            node_pairs = [p(:) q(:)];
            
            cij_temp = node2mat(node_pairs,N);
            cij = cij + cij_temp;
        end
    end
end

Cij = Cij + cij;
Cij(logical(eye(size(Cij)))) = 0;

%% Calculate Change Frequnecy
strength_cohesion = sum(Cij,2);

%% Figures
if(options.figureFlag == 1)
    figure(1); imagesc(S);                                    axis('square','off'); colormap(options.colormap); colorbar; title('Multilayer Community Structure');
    figure(2); imagesc(commChanges, [0 max(commIndex(:,4))]); axis('square','off'); colormap(options.colormap); colorbar; title('Community Changes');
    figure(3); imagesc(commCohesion,[0 max(commIndex(:,4))]); axis('square','off'); colormap(options.colormap); colorbar; title('Cohesive Community Changes');
    figure(4); imagesc(commDisjoint,[0 max(commIndex(:,4))]); axis('square','off'); colormap(options.colormap); colorbar; title('Disjoint Community Changes');
    figure(3); imagesc(Cij);                                  axis('square','off'); colormap(options.colormap); colorbar; title('Cohesion Matrix');
end
end
%% Subfunction: Edge List to Adjacency Matrix Conversion
function Aij = node2mat(node_list,N)
% This subfunction creates an adjacency matrix from an input edge list

Aij_nodes = false(N);

for ii = 1:length(node_list)
    Aij_nodes(node_list(ii,1),node_list(ii,2)) = 1;
    Aij_nodes(node_list(ii,2),node_list(ii,1)) = 1;
end
Aij = Aij_nodes;
end