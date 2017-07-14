function [ comm_spatial_diameter_array ] = comm_spatial_diameter(partitions,locations)

% COMM_SPATIAL_DIAMETER - function to calculate the spatial diameter 
%         of detected communities
%
% Inputs: 
%         'partitions'    --- an N x 1 array where N is the number of nodes
%         in the network.  Each entry contains the community index for
%         node i (where communities are sequentially indexed as 1:M and M
%         is the total number of detected communities).
% 
%         'locations'   ---  a N x dim array where N is the number of nodes and
%         dim is the spatial dimensionality of the network (1,2,or 3).  The
%         columns contain the (x,y,z) coordinates of the nodes in euclidean
%         space
%
% Outputs: 
%         comm_spatial_diameter_array   --- an (M+1) x 2 array where M is the number
%         of communities.  The first column contains the community index and
%         the second column contains the spatial diameter 
%         within that community.  The M+1th entry contains the 
%         spatial diameter of the network (denoted as community 0). 
%
% Written by Sarah Feldt Muldoon

% Reference: Feldt Muldoon S, Soltesz I, Cossart R (2013) Spatially clustered 
%         neuronal assemblies comprise the microstructure of synchrony in chronically 
%         epileptic networks. Proc Natl Acad Sci USA 110:3567?3572.


number_nodes = length(partitions);
number_communities = max(partitions);
comm_spatial_diameter_array = zeros(number_communities + 1,2);
comm_spatial_diameter_array(:,1) = [1:number_communities 0];

%calculate diameter for each community
for i = 1:number_communities
    community_i_nodes = find(partitions == i);
    number_nodes_in_i = length(community_i_nodes);
    dist_array = [];
    if number_nodes_in_i >= 2
        for j = 1:number_nodes_in_i - 1
            node_j = community_i_nodes(j);
            for k = j+1:number_nodes_in_i
                node_k = community_i_nodes(k);
                coordinates_j = locations(node_j,:);
                coordinates_k = locations(node_k,:);
                dist_jk = sqrt(sum((coordinates_j-coordinates_k) .^ 2));
                dist_array = [dist_array dist_jk];
            end
        end
        max_dist_i = max(dist_array);
        comm_spatial_diameter_array(i,2) = max_dist_i;
    end
end

%calculate diameter for the entire network
dist_array = [];
for i = 1:number_nodes-1
    coordinates_i = locations(i,:);
    for j = i+1:number_nodes
        coordinates_j = locations(j,:);
        dist_ij = sqrt(sum((coordinates_i-coordinates_j).^2));
        dist_array = [dist_array dist_ij];
    end
end
max_dist_network = max(dist_array);
comm_spatial_diameter_array(number_communities + 1,2) = max_dist_network;

end


