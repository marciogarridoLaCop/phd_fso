clear all; close all; clc;

%%%%%%%%%% Dados de Entrada %%%%%%%%%%%%%
 
x0 = [-20 -20];

%%%%%%%%%%% Definição das posições dos fotodetectores %%%%%%%%%%%%%%%%
W = 8.67; % "Largura" da Gaussiana 
d = W*sqrt(3/2); % Lado do triângulo equilátero                                
                                         
% Posições dos fotodetectores
x1 = 0; y1 = d*(sqrt(3)/3);       % Topo
x2 = -d/2; y2 = -d*(sqrt(3)/6);   % Esquerda
x3 = d/2; y3 = -d*(sqrt(3)/6);    % Direita

% Carregando dados
load('3-FSO_TXX_FYY_DDMMYY.mat');
W=14% W REAL MEDIDO
% Acessar dados dos fotodetectores
topo = DADOS.Topo;
esquerda = DADOS.Esquerda;
direita = DADOS.Direita;
pc = DADOS.Central;

% Normalização das potências
n_amostras = length(pc);
P1N = zeros(1, n_amostras); 
P2N = zeros(1, n_amostras); 
P3N = zeros(1, n_amostras);

for i = 1:n_amostras
    if pc(i) ~= 0
        P1N(i) = round(topo(i)/pc(i), 2);  % 2 casas decimais
        P2N(i) = round(esquerda(i)/pc(i), 2);
        P3N(i) = round(direita(i)/pc(i), 2);
    else
        P1N(i) = NaN;
        P2N(i) = NaN;
        P3N(i) = NaN;
    end
end

% Cálculo da posição da luz
out = {};
for i = 1:length(P1N)
    [solution, x0_novo] = resolve_triang(x0, x1, y1, x2, y2, x3, y3, P1N(i), P2N(i), P3N(i), W);
    x0 = x0_novo;
    out = [out, solution];
end   

% Extração das coordenadas

N = length(out);              % Número de elementos em out
xc = zeros(1, N);             % Pré-alocação do vetor de coordenadas X
yc = zeros(1, N);             % Pré-alocação do vetor de coordenadas Y
rc = zeros(1, N);             % Pré-alocação do vetor de raios

for i = 1:N
    coords = out{i};          % Extrai o vetor de coordenadas da célula
    xc(i) = coords(1);        % Coordenada X
    yc(i) = coords(2);        % Coordenada Y
    rc(i) = sqrt(coords(1)^2 + coords(2)^2);  % Cálculo do raio
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
%plot(xc,yc)

% 4. Configurações do gráfico
axis equal;
grid on;
xlabel('Posição X (mm)');
ylabel('Posição Y (mm)');
title('Posição da Luz no Triângulo de Fotodetectores');
legend('Triângulo', 'Fotodetectores', 'Posição da Luz', 'Location', 'best');

%%%%%%%%%% FUNÇÃO PARA RESOLVER O SISTEMA %%%%%%%%%%%%%
function [solution, x0_novo] = resolve_triang(x0, x1, y1, x2, y2, x3, y3, P1, P2, P3, W)
    format long;
    solution = {};
    x0_novo = x0; % Se pular, retorna o x0 original

    % Verifica se algum P1, P2 ou P3 é <= 0 (pois log(P) seria inválido)
    if P1 <= 0 || P2 <= 0 || P3 <= 0
        warning('P1, P2 ou P3 são <= 0. Pulando solução.');
        return;
    end

    % Verifica se algum valor é NaN ou Inf
    AUX = [x1, y1, x2, y2, x3, y3, P1, P2, P3];
    if any(isnan(AUX)) || any(isinf(AUX))
        warning('NaN ou Inf encontrado nos parâmetros. Pulando solução.');
        return;
    end

    % Verifica se W é zero ou negativo (evitar divisão por zero)
    if W <= 0
        warning('W é <= 0. Pulando solução.');
        return;
    end

    % Se todas as verificações passarem, resolve o sistema
    f = @(x) resolve_sistema(x, AUX);
    options = optimset('Algorithm', 'levenberg-marquardt', 'MaxIter', 10000, 'TolX', 1e-9, 'Display', 'off');
    
    try
        resp = fsolve(f, x0, options);
        solution = [solution, resp];
        x0_novo = resp;
    catch
        warning('Erro no fsolve. Pulando solução.');
        x0_novo = x0; % Retorna o x0 original em caso de falha
    end

    function F = resolve_sistema(x, AUX)               
        F = [ ((((AUX(1)-x(1))^2)) + (((AUX(2)-x(2))^2)) - (W^2)* (-log(AUX(7))))
              ((((AUX(3)-x(1))^2)) + (((AUX(4)-x(2))^2)) - (W^2)* (-log(AUX(8)))) 
              ((((AUX(5)-x(1))^2)) + (((AUX(6)-x(2))^2)) - (W^2)* (-log(AUX(9))))];
    end
end