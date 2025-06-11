function [u_along,u_cross] = transport_3D(f_in,f_info,depthbnds,latbnds,csbnds,csbnds_type)
% ====================================================================================
%  Extract depth averaged alonshore and cross-shore transports from CCS NRT
% 
%      [u_along,u_cross] = transport_3D(f_in,f_info,depthbnds,latbnds,csbnds,csbnds_type)
% 
%  Input:
%    f_in: ROMS input file name
%    f_info: File containing various info about wc12 grid
%    depthbnds: Sets depth range [mindepth maxdepth]
%    latbnds: Sets latitude range [minlat maxlat]
%    csbnds: Sets cross-shore bounds based on bathymetry (m)
% 	    or distance from shore (km) 
%    csbnds_type (optional): Specify whether inshore and offshore 
% 	    bounds are isobaths 'b' or distances 'd'.
% 	    Default is distances, i.e., {'d' 'd'};	
% 
%  Output:
%    u_along: Averaged alongshore transport
%    u_cross: Averaged cross-shore transport
% 
%  Example:
% 	To extract transports averaged from 35 to 40N, 50-300 m depth, and
% 	from the 500 m isobath to 300 km from shore:
% 	
% 	   [u_along,u_cross] = transport_3D('in.nc','info.mat',[50 300],[35 40],[500 300],{'b' 'd'}) 
% ====================================================================================

% Load mask
if nargin>3
    [~,~,mask] = ccsra31_mask(f_info,'psi',latbnds,csbnds,csbnds_type);
else
    [~,~,mask] = ccsra31_mask(f_info,'psi',latbnds,csbnds);
end

% Load coastline angle (calculated previously)
load(f_info,'coast_angle_1deg')

% Load depths at psi points, (calculated previously assuming zeta = 0)
load(f_info,'zp')
z = zp;
[nx,ny,nz] = size(z);

% Create 3D matrix of coastal angle
cangle_tmp=repmat((coast_angle_1deg(2:end)+coast_angle_1deg(1:end-1))/2,nx,1);
for ii = 1:nz
    cangle(:,:,ii) = cangle_tmp;
end

% Extract and average transports
nt = length(ncread(f_in,'ocean_time'));
for tt = 1:nt
    
    % Load u and v
    u = squeeze(ncread(f_in,'u',[1 1 1 tt],[Inf Inf Inf 1]));
    v = squeeze(ncread(f_in,'v',[1 1 1 tt],[Inf Inf Inf 1]));

    % Bring u and v to common (psi) grid
    u_psi = (u(:,1:end-1,:)+u(:,2:end,:))/2;
    v_psi = (v(1:end-1,:,:)+v(2:end,:,:))/2;

    % Calculate alongshore and cross-shore wind stress
    ua = v_psi.*sind(cangle) - u_psi.*cosd(cangle);
    uc = v_psi.*cosd(cangle) + u_psi.*sind(cangle);

    % Loop through each grid cell
    kk = 1;
    for ii = 1:nx
        for jj = 1:ny
            if mask(ii,jj) == 1
                if -depthbnds(2)>z(ii,jj,1)
                    % Depth range entirely in water column

                    % Create a linearly space depth profile
                    z_int = linspace(-depthbnds(2),min(z(ii,jj,end),-depthbnds(1)),10);

                    % Interpolate to z_int
                    ua_int = interp1(squeeze(z(ii,jj,:)),squeeze(ua(ii,jj,:)),z_int);
                    uc_int = interp1(squeeze(z(ii,jj,:)),squeeze(uc(ii,jj,:)),z_int);

                    % Calculate mean of vertical profile
                    ua_tmp(kk) = mean(ua_int);
                    uc_tmp(kk) = mean(uc_int);
                elseif -depthbnds(1)>z(ii,jj,1)
                    % Depth range partially in water column

                    % Create a linearly space depth profile
                    z_int = linspace(z(ii,jj,1),min(z(ii,jj,end),-depthbnds(1)),10);

                    % Interpolate to z_int
                    ua_int = interp1(squeeze(z(ii,jj,:)),squeeze(ua(ii,jj,:)),z_int);
                    uc_int = interp1(squeeze(z(ii,jj,:)),squeeze(uc(ii,jj,:)),z_int);

                    % Calculate mean of vertical profile
                    ua_tmp(kk) = mean(ua_int);
                    uc_tmp(kk) = mean(uc_int);
                else
                    % Depth range not in water column
                    ua_tmp(kk) = nan;
                    uc_tmp(kk) = nan;
                end
                kk = kk+1;
            end
        end
    end 

    % Average over specified region
    u_along(tt) = nanmean(ua_tmp);
    u_cross(tt) = nanmean(uc_tmp);
    clear ua_tmp uc_tmp
end





