%% GERARDUS DOCUMENTATION GUIDELINES
% This document contains information on how to create documentation for gerardus
% such that it is visible on the project public webpage at
% http://code.google.com
%% Prerequisites
% In order for html pages to be served from google as HTML pages rather than
% PLAINTEXT, it is important to set the mimetype correctly via svn. This can be
% done via the subversion config file, and setting appropriate
% |auto-props|.
%%
%  For more info see:
%    http://manjeetdahiya.com/2010/09/29/serving-html-documentation-from-google-code-svn/ 
%    https://code.google.com/p/flexlib/wiki/HowToBuild

%% Publisher options
% Matlab publisher can be used as normal; except you should specify in the
% options the gerardus/doc/<function_name> folder as the output path.
%%
% It is advisable to put each published output in its own folder, since if
% there's images generated by the publisher, they will be in the same folder

%% Linking to the doc from within the function files
% There are instructions on matlab on how to create searchable documentation for
% matlab for toolboxes, but this is <http://uk.mathworks.com/help/matlab/matlab_prog/display-custom-documentation.html fairly complex>.
% A simple thing to do is to create a hyperlink to the
% published html documentation, when the function help is shown, as described
% <http://uk.mathworks.com/help/matlab/matlab_prog/add-help-for-your-program.html here>.

%% Documentation online
% Once the html file has been uploaded from svn, one can create a wiki link to
% the *raw* html file. If the svn mimetype has been set correctly to text/html,
% this should display as a webpage; otherwise it will be served as text/plain
% (i.e. the page will display as source code, rather than interpreted as a
% webpage).
