% eegplugin_detectevent() - EEGLAB plugin for detecting events such as 
%                           sleep splindles
%
% Usage:
%   >> eegplugin_detectevent(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer]  EEGLAB figure
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks.
%
% Author: Arnaud Delorme, 2019

% Copyright (C) 2019 Arnaud Delorme
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function vers = eegplugin_detectevent(fig, trystrs, catchstrs)

    vers = 'detectspindles1.0';
    if nargin < 3
        error('eegplugin_detectevent requires 3 arguments');
    end

    % add folder to path
    % -----------------------
    if ~exist('eegplugin_detectevent')
        p = which('eegplugin_detectevent');
        p = p(1:findstr(p,'eegplugin_detectevent.m')-1);
        addpath([p vers]);
    end

    % find import data menu
    % ---------------------
    menu = findobj(fig, 'tag', 'tools');

    % menu callbacks
    % --------------
    com = [trystrs.no_check '[EEG LASTCOM] = pop_detectevent(EEG);' catchstrs.new_and_hist];

    % create menus if necessary
    % -------------------------
    uimenu( menu, 'Label', 'Detect spindles, blinks, etc...', 'CallBack', com);
  