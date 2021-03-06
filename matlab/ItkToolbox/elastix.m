function [t, movingReg, iterInfo] = elastix(regParam, fixed, moving, opts)
% elastix  Matlab interface to the image registration program "elastix".
%
% elastix is a simple interface to the command line program "elastix"
%
%   http://elastix.isi.uu.nl/
%
% Command-line "elastix" is a powerful rigid and nonrigid registration
% program, but it requires that input images are provided as files, and
% returns the results (transform parameters, registered image, etc) as
% files in a directory. This is not so convenient when using Matlab, so
% this interface function allows to pass images either as filenames or as
% image arrays, and transparently takes care of creating temporary files
% and directories, reading the result to Matlab variables, and cleaning up
% afterwards.
%
% [T, MOVINGREG, ITERINFO] = elastix(REGPARAM, FIXED, MOVING, OPTS)
%
%   REGPARARM is a string with the path and name of a text file with the
%   registration parameters for elastix, e.g.
%   '/path/to/ParametersTranslation2D.txt'.
%
%   FIXED, MOVING are the images to register. They can be given as file
%   names or as image arrays, e.g. 'im1.png' or im = checkerboard(10).
%   Images can have one channel (grayscale) or more (e.g. RGB colour
%   images). In the case of multi-channel images, we use the "multi-image"
%   feature in elastix (see section 6.1.1 "Image registration with
%   multiple metrics and/or images" in the elastix manual), with all
%   channels contributing equally to the combined cost function. FIXED and
%   MOVING must have the same number of channels.
%
%   OPTS is a struct where the fields contain options for the algorithm:
%
%     verbose: (def 0) If 0, it hides all the elastix command output to the
%              screen.
%
%     outfile: (def '') Path and name of output image file to save
%              registered image to. This option is ignored when MOVING is
%              an image array.
%
%     t0:      (def '') Struct or filename with an initial transform (see T
%              below for format). t0 is applied to the image before the
%              registration is run. Note that parameter
%              InitialTransformParametersFileName allows to provide another
%              transform that will be applied before t0, and so on
%              iteratively.
%
%     fMask:   (def '') Mask for the fixed image. Only voxels == 1 are
%              considered for the registration.
%
%     mMask:   (def '') Mask for the moving image. Only voxels == 1 are
%              considered for the registration.
%
%   T is a struct with the contents of the parameter transform file
%   (OUTDIR/TransformParameters.0.txt), e.g.
%
%                             Transform: 'TranslationTransform'
%                    NumberOfParameters: 2
%                   TransformParameters: [-2.4571 0.3162]
%    InitialTransformParametersFileName: 'NoInitialTransform'
%                HowToCombineTransforms: 'Compose'
%                   FixedImageDimension: 2
%                  MovingImageDimension: 2
%           FixedInternalImagePixelType: 'float'
%          MovingInternalImagePixelType: 'float'
%                                  Size: [2592 1944]
%                                 Index: [0 0]
%                               Spacing: [1 1]
%                                Origin: [0 0]
%                             Direction: [1 0 0 1]
%                   UseDirectionCosines: 'true'
%                  ResampleInterpolator: 'FinalBSplineInterpolator'
%        FinalBSplineInterpolationOrder: 3
%                             Resampler: 'DefaultResampler'
%                     DefaultPixelValue: 0
%                     ResultImageFormat: 'png'
%                  ResultImagePixelType: 'unsigned char'
%                   CompressResultImage: 'false'
%
%   Nested transforms: If T is a series of nested transforms, e.g.
%
%     ta.Transform = 'EulerTransform';
%     ta.InitialTransformParametersFileName = tb;
%
%     tb.Transform = 'BSplineTransform';
%     tb.InitialTransformParametersFileName = 'NoInitialTransform';
%
%   tb is the "initial transform" of ta, but because ITK and elastix define
%   the transform of an image in the inverse direction, in practice what
%   happens is that ta is applied *first* to the image, and then tb is
%   applied to the result.
%
%   MOVINGREG is the result of registering MOVING onto FIXED. MOVINGREG is
%   the same type as MOVING (i.e. image array or path and filename). In the
%   path and filename case, an image file will we created with path and
%   name MOVINGREG=PARAM.outfile. If PARAM.outfile is not provided or
%   empty, then the registered image is deleted and MOVINGREG=''. For
%   multi-channel images (e.g. RGB colour images), MOVINGREG will
%   correspond to the first channel only, as this is the output provided by
%   elastix. To obtain the multi-channel result, it is necessary to apply
%   the transform to MOVING with transformix().
%
%   ITERINFO is a struct with the details of the elastix optimization
%   (OUTDIR/IterationInfo.0.R0.txt), e.g.
%
%        ItNr: [10x1 double]
%      Metric: [10x1 double]
%    stepSize: [10x1 double]
%    Gradient: [10x1 double]
%        Time: [10x1 double]
%
%
% See also: transformix, elastix_read_file2param, elastix_write_param2file,
% elastix_read_reg_output.

% Author: Ramon Casero <rcasero@gmail.com>
% Copyright © 2014 University of Oxford
% Version: 0.4.2
% $Rev$
% $Date$
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

% check arguments
narginchk(3, 4);
nargoutchk(0, 3);

if (isempty(regParam))
    error('REGPARAM must be a .txt file or a struct with the registration parameters for elastix')
end

% defaults
if (nargin < 4 || isempty(opts) || ~isfield(opts, 'verbose'))
    % capture the elastix output so that it's not output on the screen
    opts.verbose = 0;
end
if (nargin < 4 || isempty(opts) || ~isfield(opts, 'outfile'))
    % no name provided for the output file
    opts.outfile = '';
end
if (nargin < 4 || isempty(opts) || ~isfield(opts, 't0'))
    % no initial transform provided
    opts.t0 = '';
end
if (nargin < 4 || isempty(opts) || ~isfield(opts, 'fMask'))
    % no fixed image mask provided
    opts.fMask = '';
end
if (nargin < 4 || isempty(opts) || ~isfield(opts, 'mMask'))
    % no moving image mask provided
    opts.mMask = '';
end

% if tranformation parameters are given as a struct, we need to create a
% temp file so that elastix can load them
[paramfile, delete_paramfile] = create_temp_file_if_struct(regParam);

% ditto for the initial transform
[t0file, delete_t0file] = create_temp_file_if_struct(opts.t0);

% if images are given as arrays instead of filenames, we need to create 
% temporary files with the images so that elastix can work with them
[fixedfile, delete_fixedfile] = create_temp_file_if_array_image(fixed);
[movingfile, delete_movingfile] = create_temp_file_if_array_image(moving);

% check that fixed and moving images have the same number of channels
if (iscell(fixedfile) && ~iscell(movingfile))
    error('Fixed and moving image must have the same number of channels')
end
if (iscell(fixedfile) && ...
        (length(fixedfile) ~= length(movingfile)))
    error('Fixed and moving image must have the same number of channels')
end

% check that registration parameters are correct for multichannel images
if (iscell(fixedfile))
    auxParam = elastix_read_file2param(paramfile);
    if (~strcmp(auxParam.Registration, 'MultiMetricMultiResolutionRegistration'))
        error('Multi-channel image registration requires regParam.Registration = ''MultiMetricMultiResolutionRegistration''.')
    end
%     if ((auxParam.FixedImagePyramid, ))
%         error('Multi-channel image registration requires regParam.Registration = ''MultiMetricMultiResolutionRegistration''.')
%     end
end

% ditto for the fixed and moving masks
[fMaskfile, delete_fMaskfile] = create_temp_file_if_array_image(opts.fMask);
[mMaskfile, delete_mMaskfile] = create_temp_file_if_array_image(opts.mMask);

if (ischar(moving))
    
    % if moving image is given as a filename, then we'll save the
    % registered image to the path provided by the user. If the user has
    % not provided an output name, then the result image will not be
    % returned. This is useful when we only need the transformation
    if (~isfield(opts, 'outfile'))
        opts.outfile = '';
    end
    
else
    
    % if moving image was provided as an image, the output will be an
    % image array in memory, and we can ignore the output directory, as it
    % will not be saved to a file
    opts.outfile = '';
    
end

% create temp directory for output
tempoutdir = tempname;
success = mkdir(tempoutdir);
if (~success)
    error(['Cannot create temp directory for registration output: ' tempoutdir])
end

% create text string with the command to run elastix
comm = 'elastix ';
if (iscell(fixedfile)) % multi-channel images
    for I = 1:length(fixedfile)
        comm = [...
            comm ...
            ' -f' num2str(I-1) ' ' fixedfile{I} ...
            ' -m' num2str(I-1) ' ' movingfile{I} ...
            ];
    end
else % single channel (grayscale) images
    comm = [...
        comm ...
        ' -f ' fixedfile ...
        ' -m ' movingfile ...
        ];
end
comm = [...
    comm ...
    ' -out ' tempoutdir ...
    ' -p ' paramfile
    ];
if (~isempty(opts.t0))
    comm = [...
        comm ...
        ' -t0 ' t0file ...
        ];
end
if (~isempty(opts.fMask))
    comm = [...
        comm ...
        ' -fMask ' fMaskfile ...
        ];
end
if (~isempty(opts.mMask))
    comm = [...
        comm ...
        ' -mMask ' mMaskfile ...
        ];
end

% run elastix
if (opts.verbose)
    status = system(comm);
else
    % hide command output from elastix
    [status, ~] = system(comm);
end
if (status ~= 0)
    error('Registration failed')
end

if (ischar(moving))
    
    % output registered image can have a different extension from the
    % moving image, so we have to check what's the actuall full name of the
    % output file
    regfile = dir([tempoutdir filesep 'result.0.*']);
    if (isempty(regfile))
        error('Elastix did not produce an output registration')
    end
    
    % read elastix result
    [t, ~, iterInfo] = elastix_read_reg_output(tempoutdir);
    
    % check that the output file extension matches the extension of the
    % output filename, and give a warning if they don't match
    if (~isempty(opts.outfile))
        
        [~, ~, regfile_ext] = fileparts(regfile.name);
        [~, ~, outfile_ext] = fileparts(opts.outfile);
        if (~strcmpi(regfile_ext, outfile_ext))
            warning('Gerardus:BadFileExtension', ...
                [ 'Elastix produced a ' regfile_ext ...
                ' image, but user asked to save to format ' outfile_ext])
        end
        
        % the first output argument will be the path to the output file,
        % rather than the image itself
        movingReg = opts.outfile;
        
        % move the result image to the directory requested by the user
        movefile([tempoutdir filesep regfile.name], movingReg);
        
    else
        
        % the first output argument will be the path to the output file, rather
        % than the image itself
        movingReg = '';
        
    end
    
    
else
    
    % read elastix result
    [t, movingReg, iterInfo] = elastix_read_reg_output(tempoutdir);
    
end

% delete temp files and directories
if (delete_fixedfile)
    delete_image(fixedfile)
end
if (delete_movingfile)
    delete_image(movingfile)
end
if (delete_paramfile)
    elastix_delete_param_file(paramfile)
end
if (delete_t0file)
    elastix_delete_param_file(t0file)
    if (ischar(t.InitialTransformParametersFileName))
        % if the transform is returned as a filename, the only one that is
        % going to be preserved is the top transform. The nested ones will
        % be deleted, so we cannot return filenames for them
        t.InitialTransformParametersFileName = 'NoInitialTransform';
    end
end
if (delete_fMaskfile)
    delete(fMaskfile)
end
if (delete_mMaskfile)
    delete(mMaskfile)
end
rmdir(tempoutdir, 's')

end

% create_temp_file_if_array_image
%
% check whether an input image is provided as an array or as a path to a
% file. If the former, then save the image to a temp file so that it can be
% processed by elastix
function [filename, delete_tempfile] = create_temp_file_if_array_image(file)

if (isempty(file))
    
    % this option is useful for the fixed and moving masks, when they are
    % not provided by the user, and thus file==''
    filename = '';
    delete_tempfile = false;

elseif (ischar(file))

    % read image header
    info = imfinfo(file);
    
    switch (info.ColorType)
        case 'truecolor'
            
            % input image is a color RGB image. We need to create a temp
            % file for each channel
            
            % load image
            im = imread(file);
            
            % create temp files to save the channels of the image
            delete_tempfile = true;
            nchan = size(im, 3);
            filename = cell(1, nchan);
            for I = 1:nchan
                % create a temp file for the image
                [pathstr, name] = fileparts(tempname);
                filename{I} = [pathstr filesep name '.png'];
                imwrite(im(:, :, I), filename{I});
            end
            
        case 'grayscale'
            
            % input is a filename already, and image is grayscale. Thus we
            % don't need to create a temp file
            delete_tempfile = false;
            filename = file;
            
        otherwise
            
            error('Image in input file is neither RGB nor grayscale')
    end
    
    
else
    
    % if image is colour, it needs to be split into channels
    nchan = size(file, 3);
    delete_tempfile = true;
    if (nchan == 1)
        % grayscale image

        % create a temp file for the image
        [pathstr, name] = fileparts(tempname);
        filename = [pathstr filesep name '.png'];
        imwrite(file, filename);
    else
        % image with more than one channel, e.g. RGB image
        
        filename = cell(1, nchan);
        for I = 1:nchan
            % create a temp file for the image
            [pathstr, name] = fileparts(tempname);
            filename{I} = [pathstr filesep name '.png'];
            imwrite(file(:, :, I), filename{I});
        end
    end
    
    
end

end

% create_temp_file_if_struct
%
% check whether parameters are provided as a struct or file. If struct,
% then save them to a temp file
function [filename, delete_tempfile] = create_temp_file_if_struct(param)

if (isempty(param))

    % nothing provided. This is useful for T0, as the user will not always
    % provide an initial transform
    delete_tempfile = false;
    filename = '';
    
elseif (isstruct(param))

    % create a temp file for the parameter file
    delete_tempfile = true;
    filename = elastix_write_param2file('', param);
    
elseif (ischar(param))
    
    % we are going to use the file provided by the user, and will not
    % delete it afterwards
    delete_tempfile = false;
    filename = param;
    
else
    
    error('REGPARAM must be a struct or file name')
    
end

end

% delete_image
%
% delete one or more files containing the channels of an image
function delete_image(filename)

if (iscell(filename))
    for I = 1:length(filename)
        delete(filename{I})
    end
else
    delete(filename)
end

end
