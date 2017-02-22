

// Calculates necessary bits to represent the argument "in_number"
// Evaluated in synthesis time
function automatic integer ceil_log2( input [31:0] in_number );
begin
    for( ceil_log2 = 0; in_number > 0; ceil_log2 = ceil_log2 + 1 )
      in_number = in_number >> 1;
end
endfunction
