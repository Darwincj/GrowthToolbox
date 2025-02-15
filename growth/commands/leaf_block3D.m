function m = leaf_block3D( m, varargin )
%m = leaf_block3D( m, ... )
%   Make a mesh consisting of an axis-aligned rectangular block divided
%   into volumetric finite elements.
%
%   Arguments:
%       M is either empty or an existing mesh.  If it is empty, then an
%       entirely new mesh is created, with the default set of morphogens.
%       If M is an existing mesh, then its geometry is replaced by the new
%       mesh.  It retains the same set of morphogens (all set to zero
%       everywhere on the new mesh), interaction function, and all other
%       properties not depending on the specific geometry of the mesh.
%
%   Options:
%
%   'size': A 3-element vector, default [2 2 2].  This specifies the
%       dimensions of the block.
%
%   'xwidth', 'ywidth', 'zwidth': Alternative way of specifying the size.
%       If the 'size' options is not given, it defaults to
%       [ xwidth, ywidth, zwidth ].
%
%   'divisions': A 3-element vector of positive integers, default [2 2 2].
%       This specifies how many finite elements it is divided into along
%       each dimension.
%
%   'xdivs', 'ydivs', 'zdivs': Alternative way of specifying the number of
%       finite elements each way. If the 'divisions' options is not given,
%       it defaults to [ xdivs, ydivs, zdivs ].
%
%   'position': A 3-element vector, default [0 0 0]. This specifies the
%       position of the centre of the block. 
%
%   'type': A finite element type.  Possibilities are 'T4Q' (the default),
%       and others to be implemented.  'H8' specifies that the block is to
%       be made of linear hexahedra. 'T4' and 'T4Q' specify linear or
%       quadratic tetrahedra respectively (combining in fives to make
%       blocks).  'P6' specifies linear pentahedra (combining in pairs to
%       make blocks).
%
%   'new':  A boolean, true by default.  If M is
%       empty, true is implied.  True means that an
%       entirely new mesh is created.  False means that
%       new geometry will be created, which will replace
%       the current geometry of M, but leave M with the
%       same set of morphogens and other parameters as it
%       had previously.  (NOT IMPLEMENTED)
%
%   See also:
%           LEAF_CIRCLE, LEAF_CYLINDER, LEAF_ICOSAHEDRON, LEAF_LOBES,
%           LEAF_ONECELL, LEAF_RECTANGLE, LEAF_SNAPDRAGON, LEAF_BLOCK3D,
%           LEAF_SPHERE3D, LEAF_ICOSAHEDRON3D.
%
%   Topics: Mesh creation.

    [s,ok] = safemakestruct( mfilename(), varargin );
    if ~ok, return; end
    setGlobals();
    s = defaultfields( s, ...
        'xwidth', 2, ...
        'ywidth', 2, ...
        'zwidth', 2, ...
        'xdivs', 2, ...
        'ydivs', 2, ...
        'zdivs', 2 );
    s = defaultfields( s, ...
        'size', [ s.xwidth, s.ywidth, s.zwidth ], ...
        'divisions', [ s.xdivs, s.ydivs, s.zdivs ], ...
        'position', [0 0 0], ...
        'type', 'T4Q', ...
        'new', true );
    % We remove 'thickness' because this parameter is not applicable to
    % volumetric  meshes.  This is just a hack to cope with the fact that
    % GFtbox always supplies the thickness value from the GUI, even for
    % volumetric meshes.
    s = safermfield( s, 'xwidth', 'ywidth', 'zwidth', 'xdivs', 'ydivs', 'zdivs', 'thickness' );
    ok = checkcommandargs( mfilename(), s, 'exact', ...
        'size', 'divisions', 'position', 'type', 'new' );
    if ~ok, return; end

    [ok,handles,m,savedstate] = prepareForGUIInteraction( m );
    if ~ok, return; end
    savedstate.replot = true;
    savedstate.install = true;
    if s.new
        m = [];
    elseif isempty(m)
        s.new = true;
    end

    locorner = s.position-s.size/2;
    hicorner = s.position+s.size/2;
    isQuadElement = strcmp( s.type, 'H8Q' ) || strcmp( s.type, 'T4Q2' );
    if isQuadElement
        segmentsperFE = [2 2 2];
    else
        segmentsperFE = [1 1 1];
    end
    numvals = s.divisions.*segmentsperFE + 1;
    xvals = linspace( locorner(1), hicorner(1), numvals(1) );
    yvals = linspace( locorner(2), hicorner(2), numvals(2) );
    zvals = linspace( locorner(3), hicorner(3), numvals(3) );
    
    allx = repmat( xvals(:), numvals(2)*numvals(3), 1 );
    ally = reshape( repmat( yvals, numvals(1), numvals(3) ), [], 1 );
    allz = reshape( repmat( zvals, numvals(1)*numvals(2), 1 ), [], 1 );
    vxs = [ allx, ally, allz ];
    dxi = segmentsperFE(1);
    dyi = numvals(1)*segmentsperFE(2);
    dzi = dyi*numvals(2)*segmentsperFE(3);
    if isQuadElement
        base = 0:segmentsperFE(1);
        relvxi = base;
        relvxi = reshape( repmat( relvxi', 1, segmentsperFE(2)+1 ) + repmat( base*numvals(1), length(relvxi), 1 ), 1, [] );
        relvxi = reshape( repmat( relvxi', 1, segmentsperFE(3)+1 ) + repmat( base*numvals(1)*numvals(2), length(relvxi), 1 ), 1, [] );
    else
        relvxi = [0, dxi, dyi, dxi+dyi];
        relvxi = [ relvxi, relvxi+dzi ];
    end
    vstarts1 = repmat( segmentsperFE(1)*(0:(s.divisions(1)-1))', s.divisions(2)*s.divisions(3), 1 );
    vstarts2 = reshape( repmat( numvals(1)*segmentsperFE(2)*(0:(s.divisions(2)-1)), s.divisions(1), s.divisions(3) ), [], 1 );
    vstarts3 = reshape( repmat( numvals(1)*numvals(2)*segmentsperFE(3)*(0:(s.divisions(3)-1)), s.divisions(1)*s.divisions(2), 1 ), [], 1 );
    vstarts = 1 + vstarts1 + vstarts2 + vstarts3;
    vxsets = repmat( vstarts, 1, length(relvxi) ) + repmat( relvxi, length(vstarts), 1 );

    ei = 0;
    for i=1:s.divisions(3)
        px = flipCuboidIndexes( 3*mod(i-1,2), segmentsperFE+1 );
%         px = flipCubeIndexes( mod(i-1,2) );
        for j=1:s.divisions(2)
            py = px( flipCuboidIndexes( 2*mod(j-1,2), segmentsperFE+1 ) );
            % py = px( flipCubeIndexes( mod(j-1,2) ) );
            for k=1:s.divisions(1)
                pz = py( flipCuboidIndexes( 1*mod(k-1,2), segmentsperFE+1 ) );
                % pz = py( flipCubeIndexes( mod(k-1,2) ) );
                ei = ei+1;
                vxsets(ei,:) = vxsets( ei,pz );
            end
        end
    end
    
    switch s.type
        case 'H8'
            % Nothing.
        case 'H8Q'
            % Nothing.
        case { 'T4', 'T4Q' }
            % Make a new version of vxsets dividing each cube into five
            % tetrahedra.
            % For the vertexes of a cube numbered 1 to 8, the tetrahedra
            % vertex sets would be 1 2 4 8, 1 3 7 8, and 1 5 6 8.
            % tetraindexes = [ 1 2 4 8; 1 3 4 8; 1 3 7 8; 1 5 7 8; 1 5 6 8; 1 2 6 8 ]';
            % subindexes = [ 1 2 3 5;  4 3 2 8;  6 2 8 5;  7 3 5 8;  2 3 5 8 ]';
            subindexes = [ 2 4 1 6; 3 1 4 7; 5 1 6 7; 8 4 7 6; 1 4 7 6 ]';
            vxsets = reshape( vxsets( :, subindexes )', size( subindexes, 1 ), [] )';
        case 'T4Q2'
            % Make a new version of vxsets dividing each cube into five
            % tetrahedra.
            % For the vertexes of a cube numbered 1 to 8, the tetrahedra
            % vertex sets would be 1 2 4 8, 1 3 7 8, and 1 5 6 8.
            % tetraindexes = [ 1 2 4 8; 1 3 4 8; 1 3 7 8; 1 5 7 8; 1 5 6 8; 1 2 6 8 ]';
            subindexes = [ 1 2 3 4 5 7 10 11 13 19;
                           9 8 7 6 5 3 18 17 15 27;
                           21 12 3 24 15 27 20 11 23 19
                           25 16 7 22 13 19 26 17 23 27
                           3 5 7 11 13 19 15 17 23 27 ]';
            vxsets = reshape( vxsets( :, subindexes )', size( subindexes, 1 ), [] )';
        case 'P6'
            % Make a new version of vxsets dividing each cube into three
            % tetrahedra.
            % For the vertexes of a cube numbered 1 to 8, the tetrahedra
            % vertex sets would be 1 2 4 8, 1 3 7 8, and 1 5 6 8.
            subindexes = [ 1 2 4 5 6 8; 1 4 3 5 8 7 ]';
            vxsets = reshape( vxsets( :, subindexes )', size( subindexes, 1 ), [] )';
        otherwise
            % Type not recognised, cannot build mesh.
            fprintf( 1, '%s: Unknown or unsupported finite element type ''%s''.\n', mfilename(), s.type );
            m = [];
            return;
    end
    
     
    newm.FEnodes = vxs;
    newm.FEsets = struct( 'fe', FiniteElementType.MakeFEType(s.type), ...
                       'fevxs', vxsets );
    if isempty(m)
        m = completeVolumetricMesh( newm );
    else
        m = replaceNodes( m, newm );
    end
    
    eps = s.size ./ (s.divisions*2);
    v_xlo = vxs(:,1) <= locorner(1) + eps(1);
    v_xhi = vxs(:,1) >= hicorner(1) - eps(1);
    v_ylo = vxs(:,2) <= locorner(2) + eps(2);
    v_yhi = vxs(:,2) >= hicorner(2) - eps(2);
    v_zlo = vxs(:,3) <= locorner(3) + eps(3);
    v_zhi = vxs(:,3) >= hicorner(3) - eps(3);
    vxcornerness = v_xlo + v_xhi + v_ylo + v_yhi + v_zlo + v_zhi;
    m.sharpedges = all( vxcornerness( m.FEconnectivity.edgeends ) > 1, 2 );
    m.sharpvxs = vxcornerness > 2;
    
    m = concludeGUIInteraction( handles, m, savedstate );
end

function p = flipCubeIndexes( axis, divs )
    
    switch axis
        case { 1, 'x' }
            p = [ 2 1 4 3 6 5 8 7 ];
        case { 2, 'y' }
            p = [ 3 1 4 2 7 5 8 6 ];
        case { 3, 'z' }
            p = [ 5 1 6 2 7 3 8 4 ];
        otherwise
            p = [ 1 2 3 4 5 6 7 8 ];
    end
end
