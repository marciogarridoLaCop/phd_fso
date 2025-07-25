function [humidity] = f_humidity(voltage)
% Converte tensão (0-5V) em umidade relativa (%RH)
% Baseado na extrapolação dos dados fornecidos:
% 0V → 100%RH
% 4V → 0%RH

% Definindo a faixa de operação
v_min = 0;    % 0V = 100%RH
v_max = 4.0;  % 4V = 0%RH

% Cálculo da umidade
if voltage <= v_min
    humidity = 100; % Limite inferior
elseif voltage >= v_max
    % Extrapolação linear para tensões acima de 4V
    humidity = 0 - ((voltage - v_max) * 25); % -25%RH por volt adicional
else
    % Faixa normal de operação
    humidity = 100 - (voltage * (100/v_max));
end

% Limitando a saída entre 0-100%RH (mesmo com extrapolação)
humidity = max(0, min(100, humidity));

% Aviso se estiver extrapolando
if voltage > v_max
    warning('Tensão acima da faixa calibrada (4V). Usando extrapolação.');
end
end