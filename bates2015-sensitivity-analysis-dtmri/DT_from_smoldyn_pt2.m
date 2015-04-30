function [ DT, ADC, FA, angle ] = DT_from_smoldyn_pt2( MRI_signal, gradient_directions, gradient_strength, delta, Delta)
%DT_FROM_SMOLDYN_PT2 Calculates the diffusion tensor from the simulated MRI
%signal.
%  
% inputs:
%   MRI_signal: vector of length n, n = no of directions
%   gradient_directions: at least 6
%   gradient_strength: in T/um
%   delta: in us
%   Delta: in us
%   
% outputs:
%   DT: diffusion tensor
%   ADC: apparant diffusion coefficient
%   FA: fractional anisotropy
%   angle: of 1st eigenvector wrt x axis, equivalent to fibre angle
%
% notes:
%   

% Author: Joanne Bates <joanne.bates@eng.ox.ac.uk>
% Copyright (c) 2015 University of Oxford
% Version: 0.1.0
% Date: 28 April 2015
% 
% University of Oxford means the Chancellor, Masters and Scholars of
% the University of Oxford, having an administrative office at
% Wellington Square, Oxford OX1 2JD, UK. 
%
% This file is part of Gerardus.
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details. The offer of this
% program under the terms of the License is subject to the License
% being interpreted in accordance with English Law and subject to any
% action against the University of Oxford being under the jurisdiction
% of the English Courts.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

% define the gyromagnetic ratio of water (rad/us/T)
gyro_ratio = 267.5;
no_of_directions = size(gradient_directions,1);

H = zeros(no_of_directions,6);
for j = 1:no_of_directions
        h = [gradient_directions(j,1)^2, gradient_directions(j,2)^2, gradient_directions(j,3)^2, 2*gradient_directions(j,1)*gradient_directions(j,2), 2*gradient_directions(j,1)*gradient_directions(j,3), 2*gradient_directions(j,2)*gradient_directions(j,3)];
        H(j,:) = h;
end

b_value = gradient_strength^2 * gyro_ratio^2 * delta^2 *(Delta - (delta/3));
% CONVERT DIFFUSION SIGNAL INTO TENSOR
Y = (-log(MRI_signal))/b_value;
d = H\Y;

DT = [d(1), d(4), d(5); d(4), d(2), d(6); d(5), d(6), d(3)];

[eVect, eVal] = eig (DT);
eVal = diag(eVal); 
[eVal, order] = sort(eVal, 'descend');
eVect = eVect(:,order);
ADC = mean(eVal);
FA = sqrt(1.5)*sqrt(((eVal(1)-ADC)^2+(eVal(2)-ADC)^2+(eVal(3)-ADC)^2)/(eVal(1)^2+eVal(2)^2+eVal(3)^2));
angle = atand(eVect(2,1)/eVect(1,1));

      
clear H MRI_signal Y d eVal eVect
clear h order
end

