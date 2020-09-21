function A = ssfull_read (file)
%SSFULL_READ read a full matrix using a subset of Matrix Market format
% This function reads in a file generated by ssfull_write.  It cannot read
% arbitrary Matrix Market formatted files.  See ssfull_write for a description
% of the file format.
%
% Example:
%   x = rand (8)
%   ssfull_write ('xfile', x)
%   y = ssfull_read ('xfile')
%   norm (x-y)
%
% See also mread, mwrite, RBwrite, RBread.

% Copyright 2006-2019, Timothy A. Davis

% open the file
f = fopen (file, 'r') ;
if (f < 0)
    error (['cannot open: ' file]) ;
end

% ignore the header line - determine real/complex from # of entries in each row
s = fgetl (f) ;								    %#ok

% read in the # of rows and columns
[siz count] = fscanf (f, '%d %d', 2) ;
if (count ~= 2)
    error (['invalid file: ' file]) ;
end
m = siz (1) ;
n = siz (2) ;

% read in the rest of the matrix
A = fscanf (f, '%g') ;

% This is an unfortunate workaround.  fscanf in C and MATLAB, and the read
% statement in Fortran, cannot interpret the character strings 'Inf', '-Inf',
% or 'NaN' as the appropriate value.  Thus, a special huge value (1e308) is
% used to represent these values (Inf and NaN both become 1e308).  A sparse
% matrix typically won't included any Inf's or NaN's, but auxiliary arrays can,
% for some problems.  For example, the bounds of an LP can be +Inf or -Inf;
% lo(i) = -Inf means that there is no lower bound on the ith variable.
%
% The identical workaround is used in ssfull_write, mread, mwrite, RBread, and
% RBwrite.  1e308 was chosen because it's close to the largest IEEE double
% precision number of 1.7977e308, and because the string '1e308' is short,
% leading to more compact files.  Note that NaN's are treated as +Inf.
A (A ==  1e308) =  Inf ;
A (A == -1e308) = -Inf ;

% reshape the matrix into its final form 
if (length (A) == m*n)
    % this is a real matrix
    A = reshape (A, m, n) ;
elseif (length (A) == 2*m*n)
    % this is a complex matrix
    A = reshape (A (1:2:end), m, n) + reshape (A (2:2:end), m, n) * 1i ;
else
    error (['invalid file: ' file]) ;
end

% close the file
fclose (f) ;

