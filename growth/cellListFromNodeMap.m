function cells = cellListFromNodeMap( m, nodemap, mode )
%cells = cellsfromnodemap( m, nodes, mode )
%   M is a mesh.  NODES is either an array of node indexes or a boolean map
%   of nodes.
%   If MODE is 'all', find every finite element for which every vertex is
%   in the set of nodes; if 'any', every finite element with at least one
%   vertex in the set.
%   The set of cells is returned as an array of indexes.  If you need a
%   boolean map of the cells, call cellMapFromNodeMap( m, nodemap, mode ).
%
%   See also: cellMapFromNodeMap

    cells = find( cellMapFromNodeMap( m, nodemap, mode ) );
end
