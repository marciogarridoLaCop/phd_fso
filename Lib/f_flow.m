function [flow] = f_flow(valor)
volts = valor;
vcc=5.2;
flow = ((volts - 1) / (vcc - 1)) * 39.8 + 0.1;
if flow < 0.01 
    flow=0;
end
end