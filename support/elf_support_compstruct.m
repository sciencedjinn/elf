function s = elf_support_compstruct(s, d, n, verbose)
% s = elf_support_compstruct(s, d, n, verbose)
% recursive function that compares the fields in s and d (default)
% if a field does not exist in s, it is copied from d

if nargin<4, verbose=1; end
if nargin<3 || isempty(n), n=''; end

if isstruct(s) && isstruct(d)
    %both structures, compare fields
    df=fieldnames(d);
    for i=1:length(df)
        if isfield(s, df{i}) && ( ~isempty(s.(df{i})) || isempty(d.(df{i})) )
            %field exists AND is not empty (or empty by default)
            s.(df{i}) = elf_support_compstruct(s.(df{i}), d.(df{i}), [n '.' df{i}], verbose);
        else
            s.(df{i}) = d.(df{i});
            if verbose, disp(['Inserting missing or empty field ' n '.' df{i}]); end
        end
    end
elseif isstruct(s) || isstruct(d)
    error(['Internal error: Field ' n 'exists in both variables, but is not a structure in one of them']);
else
    %not structures, return
end