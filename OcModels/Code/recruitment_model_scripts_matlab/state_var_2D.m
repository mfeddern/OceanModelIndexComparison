function varout = state_var_2D(f_in,f_info,var,level,latbnds,csbnds,csbnds_type)
% ====================================================================================
%  Extract a surface or bottom variable from CCS NRT using specified latitude
%  and cross-shore bounds
% 
%      varout = state_var_2D(f_in,f_info,var,level,latbnds,csbnds,csbnds_type)
% 
%  Input:
%    f_in: ROMS input file name
%    f_info: File containing various info about wc12 grid
%    var: Variable to be extracted - choices are 'temp' 'salt' 'u' 'v' 'w'
%    level: Location in water column where variable is extracted
%	    Can be 'surface' 'bottom' or a numeric sigma level
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
% 	To extract surface temperature extending from 35 to 40N and
% 	from the 500 m isobath to 300 km from shore:
% 	
% 	   varout = state_var_2D('in.nc','info.mat','temp','surface',[35 40],[500 300],{'b' 'd'}) 
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
nz = length(ncread(f_in,'s_rho'));

% Extract variable
nt = length(ncread(f_in,'ocean_time'));
for tt = 1:nt
    switch level
        case 'surface'
            varval = squeeze(ncread(f_in,var,[1 1 nz tt],[Inf Inf 1 1]));
        case 'bottom'
            varval = squeeze(ncread(f_in,var,[1 1 1 tt],[Inf Inf 1 1]));
        otherwise
            varval = squeeze(ncread(f_in,var,[1 1 level tt],[Inf Inf 1 1]));
    end
    
    % Average over specified region
    varout(tt) = nanmean(varval(mask==1));
end




