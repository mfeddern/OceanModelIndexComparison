function [lon,lat,mask] = ccsra31_mask(f_info,vartype,latbnds,csbnds,csbnds_type)

% Create a mask on the ROMS WC12 grid based on specified 
% alongshore and cross-shore bounds
%
%     [lon,lat,mask] = ccsra31_mask(f_info,vartype,latbnds,csbnds,csbnds_type)
%
% Input:
%   f_info: File containing various info about wc12 grid
%   vartype: Grid locations for mask - choices are 'rho' 'u' 'v' 'psi'
%   latbnds: Sets latitude range [minlat maxlat]
%   csbnds: Sets cross-shore bounds based on bathymetry (m)
%	    or distance from shore (km) 
%   csbnds_type (optional): Specify whether inshore and offshore 
%	    bounds are isobaths 'b' or distances 'd'.
%	    Default is distances, i.e., {'d' 'd'};	
%
% Output:
%   lon: longitude with dimensions [lon lat]
%   lat: latitude with dimensions [lon lat]
%   mask: mask with dimensions [lon lat]
%	  mask = 1 within specified range and 0 outside of range
%
% Example:
%	To generate a mask for temperature extending from 35 to 40N and
%	from the 500 m isobath to 300 km from shore:
%	
%	[lon,lat,mask] = ccsra31_mask('info.nc','rho',[35 40],[500 300],{'b' 'd'}) 

% Load grid information
load(f_info,'lon*','lat*','mask*','dist*','h*')
switch vartype
  case 'rho'
    lon = lon;
    lat = lat;
    dist = dist;
    h = h;
    landmask = mask;
  case 'u'
    lon = lonu;
    lat = latu;
    dist = distu;
    h = hu;
    landmask = masku;
  case 'v'
    lon = lonv;
    lat = latv;
    dist = distv;
    h = hv;
    landmask = maskv;
  case 'psi'
    lon = lonpsi;
    lat = latpsi;
    dist = distpsi;
    h = hpsi;
    landmask = maskpsi;
  otherwise
    disp('ERROR - Invalid variable type')
    return
end

% Initialize mask
mask = ones(size(lon));

% Apply land mask
mask(landmask==0) = 0;

% Apply latitude mask
mask(lat<latbnds(1)) = 0;
mask(lat>latbnds(2)) = 0;

% Apply cross-shore mask
if nargin>3
  switch csbnds_type{1}
    case 'b'
      mask(h<csbnds(1)) = 0;
    case 'd'
      mask(dist<csbnds(1)) = 0;
    otherwise
      dist('ERROR - Invalid cross-shore bound type')
      return
  end
  switch csbnds_type{2}
    case 'b'
      mask(h>csbnds(2)) = 0;
    case 'd'
      mask(dist>csbnds(2)) = 0;
    otherwise
      dist('ERROR - Invalid cross-shore bound type')
      return
  end
else
  mask(dist<csbnds(1)) = 0;
  mask(dist>csbnds(2)) = 0;
end

