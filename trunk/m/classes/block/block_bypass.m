%> @brief Bypass block
%>
%> Use this block
classdef block_bypass < block
    methods
        function o = block_bypass(o)
            o.classtitle = 'By-pass';
            o.flag_bootable = 0;
            o.flag_trainable = 0;
        end;
    end;
end