function [u_along,u_cross] = transport_2D(f_in,f_info,level,latbnds,csbnds,csbnds_type)
% ====================================================================================
%  Extract CCS NRT alongshore and cross-shore transport at the ocean surface or bottom
%  using specified latitude and cross-shore bounds
% 
%      [u_along,u_cross] = transport_2D(f_in,f_info,level,latbnds,csbnds,csbnds_type)
% 
%  Input:
%    f_in: ROMS input file name
%    f_info: File containing various info about wc12 grid
%    level: Location in water column where variable is extracted
%	    Can be 'surface' 'bottom', or a numeric sigma level
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
% 	To extract transports averaged from 35 to 40N and
% 	from the 500 m isobath to 300 km from shore:
% 	
% 	   [u_along,u_cross] = transport_2D('in.nc','info.mat','surface',[35 40],[500 300],{'b' 'd'}) 
% ====================================================================================


% Load mask and grid info
if nargin>3
    [~,~,mask] = ccsra31_mask(f_info,'psi',latbnds,csbnds,csbnds_type);
else
    [~,~,mask] = ccsra31_mask(f_info,'psi',latbnds,csbnds);
end
[nx,~] = size(mask);
nz = length(ncread(f_in,'s_rho'));

% Load coastline angle (calculated previously)
load(f_info,'coast_angle_1deg')

% Interpolate coast angle to psi grid (same as 
cangle = repmat((coast_angle_1deg(2:end)+coast_angle_1deg(1:end-1))/2,nx,1);

% Extract currents
nt = length(ncread(f_in,'ocean_time'));
for tt = 1:nt
    switch level
        case 'surface'
            u = squeeze(ncread(f_in,'u',[1 1 nz tt],[Inf Inf 1 1]));
            v = squeeze(ncread(f_in,'v',[1 1 nz tt],[Inf Inf 1 1]));
        case 'bottom'
            u = squeeze(ncread(f_in,'u',[1 1 1 tt],[Inf Inf 1 1]));
            v = squeeze(ncread(f_in,'v',[1 1 1 tt],[Inf Inf 1 1]));
        otherwise
            u = squeeze(ncread(f_in,'u',[1 1 level tt],[Inf Inf 1 1]));
            v = squeeze(ncread(f_in,'v',[1 1 level tt],[Inf Inf 1 1]));
    end

    % Bring u and v to common (psi) grid
    u_psi = (u(:,1:end-1)+u(:,2:end))/2;
    v_psi = (v(1:end-1,:)+v(2:end,:))/2;

    % Calculate alongshore and cross-shore transports
    ua_tmp = v_psi.*sind(cangle) - u_psi.*cosd(cangle);
    uc_tmp = v_psi.*cosd(cangle) + u_psi.*sind(cangle);

    % Average over specified region
    u_along(tt) = nanmean(ua_tmp(mask==1));
    u_cross(tt) = nanmean(uc_tmp(mask==1));
end



