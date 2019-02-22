% pop_detectevent() - detect events such as sleep spindles or blinks.
%
% Parameters for detecting sleep spindles are from the following reference
% Antony et al. (2018) Sleep Spindle Refractoriness Segregates Periods of 
% Memory Reactivation, vol 28 (11,) P1736-1743.E4, DOI:https://doi.org/10.1016/j.cub.2018.04.020
%
% Usage:
%   >> [OUTEEG] = pop_detectevent( INEEG ); % pop up interactive window
%   >> [OUTEEG] = pop_detectevent( INEEG, 'key', val);
%
% Inputs:
%   INEEG      - input dataset
%
% Optional inputs:
%   'channels'  - [integer] selected channel(s) {default all}
%   'threshold' - [float] spindle detection threshold in standard deviation
%                of the RMS of the selected channel {default 1.5}
%   'transform'   - [string or function] window limit in seconds for applying transformation 
%   'transwin'    - [min max] window limit in seconds for applying transformation 
%                 {default [-0.2 0.2]}. Emply means that the transformation
%                 is applied to the whole data.
%   'eventwin' - [min max] window limit for spindle. The signal must
%                 be above 'threshold' for at least 'min' second and at 
%                 most 'max' seconds.  {default [0.3 3]}
%
% Outputs:
%   OUTEEG     - output dataset with update events
%
% Author: Arnaud Delorme, UCSD/CNRS, 2019

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

function [EEG, com] = pop_detectevent(EEG, varargin)

if nargin < 1
    help pop_detectevent;
    return
end

if nargin == 1
	% -----------------------
	promptstr    = { 'Selected channel(s)' ...
             'Transformation to apply to the data (none is ok)' ...
             'Moving window to apply transformation in s (default all data)' ...
             'Threshold on thansformed data in standard dev.' ...
             'Min and max event duration above threshold (in s)' ...
             'Event name' };
	inistr       = { '1' '@rmsave' '-0.2 0.2' '1.5' '0.3 3' 'spindle' };
	result       = inputdlg2(promptstr, 'Detect events -- pop_detectevent()', 1,  inistr, 'pop_detectevent');
	if isempty(result), return; end
    options = { 'channels' str2num([ '[' result{1} ']' ]) ...
                'transform' result{2} ...
                'transwin' str2num( [ '[' result{3} ']' ]) ...
                'threshold' str2num(result{4}) ...
                'eventwin' str2num( [ '[' result{5} ']' ] ) ...
                'eventname' result{6} ...
                };
else
    options = varargin;
end

g = finputcheck(options, {'channels'   'integer'  [1 EEG.pnts]  1:EEG.nbchan;
                          'transform'  ''         []            '';
                          'transwin'   'float'    []            [-0.2 0.2];
                          'threshold'  'float'    []            1.5;
                          'eventname'  'string'   {}           'spindle';
                          'eventwin' 'float'    []             [0.3 3]}, 'pop_detectevent');
if ischar(g), error(g); end
           
% compute RMS of all selected channels
spindleThresh = zeros(1, EEG.pnts);
tranformFunc  = g.transform;
if ~isempty(tranformFunc) && tranformFunc(1) == '@', tranformFunc = eval(tranformFunc); end;
for iChan = 1:length(g.channels)
    
    if isempty(g.transform)
        rmsMoveAv = EEG.data(g.channels(iChan), :);
    else
        if ~isempty(g.transwin)
            window = round(EEG.srate*g.transwin);
            winSamples = [window(1):window(2)];
            rmsMoveAv = zeros(1, EEG.pnts);
            for iSample = window(2)+1:EEG.pnts+window(1)-1
                rmsMoveAv(iSample) = feval(tranformFunc, EEG.data(g.channels(iChan), iSample+winSamples));
            end
        else
            rmsMoveAv = feval(g.transform, EEG.data(g.channels(iChan), :));
        end
    end
    
    % threshold if per channel
    threshold = std(rmsMoveAv)*g.threshold;    
    spindleThresh = spindleThresh | rmsMoveAv > threshold;
end

% look for regions
spindleLowLimits = round(EEG.srate*g.eventwin(1));
spindleHiLimits = round(EEG.srate*g.eventwin(2));
continuousAboveTheshold = 0;
onsetSpindle = 0;
for iSample = 1:EEG.pnts
	if spindleThresh(iSample)
		offsetSpindle = 0;
		continuousAboveTheshold = continuousAboveTheshold+1;
	else
		offsetSpindle = iSample;
		continuousAboveTheshold = 0;
	end

	if continuousAboveTheshold > spindleLowLimits
		onsetSpindle = iSample-continuousAboveTheshold;
	end

	if onsetSpindle ~= 0 && offsetSpindle ~= 0
		% you have a spindle
		EEG.event(end+1).type = g.eventname;		
		EEG.event(end).latency = onsetSpindle;
		EEG.event(end).duration = offsetSpindle-onsetSpindle;
        onsetSpindle = 0;
        offsetSpindle = 0;
	end
end

% resort events
[~,ind] = sort([EEG.event.latency]);
EEG.event = EEG.event(ind);

% history
com = sprintf('EEG = pop_detectevent(EEG, %s);', vararg2str(options));
