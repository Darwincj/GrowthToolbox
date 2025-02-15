function o = readobj( filename )
%o = readobj( filename )
    rawmesh = [];
    formats = struct( ...
        'f', '%d', ...
        'v', '%f', ...
        'vc', '%f', ...
        'fc', '%f', ...
        'm', '%f', ...
        'mn', '%s' );
    rawmesh = addToRawMesh( rawmesh, filename, formats );
    o = rawmesh;
    facecoords = reshape( o.v( o.f', : ), 3, [], 3 );
    centres = permute( sum( facecoords, 1 ), [2 3 1] )/3;
    ns = normals( facecoords );
    figure(1);
    clf;
    hold on;
    fill3( facecoords(:,:,1), facecoords(:,:,2), facecoords(:,:,3), ...
        rand(1,size(o.f,1)), ...
        'FaceAlpha', 0.5 );
    plot3( centres(:,1), centres(:,2), centres(:,3), ...
        'LineStyle', 'none', ...
        'Marker', 'o', ...
        'MarkerSize', 3 );
    quiver3( centres(:,1), centres(:,2), centres(:,3), ...
             ns(:,1), ns(:,2), ns(:,3), ...
             'LineWidth', 3 );
    hold off;
end

function ns = normals( facecoords )
%ns = normals( facecoords )
%   facecoords is a 3*n*3
    ns = 0;
    xy = facecoords(2,:,:) - facecoords(1,:,:);
    xz = facecoords(3,:,:) - facecoords(1,:,:);
    cs = permute( cross( xy, xz, 3 ), [2 3 1] );
    size(cs)
    ns = cs ./ repmat(sqrt(sum(cs.*cs,2)),1,3)
end

