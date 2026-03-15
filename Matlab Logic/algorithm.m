clc;
clear all;
m = 16;
k = 17;
n = 19;
t = (n-k)/2; 
q = 2^m;
TYPE1=0;
TYPE2=0;
TYPE3=0;
CSCV=0;
CANV=0;
NSER=0;

prim_poly = primpoly(m, 'min');

alpha = gf(2, m, prim_poly);

disp("RS(19, 17) Code (t=1) with custom DBB (t=2) decoder.");
disp("Config: 272 data bits (17 symbols) + 32 parity bits (2 symbols).");

msg_data = randi(100, 1, k);
disp(msg_data);
data_symbols = gf(msg_data, m, prim_poly);
disp("data_symbols");
disp(data_symbols);

%PARITY GENERATION=========================================================
N_full = 2^m - 1;                                                          % This will be 65535
K_full = N_full - 2;                                                       %num_parity; % This will be 65533
genpoly = rsgenpoly(N_full, K_full, prim_poly);
msg_padded = [data_symbols.x zeros(1, n - k)];
disp("msg_padded");
disp(msg_padded);
[~, rem] = deconv(gf(msg_padded, m, prim_poly), gf(genpoly, m, prim_poly));
rem_vec = zeros(1, n - k);
disp("rem_vec");
disp(rem_vec);
if length(rem.x) < n - k
    rem_vec(end-length(rem.x)+1:end) = rem.x;
else
    rem_vec = rem.x;
end
parity_symbols = gf(rem_vec, m, prim_poly);
parity_extract = parity_symbols(end-(n-k)+1:end);

%==========================================================================

%CODEWORD GENERATION
codeword = [data_symbols parity_extract];
disp("codeword1");
disp(codeword);
%codeword = rsenc(data_symbols, n, k);
%disp("codeword2");
%disp(codeword);

original_rxcodeword = codeword;
disp("rx_codeword");
disp(original_rxcodeword);

S_C = gf(0, m, prim_poly);
for i = 1:length(codeword)
    S_C = S_C + codeword(i);
end
disp("S_C1");
disp(S_C);
S_C = polyval(codeword, gf(1, m, prim_poly));
disp("S_C2");
disp(S_C);

