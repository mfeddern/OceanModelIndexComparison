function mld = get_mld(f_in,f_info,latbnds,csbnds,csbnds_type)
% ====================================================================================
%  Extract mixed layer depth from CCSRT using specified latitude
%  and cross-shore bounds. Create 4-day averages from daily output.
% 
%      mld = get_mld(f_in,f_info,latbnds,csbnds,csbnds_type)
% 
%  Input:
%    f_in: ROMS input file name
%    f_info: File containing various info about wc12 grid
%    latbnds: Sets latitude range [minlat maxlat]
%    csbnds: Sets cross-shore bounds based on bathymetry (m)
% 	    or distance from shore (km) 
%    csbnds_type (optional): Specify whether inshore and offshore 
% 	    bounds are isobaths 'b' or distances 'd'.
% 	    Default is distances, i.e., {'d' 'd'};	
% 
%  Output:
%    mld: Spatially averaged mixed layer depth
% 
%  Example:
% 	To extract mixed layer depth averaged from 35 to 40N and
% 	from the 500 m isobath to 300 km from shore:
% 	
% 	   mld = get_mld('in.nc','info.mat',[35 40],[500 300],{'b' 'd'}) 
% ====================================================================================

% Load mask
if nargin>2
    [~,~,mask] = ccsra31_mask(f_info,'rho',latbnds,csbnds,csbnds_type);
else
    [~,~,mask] = ccsra31_mask(f_info,'rho',latbnds,csbnds);
end

% Load depths (calculated previously assuming zeta = 0)
load(f_info,'zr','h')
[nx,ny,nz] = size(zr);

% Extract and average mld
nt = length(ncread(f_in,'ocean_time'));
for tt = 1:nt

    % Load data
    temp = squeeze(ncread(f_in,'temp',[1 1 1 tt],[Inf Inf Inf 1]));
    salt = squeeze(ncread(f_in,'salt',[1 1 1 tt],[Inf Inf Inf 1]));
    dens = sw_dens0(salt,temp);

    % Loop through grid cells
    for ii=1:nx
        for jj=1:ny
            if mask(ii,jj)==1
                T10 = interp1(squeeze(zr(ii,jj,:)),squeeze(temp(ii,jj,:)),-10);
                S10 = interp1(squeeze(zr(ii,jj,:)),squeeze(salt(ii,jj,:)),-10);
                densmld = sw_dens0(S10,T10-0.8);
                if densmld > dens(ii,jj,1)
                    % MLD extends to bottom
                    mld_tmp(ii,jj) = h(ii,jj);
                else
                    try
                        mld_tmp(ii,jj) = -interp1(squeeze(dens(ii,jj,:)),squeeze(zr(ii,jj,:)),densmld);
                    catch
                        mld_tmp(ii,jj) = nan;
                    end
                end
            else
                mld_tmp(ii,jj) = nan;
            end
        end
    end

    mld(tt) = nanmean(mld_tmp(mask==1));
end
