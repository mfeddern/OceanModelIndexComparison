function varout = state_var_3D(f_in,f_info,var,depthbnds,latbnds,csbnds,csbnds_type)
% ====================================================================================
%  Extract a depth averaged variable from CCS NRT using specified latitude
%  and cross-shore bounds
% 
%      varout = state_var_3D(f_in,f_info,var,depthbnds,latbnds,csbnds,csbnds_type)
% 
%  Input:
%    f_in: ROMS input file name
%    f_info: File containing various info about wc12 grid
%    var: Variable to be extracted - choices are 'temp' 'salt' 'u' 'v' 'w'
%    depthbnds: Sets depth range [mindepth maxdepth]
%    latbnds: Sets latitude range [minlat maxlat]
%    csbnds: Sets cross-shore bounds based on bathymetry (m)
% 	    or distance from shore (km) 
%    csbnds_type (optional): Specify whether inshore and offshore 
% 	    bounds are isobaths 'b' or distances 'd'.
% 	    Default is distances, i.e., {'d' 'd'};	
% 
%  Output:
%    varout: Extracted variable
% 
%  Example:
% 	To extract temperature averaged from 50 to 300 m depth, 35 to 40N, and
% 	from the 500 m isobath to 300 km from shore:
% 	
% 	   varout = state_var_3D('in.nc','info.mat','temp',[50 300],[35 40],[500 300],{'b' 'd'}) 
% ====================================================================================


% Load mask
switch var
    case {'temp' 'salt' 'w'}
        if nargin>4
            [~,~,mask] = ccsra31_mask(f_info,'rho',latbnds,csbnds,csbnds_type);
        else
            [~,~,mask] = ccsra31_mask(f_info,'rho',latbnds,csbnds);
        end
    case 'u'
        if nargin>4
            [~,~,mask] = ccsra31_mask(f_info,'u',latbnds,csbnds,csbnds_type);
        else
            [~,~,mask] = ccsra31_mask(f_info,'u',latbnds,csbnds);
        end
    case 'v'
        if nargin>4
            [~,~,mask] = ccsra31_mask(f_info,'v',latbnds,csbnds,csbnds_type);
        else
            [~,~,mask] = ccsra31_mask(f_info,'v',latbnds,csbnds);
        end
    otherwise
        disp('ERROR - Invalid variable')
        return
end

% Load depths (calculated previously assuming zeta = 0)
load(f_info,'z*')
switch var
    case 'w'
        z = zw;
    case 'u'
        z = zu;
    case 'v'
        z = zv;
    otherwise
        z = zr;
end
[nx,ny,~] = size(z);

% Extract and average state variable
nt = length(ncread(f_in,'ocean_time'));
for tt = 1:nt

    % Load specified variable
    varval = squeeze(ncread(f_in,var,[1 1 1 tt],[Inf Inf Inf 1]));

    % Loop though each grid cell
    kk = 1;
    for ii = 1:nx
        for jj = 1:ny
            if mask(ii,jj) == 1
                if -depthbnds(2)>z(ii,jj,1)
                    % Depth range entirely in water column

                    % Create a linearly space depth profile
                    z_int = linspace(-depthbnds(2),min(z(ii,jj,end),-depthbnds(1)),10);

                    % Interpolate to z_int
                    var_int = interp1(squeeze(z(ii,jj,:)),squeeze(varval(ii,jj,:)),z_int);

                    % Calculate mean of vertical profile
                    vartmp(kk) = mean(var_int);
                elseif -depthbnds(1)>z(ii,jj,1)
                    % Depth range partially in water column

                    % Create a linearly space depth profile
                    z_int = linspace(z(ii,jj,1),min(z(ii,jj,end),-depthbnds(1)),10);

                    % Interpolate to z_int
                    var_int = interp1(squeeze(z(ii,jj,:)),squeeze(varval(ii,jj,:)),z_int);

                    % Calculate mean of vertical profile
                    vartmp(kk) = mean(var_int);
                else
                    % Depth range not in water column
                    vartmp(kk) = nan;
                end
                kk = kk+1;
            end
        end
    end 
    varout(tt) = nanmean(vartmp);
    clear vartmp
end
