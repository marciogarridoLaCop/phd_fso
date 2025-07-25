function [t1] = f_temperatura(valor)
beta = 3960.0;
r0 = 100000.0;
t0 = 273.0 + 25.0;
rx = r0 * exp(-beta / t0);
vcc = 5;
R = 100000.0;

v = valor;
rt = (vcc * R) ./ v - R;
t1 = beta ./ log(rt / rx);
t1 = t1 - 273.0;


% Vout = valor;
% Vin = 5;
% Ro = 10000; % 10k Resistor
% Rt = (Vout * Ro) ./ (Vin - Vout);
% %%Rt = 10000; 
% 
% %Steinhart Constants
% A = 0.001129148;
% B = 0.000234125;
% C = 0.0000000876741;
% 
% %Steinhart - Hart Equation
% 
% TempK = 1 ./ (A + (B * log(Rt)) + (C * log(Rt).^3));
% thermistorTempC = TempK - 273.15;
% t1=thermistorTempC;

end