%ERROR INJECTION===========================================================
num_errors_to_inject = 2;
for loc1 = 1:19
    for loc2 = 1:19
        disp("=============================================================");
        rx_codeword = original_rxcodeword;
        disp("BEFORE CORRECTION");
        %disp("RX CODEWORD = ");
        %disp(rx_codeword.x);
        disp("CODEWORD = ");
        disp(codeword.x);
        err_syms = [loc1 loc2];
        err_bits = randi([1 m], 1, num_errors_to_inject);
        
        
        Ei0 = gf(bitset(0, err_bits(1)), m, prim_poly);
        %disp(Ei0);
        Ei1 = gf(bitset(0, err_bits(2)), m, prim_poly);
        %disp(Ei1);
        
        rx_codeword(err_syms(1)) = rx_codeword(err_syms(1)) + Ei0;
        rx_codeword(err_syms(2)) = rx_codeword(err_syms(2)) + Ei1;
        disp("RX CODEWORD = ");
        disp(rx_codeword.x);
        disp("err_syms");
        disp(err_syms);
        disp("err_bits");
        disp(err_bits);
        %disp("--- Error Injection ---");
        %fprintf('Injected 2 SBE errors at locations: %d, %d\n', err_syms(1), err_syms(2));
        %fprintf('Error magnitudes of Ei0 = %d : Error magnitudes of Ei1 = %d \n',Ei0.x,Ei1.x);
        %disp("Received Codeword (with 2 errors): ")
        %disp(rx_codeword.x);
        
        
        %disp("--- SYNDROME GENERATION ---");
        S0 = gf(0, m, prim_poly);
        S1 = gf(0, m, prim_poly);
        S2 = gf(0, m, prim_poly);
        T = alpha.^(n-(1:n)); % T(j) = alpha^(n-j)
        % T2 is required for the 2-error check
        T2 = (alpha.^2).^(n-(1:n)); % T2(j) = (alpha^2)^(n-j)
        
        for j = 1:n
            symbol = rx_codeword(j);
            % S0 = c(alpha^0) = c(1)
            S0 = S0 + symbol;
            % S1 = c(alpha^1)
            S1 = S1 + symbol * T(j);
            % S2 = c(alpha^2)
            S2 = S2 + symbol * T2(j); % Use T2(j) directly
        end
        
        S0_error = S0 - S_C;
        
        S0_bin = dec2bin(S0_error.x, m);
        weight_S0 = sum(S0_bin == '1');
        
        %fprintf('\n--- Decoder ---');
        %fprintf('\nMeasured S0 = %d. Original sum(C) = %d.', S0.x, S_C.x);
        %fprintf('\nIsolated S0_error = %d (weight %d)', S0_error.x, weight_S0);
        %fprintf('\nS1 = %d', S1.x);
        %fprintf('\nS2 = %d\n', S2.x);
        
        correction_success = false;
        
        if weight_S0 == 2
            %fprintf('S0 weight is 2. Attempting DBB-ECC (Type 1/2/3) correction...\n');
            %idx_one = find(S0_bin == '1');
            idx_one = find(S0_bin == '1');
            err_bits_corrected = m - idx_one + 1;
            %disp("err_bits_corrected");
            %disp(err_bits_corrected);
            % Our guesses for the error magnitudes are the two bits found.
            Ej0 = gf(bitset(0, err_bits_corrected(1)), m, prim_poly); % Guess 1
            Ej1 = S0_error + Ej0; % Guess 2 (S0_error - Ej0 = Ej1)
            error_patterns = {[Ej0, Ej1], [Ej1, Ej0]};
            
            for pairs = 1:2
                ep = error_patterns{pairs}; % ep(1) is first error, ep(2) is second
                found = false;
                for i0 = 1:k
                    for i1 = i0+1:k
                        if (T(i0)*ep(1) + T(i1)*ep(2) + S1 == 0) && (T2(i0)*ep(1) + T2(i1)*ep(2) + S2 == 0)
                            fprintf('Type 1 DBE (Data/Data) detected at symbols %d, %d\n', i0, i1);
                            rx_codeword(i0) = rx_codeword(i0) - ep(1); % Correct error 1
                            rx_codeword(i1) = rx_codeword(i1) - ep(2); % Correct error 2
                            found = true; break;
                        end
                    end
                    if found
                        break; 
                    end
                end
                
                if ~found
                    for i0 = 1:k
                        for p = k+1:n % Parity positions
                            if (T(i0)*ep(1) + T(p)*ep(2) + S1 == 0) && (T2(i0)*ep(1) + T2(p)*ep(2) + S2 == 0)
                                fprintf('Type 2 DBE (Data/Parity) detected at Data %d and Parity %d\n', i0, p);
                                rx_codeword(i0) = rx_codeword(i0) - ep(1);
                                rx_codeword(p) = rx_codeword(p) - ep(2);
                                found = true; break;
                            end
                        end
                        if found, break; end
                    end
                end
                
                if ~found
                    for p0 = k+1:n-1
                        for p1 = p0+1:n
                            % The math is identical: S1 = Xp0*E0 + Xp1*E1
                            if (T(p0)*ep(1) + T(p1)*ep(2) + S1 == 0) && (T2(p0)*ep(1) + T2(p1)*ep(2) + S2 == 0)
                                fprintf('Type 3 DBE (Parity/Parity) detected at Parity %d and Parity %d\n', p0, p1);
                                rx_codeword(p0) = rx_codeword(p0) - ep(1);
                                rx_codeword(p1) = rx_codeword(p1) - ep(2);
                                found = true; break;
                            end
                        end
                        if found, break; end
                    end
                end
                
                if found, correction_success = true; break; end
            end
            
        elseif weight_S0 == 0
            fprintf('S0 weight is 0. Attempting DBB-ECC (Type 1/2/3 identical) correction...\n');
            found = false;
            for bitpos = 1:m
                ep = gf(bitset(0, bitpos), m, prim_poly); % ep = E0 = E1
                for i0 = 1:k
                    for i1 = i0+1:k
                        % Check if S1 = X0*E + X1*E = (X0 + X1) * E
                        if (T(i0)*ep + T(i1)*ep + S1 == 0) && (T2(i0)*ep + T2(i1)*ep + S2 == 0)
                            fprintf('Type 1 DBE (identical Data/Data) at %d, %d, bit %d\n', i0, i1, bitpos);
                            TYPE1=TYPE1+1;
                            rx_codeword(i0) = rx_codeword(i0) - ep;
                            rx_codeword(i1) = rx_codeword(i1) - ep;
                            found = true; break;
                        end
                    end
                    if found, break; end
                end
                % Check Type 2: One error in DATA, one in PARITY
                if ~found
                    for i0 = 1:k
                        for p = [k+1 k+2] % Parity positions 18 and 19
                            % Check if S1 = X0*E + Xp*E = (X0 + Xp) * E
                            if (T(i0)*ep + T(p)*ep + S1 == 0) && (T2(i0)*ep + T2(p)*ep + S2 == 0)
                                fprintf('Type 2 DBE (identical Data/Parity) at Data %d Parity %d bit %d\n', i0, p, bitpos);
                                TYPE2=TYPE2+1;
                                rx_codeword(i0) = rx_codeword(i0) - ep;
                                rx_codeword(p) = rx_codeword(p) - ep;
                                found = true; break;
                            end
                        end
                        if found, break; end
                    end
                end
                
                % Check Type 3: Two errors in PARITY symbols (p0, p1)
                if ~found
                    for p0 = k+1:n-1
                        for p1 = p0+1:n
                            % Check if S1 = Xp0*E + Xp1*E = (Xp0 + Xp1) * E
                            if (T(p0)*ep + T(p1)*ep + S1 == 0) && (T2(p0)*ep + T2(p1)*ep + S2 == 0)
                                fprintf('Type 3 DBE (identical Parity/Parity) at Parity %d, %d, bit %d\n', p0, p1, bitpos);
                                TYPE3=TYPE3+1;
                                rx_codeword(p0) = rx_codeword(p0) - ep;
                                rx_codeword(p1) = rx_codeword(p1) - ep;
                                found = true; break;
                            end
                        end
                        if found, break; end
                    end
                end
                
                if found, break; end % Break from the bitpos loop
            end
            if found, correction_success = true; end
            
        else
            fprintf('DBB check failed (Weight_S0 = %d). Attempting standard SBE (t=1) correction...\n', weight_S0);
            
            if S1.x == 0 && S2.x == 0
                % This can happen if, e.g., weight_S0=1 but S1/S2 are 0 (no error)
                fprintf('S1 and S2 are zero. No error detected by SBE decoder.\n');
            else
                X = S2 / S1;
                % Error Magnitude E = S1 / X
                E_calculated = S1 / X;
                
                error_location = 0;
                % Search for the locator X = alpha^(n-j)
                for j = 1:n
                    %locator = alpha^(n-j); % T(j)
                    if locator.x == X.x
                        error_location = j;
                        break;
                    end
                end
                
                if error_location ~= 0
                    % Found a single error
                    fprintf('Standard SBE (t=1) error detected.\n');
                    fprintf('Calculated Error Magnitude E = %d\n', E_calculated.x);
                    fprintf('Calculated Error Locator X (as power of alpha): A^%d\n', X.log);
                    fprintf('Error located at position %d.\n', error_location);
                    fprintf('Error located at position %d (original: %d).\n', error_location, random_error_location);
                    
                    % Apply correction
                    rx_codeword(error_location) = rx_codeword(error_location) - E_calculated;
                    correction_success = true;
                else
                   
                    fprintf('SBE decoder failed to find locator (uncorrectable error).\n');
                end
            end
        end % --- END of if weight_S0 == 2 ... elseif ... else ---
        
        
        % --- 8. Final Verification ---
        fprintf('\n--- Verification ---');
        if correction_success
            if all(rx_codeword.x == codeword.x)
                fprintf('\nCodeword successfully corrected and verified.\n');
                CSCV=CSCV+1;
                disp("AFTER CORRECTION");
                disp("RX CODEWORD = ");
                disp(rx_codeword.x);
                disp("CODEWORD = ");
                disp(codeword.x);
            else
                fprintf('\nCorrection applied, but verification FAILED (BUG!)\n');
                CANV=CANV+1;
                disp("AFTER CORRECTION");
                disp("RX CODEWORD = ");
                disp(rx_codeword.x);
                disp("CODEWORD = ");
                disp(codeword.x);
            end
        else
            % The decoder (neither DBB nor SBE) could find a solution.
            fprintf('\nCorrection was not successful. Errors remain.\n');
            NSER=NSER+1;
            disp("AFTER CORRECTION");
            disp("RX CODEWORD = ");
            disp(rx_codeword.x);
            disp("CODEWORD = ");
            disp(codeword.x);
        end
    end
end

fprintf('NUMBER OF CODEWORDS SUCCESSFULLY CORRECTED AND VERIFIED = %d \n',CSCV);
fprintf('NUMBER OF CORRECTIONS APPLIED, BUT VERIFICATION FAILED (BUG!) = %d \n',CANV);
fprintf('NUMBER OF CORRECTIONS NOT SUCCESSFUL. ERROR REMAINS = %d \n',NSER);
disp("===============================END===================================");