function [A,U,Z] = aprime(X1,X2,dim)
%APRIME - Compute A' (A-prime), i.e. non-parametric under ROC curve
%   [] = aprime(X1,X2[,dim])
%   Default dim = 1
%   Example
%       >> aprime(conf_correct,conf_incorrect)
%
%   See also: 
% Reference: 

% Author: K. N'Diaye (kndiaye01<at>yahoo.fr)
% Copyright (C) 2009 
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by  the
% Free Software Foundation; either version 2 of the License, or (at your
% option) any later version: http://www.gnu.org/copyleft/gpl.html
%
% ----------------------------- Script History ---------------------------------
% KND  2009-04-09 Creation
%                   
% ----------------------------- Script History ---------------------------------
if nargin<3
    dim = 1;
end
s=[ size(X1) ; size(X2) ];
n1=s(1,dim);
n2=s(2,dim);
ranks = tiedrank(cat(dim,X1,X2),dim);
n1n2 = n1.*n2;
A = (sum(ranks(1:n1,:),dim)-n1*(n1+1)/2)/n1n2;
if nargout > 1
    U = A*n1n2;
    if nargout > 2
        Z = (U-n1*(n1+n2+1)/2)/sqrt(n1n2*(n1+n2+1)/12);
    end
end
return

function [r, tieadj] = tiedrank(x, tieflag, bidirectional)
%TIEDRANK Compute the ranks of a sample, adjusting for ties.
%   [R, TIEADJ] = TIEDRANK(X) computes the ranks of the values in the
%   vector X.  If any X values are tied, TIEDRANK computes their average
%   rank.  The return value TIEADJ is an adjustment for ties required by
%   the nonparametric tests SIGNRANK and RANKSUM, and for the computation
%   of Spearman's rank correlation.
%
%   [R, TIEADJ] = TIEDRANK(X,1) computes the ranks of the values in the
%   vector X.  TIEADJ is a vector of three adjustments for ties required
%   in the computation of Kendall's tau.  TIEDRANK(X,0) is the same as
%   TIEDRANK(X).
%
%   [R, TIEADJ] = TIEDRANK(X,0,1) computes the ranks from each end, so
%   that the smallest and largest values get rank 1, the next smallest
%   and largest get rank 2, etc.  These ranks are used for the
%   Ansari-Bradley test.
%
%   See also ANSARIBRADLEY, CORR, PARTIALCORR, RANKSUM, SIGNRANK.

%   Copyright 1993-2005 The MathWorks, Inc.
%   $Revision: 1.5.2.6 $  $Date: 2005/07/29 11:42:04 $

if nargin < 2
    tieflag = false;
end
if nargin < 3
    bidirectional = 0;
end

if isvector(x)
   [r,tieadj] = tr(x,tieflag,bidirectional);
else
   if isa(x,'single')
      outclass = 'single';
   else
      outclass = 'double';
   end

   % Operate on each column vector of the input (possibly > 2 dimensional)
   sz = size(x);
   ncols = sz(2:end);  % for 2x3x4, ncols will be [3 4]
   r = zeros(sz,outclass);
   if tieflag
      tieadj = zeros([3,ncols],outclass);
   else
      tieadj = zeros([1,ncols],outclass);
   end
   for j=1:prod(ncols)
      [r(:,j),tieadj(:,j)] = tr(x(:,j),tieflag,bidirectional);
   end
end

% --------------------------------
function [r,tieadj] = tr(x,tieflag,bidirectional)
%TR Local tiedrank function to compute results for one column

% Sort, then leave the NaNs (which are sorted to the end) alone
[sx, rowidx] = sort(x(:));
numNaNs = sum(isnan(x));
xLen = numel(x) - numNaNs;

if bidirectional
    % Use ranks counting from both low and high ends
    if mod(xLen,2)==0
        ranks = [(1:xLen/2), (xLen/2:-1:1), NaN(1,numNaNs)]';
    else
        ranks = [(1:(xLen+1)/2), ((xLen-1)/2:-1:1), NaN(1,numNaNs)]';
    end         
else
    % Use ranks counting from low end
    ranks = [1:xLen NaN(1,numNaNs)]';
end

if tieflag
    tieadj = [0; 0; 0];
else
    tieadj = 0;
end
if isa(x,'single')
   ranks = single(ranks);
   tieadj = single(tieadj);
end

% Adjust for ties.  Avoid using diff(sx) here in case there are infs.
ties = (sx(1:xLen-1) == sx(2:xLen));
tieloc = [find(ties); xLen+2];
maxTies = numel(tieloc);

tiecount = 1;
while (tiecount < maxTies)
    tiestart = tieloc(tiecount);
    ntied = 2;
    while(tieloc(tiecount+1) == tieloc(tiecount)+1)
        tiecount = tiecount+1;
        ntied = ntied+1;
    end

    if tieflag
        n2minusn = ntied*(ntied-1);
        tieadj = tieadj + [n2minusn/2; n2minusn*(ntied-2); n2minusn*(2*ntied+5)];
    else
        tieadj = tieadj + ntied*(ntied-1)*(ntied+1)/2;
    end
    
    % Compute mean of tied ranks
    ranks(tiestart:tiestart+ntied-1) = ...
                  sum(ranks(tiestart:tiestart+ntied-1)) / ntied;
    tiecount = tiecount + 1;
end

% Broadcast the ranks back out, including NaN where required.
r(rowidx) = ranks;
r = reshape(r,size(x));
