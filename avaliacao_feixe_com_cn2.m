clear all; close all; clc;

%%%%%%%%%% Dados de Entrada %%%%%%%%%%%%%
% Carregando dados
load('1-CENTRO_TXX_FYY_DDMMYY.mat');

%%%%%%%%%% Dados de Entrada %%%%%%%%%%%%%
x0 = [-20 -20];
W = 8.67; % "Largura" da Gaussiana para este Anteparo 

%%%%%%%%%%% Definição das posições dos fotodetectores %%%%%%%%%%%%%%%%
d = W * sqrt(3/2); % Lado do triângulo equilátero                                
% Posições dos fotodetectores
x1 = 0; y1 = d * (sqrt(3)/3);       % Topo
x2 = -d/2; y2 = -d * (sqrt(3)/6);   % Esquerda
x3 = d/2; y3 = -d * (sqrt(3)/6);    % Direita

%%%%%%%%%%% Definição das posições dos fotodetectores %%%%%%%%%%%%%%%%

W = 15.5; % W REAL MEDIDO
% Acessar dados dos fotodetectores
topo = DADOS.Topo;
esquerda = DADOS.Esquerda;
direita = DADOS.Direita;
pc = DADOS.Central;

% Normalização das potências
n_amostras = length(pc);
P1N = NaN(1, n_amostras); 
P2N = NaN(1, n_amostras); 
P3N = NaN(1, n_amostras);

idx_valid = pc ~= 0;
P1N(idx_valid) = round(topo(idx_valid) ./ pc(idx_valid), 2);
P2N(idx_valid) = round(esquerda(idx_valid) ./ pc(idx_valid), 2);
P3N(idx_valid) = round(direita(idx_valid) ./ pc(idx_valid), 2);

% Cálculo da posição da luz
out = cell(1, n_amostras);
for i = 1:n_amostras
    [solution, x0_novo] = resolve_triang(x0, x1, y1, x2, y2, x3, y3, P1N(i), P2N(i), P3N(i), W);
    x0 = x0_novo;
    out{i} = solution;
end   

% Extração das coordenadas
N = length(out);              
xc = zeros(1, N);             
yc = zeros(1, N);             

for i = 1:N
    coords = out{i};
    if ~isempty(coords)
        xc(i) = coords(1);
        yc(i) = coords(2);
    else
        xc(i) = NaN;
        yc(i) = NaN;
    end
end

% Cálculo do rc (vetorizado)
rc = sqrt(xc.^2 + yc.^2);  % em mm



%%%%%%%%%% Cálculo do Cn² %%%%%%%%%%%%%
% A equação geral utilizada é:
%   <r_c²> = 2,42 * Cn² * L³ * W₀^(-1/3)
%
% Onde:
%   - <r_c²>  = variância de rc (em m²)
%   - L       = distância em metros
%   - W₀      = largura em metros
%   - Cn²     = parâmetro de turbulência atmosférica
%
% Isolando Cn², temos:
%   Cn² = <r_c²> / (2,42 * L³ * W₀^(-1/3))
%
% Assim, usamos a variância de rc (em janelas de 1 segundo) para estimar Cn².

%%%%%%%%%% Cálculo do Cn² %%%%%%%%%%%%%
interval_cn = 1000;        % 1 segundo de dados (1 kHz) Frequencia do DAQ
L = 1;                     % distância em metros do enlace
rc_m = rc / 1000;          % conversão mm -> m
W_m  = W  / 1000;          % conversão mm -> m

Cn2 = zeros(1, ceil(length(rc_m) / interval_cn));
for aux = 1:ceil(length(rc_m) / interval_cn)
    inicio = 1 + (aux - 1) * interval_cn;
    fim = min(aux * interval_cn, length(rc_m));
    variancia = var(rc_m(inicio:fim));
    Cn2(aux) = variancia / (2.42 * W_m^(-1/3) * L^3);
end

%%%%%%%%%% PLOT DOS RESULTADOS %%%%%%%%%%%%%
figure;
hold on;

% 1. Plot do triângulo dos fotodetectores
detectores_x = [x1, x2, x3, x1];
detectores_y = [y1, y2, y3, y1];
plot(detectores_x, detectores_y, 'k-', 'LineWidth', 2);

% 2. Plot dos fotodetectores
scatter([x1, x2, x3], [y1, y2, y3], 200, 'filled', 'MarkerFaceColor', 'b');
text(x1, y1, ' Topo', 'VerticalAlignment', 'bottom', 'FontSize', 12);
text(x2, y2, ' Esquerda', 'HorizontalAlignment', 'right', 'FontSize', 12);
text(x3, y3, ' Direita', 'HorizontalAlignment', 'left', 'FontSize', 12);

% 3. Plot da trajetória da luz
scatter(xc, yc, 40, 'r', 'filled');

% 4. Configurações do gráfico
axis equal;
grid on;
xlabel('Posição X (mm)');
ylabel('Posição Y (mm)');
title('Posição da Luz no Triângulo de Fotodetectores');
legend('Triângulo', 'Fotodetectores', 'Posição da Luz', 'Location', 'best');

% 5. Plot do Cn²
figure;
plot(Cn2, 'LineWidth', 1.5);
grid on;
xlabel('Intervalo (1 s)');
ylabel('Cn²');
title('Variação de Cn² ao longo do tempo');

%%%%%%%%%% FUNÇÃO PARA RESOLVER O SISTEMA %%%%%%%%%%%%%
function [solution, x0_novo] = resolve_triang(x0, x1, y1, x2, y2, x3, y3, P1, P2, P3, W)
    format long;
    solution = {};
    x0_novo = x0; % Se pular, retorna o x0 original

    if P1 <= 0 || P2 <= 0 || P3 <= 0
        warning('P1, P2 ou P3 são <= 0. Pulando solução.');
        return;
    end

    AUX = [x1, y1, x2, y2, x3, y3, P1, P2, P3];
    if any(isnan(AUX)) || any(isinf(AUX))
        warning('NaN ou Inf encontrado nos parâmetros. Pulando solução.');
        return;
    end

    if W <= 0
        warning('W é <= 0. Pulando solução.');
        return;
    end

    f = @(x) resolve_sistema(x, AUX, W);
    options = optimset('Algorithm', 'levenberg-marquardt', 'MaxIter', 10000, 'TolX', 1e-9, 'Display', 'off');
    
    try
        resp = fsolve(f, x0, options);
        solution = [solution, resp];
        x0_novo = resp;
    catch
        warning('Erro no fsolve. Pulando solução.');
    end
end

function F = resolve_sistema(x, AUX, W)               
    F = [ ((AUX(1)-x(1))^2 + (AUX(2)-x(2))^2) - (W^2) * (-log(AUX(7)))
          ((AUX(3)-x(1))^2 + (AUX(4)-x(2))^2) - (W^2) * (-log(AUX(8))) 
          ((AUX(5)-x(1))^2 + (AUX(6)-x(2))^2) - (W^2) * (-log(AUX(9))) ];
end
